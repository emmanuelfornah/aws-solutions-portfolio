# Performing a Basic Audit of Your AWS Environment

## Overview

This lab provides a comprehensive approach to auditing AWS account security and compliance. You'll review IAM user permissions, test policies with IAM Policy Simulator, audit EC2 Security Groups, examine VPC configurations, analyze Network ACLs, review CloudWatch metrics, and investigate CloudTrail logs in S3. This systematic audit process identifies security gaps and ensures adherence to AWS best practices.

## AWS Services Used

- **AWS IAM** - User permissions, policies, and Policy Simulator
- **Amazon EC2** - Security Groups and instance configurations
- **Amazon VPC** - Network configurations, subnets, route tables, Network ACLs
- **Amazon CloudWatch** - Metrics and monitoring data
- **AWS CloudTrail** - Audit logs stored in S3
- **Amazon S3** - CloudTrail log storage and access

## Objectives

- Audit IAM user permissions and identify overly permissive policies
- Use IAM Policy Simulator to test effective permissions
- Review EC2 Security Groups for security vulnerabilities
- Analyze VPC configurations for network security best practices
- Examine Network ACLs for proper traffic filtering
- Review CloudWatch metrics for operational insights
- Investigate CloudTrail logs in S3 for audit trail analysis

## Key Learnings

- **Least Privilege Principle**: IAM users should have minimum permissions required for their role. Avoid using `*` wildcards in policies.

- **IAM Policy Simulator**: Test what actions a user can perform without actually executing them. Essential for validating policy changes before deployment.

- **Security Group Best Practices**: Restrict source IPs (avoid 0.0.0.0/0 for SSH/RDP), use security group references instead of IP ranges, document rules with descriptions.

- **Network ACLs vs Security Groups**: NACLs are stateless (require explicit inbound and outbound rules), Security Groups are stateful (return traffic automatically allowed).

- **CloudTrail Log Analysis**: Logs stored in S3 provide long-term audit trail. Use S3 Select or Athena for querying large log volumes.

- **VPC Flow Logs**: Capture network traffic metadata for troubleshooting and security analysis (not covered in basic audit but recommended for advanced monitoring).

## Audit Checklist

### 1. IAM User Permissions Audit

**Objectives**:
- Identify users with administrative access
- Find overly permissive policies
- Verify MFA enforcement
- Check for unused credentials

**Steps**:

1. Navigate to **IAM** > **Users**
2. Review each user:
   - Click username
   - Check **Permissions** tab
   - Note attached policies (managed and inline)
   - Check **Security credentials** tab for MFA status
3. Identify high-risk permissions:
   - `AdministratorAccess` policy
   - Policies with `"Effect": "Allow", "Action": "*", "Resource": "*"`
   - Inline policies (harder to audit than managed policies)
4. Check credential age:
   - Navigate to **IAM** > **Credential report**
   - Click **Download report**
   - Review `password_last_used` and `access_key_last_used` columns
   - Identify unused credentials (>90 days)

**Red Flags**:
- Users with `AdministratorAccess` who don't need it
- Users without MFA enabled
- Access keys not rotated in >90 days
- Inline policies (should use managed policies for consistency)

### 2. IAM Policy Simulator Testing

**Objectives**:
- Test effective permissions for IAM users
- Validate policy changes before deployment
- Understand policy evaluation logic

**Steps**:

