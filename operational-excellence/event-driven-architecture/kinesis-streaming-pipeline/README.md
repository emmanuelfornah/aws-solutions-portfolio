# Navigating through Kinesis

## Overview

This lab demonstrates building a **real-time streaming data pipeline** using Amazon Kinesis services. The system processes continuous data streams from DynamoDB, transforms the data with Lambda, and delivers it to OpenSearch for real-time analytics and visualization.

## AWS Services Used

- **Amazon Kinesis Data Streams** - Real-time data streaming
- **Amazon Kinesis Data Firehose** - Data delivery to destinations
- **Amazon DynamoDB** - Source database with Streams enabled
- **DynamoDB Streams** - Change data capture
- **AWS Lambda** - Stream processing and transformation
- **Amazon OpenSearch Service** - Search and analytics
- **Amazon CloudWatch** - Monitoring and logging
- **AWS IAM** - Service permissions

## Architecture

### Architecture Diagram

```
┌──────────────────┐
│   DynamoDB       │
│   (Orders Table) │
└────────┬─────────┘
         │
         │ Change Data Capture
         ▼
┌──────────────────┐
│ DynamoDB Streams │
└────────┬─────────┘
         │
         │ Trigger
         ▼
┌──────────────────┐         ┌──────────────────┐
│ Lambda Function  │────────>│ Kinesis Data     │
│ (Transform)      │  Put    │ Streams          │
└──────────────────┘         └────────┬─────────┘
                                      │
                                      │ Subscribe
                                      ▼
                             ┌──────────────────┐
                             │ Kinesis Firehose │
                             │ (Delivery Stream)│
                             └────────┬─────────┘
                                      │
                                      │ Deliver
                                      ▼
                             ┌──────────────────┐
                             │  OpenSearch      │
                             │  (Analytics)     │
                             └────────┬─────────┘
                                      │
                                      ▼
                             ┌──────────────────┐
                             │  Kibana          │
                             │  (Visualization) │
                             └──────────────────┘
```

## Key Concepts

### Kinesis Data Streams
- **Real-time processing** - Sub-second latency
- **Shards** - Parallel processing units
- **Retention** - 24 hours to 365 days
- **Multiple consumers** - Many applications read same stream
- **Ordering** - Per-shard ordering guarantee

### DynamoDB Streams
- **Change data capture** - Track all table modifications
- **Event types** - INSERT, MODIFY, REMOVE
- **Near real-time** - Typically within seconds
- **24-hour retention** - Automatic cleanup
- **Ordered** - Changes in order they occurred

### Kinesis Firehose
- **Fully managed** - No infrastructure management
- **Automatic scaling** - Handles throughput variations
- **Data transformation** - Lambda integration
- **Batch delivery** - Efficient destination writes
- **Multiple destinations** - S3, OpenSearch, Redshift, HTTP

## Objectives

- Enable DynamoDB Streams for change data capture
- Create Kinesis Data Stream for real-time processing
- Build Lambda function to transform and forward data
- Configure Kinesis Firehose for delivery
- Set up OpenSearch for analytics
- Monitor streaming pipeline with CloudWatch

## Setup Instructions

### Step 1: Create DynamoDB Table with Streams

```bash
aws dynamodb create-table \
    --table-name Orders \
    --attribute-definitions \
        AttributeName=orderId,AttributeType=S \
    --key-schema \
        AttributeName=orderId,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --stream-specification \
        StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES
```

### Step 2: Create Kinesis Data Stream

```bash
aws kinesis create-stream \
    --stream-name order-stream \
    --shard-count 1
```

### Step 3: Create OpenSearch Domain

```bash
aws opensearch create-domain \
    --domain-name order-analytics \
    --engine-version OpenSearch_2.5 \
    --cluster-config InstanceType=t3.small.search,InstanceCount=1 \
    --ebs-options EBSEnabled=true,VolumeType=gp3,VolumeSize=10
```

### Step 4: Create Kinesis Firehose Delivery Stream

```bash
aws firehose create-delivery-stream \
    --delivery-stream-name order-delivery-stream \
    --delivery-stream-type KinesisStreamAsSource \
    --kinesis-stream-source-configuration file://configs/firehose-source.json \
    --opensearch-destination-configuration file://configs/opensearch-destination.json
```

### Step 5: Deploy Lambda Functions

1. **DynamoDB Stream Processor** - Reads from DynamoDB Streams
2. **Kinesis Data Transformer** - Transforms data for OpenSearch

### Step 6: Test the Pipeline

```python
# Insert test data into DynamoDB
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Orders')

table.put_item(
    Item={
        'orderId': '12345',
        'customer': 'John Doe',
        'amount': 99.99,
        'status': 'PENDING'
    }
)
```

## Real-World Applications

### IoT Data Processing
- Sensor data ingestion
- Real-time monitoring dashboards
- Anomaly detection
- Predictive maintenance

### Financial Services
- Transaction monitoring
- Fraud detection
- Real-time risk analysis
- Audit logging

### E-Commerce Analytics
- User behavior tracking
- Real-time inventory updates
- Recommendation engines
- Sales dashboards

### Log Analytics
- Application log aggregation
- Security event monitoring
- Performance metrics
- Error tracking

## Interview Talking Points

**Q: When to use Kinesis vs SQS?**
- **Kinesis**: Real-time analytics, multiple consumers, data replay
- **SQS**: Simple queuing, single consumer, message deletion after processing
- **Kinesis**: Ordered data within shard
- **SQS**: No ordering guarantee (except FIFO queues)

**Q: How does Kinesis scale?**
- **Shards**: Each shard = 1 MB/s input, 2 MB/s output
- **Scaling**: Add/remove shards based on throughput
- **Auto-scaling**: Use Application Auto Scaling
- **Cost**: Pay per shard-hour

**Q: What's the difference between Kinesis Data Streams and Firehose?**
- **Data Streams**: Real-time processing, custom consumers, manual scaling
- **Firehose**: Fully managed, automatic scaling, limited destinations
- **Use Data Streams**: When you need custom processing or multiple consumers
- **Use Firehose**: When you just need to deliver data to S3/OpenSearch/Redshift

## Metadata

- **Completion Date**: 2024
- **Complexity Level**: Advanced
- **Estimated Time**: 75 minutes
- **Prerequisites**: DynamoDB, Lambda, streaming concepts
