# Applying Key Lambda Functions to Applications (URL Checker)

## Overview

This lab demonstrates the serverless computing paradigm using AWS Lambda to build a URL health checker application. Unlike traditional EC2-based deployments that require server management, Lambda provides event-driven, pay-per-execution compute without infrastructure overhead. The application checks URL availability, reports HTTP status codes, and logs results to CloudWatch.

## AWS Services Used

- **AWS Lambda** - Serverless compute service for running the URL checker function
- **Amazon S3** - Storage for Lambda deployment packages
- **Amazon CloudWatch** - Logging and monitoring for function execution
- **AWS IAM** - Execution role and permissions management
- **AWS CLI** - Command-line deployment and invocation

## Architecture

The Lambda URL Checker follows a serverless architecture pattern:

1. **Lambda Function**: Python 3.13 runtime executing URL validation logic
2. **Deployment Package**: ZIP file containing application code and dependencies (requests library)
3. **Execution Role**: IAM role granting CloudWatch Logs permissions
4. **Event Invocation**: Synchronous invocation via Console or CLI with JSON payload
5. **CloudWatch Logs**: Automatic logging of execution details and results

See [architecture.md](./architecture.md) for detailed architecture diagrams and component interactions.

## Objectives

- Understand serverless computing vs traditional EC2 deployment models
- Create and package Lambda functions with external dependencies
- Deploy Lambda functions using AWS Console and CLI methods
- Configure IAM execution roles for Lambda functions
- Invoke Lambda functions with custom event payloads
- Monitor function execution using CloudWatch Logs
- Implement error handling for network requests in Lambda

## Key Learnings

- **Serverless Paradigm Shift**: Lambda eliminates server management, patching, and scaling concerns. You only pay for actual compute time (per 100ms), not idle server capacity.

- **Deployment Packaging**: External dependencies (like the `requests` library) must be packaged with your code in a ZIP file. Lambda provides a Python runtime but not all third-party libraries.

- **Event-Driven Execution**: Lambda functions are triggered by events (API calls, S3 uploads, schedules, etc.). The URL checker uses synchronous invocation with JSON payloads.

- **Automatic Scaling**: Lambda automatically scales from zero to thousands of concurrent executions without configuration. Each invocation runs in an isolated environment.

- **CloudWatch Integration**: All Lambda functions automatically log to CloudWatch. Print statements in Python become CloudWatch log entries for debugging and monitoring.

- **Cold Start Considerations**: First invocation or after idle periods may have higher latency due to container initialization. Subsequent invocations reuse warm containers.

- **Stateless Design**: Lambda functions should be stateless. Any persistent data must be stored externally (S3, DynamoDB, RDS, etc.).

## Setup Instructions

### Prerequisites

- AWS account with Lambda and IAM permissions
- AWS CLI installed and configured
- Python 3.13 installed locally (for testing)
- Basic understanding of Python and HTTP requests

### Deployment Methods

This lab demonstrates two deployment approaches:

#### Method 1: AWS Console Deployment

Follow the step-by-step guide in [deployment/deploy-console.md](./deployment/deploy-console.md) to:
1. Create the deployment package locally
2. Upload to Lambda via AWS Console
3. Configure execution role and runtime settings
4. Test the function with sample events

#### Method 2: AWS CLI Deployment

Use the automated scripts for faster deployment:

```bash
# Package the Lambda function
cd deployment
./package-lambda.sh

# Deploy using AWS CLI
./deploy-cli.sh
```

See [deployment/deploy-cli.sh](./deployment/deploy-cli.sh) for detailed CLI commands.

### Testing the Function

**Test Event Payload (Valid URL):**
```json
{
  "url": "https://aws.amazon.com"
}
```

**Expected Response:**
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

**Test Event Payload (Invalid URL):**
```json
{
  "url": "https://invalid-domain-that-does-not-exist-12345.com"
}
```

**Expected Response:**
```json
{
  "statusCode": 500,
  "body": {
    "url": "https://invalid-domain-that-does-not-exist-12345.com",
    "status": "error",
    "message": "Connection error: [error details]"
  }
}
```

### Invocation via AWS CLI

```bash
# Invoke function with inline payload
aws lambda invoke \
  --function-name URLChecker \
  --payload '{"url":"https://aws.amazon.com"}' \
  response.json

# View response
cat response.json
```

