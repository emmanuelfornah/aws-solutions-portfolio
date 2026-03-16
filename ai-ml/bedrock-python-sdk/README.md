# Using AWS SDK for Python with Amazon Bedrock

## Overview

**Duration:** 60 minutes  
**Complexity:** Intermediate

Demonstrates using Boto3 SDK to interact with Amazon Bedrock programmatically — generating text and images, and integrating with other AWS services like S3 and Rekognition.

## AWS Services Used

- **Amazon Bedrock** - Foundation model API access
- **Amazon S3** - Storage for generated images
- **Amazon Rekognition** - Image analysis and labeling
- **Boto3** - AWS SDK for Python
- **Jupyter Notebook** - Interactive development environment

## Learning Objectives

1. Configure Bedrock development environment in Jupyter Notebook
2. Create parameterized functions to invoke foundation models
3. Generate text using Amazon Nova and Meta Llama models
4. Generate and save images with Amazon Nova Canvas
5. Integrate Bedrock with Rekognition for image analysis
6. Implement error handling for AI model invocations

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│              Python Application (Jupyter Notebook)            │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Boto3 Client Initialization                       │     │
│  │  bedrock_runtime = boto3.client('bedrock-runtime') │     │
│  │  s3 = boto3.client('s3')                           │     │
│  │  rekognition = boto3.client('rekognition')         │     │
│  └────────────────┬───────────────────────────────────┘     │
│                   │                                          │
│                   ▼                                          │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Text Generation Function                          │     │
│  │  def generate_text(prompt, model_id, params):      │     │
│  │      response = bedrock_runtime.invoke_model(...)  │     │
│  │      return response['body'].read()                │     │
│  └────────────────┬───────────────────────────────────┘     │
│                   │                                          │
│                   ▼                                          │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Image Generation Function                         │     │
│  │  def generate_image(prompt, params):               │     │
│  │      response = bedrock_runtime.invoke_model(...)  │     │
│  │      image_data = base64.b64decode(...)            │     │
│  │      return image_data                             │     │
│  └────────────────┬───────────────────────────────────┘     │
│                   │                                          │
│                   ▼                                          │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Multi-Service Integration                         │     │
│  │  1. Generate image with Bedrock                    │     │
│  │  2. Save to S3                                     │     │
│  │  3. Analyze with Rekognition                       │     │
│  │  4. Generate description with Bedrock              │     │
│  └────────────────────────────────────────────────────┘     │
│                                                               │
└───────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌───────────────────────────────────────────────────────────────┐
│                      AWS Services                              │
├───────────────────────────────────────────────────────────────┤
│  Amazon Bedrock  │  Amazon S3  │  Amazon Rekognition          │
└───────────────────────────────────────────────────────────────┘
```

## Key Concepts

### Boto3 Bedrock Client

**bedrock-runtime**: For model invocation
```python
import boto3
import json

bedrock_runtime = boto3.client(
    service_name='bedrock-runtime',
    region_name='us-east-1'
)
```

**invoke_model()**: Synchronous invocation
```python
response = bedrock_runtime.invoke_model(
    modelId='amazon.nova-lite-v1:0',
    body=json.dumps({
        'prompt': 'Your prompt here',
        'temperature': 0.7,
        'topP': 0.9,
        'maxTokens': 512
    })
)
```

**invoke_model_with_response_stream()**: Streaming responses
```python
response = bedrock_runtime.invoke_model_with_response_stream(
    modelId='amazon.nova-lite-v1:0',
    body=json.dumps({...})
)

for event in response['body']:
    chunk = json.loads(event['chunk']['bytes'])
    print(chunk['outputText'], end='')
