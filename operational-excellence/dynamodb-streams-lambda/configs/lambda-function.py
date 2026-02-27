import json
import boto3
from datetime import datetime

def lambda_handler(event, context):
    """
    Process DynamoDB Stream events
    Handles INSERT, MODIFY, and REMOVE events
    """
    
    print(f"Processing {len(event['Records'])} stream records")
    
    for record in event['Records']:
        event_name = record['eventName']
        event_id = record['eventID']
        
        print(f"Event: {event_name} | ID: {event_id}")
        
        if event_name == 'INSERT':
            handle_insert(record)
        elif event_name == 'MODIFY':
            handle_modify(record)
        elif event_name == 'REMOVE':
            handle_remove(record)
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Processed {len(event["Records"])} records')
    }

def handle_insert(record):
    """Handle INSERT events"""
    new_image = record['dynamodb']['NewImage']
    
    # Extract data from DynamoDB format
    user_id = new_image.get('UserId', {}).get('S')
    email = new_image.get('Email', {}).get('S')
    
    print(f"INSERT: New user created - UserId: {user_id}, Email: {email}")
    
    # Add your business logic here
    # Example: Send welcome email, update analytics, etc.

def handle_modify(record):
    """Handle MODIFY events"""
    old_image = record['dynamodb']['OldImage']
    new_image = record['dynamodb']['NewImage']
    
    user_id = new_image.get('UserId', {}).get('S')
    
    print(f"MODIFY: User updated - UserId: {user_id}")
    
    # Compare old and new values
    # Add your business logic here
    # Example: Audit log, trigger notifications, etc.

def handle_remove(record):
    """Handle REMOVE events (including TTL expiration)"""
    old_image = record['dynamodb']['OldImage']
    
    user_id = old_image.get('UserId', {}).get('S')
    
    # Check if this is a TTL expiration
    user_identity = record.get('userIdentity')
    if user_identity and user_identity.get('type') == 'Service' and user_identity.get('principalId') == 'dynamodb.amazonaws.com':
        print(f"REMOVE (TTL): Item expired - UserId: {user_id}")
    else:
        print(f"REMOVE: Item deleted - UserId: {user_id}")
    
    # Add your business logic here
    # Example: Archive data, cleanup related resources, etc.
