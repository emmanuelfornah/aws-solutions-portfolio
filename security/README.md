# Security

## Overview

This category showcases comprehensive hands-on experience with AWS security services including Amazon Cognito, AWS WAF, AWS KMS, AWS Secrets Manager, Amazon Inspector, IAM, and advanced security architectures. The labs demonstrate expertise in authentication and authorization, web application protection, encryption and key management, secure secret storage, vulnerability scanning, identity federation, Zero Trust architecture, incident response automation, and implementing defense-in-depth security strategies across AWS environments.

## Key Skills Demonstrated

- **Authentication & Authorization**: Cognito User Pools, JWT tokens, OAuth 2.0, OIDC federation
- **Web Application Security**: WAF rules, OWASP Top 10 protection, DDoS mitigation
- **Encryption**: KMS customer-managed keys, envelope encryption, encryption at rest/transit
- **Secret Management**: Secrets Manager integration, automatic rotation, secure access patterns
- **Vulnerability Scanning**: Amazon Inspector, CVE detection, package vulnerability remediation
- **Identity Federation**: OIDC providers, web identity federation, SigV4 signing
- **Zero Trust Architecture**: Service-to-service authentication, least privilege, micro-segmentation
- **Incident Response**: Automated detection, forensic analysis, evidence preservation
- **Access Control**: IAM roles and policies, resource policies, VPC endpoint policies
- **Security Automation**: EventBridge rules, Lambda-based response, automated remediation
- **Security Monitoring**: CloudTrail logging, CloudWatch metrics, GuardDuty integration
- **Compliance**: Audit trails, encryption standards, incident documentation
- **Threat Protection**: Rate limiting, geo-blocking, SQL injection prevention, isolation
- **DevSecOps**: Continuous vulnerability scanning, automated security testing

## AWS Services Covered

- **Amazon Cognito** - User authentication and authorization
- **AWS WAF** - Web application firewall
- **AWS KMS** - Key management and encryption
- **AWS Secrets Manager** - Secure secret storage and rotation
- **Amazon Inspector** - Automated vulnerability scanning
- **AWS IAM** - Identity and access management, OIDC providers
- **AWS STS** - Security Token Service, temporary credentials
- **AWS Lambda** - Serverless compute with secure data access and incident response
- **Amazon API Gateway** - API management with IAM authorization
- **Application Load Balancer** - Load balancing with WAF integration
- **AWS CloudTrail** - API activity logging and auditing
- **Amazon CloudWatch** - Security monitoring and alerting
- **Amazon EventBridge** - Event-driven security automation
- **Amazon EC2** - Instance isolation and forensics
- **Amazon EBS** - Snapshot creation for evidence preservation
- **Amazon VPC** - Network isolation, VPC endpoints, security groups
- **Amazon GuardDuty** - Threat detection
- **Amazon SNS** - Security notifications
- **AWS Systems Manager** - Instance management and automation

## Labs in This Category

### 1. Securing Amazon API Gateway Using an Amazon Cognito Authorizer

**Complexity**: Intermediate | **Duration**: 60 minutes

Comprehensive API security implementation using Cognito User Pools for authentication and API Gateway authorizers for request validation. Includes JWT token generation, token-based access control, authorization caching, and CloudWatch logging for security events.

**Key Technologies**: Cognito User Pools, API Gateway, JWT, OAuth 2.0, Lambda

**Learning Focus**:
- Cognito User Pool configuration and app client setup
- JWT token structure and validation
- API Gateway Cognito authorizer integration
- Token-based authentication flow
- Authorization caching for performance
- Security monitoring and logging

[View Lab →](./api-gateway-cognito-authorizer/)

---

### 2. Securing a Web Application Using AWS WAF

**Complexity**: Intermediate | **Duration**: 45 minutes

Multi-layer web application protection using AWS WAF with managed rule groups, rate-based rules, and custom filtering. Includes OWASP Top 10 protection, DDoS mitigation, geo-blocking, and comprehensive logging for security analysis.

