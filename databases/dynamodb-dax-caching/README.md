# Configuring a DAX Cluster for Caching with Amazon DynamoDB

## Overview

This lab demonstrates implementing Amazon DynamoDB Accelerator (DAX) for microsecond-latency caching of DynamoDB data. The implementation includes creating DAX clusters, configuring cache settings, modifying applications to use DAX endpoints, measuring performance improvements, and understanding DAX architecture and use cases for read-heavy workloads.

## AWS Services Used

- **Amazon DynamoDB** - NoSQL database
- **Amazon DAX** - In-memory caching for DynamoDB
- **Amazon VPC** - Network configuration for DAX
- **AWS IAM** - DAX service roles and permissions
- **Amazon CloudWatch** - DAX metrics and monitoring

## Key Technologies

- **DAX Cluster** - Managed in-memory cache
- **Item Cache** - Individual item caching
- **Query Cache** - Query result caching
- **Write-Through Cache** - Automatic cache updates
- **Cache TTL** - Time-to-live for cached data
- **Cluster Nodes** - Multi-node cache cluster

## Architecture Overview

The architecture consists of a DAX cluster deployed in a VPC with multiple cache nodes for high availability. Applications connect to the DAX cluster endpoint instead of directly to DynamoDB. DAX provides read-through and write-through caching, automatically retrieving data from DynamoDB on cache misses and updating the cache on writes. This reduces DynamoDB read capacity consumption and provides microsecond response times for cached data.

See [architecture.md](./architecture.md) for detailed DAX architecture and caching strategies.

## Objectives

- Create and configure DAX clusters
- Implement DAX in application code
- Configure cache TTL and eviction policies
- Measure performance improvements with DAX
- Monitor DAX metrics with CloudWatch
- Understand DAX use cases and limitations
- Implement DAX best practices
- Optimize costs with caching

## Key Learnings

- **DAX Architecture**: Understanding in-memory caching
- **Cache Types**: Item cache vs query cache
- **Write-Through**: Automatic cache updates
- **Performance Gains**: Microsecond latency for cached reads
- **Cost Optimization**: Reducing DynamoDB read capacity
- **High Availability**: Multi-node cluster configuration
- **Use Cases**: Read-heavy workloads, hot keys
- **Limitations**: Eventually consistent reads only

## Setup Instructions

### Prerequisites

- AWS account with DAX permissions
- DynamoDB table with data
- VPC with subnets for DAX cluster
- IAM role for DAX service
- Application code to modify

### Step 1: Create DAX Subnet Group

Configure network:

```bash
./scripts/create-dax-subnet-group.sh
```

### Step 2: Create DAX Cluster

Create cache cluster:

```bash
./scripts/create-dax-cluster.sh
```

### Step 3: Configure Security Groups

Set up access rules:

```bash
./scripts/configure-security-groups.sh
```

### Step 4: Modify Application Code

Update to use DAX:

```bash
./scripts/update-application.sh
```

### Step 5: Test Performance

Measure latency improvements:

```bash
./scripts/test-performance.sh
```

### Step 6: Monitor DAX Metrics

View CloudWatch metrics:

```bash
./scripts/monitor-dax.sh
```

## Scripts and Configurations

### Scripts

- **create-dax-subnet-group.sh** - Creates subnet group
- **create-dax-cluster.sh** - Creates DAX cluster
- **configure-security-groups.sh** - Sets up security
- **update-application.sh** - Modifies app code
- **test-performance.sh** - Measures performance
- **monitor-dax.sh** - Views metrics
- **cleanup.sh** - Removes DAX resources

### Configuration Files

- **dax-cluster-config.json** - Cluster settings
- **cache-policy.json** - TTL configuration
- **application-config.py** - DAX client code
- **performance-test.sh** - Benchmark script

## Lab Metadata

- **Domain**: Databases
- **Complexity Level**: Advanced
- **Estimated Time**: 90 minutes
- **AWS Services**: DynamoDB, DAX, VPC, IAM, CloudWatch
- **Key Concepts**: In-memory caching, performance optimization, read-heavy workloads
- **Certification Alignment**: AWS Certified Database - Specialty (DAX, caching strategies)
