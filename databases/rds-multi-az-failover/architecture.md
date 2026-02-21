# RDS Multi-AZ with Secrets Manager Architecture

## Architecture Overview

This architecture demonstrates Amazon RDS MySQL deployment with Multi-AZ configuration for high availability, integrated with AWS Secrets Manager for secure credential management and SSL/TLS encryption for data protection. The design provides automatic failover capabilities with minimal downtime, synchronous replication across Availability Zones, and secure credential storage with automatic rotation.

## Components

### 1. Amazon RDS MySQL Instance

RDS provides managed relational database service with automated administration tasks.

**Instance Configuration:**
- **Engine**: MySQL 8.0 or later
- **Instance Class**: db.t3.micro to db.r6g.16xlarge
- **Storage**: General Purpose (gp3) or Provisioned IOPS (io1)
- **Multi-AZ**: Enabled for high availability
- **Encryption**: At rest using AWS KMS
- **Automated Backups**: Enabled with 7-35 day retention

**Multi-AZ Deployment:**

| Component | Primary AZ | Standby AZ |
|-----------|------------|------------|
| Instance | Active (read/write) | Passive (standby) |
| Replication | Source | Synchronous replica |
| Accessibility | Application traffic | Not accessible |
| Failover Role | Can fail over | Promoted to primary |

### 2. Multi-AZ Architecture

Multi-AZ provides high availability through synchronous replication and automatic failover.

**Primary Instance:**
- Handles all database read and write operations
- Located in primary Availability Zone
- Synchronously replicates data to standby
- Monitored continuously by RDS service

**Standby Instance:**
- Passive replica in different Availability Zone
- Receives synchronous replication from primary
- Automatically promoted during failover events
- Cannot be used for read traffic (use Read Replicas instead)
- Maintains same configuration as primary

**Synchronous Replication:**
- Every write committed to primary is replicated to standby
- Write acknowledged only after standby confirms receipt
- Ensures zero data loss during failover (RPO = 0)
- Adds 5-10ms latency to write operations

**DNS Endpoint:**
- Single CNAME record: `mydb.c9akciq32.us-east-1.rds.amazonaws.com`
- Points to currently active instance
- Automatically updated during failover
- TTL typically 30 seconds
- Applications use same endpoint regardless of failover

### 3. DB Subnet Group

DB subnet groups define which subnets RDS can use for Multi-AZ deployment.

**Configuration:**
- Minimum 2 subnets in different Availability Zones
- Subnets must be in same VPC
- Subnets should be private (no internet gateway route)
- Each subnet must have sufficient IP addresses

**Example Structure:**
```
VPC: 10.0.0.0/16
├── Subnet 1 (us-east-1a): 10.0.1.0/24 - Primary
├── Subnet 2 (us-east-1b): 10.0.2.0/24 - Standby
└── Subnet 3 (us-east-1c): 10.0.3.0/24 - Optional
```

**Best Practices:**
- Use private subnets for security
- Ensure subnets span at least 2 AZs
- Allocate sufficient IP addresses (/24 or larger)
- Use consistent CIDR allocation across AZs

### 4. AWS Secrets Manager

Secrets Manager provides secure storage and automatic rotation of database credentials.

**Secret Structure:**
```json
{
  "username": "admin",
  "password": "[GENERATED-PASSWORD]",
  "engine": "mysql",
  "host": "mydb.c9akciq32.us-east-1.rds.amazonaws.com",
  "port": 3306,
  "dbname": "mydb",
  "dbInstanceIdentifier": "mydb"
}
```

**Features:**
- Automatic password generation
- Encryption at rest using KMS
- Automatic rotation (30, 60, or 90 days)
- Version management
- Fine-grained access control with IAM
- Audit logging with CloudTrail

**Rotation Process:**
1. Lambda function invoked on schedule
2. New password generated
3. Password updated in database
4. Secret updated with new password
5. Old password remains valid during grace period
6. Applications retrieve new password automatically

**Access Control:**
- IAM policies control who can read secrets
- Resource-based policies for cross-account access
- VPC endpoints for private access
- CloudTrail logs all access attempts

### 5. Security Groups

Security groups act as virtual firewalls controlling network access to RDS.

**RDS Security Group:**

**Inbound Rules:**
| Type | Protocol | Port | Source | Description |
|------|----------|------|--------|-------------|
| MySQL | TCP | 3306 | sg-app-xxxxx | Application servers |
| MySQL | TCP | 3306 | sg-bastion-xxxxx | Bastion host |

