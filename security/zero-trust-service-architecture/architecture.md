# Architecture: Zero Trust for Service-To-Service Workloads

## Architecture Diagram

┌────────────────────────────────────────────────────────────────────────┐
│                          AWS Account                                    │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │                         VPC (10.0.0.0/16)                         │ │
│  │                                                                   │ │
│  │  ┌─────────────────────────────────────────────────────────────┐│ │
│  │  │              Private Subnet A (10.0.1.0/24)                 ││ │
│  │  │                                                              ││ │
│  │  │  ┌──────────────────────────────────────────────────────┐  ││ │
│  │  │  │  Service A (EC2 / Lambda)                            │  ││ │
│  │  │  │  IAM Role: ServiceA-Role                             │  ││ │
│  │  │  │                                                       │  ││ │
│  │  │  │  1. Prepare API request                              │  ││ │
│  │  │  │  2. Sign with SigV4                                  │  ││ │
│  │  │  │     - Access Key from IAM role                       │  ││ │
│  │  │  │     - Generate signature                             │  ││ │
│  │  │  │  3. Add Authorization header                         │  ││ │
│  │  │  └──────────────────┬───────────────────────────────────┘  ││ │
│  │  │                     │                                       ││ │
│  │  │                     │ HTTPS (443)                           ││ │
│  │  │                     │ Signed Request                        ││ │
│  │  │                     ▼                                       ││ │
│  │  │  ┌──────────────────────────────────────────────────────┐  ││ │
│  │  │  │  VPC Endpoint (Interface)                            │  ││ │
│  │  │  │  Type: execute-api                                   │  ││ │
│  │  │  │  ENI: 10.0.1.50                                      │  ││ │
│  │  │  │                                                       │  ││ │
│  │  │  │  Endpoint Policy:                                    │  ││ │
│  │  │  │  - Allow execute-api:Invoke                          │  ││ │
│  │  │  │  - Restrict to specific APIs                         │  ││ │
│  │  │  └──────────────────┬───────────────────────────────────┘  ││ │
│  │  │                     │                                       ││ │
│  │  └─────────────────────┼───────────────────────────────────────┘│ │
│  │                        │                                        │ │
│  │                        │ Private Link                           │ │
│  │                        │ (AWS Network)                          │ │
│  │                        ▼                                        │ │
│  │  ┌─────────────────────────────────────────────────────────────┐│ │
│  │  │              Security Group: API-Endpoint-SG                ││ │
│  │  │              Inbound: 443 from ServiceA-SG                  ││ │
│  │  └─────────────────────────────────────────────────────────────┘│ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │                    Amazon API Gateway                             │ │
│  │                    (Regional Endpoint)                            │ │
│  │                                                                   │ │
│  │  ┌─────────────────────────────────────────────────────────────┐│ │
│  │  │  4. Receive Request                                         ││ │
│  │  │     - Extract Authorization header                          ││ │
│  │  │     - Parse IAM credentials                                 ││ │
│  │  └─────────────────────────────────────────────────────────────┘│ │
│  │                                                                   │ │
│  │  ┌─────────────────────────────────────────────────────────────┐│ │
│  │  │  5. Validate SigV4 Signature                                ││ │
│  │  │     - Reconstruct canonical request                         ││ │
│  │  │     - Compute expected signature                            ││ │
│  │  │     - Compare with provided signature                       ││ │
│  │  │     - Check timestamp (within 15 minutes)                   ││ │
│  │  └─────────────────────────────────────────────────────────────┘│ │
│  │                                                                   │ │
│  │  ┌─────────────────────────────────────────────────────────────┐│ │
│  │  │  6. Evaluate IAM Policies                                   ││ │
│  │  │                                                              ││ │
│  │  │  Identity-Based Policy (ServiceA-Role):                     ││ │
│  │  │  {                                                           ││ │
│  │  │    "Effect": "Allow",                                        ││ │
│  │  │    "Action": "execute-api:Invoke",                           ││ │
│  │  │    "Resource": "arn:aws:execute-api:region:account:api-id/*"││ │
│  │  │  }                                                           ││ │
│  │  │                                                              ││ │
│  │  │  Resource-Based Policy (API Gateway):                       ││ │
│  │  │  {                                                           ││ │
│  │  │    "Effect": "Allow",                                        ││ │
│  │  │    "Principal": {                                            ││ │
│  │  │      "AWS": "arn:aws:iam::account:role/ServiceA-Role"       ││ │
│  │  │    },                                                        ││ │
│  │  │    "Action": "execute-api:Invoke",                           ││ │
│  │  │    "Resource": "*",                                          ││ │
│  │  │    "Condition": {                                            ││ │
│  │  │      "StringEquals": {                                       ││ │
│  │  │        "aws:SourceVpce": "vpce-12345"                        ││ │
│  │  │      }                                                       ││ │
│  │  │    }                                                         ││ │
│  │  │  }                                                           ││ │
│  │  └─────────────────────────────────────────────────────────────┘│ │
│  │                                                                   │ │
│  │  ┌─────────────────────────────────────────────────────────────┐│ │
│  │  │  7. If Authorized → Invoke Backend                          ││ │
│  │  │     If Denied → Return 403 Forbidden                        ││ │
│  │  └─────────────────────┬───────────────────────────────────────┘│ │
│  └────────────────────────┼───────────────────────────────────────┘ │
│                           │                                          │
│                           │ Invoke                                   │
│                           ▼                                          │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │              Private Subnet B (10.0.2.0/24)                      │ │
│  │                                                                   │ │
│  │  ┌─────────────────────────────────────────────────────────────┐│ │
│  │  │  Service B (Lambda / ECS)                                   ││ │
│  │  │  IAM Role: ServiceB-Role                                    ││ │
│  │  │                                                              ││ │
│  │  │  8. Process Request                                         ││ │
│  │  │     - Request already authenticated                         ││ │
│  │  │     - Caller identity in context                            ││ │
│  │  │     - Perform business logic                                ││ │
│  │  │  9. Return Response                                         ││ │
│  │  └─────────────────────────────────────────────────────────────┘│ │
│  │                                                                   │ │
│  │  ┌─────────────────────────────────────────────────────────────┐│ │
│  │  │  Security Group: ServiceB-SG                                ││ │
│  │  │  Inbound: 443 from API Gateway                              ││ │
│  │  └─────────────────────────────────────────────────────────────┘│ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │                    AWS CloudTrail                                 │ │
│  │  - AssumeRole events (ServiceA-Role)                             │ │
│  │  - execute-api:Invoke events                                     │ │
│  │  - Authorization decisions (Allow/Deny)                          │ │
│  │  - Source IP, VPC endpoint, timestamp                            │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │                    Amazon CloudWatch                              │ │
│  │  - API Gateway access logs                                       │ │
│  │  - Lambda execution logs                                         │ │
│  │  - Metrics: Latency, errors, throttles                           │ │
│  │  - Alarms: Unauthorized access attempts                          │ │
│  └──────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────┘

