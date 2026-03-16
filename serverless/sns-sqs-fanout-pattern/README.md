# Using Amazon SNS and SQS in Event-Driven Architectures

## Overview

This project demonstrates the **fan-out messaging pattern** using Amazon SNS and SQS to build an automated image processing pipeline. When an image is uploaded to S3, it triggers a cascade of parallel processing tasks that generate thumbnail, web-optimized, and mobile-optimized versions simultaneously.

## AWS Services Used

- **Amazon S3** - Image storage and event source
- **Amazon SNS** - Fan-out message distribution
- **Amazon SQS** - Message queuing and buffering
- **AWS Lambda** - Image processing functions
- **Amazon CloudWatch** - Monitoring and logging
- **AWS IAM** - Service permissions

## Architecture

### Architecture Diagram

```
                    ┌─────────────────┐
                    │   Amazon S3     │
                    │  (Image Bucket) │
                    └────────┬────────┘
                             │
                             │ S3 Event Notification
                             ▼
                    ┌─────────────────┐
                    │   Amazon SNS    │
                    │  (Topic: Image  │
                    │   Processing)   │
                    └────────┬────────┘
                             │
                             │ Fan-out (1:3)
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   SQS Queue     │ │   SQS Queue     │ │   SQS Queue     │
│  (Thumbnail)    │ │    (Web)        │ │   (Mobile)      │
└────────┬────────┘ └────────┬────────┘ └────────┬────────┘
         │                   │                   │
         │ Poll              │ Poll              │ Poll
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ Lambda Function │ │ Lambda Function │ │ Lambda Function │
│  (Thumbnail)    │ │  (Web Resize)   │ │ (Mobile Resize) │
└────────┬────────┘ └────────┬────────┘ └────────┬────────┘
         │                   │                   │
         │ Save              │ Save              │ Save
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   S3 Bucket     │ │   S3 Bucket     │ │   S3 Bucket     │
│  (Thumbnails)   │ │    (Web)        │ │   (Mobile)      │
└─────────────────┘ └─────────────────┘ └─────────────────┘
         │                   │                   │
         └───────────────────┴───────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   CloudWatch    │
                    │  (Monitoring)   │
                    └─────────────────┘
```

### Component Overview

1. **S3 Source Bucket** - Receives original image uploads
2. **SNS Topic** - Distributes upload notifications to multiple queues
3. **SQS Queues (3)** - Buffer messages for each processing type
4. **Lambda Functions (3)** - Process images in parallel
5. **S3 Destination Buckets** - Store processed images
6. **CloudWatch** - Monitor processing metrics and logs

## Key Concepts

### Fan-Out Pattern

The fan-out pattern allows a single message to be delivered to multiple consumers simultaneously:

- **1:N Distribution** - One SNS message → Multiple SQS queues
- **Parallel Processing** - All consumers process independently
- **Decoupled Scaling** - Each consumer scales independently
- **Guaranteed Delivery** - SQS ensures message persistence

### SNS vs SQS

| Feature | SNS | SQS |
|---------|-----|-----|
| **Type** | Pub/Sub | Queue |
| **Delivery** | Push | Pull |
| **Retention** | No retention | Up to 14 days |
| **Consumers** | Multiple (fan-out) | Single (or competing) |
| **Use Case** | Notifications | Buffering, decoupling |

### Why Use Both?

**SNS alone**: Messages lost if consumer unavailable  
**SQS alone**: Can't fan-out to multiple consumers  
**SNS + SQS**: Reliable fan-out with message persistence

## Objectives

- Implement fan-out messaging pattern with SNS and SQS
- Build parallel image processing pipeline
- Configure S3 event notifications
- Create Lambda functions for image resizing
- Set up dead letter queues for error handling
- Monitor processing with CloudWatch

## Setup Instructions

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- Python 3.x with Pillow library
- Basic understanding of S3, Lambda, and messaging services

### Step 1: Create S3 Buckets

