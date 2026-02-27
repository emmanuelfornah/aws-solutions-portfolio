# Lambda URL Checker - Architecture

## Overview

The Lambda URL Checker demonstrates a serverless architecture pattern where compute resources are provisioned on-demand without managing servers. This document details the architecture, component interactions, and design decisions.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│                                                                   │
│  ┌────────────────┐                                              │
│  │   Developer    │                                              │
│  │   AWS CLI      │                                              │
│  │   Console      │                                              │
│  └────────┬───────┘                                              │
│           │                                                       │
│           │ Invoke (JSON payload)                                │
│           ▼                                                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              AWS Lambda Function                         │    │
│  │  ┌────────────────────────────────────────────────────┐ │    │
│  │  │  Function: URLChecker                              │ │    │
│  │  │  Runtime: Python 3.13                              │ │    │
│  │  │  Handler: app.lambda_handler                       │ │    │
│  │  │  Memory: 128 MB                                    │ │    │
│  │  │  Timeout: 10 seconds                               │ │    │
│  │  │                                                     │ │    │
│  │  │  ┌──────────────────────────────────────────────┐ │ │    │
│  │  │  │  Deployment Package (ZIP)                    │ │ │    │
│  │  │  │  ├── app.py (application code)               │ │ │    │
│  │  │  │  └── requests/ (dependency library)          │ │ │    │
│  │  │  └──────────────────────────────────────────────┘ │ │    │
│  │  └────────────────────────────────────────────────────┘ │    │
│  │                                                           │    │
│  │  Execution Role: LambdaURLCheckerRole                    │    │
│  │  Permissions: CloudWatch Logs write access               │    │
│  └──────────────┬────────────────────────────┬───────────────┘    │
│                 │                            │                    │
│                 │ HTTP GET                   │ Write logs         │
│                 ▼                            ▼                    │
│  ┌──────────────────────┐      ┌──────────────────────────┐     │
│  │   Target URL         │      │   Amazon CloudWatch      │     │
│  │   (Internet)         │      │                          │     │
│  │                      │      │  Log Group:              │     │
│  │  • aws.amazon.com    │      │  /aws/lambda/URLChecker  │     │
│  │  • example.com       │      │                          │     │
│  │  • Any HTTP(S) URL   │      │  Log Streams:            │     │
│  └──────────────────────┘      │  • Execution logs        │     │
│                                 │  • Duration metrics      │     │
│                                 │  • Memory usage          │     │
│                                 │  • Error traces          │     │
│                                 └──────────────────────────┘     │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    Amazon S3 (Optional)                   │   │
│  │  Deployment Package Storage:                              │   │
│  │  s3://my-lambda-deployments/lambda-deployment-package.zip │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Lambda Function

**Purpose:** Serverless compute service that executes URL checking logic

**Configuration:**
- **Function Name:** URLChecker
- **Runtime:** Python 3.13
- **Handler:** app.lambda_handler (module.function format)
- **Memory Allocation:** 128 MB
- **Timeout:** 10 seconds
- **Architecture:** x86_64

**Execution Model:**
- Event-driven: Triggered by invocation events
- Stateless: No persistent state between invocations
- Isolated: Each invocation runs in a separate container
- Concurrent: Multiple invocations can run simultaneously

**Cold Start vs Warm Start:**
- **Cold Start:** First invocation or after idle period (5-10 minutes)
  - Container initialization: ~100-200ms
  - Runtime loading: ~50-100ms
  - Code initialization: ~50ms
  - Total cold start: ~200-350ms

- **Warm Start:** Subsequent invocations reusing container
  - No initialization overhead
  - Execution time: ~50-100ms for URL check

### 2. Deployment Package

**Purpose:** Contains application code and dependencies

**Structure:**
```
lambda-deployment-package.zip
├── app.py                          # Main application code
├── requests/                       # HTTP library
│   ├── __init__.py
│   ├── api.py
│   ├── models.py
│   └── [other modules]
├── urllib3/                        # Dependency of requests
├── certifi/                        # SSL certificates
├── charset_normalizer/             # Character encoding
└── idna/                           # Domain name handling
```