```

### Model-Specific Request Formats

**Amazon Nova (Text)**:
```python
request_body = {
    'prompt': 'Your prompt',
    'temperature': 0.7,
    'topP': 0.9,
    'maxTokens': 512
}
```

**Meta Llama 3**:
```python
request_body = {
    'prompt': 'Your prompt',
    'temperature': 0.7,
    'top_p': 0.9,
    'max_gen_len': 512
}
```

**Amazon Nova Canvas (Image)**:
```python
request_body = {
    'taskType': 'TEXT_IMAGE',
    'textToImageParams': {
        'text': 'Your image prompt'
    },
    'imageGenerationConfig': {
        'numberOfImages': 1,
        'quality': 'standard',
        'height': 512,
        'width': 512
    }
}
```

## Sample Code

### Text Generation Function

```python
import boto3
import json

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
        bedrock_runtime = boto3.client('bedrock-runtime')
        
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
        
    except Exception as e:
        print(f"Error generating text: {str(e)}")
        return None

# Usage
result = generate_text(
    prompt="Explain AWS Lambda in 2 sentences",
    temperature=0.5
)
print(result)
```

### Image Generation and S3 Storage

```python
import boto3
import json
import base64
from datetime import datetime

def generate_and_save_image(prompt, bucket_name):
    """
    Generate image with Bedrock and save to S3.
    
    Args:
        prompt (str): Image generation prompt
        bucket_name (str): S3 bucket for storage
    
    Returns:
        str: S3 object key
    """
    try:
        bedrock_runtime = boto3.client('bedrock-runtime')
        s3 = boto3.client('s3')
        
        # Generate image
        request_body = {
            'taskType': 'TEXT_IMAGE',
            'textToImageParams': {
                'text': prompt
            },
            'imageGenerationConfig': {
                'numberOfImages': 1,
                'quality': 'standard',
                'height': 512,
                'width': 512
            }
        }
        
        response = bedrock_runtime.invoke_model(
            modelId='amazon.nova-canvas-v1:0',
            body=json.dumps(request_body)
        )
        
        response_body = json.loads(response['body'].read())
        image_base64 = response_body['images'][0]
        image_data = base64.b64decode(image_base64)
        
        # Save to S3
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        object_key = f'generated_images/{timestamp}.png'
        
        s3.put_object(
            Bucket=bucket_name,
            Key=object_key,
            Body=image_data,
            ContentType='image/png'
        )
        
        print(f"Image saved to s3://{bucket_name}/{object_key}")
        return object_key
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return None

# Usage
object_key = generate_and_save_image(
    prompt="A futuristic cloud computing data center",
    bucket_name='[BUCKET-NAME]'
)
```

### Bedrock + Rekognition Integration

```python
import boto3
import json
import base64

