# Architecture: OIDC Identity Provider for Web Identity Federation

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Client Application                            │
│                   (Web App / Mobile App / CLI)                       │
└────────────┬────────────────────────────────────┬────────────────────┘
             │                                    │
             │ 1. Authenticate                    │ 4. Access AWS Resources
             │    (OAuth 2.0 / OIDC)             │    (with temp credentials)
             │                                    │
             ▼                                    │
┌──────────────────────────────────┐             │
│   OIDC Identity Provider         │             │
│   (Auth0, Okta, Google, etc.)    │             │
│                                  │             │
│  ┌────────────────────────────┐ │             │
│  │  Authentication Service    │ │             │
│  │  - User credentials        │ │             │
│  │  - MFA verification        │ │             │
│  │  - Session management      │ │             │
│  └────────────────────────────┘ │             │
│              │                   │             │
│              │ 2. JWT Token      │             │
│              │    (ID Token)     │             │
│              ▼                   │             │
│  ┌────────────────────────────┐ │             │
│  │  Token Endpoint            │ │             │
│  │  - Issue JWT tokens        │ │             │
│  │  - Sign with private key   │ │             │
│  │  - Include user claims     │ │             │
│  └────────────────────────────┘ │             │
│              │                   │             │
└──────────────┼───────────────────┘             │
               │                                 │
               │ 3. AssumeRoleWithWebIdentity    │
               ▼                                 │
┌──────────────────────────────────────────────┐ │
│              AWS IAM & STS                    │ │
│                                               │ │
│  ┌─────────────────────────────────────────┐ │ │
│  │  OIDC Identity Provider                 │ │ │
│  │  - Provider URL                         │ │ │
│  │  - Thumbprint (SSL cert)                │ │ │
│  │  - Audience (client IDs)                │ │ │
│  └─────────────────────────────────────────┘ │ │
│              │                                 │ │
│              │ Validate JWT                    │ │
│              ▼                                 │ │
│  ┌─────────────────────────────────────────┐ │ │
│  │  Token Validation                       │ │ │
│  │  - Verify signature (JWKS)              │ │ │
│  │  - Check issuer (iss)                   │ │ │
│  │  - Check audience (aud)                 │ │ │
│  │  - Check expiration (exp)               │ │ │
│  │  - Check subject (sub)                  │ │ │
│  └─────────────────────────────────────────┘ │ │
│              │                                 │ │
│              │ Token Valid                     │ │
│              ▼                                 │ │
│  ┌─────────────────────────────────────────┐ │ │
│  │  IAM Role (Web Identity)                │ │ │
│  │                                          │ │ │
│  │  Trust Policy:                           │ │ │
│  │  {                                       │ │ │
│  │    "Effect": "Allow",                    │ │ │
│  │    "Principal": {                        │ │ │
│  │      "Federated": "arn:aws:iam::...     │ │ │
│  │         :oidc-provider/provider.com"    │ │ │
│  │    },                                    │ │ │
│  │    "Action": "sts:AssumeRoleWith...     │ │ │
│  │              WebIdentity",               │ │ │
│  │    "Condition": {                        │ │ │
│  │      "StringEquals": {                   │ │ │
│  │        "provider.com:aud": "client-id"  │ │ │
│  │      }                                   │ │ │
│  │    }                                     │ │ │
│  │  }                                       │ │ │
│  │                                          │ │ │
│  │  Permissions:                            │ │ │
│  │  - S3 read/write                         │ │ │
│  │  - DynamoDB access                       │ │ │
│  │  - CloudWatch logs                       │ │ │
│  └─────────────────────────────────────────┘ │ │
│              │                                 │ │
│              │ Generate Credentials            │ │
│              ▼                                 │ │
│  ┌─────────────────────────────────────────┐ │ │
│  │  AWS STS                                 │ │ │
│  │  - AccessKeyId                           │ │ │
│  │  - SecretAccessKey                       │ │ │
│  │  - SessionToken                          │ │ │
│  │  - Expiration (1-12 hours)               │ │ │
│  └─────────────────────────────────────────┘ │ │
│              │                                 │ │
└──────────────┼─────────────────────────────────┘ │
               │                                   │
               └───────────────────────────────────┘
                                   │
                                   ▼
               ┌─────────────────────────────────────┐
               │        AWS Resources                 │
               │                                      │
               │  ┌────────────────────────────────┐ │
               │  │  Amazon S3                     │ │
               │  │  - User-specific buckets       │ │
               │  │  - Temporary access            │ │
               │  └────────────────────────────────┘ │
               │                                      │
               │  ┌────────────────────────────────┐ │
               │  │  Amazon DynamoDB               │ │
               │  │  - User data tables            │ │
               │  │  - Fine-grained access         │ │
               │  └────────────────────────────────┘ │
               │                                      │
               │  ┌────────────────────────────────┐ │
               │  │  Amazon CloudWatch             │ │
               │  │  - Application logs            │ │
               │  │  - Metrics                     │ │
               │  └────────────────────────────────┘ │
               └─────────────────────────────────────┘
                                   │
                                   ▼
               ┌─────────────────────────────────────┐
               │      AWS CloudTrail                  │
               │  - AssumeRoleWithWebIdentity events │
               │  - Resource access logs              │
               │  - Security auditing                 │
               └─────────────────────────────────────┘
