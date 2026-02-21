# Task 4 Diagram - Security Group Reference

## VPC Architecture - After Security Group Reference

This diagram shows the configuration after Task 4, where AppServerSG references BastionHostSG instead of a specific IP address, and the Public Server is added to BastionHostSG.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                  Internet                                    │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │   Internet Gateway      │
                    └────────────┬────────────┘
                                 │
┌────────────────────────────────┼────────────────────────────────────────────┐
│                          VPC A (10.0.0.0/16)                                 │
│                                │                                             │
│  ┌─────────────────────────────┼──────────────────────────────────────────┐ │
│  │         Public Subnet (10.0.10.0/24)                                    │ │
│  │                             │                                           │ │
│  │  ┌──────────────────────────┴───────────────────────────┐              │ │
│  │  │                                                       │              │ │
│  │  │  ┌─────────────────────┐      ┌─────────────────────┴─────────┐    │ │
│  │  │  │   Bastion Host      │      │   Public Server               │    │ │
│  │  │  │  10.0.10.50         │      │   10.0.11.50                  │    │ │
│  │  │  │  [Public IP]        │      │   [Public IP]                 │    │ │
│  │  │  │                     │      │                               │    │ │
│  │  │  │  Security Groups:   │      │  Security Groups:             │    │ │
│  │  │  │  - BastionHostSG ◄──┼──────┼──- BastionHostSG (NEW!)       │    │ │
│  │  │  │                     │      │  - PublicServerSG (REMOVED)   │    │ │
│  │  │  └──────────┬──────────┘      └───────────┬───────────────────┘    │ │
│  │  │             │                              │                        │ │
│  │  │             │ SSH ✅                       │ SSH ✅                 │ │
│  │  │             │ (Allowed via SG)             │ (Allowed via SG)       │ │
│  └──┼─────────────┼──────────────────────────────┼─────────────────────────┘ │
│     │             │                              │                           │
│     │             │                              │                           │
│  ┌──┼─────────────┼──────────────────────────────┼────────────────────────┐  │
│  │  │             │      Private Subnet          │                        │  │
│  │  │             │      (10.0.20.0/24)          │                        │  │
│  │  │             │                              │                        │  │
│  │  │             ▼                              ▼                        │  │
│  │  │  ┌──────────────────────────────────────────────────────────────┐  │  │
│  │  │  │   App Server                                                 │  │  │
│  │  │  │   10.0.20.10                                                 │  │  │
│  │  │  │   [No Public IP]                                             │  │  │
│  │  │  │                                                              │  │  │
│  │  │  │   Security Groups:                                           │  │  │
│  │  │  │   - AppServerSG (✅ References BastionHostSG)                │  │  │
│  │  │  └──────────────────────────────────────────────────────────────┘  │  │
│  │  │                                                                     │  │
│  └──┼─────────────────────────────────────────────────────────────────────┘  │
│     │                                                                        │
│     │  ┌──────────────────┐                                                 │
│     └──┤   NAT Gateway    │                                                 │
│        └──────────────────┘                                                 │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Security Group Reference Concept

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Security Group Reference                        │
│                                                                         │
│  AppServerSG Inbound Rule:                                              │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ Type: SSH                                                      │    │
│  │ Port: 22                                                       │    │
│  │ Source: sg-xxxxx (BastionHostSG) ◄─────────┐                  │    │
│  └────────────────────────────────────────────┼────────────────────┘    │
│                                               │                         │
│                                               │ References              │
│                                               │                         │
│  BastionHostSG Members:                       │                         │
│  ┌────────────────────────────────────────────┼────────────────────┐    │
│  │                                            │                    │    │
│  │  • Bastion Host (10.0.10.50) ─────────────┘                    │    │
│  │  • Public Server (10.0.11.50) ─────────────┐                   │    │
│  │                                            │                    │    │
│  └────────────────────────────────────────────┼────────────────────┘    │
│                                               │                         │
│  Result: Both instances can SSH to App Server │                         │
│          because they share BastionHostSG     │                         │
│                                               ▼                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Security Group Changes

### AppServerSG (✅ Now Using Security Group Reference)

**Inbound Rules - UPDATED:**
```
┌──────────┬──────────┬──────┬──────────────────┬──────────────────────────┐
│ Type     │ Protocol │ Port │ Source           │ Description              │
├──────────┼──────────┼──────┼──────────────────┼──────────────────────────┤
│ SSH      │ TCP      │ 22   │ sg-xxxxx         │ ✅ SSH from bastion      │
│          │          │      │ (BastionHostSG)  │    hosts                 │
└──────────┴──────────┴──────┴──────────────────┴──────────────────────────┘
```

