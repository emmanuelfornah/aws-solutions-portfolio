# Working with Amazon RDS Databases

## Overview

This lab demonstrates implementing Amazon RDS with Multi-AZ deployment for high availability, integrating AWS Secrets Manager for secure credential management, configuring SSL/TLS encryption for data in transit, and testing automatic failover capabilities. The implementation includes creating RDS MySQL instances with Multi-AZ configuration, storing database credentials in Secrets Manager, establishing encrypted connections using SSL certificates, and simulating failover scenarios to validate high availability architecture.

## AWS Services Used

- **Amazon RDS** - Managed relational database service with Multi-AZ deployment
- **AWS Secrets Manager** - Secure credential storage and rotation
- **Amazon VPC** - Network isolation with DB subnet groups
- **AWS IAM** - Database authentication and access control
- **Amazon CloudWatch** - Database monitoring and metrics

## Key Technologies

- **MySQL** - Relational database engine
- **Multi-AZ Deployment** - Synchronous replication for high availability
- **SSL/TLS** - Encrypted database connections
- **DB Subnet Groups** - Multi-AZ network configuration
- **Automated Backups** - Point-in-time recovery capability
- **Read Replicas** - Horizontal scaling for read workloads

## Architecture Overview

The architecture consists of an RDS MySQL instance deployed in Multi-AZ configuration with a primary instance in one Availability Zone and a synchronous standby replica in another AZ. Database credentials are stored securely in AWS Secrets Manager with automatic rotation enabled. Applications connect to the database using SSL/TLS encryption through a single DNS endpoint that automatically redirects to the active instance during failover events.

See [architecture.md](./architecture.md) for detailed architecture description and failover mechanisms.

## Objectives

- Create RDS MySQL instances with Multi-AZ deployment
- Configure DB subnet groups across multiple Availability Zones
- Integrate AWS Secrets Manager for credential management
- Enable SSL/TLS encryption for database connections
- Test automatic failover and measure downtime
- Configure automated backups and retention policies
- Monitor RDS metrics with CloudWatch
- Implement security best practices for RDS

## Key Learnings

- **Multi-AZ Architecture**: Understanding synchronous replication and automatic failover
- **High Availability**: Achieving 99.95% availability SLA with Multi-AZ
- **Secrets Management**: Secure credential storage with automatic rotation
- **SSL/TLS Configuration**: Enforcing encrypted connections to RDS
- **Failover Testing**: Simulating AZ failures and measuring recovery time
- **Backup Strategies**: Automated backups vs manual snapshots
- **Performance Impact**: Understanding Multi-AZ write latency overhead
- **Connection Handling**: Application retry logic for failover scenarios
- **Security Groups**: Restricting database access to specific sources

## Setup Instructions

### Prerequisites

- AWS account with RDS and Secrets Manager permissions
- VPC with subnets in at least 2 Availability Zones
- MySQL client installed locally or on EC2
- IAM permissions for RDS and Secrets Manager
- Understanding of relational database concepts

### Step 1: Create DB Subnet Group

Create a DB subnet group spanning multiple AZs:

```bash
# Run from your local machine with AWS CLI
./scripts/create-db-subnet-group.sh
```

This creates a DB subnet group with subnets in at least 2 AZs for Multi-AZ deployment.

### Step 2: Create Secrets Manager Secret

Store database credentials securely:

```bash
./scripts/create-db-secret.sh
```

This creates a secret containing:
- Database username
- Database password
- Database endpoint (updated after RDS creation)
- Database port

### Step 3: Create RDS MySQL Instance

Create RDS instance with Multi-AZ enabled:

```bash
./scripts/create-rds-instance.sh
```

This creates:
- RDS MySQL instance (db.t3.micro or larger)
- Multi-AZ deployment enabled
- Automated backups enabled (7-day retention)
- Encryption at rest enabled
- Enhanced monitoring enabled

### Step 4: Configure Security Groups

Set up security group rules for database access:

```bash
./scripts/configure-security-groups.sh
```

