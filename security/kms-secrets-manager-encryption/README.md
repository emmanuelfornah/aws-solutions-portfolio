# Using AWS KMS to Encrypt Secrets Manager Secrets

## Overview

This project demonstrates encrypting sensitive data using AWS Key Management Service (KMS) with AWS Secrets Manager. The implementation includes creating customer-managed KMS keys with key policies, storing secrets in Secrets Manager with KMS encryption, implementing automatic secret rotation, configuring IAM policies for secret access, and monitoring key usage with CloudTrail.

## AWS Services Used

- **AWS KMS** - Key management and encryption
- **AWS Secrets Manager** - Secure secret storage and rotation
- **AWS IAM** - Access control policies
- **AWS Lambda** - Secret rotation functions
- **AWS CloudTrail** - Key usage auditing
- **Amazon CloudWatch** - Monitoring and alerting

## Key Technologies

- **Customer Managed Keys (CMK)** - Custom encryption keys
- **Envelope Encryption** - Data key encryption
- **Key Policies** - KMS access control
- **Secret Rotation** - Automatic credential updates
- **IAM Policies** - Fine-grained permissions
- **Encryption at Rest** - Data protection

## Architecture Overview

The architecture implements secure secret management using KMS customer-managed keys for encryption. Secrets Manager stores sensitive data (database credentials, API keys, passwords) encrypted with KMS keys. Lambda functions retrieve secrets using IAM roles with appropriate KMS decrypt permissions. Automatic rotation updates secrets periodically without application downtime. CloudTrail logs all KMS key usage for compliance auditing.

See [architecture.md](./architecture.md) for detailed encryption flow and key management architecture.

## Objectives

- Create customer-managed KMS keys
- Configure key policies for access control
- Store secrets in Secrets Manager with KMS encryption
- Implement automatic secret rotation
- Configure IAM policies for secret access
- Retrieve secrets programmatically
- Monitor key usage with CloudTrail
- Implement key rotation best practices

## Key Learnings

- **KMS Architecture**: Customer vs AWS managed keys
- **Envelope Encryption**: Data key encryption model
- **Key Policies**: Resource-based access control
- **Secret Rotation**: Automated credential updates
- **IAM Integration**: Combining key policies and IAM
- **Encryption Best Practices**: Key management strategies
- **Compliance**: Audit logging and monitoring
- **Cost Optimization**: Key usage and pricing

## Setup Instructions

### Prerequisites

- AWS account with KMS and Secrets Manager permissions
- AWS CLI configured with appropriate credentials
- Understanding of encryption concepts
- IAM permissions for key and secret management

### Step 1: Create KMS Customer Managed Key

Create encryption key:

```bash
./scripts/create-kms-key.sh
```

### Step 2: Configure Key Policy

Set up access control:

```bash
./scripts/configure-key-policy.sh
```

### Step 3: Create Secret in Secrets Manager

Store encrypted secret:

```bash
./scripts/create-secret.sh
```

### Step 4: Configure Secret Rotation

Enable automatic rotation:

```bash
./scripts/configure-rotation.sh
```

### Step 5: Create IAM Role for Access

Set up application permissions:

```bash
./scripts/create-iam-role.sh
```

### Step 6: Retrieve Secret Programmatically

Test secret retrieval:

```bash
./scripts/retrieve-secret.sh
```

### Step 7: Monitor Key Usage

View CloudTrail logs:

```bash
./scripts/monitor-key-usage.sh
```

### Step 8: Test Secret Rotation

Verify rotation functionality:

```bash
./scripts/test-rotation.sh
```

## Scripts and Configurations

### Scripts

- **create-kms-key.sh** - Creates customer-managed key
- **configure-key-policy.sh** - Sets up key access
- **create-secret.sh** - Stores encrypted secret
- **configure-rotation.sh** - Enables rotation
- **create-iam-role.sh** - Creates access role
- **retrieve-secret.sh** - Gets secret value
- **monitor-key-usage.sh** - Views audit logs
- **test-rotation.sh** - Tests rotation
- **cleanup.sh** - Removes all resources

### Configuration Files

- **key-policy.json** - KMS key policy
- **secret-config.json** - Secret configuration
- **rotation-config.json** - Rotation settings
- **iam-policy.json** - Secret access policy

## Metadata

- **Domain**: Security
- **Complexity Level**: Intermediate
- **Estimated Time**: 40 minutes
- **AWS Services**: KMS, Secrets Manager, IAM, Lambda, CloudTrail, CloudWatch
- **Key Concepts**: Encryption, key management, secret rotation, access control

## Real-World Application

- **Database credential rotation**: Production applications use Secrets Manager with automatic rotation to eliminate hardcoded database passwords
- **Encryption at rest**: Every regulated industry (healthcare, finance, government) requires KMS-managed encryption for data at rest in S3, EBS, and RDS
- **Envelope encryption**: Large-scale data platforms use envelope encryption to encrypt data with data keys, then encrypt data keys with KMS — enabling efficient bulk encryption
- **Multi-account key management**: Enterprise organizations share KMS keys across accounts using key policies for centralized encryption governance
