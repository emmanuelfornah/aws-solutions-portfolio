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
    Demonstrates secure secret retrieval and usage
    """
    try:
        # Get configuration from environment variables
        secret_name = os.environ.get('SECRET_NAME', 'db-credentials')
        cache_ttl = int(os.environ.get('CACHE_TTL', '300'))
        
        print(f"Function invoked - Request ID: {context.request_id}")
        print(f"Secret name: {secret_name}, Cache TTL: {cache_ttl}s")
        
        # Retrieve secret (with caching)
        secret = get_secret(secret_name, ttl=cache_ttl)
        
        # Example: Use secret to connect to database
        # In production, you would use the actual database library
        print(f"Secret retrieved - Host: {secret.get('host', 'N/A')}")
        print(f"Connecting to database...")
        
        # Simulate database operation
        result = {
            'connected': True,
            'host': secret.get('host', 'N/A'),
            'database': secret.get('dbname', 'N/A'),
            'user': secret.get('username', 'N/A')
        }
        
        print(f"Database operation successful")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Successfully accessed secure data',
                'result': result,
                'request_id': context.request_id
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'request_id': context.request_id
            })
        }
