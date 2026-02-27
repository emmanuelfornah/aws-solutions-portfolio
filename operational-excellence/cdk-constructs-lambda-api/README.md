# Working with Constructs in AWS CDK

## Overview

This lab introduces AWS Cloud Development Kit (CDK) fundamentals through building a Lambda-backed API endpoint using Python. Unlike CloudFormation's declarative YAML/JSON templates, CDK uses familiar programming languages to define infrastructure as code. You'll learn CDK core concepts including constructs (reusable cloud components), synthesis (converting code to CloudFormation), deployment, testing with pytest, and iterative updates. The lab demonstrates the power of programmatic infrastructure definition by creating a serverless API that returns greeting messages.

## AWS Services Used

- **AWS CDK** - Infrastructure as Code framework using programming languages
- **AWS Lambda** - Serverless compute for API backend logic
- **Amazon API Gateway** - RESTful API endpoint management
- **AWS CloudFormation** - Underlying deployment engine (CDK synthesizes to CloudFormation)
- **AWS IAM** - Execution roles and permissions for Lambda functions
- **AWS Code Editor** - Cloud-based IDE for CDK development

## Architecture

The CDK application creates a serverless API architecture:

1. **CDK App (app.py)**: Entry point that instantiates the stack
2. **Lambda Function Stack (lambda_api_stack.py)**: Defines infrastructure using CDK constructs
3. **Lambda Function (hello.py)**: Python 3.13 handler returning greeting messages
4. **IAM Role**: Pre-created HelloLambdaRole with permissions boundary for security
5. **API Gateway**: LambdaRestApi construct providing HTTP endpoint
6. **CloudFormation Template**: Generated via `cdk synth` from Python code
7. **Pytest Tests**: Assertion-based tests validating infrastructure properties

**CDK Construct Hierarchy:**
- **L1 Constructs (CfnXxx)**: Direct CloudFormation resource mappings
- **L2 Constructs (Lambda.Function)**: Higher-level abstractions with sensible defaults
- **L3 Constructs (LambdaRestApi)**: Opinionated patterns combining multiple resources

## Objectives

- Understand AWS CDK fundamentals and construct-based infrastructure modeling
- Initialize a CDK project with Python and manage dependencies
- Create Lambda functions using CDK constructs
- Reference pre-existing IAM roles using `from_role_arn`
- Add API Gateway endpoints to Lambda functions
- Synthesize CDK code into CloudFormation templates
- Deploy and update CDK stacks with `cdk deploy` and `cdk diff`
- Write pytest assertion tests for infrastructure validation
- Test deployed APIs with curl and browser
- Clean up resources with `cdk destroy`

## Key Learnings

- **CDK Abstracts CloudFormation Complexity**: Instead of writing verbose YAML, you use Python classes and methods. CDK generates optimized CloudFormation templates automatically.

- **Constructs Are Reusable Components**: The `Lambda.Function` and `LambdaRestApi` constructs encapsulate best practices, reducing boilerplate and preventing configuration errors.

- **Synthesis Separates Definition from Deployment**: `cdk synth` generates CloudFormation templates without deploying, enabling review and version control of infrastructure changes.

- **CDK Diff Shows Infrastructure Changes**: `cdk diff` compares current stack state with proposed changes, similar to `git diff` for infrastructure, preventing unexpected modifications.

- **IAM Roles Can Be Referenced**: Using `from_role_arn` allows CDK to reference pre-existing IAM roles without managing them, useful for security-controlled environments.

- **API Gateway Integration Is Simplified**: The `LambdaRestApi` construct automatically creates API Gateway resources, deployment stages, and Lambda proxy integration with minimal code.

- **Pytest Assertions Validate Infrastructure**: CDK's `assertions` module enables testing infrastructure properties before deployment, catching configuration errors early.

- **Bootstrap Prepares AWS Environment**: CDK requires one-time bootstrap to create S3 buckets and IAM roles for deployment. Custom bootstraps can enforce security boundaries.

