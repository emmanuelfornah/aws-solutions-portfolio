# Zero Trust Architecture for Service-To-Service Workloads

## Overview

This project demonstrates implementing Zero Trust security principles for service-to-service communication in AWS. The implementation includes API Gateway with IAM authorization using SigV4 signing, API Gateway resource policies for fine-grained access control, VPC endpoint policies for private connectivity, security group tuning for network isolation, and comprehensive service-to-service authentication patterns that eliminate implicit trust.

## AWS Services Used

- **Amazon API Gateway** - API management with IAM authorization
- **AWS IAM** - Service roles and policies for authentication
- **Amazon VPC** - Network isolation and private connectivity
- **VPC Endpoints** - Private access to AWS services
- **AWS Lambda** - Microservice implementation
- **Amazon EC2** - Service workloads
- **AWS CloudWatch** - Monitoring and logging
- **AWS CloudTrail** - API activity auditing

## Key Technologies

- **Zero Trust Principles** - Never trust, always verify
- **SigV4 Signing** - AWS Signature Version 4 authentication
- **IAM Authorization** - Identity-based access control
- **Resource Policies** - Service-level access control
- **VPC Endpoints** - Private connectivity without internet
- **Security Groups** - Stateful network filtering
- **Network ACLs** - Stateless network filtering
- **Least Privilege** - Minimal permissions

## Architecture Overview

The architecture implements Zero Trust principles where no service implicitly trusts another. All service-to-service communication requires explicit authentication using IAM credentials and SigV4 signing. API Gateway validates IAM credentials before allowing requests to reach backend services. VPC endpoints provide private connectivity without internet exposure. Security groups enforce network-level isolation. Resource policies add an additional authorization layer at the service level.

See [architecture.md](./architecture.md) for detailed Zero Trust architecture and security controls.

## Objectives

- Implement Zero Trust principles for service communication
- Configure API Gateway with IAM authorization
- Set up SigV4 request signing for authentication
- Create API Gateway resource policies
- Deploy VPC endpoints for private connectivity
- Configure VPC endpoint policies
- Tune security groups for least privilege network access
- Implement service-to-service authentication patterns
- Monitor and audit service interactions
- Test authorization and access controls

## Key Learnings

- **Zero Trust Model**: Never trust, always verify approach
- **SigV4 Authentication**: AWS request signing for API calls
- **IAM Authorization**: Identity-based access control for APIs
- **Resource Policies**: Service-level access restrictions
- **Private Connectivity**: VPC endpoints for secure communication
- **Network Segmentation**: Security groups and NACLs
- **Defense in Depth**: Multiple security layers
- **Audit and Monitoring**: CloudTrail and CloudWatch integration

## Setup Instructions

### Prerequisites

- AWS account with VPC, API Gateway, and IAM permissions
- Understanding of Zero Trust security principles
- AWS CLI configured with appropriate credentials
- VPC with private subnets
- Understanding of SigV4 signing process

### Step 1: Create VPC Infrastructure

Set up VPC with private subnets:

```bash
./scripts/create-vpc-infrastructure.sh
```

### Step 2: Deploy API Gateway with IAM Authorization

Create API with IAM auth:

```bash
./scripts/deploy-api-gateway.sh
```

### Step 3: Configure Resource Policies

Set up API Gateway resource policy:

```bash
./scripts/configure-resource-policy.sh
```

### Step 4: Create VPC Endpoints

Deploy VPC endpoints for private access:

```bash
./scripts/create-vpc-endpoints.sh
```

### Step 5: Configure Security Groups

Set up network isolation:

```bash
./scripts/configure-security-groups.sh
```

### Step 6: Deploy Service Workloads

Deploy Lambda and EC2 services:

```bash
./scripts/deploy-services.sh
```

### Step 7: Test Service-to-Service Communication

Verify Zero Trust implementation:

```bash
./scripts/test-service-communication.sh
```

## Testing

### Test 1: Authenticated Request with SigV4

Test successful service-to-service call:

```bash
./scripts/test-authenticated-request.sh
```

Expected: 200 OK with response data

### Test 2: Unauthenticated Request

Test request without IAM credentials:

```bash
./scripts/test-unauthenticated-request.sh
```

Expected: 403 Forbidden - Missing Authentication Token

### Test 3: Unauthorized Service

Test request from service without permissions:

```bash
./scripts/test-unauthorized-service.sh
```

Expected: 403 Forbidden - User is not authorized