```bash
# Source bucket for original images
aws s3 mb s3://image-processing-source-ACCOUNT_ID

# Destination buckets for processed images
aws s3 mb s3://image-processing-thumbnails-ACCOUNT_ID
aws s3 mb s3://image-processing-web-ACCOUNT_ID
aws s3 mb s3://image-processing-mobile-ACCOUNT_ID
```

### Step 2: Create SNS Topic

```bash
aws sns create-topic --name ImageProcessingTopic

# Note the TopicArn from the output
```

### Step 3: Create SQS Queues

```bash
# Create main queues
aws sqs create-queue --queue-name ThumbnailQueue
aws sqs create-queue --queue-name WebQueue
aws sqs create-queue --queue-name MobileQueue

# Create dead letter queues
aws sqs create-queue --queue-name ThumbnailDLQ
aws sqs create-queue --queue-name WebDLQ
aws sqs create-queue --queue-name MobileDLQ
```

### Step 4: Subscribe SQS Queues to SNS Topic

```bash
# Subscribe thumbnail queue
aws sns subscribe \
    --topic-arn arn:aws:sns:REGION:ACCOUNT_ID:ImageProcessingTopic \
    --protocol sqs \
    --notification-endpoint arn:aws:sqs:REGION:ACCOUNT_ID:ThumbnailQueue

# Subscribe web queue
aws sns subscribe \
    --topic-arn arn:aws:sns:REGION:ACCOUNT_ID:ImageProcessingTopic \
    --protocol sqs \
    --notification-endpoint arn:aws:sqs:REGION:ACCOUNT_ID:WebQueue

# Subscribe mobile queue
aws sns subscribe \
    --topic-arn arn:aws:sns:REGION:ACCOUNT_ID:ImageProcessingTopic \
    --protocol sqs \
    --notification-endpoint arn:aws:sqs:REGION:ACCOUNT_ID:MobileQueue
```

### Step 5: Configure SQS Queue Policies

Update each SQS queue policy to allow SNS to send messages (see `configs/sqs-policy.json`).

### Step 6: Configure Dead Letter Queues

```bash
# Configure redrive policy for each main queue
aws sqs set-queue-attributes \
    --queue-url https://sqs.REGION.amazonaws.com/ACCOUNT_ID/ThumbnailQueue \
    --attributes file://configs/redrive-policy.json
```

### Step 7: Deploy Lambda Functions

Deploy the three Lambda functions (see `scripts/` directory):

1. **thumbnail_processor.py** - Creates 150x150 thumbnails
2. **web_processor.py** - Resizes for web (1200px width)
3. **mobile_processor.py** - Resizes for mobile (800px width)

### Step 8: Configure S3 Event Notification

```bash
aws s3api put-bucket-notification-configuration \
    --bucket image-processing-source-ACCOUNT_ID \
    --notification-configuration file://configs/s3-notification.json
```

### Step 9: Test the Pipeline

```bash
# Upload a test image
aws s3 cp test-image.jpg s3://image-processing-source-ACCOUNT_ID/

# Check processed images
aws s3 ls s3://image-processing-thumbnails-ACCOUNT_ID/
aws s3 ls s3://image-processing-web-ACCOUNT_ID/
aws s3 ls s3://image-processing-mobile-ACCOUNT_ID/
```

## Scripts and Configurations

### Lambda Functions

- `scripts/thumbnail_processor.py` - Thumbnail generation (150x150)
- `scripts/web_processor.py` - Web optimization (1200px width)
- `scripts/mobile_processor.py` - Mobile optimization (800px width)

### Configuration Files

- `configs/s3-notification.json` - S3 to SNS event configuration
- `configs/sqs-policy.json` - SQS queue policy for SNS
- `configs/redrive-policy.json` - Dead letter queue configuration
- `configs/lambda-layer-requirements.txt` - Python dependencies (Pillow)

### IAM Policies

- `configs/lambda-execution-policy.json` - Lambda permissions
- `configs/s3-sns-policy.json` - S3 to SNS permissions

