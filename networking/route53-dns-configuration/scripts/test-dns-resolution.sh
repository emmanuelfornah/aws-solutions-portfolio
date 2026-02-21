#!/bin/bash
# DNS Resolution Testing Script for Instance B
# Tests DNS resolution and connectivity to Instance A via Route 53

set -e  # Exit on error

# Configuration
DOMAIN="www.anycompany.corp"
EXPECTED_ZONE="anycompany.corp"

echo "=========================================="
echo "Route 53 DNS Resolution Test"
echo "=========================================="
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo "----------------------------------------"
    echo "$1"
    echo "----------------------------------------"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Test 1: Check DNS resolver configuration
print_section "1. DNS Resolver Configuration"
echo "Checking /etc/resolv.conf..."
cat /etc/resolv.conf
echo ""
echo "Expected nameserver: 10.0.0.2 (VPC DNS Resolver)"

# Test 2: Basic DNS lookup with nslookup
print_section "2. Basic DNS Lookup (nslookup)"
if command_exists nslookup; then
    echo "Testing: nslookup $DOMAIN"
    nslookup $DOMAIN || echo "⚠ DNS resolution failed"
else
    echo "⚠ nslookup not available"
fi

# Test 3: Detailed DNS query with dig
print_section "3. Detailed DNS Query (dig)"
if command_exists dig; then
    echo "Testing: dig $DOMAIN"
    dig $DOMAIN
    echo ""
    echo "Key information:"
    dig $DOMAIN +short
else
    echo "⚠ dig not available, installing bind-utils..."
    sudo yum install bind-utils -y
    dig $DOMAIN
fi

# Test 4: Simple DNS lookup with host
print_section "4. Simple DNS Lookup (host)"
if command_exists host; then
    echo "Testing: host $DOMAIN"
    host $DOMAIN || echo "⚠ DNS resolution failed"
else
    echo "⚠ host command not available"
fi

# Test 5: DNS cache statistics
print_section "5. DNS Cache Statistics"
if command_exists systemd-resolve; then
    echo "Checking DNS cache statistics..."
    systemd-resolve --statistics || echo "⚠ Statistics not available"
else
    echo "⚠ systemd-resolve not available on this system"
fi

# Test 6: HTTP connectivity test
print_section "6. HTTP Connectivity Test"
if command_exists curl; then
    echo "Testing HTTP connection to $DOMAIN..."
    echo ""
    
    # Test with verbose output
    echo "Attempting: curl -v http://$DOMAIN"
    if curl -v -m 10 http://$DOMAIN 2>&1 | head -20; then
        echo ""
        echo "✓ HTTP connection successful!"
        echo ""
        echo "Fetching page content:"
        curl -s http://$DOMAIN | grep -o "<title>.*</title>" || echo "Page content retrieved"
    else
        echo "⚠ HTTP connection failed"
        echo "Possible issues:"
        echo "  - DNS resolution not working"
        echo "  - Security group blocking HTTP (port 80)"
        echo "  - Web server not running on Instance A"
        echo "  - Network connectivity issues"
    fi
else
    echo "⚠ curl not available"
fi

# Test 7: Network connectivity test
print_section "7. Network Connectivity (ping)"
echo "Testing network connectivity to $DOMAIN..."
if ping -c 4 $DOMAIN 2>/dev/null; then
    echo "✓ Network connectivity successful!"
else
    echo "⚠ Ping failed (may be blocked by security group)"
fi

# Test 8: DNS query timing
print_section "8. DNS Query Performance"
echo "Measuring DNS query time..."
time nslookup $DOMAIN > /dev/null 2>&1 || echo "⚠ DNS query failed"

# Test 9: Verify DNS zone
print_section "9. DNS Zone Verification"
echo "Checking if domain belongs to expected zone..."
if dig $DOMAIN | grep -q "$EXPECTED_ZONE"; then
    echo "✓ Domain belongs to zone: $EXPECTED_ZONE"
else
    echo "⚠ Domain zone mismatch or not found"
fi

# Test 10: Summary
print_section "10. Test Summary"
echo ""

# Get resolved IP
RESOLVED_IP=$(dig +short $DOMAIN 2>/dev/null | head -1)

if [ -n "$RESOLVED_IP" ]; then
    echo "✓ DNS Resolution: SUCCESS"
    echo "  Domain: $DOMAIN"
    echo "  Resolved IP: $RESOLVED_IP"
    echo ""
    
    # Test HTTP connectivity
    if curl -s -m 5 http://$DOMAIN > /dev/null 2>&1; then
        echo "✓ HTTP Connectivity: SUCCESS"
        echo "  URL: http://$DOMAIN"
        echo ""
        echo "=========================================="
        echo "🎉 All tests passed!"
        echo "=========================================="
        echo ""
        echo "Your Route 53 DNS configuration is working correctly."
        echo "Instance B can successfully resolve and connect to Instance A"
        echo "using the private hosted zone domain: $DOMAIN"
    else
        echo "⚠ HTTP Connectivity: FAILED"
        echo ""
        echo "DNS resolution works, but HTTP connection failed."
        echo "Check:"
        echo "  1. Instance A security group allows HTTP (port 80)"
        echo "  2. httpd service is running on Instance A"
        echo "  3. Network ACLs allow traffic"
    fi
else
    echo "✗ DNS Resolution: FAILED"
    echo ""
    echo "DNS resolution is not working. Check:"
    echo "  1. Private hosted zone exists for $EXPECTED_ZONE"
    echo "  2. Hosted zone is associated with this VPC"
    echo "  3. A record exists for $DOMAIN"
    echo "  4. VPC has DNS support enabled"
    echo "  5. Wait 5-10 minutes for DNS propagation"
fi

echo ""
echo "=========================================="
echo "Test completed at: $(date)"
echo "=========================================="
echo ""
