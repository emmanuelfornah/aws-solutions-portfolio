# Architecture: Securing API Gateway with Cognito Authorizer

## Architecture Diagram

┌─────────────────────────────────────────────────────────────────┐
│                         Client Application                       │
│                    (Web/Mobile/CLI/Postman)                      │
└────────────┬────────────────────────────────────┬────────────────┘
             │                                    │
             │ 1. Authenticate                    │ 3. API Request
             │    (username/password)             │    (with JWT token)
             │                                    │
             ▼                                    ▼
┌─────────────────────────────┐    ┌──────────────────────────────┐
│   Amazon Cognito User Pool  │    │    Amazon API Gateway        │
│                             │    │                              │
│  ┌─────────────────────┐   │    │  ┌────────────────────────┐ │
│  │   User Directory    │   │    │  │  Cognito Authorizer    │ │
│  │  - Users            │   │    │  │  - Validate JWT        │ │
│  │  - Passwords        │   │    │  │  - Check signature     │ │
│  │  - Attributes       │   │    │  │  - Verify claims       │ │
│  └─────────────────────┘   │    │  └────────────────────────┘ │
│                             │    │            │                 │
│  ┌─────────────────────┐   │    │            │ 4. Authorized   │
│  │   App Client        │   │    │            ▼                 │
│  │  - Client ID        │   │    │  ┌────────────────────────┐ │
│  │  - Auth flows       │   │    │  │   REST API Methods     │ │
│  └─────────────────────┘   │    │  │  - GET /items          │ │
│            │                │    │  │  - POST /items         │ │
│            │ 2. JWT Tokens  │    │  │  - PUT /items/{id}     │ │
│            └────────────────┼────┼──│  - DELETE /items/{id}  │ │
│                             │    │  └────────────────────────┘ │
└─────────────────────────────┘    │            │                 │
                                   │            │ 5. Invoke       │
                                   └────────────┼─────────────────┘
                                                │
                                                ▼
                                   ┌──────────────────────────────┐
                                   │       AWS Lambda             │
                                   │                              │
                                   │  ┌────────────────────────┐ │
                                   │  │  Backend Function      │ │
                                   │  │  - Business logic      │ │
                                   │  │  - Data processing     │ │
                                   │  │  - Response generation │ │
                                   │  └────────────────────────┘ │
                                   │            │                 │
                                   └────────────┼─────────────────┘
                                                │
                                                ▼
                                   ┌──────────────────────────────┐
                                   │    Amazon CloudWatch Logs    │
                                   │  - Authentication events     │
                                   │  - Authorization decisions   │
                                   │  - API access logs           │
                                   └──────────────────────────────┘

## Authentication Flow

### 1. User Authentication

Client → Cognito User Pool
├── Request: InitiateAuth
│   ├── Username: user@example.com
│   ├── Password: [REDACTED]
│   └── ClientId: [APP_CLIENT_ID]
└── Response: Authentication Result
    ├── IdToken: eyJraWQiOiJ... (JWT)
    ├── AccessToken: eyJraWQiOiJ... (JWT)
    ├── RefreshToken: eyJjdHkiOiJ... (JWT)
    └── ExpiresIn: 3600 seconds

### 2. JWT Token Structure

