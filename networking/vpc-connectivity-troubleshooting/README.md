# Troubleshooting Connectivity Within the VPC

## Lab Overview

This lab provides hands-on experience troubleshooting connectivity to resources in a VPC, with a focus on security groups as a common source of connectivity problems. You'll learn to review allowed traffic, develop connectivity tests, identify misconfigured rules, and remediate issues following the principle of least privilege.

**Duration:** 60 minutes  
**Complexity:** Intermediate

## Learning Objectives

By the end of this lab, you will be able to:
- Examine security groups and determine allowed traffic
- Change which security groups are applied to EC2 instances
- Update security groups to follow the principle of least privilege
- Understand how security groups can reference other security groups
- Troubleshoot connectivity issues within a VPC

## Architecture

The lab environment consists of:

**VPC A:**
- **App Server** - EC2 instance in private subnet (target for SSH testing)
- **Bastion Host** - EC2 instance in public subnet (authorized SSH source)
- **Public Server** - EC2 instance in public subnet (test server)

**Separate Instance:**
- **Apache Server** - EC2 instance for challenge exercise

**Security Groups:**
- **AppServerSG** - Applied to App Server
- **BastionHostSG** - Applied to Bastion Host
- **PublicServerSG** - Applied to Public Server
- **ApacheServerSG** - Applied to Apache Server

See [architecture.md](./architecture.md) for detailed architecture diagrams and explanations.

## Prerequisites

- AWS Account with appropriate permissions
- Basic understanding of VPC concepts
- Familiarity with EC2 and security groups
- Understanding of SSH and HTTP protocols

## Tasks

### Task 1: Inspect App Server Security Group

**Objective:** Review the current security group configuration for the App Server.

1. Navigate to **EC2 Console** → **Security Groups**
2. Locate and select **AppServerSG**
3. Review the **Inbound rules** tab:
   - **Rule:** SSH (port 22) from 0.0.0.0/0
   - **Issue:** This allows SSH from anywhere (noncompliant with least privilege)
4. Review the **Outbound rules** tab:
   - **Rule:** All traffic allowed to 0.0.0.0/0

**Expected Finding:** The security group allows SSH access from any IP address, which violates the principle of least privilege.

### Task 2: Develop Tests for SSH Connectivity

**Objective:** Test SSH connectivity to the App Server from different sources.

#### Test from Bastion Host (Should Succeed)

1. Navigate to **EC2 Console** → **Instances**
2. Select **Bastion Host** instance
3. Click **Connect** → **Session Manager** → **Connect**
4. In the Session Manager terminal, run:
   ```bash
   ssh ec2-user@<APP_SERVER_PRIVATE_IP>
   ```
5. Type `yes` to accept the host key
6. **Result:** Connection should succeed (compliant with bastion pattern)

#### Test from Public Server (Succeeds but Noncompliant)

1. Select **Public Server** instance
2. Click **Connect** → **Session Manager** → **Connect**
3. In the Session Manager terminal, run:
   ```bash
   ssh ec2-user@<APP_SERVER_PRIVATE_IP>
   ```
4. **Result:** Connection succeeds but violates least privilege principle

**Automation:** Use the provided script:
```bash
./scripts/test-ssh-connectivity.sh <APP_SERVER_PRIVATE_IP>
```

### Task 3: Restrict SSH Access to Specific IPv4 Address

**Objective:** Update the security group to allow SSH only from the Bastion Host's private IP.

1. Navigate to **EC2 Console** → **Security Groups**
2. Select **AppServerSG**
3. Click **Edit inbound rules**
4. Modify the SSH rule:
   - **Type:** SSH
   - **Protocol:** TCP
   - **Port:** 22
   - **Source:** Custom - `<BASTION_HOST_PRIVATE_IP>/32`
   - **Description:** SSH from Bastion Host only
5. Click **Save rules**

#### Verify the Change

**Test from Public Server (Should Fail):**
1. Connect to Public Server via Session Manager
2. Attempt SSH to App Server:
   ```bash
   ssh ec2-user@<APP_SERVER_PRIVATE_IP>
   ```
3. **Result:** Connection should timeout or be refused (compliant)

**Test from Bastion Host (Should Succeed):**
1. Connect to Bastion Host via Session Manager
2. Attempt SSH to App Server:
   ```bash
   ssh ec2-user@<APP_SERVER_PRIVATE_IP>
   ```
3. **Result:** Connection should succeed (compliant)

**Automation:** Use the provided script:
```bash
./scripts/update-security-group.sh AppServerSG ssh <BASTION_HOST_PRIVATE_IP>/32
```

### Task 4: Reference Security Groups as Inbound Source

**Objective:** Use security group referencing instead of IP addresses for more flexible and maintainable rules.

#### Update AppServerSG to Reference BastionHostSG

