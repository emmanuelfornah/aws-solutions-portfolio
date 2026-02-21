# Using AWS Config for Compliance and Security Automation

## Overview

This lab demonstrates automated compliance monitoring and remediation using AWS Config. You'll set up Config with 1-click setup, implement compliance rules for EC2 and S3 security, and configure automatic remediation using Systems Manager Automation documents. This approach transforms manual compliance checks into automated, continuous monitoring with self-healing capabilities.

## AWS Services Used

- **AWS Config** - Configuration tracking and compliance monitoring
- **AWS Config Rules** - Automated compliance evaluation
- **AWS Systems Manager Automation** - Automated remediation workflows
- **Amazon EC2** - Compute instances for compliance testing
- **Amazon S3** - Storage buckets for compliance testing
- **AWS IAM** - Permissions for Config and remediation

## Objectives

- Set up AWS Config using 1-click setup
- Implement compliance rules for security best practices
- Configure automatic remediation with Systems Manager Automation
- Test compliance violations and automatic fixes
- Understand remediation workflows and approval processes

## Key Learnings

- **1-Click Setup**: Simplifies Config deployment with recommended settings (all resources, S3 bucket, IAM role).

- **Managed Config Rules**: AWS provides 200+ pre-built rules for common compliance requirements (no Lambda coding required).

- **Automatic Remediation**: Config rules can trigger Systems Manager Automation documents to automatically fix noncompliant resources.

- **Remediation Actions**: SSM Automation documents perform actions like stopping instances, enabling encryption, removing public access, updating security groups.

- **Compliance Drift**: Config continuously monitors for drift from desired state and can automatically remediate.

## Setup Instructions

### Step 1: Enable AWS Config (1-Click Setup)

1. Navigate to **AWS Config** > **Get started**
2. Click **1-click setup**
3. Review auto-configured settings:
   - **Resource types**: All supported resources
   - **S3 bucket**: Auto-created with name `config-bucket-[ACCOUNT-ID]-[REGION]`
   - **SNS topic**: Optional (not created by default)
   - **IAM role**: Auto-created with required permissions
4. Click **Confirm**
5. Wait 5-10 minutes for Config to initialize

### Step 2: Add Rule - EC2 Instance No Public IP

1. Navigate to **AWS Config** > **Rules** > **Add rule**
2. Search for: `ec2-instance-no-public-ip`
3. Configure rule:
   - **Name**: `ec2-no-public-ip`
   - **Description**: `Ensure EC2 instances do not have public IP addresses`
   - **Trigger**: Configuration changes
   - **Resources**: EC2:Instance
4. **Remediation action**: None (manual remediation)
5. Click **Save**

### Step 3: Add Rule - S3 Bucket Public Read Prohibited

1. Add rule: `s3-bucket-public-read-prohibited`
2. Configure:
   - **Name**: `s3-no-public-read`
   - **Description**: `Ensure S3 buckets are not publicly readable`
3. **Remediation action**:
   - Enable **Automatic remediation**
   - **Remediation action**: `AWS-PublishSNSNotification` (for testing) or `AWS-DisableS3BucketPublicReadWrite`
   - **Resource ID parameter**: `BucketName`
   - **Auto remediation**: Enabled
   - **Retries**: 5
   - **Retry interval**: 60 seconds
4. Click **Save**

### Step 4: Add Rule - S3 Bucket Versioning Enabled

1. Add rule: `s3-bucket-versioning-enabled`
2. Configure:
   - **Name**: `s3-versioning-enabled`
   - **Description**: `Ensure S3 buckets have versioning enabled`
3. **Remediation action**:
   - Enable **Automatic remediation**
   - **Remediation action**: `AWS-ConfigureS3BucketVersioning`
   - **Parameters**:
     - `BucketName`: `RESOURCE_ID`
     - `VersioningState`: `Enabled`
   - **Auto remediation**: Enabled
4. Click **Save**

### Step 5: Add Rule - S3 Bucket Logging Enabled

1. Add rule: `s3-bucket-logging-enabled`
2. Configure:
   - **Name**: `s3-logging-enabled`
   - **Description**: `Ensure S3 buckets have access logging enabled`
3. **Remediation action**:
   - Enable **Automatic remediation**
   - **Remediation action**: `AWS-ConfigureS3BucketLogging`
   - **Parameters**:
     - `BucketName`: `RESOURCE_ID`
     - `TargetBucket`: `[LOGGING-BUCKET-NAME]` (create separate bucket for logs)
     - `TargetPrefix`: `access-logs/`
   - **Auto remediation**: Enabled
4. Click **Save**

### Step 6: Test Compliance - Create Noncompliant S3 Bucket

1. Navigate to **S3** > **Create bucket**
2. Bucket name: `test-noncompliant-bucket-[RANDOM]`
3. **Block Public Access**: Disable all settings (makes bucket noncompliant)
4. **Versioning**: Disabled (noncompliant)
5. **Server access logging**: Disabled (noncompliant)
6. Click **Create bucket**
7. Wait 2-3 minutes for Config evaluation

### Step 7: Verify Compliance Violations

1. Navigate to **AWS Config** > **Rules**
2. Check rule compliance:
   - `s3-no-public-read`: **Noncompliant** (1 resource)
   - `s3-versioning-enabled`: **Noncompliant** (1 resource)
   - `s3-logging-enabled`: **Noncompliant** (1 resource)
3. Click on noncompliant rule
4. View noncompliant resources (your test bucket)

