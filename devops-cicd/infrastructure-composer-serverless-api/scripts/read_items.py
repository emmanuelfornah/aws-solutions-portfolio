import json
import boto3
from decimal import Decimal

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Items')

def lambda_handler(event, context):
    """
    Lambda function to retrieve all items from DynamoDB
    
    Expected event structure (API Gateway AWS_PROXY):
    {
        "httpMethod": "GET",
        "queryStringParameters": {
            "limit": "10",  # Optional: limit number of items
            "lastKey": "..."  # Optional: for pagination
        },
        ...
    }
    
    Returns:
        HTTP response with status code and array of items
    """
    
    try:
        # Get query parameters for pagination
        query_params = event.get('queryStringParameters') or {}
        limit = int(query_params.get('limit', 100))  # Default limit 100
        
        # Prepare scan parameters
        scan_params = {
            'Limit': limit
        }
        
        # Handle pagination with LastEvaluatedKey
        if 'lastKey' in query_params:
            try:
                last_key = json.loads(query_params['lastKey'])
                scan_params['ExclusiveStartKey'] = last_key
            except json.JSONDecodeError:
                pass  # Ignore invalid lastKey
        
        # Scan DynamoDB table
        response = table.scan(**scan_params)
        
        # Get items from response
        items = response.get('Items', [])
        
        # Convert Decimal to float for JSON serialization
        items = [convert_decimal_to_float(item) for item in items]
        
        # Prepare response body
        response_body = {
            'items': items,
            'count': len(items)
        }
        
        # Include pagination info if there are more items
        if 'LastEvaluatedKey' in response:
            response_body['lastKey'] = response['LastEvaluatedKey']
            response_body['hasMore'] = True
        else:
            response_body['hasMore'] = False
        
        # Return success response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(response_body)
        }
        
    except ValueError as e:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': f'Invalid limit parameter: {str(e)}'})
        }
        
    except Exception as e:
        print(f"Error reading items: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': 'Internal server error'})
        }

def convert_decimal_to_float(obj):
    """
    Convert Decimal values to float for JSON serialization
    DynamoDB returns numbers as Decimal, which JSON can't serialize
    """
    if isinstance(obj, dict):
        return {k: convert_decimal_to_float(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_decimal_to_float(item) for item in obj]
    elif isinstance(obj, Decimal):
        return float(obj)
    else:
        return obj
