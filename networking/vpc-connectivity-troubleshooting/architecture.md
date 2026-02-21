# VPC Connectivity Troubleshooting - Architecture

## Overview

This document provides detailed technical explanations of the VPC architecture, security group configurations, and the bastion host pattern used in this lab.

## VPC Architecture

### Network Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                          VPC A (10.0.0.0/16)                    │
│                                                                 │
│  ┌──────────────────────────┐  ┌──────────────────────────┐   │
│  │   Public Subnet          │  │   Private Subnet         │   │
│  │   10.0.1.0/24            │  │   10.0.2.0/24            │   │
│  │                          │  │                          │   │
│  │  ┌─────────────────┐    │  │  ┌─────────────────┐    │   │
│  │  │ Bastion Host    │    │  │  │  App Server     │    │   │
│  │  │ (Public IP)     │────┼──┼─→│  (Private IP)   │    │   │
│  │  │ BastionHostSG   │    │  │  │  AppServerSG    │    │   │
│  │  └─────────────────┘    │  │  └─────────────────┘    │   │
│  │                          │  │                          │   │
│  │  ┌─────────────────┐    │  │                          │   │
│  │  │ Public Server   │    │  │                          │   │
│  │  │ (Public IP)     │────┼──┼─→ (Test connectivity)   │   │
│  │  │ PublicServerSG  │    │  │                          │   │
│  │  └─────────────────┘    │  │                          │   │
│  │                          │  │                          │   │
│  └──────────┬───────────────┘  └──────────────────────────┘   │
│             │                                                   │
│             │ Route: 0.0.0.0/0 → IGW                           │
│             ↓                                                   │
│     ┌───────────────┐                                          │
│     │ Internet      │                                          │
│     │ Gateway (IGW) │                                          │
│     └───────────────┘                                          │
│             ↕                                                   │
└─────────────┼───────────────────────────────────────────────────┘
              │
         Internet
              │
