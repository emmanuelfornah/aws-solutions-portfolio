"""
Lambda Function Handler for API Gateway Proxy Integration

This function handles HTTP requests from API Gateway and returns
a greeting message with the requested path information.
"""

import json


def handler(event, context):
    """
    Lambda function handler for API Gateway proxy integration.
    
    Args:
        event (dict): API Gateway proxy event containing request details
        context (object): Lambda context object with runtime information
    
    Returns:
        dict: API Gateway proxy response with statusCode, headers, and body
    """
    # Extract request information from API Gateway event
    path = event.get('path', '/')
    http_method = event.get('httpMethod', 'UNKNOWN')
    query_params = event.get('queryStringParameters', {})
    
    # Construct greeting message
    message = f"Hello from Lambda! You requested: {path}"
    
    # Add query parameter information if present
    if query_params:
        message += f" with parameters: {query_params}"
    
    # Construct response body
    response_body = {
        'message': message,
        'method': http_method,
        'path': path,
        'timestamp': context.request_id
    }
    
    # Return API Gateway proxy response
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
        },
        'body': json.dumps(response_body, indent=2)
    }