## Zero Trust Principles Implementation

### 1. Never Trust, Always Verify

**Traditional Model** (Implicit Trust):
Service A → Service B
└── If on same network → Trusted

**Zero Trust Model** (Explicit Verification):
Service A → Service B
├── Authenticate with IAM credentials
├── Sign request with SigV4
├── Validate signature
├── Evaluate IAM policies
├── Check resource policy
└── If all pass → Authorized

### 2. Least Privilege Access

**Service A IAM Policy** (Minimal Permissions):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "execute-api:Invoke",
      "Resource": [
        "arn:aws:execute-api:us-east-1:123456789012:abc123/prod/GET/users",
        "arn:aws:execute-api:us-east-1:123456789012:abc123/prod/POST/users"
      ]
    }
  ]
}

**Not This** (Overly Permissive):
```json
{
  "Effect": "Allow",
  "Action": "execute-api:*",
  "Resource": "*"
}

### 3. Assume Breach

Design assumes attackers may compromise a service:
- **Network Segmentation**: Compromised service can't access others
- **Authentication Required**: Can't impersonate other services
- **Audit Logging**: Detect unusual behavior
- **Automated Response**: Isolate compromised service
- **Credential Rotation**: Limit credential lifetime

### 4. Micro-Segmentation

┌─────────────────────────────────────────────────────────┐
│                    Traditional Segmentation              │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  DMZ (All Web Services)                            │ │
│  │  - Service A, B, C, D can all talk to each other  │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Internal (All Backend Services)                   │ │
│  │  - Service E, F, G, H can all talk to each other  │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                    Micro-Segmentation                    │
│                                                          │
│  Service A ──[SG-A]──> API Gateway ──[SG-B]──> Service B│
│      │                                            │      │
│      │ Blocked                           Blocked │      │
│      ▼                                            ▼      │
│  Service C                                   Service D  │
│                                                          │
│  Each service isolated with:                            │
│  - Unique security group                                │
│  - Unique IAM role                                      │
│  - Explicit authorization required                      │
└─────────────────────────────────────────────────────────┘

## SigV4 Signing Process

### Step-by-Step Signing

1. Create Canonical Request
   ├── HTTP Method: GET
   ├── Canonical URI: /prod/users
   ├── Canonical Query String: (sorted)
   ├── Canonical Headers: (sorted, lowercase)
   │   ├── host:abc123.execute-api.us-east-1.amazonaws.com
   │   ├── x-amz-date:20240115T120000Z
   │   └── x-amz-security-token:[session-token]
   ├── Signed Headers: host;x-amz-date;x-amz-security-token
   └── Payload Hash: SHA256 of request body

   Canonical Request:
   GET
   /prod/users
   
   host:abc123.execute-api.us-east-1.amazonaws.com
   x-amz-date:20240115T120000Z
   x-amz-security-token:[token]
   
   host;x-amz-date;x-amz-security-token
   e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

2. Create String to Sign
   ├── Algorithm: AWS4-HMAC-SHA256
   ├── Timestamp: 20240115T120000Z
   ├── Credential Scope: 20240115/us-east-1/execute-api/aws4_request
   └── Hashed Canonical Request: SHA256(canonical_request)

   String to Sign:
   AWS4-HMAC-SHA256
   20240115T120000Z
   20240115/us-east-1/execute-api/aws4_request
   [sha256-hash-of-canonical-request]

3. Calculate Signing Key
   ├── kSecret = AWS Secret Access Key
   ├── kDate = HMAC("AWS4" + kSecret, "20240115")
   ├── kRegion = HMAC(kDate, "us-east-1")
   ├── kService = HMAC(kRegion, "execute-api")
   └── kSigning = HMAC(kService, "aws4_request")

4. Calculate Signature
   └── Signature = HMAC(kSigning, string_to_sign)

5. Add Authorization Header
   Authorization: AWS4-HMAC-SHA256 
     Credential=AKIAIOSFODNN7EXAMPLE/20240115/us-east-1/execute-api/aws4_request,
     SignedHeaders=host;x-amz-date;x-amz-security-token,
     Signature=[calculated-signature]

### Python Example

```python
import hashlib
import hmac
import datetime
import requests
from urllib.parse import quote

