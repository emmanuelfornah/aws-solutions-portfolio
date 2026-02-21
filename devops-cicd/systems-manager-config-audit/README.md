# Auditing AWS Resources with AWS Systems Manager and AWS Config

## Overview

This lab demonstrates comprehensive resource auditing using AWS Systems Manager and AWS Config. You'll set up Systems Manager Inventory to collect instance metadata, use Session Manager for secure shell access, leverage Fleet Manager for centralized instance management, and configure AWS Config rules to enforce compliance policies. This combination provides complete visibility and governance over your AWS infrastructure.

## AWS Services Used

- **AWS Systems Manager** - Unified interface for operational management
- **Systems Manager Inventory** - Automated resource metadata collection
- **Session Manager** - Secure shell access without SSH keys or bastion hosts
- **Fleet Manager** - Centralized EC2 instance management
- **AWS Config** - Resource configuration tracking and compliance monitoring
- **AWS Config Rules** - Automated compliance checks

## Architecture

The auditing and compliance architecture includes:

1. **Systems Manager Agent**: Installed on EC2 instances
2. **Inventory**: Collects instance metadata (OS, applications, network config)
3. **Session Manager**: Provides secure shell access
4. **Fleet Manager**: Centralized management console
5. **AWS Config**: Records resource configurations
6. **Config Rules**: Evaluates compliance against policies

See [architecture.md](./architecture.md) for detailed architecture diagrams.

## Objectives

- Configure Systems Manager Inventory for automated metadata collection
- Use Session Manager for secure, auditable shell access
- Manage EC2 fleet using Fleet Manager
- Set up AWS Config to track resource configurations
- Implement Config rules for compliance monitoring
- Understand the difference between Systems Manager and AWS Config

## Key Learnings

- **Systems Manager vs AWS Config**: Systems Manager focuses on operational management (patching, automation, remote access), AWS Config focuses on compliance and configuration tracking (what changed, when, by whom).

- **Inventory Collection**: Automatically gathers metadata about instances (OS version, installed applications, network configuration, Windows updates, custom inventory). No manual scripts required.

- **Session Manager Benefits**: No SSH keys to manage, no bastion hosts needed, no open inbound ports, full audit trail in CloudTrail, session logging to S3/CloudWatch.

- **Fleet Manager**: Single pane of glass for managing EC2 instances. View file systems, performance counters, Windows Event Logs, and execute commands across fleet.

- **Config Rules**: Managed rules (AWS-provided) and custom rules (Lambda-based). Evaluate resources continuously or on configuration changes.

- **Compliance as Code**: Config rules codify compliance requirements (e.g., "all EC2 instances must be managed by Systems Manager", "IAM users must not have policies attached").

## Setup Instructions

### Prerequisites

- AWS account with Systems Manager, Config, and EC2 permissions
- EC2 instances with Systems Manager agent (pre-installed on Amazon Linux 2/2023, Windows Server 2016+)
- IAM instance profile with `AmazonSSMManagedInstanceCore` policy
- VPC with internet connectivity or VPC endpoints for Systems Manager

### Step 1: Verify Systems Manager Agent

1. Navigate to **Systems Manager** > **Fleet Manager**
2. Verify your EC2 instances appear in the list
3. If instances are missing:
   - Check IAM instance profile has `AmazonSSMManagedInstanceCore` policy
   - Verify Systems Manager agent is running:
     ```bash
     # Amazon Linux
     sudo systemctl status amazon-ssm-agent
     
     # Windows (PowerShell)
     Get-Service AmazonSSMAgent
     ```
   - Check network connectivity to Systems Manager endpoints

### Step 2: Configure Systems Manager Inventory

1. Navigate to **Systems Manager** > **Inventory**
2. Click **Setup Inventory**
3. Configure inventory:
   - **Name**: `EC2-Inventory`
   - **Targets**: 
     - Option A: All managed instances
     - Option B: Specify tags (e.g., `Environment=Production`)
   - **Schedule**: Rate expression (e.g., `rate(30 minutes)`)
   - **Parameters**: Select inventory types to collect:
     - [x] AWS:Application (installed applications)
     - [x] AWS:AWSComponent (AWS agent versions)
     - [x] AWS:InstanceInformation (OS, hostname, IP)
     - [x] AWS:Network (network configuration)
     - [x] AWS:WindowsUpdate (Windows updates)
     - [x] AWS:File (custom file inventory)
     - [x] AWS:Service (running services)