### Monitoring with CloudWatch

1. Navigate to CloudWatch Logs in AWS Console
2. Find log group: `/aws/lambda/URLChecker`
3. View log streams for each invocation
4. Analyze execution duration, memory usage, and custom log messages

## Application Code

The Lambda function is implemented in Python 3.13 with the following components:

- **[application/app.py](./application/app.py)** - Main Lambda handler with URL checking logic
- **[application/requirements.txt](./application/requirements.txt)** - Python dependencies (requests library)

### Key Features

- URL validation and HTTP GET requests
- Timeout handling (5-second request timeout)
- Exception handling for network errors, invalid URLs, and timeouts
- Structured JSON responses with status codes
- CloudWatch logging for debugging

## Deployment Scripts

- **[deployment/package-lambda.sh](./deployment/package-lambda.sh)** - Creates deployment ZIP with dependencies
- **[deployment/deploy-cli.sh](./deployment/deploy-cli.sh)** - AWS CLI commands for function creation and updates
- **[deployment/deploy-console.md](./deployment/deploy-console.md)** - Step-by-step Console deployment guide

## Troubleshooting

### Common Issues

**Issue**: Function returns "Unable to import module 'app'"
- **Cause**: Deployment package structure is incorrect
- **Solution**: Ensure `app.py` is at the root of the ZIP file, not in a subdirectory

**Issue**: "No module named 'requests'"
- **Cause**: Dependencies not included in deployment package
- **Solution**: Run `package-lambda.sh` to bundle the requests library

**Issue**: Function timeout after 3 seconds
- **Cause**: Default timeout is too short for network requests
- **Solution**: Increase Lambda timeout to 10+ seconds in function configuration

**Issue**: "Access Denied" when creating function
- **Cause**: IAM user lacks Lambda permissions
- **Solution**: Attach `AWSLambdaFullAccess` policy or create custom policy

**Issue**: CloudWatch logs not appearing
- **Cause**: Execution role lacks CloudWatch Logs permissions
- **Solution**: Ensure role has `AWSLambdaBasicExecutionRole` policy attached

## Serverless Benefits vs EC2

| Aspect | AWS Lambda (Serverless) | Amazon EC2 (Traditional) |
|--------|------------------------|--------------------------|
| **Infrastructure Management** | None - fully managed | Server provisioning, patching, maintenance |
| **Scaling** | Automatic, instant | Manual or auto-scaling configuration required |
| **Pricing** | Pay per invocation (100ms increments) | Pay for running instances (hourly) |
| **Idle Costs** | Zero cost when not invoked | Continuous cost even when idle |
| **Deployment** | Upload code package | Full server setup and configuration |
| **High Availability** | Built-in across multiple AZs | Requires multi-AZ architecture design |
| **Execution Duration** | Limited to 15 minutes max | Unlimited |
| **State Management** | Stateless (external storage needed) | Can maintain local state |

## Real-World Applications

- **Website Monitoring**: Scheduled Lambda functions checking site availability
- **API Health Checks**: Validating microservice endpoints in distributed systems
- **Webhook Validation**: Testing third-party webhook URLs before registration
- **Link Verification**: Batch processing of URLs in content management systems
- **Uptime Monitoring**: Building custom monitoring solutions without server infrastructure

## Next Steps

- Add scheduled execution using Amazon EventBridge (CloudWatch Events)
- Store results in DynamoDB for historical tracking
- Send notifications via SNS when URLs are unreachable
- Implement retry logic with exponential backoff
- Add support for POST requests and custom headers
- Create API Gateway endpoint for HTTP-triggered invocations

## Complexity Level

**Intermediate** - Requires understanding of Python, HTTP requests, Lambda deployment packaging, and IAM roles.

## Estimated Time

**45-60 minutes** - Including deployment package creation, function deployment, testing, and CloudWatch log analysis.

## AWS Certification Alignment

- **AWS Certified Cloud Practitioner**: Understanding of serverless computing concepts
- **AWS Certified Solutions Architect Associate**: Lambda architecture patterns, IAM roles, CloudWatch integration
- **AWS Certified Developer Associate**: Lambda function development, deployment, and debugging

## Completion Date

2024-01-15
