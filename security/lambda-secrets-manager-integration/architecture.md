# Architecture: Lambda with Secrets Manager Integration

## Architecture Diagram

┌─────────────────────────────────────────────────────────────────┐
│                     Event Sources                                │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   API        │  │   S3         │  │   EventBridge│          │
│  │   Gateway    │  │   Event      │  │   Schedule   │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                   │
└─────────┼──────────────────┼──────────────────┼───────────────────┘
          │                  │                  │
          │ Invoke           │ Invoke           │ Invoke
          └──────────────────┴──────────────────┘
                             │
                             ▼
          ┌─────────────────────────────────────────┐
          │      AWS Lambda Function                │
          │                                         │
          │  ┌───────────────────────────────────┐ │
          │  │  Execution Environment            │ │
          │  │                                   │ │
          │  │  ┌─────────────────────────────┐ │ │
          │  │  │  Lambda Handler             │ │ │
          │  │  │  - Initialize on cold start │ │ │
          │  │  │  - Check secret cache       │ │ │
          │  │  │  - Retrieve if needed       │ │ │
          │  │  │  - Use secret               │ │ │
          │  │  └─────────────────────────────┘ │ │
          │  │                                   │ │
          │  │  ┌─────────────────────────────┐ │ │
          │  │  │  Secret Cache (Memory)      │ │ │
          │  │  │  - Cached secret value      │ │ │
          │  │  │  - Cache timestamp          │ │ │
          │  │  │  - TTL: 5 minutes           │ │ │
          │  │  └─────────────────────────────┘ │ │
          │  │                                   │ │
          │  │  ┌─────────────────────────────┐ │ │
          │  │  │  IAM Execution Role         │ │ │
          │  │  │  - Secrets Manager access   │ │ │
          │  │  │  - KMS decrypt permission   │ │ │
          │  │  │  - CloudWatch Logs          │ │ │
          │  │  └─────────────────────────────┘ │ │
          │  └───────────────────────────────────┘ │
          │                                         │
          │  Environment Variables:                 │
          │  - SECRET_NAME: db-credentials          │
          │  - CACHE_TTL: 300                       │
          │  - AWS_REGION: us-east-1                │
          └─────────────┬───────────────────────────┘
                        │
                        │ 1. GetSecretValue
                        │    (if cache miss or expired)
                        ▼
          ┌─────────────────────────────────────────┐
          │      AWS Secrets Manager                │
          │                                         │
          │  ┌───────────────────────────────────┐ │
          │  │  Secret: db-credentials           │ │
          │  │  - Encrypted value                │ │
          │  │  - KMS key ID                     │ │
          │  │  - Version ID                     │ │
          │  │  - Rotation config                │ │
          │  └───────────────────────────────────┘ │
          │                                         │
          │  2. Validate IAM permissions            │
          │  3. Request KMS decrypt                 │
          └─────────────┬───────────────────────────┘
                        │
                        │ 3. Decrypt(EncryptedDataKey)
                        ▼
          ┌─────────────────────────────────────────┐
          │         AWS KMS                         │
          │                                         │
          │  ┌───────────────────────────────────┐ │
          │  │  Customer Managed Key             │ │
          │  │  - Validate key policy            │ │
          │  │  - Decrypt data key               │ │
          │  │  - Return plaintext key           │ │
          │  └───────────────────────────────────┘ │
          │                                         │
          │  4. Log decrypt operation               │
          └─────────────┬───────────────────────────┘
                        │
                        │ 4. Plaintext Data Key
                        ▼
          ┌─────────────────────────────────────────┐
          │      Secrets Manager                    │
          │  5. Decrypt secret value                │
          │  6. Return plaintext secret             │
          └─────────────┬───────────────────────────┘
                        │
                        │ 6. Plaintext Secret
                        │    {
                        │      "username": "admin",
                        │      "password": "secret",
                        │      "host": "db.example.com"
                        │    }
                        ▼
          ┌─────────────────────────────────────────┐
          │      Lambda Function                    │
          │  7. Cache secret in memory              │
          │  8. Use secret to connect to database   │
          │  9. Execute business logic              │
          │  10. Return response                    │
          └─────────────┬───────────────────────────┘
                        │
                        ▼
          ┌─────────────────────────────────────────┐
          │      Target Service                     │
          │  - Amazon RDS                           │
          │  - External API                         │
          │  - Third-party service                  │
          └─────────────────────────────────────────┘
                        │
                        ▼
          ┌─────────────────────────────────────────┐
          │      CloudWatch Logs                    │
          │  - Function invocations                 │
          │  - Secret retrieval events              │
          │  - Cache hit/miss metrics               │
          │  - Error logs                           │
          └─────────────────────────────────────────┘