```

## Authentication Flow

### 1. User Authentication with OIDC Provider

```
User → OIDC Provider
├── Request: Authorization
│   ├── response_type: id_token
│   ├── client_id: [CLIENT_ID]
│   ├── redirect_uri: https://app.example.com/callback
│   └── scope: openid profile email
├── User Login
│   ├── Username/Email
│   ├── Password
│   └── MFA (optional)
└── Response: ID Token (JWT)
    └── Redirect: https://app.example.com/callback#id_token=eyJhbGc...
```

### 2. JWT Token Structure

**ID Token from OIDC Provider**:
```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT",
    "kid": "key-id-12345"
  },
  "payload": {
    "iss": "https://auth.provider.com",
    "sub": "auth0|5f8e9a1b2c3d4e5f6a7b8c9d",
    "aud": "client-id-abc123",
    "exp": 1234571490,
    "iat": 1234567890,
    "email": "user@example.com",
    "email_verified": true,
    "name": "John Doe",
    "picture": "https://provider.com/avatar.jpg"
  },
  "signature": "base64url-encoded-signature"
}
```

### 3. AssumeRoleWithWebIdentity Request

```bash
aws sts assume-role-with-web-identity \
  --role-arn arn:aws:iam::123456789012:role/WebIdentityRole \
  --role-session-name user-session-12345 \
  --web-identity-token eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9... \
  --duration-seconds 3600
```

**Request Flow**:
```
Client → AWS STS
├── RoleArn: arn:aws:iam::123456789012:role/WebIdentityRole
├── RoleSessionName: user-session-12345
├── WebIdentityToken: eyJhbGc... (JWT from OIDC provider)
├── DurationSeconds: 3600 (1 hour)
└── Policy: (optional) Additional restrictions
```

### 4. STS Response with Temporary Credentials

```json
{
  "Credentials": {
    "AccessKeyId": "ASIAXXXXXXXXXXX",
    "SecretAccessKey": "[REDACTED]",
    "SessionToken": "FwoGZXIvYXdzEBYaDH...",
    "Expiration": "2024-01-15T14:30:00Z"
  },
  "SubjectFromWebIdentityToken": "auth0|5f8e9a1b2c3d4e5f6a7b8c9d",
  "AssumedRoleUser": {
    "AssumedRoleId": "AROAXXXXXXXXX:user-session-12345",
    "Arn": "arn:aws:sts::123456789012:assumed-role/WebIdentityRole/user-session-12345"
  },
  "Provider": "auth.provider.com",
  "Audience": "client-id-abc123"
}
```

## Token Validation Process

### JWT Signature Verification

```
1. Retrieve JWKS (JSON Web Key Set)
   ├── URL: https://auth.provider.com/.well-known/jwks.json
   └── Keys: Public keys for signature verification

2. Extract Key ID from JWT Header
   ├── Header: { "kid": "key-id-12345", "alg": "RS256" }
   └── Find matching key in JWKS

3. Verify Signature
   ├── Algorithm: RS256 (RSA with SHA-256)
   ├── Public Key: From JWKS
   ├── Signature: From JWT
   └── Result: Valid / Invalid

