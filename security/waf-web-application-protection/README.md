# Securing a Web Application Using AWS WAF

## Overview

This lab demonstrates protecting web applications from common web exploits using AWS WAF (Web Application Firewall). The implementation includes creating WAF web ACLs with managed rule groups, configuring custom rules for rate limiting and geo-blocking, associating WAF with Application Load Balancer, testing rule effectiveness with simulated attacks, and monitoring blocked requests in CloudWatch.

## AWS Services Used

- **AWS WAF** - Web application firewall protection
- **Application Load Balancer** - Web traffic distribution
- **Amazon CloudWatch** - WAF metrics and logging
- **AWS CloudFormation** - Infrastructure as Code
- **Amazon S3** - WAF log storage

## Key Technologies

- **Web ACL** - Access control lists for web traffic
- **Managed Rule Groups** - AWS and third-party rule sets
- **Rate-Based Rules** - DDoS and brute-force protection
- **Geo-Blocking** - Geographic access control
- **IP Sets** - Allow/deny lists
- **String Matching** - Pattern-based filtering

## Architecture Overview

The architecture implements multi-layer web application protection using AWS WAF integrated with Application Load Balancer. WAF evaluates incoming requests against configured rules including AWS Managed Rules for OWASP Top 10 protection, rate-based rules for DDoS mitigation, geo-blocking rules for regional restrictions, and custom rules for application-specific threats. Blocked requests are logged to CloudWatch and S3 for analysis.

See [architecture.md](./architecture.md) for detailed WAF rule evaluation flow and protection layers.

## Objectives

- Create WAF Web ACL with managed rule groups
- Configure AWS Managed Rules for OWASP protection
- Implement rate-based rules for DDoS mitigation
- Set up geo-blocking for regional restrictions
- Create custom rules for application-specific threats
- Associate WAF with Application Load Balancer
- Test WAF rules with simulated attacks
- Monitor and analyze blocked requests

## Key Learnings

- **WAF Architecture**: Web ACL structure and rule evaluation
- **Managed Rules**: AWS Managed Rules and Marketplace rules
- **Rate Limiting**: Protecting against DDoS and brute-force
- **Geo-Blocking**: Country-based access control
- **Custom Rules**: Application-specific protection
- **Rule Priority**: Order of rule evaluation
- **Logging**: CloudWatch Logs and S3 integration
- **Testing**: Validating WAF effectiveness

## Setup Instructions

### Prerequisites

- AWS account with WAF and ALB permissions
- Existing Application Load Balancer
- Web application deployed behind ALB
- Understanding of web security threats

### Step 1: Create Web ACL

Create WAF Web ACL:

```bash
./scripts/create-web-acl.sh
```

### Step 2: Add Managed Rule Groups

Configure AWS Managed Rules:

```bash
./scripts/add-managed-rules.sh
```

### Step 3: Configure Rate-Based Rules

Set up rate limiting:

```bash
./scripts/configure-rate-limiting.sh
```

### Step 4: Set Up Geo-Blocking

Configure geographic restrictions:

```bash
./scripts/configure-geo-blocking.sh
```

### Step 5: Create Custom Rules

Add application-specific rules:

```bash
./scripts/create-custom-rules.sh
```

### Step 6: Associate with ALB

Attach WAF to load balancer:

```bash
./scripts/associate-with-alb.sh
```

### Step 7: Enable Logging

Configure CloudWatch logging:

```bash
./scripts/enable-logging.sh
```

### Step 8: Test WAF Rules

Simulate attacks and verify blocking:

```bash
./scripts/test-waf-rules.sh
```

## Scripts and Configurations

### Scripts

- **create-web-acl.sh** - Creates WAF Web ACL
- **add-managed-rules.sh** - Adds AWS Managed Rules
- **configure-rate-limiting.sh** - Sets up rate-based rules
- **configure-geo-blocking.sh** - Configures geo restrictions
- **create-custom-rules.sh** - Creates custom rules
- **associate-with-alb.sh** - Attaches WAF to ALB
- **enable-logging.sh** - Enables CloudWatch logging
- **test-waf-rules.sh** - Tests rule effectiveness
- **cleanup.sh** - Removes all resources

### Configuration Files

- **web-acl-config.json** - Web ACL configuration
- **managed-rules.json** - Managed rule groups
- **rate-limit-rules.json** - Rate-based rules
- **geo-blocking-rules.json** - Geographic restrictions
- **custom-rules.json** - Application-specific rules

## Lab Metadata

- **Domain**: Security
- **Complexity Level**: Intermediate
- **Estimated Time**: 45 minutes
- **AWS Services**: AWS WAF, ALB, CloudWatch, S3, CloudFormation
- **Key Concepts**: Web application firewall, OWASP Top 10, DDoS protection, geo-blocking
- **Certification Alignment**: AWS Certified Solutions Architect - Associate (WAF configuration), AWS Certified Security - Specialty (Web application security)

