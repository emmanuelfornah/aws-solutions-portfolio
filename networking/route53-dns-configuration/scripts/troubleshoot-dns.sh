#!/bin/bash
# DNS Troubleshooting Script
# Comprehensive diagnostics for Route 53 DNS issues

set -e  # Exit on error

# Configuration
DOMAIN="${1:-www.anycompany.corp}"
ZONE="${2:-anycompany.corp}"

echo "=========================================="
echo "Route 53 DNS Troubleshooting"
echo "=========================================="
echo "Domain: $DOMAIN"
echo "Zone: $ZONE"
echo "Timestamp: $(date)"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

# Function to check command availability
check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "⚠ $1 not found, installing..."
        sudo yum install -y "$2" 2>/dev/null || echo "Failed to install $2"
    fi
}

# Ensure required tools are installed
check_command dig bind-utils
check_command nslookup bind-utils
check_command curl curl

# 1. System Information
print_section "1. System Information"
echo "Hostname: $(hostname)"
echo "Instance ID: $(ec2-metadata --instance-id 2>/dev/null | cut -d' ' -f2 || echo 'N/A')"
echo "Availability Zone: $(ec2-metadata --availability-zone 2>/dev/null | cut -d' ' -f2 || echo 'N/A')"
echo "Local IPv4: $(ec2-metadata --local-ipv4 2>/dev/null | cut -d' ' -f2 || hostname -I | awk '{print $1}')"
echo "Public IPv4: $(ec2-metadata --public-ipv4 2>/dev/null | cut -d' ' -f2 || echo 'N/A')"

# 2. VPC DNS Configuration
print_section "2. VPC DNS Configuration"
echo "DNS Resolver Configuration (/etc/resolv.conf):"
cat /etc/resolv.conf
echo ""
echo "Expected: nameserver should be VPC+2 (e.g., 10.0.0.2)"

# 3. DNS Resolution Tests
print_section "3. DNS Resolution Tests"

echo "Test 1: nslookup"
nslookup $DOMAIN 2>&1 || echo "⚠ nslookup failed"
echo ""

echo "Test 2: dig (short answer)"
dig +short $DOMAIN 2>&1 || echo "⚠ dig failed"
echo ""

echo "Test 3: dig (full query)"
dig $DOMAIN 2>&1 || echo "⚠ dig failed"
echo ""

echo "Test 4: host"
host $DOMAIN 2>&1 || echo "⚠ host failed"
echo ""

# 4. DNS Query Analysis
print_section "4. DNS Query Analysis"

echo "Query Type: A (IPv4)"
dig $DOMAIN A +noall +answer 2>&1 || echo "⚠ No A records found"
echo ""

echo "Query Type: AAAA (IPv6)"
dig $DOMAIN AAAA +noall +answer 2>&1 || echo "No AAAA records (expected)"
echo ""

echo "Query Type: CNAME"
dig $DOMAIN CNAME +noall +answer 2>&1 || echo "No CNAME records (expected)"
echo ""

echo "Query Type: ANY"
dig $DOMAIN ANY +noall +answer 2>&1 || echo "⚠ No records found"
echo ""

# 5. DNS Trace
print_section "5. DNS Query Trace"
echo "Tracing DNS resolution path..."
dig +trace $DOMAIN 2>&1 | tail -20 || echo "⚠ Trace failed"

# 6. DNS Cache Status
print_section "6. DNS Cache Status"

if command -v systemd-resolve >/dev/null 2>&1; then
    echo "DNS Cache Statistics:"
    systemd-resolve --statistics 2>&1 || echo "⚠ Statistics not available"
    echo ""
    
    echo "DNS Cache Status:"
    systemd-resolve --status 2>&1 | head -30 || echo "⚠ Status not available"
else
    echo "systemd-resolve not available on this system"
    echo "Checking nscd (Name Service Cache Daemon)..."
    if systemctl is-active nscd >/dev/null 2>&1; then
        echo "nscd is running"
        sudo nscd -g 2>&1 || echo "⚠ Cannot get nscd statistics"
    else
        echo "nscd is not running"
    fi
fi

# 7. Network Connectivity
print_section "7. Network Connectivity Tests"

RESOLVED_IP=$(dig +short $DOMAIN 2>/dev/null | head -1)

if [ -n "$RESOLVED_IP" ]; then
    echo "Resolved IP: $RESOLVED_IP"
    echo ""
    
    echo "Test 1: Ping (ICMP)"
    if ping -c 3 -W 2 $RESOLVED_IP 2>&1; then
        echo "✓ Ping successful"
    else
        echo "⚠ Ping failed (may be blocked by security group)"
    fi
    echo ""
    
    echo "Test 2: TCP Port 80 (HTTP)"
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$RESOLVED_IP/80" 2>/dev/null; then
        echo "✓ Port 80 is open"
    else
        echo "⚠ Port 80 is closed or filtered"
    fi
    echo ""
    
    echo "Test 3: HTTP Request"
    if curl -s -m 5 http://$RESOLVED_IP 2>&1 | head -10; then
        echo "✓ HTTP request successful"
    else
        echo "⚠ HTTP request failed"
    fi
else
    echo "⚠ Cannot resolve $DOMAIN - skipping connectivity tests"
fi

# 8. DNS Server Reachability
print_section "8. DNS Server Reachability"

DNS_SERVER=$(grep nameserver /etc/resolv.conf | head -1 | awk '{print $2}')
echo "DNS Server: $DNS_SERVER"
echo ""

echo "Test 1: Ping DNS Server"
if ping -c 3 -W 2 $DNS_SERVER 2>&1; then
    echo "✓ DNS server is reachable"