## Real-World Applications

### Content Delivery Networks
- Original image upload
- Multiple format conversions (WebP, AVIF, JPEG)
- Different resolutions for responsive design
- Thumbnail generation for galleries

### Video Processing
- Upload video to S3
- Fan-out to multiple processing pipelines
- Generate different resolutions (4K, 1080p, 720p, 480p)
- Create thumbnails and preview clips

### Document Processing
- Upload document (PDF, Word)
- Convert to multiple formats
- Generate thumbnails
- Extract text for search indexing
- Virus scanning

### E-Commerce Product Images
- Product photo upload
- Generate thumbnails for listings
- Create zoom-enabled high-res versions
- Mobile-optimized images
- Watermark application

## Interview Talking Points

### Architecture Decisions

**Q: Why use SNS + SQS instead of just SNS?**
- **Message Persistence**: SQS stores messages if Lambda unavailable
- **Retry Logic**: SQS handles retries automatically
- **Rate Limiting**: SQS buffers messages during traffic spikes
- **Dead Letter Queues**: Failed messages go to DLQ for analysis
- **Visibility Timeout**: Prevents duplicate processing

**Q: Why not use EventBridge instead of SNS?**
- **Simplicity**: SNS is simpler for basic fan-out
- **Cost**: SNS is cheaper for high-volume messaging
- **Performance**: SNS has lower latency
- **Use EventBridge when**: Need complex routing, schema registry, or SaaS integration

**Q: How does this architecture scale?**
- **S3**: Unlimited storage and throughput
- **SNS**: Handles millions of messages per second
- **SQS**: Unlimited throughput with standard queues
- **Lambda**: Auto-scales to 1000 concurrent executions (default)
- **Bottleneck**: Lambda concurrency limits (can be increased)

### Error Handling

**Q: What happens if image processing fails?**
1. Lambda function throws exception
2. SQS makes message visible again after visibility timeout
3. Lambda retries (up to configured attempts)
4. After max retries, message moves to Dead Letter Queue
5. CloudWatch alarm triggers for DLQ messages
6. Operations team investigates and reprocesses

**Q: How do you prevent duplicate processing?**
- **Idempotency**: Check if output file exists before processing
- **S3 Object Versioning**: Use version ID in processing
- **Message Deduplication**: Use SQS FIFO queues if ordering matters
- **Unique Keys**: Include timestamp or UUID in output filenames

### Performance Optimization

**Q: How do you optimize Lambda performance?**
- **Memory Allocation**: More memory = more CPU (test optimal size)
- **Provisioned Concurrency**: Pre-warm functions for consistent latency
- **Lambda Layers**: Share Pillow library across functions
- **Batch Processing**: Process multiple images per invocation
- **Async Processing**: Use async/await for I/O operations

**Q: How do you handle large images?**
- **Lambda Limits**: 512 MB /tmp storage, 15-minute timeout
- **Solution 1**: Use EFS for larger temporary storage
- **Solution 2**: Stream processing with chunked reads
- **Solution 3**: Use EC2 or ECS for very large files
- **Best Practice**: Validate file size before processing

## Best Practices Implemented

### Reliability
- ✅ Dead letter queues for failed messages
- ✅ SQS message retention (14 days)
- ✅ Lambda retry logic with exponential backoff
- ✅ Idempotent processing (check before overwrite)

### Security
- ✅ IAM roles with least privilege
- ✅ S3 bucket policies restrict access
- ✅ Encrypted data at rest (S3, SQS)
- ✅ Encrypted data in transit (HTTPS)

### Performance
- ✅ Parallel processing with fan-out
- ✅ Lambda memory optimization
- ✅ SQS batch size tuning
- ✅ Efficient image processing (Pillow)

### Cost Optimization
- ✅ S3 Intelligent-Tiering for storage
- ✅ Lambda ephemeral storage for temp files
- ✅ SQS standard queues (cheaper than FIFO)
- ✅ CloudWatch Logs retention policies