4. Validate Claims
   ├── iss (Issuer): Must match OIDC provider URL
   ├── aud (Audience): Must match client ID
   ├── exp (Expiration): Must be in the future
   ├── iat (Issued At): Must be in the past
   └── sub (Subject): User identifier
```

### IAM Trust Policy Evaluation

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/auth.provider.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "auth.provider.com:aud": "client-id-abc123"
        },
        "StringLike": {
          "auth.provider.com:sub": "auth0|*"
        }
      }
    }
  ]
}
```

**Evaluation Steps**:
1. Verify JWT signature is valid
2. Check issuer matches OIDC provider URL
3. Check audience matches condition in trust policy
4. Check subject matches condition pattern
5. Verify token is not expired
6. Generate temporary credentials if all checks pass

## Security Architecture

### Defense in Depth

```
Layer 1: OIDC Provider Security
├── Strong authentication (MFA)
├── Secure token generation
├── Private key protection
└── Token expiration

Layer 2: Token Transmission
├── HTTPS only
├── No token in URLs
├── Secure storage
└── Token refresh

Layer 3: AWS IAM Validation
├── Signature verification
├── Claim validation
├── Trust policy conditions
└── Provider thumbprint check

Layer 4: Temporary Credentials
├── Short-lived (1-12 hours)
├── Least privilege permissions
├── Session-specific
└── Automatic expiration

Layer 5: Resource Access
├── IAM policy enforcement
├── Resource-based policies
├── Service control policies
└── CloudTrail logging
```

### Credential Lifecycle

```
┌─────────────────────────────────────────────────────────┐
│                  Credential Lifecycle                    │
└─────────────────────────────────────────────────────────┘

1. Authentication (t=0)
   └── User authenticates with OIDC provider
       └── Receives JWT token (valid 1 hour)

2. Token Exchange (t=0 to t=1h)
   └── App calls AssumeRoleWithWebIdentity
       └── Receives AWS credentials (valid 1-12 hours)

3. Resource Access (t=0 to t=expiration)
   └── App uses credentials to access AWS resources
       └── Credentials automatically expire

4. Token Refresh (t=50min)
   └── App refreshes JWT token before expiration
       └── Obtains new AWS credentials

5. Session End (t=expiration)
   └── Credentials expire automatically
       └── No cleanup required
```

## Integration Patterns

### Pattern 1: Mobile Application

```
Mobile App
├── User Login → OIDC Provider
├── Receive JWT Token
├── AssumeRoleWithWebIdentity → AWS STS
├── Receive Temporary Credentials
├── Direct Access to AWS Resources
│   ├── S3: Upload photos
│   ├── DynamoDB: Store user data
│   └── CloudWatch: Send logs
└── Token Refresh (before expiration)
```

**Benefits**:
- No backend server required
- User-specific permissions
- Secure credential management
- Scalable architecture

### Pattern 2: Web Application

```
Web App (Frontend)
├── User Login → OIDC Provider
├── Receive JWT Token
├── Send Token to Backend
└── Backend:
    ├── AssumeRoleWithWebIdentity
    ├── Cache Credentials
    ├── Access AWS Resources
    └── Return Data to Frontend
```

**Benefits**:
- Centralized credential management
- Backend validation
- Credential caching
- Additional security layer

### Pattern 3: Multi-Tenant SaaS

```
SaaS Application
├── Tenant A User → OIDC Provider A
│   └── Role: TenantA-UserRole
│       └── S3: s3://tenant-a-bucket/*
├── Tenant B User → OIDC Provider B
│   └── Role: TenantB-UserRole
│       └── S3: s3://tenant-b-bucket/*
└── Data Isolation by IAM Role
```

**Benefits**:
- Tenant isolation
- Separate identity providers
- Fine-grained permissions
- Compliance and auditing

## Performance Optimization

### Token Caching Strategy