def sign_request(method, url, headers, body, access_key, secret_key, session_token=None):
    # Parse URL
    from urllib.parse import urlparse
    parsed = urlparse(url)
    host = parsed.netloc
    path = parsed.path or '/'
    query = parsed.query
    
    # Add required headers
    timestamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    headers['host'] = host
    headers['x-amz-date'] = timestamp
    if session_token:
        headers['x-amz-security-token'] = session_token
    
    # Create canonical request
    canonical_headers = '\n'.join(f'{k.lower()}:{v}' for k, v in sorted(headers.items()))
    signed_headers = ';'.join(sorted(k.lower() for k in headers.keys()))
    payload_hash = hashlib.sha256(body.encode('utf-8')).hexdigest()
    
    canonical_request = f"{method}\n{path}\n{query}\n{canonical_headers}\n\n{signed_headers}\n{payload_hash}"
    
    # Create string to sign
    date_stamp = timestamp[:8]
    region = 'us-east-1'
    service = 'execute-api'
    credential_scope = f"{date_stamp}/{region}/{service}/aws4_request"
    
    string_to_sign = f"AWS4-HMAC-SHA256\n{timestamp}\n{credential_scope}\n"
    string_to_sign += hashlib.sha256(canonical_request.encode('utf-8')).hexdigest()
    
    # Calculate signing key
    def sign(key, msg):
        return hmac.new(key, msg.encode('utf-8'), hashlib.sha256).digest()
    
    k_date = sign(('AWS4' + secret_key).encode('utf-8'), date_stamp)
    k_region = sign(k_date, region)
    k_service = sign(k_region, service)
    k_signing = sign(k_service, 'aws4_request')
    
    # Calculate signature
    signature = hmac.new(k_signing, string_to_sign.encode('utf-8'), hashlib.sha256).hexdigest()
    
    # Add authorization header
    authorization = f"AWS4-HMAC-SHA256 Credential={access_key}/{credential_scope}, "
    authorization += f"SignedHeaders={signed_headers}, Signature={signature}"
    headers['Authorization'] = authorization
    
    return headers

