# Creating a Serverless Application with AWS SAM

## Overview

This project demonstrates using AWS Serverless Application Model (SAM) to define, build, and deploy serverless applications using Infrastructure as Code. SAM simplifies CloudFormation syntax and provides local development capabilities.

## AWS Services Used

- **AWS SAM** - Serverless application framework
- **AWS CloudFormation** - Infrastructure provisioning
- **AWS Lambda** - Serverless functions
- **Amazon API Gateway** - HTTP API
- **Amazon DynamoDB** - Database
- **SAM CLI** - Local development and deployment

## Architecture

```
┌──────────────────────────────────────┐
│      SAM Template (template.yaml)    │
│                                      │
│  - Lambda Functions                 │
│  - API Gateway                      │
│  - DynamoDB Tables                  │
│  - IAM Roles                        │
│  - Environment Variables            │
└──────────────┬───────────────────────┘
               │
               │ sam build
               ▼
┌──────────────────────────────────────┐
│      .aws-sam/build/                 │
│  (Compiled artifacts)                │
└──────────────┬───────────────────────┘
               │
               │ sam deploy
               ▼
┌──────────────────────────────────────┐
│      CloudFormation Stack            │
│                                      │
│  ┌────────────┐  ┌────────────┐     │
│  │  Lambda    │  │ API Gateway│     │
│  └────────────┘  └────────────┘     │
│  ┌────────────┐  ┌────────────┐     │
│  │ DynamoDB   │  │ IAM Roles  │     │
│  └────────────┘  └────────────┘     │
└──────────────────────────────────────┘
```

## Key Concepts

### SAM vs CloudFormation vs CDK

| Feature | SAM | CloudFormation | CDK |
|---------|-----|----------------|-----|
| **Syntax** | YAML (simplified) | YAML/JSON | TypeScript/Python |
| **Focus** | Serverless | All AWS | All AWS |
| **Learning Curve** | Easy | Medium | Medium-Hard |
| **Local Testing** | Yes | No | Limited |
| **Best For** | Serverless apps | Any infrastructure | Complex logic |

### SAM Template Structure

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Globals:
  # Shared configuration

Parameters:
  # Input parameters

Resources:
  # AWS resources

Outputs:
  # Stack outputs
```

### SAM CLI Commands

- `sam init` - Create new project from template
- `sam build` - Compile and prepare for deployment
- `sam deploy` - Deploy to AWS
- `sam local start-api` - Run API locally
- `sam local invoke` - Test function locally
- `sam logs` - Fetch CloudWatch logs
- `sam delete` - Remove stack

## Objectives

- Install and configure SAM CLI
- Create SAM template for serverless application
- Define Lambda functions, API, and DynamoDB
- Build application with sam build
- Deploy with sam deploy --guided
- Test locally with sam local
- Compare SAM vs raw CloudFormation

## Setup Instructions

### Step 1: Install SAM CLI

```bash
# macOS
brew install aws-sam-cli

# Windows
choco install aws-sam-cli

# Linux
pip install aws-sam-cli

# Verify installation
sam --version
```

### Step 2: Initialize SAM Project

```bash
sam init \
    --runtime python3.11 \
    --name customer-api \
    --app-template hello-world
```

### Step 3: Create SAM Template

See `template.yaml` for complete example.

### Step 4: Build Application

```bash
cd customer-api
sam build
```

### Step 5: Test Locally

```bash
# Start local API
sam local start-api

# Test in another terminal
curl http://localhost:3000/customers
```

### Step 6: Deploy to AWS

```bash
sam deploy --guided

# Follow prompts:
# - Stack name
# - AWS Region
# - Confirm changes
# - Allow IAM role creation
# - Save configuration
```

### Step 7: Test Deployed API

```bash
# Get API endpoint from outputs
aws cloudformation describe-stacks \
    --stack-name customer-api \
    --query 'Stacks[0].Outputs'

