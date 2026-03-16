"""
WebSocket Disconnect Handler
Cleans up connection records when clients disconnect
"""

import json
import boto3
import os

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')

# Environment variables
CONNECTIONS_TABLE = os.environ.get('CONNECTIONS_TABLE', 'WebSocketConnections')

# DynamoDB table
connections_table = dynamodb.Table(CONNECTIONS_TABLE)

def lambda_handler(event, context):
    """
    Handle WebSocket disconnection requests
    
    Args:
        event: API Gateway WebSocket $disconnect event
        context: Lambda context object
        
    Returns:
        Response indicating disconnection handling success
    """
    
    try:
        # Get connection ID from event
        connection_id = event['requestContext']['connectionId']
        
        print(f"WebSocket disconnection: {connection_id}")
        
        # Remove connection from DynamoDB
        connections_table.delete_item(
            Key={'connectionId': connection_id}
        )
        
        print(f"Connection {connection_id} removed from DynamoDB")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Disconnected successfully'
            })
        }
        
    except Exception as e:
        print(f"Error handling disconnection: {str(e)}")
        # Return success even if cleanup fails to avoid client errors
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Disconnection acknowledged'
            })
        }
