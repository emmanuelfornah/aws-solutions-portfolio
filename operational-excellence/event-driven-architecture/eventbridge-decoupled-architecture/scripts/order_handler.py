"""
Order Handler Lambda Function
Receives pizza orders via HTTP API and publishes events to EventBridge
"""

import json
import boto3
import os
from datetime import datetime
import uuid

# Initialize AWS clients
eventbridge = boto3.client('events')

# Environment variables
EVENT_BUS_NAME = os.environ.get('EVENT_BUS_NAME', 'pizza-orders-bus')

def lambda_handler(event, context):
    """
    Handle incoming pizza orders and publish to EventBridge
    
    Args:
        event: API Gateway HTTP API event
        context: Lambda context object
        
    Returns:
        API Gateway response with order confirmation
    """
    
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        
        # Validate required fields
        required_fields = ['pizzaType', 'size']
        for field in required_fields:
            if field not in body:
                return {
                    'statusCode': 400,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'error': f'Missing required field: {field}'
                    })
                }
        
        # Generate order ID
        order_id = str(uuid.uuid4())
        
        # Create order object
        order = {
            'orderId': order_id,
            'pizzaType': body['pizzaType'],
            'size': body['size'],
            'toppings': body.get('toppings', []),
            'timestamp': datetime.utcnow().isoformat(),
            'status': 'RECEIVED'
        }
        
        # Publish event to EventBridge
        response = eventbridge.put_events(
            Entries=[
                {
                    'Source': 'pizza.orders',
                    'DetailType': 'Order Placed',
                    'Detail': json.dumps(order),
                    'EventBusName': EVENT_BUS_NAME
                }
            ]
        )
        
        # Check if event was published successfully
        if response['FailedEntryCount'] > 0:
            print(f"Failed to publish event: {response['Entries']}")
            return {
                'statusCode': 500,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'error': 'Failed to process order'
                })
            }
        
        print(f"Order {order_id} published to EventBridge")
        
        # Return success response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Order received successfully',
                'orderId': order_id,
                'order': order
            })
        }
        
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'error': 'Invalid JSON in request body'
            })
        }
    
    except Exception as e:
        print(f"Error processing order: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'error': 'Internal server error'
            })
        }
