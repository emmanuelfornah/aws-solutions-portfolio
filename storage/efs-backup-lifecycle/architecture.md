# EFS with AWS Backup and Lifecycle Management Architecture

## Architecture Overview

This architecture demonstrates Amazon EFS implementation with comprehensive backup and cost optimization strategies. The design includes EFS file systems with multi-AZ mount targets, EC2 instances accessing shared storage via NFS, AWS Backup service for automated backup management, and lifecycle policies for automatic transition to Infrequent Access storage class.

## Components

### 1. Amazon EFS File System

EFS provides fully managed, elastic, shared file storage for AWS Cloud and on-premises resources.

**File System Configuration:**
- **Performance Mode**: General Purpose or Max I/O
- **Throughput Mode**: Bursting, Provisioned, or Elastic
- **Encryption**: At rest (KMS) and in transit (TLS)
- **Storage Classes**: Standard and Infrequent Access (IA)
- **Lifecycle Management**: Automatic transition to IA

**Performance Modes:**

| Mode | Use Case | IOPS | Latency |
|------|----------|------|---------|
| General Purpose | Most workloads | Up to 35,000 | Low (sub-ms) |
| Max I/O | Highly parallelized | 500,000+ | Higher (low-ms) |

**Throughput Modes:**

| Mode | Throughput | Cost | Use Case |
|------|------------|------|----------|
| Bursting | Scales with size | Included | Variable workloads |
| Provisioned | Fixed amount | Additional charge | Consistent high throughput |
| Elastic | Automatic scaling | Pay for use | Unpredictable workloads |

### 2. Mount Targets

Mount targets provide network interfaces for accessing EFS from VPC.

**Configuration:**
- One mount target per Availability Zone
- Each mount target has an IP address in subnet
- Security group controls access (NFS port 2049)
- Supports up to 1,000 concurrent connections per mount target

**High Availability:**
- Multiple mount targets across AZs
- Automatic failover between mount targets
- No single point of failure
- Cross-AZ access with minimal latency

### 3. Security Groups

Security groups control network access to EFS mount targets.

**EFS Security Group Rules:**

**Inbound:**
- Type: NFS
- Protocol: TCP
- Port: 2049
- Source: EC2 instance security group or CIDR block

**Outbound:**
- All traffic (default)

**Best Practices:**
- Use security group references instead of CIDR blocks
- Implement least privilege access
- Separate security groups for different applications
- Enable VPC Flow Logs for monitoring

### 4. EC2 Instances

EC2 instances mount EFS file systems via NFS protocol.

**Requirements:**
- VPC connectivity to EFS mount targets
- Security group allowing outbound NFS traffic
- amazon-efs-utils package installed
- IAM permissions for EFS access (if using IAM authorization)

**Mount Methods:**
- **EFS Mount Helper**: Simplified mounting with encryption support
- **Traditional NFS**: Standard NFS v4.1 mount
- **Access Points**: Application-specific mount points

### 5. amazon-efs-utils

EFS mount helper provides simplified mounting and additional features.

**Features:**
- Automatic mount target selection
- Encryption in transit (TLS)
- IAM authorization support
- Automatic retry and failover
- CloudWatch Logs integration

**Installation:**
```bash
# Amazon Linux 2023
sudo yum install -y amazon-efs-utils

# Ubuntu
sudo apt-get install -y amazon-efs-utils
```

**Mount Command:**
```bash
sudo mount -t efs -o tls fs-12345678:/ /mnt/efs
```

### 6. AWS Backup

AWS Backup provides centralized backup management for EFS and other AWS services.

**Components:**

**Backup Vault:**
- Secure storage for backup recovery points
- Encryption with KMS
- Access control with IAM and vault policies
- Cross-region copy support

**Backup Plan:**
- Schedule: When backups occur (cron expression)
- Retention: How long backups are kept
- Lifecycle: Transition to cold storage
- Copy to another region: For disaster recovery

**Backup Job:**
- Individual backup execution
- Status tracking (pending, running, completed, failed)
- Recovery point creation
- CloudWatch Events integration

**IAM Role:**
- AWSBackupDefaultServiceRole (default)
- Permissions to access EFS and create backups
- Trust relationship with AWS Backup service

### 7. Lifecycle Management

EFS lifecycle management automatically transitions files to IA storage class.

**Lifecycle Policy:**
- Monitors file access patterns
- Transitions files after specified period of no access
- Automatically moves files back to Standard when accessed
- No application changes required

**Transition Periods:**
- 7, 14, 30, 60, or 90 days since last access
- Recommended: 30 days for most workloads

**Cost Impact:**
- Standard: $0.30/GB-month
- IA: $0.025/GB-month (92% savings)
- IA access: $0.01/GB read

### 8. EFS Access Points

Access Points provide application-specific entry points to EFS.

**Features:**
- Enforce user identity (POSIX user and group)
- Enforce root directory (chroot)
- Simplify application access management
- Support IAM policies for access control

**Use Cases:**
- Multi-tenant applications
- Container workloads
- Lambda functions
- Application isolation

