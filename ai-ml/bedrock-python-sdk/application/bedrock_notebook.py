# Amazon Bedrock Python SDK Examples
# Jupyter Notebook code for working with foundation models

import boto3
import json
import base64
from datetime import datetime
from botocore.exceptions import ClientError

# Initialize AWS clients
bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-east-1')
s3 = boto3.client('s3')
rekognition = boto3.client('rekognition')

# Configuration
BUCKET_NAME = '[BUCKET-NAME]'  # Replace with your S3 bucket name

# ============================================================================
# TEXT GENERATION FUNCTIONS
# ============================================================================

def generate_text(prompt, model_id='amazon.nova-lite-v1:0', 
                  temperature=0.7, max_tokens=512):
    """
    Generate text using Amazon Bedrock foundation models.
    
    Args:
        prompt (str): Input prompt for text generation
        model_id (str): Foundation model identifier
        temperature (float): Creativity parameter (0.0-1.0)
        max_tokens (int): Maximum response length
    
    Returns:
        str: Generated text response
    """
    try:
        request_body = {
            'prompt': prompt,
            'temperature': temperature,
            'topP': 0.9,
            'maxTokens': max_tokens
        }
        
        response = bedrock_runtime.invoke_model(
            modelId=model_id,
            body=json.dumps(request_body)
        )
        
        response_body = json.loads(response['body'].read())
        return response_body['results'][0]['outputText']
        
    except ClientError as e:
        print(f"Error generating text: {str(e)}")
        return None


def generate_text_streaming(prompt, model_id='amazon.nova-lite-v1:0'):
    """
    Generate text with streaming response for better UX.
    
    Args:
        prompt (str): Input prompt
        model_id (str): Foundation model identifier
    
    Yields:
        str: Text chunks as they're generated
    """
    try:
        request_body = {
            'prompt': prompt,
            'temperature': 0.7,
            'maxTokens': 512
        }
        
        response = bedrock_runtime.invoke_model_with_response_stream(
            modelId=model_id,
            body=json.dumps(request_body)
        )
        
        for event in response['body']:
            chunk = json.loads(event['chunk']['bytes'])
            if 'outputText' in chunk:
                yield chunk['outputText']
                
    except ClientError as e:
        print(f"Error in streaming: {str(e)}")


# ============================================================================
# IMAGE GENERATION FUNCTIONS
# ============================================================================

def generate_image(prompt, height=512, width=512, quality='standard'):
    """
    Generate image using Amazon Nova Canvas.
    
    Args:
        prompt (str): Image generation prompt
        height (int): Image height in pixels
        width (int): Image width in pixels
        quality (str): 'standard' or 'premium'
    
    Returns:
        bytes: Image data
    """
    try:
        request_body = {
            'taskType': 'TEXT_IMAGE',
            'textToImageParams': {
                'text': prompt
            },
            'imageGenerationConfig': {
                'numberOfImages': 1,
                'quality': quality,
                'height': height,
                'width': width
            }
        }
        
        response = bedrock_runtime.invoke_model(
            modelId='amazon.nova-canvas-v1:0',
            body=json.dumps(request_body)
        )
        
        response_body = json.loads(response['body'].read())
        image_base64 = response_body['images'][0]
        image_data = base64.b64decode(image_base64)
        
        return image_data
        
    except ClientError as e:
        print(f"Error generating image: {str(e)}")
        return None


def save_image_to_s3(image_data, bucket_name, prefix='generated_images'):
    """
    Save image data to S3 bucket.
    
    Args:
        image_data (bytes): Image binary data
        bucket_name (str): S3 bucket name
        prefix (str): S3 key prefix
    
    Returns:
        str: S3 object key
    """
    try:
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        object_key = f'{prefix}/{timestamp}.png'
        
        s3.put_object(
            Bucket=bucket_name,
            Key=object_key,
            Body=image_data,
            ContentType='image/png'
        )
        
        print(f"Image saved to s3://{bucket_name}/{object_key}")
        return object_key
        
    except ClientError as e:
        print(f"Error saving to S3: {str(e)}")
        return None


# ============================================================================
# MULTI-SERVICE INTEGRATION
# ============================================================================