# Test endpoint
curl https://<api-id>.execute-api.<region>.amazonaws.com/Prod/customers
```

## SAM Template Example

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: Customer Management API

Globals:
  Function:
    Timeout: 10
    Runtime: python3.11
    Environment:
      Variables:
        TABLE_NAME: !Ref CustomersTable

Resources:
  # API Gateway
  CustomerApi:
    Type: AWS::Serverless::HttpApi
    Properties:
      CorsConfiguration:
        AllowOrigins:
          - "*"
        AllowMethods:
          - GET
          - POST
        AllowHeaders:
          - "*"

  # Lambda Functions
  ListCustomersFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/list_customers/
      Handler: app.lambda_handler
      Policies:
        - DynamoDBReadPolicy:
            TableName: !Ref CustomersTable
      Events:
        ListCustomers:
          Type: HttpApi
          Properties:
            ApiId: !Ref CustomerApi
            Path: /customers
            Method: GET

  SaveCustomerFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/save_customer/
      Handler: app.lambda_handler
      Policies:
        - DynamoDBCrudPolicy:
            TableName: !Ref CustomersTable
      Events:
        SaveCustomer:
          Type: HttpApi
          Properties:
            ApiId: !Ref CustomerApi
            Path: /customers
            Method: POST

  # DynamoDB Table
  CustomersTable:
    Type: AWS::Serverless::SimpleTable
    Properties:
      PrimaryKey:
        Name: customerId
        Type: String
      TableName: Customers

Outputs:
  ApiEndpoint:
    Description: "API Gateway endpoint URL"
    Value: !Sub "https://${CustomerApi}.execute-api.${AWS::Region}.amazonaws.com/Prod/"
  
  CustomersTableName:
    Description: "DynamoDB table name"
    Value: !Ref CustomersTable
```

## Interview Talking Points

**Q: Why use SAM instead of CloudFormation?**
- **Simplified Syntax**: Less verbose for serverless resources
- **Local Testing**: Test Lambda and API locally
- **Built-in Policies**: Predefined IAM policies
- **Faster Development**: Quick iteration cycle
- **Best Practices**: Enforces serverless patterns

**Q: How do you manage multiple environments with SAM?**
- **Parameters**: Use parameters for environment-specific values
- **Separate Stacks**: Deploy dev, staging, prod stacks
- **samconfig.toml**: Store deployment configurations
- **Environment Variables**: Pass to Lambda functions

**Q: What are SAM's limitations?**
- **Serverless Focus**: Not ideal for EC2, containers
- **CloudFormation Dependency**: Ultimately uses CloudFormation
- **Learning Curve**: Need to understand both SAM and CloudFormation
- **Alternative**: Use CDK for more complex applications

## Best Practices Implemented

✅ **Infrastructure as Code**: Version-controlled templates  
✅ **Parameterization**: Configurable deployments  
✅ **Least Privilege**: Minimal IAM permissions  
✅ **Local Testing**: Validate before deployment  
✅ **Outputs**: Export important values  
✅ **Globals**: Shared configuration  
✅ **Policy Templates**: Built-in IAM policies

## SAM vs CloudFormation Comparison

### SAM (Simplified)
```yaml
ListCustomersFunction:
  Type: AWS::Serverless::Function
  Properties:
    CodeUri: functions/list_customers/
    Handler: app.lambda_handler
    Events:
      ListCustomers:
        Type: HttpApi
        Properties:
          Path: /customers
          Method: GET
```

### CloudFormation (Verbose)
```yaml
ListCustomersFunction:
  Type: AWS::Lambda::Function
  Properties:
    Code:
      S3Bucket: !Ref DeploymentBucket
      S3Key: functions/list_customers.zip
    Handler: app.lambda_handler
    Role: !GetAtt LambdaExecutionRole.Arn
    Runtime: python3.11

ApiGatewayRoute:
  Type: AWS::ApiGatewayV2::Route
  Properties:
    ApiId: !Ref HttpApi
    RouteKey: 'GET /customers'
    Target: !Sub 'integrations/${ApiIntegration}'

ApiIntegration:
  Type: AWS::ApiGatewayV2::Integration
  Properties:
    ApiId: !Ref HttpApi
    IntegrationType: AWS_PROXY
    IntegrationUri: !GetAtt ListCustomersFunction.Arn
```

## Metadata

- **Complexity Level**: Advanced
- **Estimated Time**: 60 minutes
- **Prerequisites**: CloudFormation basics, serverless concepts

## Real-World Application

- **Serverless CI/CD**: SAM templates define entire serverless applications (Lambda, API Gateway, DynamoDB) and deploy through CodePipeline with `sam build && sam deploy`
- **Local development**: `sam local invoke` and `sam local start-api` enable developers to test Lambda functions locally before deploying — reducing iteration time from minutes to seconds
- **Multi-environment deployment**: SAM parameter overrides deploy the same template to dev/staging/prod with different configurations
- **Open-source serverless**: SAM is an extension of CloudFormation — templates are portable and work with any CI/CD system, not just AWS CodePipeline