4. Click **Setup Inventory**
5. Wait 30 minutes for first inventory collection

### Step 3: View Inventory Data

1. Navigate to **Systems Manager** > **Inventory**
2. Click on an instance ID
3. Browse inventory tabs:
   - **Inventory**: Summary of collected data
   - **Applications**: Installed software
   - **AWS Components**: SSM agent version, CloudWatch agent
   - **Network**: IP addresses, MAC addresses, gateways
   - **Services**: Running services (Linux) or Windows services
4. Export inventory data:
   - Click **Export to S3**
   - Specify S3 bucket
   - Use exported data for reporting or analysis

### Step 4: Use Session Manager for Secure Access

1. Navigate to **Systems Manager** > **Session Manager**
2. Click **Start session**
3. Select target instance
4. Click **Start session**
5. **Result**: Browser-based shell session opens (no SSH key required)
6. Run commands:
   ```bash
   # Check OS version
   cat /etc/os-release
   
   # List installed packages
   rpm -qa  # Amazon Linux
   dpkg -l  # Ubuntu
   
   # Check disk usage
   df -h
   
   # View running processes
   ps aux
   ```
7. Click **Terminate** to end session

**Session Logging**:
- Navigate to **Session Manager** > **Preferences**
- Enable logging to S3 or CloudWatch Logs
- All session activity is recorded for audit

### Step 5: Use Fleet Manager

1. Navigate to **Systems Manager** > **Fleet Manager**
2. Select an instance
3. Click **Node actions** dropdown:
   - **Start session**: Launch Session Manager
   - **View details**: Instance metadata
   - **File system**: Browse files (Windows and Linux)
   - **Performance counters**: Real-time metrics (Windows)
   - **Windows Event Logs**: View event logs (Windows)
   - **Registry**: Browse Windows Registry (Windows)
4. Explore **File system**:
   - Browse directories
   - View file contents
   - Download files
   - Upload files (with proper permissions)

### Step 6: Set Up AWS Config

1. Navigate to **AWS Config** > **Get started** (if first time)
2. Click **1-click setup** (recommended) or **Manual setup**
3. Configure settings:
   - **Resource types to record**: All resources (recommended) or specific types
   - **S3 bucket**: Create new or use existing for Config snapshots
   - **SNS topic**: Optional (for configuration change notifications)
   - **IAM role**: Create new role (auto-generated)
4. Click **Confirm**
5. Wait 5-10 minutes for Config to start recording

### Step 7: Add Config Rule - EC2 Managed by Systems Manager

1. Navigate to **AWS Config** > **Rules**
2. Click **Add rule**
3. Search for: `ec2-instance-managed-by-systems-manager`
4. Click rule name
5. Configure rule:
   - **Name**: `ec2-managed-by-ssm`
   - **Description**: `Ensure all EC2 instances are managed by Systems Manager`
   - **Trigger**: Configuration changes
   - **Resources**: EC2:Instance
6. Click **Save**
7. Wait 2-3 minutes for initial evaluation
8. View compliance status:
   - **Compliant**: Instances with Systems Manager agent
   - **Noncompliant**: Instances without Systems Manager agent

### Step 8: Add Config Rule - IAM User No Policies

1. Navigate to **AWS Config** > **Rules** > **Add rule**
2. Search for: `iam-user-no-policies-check`
3. Configure rule:
   - **Name**: `iam-user-no-policies`
   - **Description**: `Ensure IAM users do not have inline policies attached`
   - **Trigger**: Configuration changes
   - **Resources**: IAM:User
4. Click **Save**
5. View compliance status:
   - **Compliant**: Users with no inline policies (use managed policies or groups)
   - **Noncompliant**: Users with inline policies attached

### Step 9: Review Config Timeline

1. Navigate to **AWS Config** > **Resources**
2. Select resource type (e.g., EC2:Instance)
3. Click on a resource
4. View **Configuration timeline**:
   - Shows all configuration changes over time
   - Click on a change to see before/after comparison
   - View who made the change (CloudTrail integration)