## Data Flow

### File Write Operation

1. **Application Write**: Application on EC2 writes file to /mnt/efs
2. **NFS Client**: Linux NFS client processes write request
3. **Network**: Data sent over VPC network to mount target
4. **Security Group**: Mount target security group validates source
5. **Mount Target**: Receives data and forwards to EFS service
6. **EFS Service**: Distributes data across multiple AZs
7. **Replication**: Data replicated for durability (11 9s)
8. **Encryption**: Data encrypted at rest with KMS
9. **Acknowledgment**: Write completion returned to application
10. **Metadata Update**: File metadata updated (size, timestamp)

### File Read Operation

1. **Application Read**: Application requests file from /mnt/efs
2. **NFS Client**: Linux NFS client processes read request
3. **Network**: Request sent to mount target
4. **Mount Target**: Forwards request to EFS service
5. **EFS Service**: Retrieves data from storage
6. **Decryption**: Data decrypted if encryption enabled
7. **Network Transfer**: Data sent back through mount target
8. **NFS Client**: Receives and caches data
9. **Application**: Data delivered to application

### Backup Operation

1. **Scheduled Trigger**: AWS Backup triggers backup job based on schedule
2. **IAM Authorization**: Backup service assumes IAM role
3. **Snapshot Creation**: EFS creates point-in-time snapshot
4. **Incremental Backup**: Only changed data since last backup
5. **Encryption**: Backup encrypted with KMS
6. **Storage**: Recovery point stored in backup vault
7. **Metadata**: Backup metadata recorded (timestamp, size, status)
8. **Notification**: CloudWatch Events published for monitoring
9. **Retention**: Backup retained according to lifecycle policy

### Lifecycle Transition

1. **Access Monitoring**: EFS tracks last access time for each file
2. **Policy Evaluation**: Lifecycle policy evaluated periodically
3. **Transition Eligibility**: Files not accessed for specified period identified
4. **Data Movement**: Eligible files moved to IA storage class
5. **Metadata Update**: Storage class metadata updated
6. **Cost Reduction**: Storage costs reduced by 92%
7. **Access Trigger**: If file accessed, automatically moved back to Standard
8. **Transparent**: No application changes required

### Restore Operation

1. **Restore Request**: User initiates restore from backup vault
2. **Recovery Point Selection**: Specific backup selected
3. **IAM Authorization**: Backup service validates permissions
4. **New File System**: New EFS file system created
5. **Data Restoration**: Data copied from backup to new file system
6. **Verification**: Restore job status monitored
7. **Mount**: New file system mounted on EC2 instances
8. **Validation**: Application validates restored data

## Performance Characteristics

### Throughput Performance

**Bursting Mode:**
- Baseline: 50 MB/s per TB of storage
- Burst: Up to 100 MB/s per TB
- Burst credits: Accumulate when below baseline
- Credit balance: Monitored via CloudWatch

**Provisioned Mode:**
- Fixed throughput independent of storage size
- Up to 1,024 MB/s per file system
- Additional cost: $6.00 per MB/s-month
- Use case: Consistent high throughput needs

**Elastic Mode:**
- Automatic scaling up to 3 GB/s reads, 1 GB/s writes
- Pay for actual throughput used
- No burst credits or provisioning
- Recommended for most workloads

### IOPS Performance

**General Purpose Mode:**
- Up to 35,000 read IOPS
- Up to 7,000 write IOPS
- Suitable for most applications

**Max I/O Mode:**
- Virtually unlimited IOPS (500,000+)
- Higher latency (low milliseconds)
- Use case: Highly parallelized workloads

### Latency

**Read Latency:**
- First byte: Sub-millisecond to low milliseconds
- Depends on: Performance mode, file size, access pattern

**Write Latency:**
- Synchronous writes: Low milliseconds
- Asynchronous writes: Sub-millisecond
- Depends on: Data size, network conditions

## High Availability and Disaster Recovery

### Multi-AZ Architecture

**Availability:**
- Data replicated across multiple AZs
- 99.99% availability SLA
- Automatic failover between mount targets
- No single point of failure

**Durability:**
- 99.999999999% (11 9s) durability
- Data replicated within region
- Protection against AZ failures

### Backup Strategy

**Backup Frequency:**
- Daily: Most common for production
- Hourly: For critical data with low RPO
- Weekly: For less critical data

**Retention:**
- Short-term: 7-30 days (operational recovery)
- Long-term: 90-365 days (compliance)
- Permanent: Indefinite retention for archives

**Recovery Objectives:**
- **RPO (Recovery Point Objective)**: Time between backups
- **RTO (Recovery Time Objective)**: Time to restore

### Disaster Recovery

**Cross-Region Replication:**
- Use AWS Backup to copy to another region
- Automated or manual copy
- Encryption in transit and at rest

**Recovery Procedures:**
1. Identify recovery point in backup vault
2. Restore to new EFS file system
3. Update application mount points
4. Validate data integrity
5. Resume operations