```javascript
class TokenCache {
  constructor() {
    this.jwtToken = null;
    this.jwtExpiration = null;
    this.awsCredentials = null;
    this.awsExpiration = null;
  }

  async getAWSCredentials() {
    // Check if AWS credentials are still valid
    if (this.awsCredentials && Date.now() < this.awsExpiration - 300000) {
      return this.awsCredentials; // Return cached (5min buffer)
    }

    // Check if JWT token is still valid
    if (!this.jwtToken || Date.now() >= this.jwtExpiration - 60000) {
      this.jwtToken = await this.refreshJWTToken(); // Refresh (1min buffer)
    }

    // Get new AWS credentials
    this.awsCredentials = await this.assumeRoleWithWebIdentity(this.jwtToken);
    this.awsExpiration = this.awsCredentials.Expiration;

    return this.awsCredentials;
  }
}
```

### Performance Metrics

- **JWT Token Validation**: ~50-100ms (first time, then cached)
- **AssumeRoleWithWebIdentity**: ~200-500ms
- **Cached Credential Access**: <1ms
- **Token Refresh**: ~100-300ms
- **Overall Latency**: 200-600ms (first request), <1ms (cached)

## Monitoring and Auditing

### CloudTrail Events

```json
{
  "eventName": "AssumeRoleWithWebIdentity",
  "eventSource": "sts.amazonaws.com",
  "userIdentity": {
    "type": "WebIdentityUser",
    "principalId": "auth.provider.com:auth0|5f8e9a1b2c3d4e5f6a7b8c9d",
    "userName": "auth0|5f8e9a1b2c3d4e5f6a7b8c9d",
    "identityProvider": "auth.provider.com"
  },
  "requestParameters": {
    "roleArn": "arn:aws:iam::123456789012:role/WebIdentityRole",
    "roleSessionName": "user-session-12345",
    "durationSeconds": 3600
  },
  "responseElements": {
    "credentials": {
      "expiration": "2024-01-15T14:30:00Z"
    },
    "assumedRoleUser": {
      "arn": "arn:aws:sts::123456789012:assumed-role/WebIdentityRole/user-session-12345"
    }
  }
}
```

### Key Metrics to Monitor

- **Authentication Success Rate**: % of successful token validations
- **Token Expiration Events**: Frequency of expired token attempts
- **Credential Duration**: Average session length
- **Provider Availability**: OIDC provider uptime
- **Error Rates**: Failed AssumeRole attempts
- **Resource Access Patterns**: Usage by federated users

## Troubleshooting Guide

### Error: InvalidIdentityToken

**Symptoms**: AssumeRoleWithWebIdentity fails with InvalidIdentityToken

**Possible Causes**:
1. JWT signature verification failed
2. Token expired
3. Issuer doesn't match OIDC provider
4. Audience doesn't match client ID

**Resolution**:
```bash
# Decode JWT token
echo "eyJhbGc..." | base64 -d | jq .

# Check expiration
jq -r '.exp' <<< $(echo "eyJhbGc..." | base64 -d)

# Verify provider configuration
aws iam get-open-id-connect-provider \
  --open-id-connect-provider-arn arn:aws:iam::123456789012:oidc-provider/auth.provider.com
```

### Error: AccessDenied

**Symptoms**: AssumeRoleWithWebIdentity returns AccessDenied

**Possible Causes**:
1. Trust policy doesn't allow the OIDC provider
2. Audience condition doesn't match
3. Subject condition doesn't match
4. Provider thumbprint is incorrect

**Resolution**:
```bash
# Check role trust policy
aws iam get-role --role-name WebIdentityRole

# Verify token claims match conditions
jwt decode eyJhbGc...

# Update trust policy if needed
aws iam update-assume-role-policy \
  --role-name WebIdentityRole \
  --policy-document file://trust-policy.json
```

## Best Practices Summary

1. **Token Security**: Always use HTTPS, never log tokens
2. **Validation**: Verify all JWT claims (iss, aud, exp, sub)
3. **Least Privilege**: Grant minimal permissions in IAM role
4. **Session Duration**: Use shortest duration that meets requirements
5. **Caching**: Cache credentials to reduce STS calls
6. **Monitoring**: Enable CloudTrail for all federated access
7. **Provider Trust**: Only use reputable OIDC providers
8. **Thumbprint**: Keep provider thumbprint updated
9. **Conditions**: Use trust policy conditions for additional security
10. **Documentation**: Document provider configuration and dependencies
