# Implementing an OpenID Connect Identity Provider for Enhanced Security and Identity Management

## Overview

This lab demonstrates implementing an OpenID Connect (OIDC) identity provider in AWS IAM to enable federated authentication for web applications. The implementation includes creating an OIDC identity provider, configuring IAM roles with web identity federation, generating and validating JWT tokens, and using AssumeRoleWithWebIdentity to obtain short-term AWS credentials for secure access to AWS resources.

## AWS Services Used

- **AWS IAM** - Identity and Access Management with OIDC provider
- **AWS STS** - Security Token Service for temporary credentials
- **Amazon S3** - Resource access with federated credentials
- **Amazon CloudWatch** - Authentication and access logging
- **AWS CloudTrail** - API activity auditing

## Key Technologies

- **OpenID Connect (OIDC)** - Identity layer on OAuth 2.0
- **JWT Tokens** - JSON Web Tokens for identity claims
- **Web Identity Federation** - Third-party identity provider integration
- **AssumeRoleWithWebIdentity** - STS operation for federated access
- **IAM Roles** - Trust policies for web identity
- **Token Validation** - JWT signature and claims verification

## Architecture Overview

The architecture implements federated authentication using an OIDC identity provider integrated with AWS IAM. Users authenticate with the OIDC provider to receive JWT tokens containing identity claims. Applications use these tokens to call STS AssumeRoleWithWebIdentity, receiving temporary AWS credentials (access key, secret key, session token) valid for 1-12 hours. These credentials provide secure, time-limited access to AWS resources without embedding long-term credentials in applications.

See [architecture.md](./architecture.md) for detailed federation flow and security architecture.

## Objectives

- Create and configure OIDC identity provider in IAM
- Set up IAM roles with web identity trust policies
- Configure role permissions for resource access
- Generate JWT tokens from OIDC provider
- Validate JWT token structure and claims
- Use AssumeRoleWithWebIdentity for temporary credentials
- Access AWS resources with federated credentials
- Implement token refresh and credential rotation
- Monitor federated access in CloudTrail

## Key Learnings

- **OIDC Protocol**: OpenID Connect authentication flow
- **Web Identity Federation**: Third-party identity integration
- **JWT Token Structure**: Claims, signatures, and validation
- **IAM Trust Policies**: Federated identity trust relationships
- **STS Operations**: Temporary credential generation
- **Credential Lifecycle**: Token expiration and renewal
- **Security Best Practices**: Federated authentication patterns
- **Audit Logging**: CloudTrail for federation events

## Setup Instructions

### Prerequisites

- AWS account with IAM and STS permissions
- OIDC-compliant identity provider (Auth0, Okta, Google, etc.)
- AWS CLI configured with appropriate credentials
- Understanding of OAuth 2.0 and OIDC protocols
- JWT debugging tools (jwt.io)

### Step 1: Configure OIDC Provider

Create OIDC identity provider in IAM:

```bash
./scripts/create-oidc-provider.sh
```

### Step 2: Create IAM Role for Web Identity

Set up role with trust policy:

```bash
./scripts/create-web-identity-role.sh
```

### Step 3: Configure Role Permissions

Attach policies for resource access:

```bash
./scripts/configure-role-permissions.sh
```

### Step 4: Generate JWT Token

Authenticate with OIDC provider:

```bash
./scripts/generate-jwt-token.sh
```

### Step 5: Assume Role with Web Identity

Exchange JWT for AWS credentials:

```bash
./scripts/assume-role-web-identity.sh
```

### Step 6: Test Resource Access

Access AWS resources with temporary credentials:

```bash
./scripts/test-resource-access.sh
```

## Testing

### Test 1: Valid JWT Token

Test successful authentication:

```bash
./scripts/test-valid-token.sh
```

Expected: Temporary credentials returned with 1-hour expiration

### Test 2: Expired Token

Test token expiration handling:

```bash
./scripts/test-expired-token.sh
```

Expected: AccessDenied error with token expiration message

### Test 3: Invalid Signature

Test token validation:

```bash
./scripts/test-invalid-signature.sh
```

Expected: InvalidIdentityToken error

### Test 4: Resource Access

Test S3 access with federated credentials:

```bash
./scripts/test-s3-access.sh
```

Expected: Successful S3 operations with temporary credentials

## Key Concepts

### OpenID Connect (OIDC)

