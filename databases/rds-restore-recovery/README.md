# Restoring an Amazon RDS DB Instance

## Overview

This lab demonstrates comprehensive backup and restore operations for Amazon RDS, including point-in-time recovery, automated backup management, manual snapshot creation, and restore procedures. The implementation covers creating RDS instances with automated backups, performing point-in-time recovery to specific timestamps, creating and managing manual snapshots, restoring from snapshots, and understanding recovery objectives (RPO/RTO) for disaster recovery planning.

## AWS Services Used

- **Amazon RDS** - Managed relational database with automated backups
- **Amazon S3** - Backup storage (managed by RDS)
- **AWS IAM** - Permissions for backup and restore operations
- **Amazon CloudWatch** - Backup monitoring and metrics
- **AWS Backup** - Centralized backup management (optional)

## Key Technologies

- **Automated Backups** - Daily snapshots with transaction logs
- **Point-in-Time Recovery (PITR)** - Restore to any second within retention period
- **Manual Snapshots** - User-initiated backups retained indefinitely
- **Snapshot Sharing** - Cross-account snapshot sharing
- **Cross-Region Copy** - Disaster recovery with regional backups
- **Backup Encryption** - KMS-encrypted backups

## Architecture Overview

The architecture consists of an RDS instance with automated backups enabled, storing daily snapshots and transaction logs in S3. Point-in-time recovery capability allows restoration to any second within the retention period by combining automated snapshots with transaction log replay. Manual snapshots provide long-term backup retention, and cross-region snapshot copies enable disaster recovery scenarios.

See [architecture.md](./architecture.md) for detailed backup architecture and restore procedures.

## Objectives

- Configure automated backups with appropriate retention periods
- Perform point-in-time recovery to specific timestamps
- Create and manage manual database snapshots
- Restore RDS instances from snapshots
- Copy snapshots across regions for disaster recovery
- Share snapshots with other AWS accounts
- Understand RPO and RTO for backup strategies
- Monitor backup operations with CloudWatch

## Key Learnings

- **Automated Backups**: Understanding daily snapshots and transaction log backups
- **Point-in-Time Recovery**: Restoring to exact timestamps within retention period
- **Backup Retention**: Configuring 1-35 day retention for automated backups
- **Manual Snapshots**: Creating long-term backups retained indefinitely
- **Restore Operations**: Creating new instances from backups
- **Cross-Region DR**: Copying snapshots for disaster recovery
- **Backup Windows**: Scheduling backups during low-traffic periods
- **Recovery Objectives**: Defining RPO (data loss tolerance) and RTO (recovery time)
- **Backup Costs**: Understanding storage costs and optimization strategies

## Setup Instructions

### Prerequisites

- AWS account with RDS permissions
- Existing RDS instance or ability to create one
- Understanding of backup and recovery concepts
- AWS CLI configured with appropriate credentials
- Sufficient IAM permissions for RDS operations

### Step 1: Create RDS Instance with Automated Backups

Create an RDS instance with automated backups enabled:

```bash
# Run from your local machine with AWS CLI
./scripts/create-rds-with-backups.sh
```

This creates:
- RDS MySQL instance
- Automated backups enabled
- 7-day retention period
- Backup window configured

### Step 2: Populate Database with Test Data

Add test data to demonstrate restore operations:

```bash
./scripts/populate-test-data.sh
```

This creates sample tables and data with timestamps for verification.

### Step 3: Create Manual Snapshot

Create a manual snapshot for long-term retention:

```bash
./scripts/create-manual-snapshot.sh
```

This creates a user-initiated snapshot retained until explicitly deleted.

### Step 4: Simulate Data Changes

Make additional changes to test point-in-time recovery:

```bash
./scripts/simulate-data-changes.sh
```

This adds more data with timestamps to verify recovery accuracy.

### Step 5: Perform Point-in-Time Recovery

Restore database to a specific timestamp:

```bash
./scripts/restore-point-in-time.sh
```

This script:
- Prompts for target restore time
- Creates new RDS instance from PITR
- Verifies data at specified timestamp