**Outbound Rules:**
| Type | Protocol | Port | Destination | Description |
|------|----------|------|-------------|-------------|
| All | All | All | 0.0.0.0/0 | Default outbound |

**Best Practices:**
- Use security group references instead of CIDR blocks
- Implement least privilege access
- Separate security groups by environment
- Document all rules with descriptions
- Regular audit of security group rules

### 6. SSL/TLS Encryption

SSL/TLS provides encryption for data in transit between applications and RDS.

**Certificate Authority:**
- AWS provides RDS CA certificates
- Global bundle includes all regional CAs
- Certificates valid for multiple years
- Automatic rotation by AWS

**Certificate Download:**
```bash
# Global bundle (all regions)
wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

# Region-specific
wget https://truststore.pki.rds.amazonaws.com/us-east-1/us-east-1-bundle.pem
```

**Connection Modes:**
- **DISABLED**: No SSL (not recommended)
- **PREFERRED**: SSL if available, fallback to unencrypted
- **REQUIRED**: SSL required, no certificate verification
- **VERIFY_CA**: SSL with CA verification
- **VERIFY_IDENTITY**: SSL with full certificate verification

**Enforcing SSL:**
```sql
-- Require SSL for specific user
CREATE USER 'appuser'@'%' IDENTIFIED BY 'password' REQUIRE SSL;

-- Require SSL for all connections (MySQL 8.0+)
-- Set in parameter group: require_secure_transport = 1
```

### 7. Automated Backups

RDS provides automated backups with point-in-time recovery capability.

**Backup Components:**
- **Automated Snapshots**: Daily full backups
- **Transaction Logs**: Backed up every 5 minutes
- **Retention Period**: 1-35 days (7 days default)
- **Backup Window**: Preferred time for daily backups

**Storage:**
- Stored in Amazon S3 (managed by RDS)
- Encrypted if source DB is encrypted
- No performance impact on Multi-AZ deployments
- Free backup storage up to DB size

**Point-in-Time Recovery:**
- Restore to any second within retention period
- Creates new DB instance
- Specify exact timestamp or use latest restorable time
- Maintains same configuration as source

**Manual Snapshots:**
- User-initiated snapshots
- Retained until explicitly deleted
- Can be copied to other regions
- Can be shared with other AWS accounts
- No impact on automated backup retention

### 8. CloudWatch Monitoring

CloudWatch provides comprehensive monitoring of RDS metrics and logs.

**Standard Metrics (1-minute granularity):**
- **CPUUtilization**: Percentage of CPU used
- **DatabaseConnections**: Number of active connections
- **FreeableMemory**: Available RAM
- **FreeStorageSpace**: Available disk space
- **ReadLatency / WriteLatency**: Average I/O latency
- **ReadThroughput / WriteThroughput**: Bytes per second
- **ReadIOPS / WriteIOPS**: Operations per second
- **NetworkReceiveThroughput / NetworkTransmitThroughput**: Network traffic

**Multi-AZ Specific Metrics:**
- **ReplicaLag**: Replication lag in seconds (should be near zero)
- **FailoverLatency**: Duration of last failover event

**Enhanced Monitoring (1-60 second granularity):**
- OS-level metrics
- Process list and CPU usage per process
- Memory usage breakdown
- File system utilization
- Network statistics

**Database Logs:**
- Error log
- Slow query log
- General log
- Audit log (MySQL Enterprise)

## Data Flow

### Normal Operation (Write)

1. **Application Request**: Application sends SQL INSERT/UPDATE/DELETE
2. **DNS Resolution**: Application resolves RDS endpoint to primary instance IP
3. **Connection**: Application connects to primary instance on port 3306
4. **SSL Handshake**: TLS connection established using RDS certificate
5. **Authentication**: Credentials validated (from Secrets Manager)
6. **Query Execution**: Primary instance processes write operation
7. **Synchronous Replication**: Data replicated to standby instance
8. **Standby Acknowledgment**: Standby confirms receipt of data
9. **Transaction Commit**: Primary commits transaction after standby confirms
10. **Response**: Success response sent to application
11. **Transaction Log**: Write logged for point-in-time recovery

**Latency Impact:**
- Synchronous replication adds 5-10ms per write
- Depends on network latency between AZs
- Read operations not affected

### Normal Operation (Read)

1. **Application Request**: Application sends SQL SELECT query
2. **DNS Resolution**: Endpoint resolves to primary instance
3. **Connection**: Application connects to primary instance
4. **SSL Handshake**: TLS connection established
5. **Authentication**: Credentials validated
6. **Query Execution**: Primary instance processes read operation
7. **Response**: Data returned to application

