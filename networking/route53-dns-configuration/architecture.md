# Architecture: Route 53 DNS Configuration Lab

## Overview

This document provides detailed architecture information for the Route 53 DNS configuration lab, including component relationships, DNS resolution flow, and design patterns for internal service discovery.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    AnyCompany VPC                           │ │
│  │                   CIDR: 10.0.0.0/16                         │ │
│  │                                                              │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │              Public Subnet (10.0.1.0/24)             │  │ │
│  │  │                                                        │  │ │
│  │  │  ┌─────────────────────┐    ┌─────────────────────┐  │  │ │
│  │  │  │    Instance A       │    │    Instance B       │  │  │ │
│  │  │  │  ┌───────────────┐  │    │  ┌───────────────┐  │  │ │ │
│  │  │  │  │ httpd Server  │  │    │  │  Test Client  │  │  │ │ │
│  │  │  │  └───────────────┘  │    │  └───────────────┘  │  │ │ │
│  │  │  │                     │    │                     │  │  │ │
│  │  │  │ Private: 10.0.1.x   │    │ Private: 10.0.1.y   │  │  │ │
│  │  │  │ Public: [EIP]       │    │ Public: [Dynamic]   │  │  │ │
│  │  │  └─────────────────────┘    └─────────────────────┘  │  │ │
│  │  │           │                           │               │  │ │
│  │  └───────────┼───────────────────────────┼───────────────┘  │ │
│  │              │                           │                  │ │
│  │              │                           │                  │ │
│  │  ┌───────────▼───────────────────────────▼───────────────┐ │ │
│  │  │           Route 53 Resolver (10.0.0.2)                │ │ │
│  │  │         Built-in DNS service at VPC+2                 │ │ │
│  │  └───────────────────────────┬───────────────────────────┘ │ │
│  │                              │                              │ │
│  └──────────────────────────────┼──────────────────────────────┘ │
│                                 │                                │
│  ┌──────────────────────────────▼──────────────────────────────┐ │
│  │         Route 53 Private Hosted Zone                        │ │
│  │              anycompany.corp                                │ │
│  │                                                              │ │
│  │  ┌────────────────────────────────────────────────────────┐ │ │
│  │  │  A Record: www.anycompany.corp                         │ │ │
│  │  │  Type: A (IPv4)                                        │ │ │
│  │  │  Value: [Instance A Elastic IP]                        │ │ │
│  │  │  TTL: 300 seconds                                      │ │ │
│  │  │  Routing: Simple                                       │ │ │
│  │  └────────────────────────────────────────────────────────┘ │ │
│  │                                                              │ │
│  │  Associated VPCs: AnyCompany VPC                            │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘

Internet Gateway
      │
      ▼