### Step 6: Restore from Manual Snapshot

Restore from a manual snapshot:

```bash
./scripts/restore-from-snapshot.sh
```

This creates a new RDS instance from the manual snapshot.

### Step 7: Copy Snapshot to Another Region

Copy snapshot for disaster recovery:

```bash
./scripts/copy-snapshot-cross-region.sh
```

This copies the snapshot to a different AWS region.

### Step 8: Verify and Compare

Compare restored instances with original:

```bash
./scripts/verify-restore.sh
```

This script verifies data integrity and timestamp accuracy.

## Scripts and Configurations

### Scripts

All scripts are located in the `scripts/` directory:

- **create-rds-with-backups.sh** - Creates RDS instance with automated backups
- **populate-test-data.sh** - Adds test data with timestamps
- **create-manual-snapshot.sh** - Creates manual snapshot
- **simulate-data-changes.sh** - Makes additional data changes
- **restore-point-in-time.sh** - Performs PITR to specific timestamp
- **restore-from-snapshot.sh** - Restores from manual snapshot
- **copy-snapshot-cross-region.sh** - Copies snapshot to another region
- **verify-restore.sh** - Verifies restored data integrity
- **list-backups.sh** - Lists all available backups and snapshots
- **cleanup.sh** - Removes test instances and snapshots

### Configuration Files

Configuration templates are located in the `configs/` directory:

- **backup-config.json** - Automated backup configuration
- **restore-config.json** - Restore operation parameters
- **snapshot-policy.json** - Snapshot retention policy
- **test-data-schema.sql** - Test database schema
- **verification-queries.sql** - Data verification queries

## Automated Backup Configuration

### Backup Settings

**Retention Period:**
- Minimum: 1 day
- Maximum: 35 days
- Recommended: 7 days for production
- Setting to 0 disables automated backups

**Backup Window:**
- Duration: 30 minutes minimum
- Scheduled during low-traffic periods
- Example: "03:00-04:00" (3 AM - 4 AM UTC)
- Must not overlap with maintenance window

**Backup Process:**
- Daily full snapshot of storage volume
- Transaction logs backed up every 5 minutes
- Stored in Amazon S3 (managed by RDS)
- No performance impact on Multi-AZ deployments

### Backup Storage

**Storage Location:**
- Amazon S3 (managed by RDS, not directly accessible)
- Encrypted if source DB is encrypted
- Replicated across multiple Availability Zones
- Automatic lifecycle management

**Storage Costs:**
- Free backup storage up to 100% of DB storage
- Additional backup storage: $0.095/GB-month
- Example: 100 GB DB with 150 GB backups = 50 GB charged

## Point-in-Time Recovery (PITR)

### How PITR Works

**Components:**
1. **Automated Snapshots**: Daily full backups
2. **Transaction Logs**: 5-minute incremental backups
3. **Restore Process**: Snapshot + log replay to target time

**Recovery Window:**
- Earliest: Oldest automated snapshot
- Latest: Latest restorable time (typically 5 minutes ago)
- Granularity: Any second within retention period

### PITR Process

**Step 1: Identify Restore Time**
```bash
# Get latest restorable time
aws rds describe-db-instances \
    --db-instance-identifier mydb \
    --query 'DBInstances[0].LatestRestorableTime'
```

**Step 2: Initiate Restore**
```bash
aws rds restore-db-instance-to-point-in-time \
    --source-db-instance-identifier mydb \
    --target-db-instance-identifier mydb-restored \
    --restore-time "2024-01-15T10:30:00Z"
```

**Step 3: Wait for Completion**
```bash
aws rds wait db-instance-available \
    --db-instance-identifier mydb-restored
```

**Step 4: Verify Data**
```bash
# Connect and verify data at restored timestamp
mysql -h mydb-restored.xxxxx.rds.amazonaws.com -u admin -p
```

### PITR Limitations

- Cannot restore to current time (use latest restorable time)
- Creates new DB instance (cannot overwrite existing)
- Same configuration as source instance
- Requires automated backups enabled
- Limited to retention period (1-35 days)

