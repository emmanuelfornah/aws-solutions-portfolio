# Introduction to AWS Database Migration Service

## Overview

This lab demonstrates using AWS Database Migration Service (DMS) to migrate databases from MySQL to Amazon Aurora with minimal downtime. The implementation includes setting up DMS replication instances, configuring source and target endpoints, creating migration tasks with full load and change data capture (CDC), monitoring migration progress, and validating data integrity post-migration.

## AWS Services Used

- **AWS DMS** - Database migration and replication service
- **Amazon RDS MySQL** - Source database
- **Amazon Aurora MySQL** - Target database
- **Amazon VPC** - Network configuration for DMS
- **AWS IAM** - DMS service roles and permissions
- **Amazon CloudWatch** - Migration monitoring and logs

## Key Technologies

- **Replication Instance** - DMS compute resource for migration
- **Source Endpoint** - Connection to source MySQL database
- **Target Endpoint** - Connection to Aurora target database
- **Migration Task** - Full load and CDC configuration
- **Change Data Capture (CDC)** - Continuous replication
- **Table Mappings** - Selection and transformation rules

## Architecture Overview

The architecture consists of a DMS replication instance deployed in a VPC with connectivity to both source MySQL RDS and target Aurora databases. The replication instance reads data from the source endpoint, transforms it as needed, and writes to the target endpoint. Full load migration transfers existing data, while CDC captures ongoing changes for near-zero downtime migration.

See [architecture.md](./architecture.md) for detailed migration architecture and data flow.

## Objectives

- Set up DMS replication instances with appropriate sizing
- Configure source and target database endpoints
- Create migration tasks with full load and CDC
- Monitor migration progress and performance
- Validate data integrity and consistency
- Implement table mapping and transformation rules
- Handle migration errors and troubleshooting
- Perform cutover with minimal downtime

## Key Learnings

- **DMS Architecture**: Understanding replication instances and endpoints
- **Migration Types**: Full load, CDC, and full load + CDC
- **Endpoint Configuration**: Connecting to various database engines
- **Table Mappings**: Selecting tables and applying transformations
- **CDC Implementation**: Capturing ongoing changes during migration
- **Performance Tuning**: Optimizing replication instance and task settings
- **Validation**: Ensuring data integrity post-migration
- **Cutover Strategy**: Minimizing downtime during final cutover

## Setup Instructions

### Prerequisites

- AWS account with DMS permissions
- Source MySQL RDS instance with data
- Target Aurora MySQL cluster
- VPC with subnets for DMS replication instance
- IAM roles for DMS service
- Binary logging enabled on source MySQL

### Step 1: Enable Binary Logging on Source

Enable binary logging for CDC:

```bash
./scripts/enable-binary-logging.sh
```

### Step 2: Create DMS Replication Instance

Create replication instance:

```bash
./scripts/create-replication-instance.sh
```

### Step 3: Create Source Endpoint

Configure source MySQL endpoint:

```bash
./scripts/create-source-endpoint.sh
```

### Step 4: Create Target Endpoint

Configure target Aurora endpoint:

```bash
./scripts/create-target-endpoint.sh
```

### Step 5: Test Endpoint Connections

Verify connectivity:

```bash
./scripts/test-endpoints.sh
```

### Step 6: Create Migration Task

Create task with full load and CDC:

```bash
./scripts/create-migration-task.sh
```

### Step 7: Monitor Migration

Monitor progress:

```bash
./scripts/monitor-migration.sh
```

### Step 8: Validate Data

Verify data integrity:

```bash
./scripts/validate-migration.sh
```

## Scripts and Configurations

### Scripts

- **enable-binary-logging.sh** - Enables binary logging on source
- **create-replication-instance.sh** - Creates DMS replication instance
- **create-source-endpoint.sh** - Configures source endpoint
- **create-target-endpoint.sh** - Configures target endpoint
- **test-endpoints.sh** - Tests endpoint connectivity
- **create-migration-task.sh** - Creates migration task
- **monitor-migration.sh** - Monitors migration progress
- **validate-migration.sh** - Validates data integrity
- **cleanup.sh** - Removes DMS resources

### Configuration Files

- **table-mappings.json** - Table selection and transformation rules
- **task-settings.json** - Migration task configuration
- **replication-instance-config.json** - Replication instance settings

## Lab Metadata

- **Domain**: Databases
- **Complexity Level**: Advanced
- **Estimated Time**: 120 minutes
- **AWS Services**: DMS, RDS, Aurora, VPC, IAM, CloudWatch
- **Key Concepts**: Database migration, CDC, replication, data validation
- **Certification Alignment**: AWS Certified Database - Specialty (DMS, migration strategies)