┌─────────────┼───────────────────────────────────────────────────┐
│             ↕                                                   │
│     ┌───────────────┐                                          │
│     │ Internet      │                                          │
│     │ Gateway (IGW) │                                          │
│     └───────────────┘                                          │
│             │                                                   │
│  ┌──────────┴───────────────┐                                 │
│  │   Public Subnet          │                                 │
│  │   (Separate VPC)         │                                 │
│  │                          │                                 │
│  │  ┌─────────────────┐    │                                 │
│  │  │ Apache Server   │    │                                 │
│  │  │ (Public IP)     │    │                                 │
│  │  │ ApacheServerSG  │    │                                 │
│  │  │ Port 80: HTTP   │    │                                 │
│  │  └─────────────────┘    │                                 │
│  │                          │                                 │
│  └──────────────────────────┘                                 │
│                                                                 │
│              Separate VPC for Challenge                        │
└─────────────────────────────────────────────────────────────────┘
```

### Components

#### VPC A
- **CIDR Block:** 10.0.0.0/16
- **Purpose:** Main lab environment for security group troubleshooting
- **Subnets:**
  - Public Subnet (10.0.1.0/24) - Has route to Internet Gateway
  - Private Subnet (10.0.2.0/24) - No direct internet access

#### Internet Gateway
- Enables communication between VPC and the internet
- Attached to VPC A
- Public subnet route table has route: 0.0.0.0/0 → IGW

#### EC2 Instances

**Bastion Host:**
- **Location:** Public subnet
- **Purpose:** Secure entry point for SSH access to private instances
- **IP Addressing:** Public IP + Private IP
- **Security Group:** BastionHostSG

**App Server:**
- **Location:** Private subnet
- **Purpose:** Target server for connectivity testing
- **IP Addressing:** Private IP only
- **Security Group:** AppServerSG

**Public Server:**
- **Location:** Public subnet
- **Purpose:** Test server to demonstrate noncompliant access
- **IP Addressing:** Public IP + Private IP
- **Security Group:** PublicServerSG (initially), later adds BastionHostSG

**Apache Server:**
- **Location:** Separate VPC, public subnet
- **Purpose:** Challenge exercise for HTTP troubleshooting
- **IP Addressing:** Public IP + Private IP
- **Security Group:** ApacheServerSG

## Security Group Architecture

### Security Group Fundamentals

Security groups act as virtual firewalls for EC2 instances, controlling inbound and outbound traffic at the instance level.

**Key Characteristics:**
- **Stateful:** Return traffic is automatically allowed regardless of rules
- **Default Deny:** All inbound traffic is denied by default
- **Allow Rules Only:** You can only create allow rules, not deny rules
- **Rule Evaluation:** All rules are evaluated together (not in order)
- **Instance Level:** Applied to network interfaces (ENIs)

### Initial Security Group Configurations

#### AppServerSG (Initial - Noncompliant)

**Inbound Rules:**
```
Type    Protocol  Port  Source         Description
SSH     TCP       22    0.0.0.0/0      Allow SSH from anywhere (NONCOMPLIANT)
```

**Outbound Rules:**
```
Type         Protocol  Port  Destination  Description
All Traffic  All       All   0.0.0.0/0    Allow all outbound
```

**Issue:** SSH access from 0.0.0.0/0 violates the principle of least privilege.

#### BastionHostSG

**Inbound Rules:**
```
Type    Protocol  Port  Source         Description
SSH     TCP       22    0.0.0.0/0      Allow SSH from internet (for admin access)
```

**Outbound Rules:**
```
Type         Protocol  Port  Destination  Description
All Traffic  All       All   0.0.0.0/0    Allow all outbound
```

**Note:** Bastion hosts typically allow SSH from specific admin IP ranges, not 0.0.0.0/0 in production.

#### PublicServerSG

**Inbound Rules:**
```
Type    Protocol  Port  Source         Description
SSH     TCP       22    0.0.0.0/0      Allow SSH from internet
```

**Outbound Rules:**
```
Type         Protocol  Port  Destination  Description
All Traffic  All       All   0.0.0.0/0    Allow all outbound
```

#### ApacheServerSG (Initial - Broken)

**Inbound Rules:**
```
Type    Protocol  Port  Source         Description
SSH     TCP       22    0.0.0.0/0      Allow SSH from internet
```

**Outbound Rules:**
```
Type         Protocol  Port  Destination  Description
All Traffic  All       All   0.0.0.0/0    Allow all outbound
```

**Issue:** Missing HTTP (port 80) inbound rule prevents web access.

### Security Group Evolution Through Lab

#### Task 3: IP-Based Restriction

**AppServerSG (After Task 3):**

**Inbound Rules:**
```
Type    Protocol  Port  Source                    Description
SSH     TCP       22    10.0.1.10/32             SSH from Bastion Host IP only
```

**Improvement:** Restricts SSH to specific IP address (Bastion Host private IP).

**Limitation:** If Bastion Host IP changes or additional bastion hosts are added, rules must be updated.

#### Task 4: Security Group Referencing

**AppServerSG (After Task 4):**

**Inbound Rules:**
```
Type    Protocol  Port  Source                    Description
SSH     TCP       22    sg-xxxxx (BastionHostSG) SSH from Bastion Host SG
```

**Improvement:** Any instance with BastionHostSG can access App Server without IP management.

**Benefit:** Dynamic membership - adding Public Server to BastionHostSG automatically grants access.

#### Task 5: Apache Server Fix

**ApacheServerSG (After Fix):**

**Inbound Rules:**
```
Type    Protocol  Port  Source         Description
SSH     TCP       22    0.0.0.0/0      Allow SSH from internet
HTTP    TCP       80    0.0.0.0/0      Allow HTTP from internet
```

**Fix:** Added HTTP rule to allow web traffic.

## Bastion Host Pattern

### Purpose

The bastion host pattern provides secure administrative access to instances in private subnets without exposing them directly to the internet.

### Architecture Benefits

1. **Single Entry Point:** All SSH access goes through the bastion host
2. **Reduced Attack Surface:** Private instances have no public IPs
3. **Centralized Logging:** All SSH sessions can be logged at the bastion
4. **Enhanced Security:** Bastion can have additional hardening and monitoring

### Access Flow

```
Administrator → Internet → Bastion Host (Public Subnet) → App Server (Private Subnet)
```

**Step-by-step:**
1. Administrator connects to Bastion Host via SSH (or Session Manager)
2. Bastion Host has network access to private subnet
3. From Bastion Host, administrator SSH to App Server private IP
4. App Server security group allows SSH only from Bastion Host

### Security Group Configuration

**Bastion Host:**
- Inbound: SSH from admin IP ranges (or use Session Manager with no open ports)
- Outbound: SSH to private subnet instances

**Private Instances:**
- Inbound: SSH from Bastion Host security group (or specific IP)
- Outbound: As needed for application functionality

### Best Practices

1. **Limit Bastion Access:** Restrict SSH to specific admin IP ranges
2. **Use Session Manager:** Eliminates need for open SSH ports
3. **Enable Logging:** CloudWatch Logs, VPC Flow Logs, CloudTrail
4. **Harden Bastion:** Minimal software, regular patching, MFA
5. **Use Auto Scaling:** Deploy bastion in Auto Scaling group for HA
6. **Implement Jump Box:** Consider AWS Systems Manager Session Manager as alternative

## Security Group Referencing Deep Dive

### How It Works

When you specify a security group as a source in a rule, AWS automatically allows traffic from any instance that has that security group attached.

**Example:**
```
AppServerSG Inbound Rule:
  Type: SSH
  Source: sg-12345678 (BastionHostSG)