def analyze_generated_image(prompt):
    """
    Generate image with Bedrock, analyze with Rekognition,
    and create description with Bedrock.
    
    Args:
        prompt (str): Image generation prompt
    
    Returns:
        dict: Analysis results and AI description
    """
    try:
        bedrock_runtime = boto3.client('bedrock-runtime')
        rekognition = boto3.client('rekognition')
        
        # Step 1: Generate image
        image_request = {
            'taskType': 'TEXT_IMAGE',
            'textToImageParams': {'text': prompt},
            'imageGenerationConfig': {
                'numberOfImages': 1,
                'quality': 'standard',
                'height': 512,
                'width': 512
            }
        }
        
        image_response = bedrock_runtime.invoke_model(
            modelId='amazon.nova-canvas-v1:0',
            body=json.dumps(image_request)
        )
        
        image_base64 = json.loads(
            image_response['body'].read()
        )['images'][0]
        image_bytes = base64.b64decode(image_base64)
        
        # Step 2: Analyze with Rekognition
        rekog_response = rekognition.detect_labels(
            Image={'Bytes': image_bytes},
            MaxLabels=10,
            MinConfidence=75
        )
        
        labels = [label['Name'] for label in rekog_response['Labels']]
        
        # Step 3: Generate description with Bedrock
        description_prompt = f"""
        An AI generated an image with this prompt: "{prompt}"
        
        Rekognition detected these labels: {', '.join(labels)}
        
        Write a 2-sentence description of what the image likely contains.
        """
        
        desc_request = {
            'prompt': description_prompt,
            'temperature': 0.5,
            'maxTokens': 200
        }
        
        desc_response = bedrock_runtime.invoke_model(
            modelId='amazon.nova-lite-v1:0',
            body=json.dumps(desc_request)
        )
        
        description = json.loads(
            desc_response['body'].read()
        )['results'][0]['outputText']
        
        return {
            'original_prompt': prompt,
            'detected_labels': labels,
            'ai_description': description,
            'image_base64': image_base64
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return None

# Usage
result = analyze_generated_image(
    "A serene mountain landscape at sunset"
)
print(f"Labels: {result['detected_labels']}")
print(f"Description: {result['ai_description']}")
```

## Best Practices

### Error Handling

```python
from botocore.exceptions import ClientError

def invoke_model_safely(model_id, prompt):
    try:
        bedrock_runtime = boto3.client('bedrock-runtime')
        
        response = bedrock_runtime.invoke_model(
            modelId=model_id,
            body=json.dumps({'prompt': prompt})
        )
        
        return json.loads(response['body'].read())
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        
        if error_code == 'AccessDeniedException':
            print("Model access not enabled. Request access in console.")
        elif error_code == 'ThrottlingException':
            print("Rate limit exceeded. Implement retry with backoff.")
        elif error_code == 'ValidationException':
            print("Invalid request parameters.")
        else:
            print(f"Unexpected error: {str(e)}")
        
        return None
```

### Cost Optimization

```python
def estimate_cost(input_tokens, output_tokens, model_id):
    """
    Estimate cost for Bedrock API call.
    
    Pricing (example for Nova Lite):
    - Input: $0.00006 per 1K tokens
    - Output: $0.00024 per 1K tokens
    """
    pricing = {
        'amazon.nova-lite-v1:0': {
            'input': 0.00006,
            'output': 0.00024
        },
        'amazon.nova-pro-v1:0': {
            'input': 0.0008,
            'output': 0.0032
        }
    }
    
    rates = pricing.get(model_id, pricing['amazon.nova-lite-v1:0'])
    
    input_cost = (input_tokens / 1000) * rates['input']
    output_cost = (output_tokens / 1000) * rates['output']
    
    return {
        'input_cost': input_cost,
        'output_cost': output_cost,
        'total_cost': input_cost + output_cost
    }
```

## Interview Talking Points

**Q: Why use SDK instead of console?**
- Automation and CI/CD integration
- Production application development
- Batch processing capabilities
- Error handling and retry logic
- Integration with other AWS services
- Cost tracking and monitoring

**Q: How do you handle variable response times from LLMs?**
- Implement timeout handling
- Use asynchronous invocation patterns
- Provide user feedback (loading indicators)
- Consider streaming for long responses
- Cache common responses
- Set appropriate Lambda timeout limits

**Q: How do you optimize costs for Bedrock API calls?**
- Choose smallest model that meets requirements
- Set appropriate max token limits
- Implement response caching
- Batch similar requests
- Monitor usage with CloudWatch
- Use streaming to show partial results

## Real-World Application

- **Production AI services**: Every production Bedrock application uses the SDK — console playgrounds are for prototyping only
- **Multi-model pipelines**: Generate an image with Nova Canvas, analyze it with Rekognition, describe it with Nova Lite — SDK enables complex multi-service workflows
- **Batch processing**: Process thousands of documents, images, or text inputs programmatically — impossible through the console
- **Error handling and retries**: Production applications need throttling handling, exponential backoff, and graceful degradation — all implemented through the SDK

## Next Steps

After completing this project:

1. **Flashcard Application Lab**: Build serverless AI app with Lambda
2. **RAG Lab**: Integrate with knowledge bases
3. **LangChain Lab**: Use production AI framework
4. **Guardrails Lab**: Add security controls

## Key Takeaways

✅ Boto3 enables programmatic Bedrock access  
✅ Different models have different request formats  
✅ Error handling is critical for production  
✅ Multi-service integration creates powerful workflows  
✅ Streaming improves user experience for long responses  
✅ Cost monitoring and optimization are essential

---

**Status:** ✅ Complete  
**Skills Demonstrated:** Boto3 SDK, programmatic model invocation, multi-service integration, error handling