[Instance A Elastic IP] ◄─── Public access to web server
```

## Component Details

### 1. VPC (AnyCompany VPC)

**Purpose**: Isolated virtual network for hosting EC2 instances and private DNS

**Configuration**:
- **CIDR Block**: 10.0.0.0/16 (65,536 IP addresses)
- **DNS Support**: Enabled (enableDnsSupport=true)
- **DNS Hostnames**: Enabled (enableDnsHostnames=true)
- **DHCP Options**: Default (AmazonProvidedDNS)
- **Tenancy**: Default (shared hardware)

**DNS Settings**:
- **DNS Server**: 10.0.0.2 (VPC base + 2)
- **DNS Domain**: [region].compute.internal
- **Resolver**: Route 53 Resolver (built-in)

### 2. Public Subnet

**Purpose**: Hosts EC2 instances with internet connectivity

**Configuration**:
- **CIDR Block**: 10.0.1.0/24 (256 IP addresses)
- **Availability Zone**: Single AZ (can be multi-AZ)
- **Auto-assign Public IP**: Enabled
- **Route Table**: Routes 0.0.0.0/0 to Internet Gateway

**Network ACL**: Default (allows all inbound/outbound)

### 3. Instance A (Web Server)

**Purpose**: Hosts Apache httpd web server, target of DNS A record

**Configuration**:
- **AMI**: Amazon Linux 2023 or Amazon Linux 2
- **Instance Type**: t2.micro (1 vCPU, 1 GB RAM)
- **Private IP**: 10.0.1.x (assigned by VPC DHCP)
- **Elastic IP**: Static public IPv4 address
- **Security Group**: Allow HTTP (80), SSH (22)

**Software Stack**:
- **OS**: Amazon Linux 2023
- **Web Server**: Apache httpd 2.4
- **Content**: Simple HTML test page

**Network Interfaces**:
- **eth0**: Primary network interface
  - Private IP: 10.0.1.x
  - Public IP: Elastic IP (static)
  - DNS Name: ec2-[ip].compute.amazonaws.com

### 4. Instance B (Test Client)

**Purpose**: Tests DNS resolution and connectivity to Instance A

**Configuration**:
- **AMI**: Amazon Linux 2023 or Amazon Linux 2
- **Instance Type**: t2.micro
- **Private IP**: 10.0.1.y
- **Public IP**: Dynamic (optional)
- **Security Group**: Allow SSH (22), outbound HTTP

**DNS Client Tools**:
- **nslookup**: Basic DNS lookup
- **dig**: Detailed DNS query information
- **host**: Simple DNS lookup
- **curl**: HTTP client for testing web connectivity

### 5. Elastic IP

**Purpose**: Provides static public IP for Instance A

**Characteristics**:
- **Type**: IPv4 address
- **Scope**: Regional (persists across AZs)
- **Association**: Bound to Instance A's primary network interface
- **Persistence**: Survives instance stop/start
- **Remapping**: Can be reassociated to different instances

**Benefits**:
- DNS A records remain valid across instance restarts
- Predictable addressing for external access
- Quick failover by remapping to standby instance
- No DNS propagation delay when instance restarts

### 6. Route 53 Private Hosted Zone

**Purpose**: Provides internal DNS namespace for VPC resources

**Configuration**:
- **Domain Name**: anycompany.corp
- **Type**: Private hosted zone
- **Associated VPCs**: AnyCompany VPC
- **Record Count**: 3 (NS, SOA, A record)

**Automatic Records**:
- **NS (Name Server)**: Points to Route 53 name servers
- **SOA (Start of Authority)**: Zone metadata and serial number

**Custom Records**:
- **A Record**: www.anycompany.corp → Instance A Elastic IP

**Visibility**:
- **Internal**: Resolves within associated VPCs only
- **External**: Not accessible from public internet
- **Cross-Account**: Can be shared with other AWS accounts

### 7. DNS A Record

**Purpose**: Maps www.anycompany.corp to Instance A's IP address

**Configuration**:
- **Name**: www.anycompany.corp
- **Type**: A (IPv4 address)
- **Value**: Instance A's Elastic IP
- **TTL**: 300 seconds (5 minutes)
- **Routing Policy**: Simple routing

**Routing Policy Options**:
- **Simple**: Single resource (used in this lab)
- **Weighted**: Distribute traffic by percentage
- **Latency**: Route to lowest latency endpoint
- **Failover**: Active-passive failover
- **Geolocation**: Route based on user location
- **Geoproximity**: Route based on resource location
- **Multi-value**: Return multiple IPs with health checks

### 8. Route 53 Resolver

**Purpose**: Built-in DNS resolution service for VPC

**Architecture**:
- **Location**: Available in each Availability Zone
- **Address**: VPC CIDR base + 2 (e.g., 10.0.0.2)
- **Redundancy**: Highly available across AZs
- **Capacity**: Scales automatically with query volume

**Resolution Logic**:
1. Check if query matches private hosted zone
2. If match, return private hosted zone record
3. If no match, forward to public DNS
4. Cache results based on TTL

**Query Types Handled**:
- Private hosted zone queries (anycompany.corp)
- AWS service endpoints (s3.amazonaws.com)
- Public DNS queries (google.com)
- Reverse DNS lookups (PTR records)

## DNS Resolution Flow

### Step-by-Step Resolution Process

```
┌─────────────┐
│ Instance B  │
│ (Client)    │
└──────┬──────┘
       │
       │ 1. Query: www.anycompany.corp
       │
       ▼
┌─────────────────────────────────────┐
│ /etc/resolv.conf                    │
│ nameserver 10.0.0.2                 │
└──────┬──────────────────────────────┘
       │
       │ 2. Forward to Route 53 Resolver
       │
       ▼
