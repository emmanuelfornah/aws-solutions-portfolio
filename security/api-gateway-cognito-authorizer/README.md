# Securing Amazon API Gateway Using an Amazon Cognito Authorizer

## Overview

This project demonstrates implementing authentication and authorization for REST APIs using Amazon Cognito User Pools as an authorizer for API Gateway. The implementation includes creating a Cognito User Pool with app client configuration, integrating Cognito authorizer with API Gateway, testing authenticated and unauthenticated requests, and implementing token-based access control for API endpoints.

## AWS Services Used

- **Amazon API Gateway** - RESTful API management and deployment
- **Amazon Cognito** - User authentication and authorization
- **AWS Lambda** - Backend API logic
- **AWS IAM** - Service permissions and roles
- **Amazon CloudWatch** - API and authentication logging

## Key Technologies

- **Cognito User Pools** - User directory and authentication
- **JWT Tokens** - JSON Web Tokens for authorization
- **OAuth 2.0** - Authorization framework
- **API Gateway Authorizers** - Request authorization
- **REST API** - HTTP API endpoints
- **Token Validation** - JWT signature verification

## Architecture Overview

The architecture implements a secure REST API using API Gateway with Cognito User Pool authorizer. Users authenticate with Cognito to receive JWT tokens (ID token, access token, refresh token). API Gateway validates JWT tokens before allowing requests to reach Lambda backend functions. Unauthorized requests are rejected at the API Gateway level, preventing unnecessary Lambda invocations.

See [architecture.md](./architecture.md) for detailed authentication flow and security architecture.

## Objectives

- Create and configure Cognito User Pool
- Set up Cognito app client for authentication
- Integrate Cognito authorizer with API Gateway
- Configure API Gateway methods with authorization
- Test authenticated API requests with JWT tokens
- Implement token-based access control
- Handle authentication errors and token expiration
- Monitor authentication attempts in CloudWatch

## Technical Highlights

- **Cognito User Pools**: User directory and authentication service
- **JWT Tokens**: Structure and validation of JSON Web Tokens
- **API Gateway Authorizers**: Request authorization mechanisms
- **OAuth 2.0 Flow**: Authentication and token exchange
- **Token Validation**: Signature verification and claims validation
- **Security Best Practices**: Token storage and transmission
- **Error Handling**: Authentication and authorization failures
- **Monitoring**: CloudWatch logs for security events

## Setup Instructions

### Prerequisites

- AWS account with API Gateway and Cognito permissions
- AWS CLI configured with appropriate credentials
- curl or Postman for API testing
- Understanding of REST APIs and authentication

### Step 1: Create Cognito User Pool

Create user pool for authentication:

```bash
./scripts/create-user-pool.sh
```

### Step 2: Configure App Client

Set up app client:

```bash
./scripts/configure-app-client.sh
```

### Step 3: Create Test User

Add user to pool:

```bash
./scripts/create-test-user.sh
```

### Step 4: Configure API Gateway Authorizer

Integrate Cognito with API Gateway:

```bash
./scripts/configure-authorizer.sh
```

### Step 5: Deploy API

Deploy API with authorization:

```bash
./scripts/deploy-api.sh
```

### Step 6: Test Authentication

Authenticate and get tokens:

```bash
./scripts/authenticate-user.sh
```

### Step 7: Test Authorized Requests

Make authenticated API calls:

```bash
./scripts/test-authorized-request.sh
```

### Step 8: Test Unauthorized Requests

Verify authorization enforcement:

```bash
./scripts/test-unauthorized-request.sh
```

## Scripts and Configurations

### Scripts

- **create-user-pool.sh** - Creates Cognito User Pool
- **configure-app-client.sh** - Sets up app client
- **create-test-user.sh** - Adds test user
- **configure-authorizer.sh** - Integrates authorizer
- **deploy-api.sh** - Deploys API Gateway
- **authenticate-user.sh** - Gets JWT tokens
- **test-authorized-request.sh** - Tests with valid token
- **test-unauthorized-request.sh** - Tests without token
- **cleanup.sh** - Removes all resources

### Configuration Files

- **user-pool-config.json** - User pool settings
- **app-client-config.json** - App client configuration
- **authorizer-config.json** - API Gateway authorizer
- **api-definition.json** - API Gateway configuration

## Metadata

- **Domain**: Security
- **Complexity Level**: Intermediate
- **Estimated Time**: 60 minutes
- **AWS Services**: API Gateway, Cognito, Lambda, IAM, CloudWatch
- **Key Concepts**: Authentication, authorization, JWT tokens, OAuth 2.0

## Real-World Application

- **SaaS authentication**: Every multi-tenant SaaS application needs JWT-based authentication — Cognito + API Gateway is the AWS-native pattern
- **Mobile app backends**: Mobile applications use Cognito User Pools for sign-up/sign-in flows with social identity federation (Google, Apple, Facebook)
- **API monetization**: API Gateway with Cognito authorizers enables usage plans and API keys for third-party developer access
- **Healthcare portals**: Patient-facing applications use Cognito for HIPAA-compliant authentication with MFA enforcement
