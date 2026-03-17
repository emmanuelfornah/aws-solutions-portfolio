# DynamoDB Capacity Management and Auto Scaling

## Overview

Compares DynamoDB provisioned and on-demand capacity modes, then configures Application Auto Scaling to dynamically adjust read/write capacity based on utilization targets. Demonstrates cost optimization for variable workloads.

## AWS Services Used

- **Amazon DynamoDB** - NoSQL database with configurable capacity
- **Application Auto Scaling** - Dynamic capacity adjustment
- **Amazon CloudWatch** - Utilization metrics and scaling triggers
- **AWS IAM** - Auto scaling service-linked role

## Architecture

```
┌──────────────┐     Metrics     ┌──────────────┐     Scale     ┌──────────────┐
│  CloudWatch  │ <────────────── │  DynamoDB     │ <──────────── │ Auto Scaling │
│              │                 │  Table        │               │              │
│  CPU/RCU/WCU │ ──────────────>│              │               │  Target: 70% │
│  Alarms      │   Trigger      │  Provisioned │               │  Min: 2      │
└──────────────┘                │  Capacity    │               │  Max: 20     │
                                └──────────────┘               └──────────────┘
```

## Technical Highlights

- Provisioned mode: predictable cost with reserved capacity (RCU/WCU)
- On-demand mode: pay-per-request for unpredictable workloads
- Auto scaling target tracking policy at 70% utilization
- Scaling range: 2 (minimum) to 20 (maximum) capacity units
- CloudWatch alarms automatically created by auto scaling
- Capacity mode switching and its impact on availability