## Policy Evaluation Flow

### Combined Policy Evaluation

Request from Service A to API Gateway
│
├─ Step 1: Authenticate
│  ├─ Validate SigV4 signature
│  ├─ Verify timestamp (within 15 min)
│  └─ Extract principal (ServiceA-Role)
│
├─ Step 2: Evaluate Identity-Based Policies
│  ├─ Get policies attached to ServiceA-Role
│  ├─ Check for explicit Deny → If found, DENY
│  ├─ Check for Allow on execute-api:Invoke → If not found, DENY
│  └─ Result: ALLOW (continue to next step)
│
├─ Step 3: Evaluate Resource-Based Policy
│  ├─ Get API Gateway resource policy
│  ├─ Check for explicit Deny → If found, DENY
│  ├─ Check for Allow for ServiceA-Role → If not found, DENY
│  ├─ Evaluate conditions (source VPC endpoint) → If not met, DENY
│  └─ Result: ALLOW (continue to next step)
│
├─ Step 4: Evaluate VPC Endpoint Policy
│  ├─ Get VPC endpoint policy
│  ├─ Check for explicit Deny → If found, DENY
│  ├─ Check for Allow on execute-api:Invoke → If not found, DENY
│  └─ Result: ALLOW (continue to next step)
│
└─ Final Decision: ALLOW → Invoke backend service

### Policy Evaluation Logic

Decision = Deny by Default

For each policy:
  If Explicit Deny:
    Decision = Deny
    Break (Deny always wins)
  
  If Allow:
    Check Conditions:
      If Conditions Met:
        Decision = Allow
      Else:
        Continue (condition not met)

Return Decision

## Network Architecture

### Security Group Configuration

┌─────────────────────────────────────────────────────────┐
│  Security Group: ServiceA-SG                            │
│                                                          │
│  Inbound Rules:                                         │
│  - None (no inbound traffic needed)                     │
│                                                          │
│  Outbound Rules:                                        │
│  - Protocol: TCP                                        │
│  - Port: 443                                            │
│  - Destination: API-Endpoint-SG                         │
│  - Description: HTTPS to API Gateway VPC endpoint       │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  Security Group: API-Endpoint-SG                        │
│                                                          │
│  Inbound Rules:                                         │
│  - Protocol: TCP                                        │
│  - Port: 443                                            │
│  - Source: ServiceA-SG                                  │
│  - Description: HTTPS from Service A                    │
│                                                          │
│  Outbound Rules:                                        │
│  - Protocol: TCP                                        │
│  - Port: 443                                            │
│  - Destination: 0.0.0.0/0                               │
│  - Description: HTTPS to API Gateway (AWS network)      │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  Security Group: ServiceB-SG                            │
│                                                          │
│  Inbound Rules:                                         │
│  - Protocol: TCP                                        │
│  - Port: 443                                            │
│  - Source: API Gateway (managed by AWS)                 │
│  - Description: HTTPS from API Gateway                  │
│                                                          │
│  Outbound Rules:                                        │
│  - As needed for Service B dependencies                 │
└─────────────────────────────────────────────────────────┘