**ID Token (used for authorization)**:
```json
{
  "header": {
    "kid": "key-id",
    "alg": "RS256"
  },
  "payload": {
    "sub": "user-uuid",
    "aud": "app-client-id",
    "email_verified": true,
    "token_use": "id",
    "auth_time": 1234567890,
    "iss": "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_XXXXXXXXX",
    "cognito:username": "user@example.com",
    "exp": 1234571490,
    "iat": 1234567890,
    "email": "user@example.com"
  },
  "signature": "..."
}

### 3. API Request with Authorization

Client → API Gateway
├── Request Headers:
│   ├── Authorization: Bearer eyJraWQiOiJ...
│   ├── Content-Type: application/json
│   └── Accept: application/json
└── Request Body: { "data": "..." }

### 4. Token Validation Process

API Gateway Cognito Authorizer
├── 1. Extract JWT from Authorization header
├── 2. Decode JWT header and payload
├── 3. Verify token signature
│   ├── Download public keys from Cognito JWKS endpoint
│   ├── Validate signature using RS256 algorithm
│   └── Ensure token hasn't been tampered with
├── 4. Validate token claims
│   ├── Check 'iss' (issuer) matches User Pool
│   ├── Check 'aud' (audience) matches App Client ID
│   ├── Check 'token_use' is 'id' or 'access'
│   ├── Check 'exp' (expiration) is in future
│   └── Check 'iat' (issued at) is reasonable
└── 5. Authorization Decision
    ├── Valid: Allow request → Lambda
    └── Invalid: Return 401 Unauthorized

## Component Details

### Amazon Cognito User Pool

**Purpose**: Managed user directory and authentication service

**Configuration**:
- **User Pool Name**: `api-auth-user-pool`
- **Sign-in Options**: Email, username
- **Password Policy**: Minimum 8 characters, uppercase, lowercase, numbers
- **MFA**: Optional (can enable for enhanced security)
- **Account Recovery**: Email verification
- **User Attributes**: email, name, custom attributes

**App Client Settings**:
- **Client Name**: `api-gateway-client`
- **Auth Flows**: USER_PASSWORD_AUTH, REFRESH_TOKEN_AUTH
- **Token Expiration**: ID token (1 hour), Access token (1 hour), Refresh token (30 days)
- **Read/Write Attributes**: email, name

### API Gateway Cognito Authorizer

**Purpose**: Validates JWT tokens before allowing API access

**Configuration**:
- **Authorizer Type**: Cognito User Pool
- **Token Source**: Authorization header
- **Token Validation**: Automatic JWT validation
- **Authorization Caching**: 300 seconds (5 minutes)
- **Identity Source**: `method.request.header.Authorization`

**Validation Steps**:
1. Extract token from Authorization header
2. Verify token signature using Cognito public keys
3. Validate token claims (issuer, audience, expiration)
4. Cache authorization decision for performance
5. Pass user identity to Lambda via context

### API Gateway REST API

**Endpoints**:
GET    /items           - List all items (requires auth)
POST   /items           - Create item (requires auth)
GET    /items/{id}      - Get item details (requires auth)
PUT    /items/{id}      - Update item (requires auth)
DELETE /items/{id}      - Delete item (requires auth)
GET    /public/health   - Health check (no auth)

**Method Configuration**:
- **Authorization**: Cognito User Pool Authorizer
- **API Key Required**: No
- **Request Validation**: Enabled
- **CORS**: Enabled for web clients

### AWS Lambda Backend

**Purpose**: Business logic and data processing

**Integration**:
- **Integration Type**: Lambda Proxy
- **Timeout**: 30 seconds
- **Memory**: 256 MB

**Event Context**:
```json
{
  "requestContext": {
    "authorizer": {
      "claims": {
        "sub": "user-uuid",
        "email": "user@example.com",
        "cognito:username": "user@example.com"
      }
    }
  }
}

## Security Architecture

### Defense in Depth

Layer 1: Network Security
├── API Gateway in AWS managed network
├── HTTPS/TLS 1.2+ encryption
└── DDoS protection via AWS Shield

Layer 2: Authentication
├── Cognito User Pool authentication
├── Strong password policies
├── Optional MFA
└── Account lockout policies

Layer 3: Authorization
├── JWT token validation
├── Token signature verification
├── Claims validation
└── Token expiration enforcement

Layer 4: API Security
├── Request throttling
├── Rate limiting
├── Input validation
└── CORS policies

Layer 5: Application Security
├── Lambda execution role (least privilege)
├── CloudWatch logging
├── Error handling (no sensitive data leakage)
└── Audit trails

### Token Security

**Token Storage**:
- **Client-side**: Secure storage (keychain, secure storage)
- **Transmission**: HTTPS only
- **Never**: URL parameters, logs, client-side code

**Token Lifecycle**:
1. Issue (Cognito)
   ├── ID Token: 1 hour
   ├── Access Token: 1 hour
   └── Refresh Token: 30 days

2. Use (API Gateway)
   ├── Validate on each request
   └── Cache authorization (5 minutes)

3. Refresh (Client)
   ├── Use refresh token before expiration
   └── Get new ID and access tokens

4. Revoke (Admin)
   ├── Disable user in Cognito
   └── Tokens invalid immediately

## Request/Response Flow

### Successful Authenticated Request

1. Client Request
   POST /items
   Authorization: Bearer eyJraWQiOiJ...
   Content-Type: application/json
   
   {"name": "New Item", "description": "Item details"}

2. API Gateway Processing
   ├── Extract JWT from Authorization header
   ├── Invoke Cognito Authorizer
   ├── Validate token (signature + claims)
   ├── Check authorization cache
   └── Authorization: ALLOW

3. Lambda Invocation
   ├── Receive event with user context
   ├── Process business logic
   ├── Access user identity from claims
   └── Return response

4. Client Response
   HTTP 200 OK
   Content-Type: application/json
   
   {"id": "item-123", "name": "New Item", "status": "created"}

### Failed Unauthorized Request

1. Client Request
   POST /items
   (No Authorization header)
   Content-Type: application/json
   
   {"name": "New Item"}

2. API Gateway Processing
   ├── Check for Authorization header
   ├── Header missing
   └── Authorization: DENY

3. Client Response
   HTTP 401 Unauthorized
   Content-Type: application/json
   
   {"message": "Unauthorized"}

Note: Lambda is NOT invoked, saving costs

### Failed Invalid Token Request

1. Client Request
   POST /items
   Authorization: Bearer invalid-token-xyz
   Content-Type: application/json
   
   {"name": "New Item"}

2. API Gateway Processing
   ├── Extract JWT from Authorization header
   ├── Invoke Cognito Authorizer
   ├── Attempt to decode JWT
   ├── Signature validation fails
   └── Authorization: DENY

3. Client Response
   HTTP 401 Unauthorized
   Content-Type: application/json
   
   {"message": "Unauthorized"}

## Performance Considerations

### Authorization Caching