**Key Technologies**: AWS WAF, Web ACL, Managed Rules, ALB, CloudWatch

**Learning Focus**:
- WAF Web ACL creation and configuration
- AWS Managed Rules for OWASP protection
- Rate-based rules for DDoS mitigation
- Geographic restrictions and IP filtering
- Custom rules for application-specific threats
- WAF logging and monitoring
- Testing and validating rule effectiveness

[View Lab →](./waf-web-application-protection/)

---

### 3. Using AWS KMS to Encrypt Secrets Manager Secrets

**Complexity**: Intermediate | **Duration**: 40 minutes

Encryption and key management implementation using KMS customer-managed keys with Secrets Manager. Includes envelope encryption, key policies, automatic secret rotation, and CloudTrail auditing for compliance.

**Key Technologies**: AWS KMS, Secrets Manager, Envelope Encryption, IAM

**Learning Focus**:
- Customer-managed KMS key creation
- Key policies and access control
- Envelope encryption architecture
- Secrets Manager integration with KMS
- Automatic secret rotation configuration
- Key usage monitoring with CloudTrail
- Compliance and audit logging

[View Lab →](./kms-secrets-manager-encryption/)

---

### 4. Securing Data Accessed by Lambda Functions

**Complexity**: Intermediate | **Duration**: 60 minutes

Secure data access patterns for Lambda functions using Secrets Manager integration with secret caching, IAM execution roles, and error handling. Demonstrates performance optimization through caching while maintaining security best practices.

**Key Technologies**: Lambda, Secrets Manager, IAM Roles, Secret Caching

**Learning Focus**:
- Lambda execution role configuration
- Programmatic secret retrieval with AWS SDK
- Secret caching for performance optimization
- Handling secret rotation in Lambda
- VPC integration for private access
- Error handling and retry logic
- CloudWatch monitoring and X-Ray tracing

[View Lab →](./lambda-secrets-manager-integration/)

---

### 5. Implementing an OpenID Connect Identity Provider for Enhanced Security

**Complexity**: Intermediate to Advanced | **Duration**: 45-60 minutes

Implementation of OIDC identity provider in AWS IAM for federated authentication. Includes creating OIDC providers, configuring IAM roles with web identity trust policies, JWT token validation, and using AssumeRoleWithWebIdentity for temporary AWS credentials without long-term keys.

**Key Technologies**: OIDC, IAM, STS, JWT, Web Identity Federation

**Learning Focus**:
- OIDC identity provider configuration in IAM
- IAM roles with web identity trust policies
- JWT token generation and validation
- AssumeRoleWithWebIdentity for temporary credentials
- Token-based AWS resource access
- Federated authentication patterns
- Security best practices for identity federation

[View Lab →](./oidc-identity-provider/)

---

### 6. Zero Trust Architecture for Service-To-Service Workloads

**Complexity**: Advanced | **Duration**: 75 minutes

Implementation of Zero Trust security principles for service-to-service communication. Includes API Gateway with IAM authorization using SigV4 signing, API Gateway resource policies, VPC endpoint policies for private connectivity, security group tuning, and comprehensive service-to-service authentication that eliminates implicit trust.

**Key Technologies**: Zero Trust, API Gateway, IAM, SigV4, VPC Endpoints, Security Groups

**Learning Focus**:
- Zero Trust principles (never trust, always verify)
- API Gateway IAM authorization configuration
- SigV4 request signing for authentication
- API Gateway resource policies
- VPC endpoints for private connectivity
- VPC endpoint policies
- Security group micro-segmentation
- Service-to-service authentication patterns
- Defense in depth architecture

[View Lab →](./zero-trust-service-architecture/)

---

### 7. Responding to Incidents in an AWS Environment

**Complexity**: Advanced | **Duration**: 75 minutes

