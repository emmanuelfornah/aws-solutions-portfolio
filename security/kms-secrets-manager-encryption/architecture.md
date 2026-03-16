# Architecture: KMS Encryption with Secrets Manager

## Architecture Diagram

┌─────────────────────────────────────────────────────────────────┐
│                     Application Layer                            │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Lambda     │  │   EC2        │  │   ECS        │          │
│  │   Function   │  │   Instance   │  │   Container  │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                   │
│         │ IAM Role         │ IAM Role         │ IAM Role         │
│         │ (AssumeRole)     │ (Instance        │ (Task Role)      │
│         │                  │  Profile)        │                   │
└─────────┼──────────────────┼──────────────────┼───────────────────┘
          │                  │                  │
          │ 1. GetSecretValue                   │
          └──────────────────┴──────────────────┘
                             │
                             ▼
          ┌─────────────────────────────────────────┐
          │      AWS Secrets Manager                │
          │                                         │
          │  ┌───────────────────────────────────┐ │
          │  │  Secret: db-credentials           │ │
          │  │  ┌─────────────────────────────┐  │ │
          │  │  │ Encrypted Secret Value      │  │ │
          │  │  │ (Ciphertext)                │  │ │
          │  │  │                             │  │ │
          │  │  │ AES-256-GCM encrypted blob  │  │ │
          │  │  │ Encrypted with Data Key     │  │ │
          │  │  └─────────────────────────────┘  │ │
          │  │                                    │ │
          │  │  ┌─────────────────────────────┐  │ │
          │  │  │ Encrypted Data Key          │  │ │
          │  │  │ (Encrypted with KMS CMK)    │  │ │
          │  │  └─────────────────────────────┘  │ │
          │  │                                    │ │
          │  │  Metadata:                         │ │
          │  │  - KMS Key ID                      │ │
          │  │  - Rotation Config                 │ │
          │  │  - Version ID                      │ │
          │  └───────────────────────────────────┘ │
          │                                         │
          │  2. Check IAM Permissions               │
          │  3. Request KMS Decrypt                 │
          └─────────────────┬───────────────────────┘
                            │
                            │ 3. Decrypt(EncryptedDataKey)
                            ▼
          ┌─────────────────────────────────────────┐
          │         AWS KMS                         │
          │                                         │
          │  ┌───────────────────────────────────┐ │
          │  │  Customer Managed Key (CMK)       │ │
          │  │                                   │ │
          │  │  Key ID: xxxxxxxx-xxxx-xxxx...   │ │
          │  │  Key Spec: SYMMETRIC_DEFAULT      │ │
          │  │  Key Usage: ENCRYPT_DECRYPT       │ │
          │  │                                   │ │
          │  │  ┌─────────────────────────────┐ │ │
          │  │  │   Key Policy                │ │ │
          │  │  │   - Root account access     │ │ │
          │  │  │   - Secrets Manager access  │ │ │
          │  │  │   - Application role access │ │ │
          │  │  └─────────────────────────────┘ │ │
          │  │                                   │ │
          │  │  ┌─────────────────────────────┐ │ │
          │  │  │   Key Material              │ │ │
          │  │  │   (AWS managed HSM)         │ │ │
          │  │  │   - FIPS 140-2 Level 2      │ │ │
          │  │  └─────────────────────────────┘ │ │
          │  └───────────────────────────────────┘ │
          │                                         │
          │  4. Validate Key Policy                 │
          │  5. Decrypt Data Key                    │
          │  6. Return Plaintext Data Key           │
          └─────────────────┬───────────────────────┘
                            │
                            │ 6. Plaintext Data Key
                            ▼
          ┌─────────────────────────────────────────┐
          │      Secrets Manager                    │
          │                                         │
          │  7. Decrypt Secret Value                │
          │     (using plaintext data key)          │
          │                                         │
          │  8. Return Plaintext Secret             │
          └─────────────────┬───────────────────────┘
                            │
                            │ 8. Plaintext Secret
                            │    {
                            │      "username": "admin",
                            │      "password": "secret123",
                            │      "host": "db.example.com"
                            │    }
                            ▼
          ┌─────────────────────────────────────────┐
          │         Application                     │
          │  - Uses secret to connect to database   │
          │  - Secret never stored in plaintext     │
          │  - Secret automatically rotated         │
          └─────────────────────────────────────────┘
                            │
                            ▼
          ┌─────────────────────────────────────────┐
          │      AWS CloudTrail                     │
          │  - Logs all KMS API calls               │
          │  - Decrypt operations                   │
          │  - Key policy changes                   │
          │  - Compliance auditing                  │
          └─────────────────────────────────────────┘