## Manual Snapshots

### Creating Manual Snapshots

**When to Create:**
- Before major application changes
- Before database schema modifications
- For long-term retention (> 35 days)
- For compliance and audit requirements
- Before deleting DB instance

**Creation Command:**
```bash
aws rds create-db-snapshot \
    --db-instance-identifier mydb \
    --db-snapshot-identifier mydb-before-migration-2024-01-15
```

**Naming Convention:**
- Include DB identifier
- Include purpose or event
- Include date
- Example: `mydb-before-upgrade-2024-01-15`

### Managing Manual Snapshots

**List Snapshots:**
```bash
aws rds describe-db-snapshots \
    --db-instance-identifier mydb \
    --snapshot-type manual
```

**Delete Snapshot:**
```bash
aws rds delete-db-snapshot \
    --db-snapshot-identifier mydb-old-snapshot
```

**Copy Snapshot:**
```bash
aws rds copy-db-snapshot \
    --source-db-snapshot-identifier mydb-snapshot \
    --target-db-snapshot-identifier mydb-snapshot-copy \
    --kms-key-id arn:aws:kms:us-east-1:[ACCOUNT-ID]:key/xxxxx
```

### Snapshot Retention

**Automated Snapshots:**
- Retained for backup retention period (1-35 days)
- Automatically deleted when retention period expires
- Deleted when DB instance is deleted
- Cannot be retained after DB deletion

**Manual Snapshots:**
- Retained indefinitely until explicitly deleted
- Persist after DB instance deletion
- Can be copied to other regions
- Can be shared with other AWS accounts

## Restore Operations

### Restore from Snapshot

**Basic Restore:**
```bash
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier mydb-restored \
    --db-snapshot-identifier mydb-snapshot-2024-01-15
```

**Restore with Custom Configuration:**
```bash
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier mydb-restored \
    --db-snapshot-identifier mydb-snapshot-2024-01-15 \
    --db-instance-class db.t3.medium \
    --multi-az \
    --storage-type gp3 \
    --publicly-accessible false \
    --vpc-security-group-ids sg-xxxxx \
    --db-subnet-group-name mydb-subnet-group
```

### Restore Considerations

**New Instance Creation:**
- Restore always creates new DB instance
- Cannot restore over existing instance
- Must use different instance identifier
- Inherits configuration from snapshot

**Configuration Options:**
- Can change instance class during restore
- Can enable/disable Multi-AZ
- Can change storage type
- Can modify security groups and subnet group
- Cannot change engine or engine version

**Post-Restore Tasks:**
1. Verify data integrity
2. Update application connection strings
3. Reconfigure parameter groups if needed
4. Set up monitoring and alarms
5. Test application connectivity
6. Delete old instance if replacing

## Cross-Region Backup

### Copying Snapshots Across Regions

**Purpose:**
- Disaster recovery
- Geographic redundancy
- Compliance requirements
- Data migration

**Copy Command:**
```bash
aws rds copy-db-snapshot \
    --source-db-snapshot-identifier arn:aws:rds:us-east-1:[ACCOUNT-ID]:snapshot:mydb-snapshot \
    --target-db-snapshot-identifier mydb-snapshot-dr \
    --region us-west-2 \
    --kms-key-id arn:aws:kms:us-west-2:[ACCOUNT-ID]:key/xxxxx
```

**Encryption Considerations:**
- Source snapshot encryption preserved
- Must specify KMS key in target region
- Cannot copy unencrypted to encrypted (or vice versa)
- Use separate KMS keys per region

### Automated Cross-Region Copy

**Using AWS Backup:**
```json
{
  "BackupPlanName": "RDS-Cross-Region-Backup",
  "Rules": [{
    "RuleName": "DailyBackupWithCopy",
    "TargetBackupVaultName": "Default",
    "ScheduleExpression": "cron(0 3 * * ? *)",
    "CopyActions": [{
      "DestinationBackupVaultArn": "arn:aws:backup:us-west-2:[ACCOUNT-ID]:backup-vault:Default",
      "Lifecycle": {
        "DeleteAfterDays": 30
      }
    }]
  }]
}
```