┌─────────────────────────────────────┐
│ Route 53 Resolver (10.0.0.2)        │
│ - Check private hosted zones        │
│ - Check cache                       │
└──────┬──────────────────────────────┘
       │
       │ 3. Query private hosted zone
       │
       ▼
┌─────────────────────────────────────┐
│ Private Hosted Zone                 │
│ anycompany.corp                     │
│ - Lookup: www.anycompany.corp       │
│ - Type: A                           │
└──────┬──────────────────────────────┘
       │
       │ 4. Return A record
       │    Value: [Elastic IP]
       │    TTL: 300 seconds
       │
       ▼
┌─────────────────────────────────────┐
│ Route 53 Resolver                   │
│ - Cache result (300 seconds)        │
│ - Return to client                  │
└──────┬──────────────────────────────┘
       │
       │ 5. DNS Response: [Elastic IP]
       │
       ▼
┌─────────────┐
│ Instance B  │
│ - Receives IP                       │
│ - Initiates HTTP connection         │
└──────┬──────┘
       │
       │ 6. HTTP GET http://[Elastic IP]
       │
       ▼
┌─────────────┐
│ Instance A  │
│ httpd responds with web page        │
└─────────────┘
```

### Resolution Timing

1. **Initial Query**: 10-50ms (first query, no cache)
2. **Cached Query**: 1-5ms (within TTL period)
3. **Cache Miss**: 10-50ms (after TTL expiration)
4. **Propagation**: 60-300 seconds (new/updated records)

### Caching Behavior

**Client-Side Cache**:
- **Location**: systemd-resolved or nscd
- **Duration**: Respects TTL from DNS response
- **Flush**: `sudo systemd-resolve --flush-caches`

**Resolver Cache**:
- **Location**: Route 53 Resolver
- **Duration**: Based on record TTL (300 seconds)
- **Negative Cache**: 60 seconds for NXDOMAIN

**Application Cache**:
- **Location**: Application-specific (e.g., Java DNS cache)
- **Duration**: Varies by application
- **Configuration**: Often configurable via app settings

## Security Architecture

### Network Security

**Security Groups**:

**Instance A Security Group**:
```
Inbound Rules:
- HTTP (80) from 0.0.0.0/0 (or VPC CIDR for internal only)
- SSH (22) from [Admin IP] (restricted)

Outbound Rules:
- All traffic to 0.0.0.0/0 (default)
```

**Instance B Security Group**:
```
Inbound Rules:
- SSH (22) from [Admin IP] (restricted)

Outbound Rules:
- All traffic to 0.0.0.0/0 (allows DNS and HTTP)
```

**Network ACLs**:
- Default NACL allows all inbound/outbound
- Stateless (requires explicit inbound and outbound rules)
- Evaluated before security groups

### DNS Security

**Private Hosted Zone Isolation**:
- DNS records not exposed to public internet
- Only resolves within associated VPCs
- Prevents DNS enumeration attacks
- No external DNS zone transfer

**VPC DNS Protection**:
- DNS queries encrypted within AWS network
- No DNS hijacking risk (AWS-managed resolver)
- DNSSEC validation supported (optional)
- Query logging for audit trail

**Access Control**:
- IAM policies control Route 53 API access
- VPC association requires authorization
- Cross-account sharing requires explicit permission
- CloudTrail logs all Route 53 API calls

### Best Practices

1. **Least Privilege**: Restrict security group rules to minimum required
2. **SSH Bastion**: Use bastion host instead of direct SSH access
3. **DNSSEC**: Enable DNSSEC validation for external queries
4. **Query Logging**: Enable Route 53 query logging for monitoring
5. **IAM Policies**: Use resource-based policies for Route 53 access
6. **VPC Flow Logs**: Monitor network traffic for anomalies

## Scalability and High Availability

### Route 53 Scalability

**Query Capacity**:
- **Throughput**: Unlimited queries per second
- **Latency**: <10ms average query response time
- **Global**: Anycast network with 200+ edge locations
- **Auto-scaling**: Automatic capacity adjustment

**Hosted Zone Limits**:
- **Records per Hosted Zone**: 10,000 (soft limit, can increase)
- **Hosted Zones per Account**: 500 (soft limit, can increase)
- **VPC Associations**: 100 VPCs per hosted zone
- **Query Rate**: No limit

### High Availability Design

**Multi-AZ Deployment**:
```
VPC (10.0.0.0/16)
├── Subnet 1 (us-east-1a): 10.0.1.0/24
│   ├── Instance A1 (Primary)
│   └── Route 53 Resolver Endpoint
│
├── Subnet 2 (us-east-1b): 10.0.2.0/24
│   ├── Instance A2 (Standby)
│   └── Route 53 Resolver Endpoint
│
└── Private Hosted Zone
    └── A Record: www.anycompany.corp
        ├── Value 1: Instance A1 IP (Weight: 70)
        └── Value 2: Instance A2 IP (Weight: 30)
