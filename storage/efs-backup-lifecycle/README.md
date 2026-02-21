# Using Amazon EFS with AWS Backup and Lifecycle Management

## Overview

This lab demonstrates implementing Amazon Elastic File System (EFS) with comprehensive backup strategies using AWS Backup and cost optimization through lifecycle management. The implementation includes creating EFS file systems, configuring security groups for NFS access, mounting EFS on EC2 instances using amazon-efs-utils, setting up persistent mounts via fstab, implementing automated backup plans with AWS Backup, and configuring lifecycle policies to transition infrequently accessed files to the Infrequent Access (IA) storage class.

## AWS Services Used

- **Amazon EFS** - Fully managed elastic NFS file system
- **Amazon EC2** - Compute instances for EFS mounting
- **AWS Backup** - Centralized backup service
- **Amazon VPC** - Network isolation and security groups
- **AWS IAM** - Permissions and roles for backup operations

## Key Technologies

- **NFS (Network File System)** - Protocol for distributed file systems
- **amazon-efs-utils** - EFS mount helper and encryption utilities
- **fstab** - File system table for persistent mounts
- **Security Groups** - Firewall rules for NFS traffic (port 2049)
- **EFS Lifecycle Management** - Automatic transition to IA storage class
- **AWS Backup Plans** - Scheduled backup policies

## Architecture Overview

The architecture consists of an EFS file system with mount targets in multiple Availability Zones, EC2 instances mounting the file system via NFS, security groups controlling access on port 2049, AWS Backup service creating automated backups on a schedule, and lifecycle policies automatically moving files to IA storage class after a specified period of inactivity.

See [architecture.md](./architecture.md) for detailed architecture description and data flow.

## Objectives

- Create and configure Amazon EFS file systems
- Set up security groups for NFS access (port 2049)
- Mount EFS on EC2 instances using amazon-efs-utils
- Configure persistent EFS mounts in /etc/fstab
- Implement AWS Backup plans for automated backups
- Configure lifecycle management for cost optimization
- Understand EFS performance modes and throughput modes
- Monitor EFS metrics with CloudWatch

## Key Learnings

- **EFS Architecture**: Understanding distributed file system architecture with mount targets across AZs
- **NFS Configuration**: Configuring security groups for NFS protocol (TCP port 2049)
- **EFS Mount Helper**: Using amazon-efs-utils for simplified mounting and encryption
- **Persistent Mounts**: Configuring /etc/fstab for automatic mounting at boot
- **AWS Backup Integration**: Creating backup plans, vaults, and retention policies
- **Lifecycle Management**: Automatically transitioning files to IA storage class for cost savings
- **Performance Modes**: Choosing between General Purpose and Max I/O performance modes
- **Throughput Modes**: Understanding Bursting, Provisioned, and Elastic throughput modes
- **Cross-AZ Access**: Mounting EFS from instances in different Availability Zones

## Setup Instructions

### Prerequisites

- AWS account with EFS and AWS Backup permissions
- VPC with multiple subnets across Availability Zones
- EC2 instances running Amazon Linux 2023 or Ubuntu
- SSH access to EC2 instances
- IAM role with EFS and Backup permissions

### Step 1: Create EFS File System

Create an EFS file system with mount targets:

```bash
# Run from your local machine with AWS CLI
./scripts/create-efs-filesystem.sh
```

This creates:
- EFS file system with encryption at rest
- Mount targets in multiple Availability Zones
- Security group for NFS access

### Step 2: Configure Security Groups

Set up security group rules for NFS access:

```bash
./scripts/configure-security-groups.sh
```

This configures:
- Inbound rule: TCP port 2049 from EC2 security group
- Outbound rule: All traffic (default)

### Step 3: Install EFS Utilities

Install amazon-efs-utils on EC2 instances:

```bash
# SSH into your EC2 instance, then run:
./scripts/install-efs-utils.sh
```

### Step 4: Mount EFS File System

Mount EFS using the mount helper:

```bash
./scripts/mount-efs.sh
```

This mounts EFS to /mnt/efs using the EFS mount helper.

### Step 5: Configure Persistent Mount

Add EFS to /etc/fstab for automatic mounting:

```bash
./scripts/configure-fstab.sh
```

This ensures EFS mounts automatically at boot.

### Step 6: Configure Lifecycle Management