## Secret Retrieval Flow

### Cold Start (First Invocation)

Step 1: Lambda Initialization
┌─────────────────────────────────────┐
│  Lambda Cold Start                  │
│  1. Create execution environment    │
│  2. Load function code              │
│  3. Initialize global variables     │
│  4. Secret cache is empty           │
└─────────────┬───────────────────────┘
              │
              ▼
Step 2: Check Cache
┌─────────────────────────────────────┐
│  Cache Check                        │
│  - Cache is empty (cold start)      │
│  - Need to retrieve secret          │
└─────────────┬───────────────────────┘
              │
              ▼
Step 3: Retrieve Secret
┌─────────────────────────────────────┐
│  Call Secrets Manager               │
│  secretsmanager.get_secret_value(   │
│    SecretId='db-credentials'        │
│  )                                  │
│  Latency: ~50-150ms                 │
└─────────────┬───────────────────────┘
              │
              ▼
Step 4: KMS Decryption
┌─────────────────────────────────────┐
│  KMS Decrypt Operation              │
│  - Validate IAM permissions         │
│  - Decrypt data key                 │
│  - Return plaintext                 │
│  Latency: ~10-50ms                  │
└─────────────┬───────────────────────┘
              │
              ▼
Step 5: Cache Secret
┌─────────────────────────────────────┐
│  Store in Memory                    │
│  cached_secret = {                  │
│    'value': secret_dict,            │
│    'timestamp': time.time(),        │
│    'ttl': 300                       │
│  }                                  │
└─────────────┬───────────────────────┘
              │
              ▼
Step 6: Use Secret
┌─────────────────────────────────────┐
│  Connect to Database                │
│  connection = mysql.connect(        │
│    host=secret['host'],             │
│    user=secret['username'],         │
│    password=secret['password']      │
│  )                                  │
└─────────────────────────────────────┘

Total Latency: ~100-250ms

### Warm Start (Subsequent Invocations)

Step 1: Lambda Warm Start
┌─────────────────────────────────────┐
│  Lambda Warm Invocation             │
│  1. Reuse execution environment     │
│  2. Global variables preserved      │
│  3. Secret cache still in memory    │
└─────────────┬───────────────────────┘
              │
              ▼
Step 2: Check Cache
┌─────────────────────────────────────┐
│  Cache Check                        │
│  - Cache exists                     │
│  - Check TTL                        │
│  - Current time - timestamp < TTL   │
│  - Cache is valid                   │
└─────────────┬───────────────────────┘
              │
              ▼
Step 3: Use Cached Secret
┌─────────────────────────────────────┐
│  Retrieve from Memory               │
│  secret = cached_secret['value']    │
│  Latency: <1ms                      │
└─────────────┬───────────────────────┘
              │
              ▼
Step 4: Use Secret
┌─────────────────────────────────────┐
│  Connect to Database                │
│  (using cached credentials)         │
└─────────────────────────────────────┘

Total Latency: ~1-5ms (99% reduction)

### Cache Expiration

Step 1: Check Cache
┌─────────────────────────────────────┐
│  Cache Check                        │
│  - Cache exists                     │
│  - Check TTL                        │
│  - Current time - timestamp > TTL   │
│  - Cache expired                    │
└─────────────┬───────────────────────┘
              │
              ▼
Step 2: Refresh Secret
┌─────────────────────────────────────┐
│  Retrieve New Secret                │
│  - Call Secrets Manager             │
│  - Get latest version               │
│  - Update cache                     │
└─────────────┬───────────────────────┘
              │
              ▼
Step 3: Use Updated Secret
┌─────────────────────────────────────┐
│  Connect with New Credentials       │
│  (handles rotation automatically)   │
└─────────────────────────────────────┘

## Lambda Function Code Examples

