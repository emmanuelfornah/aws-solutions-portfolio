"""
List Customers Lambda Function
Retrieves all customers from DynamoDB table
"""

import json
import boto3
import os
from decimal import Decimal

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')

# Get table name from environment variable
TABLE_NAME = os.environ.get('TABLE_NAME', 'Customers')
table = dynamodb.Table(TABLE_NAME)

class DecimalEncoder(json.JSONEncoder):
    """Helper class to convert DynamoDB Decimal types to JSON"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    """
    List all customers from DynamoDB table
    
    Args:
        event: Lambda event object
        context: Lambda context object
        
    Returns:
        API Gateway response with customer list
    """
    
    try:
        print(f"Scanning table: {TABLE_NAME}")
        
        # Scan DynamoDB table
        response = table.scan()
        customers = response.get('Items', [])
        
        # Handle pagination if needed
        while 'LastEvaluatedKey' in response:
            response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
            customers.extend(response.get('Items', []))
        
        print(f"Found {len(customers)} customers")
        
        # Return success response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET,OPTIONS'
            },
            'body': json.dumps({
                'customers': customers,
                'count': len(customers)
            }, cls=DecimalEncoder)
        }
        
    except Exception as e:
        print(f"Error listing customers: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Failed to retrieve customers',
                'message': str(e)
            })
        }