Comprehensive incident response automation using event-driven architecture. Includes capturing instance metadata for forensics, creating EBS snapshots for evidence preservation, analyzing CloudWatch logs, isolating compromised instances with security groups, automating response with EventBridge, and deploying Lambda functions for automated threat remediation.

**Key Technologies**: EventBridge, Lambda, EC2, EBS, CloudWatch, CloudTrail, GuardDuty, SNS

**Learning Focus**:
- Incident response lifecycle and procedures
- Instance metadata capture for forensics
- EBS snapshot creation for evidence preservation
- CloudWatch Logs Insights for security analysis
- Automated instance isolation with security groups
- EventBridge rules for security event detection
- Lambda-based automated incident response
- SNS notification workflows
- Digital forensics and chain of custody
- Incident documentation and compliance

[View Lab →](./incident-response-automation/)

---

### 8. Using Amazon Inspector for Vulnerability Scanning

**Complexity**: Intermediate | **Duration**: 75 minutes

Automated vulnerability scanning using Amazon Inspector for EC2 instances and Lambda functions. Includes configuring Inspector for multiple scan types, interpreting CVE findings, remediating package vulnerabilities, and managing findings with suppression rules. Demonstrates hybrid scanning mode combining agent-based (SSM) and agentless (EBS snapshot) methods for comprehensive coverage.

**Key Technologies**: Amazon Inspector, Lambda, EC2, SSM, Security Groups, CVE Management

**Learning Focus**:
- Inspector activation and configuration
- Lambda standard and code scanning
- EC2 hybrid scanning (agent-based + agentless)
- CVE analysis and interpretation
- Package vulnerability remediation
- Suppression rules for accepted risks
- Finding lifecycle management
- Network reachability detection
- DevSecOps integration

[View Lab →](./inspector-vulnerability-scanning/)

---

## Lab Categories

### Authentication & Authorization (Labs 1, 5)
- **Cognito User Pools**: User directory and JWT-based authentication
- **OIDC Federation**: Third-party identity provider integration
- **API Gateway Authorizers**: Request validation and authorization
- **Web Identity Federation**: Temporary credentials without long-term keys
- **Token Management**: JWT generation, validation, and refresh

### Web Application Security (Lab 2)
- **AWS WAF**: Multi-layer web application protection
- **OWASP Top 10**: Protection against common vulnerabilities
- **DDoS Mitigation**: Rate-based rules and IP reputation
- **Geo-Blocking**: Country-based access control
- **Custom Rules**: Application-specific threat protection

### Encryption & Key Management (Lab 3)
- **KMS**: Customer-managed keys and key policies
- **Envelope Encryption**: Performance-optimized encryption
- **Key Rotation**: Automatic annual rotation
- **Compliance**: FIPS 140-2, encryption standards
- **Audit Logging**: CloudTrail for key usage

### Secret Management (Lab 4)
- **Secrets Manager**: Encrypted secret storage
- **Automatic Rotation**: Lambda-based rotation functions
- **Secret Caching**: Performance optimization
- **Access Control**: IAM policies and resource policies
- **Version Management**: Secret versioning and staging

### Zero Trust & Service Security (Lab 6)
- **Zero Trust Principles**: Never trust, always verify
- **Service Authentication**: SigV4 signing for all requests
- **Micro-Segmentation**: Network and identity isolation
- **Private Connectivity**: VPC endpoints without internet
- **Resource Policies**: Multi-layer authorization

### Incident Response & Forensics (Lab 7)
- **Automated Detection**: EventBridge and GuardDuty integration
- **Automated Response**: Lambda-based remediation
- **Digital Forensics**: Evidence collection and preservation
- **Instance Isolation**: Network-level containment
- **Compliance**: Audit trails and documentation

### Vulnerability Management (Lab 8)
- **Amazon Inspector**: Automated vulnerability scanning
- **CVE Detection**: Package and code vulnerability identification
- **Hybrid Scanning**: Agent-based and agentless methods
- **Remediation**: Package updates and security patching
- **Suppression Rules**: Risk acceptance and false positive management
- **DevSecOps**: Continuous security scanning integration