## Security Architecture

### Encryption

**At Rest:**
- AES-256 encryption
- AWS KMS managed keys
- Customer managed keys (CMK) supported
- Transparent to applications

**In Transit:**
- TLS 1.2 encryption
- Enabled via EFS mount helper
- Certificate validation
- No performance impact

### Access Control

**Network Level:**
- VPC isolation
- Security groups (port 2049)
- Network ACLs
- VPC endpoints for private connectivity

**IAM Level:**
- IAM policies for API access
- IAM authorization for file system access
- Resource-based policies
- Access points with IAM policies

**File Level:**
- POSIX permissions (user, group, other)
- Access control lists (ACLs)
- Root squashing (default)
- User and group ID mapping

### Compliance

**Standards:**
- PCI DSS
- HIPAA eligible
- SOC 1, 2, 3
- ISO 27001
- FedRAMP

**Features:**
- Encryption at rest and in transit
- Access logging with CloudTrail
- Backup and retention policies
- Immutable backups with AWS Backup Vault Lock

## Cost Analysis

### Storage Costs

**Standard Storage Class:**
- $0.30 per GB-month
- First byte latency: Sub-millisecond
- Use case: Frequently accessed files

**Infrequent Access (IA):**
- $0.025 per GB-month (92% savings)
- Access charge: $0.01 per GB read
- Use case: Files accessed < once per month

**Example:**
- 1 TB Standard: $307.20/month
- 1 TB IA: $25.60/month + access charges
- Savings: $281.60/month (if rarely accessed)

### Throughput Costs

**Bursting Mode:**
- Included with storage cost
- No additional charge
- Scales with storage size

**Provisioned Mode:**
- $6.00 per MB/s-month
- Example: 100 MB/s = $600/month
- Use only when needed

**Elastic Mode:**
- $0.03 per GB read
- $0.06 per GB write
- Pay for actual usage

### Backup Costs

**AWS Backup Storage:**
- $0.05 per GB-month (warm storage)
- $0.01 per GB-month (cold storage)
- Incremental backups reduce costs

**Example:**
- 1 TB backup: $51.20/month (warm)
- 1 TB backup: $10.24/month (cold)

### Total Cost Example

**Scenario: 2 TB file system, 30% IA, daily backups**

- Standard storage: 1.4 TB × $0.30 = $430.08
- IA storage: 0.6 TB × $0.025 = $15.36
- Backup storage: 2 TB × $0.05 = $102.40
- **Total**: $547.84/month

**With lifecycle management:**
- Savings: ~$180/month (25% reduction)

## Monitoring and Alerting

### CloudWatch Metrics

**File System Metrics:**
- **DataReadIOBytes**: Bytes read
- **DataWriteIOBytes**: Bytes written
- **MetadataIOBytes**: Metadata operations
- **TotalIOBytes**: Total I/O
- **PercentIOLimit**: I/O utilization (General Purpose mode)
- **BurstCreditBalance**: Available burst credits
- **ClientConnections**: Number of connected clients
- **StorageBytes**: Total storage used by class

**Backup Metrics:**
- Backup job status (success/failure)
- Backup duration
- Recovery point creation

### Recommended Alarms

**Performance:**
- PercentIOLimit > 95% (approaching limit)
- BurstCreditBalance < 1 TB (low credits)
- ClientConnections > 900 (approaching limit)

**Capacity:**
- StorageBytes > threshold (cost management)
- Rapid storage growth (anomaly detection)

**Backup:**
- Backup job failures
- Missing scheduled backups
- Restore job failures

### Logging

**CloudTrail:**
- API calls to EFS
- File system creation/deletion
- Lifecycle policy changes
- Access point operations

**VPC Flow Logs:**
- Network traffic to mount targets
- Security group rule effectiveness
- Troubleshooting connectivity

**CloudWatch Logs:**
- EFS mount helper logs
- Backup job logs
- Application logs

## Best Practices

### Performance

1. Use General Purpose mode for most workloads
2. Enable Elastic throughput for unpredictable workloads
3. Use multiple mount targets across AZs
4. Implement caching at application layer
5. Use appropriate NFS mount options (rsize, wsize)

### Security

1. Enable encryption at rest and in transit
2. Use security groups to restrict access
3. Implement least privilege IAM policies
4. Use EFS Access Points for application isolation
5. Enable CloudTrail logging for audit

### Cost Optimization

1. Enable lifecycle management (30-day transition)
2. Monitor storage usage with CloudWatch
3. Delete unnecessary files and backups
4. Use Elastic throughput mode
5. Right-size backup retention

### Reliability

1. Implement automated backups with AWS Backup
2. Test restore procedures regularly
3. Use cross-region backup copies for DR
4. Monitor CloudWatch metrics and alarms
5. Implement proper error handling in applications

### Operational Excellence

1. Use Infrastructure as Code (CloudFormation/Terraform)
2. Automate backup and lifecycle policies
3. Document mount procedures and configurations
4. Implement monitoring and alerting
5. Regular review of access patterns and costs

