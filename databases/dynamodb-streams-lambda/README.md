# Processing Amazon DynamoDB Streams Using AWS Lambda

## Overview

This lab demonstrates implementing DynamoDB Streams with AWS Lambda for real-time data processing. The implementation includes enabling DynamoDB Streams on tables, creating Lambda functions triggered by stream events, processing INSERT, MODIFY, and REMOVE events, implementing TTL (Time To Live) for automatic item expiration, and building event-driven architectures with DynamoDB as the event source.

## AWS Services Used

- **Amazon DynamoDB** - NoSQL database with Streams
- **AWS Lambda** - Serverless compute for stream processing
- **DynamoDB Streams** - Change data capture stream
- **AWS IAM** - Lambda execution roles and permissions
- **Amazon CloudWatch** - Logs and metrics
- **Amazon SNS** - Notifications (optional)

## Key Technologies

- **DynamoDB Streams** - Ordered change log
- **Event Source Mapping** - Lambda trigger configuration
- **Stream Records** - NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES
- **TTL (Time To Live)** - Automatic item expiration
- **Lambda Event Processing** - Batch processing of stream records
- **Error Handling** - Retry logic and DLQ

## Architecture Overview

The architecture consists of a DynamoDB table with Streams enabled, capturing all data modifications (INSERT, MODIFY, REMOVE) in an ordered stream. Lambda functions are triggered by stream events through event source mappings, processing batches of records in near real-time. TTL automatically expires items, generating REMOVE events that can trigger cleanup workflows.

See [architecture.md](./architecture.md) for detailed stream processing architecture.

## Objectives

- Enable DynamoDB Streams on tables
- Create Lambda functions for stream processing
- Configure event source mappings
- Process INSERT, MODIFY, and REMOVE events
- Implement TTL for automatic item expiration
- Handle stream processing errors and retries
- Monitor stream processing with CloudWatch
- Build event-driven data pipelines

## Key Learnings

- **Streams Architecture**: Understanding change data capture
- **Event Source Mapping**: Connecting streams to Lambda
- **Stream View Types**: NEW_IMAGE, OLD_IMAGE, KEYS_ONLY
- **Batch Processing**: Processing multiple records efficiently
- **TTL Implementation**: Automatic data expiration
- **Error Handling**: Retry logic and dead letter queues
- **Idempotency**: Handling duplicate processing
- **Use Cases**: Audit logs, data replication, notifications

## Setup Instructions

### Prerequisites

- AWS account with DynamoDB and Lambda permissions
- DynamoDB table created
- Node.js or Python for Lambda functions
- IAM role for Lambda execution

### Step 1: Enable DynamoDB Streams

Enable streams on table:

```bash
./scripts/enable-streams.sh
```

### Step 2: Create Lambda Function

Create stream processor:

```bash
./scripts/create-lambda-function.sh
```

### Step 3: Configure Event Source Mapping

Connect stream to Lambda:

```bash
./scripts/create-event-source-mapping.sh
```

### Step 4: Enable TTL

Configure TTL attribute:

```bash
./scripts/enable-ttl.sh
```

### Step 5: Test Stream Processing

Generate test events:

```bash
./scripts/test-stream-processing.sh
```

### Step 6: Monitor Processing

View CloudWatch logs:

```bash
./scripts/monitor-processing.sh
```

## Scripts and Configurations

### Scripts

- **enable-streams.sh** - Enables DynamoDB Streams
- **create-lambda-function.sh** - Creates Lambda processor
- **create-event-source-mapping.sh** - Configures trigger
- **enable-ttl.sh** - Enables TTL on table
- **test-stream-processing.sh** - Tests stream events
- **monitor-processing.sh** - Views logs and metrics
- **cleanup.sh** - Removes resources

### Configuration Files

- **lambda-function.py** - Stream processor code
- **event-source-config.json** - Mapping configuration
- **ttl-config.json** - TTL settings
- **test-events.json** - Sample stream events

## Lab Metadata

- **Domain**: Databases
- **Complexity Level**: Intermediate
- **Estimated Time**: 75 minutes
- **AWS Services**: DynamoDB, Lambda, Streams, IAM, CloudWatch
- **Key Concepts**: Event-driven architecture, CDC, stream processing, TTL
- **Certification Alignment**: AWS Certified Developer - Associate (DynamoDB Streams, Lambda triggers)
