# DynamoDB Table Design and Index Optimization

## Overview

Explores DynamoDB table design patterns — partition keys, sort keys, and Global Secondary Indexes (GSIs). Demonstrates how key schema design impacts query performance and access patterns.

## AWS Services Used

- **Amazon DynamoDB** - NoSQL database
- **AWS CLI** - Table creation and query operations
- **AWS IAM** - DynamoDB access permissions

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  DynamoDB Table                      │
│                                                     │
│  Primary Key:                                       │
│  ┌──────────────┬──────────────┐                    │
│  │ Partition Key │  Sort Key    │                    │
│  │ (PK)         │  (SK)        │                    │
│  └──────────────┴──────────────┘                    │
│                                                     │
│  Global Secondary Index (GSI):                      │
│  ┌──────────────┬──────────────┐                    │
│  │ GSI-PK       │  GSI-SK      │  ← Alternate      │
│  │              │              │    access pattern   │
│  └──────────────┴──────────────┘                    │
└─────────────────────────────────────────────────────┘
```

## Technical Highlights

- Partition key selection for even data distribution
- Composite primary key (partition + sort) for hierarchical data
- GSI creation for alternate query patterns without table scans
- Query vs Scan operations — performance and cost implications
- Key condition expressions and filter expressions
- Projected attributes in GSIs for read optimization