**Outbound Rules:**
```
┌──────────┬──────────┬──────┬─────────────┬──────────────────────────────┐
│ Type     │ Protocol │ Port │ Destination │ Description                  │
├──────────┼──────────┼──────┼─────────────┼──────────────────────────────┤
│ All      │ All      │ All  │ 0.0.0.0/0   │ Allow all outbound           │
└──────────┴──────────┴──────┴─────────────┴──────────────────────────────┘
```

### Instance Security Group Assignments

**Bastion Host:**
```
Security Groups:
  - BastionHostSG (unchanged)
```

**Public Server (CHANGED):**
```
Security Groups:
  - BastionHostSG (✅ ADDED - now a bastion host!)
  - PublicServerSG (❌ REMOVED)
```

**App Server:**
```
Security Groups:
  - AppServerSG (rule updated to reference BastionHostSG)
```

## Traffic Flow - After Security Group Reference

### SSH from Bastion Host to App Server (✅ Still Works)

```
Bastion Host (10.0.10.50)
         │
         │ Security Groups: BastionHostSG
         │ SSH (port 22)
         │
         ▼
App Server (10.0.20.10)
         │
         └─ AppServerSG checks:
            Rule: SSH from BastionHostSG
            Source Instance SGs: BastionHostSG
            Match: ✅ YES (BastionHostSG in BastionHostSG)
         └─ Connection ALLOWED ✅
```

**Test Command:**
```bash
[ec2-user@ip-10-0-10-50 ~]$ ssh -A ec2-user@10.0.20.10
Last login: ...
[ec2-user@ip-10-0-20-10 ~]$ hostname
ip-10-0-20-10
```

**Result:** ✅ SUCCESS - Bastion Host can still connect

### SSH from Public Server to App Server (✅ Now Works!)

```
Public Server (10.0.11.50)
         │
         │ Security Groups: BastionHostSG (newly added)
         │ SSH (port 22)
         │
         ▼
App Server (10.0.20.10)
         │
         └─ AppServerSG checks:
            Rule: SSH from BastionHostSG
            Source Instance SGs: BastionHostSG
            Match: ✅ YES (BastionHostSG in BastionHostSG)
         └─ Connection ALLOWED ✅
```

**Test Command:**
```bash
[ec2-user@ip-10-0-11-50 ~]$ ssh -A ec2-user@10.0.20.10
Last login: ...
[ec2-user@ip-10-0-20-10 ~]$ hostname
ip-10-0-20-10
```

**Result:** ✅ SUCCESS - Public Server can now connect (compliant!)

## How Security Group References Work

### Step-by-Step Evaluation

When a connection attempt is made:

1. **Source Instance Identified:** AWS identifies the source instance (e.g., Public Server)

2. **Source Security Groups Retrieved:** AWS retrieves all security groups attached to the source instance
   - Public Server has: BastionHostSG

3. **Target Security Group Rules Evaluated:** AWS checks AppServerSG inbound rules
   - Rule: Allow SSH from BastionHostSG

4. **Match Check:** AWS checks if any source security group matches the rule
   - Source SGs: [BastionHostSG]
   - Rule requires: BastionHostSG
   - Match: ✅ YES

5. **Decision:** Connection ALLOWED

### Dynamic Updates

Security group references are dynamic:

**Scenario 1: Add a new bastion host**
```bash
# Launch new instance
aws ec2 run-instances --image-id ami-xxxxx ...

# Assign BastionHostSG to it
aws ec2 modify-instance-attribute \
  --instance-id i-newbastion \
  --groups sg-bastionhostsg

# Result: New instance can immediately SSH to App Server
# No changes to AppServerSG needed!
```

**Scenario 2: Remove bastion access**
```bash
# Remove BastionHostSG from Public Server
aws ec2 modify-instance-attribute \
  --instance-id i-publicserver \
  --groups sg-publicserversg

# Result: Public Server can no longer SSH to App Server
# No changes to AppServerSG needed!
```

## AWS CLI Commands

### Step 1: Update AppServerSG to Reference BastionHostSG