else
    echo "⚠ DNS server is not reachable"
fi
echo ""

echo "Test 2: Query DNS Server Directly"
dig @$DNS_SERVER $DOMAIN +short 2>&1 || echo "⚠ Direct query failed"

# 9. Alternative DNS Servers
print_section "9. Alternative DNS Server Tests"

echo "Test 1: Google DNS (8.8.8.8)"
dig @8.8.8.8 $DOMAIN +short 2>&1 || echo "⚠ Query to Google DNS failed (expected for private zones)"
echo ""

echo "Test 2: Cloudflare DNS (1.1.1.1)"
dig @1.1.1.1 $DOMAIN +short 2>&1 || echo "⚠ Query to Cloudflare DNS failed (expected for private zones)"
echo ""

echo "Note: Private hosted zones only resolve within associated VPCs"
echo "External DNS servers (8.8.8.8, 1.1.1.1) cannot resolve private domains"

# 10. DNS Timing Analysis
print_section "10. DNS Query Performance"

echo "Measuring DNS query time (5 iterations)..."
for i in {1..5}; do
    echo -n "Query $i: "
    time dig $DOMAIN +short >/dev/null 2>&1
done

# 11. Security Group Check
print_section "11. Security Group Information"

INSTANCE_ID=$(ec2-metadata --instance-id 2>/dev/null | cut -d' ' -f2 || echo 'N/A')

if [ "$INSTANCE_ID" != "N/A" ]; then
    echo "Instance ID: $INSTANCE_ID"
    echo ""
    echo "Note: Use AWS CLI or Console to verify security group rules:"
    echo "  aws ec2 describe-security-groups --group-ids <sg-id>"
    echo ""
    echo "Required rules for Instance A (web server):"
    echo "  - Inbound: HTTP (80) from VPC CIDR or 0.0.0.0/0"
    echo "  - Inbound: SSH (22) from admin IP"
    echo ""
    echo "Required rules for Instance B (test client):"
    echo "  - Outbound: All traffic (default)"
else
    echo "Cannot determine instance ID"
fi

# 12. Common Issues Checklist
print_section "12. Common Issues Checklist"

echo "Checking for common DNS issues..."
echo ""

# Check if domain resolves
if dig +short $DOMAIN >/dev/null 2>&1; then
    echo "✓ DNS resolution works"
else
    echo "✗ DNS resolution failed"
    echo "  Possible causes:"
    echo "  - Private hosted zone not created"
    echo "  - Hosted zone not associated with VPC"
    echo "  - A record not created or incorrect"
    echo "  - VPC DNS support disabled"
    echo "  - DNS propagation delay (wait 5-10 minutes)"
fi
echo ""

# Check if HTTP works
if [ -n "$RESOLVED_IP" ] && curl -s -m 5 http://$DOMAIN >/dev/null 2>&1; then
    echo "✓ HTTP connectivity works"
else
    echo "✗ HTTP connectivity failed"
    echo "  Possible causes:"
    echo "  - Security group blocking port 80"
    echo "  - httpd service not running"
    echo "  - Network ACL blocking traffic"
    echo "  - Instance not in running state"
fi
echo ""

# Check DNS resolver
if grep -q "nameserver 10.0" /etc/resolv.conf; then
    echo "✓ Using VPC DNS resolver"
else
    echo "⚠ Not using VPC DNS resolver"
    echo "  Expected: nameserver 10.0.x.2"
    echo "  Actual: $(grep nameserver /etc/resolv.conf)"
fi
echo ""

# 13. Recommendations
print_section "13. Troubleshooting Recommendations"

echo "If DNS resolution is not working:"
echo ""
echo "1. Verify Route 53 Configuration:"
echo "   - Private hosted zone exists for $ZONE"
echo "   - Hosted zone is associated with your VPC"
echo "   - A record exists for $DOMAIN"
echo "   - A record points to correct IP address"
echo ""
echo "2. Verify VPC Configuration:"
echo "   - VPC has DNS support enabled (enableDnsSupport=true)"
echo "   - VPC has DNS hostnames enabled (enableDnsHostnames=true)"
echo "   - Instance is in the correct VPC"
echo ""
echo "3. Wait for DNS Propagation:"
echo "   - New records take 1-5 minutes to propagate"
echo "   - DNS cache TTL is typically 300 seconds (5 minutes)"
echo "   - Clear DNS cache: sudo systemd-resolve --flush-caches"
echo ""
echo "4. Check Network Configuration:"
echo "   - Security groups allow required traffic"
echo "   - Network ACLs allow traffic"
echo "   - Route tables are correct"
echo ""
echo "5. Verify Instance Configuration:"
echo "   - Instance A has Elastic IP associated"
echo "   - httpd service is running on Instance A"
echo "   - Both instances are in the same VPC"
echo ""

# 14. Summary
print_section "14. Summary"

if [ -n "$RESOLVED_IP" ] && curl -s -m 5 http://$DOMAIN >/dev/null 2>&1; then
    echo "✓ DNS and HTTP connectivity are working correctly"
    echo ""
    echo "Configuration Summary:"
    echo "  Domain: $DOMAIN"
    echo "  Resolved IP: $RESOLVED_IP"
    echo "  DNS Server: $DNS_SERVER"
    echo "  Status: HEALTHY"
else
    echo "⚠ Issues detected with DNS or HTTP connectivity"
    echo ""
    echo "Review the troubleshooting sections above for details"
    echo "Follow the recommendations in section 13"
fi

echo ""
echo "=========================================="
echo "Troubleshooting completed at: $(date)"
echo "=========================================="
echo ""
