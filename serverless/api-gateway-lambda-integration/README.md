# Connecting Serverless Functions with Amazon API Gateway

## Overview

This project demonstrates creating a complete serverless REST API using Amazon API Gateway HTTP API integrated with AWS Lambda functions. You'll build a customer management API with GET and POST endpoints, CORS configuration, and end-to-end testing.

## AWS Services Used

- **Amazon API Gateway** - HTTP API
- **AWS Lambda** - Backend functions
- **Amazon DynamoDB** - Data storage
- **AWS IAM** - API and function permissions

## Architecture

```
┌──────────────────┐
│   Web Client     │
│   (Browser/App)  │
└────────┬─────────┘
         │
         │ HTTPS
         ▼
┌──────────────────────────────┐
│   API Gateway HTTP API       │
│                              │
│  GET  /customers             │
│  POST /customers             │
│  GET  /customers/{id}        │
└────────┬─────────────────────┘
         │
         │ Lambda Proxy Integration
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌─────────┐ ┌─────────┐
│ Lambda  │ │ Lambda  │
│  (GET)  │ │ (POST)  │
└────┬────┘ └────┬────┘
     │           │
     └─────┬─────┘
           │
           ▼
    ┌─────────────┐
    │  DynamoDB   │
    │ (Customers) │
    └─────────────┘
```

## Key Concepts

### HTTP API vs REST API

| Feature | HTTP API | REST API |
|---------|----------|----------|
| **Cost** | 70% cheaper | Higher cost |
| **Latency** | Lower | Higher |
| **Features** | Basic | Advanced |
| **Caching** | No | Yes |
| **Request Validation** | No | Yes |
| **Usage Plans** | No | Yes |
| **Best For** | Simple APIs | Complex APIs |

### Lambda Proxy Integration
- **Request**: API Gateway passes entire request to Lambda
- **Response**: Lambda returns formatted API Gateway response
- **Flexibility**: Full control over response format
- **Headers**: Lambda manages all HTTP headers

### CORS Configuration
- **Purpose**: Allow cross-origin requests from browsers
- **Headers**: Access-Control-Allow-Origin, Methods, Headers
- **Preflight**: OPTIONS requests for complex requests
- **Security**: Restrict origins in production

## Objectives

- Create HTTP API with API Gateway
- Configure Lambda proxy integration
- Implement GET and POST endpoints
- Set up CORS for web access
- Test API with curl and Postman
- Deploy and version API

## Setup Instructions

### Step 1: Create HTTP API

```bash
aws apigatewayv2 create-api \
    --name CustomerAPI \
    --protocol-type HTTP \
    --cors-configuration file://configs/cors-config.json
```

### Step 2: Create Lambda Integration

```bash
# Create integration for GET
aws apigatewayv2 create-integration \
    --api-id <api-id> \
    --integration-type AWS_PROXY \
    --integration-uri arn:aws:lambda:REGION:ACCOUNT_ID:function:ListCustomers \
    --payload-format-version 2.0

# Create integration for POST
aws apigatewayv2 create-integration \
    --api-id <api-id> \
    --integration-type AWS_PROXY \
    --integration-uri arn:aws:lambda:REGION:ACCOUNT_ID:function:SaveCustomer \
    --payload-format-version 2.0
```

### Step 3: Create Routes

```bash
# GET /customers
aws apigatewayv2 create-route \
    --api-id <api-id> \
    --route-key 'GET /customers' \
    --target integrations/<integration-id>

# POST /customers
aws apigatewayv2 create-route \
    --api-id <api-id> \
    --route-key 'POST /customers' \
    --target integrations/<integration-id>
```

### Step 4: Create Stage and Deploy

```bash
aws apigatewayv2 create-stage \
    --api-id <api-id> \
    --stage-name prod \
    --auto-deploy
```

### Step 5: Grant API Gateway Permission to Invoke Lambda

```bash
aws lambda add-permission \
    --function-name ListCustomers \
    --statement-id apigateway-invoke \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:REGION:ACCOUNT_ID:<api-id>/*"
```

### Step 6: Test API

```bash
# List customers
curl https://<api-id>.execute-api.<region>.amazonaws.com/customers

# Create customer
curl -X POST https://<api-id>.execute-api.<region>.amazonaws.com/customers \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Smith",
    "email": "jane@example.com",
    "phone": "+1-555-0123"
  }'
```

## Interview Talking Points

**Q: When to use HTTP API vs REST API?**
- **HTTP API**: Cost-sensitive, simple APIs, modern applications
- **REST API**: Need caching, request validation, usage plans, API keys
- **Migration**: Can migrate REST to HTTP for cost savings

**Q: How do you secure API Gateway?**
- **IAM Authorization**: AWS Signature V4
- **Lambda Authorizers**: Custom authorization logic
- **Cognito User Pools**: User authentication
- **API Keys**: Simple client identification (not security)
- **WAF**: Protect against common web exploits

**Q: How do you handle API versioning?**
- **URL Versioning**: /v1/customers, /v2/customers
- **Header Versioning**: Accept: application/vnd.api.v2+json
- **Stages**: dev, staging, prod with different backends
- **Best Practice**: URL versioning for clarity

## Best Practices Implemented

✅ **HTTP API**: Cost-effective for simple REST APIs  
✅ **Lambda Proxy**: Flexible request/response handling  
✅ **CORS**: Properly configured for web clients  
✅ **Error Handling**: Consistent error responses  
✅ **Logging**: CloudWatch Logs enabled  
✅ **Throttling**: Protect backend from overload  
✅ **Stages**: Separate dev/prod environments

## Metadata

- **Complexity Level**: Intermediate
- **Estimated Time**: 45 minutes
- **Prerequisites**: Lambda basics, REST API concepts

## Real-World Application

- **REST API backends**: The most common serverless pattern on AWS — powers millions of production APIs from startups to enterprises
- **Mobile app backends**: API Gateway + Lambda provides auto-scaling backends for mobile apps without capacity planning
- **Webhook receivers**: SaaS platforms expose webhook endpoints that trigger Lambda functions for event processing (Stripe payments, GitHub events, Slack commands)
- **API versioning**: API Gateway stages enable v1/v2 API versioning with gradual traffic migration between Lambda function versions