## Snapshot Sharing

### Sharing with Other AWS Accounts

**Share Snapshot:**
```bash
aws rds modify-db-snapshot-attribute \
    --db-snapshot-identifier mydb-snapshot \
    --attribute-name restore \
    --values-to-add [ACCOUNT-ID-2]
```

**View Shared Snapshots:**
```bash
aws rds describe-db-snapshot-attributes \
    --db-snapshot-identifier mydb-snapshot
```

**Restore Shared Snapshot (in target account):**
```bash
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier mydb-from-shared \
    --db-snapshot-identifier arn:aws:rds:us-east-1:[SOURCE-ACCOUNT-ID]:snapshot:mydb-snapshot
```

### Sharing Encrypted Snapshots

**Requirements:**
- Share KMS key with target account
- Target account must have permissions to use KMS key
- Cannot share snapshots encrypted with default RDS key

**KMS Key Policy:**
```json
{
  "Sid": "Allow use of the key for RDS",
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::[TARGET-ACCOUNT-ID]:root"
  },
  "Action": [
    "kms:Decrypt",
    "kms:CreateGrant"
  ],
  "Resource": "*"
}
```

## Recovery Objectives

### RPO (Recovery Point Objective)

**Definition**: Maximum acceptable data loss measured in time

**RDS RPO:**
- **Automated Backups**: 5 minutes (transaction log frequency)
- **Manual Snapshots**: Time since last snapshot
- **Multi-AZ**: 0 seconds (synchronous replication)

**Improving RPO:**
- Reduce backup retention increases cost but improves options
- Use Multi-AZ for zero data loss
- Create manual snapshots before critical operations
- Enable transaction log backups (automatic with automated backups)

### RTO (Recovery Time Objective)

**Definition**: Maximum acceptable downtime for recovery

**RDS RTO:**
- **PITR**: 30-60 minutes (depends on DB size and log replay)
- **Snapshot Restore**: 20-45 minutes (depends on DB size)
- **Multi-AZ Failover**: 1-2 minutes (automatic)

**Improving RTO:**
- Use Multi-AZ for fastest recovery
- Maintain smaller databases for faster restore
- Pre-provision standby instances
- Automate restore procedures
- Regular restore testing

## Monitoring and Verification

### Backup Monitoring

**CloudWatch Metrics:**
- Backup retention period
- Automated backup status
- Snapshot creation time
- Backup storage used

**CloudWatch Events:**
- Backup started
- Backup completed
- Backup failed
- Snapshot created

**Monitoring Script:**
```bash
# Check backup status
aws rds describe-db-instances \
    --db-instance-identifier mydb \
    --query 'DBInstances[0].[BackupRetentionPeriod,PreferredBackupWindow,LatestRestorableTime]'

# List recent automated backups
aws rds describe-db-snapshots \
    --db-instance-identifier mydb \
    --snapshot-type automated \
    --max-records 10
```

### Restore Verification

**Data Integrity Checks:**
```sql
-- Verify row counts
SELECT COUNT(*) FROM important_table;

-- Check timestamp ranges
SELECT MIN(created_at), MAX(created_at) FROM important_table;

-- Verify specific records
SELECT * FROM important_table WHERE id = 12345;

-- Check data consistency
SELECT table_name, checksum FROM table_checksums;
```

**Application Testing:**
1. Connect application to restored instance
2. Run smoke tests
3. Verify critical functionality
4. Check data consistency
5. Validate timestamps

## Troubleshooting

### Backup Issues

**Automated Backups Not Running:**
```bash
# Check backup retention period (must be > 0)
aws rds describe-db-instances \
    --db-instance-identifier mydb \
    --query 'DBInstances[0].BackupRetentionPeriod'

# Verify backup window
aws rds describe-db-instances \
    --db-instance-identifier mydb \
    --query 'DBInstances[0].PreferredBackupWindow'
```