## Technical Competencies

### Authentication & Authorization

- **User Management**: Cognito User Pools, user directories, password policies
- **Token-Based Auth**: JWT tokens, OAuth 2.0, OIDC, token validation
- **API Authorization**: API Gateway authorizers, IAM authorization, request validation
- **Session Management**: Token expiration, refresh tokens, revocation
- **MFA**: Multi-factor authentication configuration
- **Identity Federation**: SAML, OpenID Connect, web identity federation
- **Temporary Credentials**: STS, AssumeRoleWithWebIdentity, short-lived access

### Web Application Security

- **WAF Configuration**: Web ACLs, rule groups, rule priorities
- **OWASP Protection**: SQL injection, XSS, CSRF prevention
- **DDoS Mitigation**: Rate limiting, IP reputation lists
- **Geo-Blocking**: Country-based access control
- **Custom Rules**: Application-specific threat protection
- **Logging**: Security event logging and analysis

### Encryption & Key Management

- **KMS Keys**: Customer-managed keys, AWS managed keys
- **Envelope Encryption**: Data key encryption model
- **Key Policies**: Resource-based access control
- **Key Rotation**: Automatic annual rotation
- **Encryption Standards**: AES-256, RSA-2048
- **Compliance**: FIPS 140-2, encryption at rest/transit

### Secret Management

- **Secret Storage**: Encrypted secret storage in Secrets Manager
- **Automatic Rotation**: Lambda-based rotation functions
- **Secret Retrieval**: SDK integration, caching strategies
- **Version Management**: Secret versioning, staging labels
- **Access Control**: IAM policies, resource policies
- **Audit Logging**: CloudTrail integration

### Zero Trust Architecture

- **Never Trust, Always Verify**: Explicit authentication for all requests
- **Least Privilege**: Minimal permissions for each service
- **Micro-Segmentation**: Network and identity isolation
- **SigV4 Signing**: AWS request signing for authentication
- **Resource Policies**: Service-level access control
- **VPC Endpoints**: Private connectivity without internet
- **Defense in Depth**: Multiple security layers

### Incident Response

- **Detection**: GuardDuty, CloudTrail, CloudWatch alarms
- **Containment**: Instance isolation, security group replacement
- **Forensics**: Metadata capture, EBS snapshots, log analysis
- **Automation**: EventBridge rules, Lambda functions
- **Evidence Preservation**: Chain of custody, snapshot management
- **Notification**: SNS topics, automated alerting
- **Documentation**: Incident tracking, compliance reporting

### Access Control

- **IAM Roles**: Execution roles, service roles, cross-account access
- **IAM Policies**: Identity-based, resource-based policies
- **Least Privilege**: Minimal permission sets
- **Policy Conditions**: Context-based access control
- **Service Control Policies**: Organization-level controls
- **Permission Boundaries**: Maximum permission limits
- **OIDC Providers**: Federated identity integration

### Security Monitoring

- **CloudTrail**: API activity logging, compliance auditing
- **CloudWatch**: Metrics, alarms, log analysis, Logs Insights
- **X-Ray**: Distributed tracing, performance analysis
- **GuardDuty**: Threat detection, anomaly detection
- **EventBridge**: Event-driven automation
- **Security Hub**: Centralized security findings (conceptual)
- **Config**: Resource compliance monitoring (conceptual)

## Architecture Patterns

### API Security Pattern

```
Client Application
├── Authenticate with Cognito/OIDC
│   ├── Username/Password or OAuth
│   └── Receive JWT tokens
├── API Request with JWT
│   ├── Authorization: Bearer <token>
│   └── API Gateway validates token
└── Authorized Access
    └── Lambda backend execution
```

**Benefits**: Centralized authentication, token-based authorization, scalable security

### Zero Trust Service Pattern