**Note**: Standby instance cannot serve read traffic. Use Read Replicas for read scaling.

### Failover Process

**Trigger Events:**
- Primary instance failure (hardware, OS, database crash)
- Primary AZ failure or network partition
- Storage failure on primary instance
- Manual failover initiated by user
- Maintenance operations (patching, instance scaling)

**Failover Steps:**

1. **Failure Detection** (10-30 seconds)
   - RDS monitoring detects primary instance failure
   - Health checks fail multiple times
   - Decision made to initiate failover

2. **DNS Update** (5-10 seconds)
   - RDS updates DNS CNAME record
   - Points to standby instance IP address
   - TTL typically 30 seconds

3. **Standby Promotion** (30-60 seconds)
   - Standby instance promoted to primary
   - Database recovery process completes
   - Instance becomes available for connections

4. **New Standby Provisioning** (5-10 minutes)
   - New standby instance launched in different AZ
   - Synchronous replication established
   - Multi-AZ configuration restored

**Total Failover Time:**
- Typical: 60-120 seconds
- Depends on: Database size, transaction volume, DNS propagation
- RPO (Recovery Point Objective): 0 seconds (no data loss)
- RTO (Recovery Time Objective): 1-2 minutes

**Application Impact:**
- Connection errors during failover
- Applications should implement retry logic
- Connection pools should validate connections
- Transactions in progress will fail and need retry

### Secrets Manager Integration

**Credential Retrieval:**

1. **Application Startup**: Application needs database credentials
2. **IAM Authentication**: Application uses IAM role credentials
3. **API Call**: GetSecretValue API called with secret ARN
4. **Authorization**: IAM policy evaluated for permissions
5. **Decryption**: Secret decrypted using KMS key
6. **Response**: Credentials returned to application
7. **Connection**: Application connects to RDS using credentials
8. **Caching**: Application caches credentials (with refresh logic)

**Automatic Rotation:**

1. **Scheduled Trigger**: CloudWatch Events triggers rotation
2. **Lambda Invocation**: Rotation Lambda function invoked
3. **Create Secret**: New password generated
4. **Set Secret**: New password set in database
5. **Test Secret**: Connection tested with new password
6. **Finish Secret**: Secret updated with new password
7. **Notification**: CloudWatch Events published for monitoring

**Rotation Strategies:**
- **Single User**: Rotate password for single user (brief downtime)
- **Alternating Users**: Rotate between two users (zero downtime)
- **Multi-User**: Rotate multiple users on schedule

### Backup and Restore Flow

**Automated Backup:**

1. **Scheduled Trigger**: Daily backup window begins
2. **Snapshot Creation**: RDS creates storage volume snapshot
3. **Multi-AZ Optimization**: Snapshot taken from standby (no performance impact)
4. **S3 Upload**: Snapshot uploaded to S3 (managed by RDS)
5. **Encryption**: Snapshot encrypted if source DB encrypted
6. **Transaction Logs**: Continuous log backup every 5 minutes
7. **Retention**: Old backups deleted per retention policy

**Point-in-Time Restore:**

1. **Restore Request**: User specifies restore time
2. **Snapshot Selection**: RDS selects appropriate automated snapshot
3. **Transaction Log Replay**: Logs replayed to specified time
4. **New Instance Creation**: New DB instance created
5. **Data Restoration**: Data restored to new instance
6. **Configuration**: Same configuration as source instance
7. **Availability**: New instance becomes available
8. **Verification**: User validates restored data

## High Availability Architecture

### Availability Zones

**Multi-AZ Deployment:**
```
Region: us-east-1
├── AZ 1 (us-east-1a)
│   ├── Primary RDS Instance
│   ├── Application Servers
│   └── NAT Gateway
├── AZ 2 (us-east-1b)
│   ├── Standby RDS Instance
│   ├── Application Servers
│   └── NAT Gateway
└── AZ 3 (us-east-1c)
    ├── Application Servers
    └── NAT Gateway
```

**Benefits:**
- Protection against AZ failures
- Zero data loss (RPO = 0)
- Automatic failover (RTO = 1-2 minutes)
- No manual intervention required
- Transparent to applications (same endpoint)

### Failure Scenarios

**Scenario 1: Primary Instance Failure**
- **Cause**: Database crash, OS failure, hardware failure
- **Detection**: 10-30 seconds
- **Failover**: Automatic to standby
- **Downtime**: 60-120 seconds
- **Data Loss**: None (synchronous replication)

