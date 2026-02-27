# Lambda Function: Flashcard Generator with Amazon Bedrock

import json
import boto3
import re
from botocore.exceptions import ClientError

# Initialize Bedrock client
bedrock_runtime = boto3.client('bedrock-runtime')

# System prompt for flashcard generation
SYSTEM_PROMPT = """
You are a flashcard generator. Convert study notes into flashcards for effective learning.

Output Format (JSON array only, no additional text):
[
  {
    "question": "Clear, specific question testing a key concept",
    "answer": "Concise, accurate answer (1-2 sentences)"
  }
]

Rules:
- Generate 5-10 flashcards based on content length
- Questions should test understanding, not just memorization
- Answers should be clear and concise
- Cover the most important concepts
- Output ONLY valid JSON array, no markdown or explanations
"""

def lambda_handler(event, context):
    """
    Lambda handler for flashcard generation.
    
    Expected input:
    {
      "body": "{\"notes\": \"Study notes text here\"}"
    }
    
    Returns:
    {
      "statusCode": 200,
      "body": "{\"flashcards\": [...], \"count\": 5}"
    }
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        notes = body.get('notes', '').strip()
        
        # Validate input
        if not notes:
            return create_response(400, {
                'error': 'Notes are required',
                'message': 'Please provide study notes to generate flashcards'
            })
        
        if len(notes) < 50:
            return create_response(400, {
                'error': 'Notes too short',
                'message': 'Please provide at least 50 characters of study notes'
            })
        
        # Generate flashcards
        flashcards = generate_flashcards(notes)
        
        if not flashcards:
            return create_response(500, {
                'error': 'Generation failed',
                'message': 'Could not generate flashcards. Please try again.'
            })
        
        # Return success response
        return create_response(200, {
            'flashcards': flashcards,
            'count': len(flashcards),
            'message': f'Successfully generated {len(flashcards)} flashcards'
        })
        
    except json.JSONDecodeError as e:
        return create_response(400, {
            'error': 'Invalid JSON',
            'message': 'Request body must be valid JSON'
        })
        
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        return create_response(500, {
            'error': 'Internal server error',
            'message': 'An unexpected error occurred'
        })


def generate_flashcards(notes):
    """
    Generate flashcards from study notes using Amazon Bedrock.
    
    Args:
        notes (str): Study notes text
    
    Returns:
        list: Array of flashcard objects
    """
    try:
        # Create prompt
        prompt = f"""
{SYSTEM_PROMPT}

Study Notes:
{notes}

Flashcards (JSON array):
"""
        
        # Prepare request body
        request_body = {
            'prompt': prompt,
            'temperature': 0.3,  # Low for consistent JSON output
            'topP': 0.9,
            'maxTokens': 2000
        }
        
        # Invoke Bedrock model
        response = bedrock_runtime.invoke_model(
            modelId='amazon.nova-lite-v1:0',
            body=json.dumps(request_body)
        )
        
        # Parse response
        response_body = json.loads(response['body'].read())
        generated_text = response_body['results'][0]['outputText']
        
        # Parse flashcards from response
        flashcards = parse_flashcards(generated_text)
        
        # Validate flashcards
        if not validate_flashcards(flashcards):
            print("Invalid flashcard format")
            return None
        
        return flashcards
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        print(f"Bedrock error ({error_code}): {str(e)}")
        return None
        
    except Exception as e:
        print(f"Error generating flashcards: {str(e)}")
        return None


def parse_flashcards(generated_text):
    """
    Parse flashcards from LLM response, handling various formats.
    
    Args:
        generated_text (str): Raw LLM output
    
    Returns:
        list: Parsed flashcard array
    """
    try:
        # Try direct JSON parse
        return json.loads(generated_text)
        
    except json.JSONDecodeError:
        # Try to extract JSON from markdown code blocks
        json_match = re.search(
            r'```(?:json)?\n?(.*?)\n?```',
            generated_text,
            re.DOTALL
        )
        
        if json_match:
            try:
                return json.loads(json_match.group(1))
            except json.JSONDecodeError:
                pass
        
        # Try to find JSON array in text
        array_match = re.search(
            r'\[\s*\{.*?\}\s*\]',
            generated_text,
            re.DOTALL
        )
        
        if array_match:
            try:
                return json.loads(array_match.group(0))
            except json.JSONDecodeError:
                pass
        
        print(f"Could not parse JSON from: {generated_text[:200]}")
        return None


def validate_flashcards(flashcards):
    """
    Validate flashcard structure and content.
    
    Args:
        flashcards (list): Array of flashcard objects
    
    Returns:
        bool: True if valid, False otherwise
    """
    if not isinstance(flashcards, list):
        return False
    
    if len(flashcards) == 0:
        return False
    
    for card in flashcards:
        if not isinstance(card, dict):
            return False
        
        if 'question' not in card or 'answer' not in card:
            return False
        
        if not isinstance(card['question'], str) or not isinstance(card['answer'], str):
            return False
        
        if len(card['question'].strip()) == 0 or len(card['answer'].strip()) == 0:
            return False
    
    return True


def create_response(status_code, body):
    """
    Create API Gateway response with CORS headers.
    
    Args:
        status_code (int): HTTP status code
        body (dict): Response body
    
    Returns:
        dict: API Gateway response object
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST,OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': json.dumps(body)
    }
