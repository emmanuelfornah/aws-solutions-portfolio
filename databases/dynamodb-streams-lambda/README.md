# Change Data Capture with DynamoDB Streams

## Overview

Implements event-driven processing using DynamoDB Streams and Lambda. When items are created, updated, or deleted in DynamoDB, the stream triggers a Lambda function to process the change event — enabling real-time data pipelines and audit logging.

## AWS Services Used

- **Amazon DynamoDB Streams** - Change data capture
- **AWS Lambda** - Stream event processor
- **Amazon DynamoDB** - Source table
- **AWS IAM** - Lambda execution role with stream read permissions

## Architecture

```
┌──────────────────┐     Stream Event     ┌──────────────────┐
│  DynamoDB Table  │ ──────────────────> │  Lambda Function  │
│                  │                     │                   │
│  INSERT/MODIFY/  │   ┌────────────┐   │  Process change   │
│  REMOVE          │──>│  DynamoDB  │──>│  event record     │
│                  │   │  Stream    │   │                   │
└──────────────────┘   └────────────┘   └──────────────────┘
```

## Technical Highlights

- DynamoDB Streams enabled with `NEW_AND_OLD_IMAGES` view type
- Lambda event source mapping for automatic stream polling
- Event record structure: `eventName`, `dynamodb.NewImage`, `dynamodb.OldImage`
- Batch processing with configurable batch size and window
- Error handling with bisect-on-error for poison pill records
- Use cases: audit logging, cross-region replication, materialized views
