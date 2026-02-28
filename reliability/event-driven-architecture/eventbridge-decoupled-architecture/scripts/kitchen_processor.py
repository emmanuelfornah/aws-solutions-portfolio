"""
Kitchen Processor Lambda Function
Processes pizza orders from EventBridge and simulates kitchen operations
"""

import json
import boto3
import os
import time

# Initialize AWS clients
eventbridge = boto3.client('events')

# Environment variables
EVENT_BUS_NAME = os.environ.get('EVENT_BUS_NAME', 'pizza-orders-bus')

def lambda_handler(event, context):
    """
    Process pizza orders and publish status updates
    
    Args:
        event: EventBridge event
        context: Lambda context object
    """
    
    try:
        # Extract order details from event
        detail = event.get('detail', {})
        order_id = detail.get('orderId')
        pizza_type = detail.get('pizzaType')
        size = detail.get('size')
        
        print(f"Processing order {order_id}: {size} {pizza_type}")
        
        # Simulate kitchen processing stages
        stages = [
            {'status': 'PREPARING', 'message': 'Preparing ingredients'},
            {'status': 'COOKING', 'message': 'Pizza in the oven'},
            {'status': 'READY', 'message': 'Order ready for pickup'}
        ]
        
        for stage in stages:
            # Publish status update event
            update_event = {
                'orderId': order_id,
                'pizzaType': pizza_type,
                'size': size,
                'status': stage['status'],
                'message': stage['message']
            }
            
            response = eventbridge.put_events(
                Entries=[
                    {
                        'Source': 'pizza.kitchen',
                        'DetailType': 'Order Status Update',
                        'Detail': json.dumps(update_event),
                        'EventBusName': EVENT_BUS_NAME
                    }
                ]
            )
            
            print(f"Published status update: {stage['status']}")
            
            # Simulate processing time (in real scenario, this would be actual work)
            # Note: In production, use Step Functions for long-running workflows
            time.sleep(2)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Order {order_id} processed successfully'
            })
        }
        
    except Exception as e:
        print(f"Error processing order: {str(e)}")
        # In production, send to DLQ or error handling service
        raise