**Size Considerations:**
- Uncompressed: ~2-3 MB
- Compressed (ZIP): ~1-1.5 MB
- Lambda limit: 50 MB (zipped), 250 MB (unzipped)

**Packaging Process:**
1. Install dependencies to local directory: `pip install -r requirements.txt -t package/`
2. Copy application code: `cp app.py package/`
3. Create ZIP archive: `cd package && zip -r ../lambda-deployment-package.zip .`

### 3. IAM Execution Role

**Purpose:** Grants Lambda function permissions to access AWS services

**Role Name:** LambdaURLCheckerRole

**Trust Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Attached Policies:**
- **AWSLambdaBasicExecutionRole** (AWS managed policy)
  - Permissions:
    - `logs:CreateLogGroup`
    - `logs:CreateLogStream`
    - `logs:PutLogEvents`

**Security Principle:** Least privilege - only grants CloudWatch Logs access

### 4. Amazon CloudWatch Logs

**Purpose:** Centralized logging for function execution and debugging

**Log Group:** `/aws/lambda/URLChecker`

**Log Streams:** One per container instance (format: `YYYY/MM/DD/[$LATEST]<random-id>`)

**Log Entry Types:**
1. **START:** Function invocation begins
2. **Custom Logs:** Print statements from code
3. **END:** Function invocation completes
4. **REPORT:** Execution metrics (duration, memory, billing)

**Example Log Entry:**
```
START RequestId: 12345678-1234-1234-1234-123456789012 Version: $LATEST
Checking URL: https://aws.amazon.com
Success: https://aws.amazon.com returned status 200
END RequestId: 12345678-1234-1234-1234-123456789012
REPORT RequestId: 12345678-1234-1234-1234-123456789012
    Duration: 245.67 ms
    Billed Duration: 246 ms
    Memory Size: 128 MB
    Max Memory Used: 45 MB
    Init Duration: 123.45 ms (cold start only)
```

**Retention:** Default 30 days (configurable)

### 5. Event Payload

**Purpose:** Input data passed to Lambda function

**Format:** JSON object with URL parameter

**Example:**
```json
{
  "url": "https://aws.amazon.com"
}
```

**Validation:**
- Required field: `url`
- Expected format: Valid HTTP/HTTPS URL string
- Error handling: Returns 400 status if missing

### 6. Response Format

**Purpose:** Structured output from Lambda function

**Success Response:**
```json
{
  "statusCode": 200,
  "body": {
    "url": "https://aws.amazon.com",
    "status": "success",
    "http_status": 200,
    "message": "URL is reachable"
  }
}
```

**Error Response:**
```json
{
  "statusCode": 500,
  "body": {
    "url": "https://invalid-domain.com",
    "status": "error",
    "message": "Connection error: [error details]"
  }
}
```

## Execution Flow

### Synchronous Invocation Flow

```
1. Client (CLI/Console) sends invocation request
   ↓
2. Lambda service receives request
   ↓
3. Container provisioning (cold start) or reuse (warm start)
   ↓
4. Load deployment package and initialize runtime
   ↓
5. Execute lambda_handler function with event payload
   ↓
6. Function extracts URL from event
   ↓
7. Function makes HTTP GET request to target URL
   ↓
8. Function processes response or handles exceptions
   ↓
9. Function returns structured JSON response
   ↓
10. Lambda service returns response to client
    ↓
11. CloudWatch Logs receives execution logs
```

### Error Handling Flow

```
URL Validation
├── Missing URL → Return 400 error
└── URL present → Continue

HTTP Request
├── Timeout (>5s) → Return 500 with timeout message
├── Connection Error → Return 500 with connection error
├── HTTP Error (4xx/5xx) → Return 500 with HTTP status
├── Request Exception → Return 500 with request error
├── Unexpected Error → Return 500 with generic error
└── Success (2xx/3xx) → Return 200 with success message
```

