"""
WebSocket Notifier Lambda Function
Sends real-time updates to connected clients via WebSocket API
"""

import json
import boto3
import os

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
apigateway = boto3.client('apigatewaymanagementapi')

# Environment variables
CONNECTIONS_TABLE = os.environ.get('CONNECTIONS_TABLE', 'WebSocketConnections')
WEBSOCKET_ENDPOINT = os.environ.get('WEBSOCKET_ENDPOINT')

# DynamoDB table
connections_table = dynamodb.Table(CONNECTIONS_TABLE)

def lambda_handler(event, context):
    """
    Send order status updates to all connected WebSocket clients
    
    Args:
        event: EventBridge event with order status update
        context: Lambda context object
    """
    
    try:
        # Extract order details from event
        detail = event.get('detail', {})
        order_id = detail.get('orderId')
        status = detail.get('status')
        message = detail.get('message')
        
        print(f"Sending notification for order {order_id}: {status}")
        
        # Get all active WebSocket connections
        response = connections_table.scan()
        connections = response.get('Items', [])
        
        if not connections:
            print("No active WebSocket connections")
            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'No active connections'})
            }
        
        # Prepare notification message
        notification = {
            'type': 'ORDER_UPDATE',
            'orderId': order_id,
            'status': status,
            'message': message,
            'timestamp': detail.get('timestamp')
        }
        
        # Configure API Gateway Management API client with WebSocket endpoint
        if WEBSOCKET_ENDPOINT:
            apigateway_client = boto3.client(
                'apigatewaymanagementapi',
                endpoint_url=WEBSOCKET_ENDPOINT
            )
        else:
            apigateway_client = apigateway
        
        # Send message to all connected clients
        stale_connections = []
        
        for connection in connections:
            connection_id = connection['connectionId']
            
            try:
                apigateway_client.post_to_connection(
                    ConnectionId=connection_id,
                    Data=json.dumps(notification).encode('utf-8')
                )
                print(f"Sent notification to connection {connection_id}")
                
            except apigateway_client.exceptions.GoneException:
                # Connection is stale, mark for deletion
                print(f"Connection {connection_id} is stale")
                stale_connections.append(connection_id)
                
            except Exception as e:
                print(f"Error sending to connection {connection_id}: {str(e)}")
        
        # Clean up stale connections
        for connection_id in stale_connections:
            try:
                connections_table.delete_item(
                    Key={'connectionId': connection_id}
                )
                print(f"Deleted stale connection {connection_id}")
            except Exception as e:
                print(f"Error deleting connection {connection_id}: {str(e)}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Notifications sent',
                'activeConnections': len(connections) - len(stale_connections),
                'staleConnections': len(stale_connections)
            })
        }
        
    except Exception as e:
        print(f"Error sending notifications: {str(e)}")
        raise