```

**Failover Configuration**:
```
Primary Record:
- Type: A
- Value: Instance A1 IP
- Health Check: HTTP check on port 80
- Failover: Primary

Secondary Record:
- Type: A
- Value: Instance A2 IP
- Health Check: HTTP check on port 80
- Failover: Secondary
```

### Load Balancer Integration

**ALB with Route 53**:
```
Private Hosted Zone: anycompany.corp
└── A Record: www.anycompany.corp
    └── Alias: internal-alb-123.us-east-1.elb.amazonaws.com
        └── Application Load Balancer
            ├── Target Group 1: Instance A1, A2, A3
            └── Health Checks: HTTP /health
```

**Benefits**:
- Automatic failover to healthy instances
- Horizontal scaling without DNS changes
- SSL/TLS termination at load balancer
- Path-based routing for microservices

## Performance Optimization

### DNS Query Optimization

**TTL Tuning**:
- **Low TTL (60s)**: Fast updates, higher query costs
- **Medium TTL (300s)**: Balanced (recommended)
- **High TTL (3600s)**: Lower costs, slower updates

**Caching Strategy**:
- Enable client-side DNS caching
- Use connection pooling to reuse resolved IPs
- Implement application-level DNS caching
- Pre-resolve critical hostnames at startup

### Network Performance

**Placement Groups**:
- Use cluster placement group for low latency
- Instances in same AZ for minimal network hops
- Enhanced networking for higher throughput

**VPC Optimization**:
- Use VPC endpoints for AWS services (bypass internet)
- Enable VPC Flow Logs for traffic analysis
- Optimize security group rules (fewer rules = faster processing)

## Cost Optimization

### Route 53 Costs

**Hosted Zone**:
- $0.50/month per private hosted zone
- First 25 hosted zones: $0.50/month each
- Additional hosted zones: $0.10/month each

**DNS Queries**:
- First 1 billion queries/month: $0.40 per million
- Over 1 billion queries/month: $0.20 per million
- Queries within VPC: Same pricing

**Health Checks** (not used in basic lab):
- AWS endpoint: $0.50/month per health check
- Non-AWS endpoint: $0.75/month per health check

### Cost Comparison

**Scenario**: 10 million DNS queries/month

| Component | Monthly Cost |
|-----------|--------------|
| Private hosted zone | $0.50 |
| DNS queries (10M) | $4.00 |
| **Total** | **$4.50** |

**Alternative**: Self-managed BIND DNS server
- EC2 instance (t3.small): ~$15/month
- Maintenance overhead: High
- High availability: Requires multiple instances

**Recommendation**: Use Route 53 for cost-effectiveness and reliability

## Monitoring and Observability

### CloudWatch Metrics

**Route 53 Metrics**:
- **QueryCount**: Number of DNS queries
- **HealthCheckStatus**: Health check results (if configured)
- **HealthCheckPercentageHealthy**: Percentage of healthy endpoints

**EC2 Metrics**:
- **CPUUtilization**: Instance CPU usage
- **NetworkIn/NetworkOut**: Network traffic
- **StatusCheckFailed**: Instance health status

### Query Logging

**Configuration**:
```json
{
  "HostedZoneId": "Z1234567890ABC",
  "CloudWatchLogsLogGroupArn": "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/anycompany.corp"
}
```

**Log Fields**:
- Query timestamp
- Hosted zone ID
- Query name (www.anycompany.corp)
- Query type (A, AAAA, CNAME, etc.)
- Response code (NOERROR, NXDOMAIN, etc.)
- Source IP (VPC resolver IP)

**Use Cases**:
- Troubleshoot DNS resolution issues
- Audit DNS query patterns
- Detect anomalous query behavior
- Capacity planning

### Alarms

**Recommended CloudWatch Alarms**:

1. **High Query Rate**:
   - Metric: QueryCount
   - Threshold: > 1000 queries/minute
   - Action: SNS notification

2. **Instance Health**:
   - Metric: StatusCheckFailed
   - Threshold: > 0
   - Action: SNS notification, auto-recovery

3. **HTTP Errors**:
   - Metric: HTTPCode_Target_5XX_Count
   - Threshold: > 10 errors/5 minutes
   - Action: SNS notification

## Integration Patterns

### Microservices Architecture

**Service Discovery Pattern**:
```
Private Hosted Zone: services.internal
├── api.services.internal → API Gateway ALB
├── auth.services.internal → Auth Service ALB
├── db.services.internal → RDS Endpoint
└── cache.services.internal → ElastiCache Endpoint
```

**Benefits**:
- Decouples service locations from consumers
- Enables blue/green deployments
- Simplifies configuration management
- Supports multi-environment (dev, staging, prod)

### Hybrid Cloud Integration

**Route 53 Resolver Endpoints**:
```
On-Premises Network
       │
       │ VPN/Direct Connect
       │
       ▼