```
Service A
├── Sign request with SigV4 (IAM credentials)
├── Send through VPC endpoint (private)
└── API Gateway
    ├── Validate IAM signature
    ├── Check identity-based policy
    ├── Check resource policy
    ├── Check VPC endpoint policy
    └── If all pass → Invoke Service B
```

**Benefits**: No implicit trust, explicit authentication, defense in depth

### Incident Response Pattern

```
Security Event (GuardDuty/CloudTrail)
├── EventBridge detects pattern
├── Trigger Lambda function
│   ├── Capture metadata
│   ├── Create snapshots
│   ├── Isolate instance
│   └── Send notification
└── Security team investigates
```

**Benefits**: Automated response, reduced MTTR, evidence preservation

### Web Application Protection Pattern

```
Internet Traffic
├── AWS WAF (Web ACL)
│   ├── Rate-based rules (DDoS)
│   ├── Geo-blocking rules
│   ├── AWS Managed Rules (OWASP)
│   └── Custom rules
├── Application Load Balancer
│   └── Target groups
└── Application Servers
    └── Protected resources
```

**Benefits**: Multi-layer defense, managed rule updates, comprehensive logging

### Encryption Pattern

```
Application
├── Request secret from Secrets Manager
├── Secrets Manager retrieves encrypted secret
├── KMS decrypts data key
├── Secrets Manager decrypts secret
└── Application receives plaintext secret
    └── Uses secret securely
```

**Benefits**: Envelope encryption, centralized key management, audit trails

### Secure Lambda Pattern

```
Lambda Function
├── IAM Execution Role
│   ├── Secrets Manager permissions
│   └── KMS decrypt permissions
├── Retrieve secret (with caching)
│   ├── Cache hit: <1ms
│   └── Cache miss: ~100ms
└── Use secret securely
    └── Connect to database/API
```

**Benefits**: Performance optimization, secure access, automatic rotation handling

## Best Practices Demonstrated

### Authentication & Authorization

- ✅ Strong password policies with complexity requirements
- ✅ JWT token validation with signature verification
- ✅ Token expiration and refresh mechanisms
- ✅ Authorization caching for performance
- ✅ MFA for sensitive operations
- ✅ Audit logging for authentication events
- ✅ OIDC federation for centralized identity
- ✅ Temporary credentials instead of long-term keys

### Web Application Security

- ✅ Defense in depth with multiple protection layers
- ✅ AWS Managed Rules for OWASP Top 10
- ✅ Rate limiting to prevent DDoS and brute-force
- ✅ Geo-blocking for compliance and risk reduction
- ✅ Custom rules for application-specific threats
- ✅ Comprehensive logging and monitoring

### Encryption & Key Management

- ✅ Customer-managed keys for control and compliance
- ✅ Envelope encryption for performance
- ✅ Automatic key rotation (annual)
- ✅ Key policies for fine-grained access control
- ✅ Encryption at rest and in transit
- ✅ CloudTrail logging for key usage

### Secret Management

- ✅ No hardcoded secrets in code or configuration
- ✅ Automatic secret rotation
- ✅ Secret caching for performance
- ✅ Least privilege access to secrets
- ✅ Version management for rollback
- ✅ Audit logging for secret access

### Zero Trust Architecture

- ✅ Never trust, always verify principle
- ✅ Explicit authentication for all requests
- ✅ Least privilege IAM policies
- ✅ Micro-segmentation with security groups
- ✅ Private connectivity with VPC endpoints
- ✅ Resource policies for additional security
- ✅ SigV4 signing for all API calls
- ✅ Regular permission audits

### Incident Response

- ✅ Automated detection and response
- ✅ Immediate instance isolation
- ✅ Forensic snapshot creation
- ✅ Metadata and evidence preservation
- ✅ Comprehensive audit trails
- ✅ Automated notification workflows
- ✅ Regular testing of response procedures
- ✅ Post-incident reviews and improvements

### Access Control