```bash
# Get security group IDs
APPSERVER_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=AppServerSG" \
  --query "SecurityGroups[0].GroupId" \
  --output text)

BASTION_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=BastionHostSG" \
  --query "SecurityGroups[0].GroupId" \
  --output text)

# Get Bastion Host IP (for removing old rule)
BASTION_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=Bastion Host" \
  --query "Reservations[0].Instances[0].PrivateIpAddress" \
  --output text)

# Remove the IP-based rule
aws ec2 revoke-security-group-ingress \
  --group-id $APPSERVER_SG \
  --protocol tcp \
  --port 22 \
  --cidr ${BASTION_IP}/32

# Add the security group reference rule
aws ec2 authorize-security-group-ingress \
  --group-id $APPSERVER_SG \
  --protocol tcp \
  --port 22 \
  --source-group $BASTION_SG \
  --description "SSH from bastion hosts"
```

### Step 2: Assign BastionHostSG to Public Server

```bash
# Get Public Server instance ID
PUBLIC_SERVER=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=Public Server" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

# Get current security groups
CURRENT_SGS=$(aws ec2 describe-instances \
  --instance-ids $PUBLIC_SERVER \
  --query "Reservations[0].Instances[0].SecurityGroups[*].GroupId" \
  --output text)

# Assign BastionHostSG (and remove PublicServerSG)
aws ec2 modify-instance-attribute \
  --instance-id $PUBLIC_SERVER \
  --groups $BASTION_SG
```

## Advantages of Security Group References

✅ **Dynamic:** Automatically updates when instances change  
✅ **Scalable:** Supports multiple bastion hosts easily  
✅ **Maintainable:** No need to update rules when IPs change  
✅ **Flexible:** Add/remove access by changing instance SG assignments  
✅ **Clear Intent:** Shows logical relationship between resources  
✅ **Auto Scaling Friendly:** Works with auto-scaling groups  

## Comparison: IP-Based vs Security Group Reference

### IP-Based Rule (Task 3)
```
AppServerSG Inbound:
  SSH from 10.0.10.50/32

Pros:
  • Explicit IP address
  • Simple to understand

Cons:
  • Static configuration
  • Must update if IP changes
  • Only one bastion host
  • Manual management
```

### Security Group Reference (Task 4)
```
AppServerSG Inbound:
  SSH from BastionHostSG

Pros:
  • Dynamic updates
  • Multiple bastion hosts
  • No IP management
  • Scalable solution

Cons:
  • Less explicit about IPs
  • Requires SG understanding
```

## Use Cases for Security Group References

### Multi-Tier Application

```
[Web Tier SG] → [App Tier SG] → [Database Tier SG]

Database SG Inbound:
  PostgreSQL from App Tier SG

App Tier SG Inbound:
  HTTP from Web Tier SG

Web Tier SG Inbound:
  HTTP/HTTPS from 0.0.0.0/0
```

### Auto Scaling Groups

```
Auto Scaling Group:
  Launch Configuration:
    Security Groups: WebServerSG

Load Balancer SG Inbound:
  HTTP from 0.0.0.0/0

WebServerSG Inbound:
  HTTP from Load Balancer SG

Result: All auto-scaled instances automatically get access
```

### Microservices

```
Service A SG ↔ Service B SG ↔ Service C SG

Each service references the others' security groups
No IP management needed as services scale
```

## Verification Checklist

After completing Task 4, verify:

- [ ] Bastion Host can SSH to App Server
- [ ] Public Server can SSH to App Server (now compliant as bastion)
- [ ] AppServerSG inbound rule references BastionHostSG (not IP)
- [ ] Public Server has BastionHostSG assigned
- [ ] Public Server does not have PublicServerSG assigned
- [ ] Security policy compliance maintained

## Troubleshooting

**If connections fail after update:**
1. Verify AppServerSG rule references correct security group ID
2. Check that source instance has BastionHostSG attached
3. Ensure old IP-based rule was removed (conflicts can occur)
4. Wait a few seconds for changes to propagate
5. Check for typos in security group IDs

**If wrong instances can connect:**
1. Review which instances have BastionHostSG assigned
2. Remove BastionHostSG from unauthorized instances
3. Verify no other security groups on App Server allow SSH

## Key Learnings

1. **Security group references are more flexible than IP-based rules**
2. **Multiple instances can share the same security group for access**
3. **Changes to instance security group assignments automatically update access**
4. **This pattern scales well for multiple bastion hosts**
5. **No need to update rules when IP addresses change**

This completes the security group configuration tasks. Next, tackle the Apache Server challenge!
