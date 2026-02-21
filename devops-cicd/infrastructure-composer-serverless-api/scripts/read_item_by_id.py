import json
import boto3
from decimal import Decimal

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Items')

def lambda_handler(event, context):
    """
    Lambda function to retrieve a specific item by ID from DynamoDB
    
    Expected event structure (API Gateway AWS_PROXY):
    {
        "pathParameters": {
            "id": "item-001"
        },
        "httpMethod": "GET",
        ...
    }
    
    Returns:
        HTTP response with status code and item (or 404 if not found)
    """
    
    try:
        # Extract item ID from path parameters
        path_params = event.get('pathParameters') or {}
        item_id = path_params.get('id')
        
        if not item_id:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Item ID is required in path'})
            }
        
        # Get item from DynamoDB
        response = table.get_item(
            Key={'id': item_id}
        )
        
        # Check if item exists
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Item not found',
                    'id': item_id
                })
            }
        
        # Get item and convert Decimal to float
        item = convert_decimal_to_float(response['Item'])
        
        # Return success response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'item': item})
        }
        
    except Exception as e:
        print(f"Error reading item: {str(e)}")
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
