"""
AWS Lambda URL Checker Function

This Lambda function checks the availability of a given URL by making an HTTP GET request.
It returns the HTTP status code and handles various error conditions including timeouts,
connection errors, and invalid URLs.

Event Payload Format:
{
    "url": "https://example.com"
}

Response Format:
{
    "statusCode": 200,
    "body": {
        "url": "https://example.com",
        "status": "success",
        "http_status": 200,
        "message": "URL is reachable"
    }
}
"""

import json
import requests
from requests.exceptions import RequestException, Timeout, ConnectionError, HTTPError


def lambda_handler(event, context):
    """
    Lambda handler function for URL checking.
    
    Args:
        event (dict): Lambda event containing 'url' key
        context (object): Lambda context object (unused)
    
    Returns:
        dict: Response with statusCode and body containing check results
    """
    
    # Extract URL from event payload
    url = event.get('url')
    
    # Validate URL presence
    if not url:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'status': 'error',
                'message': 'Missing required parameter: url'
            })
        }
    
    print(f"Checking URL: {url}")
    
    try:
        # Make HTTP GET request with timeout
        response = requests.get(url, timeout=5)
        
        # Raise exception for 4xx/5xx status codes
        response.raise_for_status()
        
        # Success case
        result = {
            'url': url,
            'status': 'success',
            'http_status': response.status_code,
            'message': 'URL is reachable'
        }
        
        print(f"Success: {url} returned status {response.status_code}")
        
        return {
            'statusCode': 200,
            'body': result
        }
        
    except Timeout:
        # Handle request timeout
        error_msg = f"Request timeout: URL did not respond within 5 seconds"
        print(f"Timeout error for {url}")
        
        return {
            'statusCode': 500,
            'body': {
                'url': url,
                'status': 'error',
                'message': error_msg
            }
        }
        
    except ConnectionError as e:
        # Handle connection errors (DNS failure, refused connection, etc.)
        error_msg = f"Connection error: {str(e)}"
        print(f"Connection error for {url}: {str(e)}")
        
        return {
            'statusCode': 500,
            'body': {
                'url': url,
                'status': 'error',
                'message': error_msg
            }
        }
        
    except HTTPError as e:
        # Handle HTTP errors (4xx, 5xx status codes)
        error_msg = f"HTTP error: {response.status_code} - {str(e)}"
        print(f"HTTP error for {url}: {response.status_code}")
        
        return {
            'statusCode': 500,
            'body': {
                'url': url,
                'status': 'error',
                'http_status': response.status_code,
                'message': error_msg
            }
        }
        
    except RequestException as e:
        # Handle all other request exceptions
        error_msg = f"Request error: {str(e)}"
        print(f"Request error for {url}: {str(e)}")
        
        return {
            'statusCode': 500,
            'body': {
                'url': url,
                'status': 'error',
                'message': error_msg
            }
        }
        
    except Exception as e:
        # Handle unexpected errors
        error_msg = f"Unexpected error: {str(e)}"
        print(f"Unexpected error for {url}: {str(e)}")
        
        return {
            'statusCode': 500,
            'body': {
                'url': url,
                'status': 'error',
                'message': error_msg
            }
        }


# Local testing
if __name__ == "__main__":
    # Test with valid URL
    test_event_valid = {
        "url": "https://aws.amazon.com"
    }
    
    print("Testing with valid URL:")
    result = lambda_handler(test_event_valid, None)
    print(json.dumps(result, indent=2))
    
    print("\n" + "="*50 + "\n")
    
    # Test with invalid URL
    test_event_invalid = {
        "url": "https://invalid-domain-that-does-not-exist-12345.com"
    }
    
    print("Testing with invalid URL:")
    result = lambda_handler(test_event_invalid, None)
    print(json.dumps(result, indent=2))
    
    print("\n" + "="*50 + "\n")
    
    # Test with missing URL
    test_event_missing = {}
    
    print("Testing with missing URL:")
    result = lambda_handler(test_event_missing, None)
    print(json.dumps(result, indent=2))