### Test 4: Resource Policy Enforcement

Test resource policy restrictions:

```bash
./scripts/test-resource-policy.sh
```

Expected: 403 Forbidden if source not in allowed list

### Test 5: VPC Endpoint Access

Test private connectivity through VPC endpoint:

```bash
./scripts/test-vpc-endpoint-access.sh
```

Expected: Successful access without internet gateway

### Test 6: Security Group Isolation

Test network-level access control:

```bash
./scripts/test-security-group-isolation.sh
```

Expected: Connection timeout or refused from unauthorized sources

## Key Concepts

### Zero Trust Principles

Core tenets of Zero Trust security:
- **Never Trust, Always Verify**: No implicit trust based on network location
- **Least Privilege Access**: Minimal permissions for each service
- **Assume Breach**: Design assuming attackers are already inside
- **Verify Explicitly**: Authenticate and authorize every request
- **Micro-Segmentation**: Isolate services and data
- **Continuous Monitoring**: Real-time visibility and analytics

### SigV4 Request Signing

AWS authentication mechanism:
- **Canonical Request**: Standardized request format
- **String to Sign**: Hashed canonical request with metadata
- **Signing Key**: Derived from secret access key
- **Signature**: HMAC-SHA256 of string to sign
- **Authorization Header**: Contains signature and credentials

### IAM Authorization for API Gateway

Identity-based access control:
- **IAM Credentials**: Access key and secret key
- **IAM Policies**: Define allowed API operations
- **Request Validation**: API Gateway validates IAM signature
- **Principal Identification**: Determine caller identity
- **Policy Evaluation**: Check if caller has permission

### Resource Policies

Service-level access control:
- **Principal-Based**: Allow/deny specific IAM principals
- **Source-Based**: Restrict by source IP or VPC endpoint
- **Condition-Based**: Additional context requirements
- **Explicit Deny**: Override other permissions
- **Cross-Account**: Control access from other accounts

### VPC Endpoints

Private connectivity to AWS services:
- **Interface Endpoints**: ENI in your VPC (powered by PrivateLink)
- **Gateway Endpoints**: Route table target (S3, DynamoDB)
- **Endpoint Policies**: Control access through endpoint
- **Private DNS**: Resolve service names to private IPs
- **No Internet Required**: Traffic stays on AWS network

## Security Architecture

### Defense in Depth Layers

```
Layer 1: Network (VPC, Security Groups, NACLs)
├── VPC isolation
├── Private subnets
├── Security group rules
└── Network ACLs

Layer 2: Connectivity (VPC Endpoints)
├── Private connectivity
├── No internet exposure
├── Endpoint policies
└── DNS resolution

Layer 3: Authentication (IAM, SigV4)
├── IAM credentials
├── SigV4 request signing
├── Signature validation
└── Credential rotation

Layer 4: Authorization (IAM Policies, Resource Policies)
├── IAM policy evaluation
├── Resource policy enforcement
├── Least privilege
└── Explicit deny

Layer 5: Monitoring (CloudTrail, CloudWatch)
├── API call logging
├── Access patterns
├── Anomaly detection
└── Alerting
```

### Service-to-Service Authentication Flow

```
Service A (Caller)
├── 1. Prepare API request
├── 2. Sign request with SigV4
│   ├── Access Key ID
│   ├── Secret Access Key
│   └── Generate signature
├── 3. Add Authorization header
└── 4. Send request to API Gateway

API Gateway
├── 5. Receive request
├── 6. Validate IAM signature
│   ├── Extract credentials
│   ├── Verify signature
│   └── Check expiration
├── 7. Evaluate IAM policies
│   ├── Caller's IAM policies
│   └── API Gateway resource policy
├── 8. If authorized, invoke backend
└── 9. Return response

Service B (Backend)
└── 10. Process request (already authenticated)
```

## Security Considerations

### Authentication

- Use IAM roles for services (no long-term credentials)
- Implement SigV4 signing for all API requests
- Rotate credentials regularly (automatic with IAM roles)
- Use temporary credentials from STS when possible
- Validate signatures on every request
- Monitor for authentication failures

### Authorization

- Implement least privilege IAM policies
- Use resource policies for additional control
- Combine identity-based and resource-based policies
- Use condition keys for context-based access
- Regular permission audits
- Explicit deny for sensitive operations

### Network Security