**Scenario 2: Primary AZ Failure**
- **Cause**: Power outage, network partition, natural disaster
- **Detection**: 10-30 seconds
- **Failover**: Automatic to standby in different AZ
- **Downtime**: 60-120 seconds
- **Data Loss**: None

**Scenario 3: Storage Failure**
- **Cause**: EBS volume failure
- **Detection**: Immediate
- **Failover**: Automatic to standby
- **Downtime**: 60-120 seconds
- **Data Loss**: None

**Scenario 4: Maintenance Operations**
- **Cause**: Patching, scaling, parameter changes
- **Detection**: Scheduled
- **Failover**: Controlled failover to standby
- **Downtime**: 60-120 seconds
- **Data Loss**: None

### Application Resilience

**Connection Retry Logic:**
```python
import mysql.connector
from mysql.connector import Error
import time

def connect_with_retry(max_retries=3, retry_delay=5):
    for attempt in range(max_retries):
        try:
            connection = mysql.connector.connect(
                host='mydb.c9akciq32.us-east-1.rds.amazonaws.com',
                user='admin',
                password=get_password_from_secrets_manager(),
                database='mydb',
                ssl_ca='global-bundle.pem',
                ssl_verify_cert=True
            )
            return connection
        except Error as e:
            if attempt < max_retries - 1:
                time.sleep(retry_delay)
            else:
                raise
```

**Connection Pool Configuration:**
- Set connection timeout (e.g., 30 seconds)
- Implement connection validation
- Configure retry logic for transient errors
- Set appropriate pool size
- Enable connection health checks

## Performance Characteristics

### Write Performance

**Multi-AZ Impact:**
- Synchronous replication adds 5-10ms latency
- Latency depends on network between AZs
- Throughput not significantly impacted
- IOPS capacity same as Single-AZ

**Optimization:**
- Use Provisioned IOPS for consistent performance
- Batch writes when possible
- Use appropriate instance class for workload
- Optimize queries and indexes

### Read Performance

**Multi-AZ Configuration:**
- Reads served only by primary instance
- Standby not accessible for read traffic
- No performance benefit for reads
- Use Read Replicas for read scaling

**Read Replica Architecture:**
```
Primary (Multi-AZ)
├── Standby (synchronous)
└── Read Replicas (asynchronous)
    ├── Read Replica 1 (us-east-1a)
    ├── Read Replica 2 (us-east-1b)
    └── Read Replica 3 (us-west-2a) - Cross-region
```

### Storage Performance

**General Purpose (gp3):**
- Baseline: 3,000 IOPS, 125 MB/s
- Scalable: Up to 16,000 IOPS, 1,000 MB/s
- Cost-effective for most workloads
- Predictable performance

**Provisioned IOPS (io1/io2):**
- Up to 64,000 IOPS per instance
- Up to 1,000 MB/s throughput
- Consistent low-latency performance
- Higher cost

## Security Architecture

### Network Security

**VPC Isolation:**
- RDS deployed in private subnets
- No direct internet access
- Access through security groups
- VPC Flow Logs for monitoring

**Security Group Layers:**
```
Application Tier
├── ALB Security Group (443 from Internet)
├── App Security Group (443 from ALB)
└── RDS Security Group (3306 from App)
```

**Network ACLs:**
- Subnet-level firewall
- Stateless rules
- Additional layer of defense
- Typically allow all for RDS subnets

### Encryption

**At Rest:**
- AES-256 encryption
- AWS KMS managed keys
- Customer-managed keys (CMK) supported
- Encrypts: Data, backups, snapshots, logs, replicas

**In Transit:**
- TLS 1.2 or higher
- RDS-provided certificates
- Certificate verification supported
- Can be enforced via parameter group

**Key Management:**
- Separate KMS keys per environment
- Key rotation enabled
- Key policies for access control
- CloudTrail logging of key usage

### Access Control

**IAM Database Authentication:**
- Token-based authentication
- No passwords in application code
- 15-minute token validity
- Integrated with IAM policies

**Database Users:**
- Separate users per application
- Least privilege permissions
- SSL required for all users
- Regular password rotation (via Secrets Manager)

**Audit Logging:**
- CloudTrail: API calls to RDS
- Database logs: Query activity
- Enhanced Monitoring: OS-level activity
- VPC Flow Logs: Network traffic

## Cost Analysis

### Instance Costs