```

This allows SSH from:
- Any instance with BastionHostSG attached
- Automatically updates when instances are added/removed
- No IP address management required

### Use Cases

1. **Multi-Tier Applications:**
   ```
   Web Tier SG → App Tier SG → Database Tier SG
   ```

2. **Bastion Host Pattern:**
   ```
   BastionHostSG → Private Instance SGs
   ```

3. **Load Balancer to Application:**
   ```
   LoadBalancerSG → WebServerSG
   ```

4. **Microservices Communication:**
   ```
   ServiceA_SG ↔ ServiceB_SG
   ```

### Advantages

- **Dynamic Membership:** Instances automatically gain/lose access when SG is attached/detached
- **Simplified Management:** No IP address tracking
- **Scalability:** Works with Auto Scaling groups
- **Cross-Account:** Can reference security groups in peered VPCs (same region)

### Limitations

- **Same Region:** Security groups must be in the same region
- **VPC Peering:** Requires VPC peering for cross-VPC references
- **No Transitive Rules:** If SG-A allows SG-B, and SG-B allows SG-C, SG-A does NOT allow SG-C

## Network Traffic Flow

### SSH to App Server from Bastion Host

```
1. Bastion Host (10.0.1.10) initiates SSH to App Server (10.0.2.20)
   ↓
2. Packet leaves Bastion Host ENI
   - Source: 10.0.1.10:random_port
   - Destination: 10.0.2.20:22
   ↓
3. BastionHostSG Outbound Rules evaluated
   - Rule: All traffic to 0.0.0.0/0 → ALLOWED
   ↓
4. Packet routed within VPC (same VPC, no IGW needed)
   ↓
5. AppServerSG Inbound Rules evaluated
   - Rule: SSH from sg-xxxxx (BastionHostSG) → ALLOWED
   ↓
6. Packet delivered to App Server ENI
   ↓
7. App Server responds
   - Source: 10.0.2.20:22
   - Destination: 10.0.1.10:random_port
   ↓
8. AppServerSG Outbound Rules evaluated
   - Rule: All traffic to 0.0.0.0/0 → ALLOWED
   ↓
9. Return packet automatically allowed by BastionHostSG (stateful)
   ↓
10. Connection established
```

### HTTP to Apache Server from Internet

```
1. Client initiates HTTP request to Apache Server public IP
   ↓
2. Packet arrives at Internet Gateway
   ↓
3. IGW translates public IP to private IP (NAT)
   ↓
4. ApacheServerSG Inbound Rules evaluated
   - Rule: HTTP (port 80) from 0.0.0.0/0 → ALLOWED
   ↓
5. Packet delivered to Apache Server ENI
   ↓
6. Apache Server responds
   ↓
7. ApacheServerSG Outbound Rules evaluated
   - Rule: All traffic to 0.0.0.0/0 → ALLOWED
   ↓
8. Return packet automatically allowed (stateful)
   ↓
9. IGW translates private IP to public IP
   ↓
10. Response delivered to client
```

## Troubleshooting Decision Tree

```
Cannot connect to instance?
│
├─ Is the application running?
│  ├─ No → Start the application
│  └─ Yes → Continue
│
├─ Does the instance have correct IP addressing?
│  ├─ Public subnet instance needs public IP
│  ├─ Private subnet instance needs private IP only
│  └─ Check route table for correct routes
│
├─ Check Security Group Inbound Rules
│  ├─ Is the required port allowed?
│  ├─ Is the source correct (IP or SG)?
│  └─ Is the protocol correct (TCP/UDP)?
│
├─ Check Network ACLs (if SG rules are correct)
│  ├─ Inbound rules allow traffic?
│  └─ Outbound rules allow return traffic?
│
├─ Check Route Tables
│  ├─ Public subnet has route to IGW?
│  └─ Private subnet has route to NAT Gateway (if needed)?
│
└─ Check OS-level Firewall
   ├─ iptables (Linux)
   └─ Windows Firewall (Windows)
```

## Key Takeaways

1. **Security groups are the first line of defense** for EC2 instances
2. **Principle of least privilege** should guide all security group configurations
3. **Security group referencing** provides flexible, maintainable access control
4. **Bastion host pattern** is essential for secure access to private instances
5. **Stateful nature** of security groups simplifies rule management
6. **Systematic troubleshooting** methodology quickly identifies connectivity issues