**Cache Configuration**:
- **TTL**: 300 seconds (5 minutes)
- **Cache Key**: Authorization header value
- **Benefits**: Reduced latency, lower Cognito API calls

**Cache Behavior**:
First Request (Cache Miss)
├── Validate token with Cognito: ~100-200ms
├── Cache authorization decision
└── Total latency: ~150-250ms

Subsequent Requests (Cache Hit)
├── Retrieve from cache: ~1-5ms
└── Total latency: ~10-20ms

### Optimization Strategies

1. **Enable Authorization Caching**: Reduce validation overhead
2. **Use Access Tokens**: Smaller payload than ID tokens
3. **Implement Token Refresh**: Avoid re-authentication
4. **Monitor CloudWatch Metrics**: Track authorization latency
5. **Right-size Lambda**: Adequate memory for fast execution

## Monitoring and Logging

### CloudWatch Logs

**API Gateway Logs**:
{
  "requestId": "request-uuid",
  "ip": "203.0.113.0",
  "requestTime": "01/Jan/2024:12:00:00 +0000",
  "httpMethod": "POST",
  "resourcePath": "/items",
  "status": 200,
  "protocol": "HTTP/1.1",
  "responseLength": 256,
  "authorizer": {
    "principalId": "user@example.com",
    "latency": 150
  }
}

**Cognito Logs**:
- Authentication attempts (success/failure)
- Token issuance
- User sign-ups and confirmations
- Password reset requests

### CloudWatch Metrics

**API Gateway Metrics**:
- `Count`: Total API requests
- `4XXError`: Client errors (including 401)
- `5XXError`: Server errors
- `Latency`: Request processing time
- `IntegrationLatency`: Backend latency

**Cognito Metrics**:
- `SignInSuccesses`: Successful authentications
- `SignInThrottles`: Throttled requests
- `TokenRefreshSuccesses`: Token refresh operations

## Best Practices

### Security Best Practices

✅ **Use HTTPS Only**: Encrypt all API traffic
✅ **Validate All Tokens**: Never trust client-provided data
✅ **Implement Token Expiration**: Short-lived tokens (1 hour)
✅ **Enable CloudWatch Logging**: Audit all authentication events
✅ **Use Strong Password Policies**: Enforce complexity requirements
✅ **Consider MFA**: Add second factor for sensitive operations
✅ **Rotate Secrets**: Regular rotation of app client secrets
✅ **Least Privilege IAM**: Minimal permissions for Lambda roles

### Performance Best Practices

✅ **Enable Authorization Caching**: Reduce validation latency
✅ **Use Appropriate Token Types**: ID tokens for user info, access tokens for authorization
✅ **Implement Token Refresh**: Avoid repeated authentication
✅ **Monitor Latency**: Track authorization overhead
✅ **Optimize Lambda Cold Starts**: Provisioned concurrency for critical APIs

### Operational Best Practices

✅ **Implement Health Checks**: Unauthenticated endpoint for monitoring
✅ **Set Up Alarms**: Alert on high 401 error rates
✅ **Document API**: Include authentication requirements
✅ **Test Error Scenarios**: Verify proper error handling
✅ **Plan for Token Expiration**: Client-side refresh logic

## Cost Considerations

### Pricing Components

**Amazon Cognito**:
- First 50,000 MAU (Monthly Active Users): Free
- Additional MAU: $0.0055 per MAU
- No charge for token validation

**API Gateway**:
- First 1 million requests: $3.50
- Authorization caching: Included
- Data transfer: Standard rates

**AWS Lambda**:
- First 1 million requests: Free
- Compute time: $0.00001667 per GB-second

### Cost Optimization

1. **Enable Authorization Caching**: Reduce Cognito API calls
2. **Use Refresh Tokens**: Minimize authentication requests
3. **Right-size Lambda**: Avoid over-provisioning
4. **Monitor Usage**: Track MAU and API requests
5. **Implement Rate Limiting**: Prevent abuse

## Troubleshooting

### Common Issues

**401 Unauthorized Error**:
- Check token expiration
- Verify Authorization header format: `Bearer <token>`
- Confirm User Pool ID in authorizer configuration
- Validate App Client ID matches token audience

**Token Validation Failure**:
- Ensure token is from correct User Pool
- Check token signature
- Verify token hasn't been modified
- Confirm token_use claim is correct

**CORS Errors**:
- Enable CORS on API Gateway
- Include Authorization in allowed headers
- Configure proper origin policies

## Real-World Use Cases

### Mobile Application Backend

- User authentication with Cognito
- Secure API access with JWT tokens
- Token refresh for seamless experience
- User profile management

### SaaS Application

- Multi-tenant authentication
- Role-based access control via custom claims
- API rate limiting per user
- Usage tracking and billing

### Microservices Architecture

- Centralized authentication service
- Token-based service-to-service communication
- Consistent authorization across services
- Audit logging for compliance

## Additional Resources

- [Amazon Cognito User Pools Documentation](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools.html)
- [API Gateway Authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html)
- [JWT.io - JWT Debugger](https://jwt.io/)
- [OAuth 2.0 Specification](https://oauth.net/2/)
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)