5. Click **Manage resource** to navigate to resource in AWS Console

### Step 10: Create Config Compliance Dashboard

1. Navigate to **AWS Config** > **Dashboard**
2. View compliance summary:
   - Total resources
   - Compliant resources
   - Noncompliant resources
   - Rules by compliance status
3. Click on noncompliant resources to investigate
4. Export compliance report:
   - Click **Actions** > **Export**
   - Download CSV for reporting

## Config Rules for Common Compliance Requirements

### Security Compliance

- `ec2-instance-managed-by-systems-manager`: Instances have SSM agent
- `ec2-instance-no-public-ip`: Instances don't have public IPs
- `restricted-ssh`: Security groups don't allow SSH from 0.0.0.0/0
- `restricted-rdp`: Security groups don't allow RDP from 0.0.0.0/0
- `encrypted-volumes`: EBS volumes are encrypted
- `s3-bucket-public-read-prohibited`: S3 buckets are not publicly readable
- `s3-bucket-public-write-prohibited`: S3 buckets are not publicly writable

### IAM Compliance

- `iam-user-no-policies-check`: Users don't have inline policies
- `iam-user-mfa-enabled`: Users have MFA enabled
- `iam-password-policy`: Account has strong password policy
- `iam-root-access-key-check`: Root account has no access keys

### Operational Compliance

- `required-tags`: Resources have required tags
- `approved-amis-by-id`: Instances use approved AMIs
- `ec2-instance-detailed-monitoring-enabled`: Instances have detailed monitoring

See [configs/config-rules.json](./configs/config-rules.json) for complete rule definitions.

## Testing and Validation

### Test Scenario 1: Inventory Collection

**Action**: Wait 30 minutes after inventory setup

**Expected Results**:
- Inventory data appears in Systems Manager Inventory
- Applications, network config, and services are listed
- Data can be exported to S3

### Test Scenario 2: Session Manager Access

**Action**: Start Session Manager session to EC2 instance

**Expected Results**:
- Browser-based shell opens without SSH key
- Commands execute successfully
- Session is logged (if logging enabled)

### Test Scenario 3: Config Rule Compliance

**Action**: Launch EC2 instance without Systems Manager agent

**Expected Results**:
- Config rule `ec2-managed-by-ssm` evaluates instance
- Instance marked as **Noncompliant**
- Compliance dashboard shows noncompliant resource

## Cleanup

1. Delete Config rules
2. Stop Config recorder:
   - Navigate to **AWS Config** > **Settings**
   - Click **Stop recording**
3. Delete Config S3 bucket (empty first)
4. Delete Systems Manager Inventory association
5. Delete Session Manager preferences (if configured)

## Real-World Applications

- **Compliance Auditing**: Automated compliance checks for SOC 2, PCI-DSS, HIPAA
- **Security Posture Management**: Continuous monitoring of security configurations
- **Change Management**: Track all configuration changes with audit trail
- **Operational Visibility**: Centralized view of instance metadata and configurations
- **Incident Response**: Investigate configuration changes during security incidents

## Interview Talking Points

- **Explain Systems Manager vs Config**: Systems Manager for operations (patching, automation), Config for compliance (tracking, auditing)
- **Describe Session Manager benefits**: No SSH keys, no bastion hosts, no open ports, full audit trail
- **Discuss Config rules**: Managed rules (AWS-provided) vs custom rules (Lambda-based)
- **Explain compliance as code**: Codify compliance requirements as Config rules for automated enforcement

## Complexity Level

**Intermediate** - Requires understanding of Systems Manager, AWS Config, IAM, and compliance concepts.

## Estimated Time

**60 minutes** - Including Systems Manager setup, Config configuration, rule creation, and testing.

## AWS Certification Alignment

- **AWS Certified Solutions Architect Associate**: Systems Manager architecture, Config integration, compliance design
- **AWS Certified Security Specialty**: Compliance monitoring, audit logging, security automation
- **AWS Certified SysOps Administrator Associate**: Operational management, Systems Manager, Config rules

## Completion Date

2024-01-15
