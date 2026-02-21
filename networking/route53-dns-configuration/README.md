# Configuring DNS on Amazon EC2

## Overview

This lab provides hands-on experience with Amazon Route 53 private hosted zones and DNS configuration for EC2 instances within a VPC. The lab demonstrates how to create custom internal DNS names that resolve within your VPC without exposing them to the public internet, enabling clean service discovery and internal communication patterns.

**Lab Type**: Hands-on configuration and testing  
**Difficulty**: Intermediate  
**Estimated Time**: 45 minutes

## AWS Services Used

- **Amazon Route 53** - Scalable DNS web service for domain name management
- **Amazon EC2** - Virtual servers for hosting applications and testing DNS resolution
- **Amazon VPC** - Isolated virtual network for secure resource deployment
- **Elastic IP** - Static IPv4 address for consistent instance addressing

## Key Technologies

- **DNS (Domain Name System)** - Hierarchical naming system for network resources
- **Private Hosted Zones** - Internal DNS namespaces for VPC resources
- **A Records** - DNS records mapping hostnames to IPv4 addresses
- **Route 53 Resolver** - Built-in DNS resolution service in each Availability Zone
- **httpd (Apache)** - Web server for testing DNS-based connectivity

## Architecture Overview

The lab creates a VPC with two EC2 instances and a private hosted zone for internal DNS resolution:

```
VPC (AnyCompany VPC)
├── Instance A (Web Server)
│   ├── Elastic IP: [REDACTED]
│   ├── Private IP: 10.0.x.x
│   └── httpd web server running
│
├── Instance B (Test Client)
│   └── Private IP: 10.0.x.x
│
└── Route 53 Private Hosted Zone
    ├── Domain: anycompany.corp
    ├── A Record: www.anycompany.corp → Instance A Elastic IP
    └── Routing Policy: Simple
```

**Key Components**:
- **Instance A**: EC2 instance with Elastic IP running Apache httpd web server
- **Instance B**: EC2 instance used for testing DNS resolution
- **Private Hosted Zone**: anycompany.corp domain associated with VPC
- **A Record**: Maps www.anycompany.corp to Instance A's Elastic IP
- **Route 53 Resolver**: Automatically resolves DNS queries within VPC

**DNS Resolution Flow**:
1. Instance B queries www.anycompany.corp
2. Route 53 Resolver intercepts query within VPC
3. Resolver checks private hosted zone for anycompany.corp
4. A record returns Instance A's Elastic IP address
5. Instance B connects to Instance A using resolved IP

## Objectives

By completing this lab, you will:

1. ✅ Launch an Amazon EC2 instance in a VPC
2. ✅ Allocate and associate an Elastic IP address to an EC2 instance
3. ✅ Install and configure Apache httpd web server on EC2
4. ✅ Create a Route 53 private hosted zone for a custom domain
5. ✅ Associate a private hosted zone with a VPC
6. ✅ Create DNS A records with simple routing policy
7. ✅ Test DNS resolution from within the VPC
8. ✅ Verify reachability of services using custom DNS names
9. ✅ Understand DNS propagation timing and behavior
10. ✅ Configure internal service discovery patterns

## Key Learnings

### Route 53 Private Hosted Zones
- **Internal DNS**: Custom domain names that resolve only within associated VPCs
- **No Internet Exposure**: DNS records remain private and inaccessible from public internet
- **Multi-VPC Support**: Single hosted zone can be associated with multiple VPCs
- **Cross-Account**: Can associate hosted zones with VPCs in different AWS accounts
- **Cost-Effective**: $0.50/month per hosted zone, $0.40 per million queries

### DNS Record Types and Routing
- **A Records**: Map hostnames to IPv4 addresses (most common)
- **AAAA Records**: Map hostnames to IPv6 addresses
- **CNAME Records**: Alias one hostname to another
- **Simple Routing**: Single resource with one or more IP addresses
- **Weighted Routing**: Distribute traffic across multiple resources
- **Failover Routing**: Active-passive failover configurations