- **CDK Supports Iterative Development**: You can deploy, test, modify code, and redeploy quickly, enabling rapid infrastructure iteration similar to application development.

## Setup Instructions

### Prerequisites

- AWS account with CDK, Lambda, API Gateway, and IAM permissions
- AWS Code Editor IDE access (or local environment with AWS CLI configured)
- Python 3.13 installed
- Node.js and npm installed (for CDK CLI)
- Basic understanding of Python and REST APIs

### Step 1: Install AWS CDK CLI

If not already installed:

```bash
npm install -g aws-cdk

# Verify installation
cdk --version
```

### Step 2: Initialize CDK Project

```bash
# Create project directory
mkdir lambda-api
cd lambda-api

# Initialize CDK app with Python
cdk init app --language python

# Project structure created:
# - app.py: CDK app entry point
# - lambda_api/lambda_api_stack.py: Stack definition
# - requirements.txt: Python dependencies
# - cdk.json: CDK configuration
```

### Step 3: Set Up Python Virtual Environment

```bash
# Create virtual environment
python3 -m venv .venv

# Activate virtual environment
source .venv/bin/activate  # Linux/Mac
# .venv\Scripts\activate.bat  # Windows

# Install dependencies
pip install -r requirements.txt
```

### Step 4: Create Lambda Function Handler

Create `hello.py` in the project root:

```python
import json

def handler(event, context):
    """
    Lambda function handler for API Gateway proxy integration.
    Returns a greeting message with the requested path.
    """
    # Extract path from API Gateway event
    path = event.get('path', '/')
    
    # Construct greeting message
    message = f"Hello from Lambda! You requested: {path}"
    
    # Return API Gateway proxy response
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': message,
            'event': event.get('httpMethod', 'UNKNOWN')
        })
    }
```

### Step 5: Define Lambda Infrastructure in CDK Stack

Edit `lambda_api/lambda_api_stack.py`:

```python
from aws_cdk import (
    Stack,
    aws_lambda as _lambda,
    aws_iam as iam,
)
from constructs import Construct
import os

class LambdaApiStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        
        # Reference pre-created IAM role
        lambda_role = iam.Role.from_role_arn(
            self, 
            'HelloLambdaRole',
            role_arn=f'arn:aws:iam::{os.environ.get("CDK_DEFAULT_ACCOUNT")}:role/HelloLambdaRole'
        )
        
        # Create Lambda function
        hello_function = _lambda.Function(
            self,
            'HelloFunction',
            runtime=_lambda.Runtime.PYTHON_3_13,
            handler='hello.handler',
            code=_lambda.Code.from_asset('.'),
            role=lambda_role
        )
```

### Step 6: Synthesize and Deploy Initial Stack

```bash
# Synthesize CloudFormation template
cdk synth

# Review generated template in cdk.out/LambdaApiStack.template.json

# Deploy stack
cdk deploy

# Confirm deployment when prompted
```

### Step 7: Test Lambda Function in Console

1. Navigate to Lambda in AWS Console
2. Find the `HelloFunction` function
3. Click "Test" tab
4. Create test event with API Gateway proxy template:

```json
{
  "path": "/hello",
  "httpMethod": "GET",
  "headers": {},
  "queryStringParameters": null,
  "body": null
}
```

5. Click "Test" and verify response

### Step 8: Add API Gateway Endpoint

Update `lambda_api/lambda_api_stack.py` to add API Gateway:

```python
from aws_cdk import (
    Stack,
    aws_lambda as _lambda,
    aws_iam as iam,
    aws_apigateway as apigateway,  # Add this import
)
from constructs import Construct
import os

class LambdaApiStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        
        # Reference pre-created IAM role
        lambda_role = iam.Role.from_role_arn(
            self, 
            'HelloLambdaRole',
            role_arn=f'arn:aws:iam::{os.environ.get("CDK_DEFAULT_ACCOUNT")}:role/HelloLambdaRole'
        )
        
        # Create Lambda function
        hello_function = _lambda.Function(
            self,
            'HelloFunction',
            runtime=_lambda.Runtime.PYTHON_3_13,
            handler='hello.handler',
            code=_lambda.Code.from_asset('.'),
            role=lambda_role
        )
        
        # Create API Gateway endpoint
        api = apigateway.LambdaRestApi(
            self,
            'HelloApi',
            handler=hello_function,
            proxy=True,
            description='Lambda-backed API endpoint'
        )
```

### Step 9: Write Pytest Assertion Tests

Create `tests/unit/test_lambda_api_stack.py`:

```python
import aws_cdk as cdk
from aws_cdk.assertions import Template
from lambda_api.lambda_api_stack import LambdaApiStack
import pytest

@pytest.fixture
def template():
    """Fixture that creates a CloudFormation template from the stack."""
    app = cdk.App()
    stack = LambdaApiStack(app, "TestStack")
    return Template.from_stack(stack)

def test_api_gateway_created(template):
    """Test that API Gateway RestApi resource exists."""
    template.has_resource_properties(
        "AWS::ApiGateway::RestApi",
        {
            "Description": "Lambda-backed API endpoint"
        }
    )

def test_api_gateway_deployment_count(template):
    """Test that exactly one API Gateway Deployment exists."""
    template.resource_count_is("AWS::ApiGateway::Deployment", 1)

def test_lambda_function_properties(template):
    """Test Lambda function configuration."""
    template.has_resource_properties(
        "AWS::Lambda::Function",
        {
            "Handler": "hello.handler",
            "Runtime": "python3.13"
        }
    )
```

Install pytest:

```bash
pip install pytest
```

Run tests:

```bash
pytest tests/
```

### Step 10: Deploy Updated Stack

```bash
# Preview changes
cdk diff

# Deploy updates
cdk deploy
```

### Step 11: Test API Endpoint

After deployment, CDK outputs the API Gateway URL:

```bash
# Test with curl
curl https://your-api-id.execute-api.region.amazonaws.com/prod/

# Test with specific path
curl https://your-api-id.execute-api.region.amazonaws.com/prod/hello

# Open in browser
# Navigate to the API URL
```

### Step 12: Clean Up Resources

```bash
# Destroy all resources
cdk destroy

# Confirm deletion when prompted
```

## Application Code

### Lambda Handler

- **[application/hello.py](./application/hello.py)** - Lambda function handler with API Gateway proxy integration

### CDK Infrastructure Code

- **[application/app.py](./application/app.py)** - CDK app entry point
- **[application/lambda_api_stack.py](./application/lambda_api_stack.py)** - Stack definition with Lambda and API Gateway constructs
- **[application/requirements.txt](./application/requirements.txt)** - Python dependencies for CDK

### Test Code

- **[application/tests/unit/test_lambda_api_stack.py](./application/tests/unit/test_lambda_api_stack.py)** - Pytest assertion tests for infrastructure validation

## Scripts

### CDK Workflow Scripts

- **[scripts/init-project.sh](./scripts/init-project.sh)** - Initialize new CDK project with Python
- **[scripts/synth-template.sh](./scripts/synth-template.sh)** - Synthesize CloudFormation template
- **[scripts/deploy-stack.sh](./scripts/deploy-stack.sh)** - Deploy CDK stack
- **[scripts/test-api.sh](./scripts/test-api.sh)** - Test deployed API endpoint
- **[scripts/destroy-stack.sh](./scripts/destroy-stack.sh)** - Clean up all resources

### Testing Scripts

- **[scripts/run-tests.sh](./scripts/run-tests.sh)** - Execute pytest tests

## Configuration Files

- **[configs/cdk.json](./configs/cdk.json)** - CDK configuration and context
- **[configs/requirements.txt](./configs/requirements.txt)** - Python dependencies for CDK project