### Step 8: Verify Automatic Remediation

1. Navigate to **AWS Config** > **Rules** > Select noncompliant rule
2. Click **Remediation action** tab
3. View remediation execution:
   - **Status**: In progress → Success
   - **Execution time**: Timestamp
   - **Automation document**: SSM document used
4. Navigate to **S3** > Select test bucket
5. Verify fixes applied:
   - **Versioning**: Enabled (if remediation configured)
   - **Logging**: Enabled (if remediation configured)
   - **Public access**: Blocked (if remediation configured)

### Step 9: Review Remediation History

1. Navigate to **Systems Manager** > **Automation**
2. View **Execution history**
3. Find executions triggered by Config
4. Click execution ID to view details:
   - **Inputs**: Resource ID, parameters
   - **Outputs**: Remediation results
   - **Steps**: Automation workflow steps
   - **Status**: Success or Failed

### Step 10: Create Custom Remediation Workflow

For rules without built-in remediation, create custom SSM Automation document:

1. Navigate to **Systems Manager** > **Documents** > **Create document**
2. Document type: **Automation**
3. Example: Stop EC2 instances with public IPs
   ```yaml
   schemaVersion: '0.3'
   description: Stop EC2 instance with public IP
   parameters:
     InstanceId:
       type: String
       description: EC2 Instance ID
   mainSteps:
     - name: StopInstance
       action: 'aws:executeAwsApi'
       inputs:
         Service: ec2
         Api: StopInstances
         InstanceIds:
           - '{{ InstanceId }}'
   ```
4. Save document
5. Associate with Config rule `ec2-no-public-ip`

See [configs/remediation-documents/](./configs/remediation-documents/) for custom automation documents.

## Config Rules and Remediation Actions

| Config Rule | Compliance Check | Remediation Action | Auto-Remediate |
|-------------|------------------|-------------------|----------------|
| ec2-instance-no-public-ip | No public IP | Stop instance | Optional |
| s3-bucket-public-read-prohibited | No public read | Block public access | Yes |
| s3-bucket-public-write-prohibited | No public write | Block public access | Yes |
| s3-bucket-versioning-enabled | Versioning enabled | Enable versioning | Yes |
| s3-bucket-logging-enabled | Logging enabled | Enable logging | Yes |
| encrypted-volumes | EBS encryption | N/A (can't encrypt existing) | No |
| restricted-ssh | No SSH from 0.0.0.0/0 | Remove rule | Optional |
| iam-user-mfa-enabled | MFA enabled | Send notification | No |

See [configs/config-rules-remediation.json](./configs/config-rules-remediation.json) for complete configurations.

## Testing and Validation

### Test Scenario 1: S3 Public Access Remediation

**Action**: Create S3 bucket with public read access

**Expected Results**:
- Config rule detects noncompliance within 2-3 minutes
- Automatic remediation triggers SSM Automation
- Public access is blocked automatically
- Bucket becomes compliant

### Test Scenario 2: S3 Versioning Remediation

**Action**: Create S3 bucket without versioning

**Expected Results**:
- Config rule detects noncompliance
- Automatic remediation enables versioning
- Bucket becomes compliant

### Test Scenario 3: Manual Remediation

**Action**: Launch EC2 instance with public IP

**Expected Results**:
- Config rule detects noncompliance
- Manual remediation required (stop instance or remove public IP)
- After remediation, instance becomes compliant

## Remediation Best Practices

1. **Test Before Auto-Remediation**: Test remediation actions manually before enabling automatic remediation
2. **Use Approval Workflows**: For critical resources, require manual approval before remediation
3. **Set Retry Limits**: Configure appropriate retry attempts and intervals
4. **Monitor Remediation**: Set up CloudWatch alarms for failed remediations
5. **Document Exceptions**: Use Config rule exclusions for legitimate noncompliant resources
6. **Gradual Rollout**: Enable auto-remediation for non-critical resources first

## Cleanup

1. Delete Config rules
2. Delete test S3 bucket
3. Delete custom SSM Automation documents
4. Stop Config recorder (if no longer needed)
5. Delete Config S3 bucket (empty first)

## Real-World Applications

- **Continuous Compliance**: Automated monitoring and remediation for security standards (CIS, PCI-DSS, HIPAA)
- **Security Automation**: Automatically fix security misconfigurations (public S3 buckets, open security groups)
- **Cost Optimization**: Automatically stop idle instances, delete unattached volumes
- **Governance**: Enforce organizational policies (required tags, approved AMIs, encryption)

## Interview Talking Points

- **Explain Config vs CloudWatch**: Config tracks configuration changes and compliance, CloudWatch monitors performance metrics
- **Describe automatic remediation**: Config rules trigger SSM Automation documents to fix noncompliant resources
- **Discuss remediation approval**: Balance between automation speed and change control requirements
- **Explain compliance as code**: Codify compliance requirements as Config rules for consistent enforcement

## Complexity Level

**Intermediate** - Requires understanding of AWS Config, Systems Manager Automation, and compliance concepts.

## Estimated Time

**60 minutes** - Including Config setup, rule configuration, remediation testing, and validation.

## AWS Certification Alignment

- **AWS Certified Security Specialty**: Compliance automation, security remediation, Config rules
- **AWS Certified Solutions Architect Associate**: Config architecture, automation design
- **AWS Certified SysOps Administrator Associate**: Operational automation, compliance monitoring

## Completion Date

2024-01-15