**Multi-AZ Pricing:**
- 2x instance cost (primary + standby)
- Same instance class for both
- No additional charge for replication
- No charge for failover operations

**Example (us-east-1):**
| Instance Class | Single-AZ | Multi-AZ | Monthly Cost |
|----------------|-----------|----------|--------------|
| db.t3.micro | $0.017/hr | $0.034/hr | $24.48 |
| db.t3.small | $0.034/hr | $0.068/hr | $48.96 |
| db.t3.medium | $0.068/hr | $0.136/hr | $97.92 |
| db.r6g.large | $0.24/hr | $0.48/hr | $345.60 |

### Storage Costs

**General Purpose (gp3):**
- $0.115/GB-month
- 3,000 IOPS included
- Additional IOPS: $0.005 per IOPS-month
- Additional throughput: $0.04 per MB/s-month

**Provisioned IOPS (io1):**
- $0.125/GB-month
- $0.10 per IOPS-month
- Consistent performance
- Higher cost

**Backup Storage:**
- Free up to 100% of DB storage
- Additional: $0.095/GB-month
- Snapshots in same region
- Cross-region copy: $0.095/GB-month + data transfer

### Secrets Manager Costs

**Pricing:**
- $0.40 per secret per month
- $0.05 per 10,000 API calls
- Free tier: 30-day trial

**Example:**
- 1 secret: $0.40/month
- 100,000 API calls: $0.50/month
- Total: $0.90/month

### Total Cost Example

**Scenario: Production database**
- Instance: db.t3.medium Multi-AZ
- Storage: 100 GB gp3
- Backups: 100 GB (within free tier)
- Secrets Manager: 1 secret

**Monthly Cost:**
- Instance: $97.92
- Storage: $11.50
- Backups: $0 (within free tier)
- Secrets Manager: $0.40
- **Total: $109.82/month**

### Cost Optimization

**Reserved Instances:**
- 1-year: ~40% savings
- 3-year: ~60% savings
- All Upfront, Partial Upfront, No Upfront options

**Right-Sizing:**
- Monitor CPU and memory utilization
- Start small and scale up as needed
- Use CloudWatch metrics for sizing decisions

**Storage Optimization:**
- Use gp3 instead of io1 when possible
- Delete old manual snapshots
- Optimize backup retention period

## Monitoring and Alerting

### Key Metrics to Monitor

**Availability:**
- Database connection success rate
- Failover events
- Instance status

**Performance:**
- CPU utilization (< 80%)
- Memory utilization (> 20% free)
- Storage space (> 20% free)
- IOPS utilization (< 80%)
- Connection count (< max_connections)

**Replication:**
- Replica lag (< 1 second)
- Replication errors

### CloudWatch Alarms

**Critical Alarms:**
```json
{
  "AlarmName": "RDS-High-CPU",
  "MetricName": "CPUUtilization",
  "Threshold": 80,
  "ComparisonOperator": "GreaterThanThreshold",
  "EvaluationPeriods": 2,
  "Period": 300
}
```

**Warning Alarms:**
- CPU > 60%
- Free storage < 20%
- Database connections > 80% of max
- Read/Write latency > 100ms

### Logging

**CloudWatch Logs:**
- Error log: Database errors and warnings
- Slow query log: Queries exceeding threshold
- General log: All queries (high overhead)
- Audit log: Security-relevant events

**Log Retention:**
- Error log: 30 days
- Slow query log: 7 days
- General log: 1 day (if enabled)
- CloudTrail: 90 days

## Best Practices

### High Availability

1. Always use Multi-AZ for production databases
2. Test failover procedures regularly
3. Implement application retry logic
4. Set appropriate connection timeouts
5. Monitor failover metrics and duration

### Security

1. Deploy RDS in private subnets
2. Enable encryption at rest and in transit
3. Use Secrets Manager for credential management
4. Implement least privilege access
5. Enable audit logging and monitoring

### Performance

1. Right-size instance class based on workload
2. Use appropriate storage type (gp3 vs io1)
3. Implement connection pooling
4. Optimize queries and indexes
5. Monitor CloudWatch metrics regularly

### Backup and Recovery

1. Enable automated backups with appropriate retention
2. Test restore procedures regularly
3. Create manual snapshots before major changes
4. Consider cross-region backup copies for DR
5. Document recovery procedures

### Cost Management

1. Use Reserved Instances for production
2. Right-size instances based on utilization
3. Optimize backup retention periods
4. Delete unnecessary manual snapshots
5. Use Single-AZ for dev/test environments
