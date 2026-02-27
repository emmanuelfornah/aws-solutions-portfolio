"""
WebSocket Connect Handler
Manages WebSocket connection establishment and stores connection IDs
"""

import json
import boto3
import os
from datetime import datetime, timedelta

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')

# Environment variables
CONNECTIONS_TABLE = os.environ.get('CONNECTIONS_TABLE', 'WebSocketConnections')

# DynamoDB table
connections_table = dynamodb.Table(CONNECTIONS_TABLE)

def lambda_handler(event, context):
    """
    Handle WebSocket connection requests
    
    Args:
        event: API Gateway WebSocket $connect event
        context: Lambda context object
        
    Returns:
        Response indicating connection success or failure
    """
    
    try:
        # Get connection ID from event
        connection_id = event['requestContext']['connectionId']
        
        print(f"New WebSocket connection: {connection_id}")
        
        # Calculate TTL (24 hours from now)
        ttl = int((datetime.utcnow() + timedelta(hours=24)).timestamp())
        
        # Store connection in DynamoDB
        connections_table.put_item(
            Item={
                'connectionId': connection_id,
                'connectedAt': datetime.utcnow().isoformat(),
                'ttl': ttl
            }
        )
        
        print(f"Connection {connection_id} stored in DynamoDB")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Connected successfully'
            })
        }
        
    except Exception as e:
        print(f"Error handling connection: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Failed to establish connection'
            })
        }