## Envelope Encryption Flow

### Encryption Process (Storing Secret)

Step 1: Generate Data Key
┌─────────────────────────────────────┐
│  Application/Secrets Manager        │
│  Calls: KMS.GenerateDataKey()       │
│  Parameters:                         │
│    - KeyId: CMK ARN                  │
│    - KeySpec: AES_256                │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  AWS KMS                             │
│  1. Validates key policy             │
│  2. Generates random 256-bit key     │
│  3. Encrypts key with CMK            │
│  4. Returns both versions:           │
│     - Plaintext data key             │
│     - Encrypted data key (ciphertext)│
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  Secrets Manager                     │
│  1. Receives plaintext data key      │
│  2. Encrypts secret with data key    │
│     (AES-256-GCM)                    │
│  3. Stores encrypted secret          │
│  4. Stores encrypted data key        │
│  5. Deletes plaintext data key       │
│     from memory                      │
└─────────────────────────────────────┘

Result:
├─ Encrypted Secret (ciphertext)
├─ Encrypted Data Key (ciphertext)
└─ No plaintext data stored

### Decryption Process (Retrieving Secret)

Step 1: Retrieve Encrypted Secret
┌─────────────────────────────────────┐
│  Application                         │
│  Calls: SecretsManager.GetSecretValue│
│  Parameters:                         │
│    - SecretId: secret-name           │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  Secrets Manager                     │
│  1. Validates IAM permissions        │
│  2. Retrieves encrypted secret       │
│  3. Retrieves encrypted data key     │
│  4. Calls KMS to decrypt data key    │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  AWS KMS                             │
│  1. Validates key policy             │
│  2. Validates IAM permissions        │
│  3. Decrypts data key with CMK       │
│  4. Returns plaintext data key       │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  Secrets Manager                     │
│  1. Receives plaintext data key      │
│  2. Decrypts secret with data key    │
│  3. Returns plaintext secret         │
│  4. Deletes plaintext data key       │
│     from memory                      │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  Application                         │
│  Receives plaintext secret:          │
│  {                                   │
│    "username": "admin",              │
│    "password": "secret123",          │
│    "host": "db.example.com"          │
│  }                                   │
└─────────────────────────────────────┘

## Secret Rotation Architecture

                    Rotation Schedule
                    (e.g., every 30 days)
                            │
                            ▼
          ┌─────────────────────────────────────┐
          │  Secrets Manager Rotation           │
          │  - Checks rotation schedule         │
          │  - Triggers rotation Lambda         │
          └─────────────┬───────────────────────┘
                        │
                        │ Invoke
                        ▼
          ┌─────────────────────────────────────┐
          │  Lambda Rotation Function           │
          │                                     │
          │  Step 1: createSecret               │
          │  ├─ Generate new password           │
          │  ├─ Store as AWSPENDING version     │
          │  └─ Encrypt with KMS                │
          │                                     │
          │  Step 2: setSecret                  │
          │  ├─ Update database password        │
          │  ├─ Test new credentials            │
          │  └─ Rollback if fails               │
          │                                     │
          │  Step 3: testSecret                 │
          │  ├─ Connect with new credentials    │
          │  ├─ Verify access                   │
          │  └─ Confirm functionality           │
          │                                     │
          │  Step 4: finishSecret               │
          │  ├─ Mark AWSPENDING as AWSCURRENT   │
          │  ├─ Mark old version as AWSPREVIOUS │
          │  └─ Complete rotation               │
          └─────────────┬───────────────────────┘
                        │
                        ▼
          ┌─────────────────────────────────────┐
          │  Database/Service                   │
          │  - Password updated                 │
          │  - Old password still valid         │
          │    (for brief transition)           │
          │  - Applications use new password    │
          └─────────────────────────────────────┘
                        │
                        ▼
          ┌─────────────────────────────────────┐
          │  CloudWatch Logs                    │
          │  - Rotation success/failure         │
          │  - Timestamp                        │
          │  - Version information              │
          └─────────────────────────────────────┘

