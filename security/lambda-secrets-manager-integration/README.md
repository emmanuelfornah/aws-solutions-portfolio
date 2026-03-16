# Securing Data Accessed by Lambda Functions

## Overview

This project demonstrates secure data access patterns for AWS Lambda functions using Secrets Manager integration. The implementation includes configuring Lambda execution roles with least privilege permissions, retrieving secrets from Secrets Manager within Lambda code, implementing secret caching for performance optimization, handling secret rotation in Lambda functions, and monitoring secret access with CloudWatch Logs.

## AWS Services Used

- **AWS Lambda** - Serverless compute functions
- **AWS Secrets Manager** - Secure secret storage
- **AWS KMS** - Encryption key management
- **AWS IAM** - Access control and permissions
- **Amazon CloudWatch** - Logging and monitoring
- **AWS X-Ray** - Distributed tracing

## Key Technologies

- **Lambda Execution Roles** - IAM roles for function permissions
- **Secrets Manager SDK** - Programmatic secret retrieval
- **Secret Caching** - Performance optimization
- **Environment Variables** - Configuration management
- **VPC Integration** - Private network access
- **Error Handling** - Graceful failure management

## Architecture Overview

The architecture implements secure secret access for Lambda functions using IAM roles and Secrets Manager. Lambda functions retrieve database credentials and API keys from Secrets Manager using the AWS SDK. Secrets are cached in memory for the lifetime of the Lambda execution environment to minimize API calls and improve performance. Functions handle secret rotation gracefully by catching exceptions and refreshing cached values.

See [architecture.md](./architecture.md) for detailed secret retrieval flow and caching strategies.

## Objectives

- Configure Lambda execution role with secret access
- Retrieve secrets from Secrets Manager in Lambda code
- Implement secret caching for performance
- Handle secret rotation in Lambda functions
- Use VPC endpoints for private secret access
- Monitor secret access with CloudWatch Logs
- Implement error handling and retry logic
- Follow security best practices for Lambda

## Technical Highlights

- **Lambda IAM Roles**: Execution role configuration
- **Secrets Manager SDK**: Programmatic secret retrieval
- **Secret Caching**: Performance optimization techniques
- **Rotation Handling**: Graceful secret updates
- **VPC Integration**: Private network access
- **Error Handling**: Retry logic and fallbacks
- **Monitoring**: CloudWatch Logs and X-Ray tracing
- **Best Practices**: Secure Lambda development

## Setup Instructions

### Prerequisites

- AWS account with Lambda and Secrets Manager permissions
- AWS CLI configured with appropriate credentials
- Python 3.9+ or Node.js 18+ for Lambda runtime
- Understanding of Lambda execution model

### Step 1: Create Secret in Secrets Manager

Store database credentials:

```bash
./scripts/create-secret.sh
```

### Step 2: Create Lambda Execution Role

Configure IAM permissions:

```bash
./scripts/create-execution-role.sh
```

### Step 3: Deploy Lambda Function

Deploy function with secret access:

```bash
./scripts/deploy-lambda.sh
```

### Step 4: Test Secret Retrieval

Invoke function and verify:

```bash
./scripts/test-lambda.sh
```

### Step 5: Implement Secret Caching

Add caching layer:

```bash
./scripts/implement-caching.sh
```

### Step 6: Test Secret Rotation

Verify rotation handling:

```bash
./scripts/test-rotation.sh
```

### Step 7: Monitor Secret Access

View CloudWatch Logs:

```bash
./scripts/monitor-access.sh
```

### Step 8: Performance Testing

Measure caching impact:

```bash
./scripts/performance-test.sh
```

## Scripts and Configurations

### Scripts

- **create-secret.sh** - Creates secret in Secrets Manager
- **create-execution-role.sh** - Creates Lambda IAM role
- **deploy-lambda.sh** - Deploys Lambda function
- **test-lambda.sh** - Tests secret retrieval
- **implement-caching.sh** - Adds caching layer
- **test-rotation.sh** - Tests rotation handling
- **monitor-access.sh** - Views CloudWatch Logs
- **performance-test.sh** - Measures performance
- **cleanup.sh** - Removes all resources

### Configuration Files

- **lambda-role-policy.json** - IAM policy for Lambda
- **lambda-function.py** - Python Lambda code
- **lambda-function.js** - Node.js Lambda code
- **requirements.txt** - Python dependencies

## Metadata

- **Domain**: Security
- **Complexity Level**: Intermediate
- **Estimated Time**: 60 minutes
- **AWS Services**: Lambda, Secrets Manager, KMS, IAM, CloudWatch, X-Ray
- **Key Concepts**: Secure data access, secret caching, IAM roles, error handling

## Real-World Application

- **Serverless database access**: Lambda functions accessing RDS, DynamoDB, or third-party APIs retrieve credentials from Secrets Manager at runtime — never hardcoded
- **Secret caching**: High-throughput Lambda functions cache secrets locally to avoid Secrets Manager API calls on every invocation — reducing latency by 99%
- **Credential rotation**: Applications using Secrets Manager automatically pick up rotated credentials without redeployment or downtime
- **Third-party API keys**: SaaS integrations store API keys, OAuth tokens, and webhook secrets in Secrets Manager with IAM-controlled access
