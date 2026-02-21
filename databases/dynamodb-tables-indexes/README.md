# Working with Amazon DynamoDB Tables and Indexes

## Overview

This lab demonstrates creating and managing Amazon DynamoDB tables with partition keys, sort keys, and global secondary indexes (GSIs). The implementation includes designing efficient key schemas, creating tables with on-demand and provisioned capacity modes, implementing GSIs for alternate query patterns, performing queries and scans, and understanding DynamoDB best practices for performance and cost optimization.

## AWS Services Used

- **Amazon DynamoDB** - Fully managed NoSQL database
- **AWS IAM** - DynamoDB access permissions
- **Amazon CloudWatch** - Table metrics and monitoring
- **AWS CLI** - Table management and operations

## Key Technologies

- **Partition Key** - Primary key for data distribution
- **Sort Key** - Optional key for sorting within partition
- **Global Secondary Index (GSI)** - Alternate query patterns
- **Local Secondary Index (LSI)** - Alternate sort key
- **Capacity Modes** - On-demand vs provisioned
- **Query Operations** - Efficient key-based retrieval
- **Scan Operations** - Full table scans

## Architecture Overview

The architecture consists of DynamoDB tables with carefully designed partition and sort keys for efficient data distribution and access patterns. Global secondary indexes provide alternate query capabilities without duplicating data. The service automatically distributes data across multiple partitions based on partition key values, ensuring horizontal scalability and consistent performance.

See [architecture.md](./architecture.md) for detailed table design and indexing strategies.

## Objectives

- Design effective partition and sort key schemas
- Create DynamoDB tables with appropriate capacity modes
- Implement global secondary indexes for alternate queries
- Perform efficient query and scan operations
- Understand partition key distribution and hot partitions
- Configure table settings for performance and cost
- Monitor table metrics with CloudWatch
- Implement best practices for DynamoDB design

## Key Learnings

- **Key Design**: Choosing partition and sort keys for access patterns
- **GSI Implementation**: Creating indexes for alternate query patterns
- **Capacity Modes**: On-demand vs provisioned capacity
- **Query Efficiency**: Using keys vs scanning tables
- **Data Distribution**: Avoiding hot partitions
- **Index Projections**: Optimizing GSI attribute projections
- **Consistency Models**: Eventual vs strong consistency
- **Cost Optimization**: Balancing performance and cost

## Setup Instructions

### Prerequisites

- AWS account with DynamoDB permissions
- AWS CLI configured
- Understanding of NoSQL concepts
- Familiarity with access patterns

### Step 1: Design Table Schema

Plan partition and sort keys:

```bash
./scripts/design-schema.sh
```

### Step 2: Create DynamoDB Table

Create table with keys:

```bash
./scripts/create-table.sh
```

### Step 3: Add Global Secondary Index

Create GSI for alternate queries:

```bash
./scripts/create-gsi.sh
```

### Step 4: Load Sample Data

Populate table with test data:

```bash
./scripts/load-sample-data.sh
```

### Step 5: Perform Query Operations

Execute efficient queries:

```bash
./scripts/query-examples.sh
```

### Step 6: Test GSI Queries

Query using secondary index:

```bash
./scripts/query-gsi.sh
```

### Step 7: Monitor Performance

View CloudWatch metrics:

```bash
./scripts/monitor-table.sh
```

## Scripts and Configurations

### Scripts

- **design-schema.sh** - Schema design helper
- **create-table.sh** - Creates DynamoDB table
- **create-gsi.sh** - Adds global secondary index
- **load-sample-data.sh** - Loads test data
- **query-examples.sh** - Query operation examples
- **query-gsi.sh** - GSI query examples
- **monitor-table.sh** - CloudWatch metrics
- **cleanup.sh** - Deletes table and indexes

### Configuration Files

- **table-schema.json** - Table definition
- **gsi-definition.json** - GSI configuration
- **sample-data.json** - Test data
- **query-patterns.json** - Common query examples

## Lab Metadata

- **Domain**: Databases
- **Complexity Level**: Intermediate
- **Estimated Time**: 60 minutes
- **AWS Services**: DynamoDB, IAM, CloudWatch
- **Key Concepts**: NoSQL, partition keys, indexes, queries
- **Certification Alignment**: AWS Certified Developer - Associate (DynamoDB design and operations)