### Python Implementation with Caching

```python
import json
import boto3
import os
import time
from botocore.exceptions import ClientError

# Initialize clients outside handler (reused across invocations)
secretsmanager = boto3.client('secretsmanager')

# Global cache (persists across warm invocations)
secret_cache = {}

def get_secret(secret_name, ttl=300):
    """
    Retrieve secret with caching
    
    Args:
        secret_name: Name of the secret in Secrets Manager
        ttl: Cache time-to-live in seconds (default: 5 minutes)
    
    Returns:
        dict: Secret value as dictionary
    """
    current_time = time.time()
    
    # Check if secret is in cache and not expired
    if secret_name in secret_cache:
        cached_data = secret_cache[secret_name]
        if current_time - cached_data['timestamp'] < ttl:
            print(f"Cache hit for secret: {secret_name}")
            return cached_data['value']
        else:
            print(f"Cache expired for secret: {secret_name}")
    else:
        print(f"Cache miss for secret: {secret_name}")
    
    # Retrieve secret from Secrets Manager
    try:
        print(f"Retrieving secret from Secrets Manager: {secret_name}")
        response = secretsmanager.get_secret_value(SecretId=secret_name)
        
        # Parse secret string
        if 'SecretString' in response:
            secret_value = json.loads(response['SecretString'])
        else:
            # Binary secret (decode if needed)
            secret_value = response['SecretBinary']
        
        # Update cache
        secret_cache[secret_name] = {
            'value': secret_value,
            'timestamp': current_time
        }
        
        print(f"Secret cached successfully: {secret_name}")
        return secret_value
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        
        if error_code == 'ResourceNotFoundException':
            print(f"Secret not found: {secret_name}")
        elif error_code == 'InvalidRequestException':
            print(f"Invalid request: {e}")
        elif error_code == 'InvalidParameterException':
            print(f"Invalid parameter: {e}")
        elif error_code == 'DecryptionFailure':
            print(f"Decryption failed: {e}")
        elif error_code == 'InternalServiceError':
            print(f"Internal service error: {e}")
        
        raise e

def lambda_handler(event, context):
    """
    Lambda handler function
    """
    try:
        # Get secret name from environment variable
        secret_name = os.environ.get('SECRET_NAME', 'db-credentials')
        cache_ttl = int(os.environ.get('CACHE_TTL', '300'))
        
        # Retrieve secret (with caching)
        secret = get_secret(secret_name, ttl=cache_ttl)
        
        # Use secret to connect to database
        # Example: Connect to RDS MySQL
        import pymysql
        
        connection = pymysql.connect(
            host=secret['host'],
            user=secret['username'],
            password=secret['password'],
            database=secret['dbname'],
            port=int(secret.get('port', 3306))
        )
        
        # Execute query
        with connection.cursor() as cursor:
            cursor.execute("SELECT VERSION()")
            version = cursor.fetchone()
            print(f"Database version: {version[0]}")
        
        connection.close()
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Successfully connected to database',
                'database_version': version[0]
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }

### Node.js Implementation with Caching

```javascript
const AWS = require('aws-sdk');
const secretsManager = new AWS.SecretsManager();

// Global cache (persists across warm invocations)
const secretCache = {};

async function getSecret(secretName, ttl = 300) {
    const currentTime = Date.now() / 1000;
    
    // Check cache
    if (secretCache[secretName]) {
        const cachedData = secretCache[secretName];
        if (currentTime - cachedData.timestamp < ttl) {
            console.log(`Cache hit for secret: ${secretName}`);
            return cachedData.value;
        } else {
            console.log(`Cache expired for secret: ${secretName}`);
        }
    } else {
        console.log(`Cache miss for secret: ${secretName}`);
    }
    
    // Retrieve from Secrets Manager
    try {
        console.log(`Retrieving secret from Secrets Manager: ${secretName}`);
        const data = await secretsManager.getSecretValue({
            SecretId: secretName
        }).promise();
        
        let secretValue;
        if ('SecretString' in data) {
            secretValue = JSON.parse(data.SecretString);
        } else {
            secretValue = Buffer.from(data.SecretBinary, 'base64');
        }
        
        // Update cache
        secretCache[secretName] = {
            value: secretValue,
            timestamp: currentTime
        };
        
        console.log(`Secret cached successfully: ${secretName}`);
        return secretValue;
        
    } catch (error) {
        console.error(`Error retrieving secret: ${error.message}`);
        throw error;
    }
}