### Elastic IP Benefits
- **Static Addressing**: IP address persists across instance stops/starts
- **Remapping**: Can quickly remap to different instances for failover
- **DNS Stability**: A records don't need updates when instances restart
- **Cost**: Free when associated with running instance, $0.005/hour when idle
- **Limits**: 5 Elastic IPs per region by default (can request increase)

### Route 53 Resolver Architecture
- **Built-in Service**: Automatically available in every VPC at VPC+2 address
- **Availability Zone Redundancy**: Resolver endpoints in each AZ
- **Hybrid DNS**: Can forward queries to on-premises DNS servers
- **Query Logging**: Optional logging to CloudWatch Logs for auditing
- **DNSSEC Validation**: Supports DNS Security Extensions

### DNS Propagation and TTL
- **Propagation Time**: Route 53 changes typically propagate in 60 seconds
- **TTL (Time to Live)**: Controls how long DNS records are cached
- **Default TTL**: 300 seconds (5 minutes) for most record types
- **Low TTL**: Faster updates but higher query costs
- **High TTL**: Better performance but slower updates

### VPC DNS Configuration
- **enableDnsHostnames**: Assigns public DNS hostnames to instances with public IPs
- **enableDnsSupport**: Enables DNS resolution via Route 53 Resolver
- **VPC+2 Address**: DNS server at base VPC CIDR + 2 (e.g., 10.0.0.2 for 10.0.0.0/16)
- **Custom DNS**: Can configure custom DNS servers via DHCP option sets
- **Split-Horizon DNS**: Different responses for internal vs external queries

### Internal Service Discovery Patterns
- **Microservices**: Each service gets a DNS name (api.internal, db.internal)
- **Environment Separation**: dev.internal, staging.internal, prod.internal
- **Load Balancer Integration**: Point DNS to ALB/NLB for high availability
- **Service Mesh**: DNS-based service discovery for containerized workloads
- **Database Endpoints**: Friendly names for RDS, ElastiCache, etc.

## Setup Instructions

### Prerequisites

- AWS account with appropriate permissions
- Access to AWS Management Console
- Basic understanding of VPC networking
- Familiarity with EC2 instance management
- Understanding of DNS concepts

### Step 1: Create EC2 Instance (Instance A)

Launch an EC2 instance in the AnyCompany VPC:

1. Navigate to **EC2 Console** → **Instances** → **Launch Instance**
2. Configure instance:
   - **Name**: Instance A
   - **AMI**: Amazon Linux 2023 (or Amazon Linux 2)
   - **Instance Type**: t2.micro (Free Tier eligible)
   - **VPC**: AnyCompany VPC
   - **Subnet**: Public subnet in any AZ
   - **Auto-assign Public IP**: Enable
   - **Security Group**: Allow HTTP (80) and SSH (22)
3. Launch instance and wait for status checks to pass

### Step 2: Allocate and Associate Elastic IP

Create a static IP address for Instance A:

1. Navigate to **EC2 Console** → **Elastic IPs** → **Allocate Elastic IP address**
2. Click **Allocate**
3. Select the new Elastic IP → **Actions** → **Associate Elastic IP address**
4. Configure association:
   - **Resource type**: Instance
   - **Instance**: Select Instance A
   - **Private IP**: Select instance's private IP
5. Click **Associate**

**Result**: Instance A now has a static public IP that persists across restarts.

### Step 3: Install and Configure httpd Web Server

Connect to Instance A and install Apache:

```bash
# Connect via EC2 Instance Connect or SSH
ssh -i your-key.pem ec2-user@[ELASTIC-IP]

# Update system packages
sudo yum update -y

# Install Apache httpd
sudo yum install httpd -y

# Start httpd service
sudo systemctl start httpd

# Enable httpd to start on boot
sudo systemctl enable httpd

# Verify httpd is running
sudo systemctl status httpd

# Create a simple test page
echo "<h1>Hello from Instance A</h1>" | sudo tee /var/www/html/index.html

# Test locally
curl localhost
```

**Verification**: Access http://[ELASTIC-IP] in browser to see test page.

### Step 4: Create Private Hosted Zone

Create a Route 53 private hosted zone for your domain:

1. Navigate to **Route 53 Console** → **Hosted zones** → **Create hosted zone**
2. Configure hosted zone:
   - **Domain name**: anycompany.corp
   - **Description**: Private DNS for AnyCompany VPC
   - **Type**: Private hosted zone
   - **VPCs to associate**: Select AnyCompany VPC and region
3. Click **Create hosted zone**

**Result**: Private hosted zone created with NS and SOA records automatically.

**Important Notes**:
- Private hosted zones only resolve within associated VPCs
- You can use any domain name (doesn't need to be registered)
- Common patterns: .internal, .local, .corp, .private
- Can associate with multiple VPCs after creation

### Step 5: Create A Record for Instance A

Add a DNS record pointing to Instance A:

1. In the **anycompany.corp** hosted zone, click **Create record**
2. Configure record:
   - **Record name**: www
   - **Record type**: A - Routes traffic to an IPv4 address
   - **Value**: [Instance A Elastic IP]
   - **TTL**: 300 seconds (default)
   - **Routing policy**: Simple routing
3. Click **Create records**

**Result**: www.anycompany.corp now resolves to Instance A's Elastic IP within the VPC.

**DNS Record Details**:
- **FQDN**: www.anycompany.corp
- **Type**: A (IPv4 address)
- **Value**: Instance A's Elastic IP
- **TTL**: 300 seconds (5 minutes)
- **Routing**: Simple (single target)

### Step 6: Test DNS Resolution Before Configuration

From Instance B, test DNS before creating the record (should fail):

```bash
# Connect to Instance B
ssh -i your-key.pem ec2-user@[INSTANCE-B-IP]

# Test DNS resolution (should fail or return NXDOMAIN)
nslookup www.anycompany.corp

# Test with dig
dig www.anycompany.corp

# Expected result: NXDOMAIN (domain doesn't exist)
```

### Step 7: Test DNS Resolution After Configuration

After creating the A record, test DNS resolution:

```bash
# Wait 5-10 minutes for DNS propagation
# Test DNS resolution (should succeed)
nslookup www.anycompany.corp

# Expected output:
# Server:    10.0.0.2
# Address:   10.0.0.2#53
# 
# Name:      www.anycompany.corp
# Address:   [ELASTIC-IP]

# Test with dig for detailed information
dig www.anycompany.corp

# Test with host command
host www.anycompany.corp

# Verify the resolved IP matches Instance A's Elastic IP
```

**Troubleshooting DNS Resolution**:
- If resolution fails, wait 5-10 minutes for propagation
- Verify VPC has DNS support enabled
- Check that hosted zone is associated with correct VPC
- Ensure Instance B is in the same VPC
- Verify A record was created correctly

### Step 8: Test Reachability via DNS Name

Verify you can reach Instance A using the DNS name:

```bash
# From Instance B, test HTTP connectivity
curl http://www.anycompany.corp

# Expected output: <h1>Hello from Instance A</h1>

# Test with wget
wget -O - http://www.anycompany.corp

# Test DNS-based ping
ping www.anycompany.corp

# Verify response comes from correct IP
```

**Success Criteria**:
- DNS name resolves to Instance A's Elastic IP
- HTTP request returns Instance A's web page
- Ping shows connectivity to correct IP address

### Step 9: Verify DNS Configuration

Check DNS configuration details:

```bash
# View DNS resolver configuration
cat /etc/resolv.conf

# Expected output:
# nameserver 10.0.0.2  (VPC DNS resolver)
# search [region].compute.internal

# Test DNS query path
dig +trace www.anycompany.corp

# View DNS cache (if using systemd-resolved)
systemd-resolve --status

# Clear DNS cache if needed
sudo systemd-resolve --flush-caches
```

### Step 10: Test DNS Propagation Timing

Observe DNS propagation behavior:

```bash
# Immediately after creating record, test resolution
nslookup www.anycompany.corp

# If it fails, wait 1 minute and retry
sleep 60
nslookup www.anycompany.corp

# Continue testing every minute until resolution succeeds
# Typical propagation: 1-5 minutes
# Maximum propagation: 10 minutes
```

**DNS Propagation Factors**:
- Route 53 internal propagation: ~60 seconds
- DNS cache TTL: 300 seconds (5 minutes)
- Resolver cache: May cache negative responses
- Network latency: Minimal within AWS

## Configuration Files

### DNS Record Configuration

The A record configuration for www.anycompany.corp:

```json
{
  "Name": "www.anycompany.corp",
  "Type": "A",
  "TTL": 300,
  "ResourceRecords": [
    {
      "Value": "[ELASTIC-IP]"
    }
  ],
  "RoutingPolicy": "Simple"
}
```

### VPC DNS Settings

Required VPC configuration for private hosted zones:

```json
{
  "EnableDnsHostnames": true,
  "EnableDnsSupport": true,
  "DnsServers": ["AmazonProvidedDNS"]
}
```

**Configuration Notes**:
- **EnableDnsSupport**: Must be true for Route 53 Resolver to work
- **EnableDnsHostnames**: Assigns DNS names to instances with public IPs
- **AmazonProvidedDNS**: Route 53 Resolver at VPC+2 address

### httpd Configuration

Basic Apache configuration on Instance A:

```bash
# httpd service configuration
sudo systemctl enable httpd
sudo systemctl start httpd

# Firewall configuration (if using firewalld)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

# Document root
/var/www/html/

# Configuration file
/etc/httpd/conf/httpd.conf

# Logs
/var/log/httpd/access_log
/var/log/httpd/error_log
```

## Troubleshooting

### Common Issues

**Issue**: DNS resolution fails from Instance B  
**Solution**: 
- Verify VPC has DNS support enabled (enableDnsSupport=true)
- Check hosted zone is associated with correct VPC
- Ensure Instance B is in the same VPC
- Wait 5-10 minutes for DNS propagation
- Verify A record was created correctly

**Issue**: DNS resolves but HTTP connection fails  
**Solution**:
- Check Instance A security group allows HTTP (port 80)
- Verify httpd service is running on Instance A
- Test local connectivity on Instance A: `curl localhost`
- Check Instance A's network ACLs allow traffic

**Issue**: DNS resolves to wrong IP address  
**Solution**:
- Verify A record value matches Instance A's Elastic IP
- Check for duplicate records in hosted zone
- Clear DNS cache on Instance B
- Wait for TTL to expire (300 seconds)

**Issue**: Elastic IP association fails  
**Solution**:
- Verify you haven't exceeded Elastic IP limit (5 per region)
- Check instance is in running state
- Ensure instance is in VPC (not EC2-Classic)
- Verify IAM permissions for EC2 operations

**Issue**: Private hosted zone not resolving  
**Solution**:
- Verify hosted zone type is "Private"
- Check VPC association is correct
- Ensure VPC DNS settings are enabled
- Verify no conflicting DHCP option sets

### Debugging Commands

```bash
# Test DNS resolution
nslookup www.anycompany.corp
dig www.anycompany.corp
host www.anycompany.corp

# Check DNS resolver configuration
cat /etc/resolv.conf

# Test HTTP connectivity
curl -v http://www.anycompany.corp
wget --spider http://www.anycompany.corp

# Check network connectivity
ping www.anycompany.corp
traceroute www.anycompany.corp

# View DNS cache
systemd-resolve --statistics
systemd-resolve --status

# Clear DNS cache
sudo systemd-resolve --flush-caches

# Test from Instance A (should resolve)
ssh instance-a
nslookup www.anycompany.corp
```

### Verification Checklist

- [ ] Instance A is running with Elastic IP associated
- [ ] httpd service is running on Instance A
- [ ] Security group allows HTTP (80) and SSH (22)
- [ ] Private hosted zone created for anycompany.corp
- [ ] Hosted zone associated with AnyCompany VPC
- [ ] A record created: www.anycompany.corp → Elastic IP
- [ ] VPC has DNS support enabled
- [ ] Instance B can resolve www.anycompany.corp
- [ ] Instance B can access http://www.anycompany.corp
- [ ] DNS resolution returns correct Elastic IP

## Cost Considerations

**Route 53 Costs**:
- Private hosted zone: $0.50/month
- DNS queries: $0.40 per million queries
- Health checks: $0.50/month per health check (not used in this lab)

**EC2 Costs**:
- t2.micro instances: Free Tier eligible (750 hours/month first year)
- After Free Tier: ~$0.0116/hour per instance
- Elastic IP: Free when associated with running instance
- Elastic IP (unassociated): $0.005/hour

**Data Transfer**:
- Within same AZ: Free
- Between AZs: $0.01/GB
- To internet: $0.09/GB (first 10TB/month)

**Monthly Cost Estimate** (after Free Tier):
- 2 x t2.micro instances: ~$17/month
- 1 x Private hosted zone: $0.50/month
- DNS queries (typical): <$1/month
- **Total**: ~$18.50/month

**Cost Optimization Tips**:
- Stop instances when not in use
- Release Elastic IPs when not needed
- Delete hosted zones after lab completion
- Use Free Tier for learning and testing

## Next Steps

### Enhancements

1. **Add More Records**: Create additional A records for different services
2. **CNAME Records**: Create aliases (api.anycompany.corp → www.anycompany.corp)
3. **Weighted Routing**: Distribute traffic across multiple instances
4. **Health Checks**: Add Route 53 health checks for failover
5. **Multi-VPC**: Associate hosted zone with multiple VPCs
6. **Hybrid DNS**: Configure Route 53 Resolver endpoints for on-premises integration
7. **DNSSEC**: Enable DNS Security Extensions for validation
8. **Query Logging**: Enable Route 53 query logging to CloudWatch

### Related Labs

- **VPC Connectivity Troubleshooting**: Network connectivity and routing
- **Network Access Analyzer**: VPC network path analysis
- **Elastic Load Balancing**: Combine DNS with load balancers
- **Multi-Tier Architecture**: Use DNS for service discovery

### Real-World Use Cases

- **Microservices**: Internal service discovery (auth.internal, api.internal)
- **Database Endpoints**: Friendly names for RDS instances
- **Environment Separation**: dev.corp, staging.corp, prod.corp
- **Hybrid Cloud**: DNS resolution between AWS and on-premises
- **Container Orchestration**: Service discovery for ECS/EKS
- **Multi-Region**: Route 53 for cross-region DNS resolution

## Certification Alignment

This lab aligns with the following AWS certification topics:

**AWS Certified Solutions Architect - Associate**:
- Domain 1: Design Resilient Architectures (Route 53, Elastic IP)
- Domain 2: Design High-Performing Architectures (DNS optimization)
- Domain 3: Design Secure Applications (Private hosted zones, VPC DNS)
- Domain 4: Design Cost-Optimized Architectures (Route 53 pricing)

**AWS Certified Advanced Networking - Specialty**:
- Domain 1: Network Design (DNS architecture, private hosted zones)
- Domain 2: Network Implementation (Route 53 configuration)
- Domain 3: Network Management (DNS troubleshooting)
- Domain 4: Network Security (Private DNS, VPC isolation)

**AWS Certified Developer - Associate**:
- Domain 3: Development with AWS Services (Route 53 API)
- Domain 4: Refactoring (Service discovery patterns)

## Resources

- [Amazon Route 53 Documentation](https://docs.aws.amazon.com/route53/)
- [Private Hosted Zones](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-private.html)
- [Creating a Private Hosted Zone](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zone-private-creating.html)
- [Configuring Route 53 to Route Traffic to EC2](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-to-ec2-instance.html)
- [Route 53 Resolver](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resolver.html)
- [VPC DNS Configuration](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html)
- [Elastic IP Addresses](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html)

## Tags

`AWS` `Route-53` `DNS` `Private-Hosted-Zone` `EC2` `VPC` `Elastic-IP` `Networking` `Service-Discovery` `A-Record` `httpd` `Apache` `Internal-DNS` `DNS-Resolution` `Route-53-Resolver`

---

**Lab Completed**: AWS Cloud Fundamentals  
**Domain**: Networking  
**Complexity**: Intermediate  
**Last Updated**: 2024