- ✅ IAM roles instead of long-term credentials
- ✅ Least privilege principle
- ✅ Resource-based policies for service access
- ✅ Policy conditions for context-based control
- ✅ Regular permission audits
- ✅ Separation of duties

### Monitoring & Compliance

- ✅ CloudTrail enabled for all regions
- ✅ CloudWatch alarms for security events
- ✅ Log retention for compliance requirements
- ✅ Regular security audits
- ✅ Incident response procedures
- ✅ Documentation and runbooks
- ✅ Automated security responses

## Real-World Applications

### SaaS Application

- **Cognito/OIDC**: Multi-tenant user authentication
- **API Gateway**: Secure API access with JWT/IAM
- **WAF**: Protection against web attacks
- **Secrets Manager**: Database credentials per tenant
- **KMS**: Per-tenant encryption keys
- **Zero Trust**: Service-to-service authentication
- **Incident Response**: Automated threat detection and response

### E-Commerce Platform

- **Cognito**: Customer authentication and profiles
- **WAF**: Payment page protection, bot mitigation
- **Secrets Manager**: Payment gateway credentials
- **Lambda**: Secure order processing
- **CloudTrail**: PCI DSS compliance auditing
- **Incident Response**: Fraud detection and automated response

### Financial Services

- **OIDC**: Customer and employee authentication
- **WAF**: Advanced threat protection
- **KMS**: Encryption for sensitive financial data
- **Secrets Manager**: API keys and credentials
- **Zero Trust**: Service-to-service security
- **CloudTrail**: Regulatory compliance logging
- **Incident Response**: Breach detection and containment

### Healthcare Application

- **Cognito**: Patient and provider authentication
- **WAF**: HIPAA-compliant web protection
- **KMS**: PHI encryption with customer-managed keys
- **Secrets Manager**: EHR system credentials
- **Audit Logging**: HIPAA compliance trails
- **Incident Response**: Breach notification procedures

## Certification Alignment

### AWS Certified Solutions Architect - Associate

- ✅ API Gateway with Cognito authorizers
- ✅ WAF configuration and rule management
- ✅ KMS encryption and key policies
- ✅ Secrets Manager integration
- ✅ IAM roles and policies
- ✅ VPC security (security groups, VPC endpoints)
- ✅ Security best practices

### AWS Certified Developer - Associate

- ✅ Cognito SDK integration
- ✅ Lambda with Secrets Manager
- ✅ Secret caching strategies
- ✅ Error handling and retry logic
- ✅ CloudWatch logging
- ✅ Secure application development
- ✅ SigV4 request signing

### AWS Certified Security - Specialty

- ✅ Advanced authentication mechanisms (Cognito, OIDC)
- ✅ WAF rule optimization
- ✅ KMS key management strategies
- ✅ Encryption best practices
- ✅ Zero Trust architecture implementation
- ✅ Incident response automation
- ✅ Forensic analysis procedures
- ✅ Compliance and auditing
- ✅ Threat detection and mitigation
- ✅ Identity federation patterns
- ✅ Service-to-service security

## Key Metrics and Achievements

- **8 Security Labs**: Comprehensive coverage of AWS security services and architectures
- **Authentication**: JWT-based API authorization with Cognito and OIDC federation
- **Web Protection**: Multi-layer WAF with OWASP Top 10 coverage
- **Encryption**: Customer-managed keys with envelope encryption
- **Secret Management**: Automatic rotation with secure access patterns
- **Vulnerability Scanning**: Automated CVE detection for EC2 and Lambda
- **Zero Trust**: Service-to-service authentication with SigV4 signing
- **Incident Response**: Automated detection, isolation, and forensics
- **Performance**: 99% latency reduction with secret caching
- **Compliance**: CloudTrail auditing for all security operations
- **Cost Optimization**: Caching strategies reducing API calls by 70%
- **Response Time**: <10 seconds from detection to isolation

## Technologies and Tools