## Troubleshooting

### Common Issues

**Issue**: `cdk: command not found`
- **Cause**: CDK CLI not installed
- **Solution**: Run `npm install -g aws-cdk`

**Issue**: "This stack uses assets, so the toolkit stack must be deployed"
- **Cause**: CDK bootstrap not completed
- **Solution**: Run `cdk bootstrap aws://ACCOUNT-ID/REGION`

**Issue**: "Role HelloLambdaRole does not exist"
- **Cause**: Pre-created IAM role is missing
- **Solution**: Create the role manually or modify stack to create role inline

**Issue**: Pytest tests fail with "No module named 'aws_cdk'"
- **Cause**: Dependencies not installed in virtual environment
- **Solution**: Activate venv and run `pip install -r requirements.txt`

**Issue**: `cdk deploy` fails with "Permissions boundary required"
- **Cause**: AWS environment has security policies requiring permissions boundaries
- **Solution**: Use custom bootstrap with permissions boundary or modify role creation

**Issue**: API Gateway returns 502 Bad Gateway
- **Cause**: Lambda function error or incorrect response format
- **Solution**: Check CloudWatch Logs for Lambda errors, verify response includes statusCode and body

**Issue**: `cdk diff` shows no changes but code was modified
- **Cause**: CDK caches synthesized templates
- **Solution**: Run `cdk synth --force` to regenerate template

## CDK vs CloudFormation Comparison

| Aspect | AWS CDK | AWS CloudFormation |
|--------|---------|-------------------|
| **Language** | Python, TypeScript, Java, C#, Go | YAML, JSON |
| **Abstraction Level** | High-level constructs | Low-level resource definitions |
| **Code Reusability** | Classes, functions, modules | Nested stacks, macros |
| **Type Safety** | IDE autocomplete, type checking | Schema validation only |
| **Testing** | Unit tests with assertions | Template validation, integration tests |
| **Learning Curve** | Requires programming knowledge | Requires YAML/JSON and AWS resource knowledge |
| **Deployment** | Synthesizes to CloudFormation | Direct deployment |
| **Community Libraries** | CDK Construct Hub | CloudFormation Registry |

## Real-World Applications

- **Microservices APIs**: Build multiple Lambda-backed APIs with consistent patterns
- **Infrastructure Testing**: Validate infrastructure properties before deployment using pytest
- **Multi-Environment Deployments**: Use CDK context and parameters for dev/staging/prod
- **Custom Constructs**: Create reusable infrastructure patterns for organization-wide use
- **CI/CD Integration**: Automate CDK synthesis and deployment in pipelines
- **Infrastructure Refactoring**: Safely modify infrastructure with diff previews

## Next Steps

- Add DynamoDB table for data persistence
- Implement multiple API endpoints with different Lambda functions
- Add CloudWatch alarms for Lambda errors and API latency
- Create custom CDK constructs for reusable patterns
- Implement CDK Pipelines for automated deployment
- Add API Gateway authentication with Cognito
- Explore CDK aspects for cross-cutting concerns (tagging, security)

## Complexity Level

**Intermediate** - Requires Python programming knowledge, understanding of Lambda and API Gateway, and familiarity with Infrastructure as Code concepts.

## Estimated Time

**45 minutes** - Including CDK project initialization, Lambda function creation, API Gateway integration, testing, and cleanup.

## AWS Certification Alignment

- **AWS Certified Cloud Practitioner**: Understanding of Infrastructure as Code and serverless concepts
- **AWS Certified Solutions Architect Associate**: CDK architecture patterns, Lambda and API Gateway integration
- **AWS Certified Developer Associate**: CDK development, Lambda function deployment, API testing
- **AWS Certified DevOps Engineer Professional**: CDK best practices, infrastructure testing, CI/CD integration

## Completion Date

2024-01-20