## KMS Key Policy Structure

### Complete Key Policy

```json
{
  "Version": "2012-10-17",
  "Id": "secrets-manager-key-policy",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::XXXXXXXXXXXX:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow Secrets Manager to use the key",
      "Effect": "Allow",
      "Principal": {
        "Service": "secretsmanager.amazonaws.com"
      },
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:CreateGrant"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "secretsmanager.us-east-1.amazonaws.com"
        }
      }
    },
    {
      "Sid": "Allow application role to decrypt",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::XXXXXXXXXXXX:role/AppRole"
      },
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow CloudTrail to log key usage",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ],
      "Resource": "*"
    }
  ]
}

## IAM Policy for Secret Access

### Application Role Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GetSecretValue",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:XXXXXXXXXXXX:secret:db-credentials-*"
    },
    {
      "Sid": "DecryptWithKMS",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": "arn:aws:kms:us-east-1:XXXXXXXXXXXX:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "secretsmanager.us-east-1.amazonaws.com"
        }
      }
    }
  ]
}

## Security Architecture

### Defense in Depth

Layer 1: Network Security
├─ VPC endpoints for Secrets Manager
├─ VPC endpoints for KMS
└─ No internet access required

Layer 2: IAM Authentication
├─ IAM roles for applications
├─ Temporary credentials
└─ No long-term access keys

Layer 3: Authorization
├─ IAM policies (identity-based)
├─ KMS key policies (resource-based)
└─ Least privilege principle

Layer 4: Encryption
├─ Encryption at rest (KMS)
├─ Encryption in transit (TLS)
└─ Envelope encryption

Layer 5: Auditing
├─ CloudTrail logging
├─ CloudWatch monitoring
└─ Compliance reporting

## Key Management Best Practices

### Key Lifecycle

1. Key Creation
   ├─ Customer managed key
   ├─ Symmetric encryption
   ├─ Key policy configuration
   └─ Key alias for easy reference

2. Key Usage
   ├─ Encrypt secrets
   ├─ Decrypt for authorized principals
   ├─ Grant management
   └─ CloudTrail logging

3. Key Rotation
   ├─ Automatic annual rotation
   ├─ Old key material retained
   ├─ Transparent to applications
   └─ No re-encryption needed

4. Key Monitoring
   ├─ CloudWatch metrics
   ├─ CloudTrail events
   ├─ Usage patterns
   └─ Anomaly detection

5. Key Deletion
   ├─ 7-30 day waiting period
   ├─ Key disabled immediately
   ├─ Verify no dependencies
   └─ Permanent deletion

## Encryption Performance

### Latency Considerations

**KMS API Calls**:
- GenerateDataKey: 10-50ms
- Decrypt: 10-50ms
- DescribeKey: 5-20ms

**Secrets Manager Operations**:
- GetSecretValue (first call): 50-150ms
  - Includes KMS decrypt operation
- GetSecretValue (cached): 5-20ms
  - Uses cached data key

**Optimization Strategies**:
1. **Cache Secrets**: Store decrypted secrets in memory
2. **Batch Operations**: Retrieve multiple secrets together
3. **VPC Endpoints**: Reduce network latency
4. **Regional Deployment**: Use same region for KMS and Secrets Manager

## Cost Considerations

### Pricing Components

**AWS KMS**:
- Customer managed key: $1.00/month
- API requests: $0.03 per 10,000 requests
- Automatic key rotation: Included

**AWS Secrets Manager**:
- Secret storage: $0.40 per secret per month
- API calls: $0.05 per 10,000 API calls
- Rotation: Lambda execution costs

**Example Monthly Cost**:
KMS Key: $1.00
Secrets (5): $2.00
KMS API calls (100K): $0.30
Secrets API calls (50K): $0.25
Lambda rotation: $0.20
Total: ~$3.75/month

### Cost Optimization

1. **Consolidate Secrets**: Store multiple values in one secret
2. **Cache Secrets**: Reduce API calls
3. **Use AWS Managed Keys**: For non-compliance workloads ($0/month)
4. **Optimize Rotation**: Balance security and cost
5. **Delete Unused Secrets**: Avoid unnecessary charges

## Monitoring and Alerting

### CloudWatch Metrics

**KMS Metrics**:
- `NumberOfDecryptCalls`: Decrypt operations
- `NumberOfEncryptCalls`: Encrypt operations
- `NumberOfGenerateDataKeyCalls`: Data key generation

**Secrets Manager Metrics**:
- `GetSecretValueCalls`: Secret retrieval
- `RotationSucceeded`: Successful rotations
- `RotationFailed`: Failed rotations

### CloudTrail Events

**Key Events to Monitor**:
KMS Events:
├─ Decrypt: Secret access
├─ GenerateDataKey: Secret creation
├─ PutKeyPolicy: Key policy changes
├─ DisableKey: Key disabled
└─ ScheduleKeyDeletion: Key deletion

Secrets Manager Events:
├─ GetSecretValue: Secret retrieval
├─ PutSecretValue: Secret update
├─ RotateSecret: Rotation trigger
├─ DeleteSecret: Secret deletion
└─ UpdateSecretVersionStage: Version changes

### Security Alerts

**Recommended Alarms**:
1. **Unusual Decrypt Volume**: > 1000 decrypts/hour
2. **Failed Decrypt Attempts**: > 10 failures/5 minutes
3. **Key Policy Changes**: Any modification
4. **Rotation Failures**: Any failed rotation
5. **Unauthorized Access**: Access denied errors

## Compliance and Auditing

### Compliance Standards

**Supported Compliance**:
- **HIPAA**: Encryption of PHI
- **PCI DSS**: Key management requirements
- **GDPR**: Data protection measures
- **SOC 2**: Security controls
- **FedRAMP**: Government compliance

### Audit Requirements

**CloudTrail Logging**:
- All KMS API calls logged
- All Secrets Manager operations logged
- Immutable audit trail
- Long-term retention in S3

**Audit Reports**:
Key Usage Report:
├─ Who accessed which keys
├─ When keys were used
├─ What operations were performed
└─ Success/failure status

Secret Access Report:
├─ Which secrets were accessed
├─ By which principals
├─ From which sources
└─ Access patterns

## Disaster Recovery

### Backup Strategy

**KMS Keys**:
- Key material backed up by AWS
- Multi-region key replication available
- Key policies stored in CloudFormation

**Secrets**:
- Automatic versioning
- Point-in-time recovery
- Cross-region replication available
- Backup to S3 for compliance

### Recovery Procedures

**Key Compromise**:
1. Disable compromised key immediately
2. Create new customer managed key
3. Re-encrypt all secrets with new key
4. Update applications with new key ID
5. Schedule old key for deletion

**Secret Compromise**:
1. Rotate secret immediately
2. Update all applications
3. Audit access logs
4. Investigate breach source
5. Implement additional controls

## Real-World Use Cases

### Database Credentials

- Store RDS/Aurora credentials
- Automatic rotation every 30 days
- Applications retrieve on startup
- Zero-downtime rotation

### API Keys

- Third-party service credentials
- Encrypted with customer managed key
- Cached for performance
- Rotated on schedule

### Application Secrets

- JWT signing keys
- Encryption keys
- OAuth client secrets
- Service account credentials

### Multi-Tenant SaaS

- Per-tenant encryption keys
- Isolated key policies
- Tenant-specific access control
- Compliance per tenant

## Additional Resources

- [AWS KMS Documentation](https://docs.aws.amazon.com/kms/)
- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [Envelope Encryption](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#enveloping)
- [Key Policies](https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html)
- [Secret Rotation](https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html)