This configures:
- Inbound rule: MySQL port 3306 from application security group
- Outbound rule: All traffic (default)

### Step 5: Download SSL Certificate

Download RDS SSL certificate for encrypted connections:

```bash
./scripts/download-ssl-certificate.sh
```

This downloads the RDS CA certificate bundle for SSL/TLS connections.

### Step 6: Connect to Database

Connect to RDS using SSL and Secrets Manager credentials:

```bash
./scripts/connect-to-rds.sh
```

This script:
- Retrieves credentials from Secrets Manager
- Connects using MySQL client with SSL
- Verifies encrypted connection

### Step 7: Test Failover

Simulate failover to test high availability:

```bash
./scripts/test-failover.sh
```

This script:
- Forces a failover using AWS CLI
- Monitors failover progress
- Measures downtime duration
- Verifies automatic recovery

### Step 8: Monitor and Verify

Monitor RDS metrics and verify configuration:

```bash
# Check Multi-AZ status
aws rds describe-db-instances --db-instance-identifier mydb

# View CloudWatch metrics
./scripts/view-metrics.sh

# Verify SSL connection
./scripts/verify-ssl.sh
```

## Scripts and Configurations

### Scripts

All scripts are located in the `scripts/` directory:

- **create-db-subnet-group.sh** - Creates DB subnet group across AZs
- **create-db-secret.sh** - Creates Secrets Manager secret for credentials
- **create-rds-instance.sh** - Creates RDS MySQL instance with Multi-AZ
- **configure-security-groups.sh** - Sets up security group rules
- **download-ssl-certificate.sh** - Downloads RDS SSL certificate
- **connect-to-rds.sh** - Connects to RDS using SSL and Secrets Manager
- **test-failover.sh** - Tests automatic failover functionality
- **view-metrics.sh** - Displays CloudWatch metrics
- **verify-ssl.sh** - Verifies SSL/TLS connection
- **cleanup.sh** - Removes RDS instance and related resources

### Configuration Files

Configuration templates are located in the `configs/` directory:

- **db-parameter-group.json** - Custom DB parameter group settings
- **mysql-ssl.cnf** - MySQL client SSL configuration
- **secrets-manager-policy.json** - IAM policy for Secrets Manager access
- **security-group-rules.json** - Security group rule definitions
- **cloudwatch-alarms.json** - CloudWatch alarm configurations

## Multi-AZ Configuration

### Architecture Components

**Primary Instance:**
- Active database instance handling all read/write operations
- Located in primary Availability Zone
- Synchronously replicates to standby

**Standby Instance:**
- Passive replica in different Availability Zone
- Receives synchronous replication from primary
- Automatically promoted during failover
- Not accessible for read operations (use Read Replicas instead)

**DNS Endpoint:**
- Single CNAME record pointing to active instance
- Automatically updated during failover
- Applications use same endpoint regardless of failover

### Failover Scenarios

**Automatic Failover Triggers:**
- Primary AZ failure or network partition
- Primary instance failure (hardware, OS, database)
- Storage failure on primary instance
- Manual failover initiated by user
- Maintenance operations (patching, scaling)

**Failover Process:**
1. RDS detects primary instance failure
2. DNS CNAME updated to point to standby
3. Standby promoted to primary
4. New standby provisioned in different AZ
5. Synchronous replication resumed

**Failover Duration:**
- Typical: 60-120 seconds
- Depends on: Database size, transaction volume, DNS TTL
- Application impact: Connection errors during failover

### Performance Considerations

**Write Latency:**
- Multi-AZ adds ~5-10ms latency per write
- Due to synchronous replication to standby
- Read operations not affected

**Throughput:**
- No impact on read throughput
- Slight impact on write throughput
- Standby not available for read traffic

## Secrets Manager Integration

### Secret Structure

```json
{
  "username": "admin",
  "password": "[GENERATED-PASSWORD]",
  "engine": "mysql",
  "host": "mydb.c9akciq32.us-east-1.rds.amazonaws.com",
  "port": 3306,
  "dbname": "mydb"
}
```

### Automatic Rotation