def analyze_generated_image(prompt):
    """
    Generate image, analyze with Rekognition, create AI description.
    
    Args:
        prompt (str): Image generation prompt
    
    Returns:
        dict: Complete analysis results
    """
    try:
        # Step 1: Generate image with Bedrock
        print("Generating image...")
        image_data = generate_image(prompt)
        
        if not image_data:
            return None
        
        # Step 2: Analyze with Rekognition
        print("Analyzing image with Rekognition...")
        rekog_response = rekognition.detect_labels(
            Image={'Bytes': image_data},
            MaxLabels=10,
            MinConfidence=75
        )
        
        labels = [
            {
                'name': label['Name'],
                'confidence': label['Confidence']
            }
            for label in rekog_response['Labels']
        ]
        
        label_names = [label['name'] for label in labels]
        
        # Step 3: Generate description with Bedrock
        print("Generating AI description...")
        description_prompt = f"""
        An AI generated an image with this prompt: "{prompt}"
        
        Amazon Rekognition detected these labels: {', '.join(label_names)}
        
        Write a 2-sentence description of what the image likely contains.
        """
        
        description = generate_text(
            prompt=description_prompt,
            temperature=0.5,
            max_tokens=200
        )
        
        # Step 4: Save to S3
        print("Saving to S3...")
        object_key = save_image_to_s3(image_data, BUCKET_NAME)
        
        return {
            'original_prompt': prompt,
            'detected_labels': labels,
            'ai_description': description,
            's3_location': f's3://{BUCKET_NAME}/{object_key}',
            'image_data': image_data
        }
        
    except Exception as e:
        print(f"Error in analysis pipeline: {str(e)}")
        return None


# ============================================================================
# COST ESTIMATION
# ============================================================================

def estimate_cost(input_tokens, output_tokens, model_id):
    """
    Estimate cost for Bedrock API call.
    
    Args:
        input_tokens (int): Number of input tokens
        output_tokens (int): Number of output tokens
        model_id (str): Model identifier
    
    Returns:
        dict: Cost breakdown
    """
    # Pricing per 1K tokens (example rates)
    pricing = {
        'amazon.nova-lite-v1:0': {
            'input': 0.00006,
            'output': 0.00024
        },
        'amazon.nova-pro-v1:0': {
            'input': 0.0008,
            'output': 0.0032
        },
        'meta.llama3-8b-instruct-v1:0': {
            'input': 0.0003,
            'output': 0.0006
        }
    }
    
    rates = pricing.get(model_id, pricing['amazon.nova-lite-v1:0'])
    
    input_cost = (input_tokens / 1000) * rates['input']
    output_cost = (output_tokens / 1000) * rates['output']
    
    return {
        'input_tokens': input_tokens,
        'output_tokens': output_tokens,
        'input_cost': f'${input_cost:.6f}',
        'output_cost': f'${output_cost:.6f}',
        'total_cost': f'${(input_cost + output_cost):.6f}'
    }


# ============================================================================
# EXAMPLE USAGE
# ============================================================================

if __name__ == '__main__':
    # Example 1: Simple text generation
    print("=== Example 1: Text Generation ===")
    result = generate_text(
        prompt="Explain AWS Lambda in 2 sentences",
        temperature=0.5
    )
    print(f"Result: {result}\n")
    
    # Example 2: Streaming text generation
    print("=== Example 2: Streaming Text ===")
    print("Response: ", end='')
    for chunk in generate_text_streaming(
        prompt="Write a haiku about cloud computing"
    ):
        print(chunk, end='', flush=True)
    print("\n")
    
    # Example 3: Image generation
    print("=== Example 3: Image Generation ===")
    image_data = generate_image(
        prompt="A futuristic cloud computing data center with glowing servers"
    )
    if image_data:
        print(f"Generated image: {len(image_data)} bytes\n")
    
    # Example 4: Multi-service integration
    print("=== Example 4: Complete Analysis Pipeline ===")
    analysis = analyze_generated_image(
        prompt="A serene mountain landscape at sunset"
    )
    if analysis:
        print(f"Prompt: {analysis['original_prompt']}")
        print(f"Labels: {[l['name'] for l in analysis['detected_labels']]}")
        print(f"Description: {analysis['ai_description']}")
        print(f"S3 Location: {analysis['s3_location']}\n")
    
    # Example 5: Cost estimation
    print("=== Example 5: Cost Estimation ===")
    cost = estimate_cost(
        input_tokens=100,
        output_tokens=500,
        model_id='amazon.nova-lite-v1:0'
    )
    print(f"Cost breakdown: {json.dumps(cost, indent=2)}")