Set up lifecycle policy to transition files to IA storage:

```bash
./scripts/configure-lifecycle.sh
```

This configures:
- Transition to IA after 30 days of no access
- Automatic cost optimization

### Step 7: Create AWS Backup Plan

Set up automated backup schedule:

```bash
./scripts/create-backup-plan.sh
```

This creates:
- Daily backups at 2 AM UTC
- 30-day retention policy
- Backup vault for storage

### Step 8: Test and Verify

Verify EFS functionality and backups:

```bash
# Test file operations
./scripts/test-efs.sh

# Verify backup plan
aws backup list-backup-plans

# Check lifecycle policy
aws efs describe-lifecycle-configuration --file-system-id fs-xxxxx
```

## Scripts and Configurations

### Scripts

All scripts are located in the `scripts/` directory:

- **create-efs-filesystem.sh** - Creates EFS file system with mount targets
- **configure-security-groups.sh** - Sets up security group rules for NFS
- **install-efs-utils.sh** - Installs amazon-efs-utils package
- **mount-efs.sh** - Mounts EFS file system using mount helper
- **configure-fstab.sh** - Adds EFS to /etc/fstab for persistent mounting
- **configure-lifecycle.sh** - Sets up lifecycle policy for IA transition
- **create-backup-plan.sh** - Creates AWS Backup plan and vault
- **test-efs.sh** - Tests EFS functionality with file operations
- **cleanup.sh** - Removes EFS file system and backup resources

### Configuration Files

Configuration templates are located in the `configs/` directory:

- **efs-mount-options.conf** - EFS mount options and parameters
- **backup-plan.json** - AWS Backup plan configuration
- **lifecycle-policy.json** - EFS lifecycle management policy
- **security-group-rules.json** - Security group rule definitions
- **fstab-entry.txt** - Sample fstab entry for EFS

## EFS Mount Options

### Using EFS Mount Helper

```bash
# Basic mount
sudo mount -t efs fs-12345678:/ /mnt/efs

# Mount with encryption in transit
sudo mount -t efs -o tls fs-12345678:/ /mnt/efs

# Mount with access point
sudo mount -t efs -o tls,accesspoint=fsap-12345678 fs-12345678:/ /mnt/efs
```

### Using Traditional NFS Mount

```bash
# Mount using NFS v4.1
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 \
    fs-12345678.efs.us-east-1.amazonaws.com:/ /mnt/efs
```

### fstab Entry

```
# EFS mount with encryption in transit
fs-12345678:/ /mnt/efs efs _netdev,tls,iam 0 0

# EFS mount without encryption
fs-12345678:/ /mnt/efs efs _netdev 0 0

# Traditional NFS mount
fs-12345678.efs.us-east-1.amazonaws.com:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0
```

## AWS Backup Configuration

### Backup Plan Structure

```json
{
  "BackupPlanName": "EFS-Daily-Backup",
  "Rules": [
    {
      "RuleName": "DailyBackup",
      "TargetBackupVaultName": "EFS-Backup-Vault",
      "ScheduleExpression": "cron(0 2 * * ? *)",
      "StartWindowMinutes": 60,
      "CompletionWindowMinutes": 120,
      "Lifecycle": {
        "DeleteAfterDays": 30
      }
    }
  ]
}
```

### Backup Frequency Options

- **Hourly**: `cron(0 * * * ? *)`
- **Daily**: `cron(0 2 * * ? *)` (2 AM UTC)
- **Weekly**: `cron(0 2 ? * SUN *)` (Sunday 2 AM)
- **Monthly**: `cron(0 2 1 * ? *)` (1st of month 2 AM)

### Retention Policies

- **Short-term**: 7-30 days
- **Medium-term**: 30-90 days
- **Long-term**: 90-365 days
- **Compliance**: 7+ years with transition to cold storage

## Lifecycle Management

### Lifecycle Policy Configuration

```json
{
  "LifecyclePolicies": [
    {
      "TransitionToIA": "AFTER_30_DAYS"
    }
  ]
}
```

### Transition Options

- **AFTER_7_DAYS**: Transition after 7 days of no access
- **AFTER_14_DAYS**: Transition after 14 days of no access
- **AFTER_30_DAYS**: Transition after 30 days of no access (recommended)
- **AFTER_60_DAYS**: Transition after 60 days of no access
- **AFTER_90_DAYS**: Transition after 90 days of no access

