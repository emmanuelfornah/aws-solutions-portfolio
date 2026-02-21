# Networking Labs

This domain focuses on Amazon VPC (Virtual Private Cloud) networking concepts, security, troubleshooting, and analysis. These labs provide hands-on experience with core networking services that form the foundation of AWS cloud infrastructure.

## Domain Overview

Amazon VPC enables you to launch AWS resources in a logically isolated virtual network that you define. You have complete control over your virtual networking environment, including selection of IP address ranges, creation of subnets, and configuration of route tables and network gateways.

These labs cover essential networking skills including:
- VPC architecture and design patterns
- Security group configuration and troubleshooting
- Network path analysis and validation
- Connectivity troubleshooting methodologies
- Compliance verification and security posture assessment

## Labs

### 1. Troubleshooting Connectivity Within the VPC

**Complexity:** Intermediate  
**Duration:** 60 minutes

Practice troubleshooting connectivity to resources in a VPC, focusing on security groups as a common source of connectivity problems. Learn to review allowed traffic, develop connectivity tests, identify misconfigured rules, and remediate issues.

**Key Services:**
- Amazon VPC
- Amazon EC2
- AWS Systems Manager (Session Manager)
- Security Groups

**Key Learnings:**
- Security groups as stateful firewalls
- Principle of least privilege for security rules
- Security group referencing (using SG as source instead of IP)
- Troubleshooting methodology for connectivity issues
- Session Manager for secure instance access

**Architecture Highlights:**
- VPC with public and private subnets
- Bastion host pattern for secure SSH access
- Multiple EC2 instances with different security group configurations
- Apache web server for HTTP connectivity testing

[View Lab →](./vpc-connectivity-troubleshooting/)

---

### 2. Working with Amazon VPC Network Access Analyzer

**Complexity:** Intermediate  
**Duration:** 60 minutes

Use Network Access Analyzer feature in Amazon VPC to understand, verify, and improve network security posture. Analyze network paths, validate configurations, and demonstrate compliance requirements using automated reasoning algorithms.

**Key Services:**
- Amazon VPC
- Network Access Analyzer
- Amazon EC2
- VPC Endpoints (S3 Gateway)
- NAT Gateway
- VPC Peering

**Key Learnings:**
- Network Access Analyzer for security posture verification
- Analyzing inbound/outbound traffic paths
- VPC endpoint path validation
- Private subnet isolation verification
- VPC segmentation and peering analysis
- NAT gateway usage validation
- Compliance demonstration and validation

**Architecture Highlights:**
- Three VPCs with different network designs
- Private and public subnet configurations
- S3 gateway endpoint for private access
- VPC peering connections
- NAT gateway for outbound internet access

[View Lab →](./vpc-network-access-analyzer/)

---

### 3. Configuring DNS on Amazon EC2

**Complexity:** Intermediate  
**Duration:** 45 minutes

Learn to configure Amazon Route 53 private hosted zones for internal DNS resolution within a VPC. Create custom domain names for EC2 instances, configure DNS records, and test DNS-based service discovery patterns.

**Key Services:**
- Amazon Route 53
- Amazon EC2
- Amazon VPC
- Elastic IP

**Key Learnings:**
- Route 53 private hosted zones for internal DNS
- DNS A record configuration and routing policies
- Elastic IP for consistent addressing
- Route 53 Resolver architecture and behavior
- DNS propagation and TTL concepts
- Internal service discovery patterns
- VPC DNS configuration requirements

**Architecture Highlights:**
- Private hosted zone associated with VPC
- EC2 instance with Elastic IP running web server
- DNS A record mapping custom domain to instance
- Route 53 Resolver for VPC-internal DNS resolution
- Test client for DNS resolution verification

[View Lab →](./route53-dns-configuration/)

---

## Prerequisites

- AWS Account with appropriate permissions
- Basic understanding of networking concepts (IP addressing, routing, firewalls)
- Familiarity with AWS Management Console
- AWS CLI installed and configured (for automation scripts)

## Getting Started

Each lab directory contains:
- **README.md**: Comprehensive lab guide with step-by-step instructions
- **architecture.md**: Detailed technical explanations and architecture diagrams
- **configs/**: Sample configuration files and templates
- **scripts/**: Automation scripts for common tasks

Start with the VPC Connectivity Troubleshooting lab to build foundational skills, then progress to Network Access Analyzer for advanced security posture analysis.