## Serverless Architecture Benefits

### 1. No Server Management
- **Traditional EC2:** Provision, patch, monitor, scale servers
- **Lambda:** AWS manages all infrastructure automatically

### 2. Automatic Scaling
- **Traditional EC2:** Configure auto-scaling groups, load balancers
- **Lambda:** Scales from 0 to 1000+ concurrent executions automatically

### 3. Pay-Per-Use Pricing
- **Traditional EC2:** Pay for running instances even when idle
- **Lambda:** Pay only for actual execution time (100ms increments)

### 4. High Availability
- **Traditional EC2:** Design multi-AZ architecture manually
- **Lambda:** Built-in redundancy across multiple availability zones

### 5. Integrated Monitoring
- **Traditional EC2:** Install and configure monitoring agents
- **Lambda:** CloudWatch integration automatic and built-in

## Performance Characteristics

### Latency Breakdown

**Cold Start (First Invocation):**
- Container initialization: 100-200ms
- Runtime loading: 50-100ms
- Code initialization: 50ms
- HTTP request: 50-200ms (depends on target URL)
- **Total:** 250-550ms

**Warm Start (Subsequent Invocations):**
- HTTP request: 50-200ms
- **Total:** 50-200ms

### Concurrency

- **Default Account Limit:** 1,000 concurrent executions
- **Burst Limit:** 500-3,000 (region-dependent)
- **Reserved Concurrency:** Can be configured per function
- **Provisioned Concurrency:** Pre-warmed containers for consistent latency

### Memory and CPU

- **Memory:** 128 MB to 10,240 MB (configurable)
- **CPU:** Proportional to memory (1,769 MB = 1 vCPU)
- **This Function:** 128 MB sufficient (uses ~45 MB)

## Security Architecture

### Network Security

**Default Configuration:**
- Lambda runs in AWS-managed VPC
- Has internet access for external URL checking
- No inbound connections possible

**VPC Configuration (Optional):**
- Can deploy Lambda in customer VPC
- Requires VPC endpoints or NAT Gateway for internet access
- Use case: Checking internal URLs within VPC

### IAM Security

**Execution Role:**
- Defines what AWS services Lambda can access
- This function: Only CloudWatch Logs

**Resource Policy:**
- Defines who can invoke the function
- Default: Only AWS account owner

**Best Practices:**
- Least privilege permissions
- Separate roles per function
- Regular permission audits

### Data Security

**In Transit:**
- HTTPS for target URL requests
- TLS 1.2+ for AWS API calls

**At Rest:**
- Deployment package encrypted in S3
- Environment variables encrypted with KMS (if used)

**Secrets Management:**
- Use AWS Secrets Manager for API keys
- Use environment variables for configuration
- Never hardcode credentials in code

## Cost Architecture

### Pricing Components

**1. Request Charges:**
- $0.20 per 1 million requests
- First 1 million requests per month free

**2. Duration Charges:**
- $0.0000166667 per GB-second
- First 400,000 GB-seconds per month free

### Cost Calculation Example

**Scenario:** 100,000 invocations per month
- Memory: 128 MB (0.125 GB)
- Duration: 250ms (0.25 seconds)

**Calculations:**
- Request cost: 100,000 × $0.20 / 1,000,000 = $0.02
- Duration cost: 100,000 × 0.125 GB × 0.25 s × $0.0000166667 = $0.052
- **Total:** $0.072 per month

**Free Tier Coverage:**
- Requests: 1,000,000 free (covers 100,000)
- Duration: 400,000 GB-seconds free (uses 3,125 GB-seconds)
- **Actual Cost:** $0.00 (within free tier)

## Monitoring and Observability

### CloudWatch Metrics

**Automatic Metrics:**
- Invocations (count)
- Duration (milliseconds)
- Errors (count)
- Throttles (count)
- Concurrent Executions (count)
- Iterator Age (for stream-based invocations)