### VPC Endpoint Configuration

```json
{
  "ServiceName": "com.amazonaws.us-east-1.execute-api",
  "VpcEndpointType": "Interface",
  "VpcId": "vpc-12345",
  "SubnetIds": ["subnet-abc", "subnet-def"],
  "SecurityGroupIds": ["sg-api-endpoint"],
  "PrivateDnsEnabled": true,
  "PolicyDocument": {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "execute-api:Invoke",
        "Resource": [
          "arn:aws:execute-api:us-east-1:123456789012:abc123/*"
        ]
      }
    ]
  }
}

## Monitoring and Alerting

### CloudWatch Metrics

API Gateway Metrics:
├── Count: Total requests
├── 4XXError: Client errors (auth failures)
├── 5XXError: Server errors
├── Latency: Request latency
├── IntegrationLatency: Backend latency
└── CacheHitCount: Cache performance

Custom Metrics:
├── UnauthorizedAttempts: 403 errors
├── AuthenticationFailures: Invalid signatures
├── ResourcePolicyDenials: Resource policy blocks
└── UnusualAccessPatterns: Anomaly detection

### CloudWatch Alarms

```yaml
UnauthorizedAccessAlarm:
  MetricName: 4XXError
  Threshold: 10
  Period: 300  # 5 minutes
  EvaluationPeriods: 1
  ComparisonOperator: GreaterThanThreshold
  AlarmActions:
    - SNS Topic: security-alerts
    - Lambda: investigate-unauthorized-access

AuthenticationFailureAlarm:
  MetricName: Custom/AuthFailures
  Threshold: 5
  Period: 60  # 1 minute
  EvaluationPeriods: 2
  ComparisonOperator: GreaterThanThreshold
  AlarmActions:
    - SNS Topic: security-alerts
    - Lambda: block-suspicious-principal

### CloudTrail Analysis

```sql
-- Query unauthorized access attempts
SELECT
  userIdentity.principalId,
  sourceIPAddress,
  requestParameters.resource,
  errorCode,
  errorMessage,
  COUNT(*) as attempts
FROM cloudtrail_logs
WHERE
  eventName = 'Invoke'
  AND eventSource = 'execute-api.amazonaws.com'
  AND errorCode IN ('AccessDenied', 'UnauthorizedException')
  AND eventTime > DATE_SUB(NOW(), INTERVAL 1 HOUR)
GROUP BY
  userIdentity.principalId,
  sourceIPAddress,
  requestParameters.resource,
  errorCode,
  errorMessage
ORDER BY attempts DESC

## Best Practices Summary

### Authentication
1. Use IAM roles for all services (no long-term credentials)
2. Implement SigV4 signing for all API requests
3. Validate signatures on every request
4. Use temporary credentials from STS
5. Monitor authentication failures

### Authorization
1. Implement least privilege IAM policies
2. Use resource policies for additional control
3. Combine identity-based and resource-based policies
4. Use condition keys for context-based access
5. Regular permission audits

### Network Security
1. Deploy services in private subnets
2. Use VPC endpoints for AWS service access
3. Configure security groups with minimal rules
4. Implement network ACLs for subnet-level control
5. No direct internet access for services

### Monitoring
1. Enable CloudTrail for all API calls
2. Configure CloudWatch alarms for anomalies
3. Log all authentication and authorization events
4. Monitor for unusual access patterns
5. Implement automated incident response