**Rotation Configuration:**
- Rotation interval: 30, 60, or 90 days
- Lambda function handles rotation
- Zero-downtime rotation strategy
- Old credentials remain valid during rotation

**Rotation Process:**
1. Create new password in database
2. Update secret with new password
3. Test new credentials
4. Mark rotation complete
5. Old password deprecated after grace period

### Retrieving Credentials

**AWS CLI:**
```bash
aws secretsmanager get-secret-value \
    --secret-id rds/mydb/credentials \
    --query SecretString \
    --output text | jq -r '.password'
```

**Python (boto3):**
```python
import boto3
import json

client = boto3.client('secretsmanager')
response = client.get_secret_value(SecretId='rds/mydb/credentials')
secret = json.loads(response['SecretString'])
password = secret['password']
```

## SSL/TLS Configuration

### Enabling SSL Connections

**Download Certificate:**
```bash
wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
```

**MySQL Client Connection:**
```bash
mysql -h mydb.c9akciq32.us-east-1.rds.amazonaws.com \
      -u admin \
      -p \
      --ssl-ca=global-bundle.pem \
      --ssl-mode=REQUIRED
```

**Verify SSL Connection:**
```sql
SHOW STATUS LIKE 'Ssl_cipher';
-- Should return cipher name if SSL is active
```

### Enforcing SSL

**Require SSL for All Connections:**
```sql
-- Create user requiring SSL
CREATE USER 'appuser'@'%' IDENTIFIED BY 'password' REQUIRE SSL;

-- Modify existing user
ALTER USER 'appuser'@'%' REQUIRE SSL;
```

**Parameter Group Setting:**
```json
{
  "ParameterGroupName": "mysql-ssl-required",
  "Parameters": [
    {
      "ParameterName": "require_secure_transport",
      "ParameterValue": "1"
    }
  ]
}
```

## Backup and Recovery

### Automated Backups

**Configuration:**
- Backup retention: 1-35 days (7 days recommended)
- Backup window: Preferred time for daily backups
- Maintenance window: Preferred time for updates
- Point-in-time recovery: Restore to any second within retention

**Backup Process:**
- Automated daily snapshots
- Transaction logs backed up every 5 minutes
- Stored in Amazon S3 (managed by RDS)
- No performance impact on Multi-AZ deployments

### Manual Snapshots

**Creating Snapshots:**
```bash
aws rds create-db-snapshot \
    --db-instance-identifier mydb \
    --db-snapshot-identifier mydb-snapshot-2024-01-15
```

**Restoring from Snapshot:**
```bash
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier mydb-restored \
    --db-snapshot-identifier mydb-snapshot-2024-01-15 \
    --multi-az
```

### Point-in-Time Recovery

**Restore to Specific Time:**
```bash
aws rds restore-db-instance-to-point-in-time \
    --source-db-instance-identifier mydb \
    --target-db-instance-identifier mydb-restored \
    --restore-time 2024-01-15T10:30:00Z \
    --multi-az
```

## Monitoring and Alerting

### CloudWatch Metrics

**Database Metrics:**
- **CPUUtilization**: CPU usage percentage
- **DatabaseConnections**: Number of active connections
- **FreeableMemory**: Available RAM
- **FreeStorageSpace**: Available disk space
- **ReadLatency / WriteLatency**: I/O latency
- **ReadThroughput / WriteThroughput**: I/O throughput
- **ReadIOPS / WriteIOPS**: I/O operations per second

**Multi-AZ Specific:**
- **ReplicaLag**: Replication lag (should be near zero)
- **FailoverLatency**: Time taken for last failover

### Recommended Alarms

**Critical:**
- CPUUtilization > 80%
- FreeStorageSpace < 10%
- DatabaseConnections > 80% of max

**Warning:**
- CPUUtilization > 60%
- FreeableMemory < 1 GB
- ReadLatency > 100ms

### Enhanced Monitoring

**Features:**
- OS-level metrics (1-60 second granularity)
- Process list and resource usage
- File system utilization
- Network statistics