**Custom Metrics:**
- Can publish custom metrics using CloudWatch API
- Example: Track successful vs failed URL checks

### CloudWatch Alarms

**Recommended Alarms:**
1. **Error Rate:** Alert if errors > 5% of invocations
2. **Duration:** Alert if p99 duration > 5 seconds
3. **Throttles:** Alert if any throttling occurs
4. **Concurrent Executions:** Alert if approaching account limit

### X-Ray Tracing (Optional)

- Enable for detailed execution traces
- Visualize service call graph
- Identify performance bottlenecks
- Track downstream HTTP requests

## Deployment Strategies

### 1. Console Deployment (Manual)
- Upload ZIP file through web interface
- Good for: Development, testing, small changes
- Limitations: Manual process, no version control integration

### 2. AWS CLI Deployment (Scripted)
- Automated deployment via command-line
- Good for: Repeatable deployments, CI/CD integration
- Supports: Function creation, updates, configuration changes

### 3. Infrastructure as Code (Advanced)
- **CloudFormation:** YAML/JSON templates
- **AWS SAM:** Simplified CloudFormation for serverless
- **Terraform:** Multi-cloud IaC tool
- **AWS CDK:** Define infrastructure in Python/TypeScript
- Good for: Production environments, team collaboration

### 4. CI/CD Pipeline (Production)
- Automated testing and deployment
- Version control integration (Git)
- Staged deployments (dev → staging → prod)
- Rollback capabilities

## Scaling Considerations

### Horizontal Scaling (Concurrency)
- **Automatic:** Lambda scales to handle concurrent requests
- **Limit:** 1,000 concurrent executions (default)
- **Burst:** 500-3,000 additional (region-dependent)
- **Throttling:** Requests beyond limit receive 429 error

### Vertical Scaling (Memory/CPU)
- Increase memory allocation for more CPU power
- This function: 128 MB sufficient
- Use case for more: CPU-intensive operations, large data processing

### Optimization Strategies
1. **Minimize cold starts:** Use provisioned concurrency
2. **Reduce package size:** Remove unused dependencies
3. **Optimize code:** Efficient algorithms, connection pooling
4. **Adjust timeout:** Balance between reliability and cost
5. **Monitor metrics:** Identify bottlenecks and optimize

## Comparison: Lambda vs EC2

| Aspect | AWS Lambda | Amazon EC2 |
|--------|-----------|------------|
| **Management** | Fully managed | Self-managed |
| **Scaling** | Automatic, instant | Manual or auto-scaling groups |
| **Pricing** | Per-invocation | Per-hour |
| **Idle Cost** | $0 | Full instance cost |
| **Startup Time** | 50-500ms | Minutes |
| **Max Duration** | 15 minutes | Unlimited |
| **State** | Stateless | Can maintain state |
| **Customization** | Limited runtime options | Full OS control |
| **Use Case** | Event-driven, short tasks | Long-running, stateful apps |

## Future Enhancements

### 1. Scheduled Execution
- Use Amazon EventBridge (CloudWatch Events)
- Run URL checks every 5 minutes
- Monitor website uptime continuously

### 2. Result Storage
- Store check results in DynamoDB
- Track historical uptime data
- Generate availability reports

### 3. Notifications
- Send SNS notifications on failures
- Email/SMS alerts for downtime
- Integration with PagerDuty/Slack

### 4. API Gateway Integration
- Create REST API endpoint
- HTTP-triggered invocations
- Public URL checking service

### 5. Advanced Features
- Retry logic with exponential backoff
- Circuit breaker pattern
- Multiple URL checks in parallel
- Custom headers and authentication
- POST/PUT request support

## Conclusion

The Lambda URL Checker demonstrates a modern serverless architecture that eliminates infrastructure management while providing automatic scaling, high availability, and cost efficiency. This pattern is ideal for event-driven workloads, periodic tasks, and applications with variable traffic patterns.