1. Navigate to **IAM** > **Policy Simulator** (or visit https://policysim.aws.amazon.com)
2. Select user or role to test
3. Select AWS service (e.g., EC2, S3, IAM)
4. Select actions to test (e.g., `ec2:TerminateInstances`, `s3:DeleteBucket`)
5. Optionally specify resource ARN
6. Click **Run Simulation**
7. Review results:
   - **Allowed**: User can perform action
   - **Denied**: User cannot perform action (shows which policy denied)
   - **Implicitly Denied**: No policy explicitly allows (default deny)

**Example Test Cases**:
- Can user `john.doe` terminate EC2 instances?
- Can user `jane.smith` delete S3 buckets?
- Can user `admin` create IAM users?

See [scripts/policy-simulator-tests.txt](./scripts/policy-simulator-tests.txt) for test scenarios.

### 3. EC2 Security Groups Review

**Objectives**:
- Identify overly permissive rules (0.0.0.0/0)
- Verify proper port restrictions
- Check for unused security groups

**Steps**:

1. Navigate to **EC2** > **Security Groups**
2. For each security group:
   - Review **Inbound rules**:
     - Check for `0.0.0.0/0` (anywhere) on sensitive ports (22, 3389, 3306, 5432)
     - Verify source restrictions (specific IPs or security groups)
   - Review **Outbound rules**:
     - Check if overly permissive (usually allow all is acceptable)
   - Check **Description** field (should document purpose)
3. Identify unused security groups:
   - Check **Network interfaces** column
   - If 0, security group is unused (can be deleted)

**Security Group Best Practices**:
```
# BAD: SSH open to the world
Type: SSH (22)
Source: 0.0.0.0/0

# GOOD: SSH restricted to corporate IP
Type: SSH (22)
Source: 203.0.113.0/24

# BETTER: SSH restricted to bastion security group
Type: SSH (22)
Source: sg-0123456789abcdef0 (bastion-sg)
```

See [configs/security-group-audit-template.csv](./configs/security-group-audit-template.csv) for audit spreadsheet.

### 4. VPC Configuration Review

**Objectives**:
- Verify proper subnet design (public vs private)
- Check route table configurations
- Validate Internet Gateway and NAT Gateway setup

**Steps**:

1. Navigate to **VPC** > **Your VPCs**
2. For each VPC:
   - Note CIDR block (e.g., 10.0.0.0/16)
   - Check **DNS hostnames** and **DNS resolution** (should be enabled)
3. Navigate to **Subnets**:
   - Identify public subnets (route to Internet Gateway)
   - Identify private subnets (route to NAT Gateway or no internet route)
   - Verify subnets span multiple Availability Zones (high availability)
4. Navigate to **Route Tables**:
   - Check routes for each subnet
   - Public subnet should have: `0.0.0.0/0 → igw-xxxxx`
   - Private subnet should have: `0.0.0.0/0 → nat-xxxxx` (if internet needed)
5. Navigate to **Internet Gateways**:
   - Verify attached to correct VPC
6. Navigate to **NAT Gateways**:
   - Verify in public subnet
   - Check Elastic IP association

**VPC Best Practices**:
- Use private subnets for databases and application servers
- Use public subnets only for load balancers and bastion hosts
- Deploy NAT Gateways in multiple AZs for high availability
- Use VPC Flow Logs for traffic analysis

### 5. Network ACL Analysis

**Objectives**:
- Verify default NACL rules
- Check for custom NACL restrictions
- Understand stateless filtering

**Steps**:

1. Navigate to **VPC** > **Network ACLs**
2. For each NACL:
   - Review **Inbound rules**:
     - Rule numbers (lower = higher priority)
     - Type, Protocol, Port range, Source, Allow/Deny
   - Review **Outbound rules**:
     - Check ephemeral port ranges (1024-65535) are allowed
   - Check **Subnet associations**
3. Default NACL rules (allow all):
   ```
   Rule #  Type        Protocol  Port Range  Source      Allow/Deny
   100     All Traffic All       All         0.0.0.0/0   Allow
   *       All Traffic All       All         0.0.0.0/0   Deny
   ```

**NACL Best Practices**:
- Use Security Groups as primary filtering mechanism
- Use NACLs for additional defense-in-depth
- Remember NACLs are stateless (need explicit inbound and outbound rules)
- Use rule numbers in increments of 10 (allows inserting rules later)

### 6. CloudWatch Metrics Review

**Objectives**:
- Identify underutilized resources
- Check for missing metrics (stopped instances)
- Verify monitoring coverage

**Steps**:

1. Navigate to **CloudWatch** > **Metrics** > **All metrics**
2. Review EC2 metrics:
   - Select **EC2** > **Per-Instance Metrics**
   - Check **CPUUtilization** for all instances
   - Identify idle instances (CPU < 5% for extended periods)
3. Review RDS metrics (if applicable):
   - Check **DatabaseConnections**, **CPUUtilization**, **FreeStorageSpace**
4. Review ELB metrics (if applicable):
   - Check **RequestCount**, **TargetResponseTime**, **HealthyHostCount**
5. Identify missing metrics:
   - Instances without recent data points (stopped or terminated)

**Cost Optimization Opportunities**:
- Instances with consistently low CPU (< 10%) → Downsize or terminate
- Unattached EBS volumes → Delete or snapshot
- Idle load balancers (no requests) → Delete

### 7. CloudTrail Log Investigation

**Objectives**:
- Verify CloudTrail is enabled
- Review recent API activity
- Identify suspicious actions

**Steps**:

1. Navigate to **CloudTrail** > **Trails**
2. Verify trail is **Logging: ON**
3. Note S3 bucket name for log storage
4. Navigate to **S3** > Find CloudTrail bucket
5. Browse folder structure:
   ```
   s3://bucket-name/AWSLogs/[ACCOUNT-ID]/CloudTrail/region/YYYY/MM/DD/
   ```
6. Download recent log file (JSON format)
7. Search for security-relevant events:
   - `"eventName": "ConsoleLogin"` (login attempts)
   - `"eventName": "CreateUser"` (IAM user creation)
   - `"eventName": "PutUserPolicy"` (permission changes)
   - `"eventName": "AuthorizeSecurityGroupIngress"` (security group changes)
   - `"errorCode": "AccessDenied"` (unauthorized attempts)

**Alternative: Use CloudWatch Logs Insights**:
If CloudTrail is integrated with CloudWatch Logs, use Logs Insights for easier querying (see Lab 1).

See [scripts/cloudtrail-analysis-queries.txt](./scripts/cloudtrail-analysis-queries.txt) for S3 Select queries.

## Audit Report Template

Create audit report documenting findings:

```markdown
# AWS Account Audit Report
Date: [DATE]
Auditor: [NAME]
Account ID: [ACCOUNT-ID]

## Executive Summary
- Total IAM Users: X
- Users with Admin Access: X
- Security Groups Reviewed: X
- High-Risk Findings: X

## IAM Findings
- [ ] X users without MFA
- [ ] X users with unused credentials (>90 days)
- [ ] X users with AdministratorAccess

## Network Security Findings
- [ ] X security groups with 0.0.0.0/0 on port 22
- [ ] X security groups with 0.0.0.0/0 on port 3389
- [ ] X unused security groups

## Recommendations
1. Enable MFA for all users
2. Rotate access keys older than 90 days
3. Restrict SSH/RDP to specific IP ranges
4. Remove unused security groups
5. Enable VPC Flow Logs for traffic analysis
```

See [configs/audit-report-template.md](./configs/audit-report-template.md) for complete template.

## Cleanup

No cleanup required - this is a read-only audit lab.

## Real-World Applications

- **Security Audits**: Regular audits identify misconfigurations before they're exploited
- **Compliance Reporting**: Document security posture for SOC 2, ISO 27001, PCI-DSS audits
- **Cost Optimization**: Identify idle resources and rightsizing opportunities
- **Incident Response**: Audit after security incidents to identify attack vectors
- **Onboarding Reviews**: Audit new AWS accounts before production deployment

## Interview Talking Points

- **Describe IAM best practices**: Least privilege, MFA enforcement, credential rotation, managed policies over inline
- **Explain Security Group vs NACL**: Stateful vs stateless, allow-only vs allow/deny, instance-level vs subnet-level
- **Discuss audit frequency**: Monthly for small environments, weekly for large/regulated environments, continuous with AWS Config
- **Describe remediation priorities**: Fix critical issues first (admin access without MFA, SSH open to world), then medium/low

## Complexity Level

**Intermediate** - Requires understanding of IAM, VPC networking, Security Groups, and CloudTrail.

## Estimated Time

**Varies** - 30 minutes for small accounts, 2-3 hours for large accounts with many resources.

## AWS Certification Alignment

- **AWS Certified Security Specialty**: IAM auditing, network security, CloudTrail analysis, compliance
- **AWS Certified Solutions Architect Associate**: VPC design, Security Groups, IAM policies
- **AWS Certified SysOps Administrator Associate**: Operational auditing, resource optimization

## Completion Date

2024-01-15