**Enabling:**
```bash
aws rds modify-db-instance \
    --db-instance-identifier mydb \
    --monitoring-interval 60 \
    --monitoring-role-arn arn:aws:iam::[ACCOUNT-ID]:role/rds-monitoring-role
```

## Troubleshooting

### Connection Issues

**Cannot Connect to Database:**
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Verify DB instance status
aws rds describe-db-instances --db-instance-identifier mydb

# Test network connectivity
telnet mydb.c9akciq32.us-east-1.rds.amazonaws.com 3306
```

**SSL Connection Failures:**
```bash
# Verify certificate is valid
openssl verify -CAfile global-bundle.pem global-bundle.pem

# Check SSL is enabled on RDS
aws rds describe-db-instances \
    --db-instance-identifier mydb \
    --query 'DBInstances[0].CACertificateIdentifier'
```

### Failover Issues

**Failover Taking Too Long:**
- Check application connection timeout settings
- Verify DNS TTL is set appropriately (< 30 seconds)
- Review transaction log size and activity
- Check for long-running transactions

**Application Not Reconnecting:**
- Implement connection retry logic
- Use connection pooling with health checks
- Set appropriate connection timeouts
- Handle transient errors gracefully

### Performance Issues

**High CPU Utilization:**
```sql
-- Identify slow queries
SELECT * FROM mysql.slow_log ORDER BY query_time DESC LIMIT 10;

-- Check for missing indexes
SHOW INDEXES FROM table_name;

-- Analyze query execution plan
EXPLAIN SELECT * FROM table_name WHERE condition;
```

**High Write Latency:**
- Multi-AZ adds replication latency
- Check network connectivity between AZs
- Review IOPS provisioning (if using Provisioned IOPS)
- Consider upgrading instance class

## Security Best Practices

### Network Security

- Deploy RDS in private subnets (no public access)
- Use security groups to restrict access to specific sources
- Enable VPC Flow Logs for network monitoring
- Use VPC endpoints for AWS service access

### Access Control

- Use IAM database authentication where possible
- Implement least privilege for database users
- Rotate credentials regularly with Secrets Manager
- Audit database access with CloudTrail and database logs

### Encryption

- Enable encryption at rest using KMS
- Enforce SSL/TLS for all connections
- Use customer-managed KMS keys for compliance
- Encrypt automated backups and snapshots

### Monitoring and Auditing

- Enable Enhanced Monitoring for detailed metrics
- Configure CloudWatch alarms for anomalies
- Enable database audit logs
- Review security group changes with CloudTrail

## Cost Optimization

### Instance Sizing

- Start with smaller instance classes (db.t3.micro)
- Monitor CPU and memory utilization
- Scale vertically when needed
- Use Reserved Instances for production (up to 69% savings)

### Storage Optimization

- Use General Purpose (gp3) storage for most workloads
- Provision IOPS only when needed
- Monitor storage growth and set alarms
- Delete old manual snapshots

### Multi-AZ Costs

- Multi-AZ doubles instance costs
- No additional charge for data transfer
- Automated backups included
- Consider Single-AZ for dev/test environments

### Backup Costs

- Automated backups: Free up to DB size
- Additional backup storage: $0.095/GB-month
- Snapshot copy to another region: Data transfer charges
- Optimize retention period based on requirements

## Next Steps

- Implement Read Replicas for horizontal scaling
- Configure Performance Insights for query analysis
- Set up cross-region Read Replicas for disaster recovery
- Implement database parameter tuning
- Configure automated minor version upgrades
- Explore RDS Proxy for connection pooling
- Implement database activity streams for audit
- Test restore procedures regularly

## Lab Metadata

- **Domain**: Databases
- **Complexity Level**: Intermediate
- **Estimated Time**: 90 minutes
- **AWS Services**: RDS, Secrets Manager, VPC, IAM, CloudWatch
- **Key Concepts**: Multi-AZ, high availability, failover, SSL/TLS, credential management
- **Certification Alignment**: AWS Certified Solutions Architect - Associate (RDS Multi-AZ, high availability, security)
