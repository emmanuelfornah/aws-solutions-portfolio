import json
import boto3

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Items')

def lambda_handler(event, context):
    """
    Lambda function to delete an item from DynamoDB
    
    Expected event structure (API Gateway AWS_PROXY):
    {
        "pathParameters": {
            "id": "item-001"
        },
        "httpMethod": "DELETE",
        ...
    }
    
    Returns:
        HTTP response with status code and deletion confirmation
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
        
        # Check if item exists before deleting
        get_response = table.get_item(Key={'id': item_id})
        
        if 'Item' not in get_response:
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
        
        # Delete item from DynamoDB
        table.delete_item(Key={'id': item_id})
        
        # Return success response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Item deleted successfully',
                'id': item_id
            })
        }
        
    except Exception as e:
        print(f"Error deleting item: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': 'Internal server error'})
        }