### Cost Savings

**Standard Storage Class:**
- Cost: $0.30 per GB-month
- Use case: Frequently accessed files

**Infrequent Access (IA) Storage Class:**
- Cost: $0.025 per GB-month (92% savings)
- Access cost: $0.01 per GB read
- Use case: Files accessed less than once per month

**Example Savings:**
- 1 TB of data in IA: $25.60/month vs $307.20/month (Standard)
- Monthly savings: $281.60 (92% reduction)

## Troubleshooting

### Mount Failures

**EFS Mount Helper Not Found:**
```bash
# Install amazon-efs-utils
sudo yum install -y amazon-efs-utils  # Amazon Linux
sudo apt-get install -y amazon-efs-utils  # Ubuntu
```

**Connection Timeout:**
```bash
# Check security group allows NFS (port 2049)
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Verify mount target is available
aws efs describe-mount-targets --file-system-id fs-xxxxx

# Test connectivity
telnet fs-xxxxx.efs.us-east-1.amazonaws.com 2049
```

**Permission Denied:**
```bash
# Check IAM permissions for EFS
# Verify EC2 instance has IAM role with EFS permissions

# Check file system policy
aws efs describe-file-system-policy --file-system-id fs-xxxxx
```

### Backup Issues

**Backup Plan Not Running:**
```bash
# Check backup plan status
aws backup describe-backup-plan --backup-plan-id plan-xxxxx

# Verify IAM role has backup permissions
aws iam get-role --role-name AWSBackupDefaultServiceRole

# Check backup vault
aws backup list-backup-vaults
```

**Backup Failures:**
```bash
# Check backup job status
aws backup list-backup-jobs --by-resource-arn arn:aws:elasticfilesystem:region:account:file-system/fs-xxxxx

# Review CloudWatch Logs for backup service
aws logs tail /aws/backup/jobs --follow
```

### Performance Issues

**Slow Performance:**
```bash
# Check EFS performance mode
aws efs describe-file-systems --file-system-id fs-xxxxx

# Monitor CloudWatch metrics
# - PercentIOLimit (should be < 100%)
# - BurstCreditBalance (should be > 0)

# Consider switching to Elastic throughput mode
aws efs update-file-system --file-system-id fs-xxxxx --throughput-mode elastic
```

## Security Considerations

- Enable encryption at rest using AWS KMS
- Enable encryption in transit using TLS
- Use security groups to restrict NFS access to specific instances
- Implement least privilege IAM policies
- Use EFS Access Points for application-specific access control
- Enable VPC Flow Logs for network monitoring
- Use AWS Backup for data protection and compliance
- Implement file system policies for fine-grained access control
- Regularly review and audit access logs

## Cost Optimization

### Storage Costs

- Enable lifecycle management to transition to IA storage
- Monitor file access patterns with CloudWatch metrics
- Delete unnecessary files and backups
- Use EFS Intelligent-Tiering (automatic lifecycle management)
- Right-size backup retention periods

### Throughput Costs

- Use Bursting mode for variable workloads (no additional cost)
- Use Elastic mode for unpredictable workloads (pay for actual throughput)
- Use Provisioned mode only when consistent high throughput needed
- Monitor PercentIOLimit to avoid performance throttling

### Backup Costs

- Optimize backup frequency based on RPO requirements
- Implement appropriate retention policies
- Use AWS Backup lifecycle to transition to cold storage
- Delete old recovery points no longer needed

## Next Steps

- Implement EFS Access Points for multi-tenant applications
- Configure EFS Replication for disaster recovery
- Set up CloudWatch alarms for EFS metrics
- Implement EFS file system policies for access control
- Test backup restoration procedures
- Explore EFS Intelligent-Tiering for automatic lifecycle management
- Integrate with AWS DataSync for data migration
- Implement cross-region backup replication

## Lab Metadata

- **Domain**: Storage
- **Complexity Level**: Intermediate
- **Estimated Time**: 60 minutes
- **AWS Services**: EFS, EC2, AWS Backup, VPC, IAM, CloudWatch
- **Key Concepts**: NFS, distributed file systems, backup strategies, lifecycle management, cost optimization
- **Certification Alignment**: AWS Certified Solutions Architect - Associate (EFS, backup strategies, cost optimization)