1. Navigate to **EC2 Console** → **Security Groups**
2. Select **AppServerSG**
3. Click **Edit inbound rules**
4. Modify the SSH rule:
   - **Type:** SSH
   - **Protocol:** TCP
   - **Port:** 22
   - **Source:** Custom - Select **BastionHostSG** (security group ID)
   - **Description:** SSH from Bastion Host security group
5. Click **Save rules**

**Benefit:** Any instance with BastionHostSG attached can now SSH to the App Server, without updating IP addresses.

#### Add Public Server to BastionHostSG

1. Navigate to **EC2 Console** → **Instances**
2. Select **Public Server** instance
3. Click **Actions** → **Security** → **Change security groups**
4. Add **BastionHostSG** (keep existing PublicServerSG)
5. Click **Save**

#### Verify Connectivity

**Test from Public Server (Should Now Succeed):**
1. Connect to Public Server via Session Manager
2. Attempt SSH to App Server:
   ```bash
   ssh ec2-user@<APP_SERVER_PRIVATE_IP>
   ```
3. **Result:** Connection should succeed (Public Server now has BastionHostSG)

**Key Insight:** Security group referencing allows dynamic membership without IP address management.

### Task 5: Challenge - Troubleshoot Apache Server Connectivity

**Scenario:** The Apache Server is running but cannot be accessed via HTTP from the internet.

#### Problem Statement

- Apache HTTP Server is installed and running on the instance
- The instance is in a public subnet with an internet gateway
- The instance has a public IP address
- HTTP requests to `http://<APACHE_SERVER_PUBLIC_IP>` fail

#### Troubleshooting Steps

1. **Verify Apache is Running:**
   - Connect to Apache Server via Session Manager
   - Run: `sudo systemctl status httpd`
   - Expected: Service should be active (running)

2. **Check Network Configuration:**
   - Verify instance has public IP address
   - Verify subnet route table has route to internet gateway (0.0.0.0/0 → igw-xxx)

3. **Inspect Security Group:**
   - Navigate to **EC2 Console** → **Security Groups**
   - Select **ApacheServerSG**
   - Review **Inbound rules**
   - **Finding:** No HTTP (port 80) or HTTPS (port 443) rules exist!

#### Solution

1. Select **ApacheServerSG**
2. Click **Edit inbound rules**
3. Click **Add rule**:
   - **Type:** HTTP
   - **Protocol:** TCP
   - **Port:** 80
   - **Source:** 0.0.0.0/0 (allow from internet)
   - **Description:** Allow HTTP from internet
4. Click **Save rules**

#### Verify the Fix

1. Open a web browser
2. Navigate to: `http://<APACHE_SERVER_PUBLIC_IP>`
3. **Result:** Apache test page should load successfully

**Automation:** Use the provided script:
```bash
./scripts/verify-apache-access.sh <APACHE_SERVER_PUBLIC_IP>
```

## Key Learnings

### Security Groups as Stateful Firewalls

- Security groups are stateful: return traffic is automatically allowed
- Inbound rules control incoming traffic
- Outbound rules control outgoing traffic
- Rules are evaluated together (not in order)

### Principle of Least Privilege

- Grant only the minimum permissions necessary
- Avoid 0.0.0.0/0 for SSH access
- Use specific IP addresses or security group references
- Regularly audit and update security group rules

### Security Group Referencing

- Reference other security groups as sources/destinations
- Enables dynamic membership without IP management
- Simplifies multi-tier application architectures
- Automatically adapts when instances are added/removed

### Troubleshooting Methodology

1. **Verify the application** is running
2. **Check network configuration** (routing, IP addresses)
3. **Inspect security groups** (most common issue)
4. **Review network ACLs** (if security groups are correct)
5. **Check OS-level firewalls** (iptables, Windows Firewall)

### Common Connectivity Issues

- **Missing inbound rules** (e.g., HTTP port 80 not allowed)
- **Overly permissive rules** (0.0.0.0/0 for SSH)
- **Wrong source/destination** (incorrect IP or security group)
- **Wrong port** (e.g., allowing 443 when app uses 8443)

## Best Practices

1. **Use bastion hosts** for SSH access to private instances
2. **Reference security groups** instead of IP addresses when possible
3. **Document security group rules** with descriptions
4. **Regularly audit** security group configurations
5. **Use Session Manager** instead of SSH when possible (no open ports needed)
6. **Implement defense in depth** (security groups + NACLs + OS firewalls)
7. **Tag security groups** for easy identification and management

## Cleanup

To avoid ongoing charges, delete the lab resources:

1. Terminate all EC2 instances
2. Delete security groups (after instances are terminated)
3. Delete the VPC (if created specifically for this lab)

## Additional Resources

- [AWS Security Groups Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [VPC Security Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)

## Scripts

This lab includes automation scripts in the `scripts/` directory:

- `test-ssh-connectivity.sh` - Test SSH connectivity from current instance
- `update-security-group.sh` - Update security group rules via AWS CLI
- `verify-apache-access.sh` - Test HTTP connectivity to Apache server

See individual script files for usage instructions.
