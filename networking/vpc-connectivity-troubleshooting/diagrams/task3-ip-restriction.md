# Task 3 Diagram - IP Address Restriction

## VPC Architecture - After IP-Based Restriction

This diagram shows the configuration after Task 3, where AppServerSG is restricted to allow SSH only from the Bastion Host's specific IP address.

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
│  │  │  │  - BastionHostSG    │      │  - PublicServerSG             │    │ │
│  │  │  └──────────┬──────────┘      └───────────┬───────────────────┘    │ │
│  │  │             │                              │                        │ │
│  │  │             │ SSH ✅                       │ SSH ❌                 │ │
│  │  │             │ (Allowed)                    │ (Blocked)              │ │
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
│  │  │  │   - AppServerSG (✅ Now restricted to 10.0.10.50/32)         │  │  │
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

## Security Group Changes

### AppServerSG (✅ Now Compliant)

**Inbound Rules - UPDATED:**
```
┌──────────┬──────────┬──────┬──────────────┬──────────────────────────────┐
│ Type     │ Protocol │ Port │ Source       │ Description                  │
├──────────┼──────────┼──────┼──────────────┼──────────────────────────────┤
│ SSH      │ TCP      │ 22   │ 10.0.10.50/32│ ✅ SSH from Bastion Host IP  │
│          │          │      │              │    only                      │
└──────────┴──────────┴──────┴──────────────┴──────────────────────────────┘
```

**Outbound Rules:**
```
┌──────────┬──────────┬──────┬─────────────┬──────────────────────────────┐
│ Type     │ Protocol │ Port │ Destination │ Description                  │
├──────────┼──────────┼──────┼─────────────┼──────────────────────────────┤
│ All      │ All      │ All  │ 0.0.0.0/0   │ Allow all outbound           │
└──────────┴──────────┴──────┴─────────────┴──────────────────────────────┘
```

### Other Security Groups (Unchanged)

BastionHostSG, PublicServerSG, and ApacheServerSG remain the same as in initial-setup.md.

## Traffic Flow - After IP Restriction

### SSH from Bastion Host to App Server (✅ Still Works)

```
Bastion Host (10.0.10.50)
         │
         │ SSH (port 22)
         │ Source IP: 10.0.10.50
         │
         ▼
App Server (10.0.20.10)
         │
         └─ AppServerSG checks:
            Rule: SSH from 10.0.10.50/32
            Source: 10.0.10.50
            Match: ✅ YES
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

### SSH from Public Server to App Server (❌ Now Blocked)

```
Public Server (10.0.11.50)
         │
         │ SSH (port 22)
         │ Source IP: 10.0.11.50
         │
         ▼
App Server (10.0.20.10)
         │
         └─ AppServerSG checks:
            Rule: SSH from 10.0.10.50/32
            Source: 10.0.11.50
            Match: ❌ NO
         └─ Connection DENIED ❌
```

**Test Command:**
```bash
[ec2-user@ip-10-0-11-50 ~]$ ssh -A ec2-user@10.0.20.10
ssh: connect to host 10.0.20.10 port 22: Connection timed out
```

**Result:** ✅ SUCCESS - Public Server is now blocked (compliant!)

## Configuration Details

### CIDR Notation Explained

**10.0.10.50/32**
- IP Address: 10.0.10.50
- Subnet Mask: /32 (255.255.255.255)
- Meaning: Exactly ONE IP address
- Matches: Only 10.0.10.50

**Comparison:**
```
10.0.10.50/32    → Only 10.0.10.50 (1 IP)
10.0.10.0/24     → 10.0.10.0 - 10.0.10.255 (256 IPs)
10.0.0.0/16      → 10.0.0.0 - 10.0.255.255 (65,536 IPs)
0.0.0.0/0        → All IPv4 addresses (4.3 billion IPs)
```

### AWS CLI Command to Update Security Group

```bash
# Get the security group ID
APPSERVER_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=AppServerSG" \
  --query "SecurityGroups[0].GroupId" \
  --output text)

# Get the Bastion Host private IP
BASTION_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=Bastion Host" \
  --query "Reservations[0].Instances[0].PrivateIpAddress" \
  --output text)

# Remove the old rule (0.0.0.0/0)
aws ec2 revoke-security-group-ingress \
  --group-id $APPSERVER_SG \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Add the new rule (Bastion Host IP only)
aws ec2 authorize-security-group-ingress \
  --group-id $APPSERVER_SG \
  --protocol tcp \
  --port 22 \
  --cidr ${BASTION_IP}/32 \
  --description "SSH from Bastion Host only"
```

## Advantages of IP-Based Restriction

✅ **Explicit Control:** You know exactly which IP is allowed  
✅ **Simple to Understand:** Clear and straightforward  
✅ **Immediate Compliance:** Meets security policy requirements  

## Limitations of IP-Based Restriction

❌ **Static Configuration:** Must update if Bastion Host IP changes  
❌ **Single Instance:** Only works for one bastion host  
❌ **Manual Updates:** Requires manual intervention for changes  
❌ **Not Scalable:** Difficult to manage multiple bastion hosts  

## Next Step: Task 4

Task 4 will address these limitations by using security group references instead of IP addresses, providing:
- Dynamic updates when instances change
- Support for multiple bastion hosts
- Easier management and scalability

See `task4-sg-reference.md` for the improved configuration.

## Verification Checklist

After completing Task 3, verify:

- [ ] Bastion Host can SSH to App Server
- [ ] Public Server cannot SSH to App Server (connection times out)
- [ ] AppServerSG inbound rule shows specific IP with /32
- [ ] Security policy compliance achieved
- [ ] No other connectivity broken

## Troubleshooting

**If Bastion Host cannot connect:**
1. Verify the IP address in the security group rule matches the Bastion Host's private IP
2. Check for typos in the CIDR notation (must include /32)
3. Ensure the rule is for TCP port 22
4. Confirm the security group is attached to the App Server

**If Public Server can still connect:**
1. Verify the old 0.0.0.0/0 rule was removed
2. Check that no other security groups on App Server allow SSH
3. Wait a few seconds for changes to propagate
4. Try from a new SSH session