**Snapshot Creation Fails:**
- Check IAM permissions
- Verify sufficient storage quota
- Check for ongoing maintenance operations
- Review CloudWatch Logs for errors

### Restore Issues

**PITR Fails:**
```bash
# Verify restore time is within retention period
aws rds describe-db-instances \
    --db-instance-identifier mydb \
    --query 'DBInstances[0].[LatestRestorableTime,BackupRetentionPeriod]'

# Check automated backups are enabled
aws rds describe-db-instances \
    --db-instance-identifier mydb \
    --query 'DBInstances[0].BackupRetentionPeriod'
```

**Snapshot Restore Fails:**
- Verify snapshot exists and is available
- Check IAM permissions
- Ensure sufficient quota for new instance
- Verify subnet group and security groups exist
- Check KMS key permissions for encrypted snapshots

### Performance Issues

**Slow Restore:**
- Large databases take longer to restore
- Transaction log replay can be time-consuming
- Network latency for cross-region restores
- Consider using Read Replicas for faster recovery

**Backup Impact:**
- Single-AZ: Backup may cause I/O suspension
- Multi-AZ: Backup taken from standby (no impact)
- Use Multi-AZ for production workloads

## Best Practices

### Backup Strategy

1. Enable automated backups for all production databases
2. Set retention period based on RPO requirements (7-30 days typical)
3. Create manual snapshots before major changes
4. Schedule backups during low-traffic periods
5. Test restore procedures regularly (monthly recommended)

### Disaster Recovery

1. Copy snapshots to multiple regions
2. Document restore procedures
3. Automate restore testing
4. Define and measure RPO/RTO
5. Use Multi-AZ for high availability

### Cost Optimization

1. Optimize backup retention period
2. Delete unnecessary manual snapshots
3. Use lifecycle policies for old backups
4. Monitor backup storage usage
5. Consider AWS Backup for centralized management

### Security

1. Enable encryption for all backups
2. Use customer-managed KMS keys
3. Implement least privilege IAM policies
4. Audit snapshot sharing
5. Enable CloudTrail logging

### Operational Excellence

1. Automate backup and restore procedures
2. Monitor backup success/failure
3. Document recovery procedures
4. Train team on restore operations
5. Conduct regular DR drills

## Cost Analysis

### Backup Storage Costs

**Free Tier:**
- Backup storage up to 100% of DB storage is free
- Example: 100 GB DB = 100 GB free backup storage

**Additional Storage:**
- $0.095/GB-month for storage beyond free tier
- Example: 100 GB DB with 200 GB backups = 100 GB charged = $9.50/month

**Cross-Region Copy:**
- Snapshot storage in target region: $0.095/GB-month
- Data transfer: $0.02/GB (inter-region)
- Example: 100 GB snapshot copy = $9.50/month + $2.00 transfer

### Optimization Strategies

**Reduce Retention Period:**
- 35 days → 7 days can significantly reduce costs
- Balance between cost and recovery requirements

**Delete Old Manual Snapshots:**
- Review snapshots regularly
- Delete snapshots no longer needed
- Implement automated cleanup policies

**Optimize Cross-Region Copies:**
- Copy only critical snapshots
- Use appropriate retention in DR region
- Consider snapshot lifecycle policies

## Next Steps

- Implement automated restore testing
- Configure AWS Backup for centralized management
- Set up cross-region disaster recovery
- Create runbooks for restore procedures
- Implement backup monitoring and alerting
- Test failover and recovery scenarios
- Document RPO/RTO requirements
- Explore database cloning for testing

## Lab Metadata

- **Domain**: Databases
- **Complexity Level**: Intermediate
- **Estimated Time**: 75 minutes
- **AWS Services**: RDS, S3, IAM, CloudWatch, AWS Backup
- **Key Concepts**: PITR, automated backups, snapshots, disaster recovery, RPO/RTO
- **Certification Alignment**: AWS Certified Solutions Architect - Associate (RDS backup and restore, disaster recovery)