- Deploy services in private subnets
- Use VPC endpoints for AWS service access
- Configure security groups with minimal rules
- Implement network ACLs for subnet-level control
- No direct internet access for services
- Use NAT Gateway only when necessary

### Monitoring and Auditing

- Enable CloudTrail for all API calls
- Configure CloudWatch alarms for anomalies
- Log all authentication and authorization events
- Monitor for unusual access patterns
- Implement automated response to threats
- Regular security audits

## Troubleshooting

### Common Issues

**Issue**: 403 Forbidden - Missing Authentication Token
- **Cause**: Request not signed with SigV4
- **Solution**: Ensure IAM credentials are configured and request is signed

**Issue**: 403 Forbidden - User is not authorized
- **Cause**: IAM policy doesn't allow API Gateway invoke
- **Solution**: Add `execute-api:Invoke` permission to IAM policy

**Issue**: 403 Forbidden - Resource policy denies access
- **Cause**: Resource policy explicitly denies or doesn't allow principal
- **Solution**: Update resource policy to allow the calling service

**Issue**: Connection timeout to API Gateway
- **Cause**: Security group or NACL blocking traffic
- **Solution**: Update security group rules to allow HTTPS (443)

**Issue**: VPC endpoint not resolving
- **Cause**: Private DNS not enabled or DNS resolution issue
- **Solution**: Enable private DNS on VPC endpoint

**Issue**: Signature mismatch error
- **Cause**: Clock skew or incorrect signing process
- **Solution**: Sync system time and verify signing implementation

## Performance Considerations

- **SigV4 Signing Overhead**: ~1-5ms per request
- **API Gateway Latency**: ~10-50ms
- **VPC Endpoint Latency**: Minimal (<1ms vs internet)
- **IAM Policy Evaluation**: <1ms (cached)
- **Resource Policy Evaluation**: <1ms
- **Overall Impact**: 10-60ms per request

### Optimization Strategies

- Cache IAM credentials (refresh before expiration)
- Reuse HTTP connections
- Implement request batching where possible
- Use regional endpoints for lower latency
- Monitor and optimize API Gateway configuration

## Cost Optimization

- **API Gateway**: $3.50 per million requests
- **VPC Endpoints**: $0.01 per hour + $0.01 per GB processed
- **CloudTrail**: First trail free, $2 per 100,000 events
- **CloudWatch Logs**: $0.50 per GB ingested
- **Data Transfer**: Free within same AZ through VPC endpoint

### Cost Reduction Tips

- Use VPC endpoints to avoid NAT Gateway costs
- Implement request caching in API Gateway
- Optimize CloudWatch log retention
- Use CloudTrail insights selectively
- Monitor and right-size resources

## Real-World Applications

### Microservices Architecture

- Service mesh with Zero Trust
- API Gateway as service gateway
- Each service has unique IAM role
- No service-to-service implicit trust
- Centralized authentication and authorization

### Multi-Tier Applications

- Frontend → API Gateway → Backend services
- Each tier isolated in separate subnets
- VPC endpoints for AWS service access
- Security groups enforce tier separation
- All communication authenticated

### Multi-Account Environments

- Cross-account service access
- Resource policies for account restrictions
- IAM roles for cross-account access
- VPC peering or Transit Gateway
- Centralized logging and monitoring

## Best Practices

- ✅ Implement Zero Trust: Never trust, always verify
- ✅ Use IAM roles for services (no long-term keys)
- ✅ Sign all requests with SigV4
- ✅ Implement resource policies for additional security
- ✅ Use VPC endpoints for private connectivity
- ✅ Configure security groups with least privilege
- ✅ Enable CloudTrail for all API calls
- ✅ Monitor for authentication and authorization failures
- ✅ Regular security audits and permission reviews
- ✅ Implement automated incident response
- ✅ Use private subnets for all services
- ✅ Implement network segmentation
- ✅ Test security controls regularly
- ✅ Document security architecture
- ✅ Train teams on Zero Trust principles

## Additional Resources

- [AWS Zero Trust Architecture](https://aws.amazon.com/security/zero-trust/)
- [API Gateway IAM Authorization](https://docs.aws.amazon.com/apigateway/latest/developerguide/permissions.html)
- [SigV4 Signing Process](https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html)
- [VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
- [Zero Trust Whitepaper](https://docs.aws.amazon.com/whitepapers/latest/zero-trust-architectures/)

## Lab Duration

**Estimated Time**: 75 minutes

## Difficulty Level

**Complexity**: Advanced