┌─────────────────────────────┐
│ Route 53 Resolver Endpoints │
│ - Inbound: On-prem → AWS    │
│ - Outbound: AWS → On-prem   │
└─────────────────────────────┘
       │
       ▼
Private Hosted Zones (AWS)
```

**Use Cases**:
- Resolve AWS private DNS from on-premises
- Resolve on-premises DNS from AWS
- Unified DNS namespace across hybrid cloud
- Seamless migration to cloud

### Container Orchestration

**ECS Service Discovery**:
```
ECS Cluster
├── Service: web-app
│   └── DNS: web-app.ecs.internal
│       └── A Records: [Task IPs]
│
└── Service: api-service
    └── DNS: api-service.ecs.internal
        └── A Records: [Task IPs]
```

**Kubernetes (EKS)**:
- CoreDNS for cluster-internal DNS
- ExternalDNS for Route 53 integration
- Service discovery via Kubernetes Services
- Ingress controllers with Route 53 aliases

## Troubleshooting Guide

### DNS Resolution Issues

**Problem**: DNS query returns NXDOMAIN

**Diagnosis**:
```bash
# Check hosted zone association
aws route53 list-hosted-zones-by-vpc --vpc-id vpc-xxx

# Verify A record exists
aws route53 list-resource-record-sets --hosted-zone-id Z123

# Check VPC DNS settings
aws ec2 describe-vpc-attribute --vpc-id vpc-xxx --attribute enableDnsSupport
aws ec2 describe-vpc-attribute --vpc-id vpc-xxx --attribute enableDnsHostnames
```

**Solutions**:
- Associate hosted zone with VPC
- Create missing A record
- Enable VPC DNS support

### Connectivity Issues

**Problem**: DNS resolves but connection fails

**Diagnosis**:
```bash
# Test DNS resolution
nslookup www.anycompany.corp

# Test network connectivity
ping [resolved-ip]
telnet [resolved-ip] 80
curl -v http://www.anycompany.corp

# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxx
```

**Solutions**:
- Update security group rules
- Verify httpd service is running
- Check network ACLs
- Verify route tables

### Performance Issues

**Problem**: Slow DNS resolution

**Diagnosis**:
```bash
# Measure DNS query time
time nslookup www.anycompany.corp

# Check DNS cache
systemd-resolve --statistics

# Test with different DNS servers
dig @10.0.0.2 www.anycompany.corp
dig @8.8.8.8 www.anycompany.corp
```

**Solutions**:
- Enable DNS caching
- Reduce TTL for faster updates
- Use connection pooling
- Implement application-level caching

## References

- [Route 53 Private Hosted Zones](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-private.html)
- [VPC DNS Configuration](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html)
- [Route 53 Resolver](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resolver.html)
- [DNS Best Practices](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/best-practices-dns.html)