### Observability
- ✅ CloudWatch Logs for all Lambda functions
- ✅ CloudWatch Metrics for queue depth
- ✅ CloudWatch Alarms for DLQ messages
- ✅ X-Ray tracing for distributed debugging

## Troubleshooting

### Messages Not Reaching SQS Queues

**Issue**: SNS publishes but SQS queues empty

**Solutions**:
- Verify SQS queue policy allows SNS to send messages
- Check SNS subscription status (should be "Confirmed")
- Review SNS topic access policy
- Check CloudWatch Logs for SNS delivery failures

### Lambda Functions Not Triggered

**Issue**: Messages in SQS but Lambda not processing

**Solutions**:
- Verify Lambda event source mapping is enabled
- Check Lambda execution role has SQS permissions
- Review Lambda concurrency limits
- Check for Lambda function errors in CloudWatch Logs

### Image Processing Failures

**Issue**: Lambda function errors during processing

**Solutions**:
- Verify Pillow library in Lambda layer or deployment package
- Check Lambda memory allocation (increase if needed)
- Validate image format compatibility
- Review /tmp storage usage (512 MB limit)
- Check S3 permissions for read and write

### Dead Letter Queue Messages

**Issue**: Messages accumulating in DLQ

**Solutions**:
- Review CloudWatch Logs for error patterns
- Check image format compatibility
- Verify S3 bucket permissions
- Increase Lambda timeout if needed
- Reprocess messages after fixing issues

## CloudWatch Monitoring

### Key Metrics to Monitor

**SQS Metrics**:
- `ApproximateNumberOfMessagesVisible` - Queue depth
- `ApproximateAgeOfOldestMessage` - Processing lag
- `NumberOfMessagesSent` - Throughput
- `NumberOfMessagesDeleted` - Successful processing

**Lambda Metrics**:
- `Invocations` - Function execution count
- `Errors` - Failed executions
- `Duration` - Processing time
- `ConcurrentExecutions` - Parallel executions

**SNS Metrics**:
- `NumberOfMessagesPublished` - Messages sent
- `NumberOfNotificationsFailed` - Delivery failures

### CloudWatch Alarms

```bash
# Alarm for DLQ messages
aws cloudwatch put-metric-alarm \
    --alarm-name ThumbnailDLQAlarm \
    --alarm-description "Alert when messages in DLQ" \
    --metric-name ApproximateNumberOfMessagesVisible \
    --namespace AWS/SQS \
    --statistic Sum \
    --period 300 \
    --threshold 1 \
    --comparison-operator GreaterThanThreshold
```

## Cost Analysis

### Estimated Monthly Costs (1 million images)

**S3**:
- Storage: 1TB = $23/month
- PUT requests: 1M = $5/month
- GET requests: 3M = $0.40/month

**SNS**:
- Messages: 1M = $0.50/month

**SQS**:
- Requests: 3M = $1.20/month

**Lambda**:
- Invocations: 3M = $0.60/month
- Duration: Varies by memory/time

**Total**: ~$30-50/month for 1M images

## Metadata

- **Complexity Level**: Intermediate
- **Estimated Time**: 60 minutes
- **Prerequisites**: S3, Lambda, basic messaging concepts
- **Learning Path**: Event-driven architecture patterns

## Next Steps

- Explore **EventBridge** for complex event routing
- Learn **Step Functions** for workflow orchestration
- Implement **S3 Transfer Acceleration** for faster uploads
- Add **CloudFront** for global content delivery
- Integrate **Rekognition** for image analysis
- Use **MediaConvert** for video processing

## Additional Resources

- [SNS Documentation](https://docs.aws.amazon.com/sns/)
- [SQS Documentation](https://docs.aws.amazon.com/sqs/)
- [Fan-Out Pattern](https://docs.aws.amazon.com/sns/latest/dg/sns-common-scenarios.html)
- [Lambda with SQS](https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html)
