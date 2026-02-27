# Adjusting Table Capacity in Amazon DynamoDB

## Overview

This lab demonstrates managing DynamoDB table capacity with provisioned and on-demand modes, implementing auto scaling for dynamic workloads, monitoring capacity metrics with CloudWatch, and optimizing costs through appropriate capacity planning. The implementation includes configuring read and write capacity units, setting up auto scaling policies, analyzing CloudWatch metrics for capacity planning, and switching between capacity modes.

## AWS Services Used

- **Amazon DynamoDB** - NoSQL database with flexible capacity
- **Application Auto Scaling** - Automatic capacity adjustment
- **Amazon CloudWatch** - Capacity metrics and alarms
- **AWS IAM** - Auto scaling service roles

## Key Technologies

- **Provisioned Capacity** - Fixed RCU/WCU allocation
- **On-Demand Capacity** - Pay-per-request pricing
- **Auto Scaling** - Dynamic capacity adjustment
- **Read Capacity Units (RCU)** - Read throughput
- **Write Capacity Units (WCU)** - Write throughput
- **CloudWatch Metrics** - Capacity utilization monitoring

## Architecture Overview

The architecture demonstrates DynamoDB capacity management with provisioned capacity mode using auto scaling to automatically adjust read and write capacity units based on utilization. CloudWatch monitors consumed capacity and triggers scaling policies when thresholds are exceeded. On-demand mode provides an alternative for unpredictable workloads with automatic scaling.

See [architecture.md](./architecture.md) for detailed capacity management strategies.

## Objectives

- Configure provisioned capacity for tables and indexes
- Implement auto scaling policies for dynamic workloads
- Monitor capacity utilization with CloudWatch
- Switch between provisioned and on-demand modes
- Optimize costs through capacity planning
- Handle throttling and capacity exceptions
- Understand RCU and WCU calculations
- Implement capacity best practices

## Key Learnings

- **Capacity Modes**: Provisioned vs on-demand
- **Auto Scaling**: Target tracking policies
- **RCU/WCU Calculation**: Understanding capacity units
- **Throttling**: Handling capacity exceeded errors
- **Cost Optimization**: Balancing performance and cost
- **Burst Capacity**: Temporary capacity buffer
- **GSI Capacity**: Independent index capacity
- **Monitoring**: CloudWatch metrics for capacity planning

## Setup Instructions

### Prerequisites

- AWS account with DynamoDB permissions
- Existing DynamoDB table
- Understanding of capacity concepts
- CloudWatch access for monitoring

### Step 1: Configure Provisioned Capacity

Set initial capacity:

```bash
./scripts/configure-provisioned-capacity.sh
```

### Step 2: Enable Auto Scaling

Configure auto scaling:

```bash
./scripts/enable-auto-scaling.sh
```

### Step 3: Generate Load

Create test workload:

```bash
./scripts/generate-load.sh
```

### Step 4: Monitor Capacity

View CloudWatch metrics:

```bash
./scripts/monitor-capacity.sh
```

### Step 5: Test Scaling

Verify auto scaling:

```bash
./scripts/test-scaling.sh
```

### Step 6: Switch to On-Demand

Change capacity mode:

```bash
./scripts/switch-to-on-demand.sh
```

## Scripts and Configurations

### Scripts

- **configure-provisioned-capacity.sh** - Sets RCU/WCU
- **enable-auto-scaling.sh** - Configures auto scaling
- **generate-load.sh** - Creates test workload
- **monitor-capacity.sh** - Views metrics
- **test-scaling.sh** - Verifies scaling behavior
- **switch-to-on-demand.sh** - Changes capacity mode
- **cleanup.sh** - Resets configuration

### Configuration Files

- **capacity-config.json** - Initial capacity settings
- **auto-scaling-policy.json** - Scaling configuration
- **cloudwatch-alarms.json** - Capacity alarms

## Lab Metadata

- **Domain**: Databases
- **Complexity Level**: Intermediate
- **Estimated Time**: 60 minutes
- **AWS Services**: DynamoDB, Auto Scaling, CloudWatch, IAM
- **Key Concepts**: Capacity planning, auto scaling, cost optimization
- **Certification Alignment**: AWS Certified Developer - Associate (DynamoDB capacity management)
