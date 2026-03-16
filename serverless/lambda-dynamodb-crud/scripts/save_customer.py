"""
Save Customer Lambda Function
Adds a new customer to DynamoDB table
"""

import json
import boto3
import os
import uuid
from datetime import datetime

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')

# Get table name from environment variable
TABLE_NAME = os.environ.get('TABLE_NAME', 'Customers')
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    """
    Save a new customer to DynamoDB table
    
    Args:
        event: Lambda event object with customer data
        context: Lambda context object
        
    Returns:
        API Gateway response with saved customer
    """
    
    try:
        # Parse request body
        if 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event
        
        # Validate required fields
        required_fields = ['name', 'email']
        for field in required_fields:
            if field not in body:
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({
                        'error': f'Missing required field: {field}'
                    })
                }
        
        # Generate customer ID
        customer_id = str(uuid.uuid4())
        
        # Create customer item
        customer = {
            'customerId': customer_id,
            'name': body['name'],
            'email': body['email'],
            'phone': body.get('phone', ''),
            'address': body.get('address', ''),
            'createdAt': datetime.utcnow().isoformat(),
            'status': 'active'
        }
        
        print(f"Saving customer: {customer_id}")
        
        # Save to DynamoDB
        table.put_item(Item=customer)
        
        print(f"Customer saved successfully: {customer_id}")
        
        # Return success response
        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'message': 'Customer created successfully',
                'customer': customer
            })
        }
        
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Invalid JSON in request body'
            })
        }
    
    except Exception as e:
        print(f"Error saving customer: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Failed to save customer',
                'message': str(e)
            })
        }