Identity layer built on OAuth 2.0 protocol:
- **Authentication**: Verify user identity
- **Authorization**: Grant access to resources
- **ID Token**: JWT containing user claims
- **UserInfo Endpoint**: Additional user information
- **Discovery**: Provider metadata endpoint

### Web Identity Federation

Federated access to AWS resources:
- **Trust Relationship**: IAM role trusts OIDC provider
- **Token Exchange**: JWT token for AWS credentials
- **Temporary Credentials**: Time-limited access
- **No Long-Term Keys**: Enhanced security
- **Centralized Identity**: Single source of truth

### JWT Token Structure

Three-part token (header.payload.signature):
- **Header**: Algorithm and token type
- **Payload**: Claims about the user
- **Signature**: Cryptographic verification
- **Validation**: Signature, expiration, audience

### AssumeRoleWithWebIdentity

STS operation for federated access:
- **Input**: JWT token, role ARN, session name
- **Output**: Temporary credentials
- **Duration**: 1-12 hours (default 1 hour)
- **Permissions**: Based on role policies
- **Session Tags**: Additional context

## Security Considerations

### Token Security

- Store tokens securely (never in code or logs)
- Use HTTPS for all token transmission
- Validate token signature and claims
- Check token expiration before use
- Implement token refresh logic
- Revoke tokens when no longer needed

### Role Configuration

- Use least privilege for role permissions
- Restrict role assumption with conditions
- Limit session duration appropriately
- Use session tags for additional context
- Monitor role usage with CloudTrail
- Regular permission audits

### Provider Configuration

- Verify provider thumbprint
- Use trusted OIDC providers only
- Configure audience restrictions
- Implement provider rotation plan
- Monitor provider availability
- Document provider dependencies

## Troubleshooting

### Common Issues

**Issue**: InvalidIdentityToken error
- **Cause**: Token signature validation failed
- **Solution**: Verify provider thumbprint and token signature

**Issue**: AccessDenied when assuming role
- **Cause**: Trust policy doesn't match token claims
- **Solution**: Check audience, issuer, and subject claims

**Issue**: Credentials expired during operation
- **Cause**: Session duration too short
- **Solution**: Increase duration or implement refresh logic

**Issue**: Provider not found
- **Cause**: OIDC provider not configured in IAM
- **Solution**: Create provider with correct URL and thumbprint

## Performance Considerations

- **Token Caching**: Cache valid tokens to reduce provider calls
- **Credential Caching**: Reuse credentials until expiration
- **Session Duration**: Balance security and performance
- **Parallel Requests**: Handle concurrent credential requests
- **Provider Latency**: Account for OIDC provider response time

## Cost Optimization

- **STS Calls**: No charge for AssumeRoleWithWebIdentity
- **CloudTrail**: Standard logging costs apply
- **Provider Costs**: Check OIDC provider pricing
- **Token Caching**: Reduce provider API calls
- **Session Duration**: Longer sessions reduce STS calls

## Real-World Applications

### Mobile Applications

- Users authenticate with social identity providers
- App exchanges tokens for AWS credentials
- Direct access to S3, DynamoDB, etc.
- No backend server for credential management

### Web Applications

- Single sign-on with corporate identity provider
- Federated access to AWS resources
- User-specific permissions and data isolation
- Centralized user management

### Multi-Cloud Environments

- Consistent identity across cloud providers
- OIDC as common authentication protocol
- Federated access to AWS from other clouds
- Simplified credential management

## Best Practices

- ✅ Use OIDC providers with strong security posture
- ✅ Validate all JWT token claims (iss, aud, exp, sub)
- ✅ Implement least privilege for IAM roles
- ✅ Use condition keys in trust policies for additional security
- ✅ Set appropriate session durations (1-12 hours)
- ✅ Implement token refresh before expiration
- ✅ Monitor federated access with CloudTrail
- ✅ Use session tags for access attribution
- ✅ Regularly audit role permissions
- ✅ Document OIDC provider configuration

## Additional Resources

- [AWS IAM OIDC Identity Providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [AssumeRoleWithWebIdentity API](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html)
- [OpenID Connect Specification](https://openid.net/connect/)
- [JWT Token Best Practices](https://tools.ietf.org/html/rfc8725)

## Lab Duration

**Estimated Time**: 45-60 minutes

## Difficulty Level

**Complexity**: Intermediate to Advanced

## Tags

`IAM` `OIDC` `Web Identity Federation` `STS` `JWT` `Authentication` `Security` `Federated Access`