exports.handler = async (event, context) => {
    try {
        const secretName = process.env.SECRET_NAME || 'db-credentials';
        const cacheTtl = parseInt(process.env.CACHE_TTL || '300');
        
        // Retrieve secret (with caching)
        const secret = await getSecret(secretName, cacheTtl);
        
        // Use secret to connect to database
        const mysql = require('mysql2/promise');
        
        const connection = await mysql.createConnection({
            host: secret.host,
            user: secret.username,
            password: secret.password,
            database: secret.dbname,
            port: secret.port || 3306
        });
        
        const [rows] = await connection.execute('SELECT VERSION()');
        console.log(`Database version: ${rows[0]['VERSION()']}`);
        
        await connection.end();
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Successfully connected to database',
                database_version: rows[0]['VERSION()']
            })
        };
        
    } catch (error) {
        console.error(`Error: ${error.message}`);
        return {
            statusCode: 500,
            body: JSON.stringify({
                error: error.message
            })
        };
    }
};

## IAM Execution Role Policy

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
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:us-east-1:XXXXXXXXXXXX:log-group:/aws/lambda/*"
    },
    {
      "Sid": "XRayTracing",
      "Effect": "Allow",
      "Action": [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ],
      "Resource": "*"
    }
  ]
}

## Handling Secret Rotation

### Rotation Detection and Handling

```python
def get_secret_with_rotation_handling(secret_name):
    """
    Retrieve secret with automatic rotation handling
    """
    try:
        # Try to use cached secret
        secret = get_secret(secret_name)
        return secret
        
    except Exception as e:
        # If error occurs, it might be due to rotation
        # Clear cache and retry
        if secret_name in secret_cache:
            print(f"Clearing cache for {secret_name} due to error")
            del secret_cache[secret_name]
        
        # Retry with fresh secret
        secret = get_secret(secret_name)
        return secret

def connect_to_database_with_retry(secret):
    """
    Connect to database with retry logic for rotation
    """
    max_retries = 3
    retry_delay = 1  # seconds
    
    for attempt in range(max_retries):
        try:
            connection = pymysql.connect(
                host=secret['host'],
                user=secret['username'],
                password=secret['password'],
                database=secret['dbname']
            )
            return connection
            
        except pymysql.OperationalError as e:
            if attempt < max_retries - 1:
                print(f"Connection failed (attempt {attempt + 1}), retrying...")
                time.sleep(retry_delay)
                
                # Refresh secret (might have been rotated)
                secret = get_secret_with_rotation_handling(
                    os.environ['SECRET_NAME']
                )
            else:
                raise e

## Performance Optimization

### Caching Strategy Comparison

Without Caching:
├─ Every invocation: Secrets Manager API call
├─ Latency: 50-150ms per invocation
├─ Cost: $0.05 per 10,000 API calls
└─ 1000 invocations/day = $0.005/day

With Caching (5-minute TTL):
├─ Cold start: Secrets Manager API call
├─ Warm invocations: Memory cache (<1ms)
├─ Cache refresh: Every 5 minutes
├─ 1000 invocations/day ≈ 288 API calls
└─ Cost: $0.0014/day (72% reduction)

Performance Improvement:
├─ Latency: 99% reduction (warm invocations)
├─ Cost: 72% reduction
├─ API calls: 71% reduction
└─ Throughput: Higher (less API throttling)

### VPC Integration for Private Access

┌─────────────────────────────────────────┐
│  Lambda Function (in VPC)               │
│  - Private subnet                       │
│  - No internet access                   │
└─────────────┬───────────────────────────┘
              │
              │ Private connection
              ▼
┌─────────────────────────────────────────┐
│  VPC Endpoint (Secrets Manager)         │
│  - Interface endpoint                   │
│  - Private IP address                   │
│  - No NAT Gateway needed                │
└─────────────┬───────────────────────────┘
              │
              │ AWS PrivateLink
              ▼
┌─────────────────────────────────────────┐
│  AWS Secrets Manager                    │
│  - Private access                       │
│  - No internet exposure                 │
│  - Lower latency                        │
└─────────────────────────────────────────┘

Benefits:
├─ Enhanced security (no internet)
├─ Lower latency (private network)
├─ Cost savings (no NAT Gateway)
└─ Compliance (data residency)

## Monitoring and Logging

### CloudWatch Logs Structure

Log Group: /aws/lambda/my-function

Log Stream: 2024/01/15/[$LATEST]abc123...

Sample Logs:
START RequestId: abc-123 Version: $LATEST
Cache miss for secret: db-credentials
Retrieving secret from Secrets Manager: db-credentials
Secret cached successfully: db-credentials
Database version: 8.0.35
END RequestId: abc-123
REPORT RequestId: abc-123
  Duration: 1250.45 ms
  Billed Duration: 1251 ms
  Memory Size: 256 MB
  Max Memory Used: 85 MB
  Init Duration: 450.23 ms

Next Invocation (Warm):
START RequestId: def-456 Version: $LATEST
Cache hit for secret: db-credentials
Database version: 8.0.35
END RequestId: def-456
REPORT RequestId: def-456
  Duration: 45.12 ms
  Billed Duration: 46 ms
  Memory Size: 256 MB
  Max Memory Used: 86 MB

### X-Ray Tracing

Trace Timeline:
├─ Lambda Initialization: 450ms
│  └─ Load dependencies: 400ms
├─ Handler Execution: 800ms
│  ├─ Get Secret: 150ms
│  │  ├─ Secrets Manager API: 100ms
│  │  └─ KMS Decrypt: 50ms
│  ├─ Database Connection: 500ms
│  └─ Query Execution: 150ms
└─ Total Duration: 1250ms

Subsequent Invocation (Cached):
├─ Handler Execution: 45ms
│  ├─ Get Secret (cached): <1ms
│  ├─ Database Connection: 30ms
│  └─ Query Execution: 15ms
└─ Total Duration: 45ms

## Best Practices

### Security Best Practices

✅ **Least Privilege IAM**: Minimal permissions for Lambda role
✅ **VPC Integration**: Private network access when possible
✅ **Encryption in Transit**: TLS for all connections
✅ **No Hardcoded Secrets**: Always use Secrets Manager
✅ **Audit Logging**: Enable CloudTrail and CloudWatch
✅ **Secret Rotation**: Implement rotation handling
✅ **Error Handling**: Don't expose secrets in logs
✅ **Memory Cleanup**: Clear sensitive data after use

### Performance Best Practices

✅ **Cache Secrets**: Reduce API calls and latency
✅ **Appropriate TTL**: Balance freshness and performance
✅ **Connection Pooling**: Reuse database connections
✅ **Provisioned Concurrency**: Eliminate cold starts
✅ **VPC Endpoints**: Reduce network latency
✅ **Right-size Memory**: Adequate resources for caching
✅ **Monitor Metrics**: Track cache hit rates

### Operational Best Practices

✅ **Environment Variables**: Configure secret names
✅ **Error Handling**: Graceful failure and retry
✅ **Logging**: Structured logs for debugging
✅ **Monitoring**: CloudWatch alarms for failures
✅ **Testing**: Unit and integration tests
✅ **Documentation**: Code comments and README
✅ **Version Control**: Track function changes

## Cost Optimization

### Cost Breakdown

Monthly Cost Example (1M invocations):

Lambda:
├─ Compute: $0.20 (128MB, 100ms avg)
├─ Requests: $0.20 (1M requests)
└─ Subtotal: $0.40

Secrets Manager:
├─ Secret storage: $0.40 (1 secret)
├─ API calls: $0.50 (100K calls with caching)
└─ Subtotal: $0.90

KMS:
├─ Key: $1.00
├─ API calls: $0.03 (10K decrypt calls)
└─ Subtotal: $1.03

Total: $2.33/month

Without Caching:
├─ Secrets Manager API: $5.00 (1M calls)
├─ KMS API: $0.30 (100K decrypts)
└─ Total: $6.70/month

Savings with Caching: $4.37/month (65%)

## Additional Resources

- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [Secrets Manager with Lambda](https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieving-secrets_lambda.html)
- [Lambda Execution Role](https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html)
- [VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)

