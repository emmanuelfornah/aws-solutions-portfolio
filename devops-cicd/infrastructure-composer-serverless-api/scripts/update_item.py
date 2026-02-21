import json
import boto3
from decimal import Decimal

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Items')

def lambda_handler(event, context):
    """
    Lambda function to update an existing item in DynamoDB
    
    Expected event structure (API Gateway AWS_PROXY):
    {
        "pathParameters": {
            "id": "item-001"
        },
        "body": "{\"name\": \"Updated Name\", \"price\": 1299.99}",
        "httpMethod": "PUT",
        ...
    }
    
    Returns:
        HTTP response with status code and updated item
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
        
        # Parse request body
        if not event.get('body'):
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Request body is required'})
            }
        
        # Parse JSON body
        body = json.loads(event['body'])
        
        # Remove 'id' from body if present (can't update partition key)
        body.pop('id', None)
        
        if not body:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'No attributes to update'})
            }
        
        # Build update expression and attribute values
        update_expression = "SET "
        expression_attribute_names = {}
        expression_attribute_values = {}
        
        for i, (key, value) in enumerate(body.items()):
            # Use attribute names to handle reserved keywords
            attr_name = f"#attr{i}"
            attr_value = f":val{i}"
            
            if i > 0:
                update_expression += ", "
            
            update_expression += f"{attr_name} = {attr_value}"
            expression_attribute_names[attr_name] = key
            
            # Convert float to Decimal for DynamoDB
            if isinstance(value, float):
                value = Decimal(str(value))
            
            expression_attribute_values[attr_value] = value
        
        # Update item in DynamoDB
        response = table.update_item(
            Key={'id': item_id},
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues='ALL_NEW'
        )
        
        # Get updated item
        updated_item = convert_decimal_to_float(response['Attributes'])
        
        # Return success response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Item updated successfully',
                'item': updated_item
            })
        }
        
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': 'Invalid JSON in request body'})
        }
        
    except Exception as e:
        print(f"Error updating item: {str(e)}")
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
