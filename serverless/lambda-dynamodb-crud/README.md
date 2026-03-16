# Creating AWS Lambda Functions to List and Save Customers

## Overview

This project demonstrates building foundational serverless applications with AWS Lambda and DynamoDB. You'll create Lambda functions that perform CRUD operations on a DynamoDB table and integrate with an S3-hosted static website.

## AWS Services Used

- **AWS Lambda** - Serverless compute (Python 3.x)
- **Amazon DynamoDB** - NoSQL database
- **Amazon S3** - Static website hosting
- **AWS IAM** - Function permissions
- **Boto3** - AWS SDK for Python

## Architecture

```
┌──────────────────┐
│  S3 Static Site  │
│  (Frontend HTML) │
└────────┬─────────┘
         │
         │ Invoke
         ▼
┌──────────────────┐         ┌──────────────────┐
│ Lambda Function  │────────>│   DynamoDB       │
│ (List Customers) │  Scan   │ (Customers Table)│
└──────────────────┘         └──────────────────┘

┌──────────────────┐         ┌──────────────────┐
│ Lambda Function  │────────>│   DynamoDB       │
│ (Save Customer)  │ PutItem │ (Customers Table)│
└──────────────────┘         └──────────────────┘
```

## Key Concepts

### Lambda Function Basics
- **Handler**: Entry point for function execution
- **Event**: Input data passed to function
- **Context**: Runtime information
- **Environment Variables**: Configuration values
- **IAM Role**: Permissions for AWS service access

### DynamoDB Operations
- **Scan**: Read all items (use carefully in production)
- **PutItem**: Create or replace item
- **GetItem**: Read single item by key
- **Query**: Efficient retrieval with partition key

### Boto3 SDK
- **Resource API**: High-level, object-oriented
- **Client API**: Low-level, service-specific
- **Error Handling**: ClientError exceptions
- **Pagination**: Handle large result sets

## Objectives

- Create DynamoDB table for customer data
- Build Lambda function to list all customers
- Build Lambda function to save new customers
- Test functions with mock events
- Deploy S3 static website
- Integrate frontend with Lambda functions

## Setup Instructions

### Step 1: Create DynamoDB Table

```bash
aws dynamodb create-table \
    --table-name Customers \
    --attribute-definitions \
        AttributeName=customerId,AttributeType=S \
    --key-schema \
        AttributeName=customerId,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
```

### Step 2: Create Lambda Execution Role

```bash
aws iam create-role \
    --role-name LambdaDynamoDBRole \
    --assume-role-policy-document file://configs/lambda-trust-policy.json

aws iam attach-role-policy \
    --role-name LambdaDynamoDBRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam put-role-policy \
    --role-name LambdaDynamoDBRole \
    --policy-name DynamoDBAccess \
    --policy-document file://configs/dynamodb-policy.json
```

### Step 3: Deploy Lambda Functions

See `scripts/` directory for function code:
- `list_customers.py` - Retrieve all customers
- `save_customer.py` - Add new customer

### Step 4: Test Functions

```bash
# Test list function
aws lambda invoke \
    --function-name ListCustomers \
    --payload '{}' \
    response.json

# Test save function
aws lambda invoke \
    --function-name SaveCustomer \
    --payload file://test-events/save-customer-event.json \
    response.json
```

### Step 5: Deploy S3 Static Website

```bash
# Create bucket
aws s3 mb s3://customer-app-ACCOUNT_ID

# Enable static website hosting
aws s3 website s3://customer-app-ACCOUNT_ID \
    --index-document index.html

# Upload website files
aws s3 cp website/ s3://customer-app-ACCOUNT_ID/ --recursive
```

## Scripts and Configurations

### Lambda Functions
- `scripts/list_customers.py` - DynamoDB scan operation
- `scripts/save_customer.py` - DynamoDB put_item operation

### Test Events
- `test-events/save-customer-event.json` - Sample customer data

### IAM Policies
- `configs/lambda-trust-policy.json` - Lambda execution role
- `configs/dynamodb-policy.json` - DynamoDB permissions

### Website Files
- `website/index.html` - Customer management interface

## Interview Talking Points

**Q: What are Lambda cold starts and how do you optimize them?**
- **Cold Start**: First invocation or after idle period
- **Optimization**: 
  - Minimize deployment package size
  - Use Lambda Layers for dependencies
  - Increase memory allocation (more CPU)
  - Use Provisioned Concurrency for critical functions
  - Keep functions warm with scheduled pings (anti-pattern for cost)

**Q: When to use DynamoDB scan vs query?**
- **Scan**: Reads entire table, expensive, slow
- **Query**: Uses partition key, fast, efficient
- **Best Practice**: Always use Query when possible
- **Scan Use Cases**: Small tables, admin operations, full-text search alternatives

**Q: How do you handle errors in Lambda?**
- **Try-Catch**: Wrap code in exception handlers
- **Logging**: Use print() or logging module (goes to CloudWatch)
- **Dead Letter Queues**: Capture failed invocations
- **Retries**: Automatic for async invocations (2 attempts)
- **Idempotency**: Design functions to handle retries safely

## Best Practices Implemented

✅ **Error Handling**: Comprehensive try-catch blocks  
✅ **Logging**: Structured logging for debugging  
✅ **Environment Variables**: Externalized configuration  
✅ **Least Privilege**: Minimal IAM permissions  
✅ **Input Validation**: Check required fields  
✅ **Response Format**: Consistent JSON responses  
✅ **CORS Headers**: Enable cross-origin requests  
✅ **Idempotency**: Safe to retry operations

## Metadata

- **Complexity Level**: Intermediate
- **Estimated Time**: 45 minutes
- **Prerequisites**: Python basics, AWS fundamentals

## Real-World Application

- **Serverless web applications**: The Lambda + DynamoDB + S3 stack powers full-stack serverless apps with zero server management
- **CRUD microservices**: Each microservice owns its DynamoDB table and exposes CRUD operations through Lambda — the single-table design pattern
- **Real-time dashboards**: Admin dashboards backed by Lambda CRUD functions provide instant data access without provisioning application servers
- **IoT data ingestion**: IoT devices write sensor data through Lambda to DynamoDB — auto-scaling from zero to millions of writes per second