**Security Services**:
- Amazon Cognito
- AWS WAF
- AWS KMS
- AWS Secrets Manager
- Amazon Inspector
- AWS IAM (including OIDC providers)
- AWS STS
- Amazon GuardDuty

**Integration Services**:
- Amazon API Gateway
- AWS Lambda
- Application Load Balancer
- Amazon CloudWatch
- AWS CloudTrail
- Amazon EventBridge
- Amazon EC2
- Amazon EBS
- Amazon VPC
- Amazon SNS
- AWS Systems Manager

**Development Tools**:
- AWS CLI
- AWS SDK (Python/Node.js)
- JWT.io (token debugging)
- Postman (API testing)
- SigV4 signing libraries

**Monitoring Tools**:
- CloudWatch Logs
- CloudWatch Logs Insights
- CloudWatch Metrics
- CloudTrail Events
- X-Ray Tracing
- GuardDuty Findings

## Learning Outcomes

After completing these labs, I have demonstrated:

1. **Authentication Architecture**: Implementing secure user authentication with Cognito and OIDC
2. **API Security**: Protecting APIs with JWT-based and IAM authorization
3. **Web Application Protection**: Configuring WAF for comprehensive threat mitigation
4. **Encryption Management**: Using KMS for encryption and key management
5. **Secret Security**: Implementing secure secret storage and rotation
6. **Identity Federation**: Configuring OIDC providers and web identity federation
7. **Zero Trust Implementation**: Building service-to-service authentication without implicit trust
8. **Incident Response**: Automating detection, containment, and forensic analysis
9. **Vulnerability Management**: Implementing continuous security scanning with Inspector
10. **Access Control**: Configuring IAM roles and policies with least privilege
11. **Performance Optimization**: Balancing security and performance with caching
12. **Compliance**: Implementing audit logging and monitoring for compliance
13. **Security Automation**: Building event-driven security responses
14. **Network Security**: Implementing VPC endpoints and security group isolation
15. **Forensic Analysis**: Capturing evidence and maintaining chain of custody
16. **Best Practices**: Following AWS Well-Architected Security Pillar

## Security Principles

### Defense in Depth

Multiple layers of security controls:
- Network security (VPC, security groups, VPC endpoints)
- Application security (WAF, API Gateway)
- Authentication (Cognito, IAM, OIDC)
- Authorization (IAM policies, resource policies)
- Encryption (KMS, TLS)
- Monitoring (CloudTrail, CloudWatch, GuardDuty)
- Incident Response (EventBridge, Lambda automation)

### Least Privilege

Minimal permissions for all principals:
- IAM roles with specific permissions
- Resource-based policies
- Time-bound credentials
- Regular permission audits
- Policy conditions for context-based access

### Zero Trust

Never trust, always verify:
- Explicit authentication for all requests
- No implicit trust based on network location
- Micro-segmentation and isolation
- Continuous verification
- Assume breach mentality

### Encryption Everywhere

Data protection at all stages:
- Encryption at rest (KMS)
- Encryption in transit (TLS)
- Envelope encryption for performance
- Key rotation for compliance
- Customer-managed keys for control

### Audit Everything

Comprehensive logging and monitoring:
- CloudTrail for API activity
- CloudWatch for metrics and alarms
- VPC Flow Logs for network traffic
- Application logs for debugging
- GuardDuty for threat detection
- Automated incident response

## Next Steps

- Implement AWS GuardDuty for threat detection
- Configure AWS Security Hub for centralized findings
- Set up AWS Config for compliance monitoring
- Implement AWS Systems Manager for patch management
- Configure AWS Shield Advanced for DDoS protection
- Explore AWS Network Firewall for VPC protection
- Implement AWS Certificate Manager for TLS certificates
- Configure Amazon Macie for data discovery and protection
- Implement AWS Firewall Manager for centralized WAF management
- Explore AWS Detective for security investigation

---

**Total Labs**: 8 | **Total Estimated Time**: 8.25 hours | **Complexity Range**: Intermediate to Advanced
