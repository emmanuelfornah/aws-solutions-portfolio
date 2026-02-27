# Architecture: AWS SDK for Python with Amazon Bedrock

## System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                  Python Application Layer                         │
│                    (Jupyter Notebook / Script)                    │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  Boto3 SDK                                             │     │
│  │  • bedrock-runtime client (model invocation)           │     │
│  │  • s3 client (image storage)                           │     │
│  │  • rekognition client (image analysis)                 │     │
│  └────────────────┬───────────────────────────────────────┘     │
│                   │                                              │
└───────────────────┼──────────────────────────────────────────────┘
                    │
                    │ AWS API Calls (HTTPS)
                    │
┌───────────────────▼──────────────────────────────────────────────┐
│                    AWS Service Layer                              │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ Amazon Bedrock   │  │  Amazon S3   │  │    Amazon        │  │
│  │   Runtime        │  │              │  │  Rekognition     │  │
│  │                  │  │              │  │                  │  │
│  │ • invoke_model   │  │ • put_object │  │ • detect_labels  │  │
│  │ • streaming      │  │ • get_object │  │ • detect_text    │  │
│  └──────────────────┘  └──────────────┘  └──────────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

## API Call Flow

### Text Generation Flow

```
Python Application
       │
       │ 1. Create bedrock_runtime client
       ▼
┌─────────────────────────────────────┐
│ boto3.client('bedrock-runtime')     │
└─────────────┬───────────────────────┘
              │
              │ 2. Prepare request body
              ▼
┌─────────────────────────────────────┐
│ request_body = {                    │
│   'prompt': 'Your prompt',          │
│   'temperature': 0.7,               │
│   'maxTokens': 512                  │
│ }                                   │
└─────────────┬───────────────────────┘
              │
              │ 3. Invoke model
              ▼
┌─────────────────────────────────────┐
│ bedrock_runtime.invoke_model(       │
│   modelId='amazon.nova-lite-v1:0',  │
│   body=json.dumps(request_body)     │
│ )                                   │
└─────────────┬───────────────────────┘
              │
              │ 4. Parse response
              ▼
┌─────────────────────────────────────┐
│ response_body = json.loads(         │
│   response['body'].read()           │
│ )                                   │
│ text = response_body['results'][0]  │
│        ['outputText']                │
└─────────────────────────────────────┘
```

### Multi-Service Integration Flow

```
┌─────────────────────────────────────────────────────────────┐
│  Step 1: Generate Image with Bedrock                        │
│  ┌───────────────────────────────────────────────────┐     │
│  │ bedrock_runtime.invoke_model(                      │     │
│  │   modelId='amazon.nova-canvas-v1:0',               │     │
│  │   body=image_generation_request                    │     │
│  │ )                                                  │     │
│  └───────────────────┬───────────────────────────────┘     │
│                      │                                      │
│                      ▼                                      │
│  ┌───────────────────────────────────────────────────┐     │
│  │ image_base64 = response['images'][0]               │     │
│  │ image_bytes = base64.b64decode(image_base64)       │     │
│  └───────────────────┬───────────────────────────────┘     │
└────────────────────────┼────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│  Step 2: Save to S3                                         │
│  ┌───────────────────────────────────────────────────┐     │
│  │ s3.put_object(                                     │     │
│  │   Bucket='my-bucket',                              │     │
│  │   Key='images/generated.png',                      │     │
│  │   Body=image_bytes,                                │     │
│  │   ContentType='image/png'                          │     │
│  │ )                                                  │     │
│  └───────────────────┬───────────────────────────────┘     │
└────────────────────────┼────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│  Step 3: Analyze with Rekognition                           │
│  ┌───────────────────────────────────────────────────┐     │
│  │ rekognition.detect_labels(                         │     │
│  │   Image={'Bytes': image_bytes},                    │     │
│  │   MaxLabels=10,                                    │     │
│  │   MinConfidence=75                                 │     │
│  │ )                                                  │     │
│  └───────────────────┬───────────────────────────────┘     │
│                      │                                      │
│                      ▼                                      │
│  ┌───────────────────────────────────────────────────┐     │
│  │ labels = [label['Name'] for label in               │     │
│  │           response['Labels']]                       │     │
│  └───────────────────┬───────────────────────────────┘     │
└────────────────────────┼────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│  Step 4: Generate Description with Bedrock                  │
│  ┌───────────────────────────────────────────────────┐     │
│  │ prompt = f"Describe image with labels: {labels}"   │     │
│  │ bedrock_runtime.invoke_model(                      │     │
│  │   modelId='amazon.nova-lite-v1:0',                 │     │
│  │   body=description_request                         │     │
│  │ )                                                  │     │
│  └───────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## Error Handling Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  Error Handling Strategy                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  try:                                                        │
│      response = bedrock_runtime.invoke_model(...)           │
│                                                              │
│  except ClientError as e:                                   │
│      error_code = e.response['Error']['Code']               │
│                                                              │
│      ┌──────────────────────────────────────────┐          │
│      │ AccessDeniedException                     │          │
│      │ → Request model access in console         │          │
│      └──────────────────────────────────────────┘          │
│                                                              │
│      ┌──────────────────────────────────────────┐          │
│      │ ThrottlingException                       │          │
│      │ → Implement exponential backoff           │          │
│      │ → Reduce request rate                     │          │
│      └──────────────────────────────────────────┘          │
│                                                              │
│      ┌──────────────────────────────────────────┐          │
│      │ ValidationException                       │          │
│      │ → Check request parameters                │          │
│      │ → Verify model ID format                  │          │
│      └──────────────────────────────────────────┘          │
│                                                              │
│      ┌──────────────────────────────────────────┐          │
│      │ ModelTimeoutException                     │          │
│      │ → Retry with same parameters              │          │
│      │ → Consider smaller max_tokens             │          │
│      └──────────────────────────────────────────┘          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Best Practices

✅ Use environment variables for configuration  
✅ Implement retry logic with exponential backoff  
✅ Log all API calls for debugging  
✅ Monitor token usage and costs  
✅ Cache responses when appropriate  
✅ Handle streaming responses for better UX

