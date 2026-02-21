# Architecture: Introduction to Amazon Bedrock Console

## System Architecture

### High-Level Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                         User Interface                            │
│                    (AWS Management Console)                       │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             │ HTTPS
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│                      Amazon Bedrock Service                       │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Playground Interfaces                       │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  • Text Playground (single prompts)                      │    │
│  │  • Chat Playground (multi-turn conversations)            │    │
│  │  • Image Playground (image generation/editing)           │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Model Router & Orchestration                │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  • Model selection and routing                           │    │
│  │  • Parameter validation                                  │    │
│  │  • Request/response formatting                           │    │
│  │  • Token counting and billing                            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
                             │
                             │ Model API Calls
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│                    Foundation Model Layer                         │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Amazon Nova  │  │  Meta Llama  │  │  Anthropic   │          │
│  │    Lite      │  │      3       │  │   Claude     │          │
│  │   (Text)     │  │   (Text)     │  │   (Text)     │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Amazon Nova  │  │ Amazon Titan │  │    Cohere    │          │
│  │   Canvas     │  │ (Text/Embed) │  │   Command    │          │
│  │   (Image)    │  │              │  │   (Text)     │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Console Interface Layer

**Purpose**: Provide user-friendly interface for foundation model interaction

**Features**:
- **Text Playground**: Single-prompt text generation
- **Chat Playground**: Multi-turn conversational interface
- **Image Playground**: Image generation and editing
- **Model Comparison**: Side-by-side model testing
- **Parameter Controls**: Interactive sliders and inputs

**User Experience Flow**:
```
User Input → Parameter Selection → Model Selection → Submit
     ↓
Response Display ← Token Count ← Model Processing ← Bedrock API
```

### 2. Bedrock Service Layer

**Purpose**: Orchestrate model access, manage parameters, handle billing

**Responsibilities**:
- Model access control and permissions
- Request validation and sanitization
- Parameter normalization across models
- Token counting and cost calculation
- Response formatting and streaming
- Error handling and retry logic

**Request Processing**:
```
1. Validate IAM permissions
2. Check model access status
3. Validate parameters (temperature, top-p, etc.)
4. Format request for target model
5. Route to appropriate foundation model
6. Stream or batch response
7. Calculate token usage and cost
```

### 3. Foundation Model Layer

**Purpose**: Execute inference on foundation models

**Model Categories**:

**Text Generation Models**:
- Amazon Nova Lite: Fast, cost-effective
- Meta Llama 3: Open-source, customizable
- Anthropic Claude: Advanced reasoning
- Amazon Titan: AWS-native
- Cohere Command: Enterprise-focused

**Image Generation Models**:
- Amazon Nova Canvas: Text-to-image, image editing
- Stability AI: Stable Diffusion models

**Embedding Models**:
- Amazon Titan Embeddings v2: Vector representations
- Cohere Embed: Multilingual embeddings

## Data Flow

### Text Generation Flow

```
┌─────────────┐
│ User Prompt │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Bedrock Console                     │
│ • Select model: Nova Lite           │
│ • Set temperature: 0.7              │
│ • Set top-p: 0.9                    │
│ • Set max tokens: 512               │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Bedrock Service                     │
│ • Validate parameters               │
│ • Format request                    │
│ • Route to Nova Lite                │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Amazon Nova Lite Model              │
│ • Process prompt                    │
│ • Apply parameters                  │
│ • Generate tokens                   │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Response Processing                 │
│ • Count tokens (input + output)     │
│ • Calculate cost                    │
│ • Format response                   │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────┐
│ Display to  │
│    User     │
└─────────────┘
```

### Image Generation Flow

```
┌─────────────────┐
│ Text Prompt     │
│ "A sunset over  │
│  mountains"     │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Image Playground                    │
│ • Select Nova Canvas                │
│ • Choose aspect ratio: 16:9         │
│ • Set style: Photorealistic         │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Bedrock Service                     │
│ • Validate image parameters         │
│ • Format image generation request   │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Amazon Nova Canvas                  │
│ • Process text prompt               │
│ • Generate image                    │
│ • Apply style parameters            │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Image Response                      │
│ • Base64 encoded image              │
│ • Metadata (size, format)           │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────┐
│ Display     │
│ Image       │
└─────────────┘
```

## Parameter Impact Analysis

### Temperature Effect

```
Temperature: 0.0 (Deterministic)
Prompt: "The capital of France is"
Response: "Paris."
Consistency: 100% same response

Temperature: 0.5 (Balanced)
Prompt: "The capital of France is"
Response: "Paris, a beautiful city known for..."
Consistency: ~80% similar responses

Temperature: 1.0 (Creative)
Prompt: "The capital of France is"
Response: "Paris! This magnificent metropolis..."
Consistency: ~40% similar responses
```

### Top-P (Nucleus Sampling) Effect

```
Top-P: 0.1 (Very Focused)
Token Pool: Top 10% probability tokens
Output: Highly predictable, limited vocabulary

Top-P: 0.5 (Moderate)
Token Pool: Top 50% probability tokens
Output: Balanced predictability and diversity

Top-P: 0.9 (Diverse)
Token Pool: Top 90% probability tokens
Output: More creative, varied vocabulary
```

## Security Architecture

### Access Control

```
┌─────────────────────────────────────────────────────────┐
│                    IAM User/Role                         │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  IAM Policy Check                        │
│  {                                                       │
│    "Effect": "Allow",                                    │
│    "Action": [                                           │
│      "bedrock:InvokeModel",                              │
│      "bedrock:InvokeModelWithResponseStream"             │
│    ],                                                    │
│    "Resource": "arn:aws:bedrock:*::foundation-model/*"   │
│  }                                                       │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│              Model Access Verification                   │
│  • Check if model access requested                       │
│  • Verify access approval status                         │
│  • Validate region availability                          │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                 Allow Model Access                       │
└─────────────────────────────────────────────────────────┘
```

### Data Privacy

- **No Training on Customer Data**: Bedrock doesn't use prompts/responses for model training
- **Encryption in Transit**: TLS 1.2+ for all API calls
- **Encryption at Rest**: Not applicable (no data persistence in console)
- **Audit Logging**: CloudTrail captures all API calls
- **Regional Isolation**: Data doesn't leave selected region

## Performance Characteristics

### Model Latency Comparison

```
Model               | Avg Latency | Tokens/Sec | Use Case
--------------------|-------------|------------|------------------
Nova Lite           | ~200ms      | ~50        | Simple tasks
Nova Pro            | ~500ms      | ~30        | Complex reasoning
Llama 3 8B          | ~300ms      | ~40        | General purpose
Llama 3 70B         | ~800ms      | ~20        | Advanced tasks
Claude Sonnet       | ~600ms      | ~25        | Long context
```

### Throughput Considerations

- **Console Limits**: Single request at a time
- **Rate Limits**: Vary by model and region
- **Concurrent Requests**: Not applicable in console
- **Batch Processing**: Not available in console

## Cost Architecture

### Pricing Components

```
Total Cost = (Input Tokens × Input Price) + (Output Tokens × Output Price)

Example: Nova Lite
Input: 1,000 tokens × $0.00006 = $0.06
Output: 500 tokens × $0.00024 = $0.12
Total: $0.18 per request
```

### Cost Optimization Strategies

1. **Model Selection**: Use smallest model that meets requirements
2. **Token Limits**: Set appropriate max tokens
3. **Prompt Efficiency**: Minimize unnecessary context
4. **Caching**: Reuse responses for identical prompts (API only)
5. **Batch Processing**: Group similar requests (API only)

## Scalability Considerations

### Console Limitations

- Single user interface (not for production)
- No concurrent request handling
- Manual testing only
- No automation or CI/CD integration

### Production Migration Path

```
Console Testing → SDK Development → Lambda Integration → Production API
     ↓                  ↓                   ↓                  ↓
  Explore models    Automate calls    Serverless scale   Full production
  Test prompts      Error handling    API Gateway        Monitoring
  Tune parameters   Logging           Auto-scaling       Cost tracking
```

## Best Practices

### Console Usage

✅ **Do**:
- Test multiple models for comparison
- Experiment with parameters systematically
- Document successful prompts and settings
- Use for rapid prototyping and exploration
- Validate model capabilities before coding

❌ **Don't**:
- Use for production workloads
- Send sensitive or PII data
- Expect consistent performance
- Rely on for automated testing
- Use for high-volume requests

### Parameter Tuning

✅ **Do**:
- Start with recommended defaults
- Change one parameter at a time
- Test with representative prompts
- Document optimal settings per use case
- Consider cost implications

❌ **Don't**:
- Use extreme values without testing
- Ignore token limits
- Assume same settings work for all models
- Forget to test edge cases

## Monitoring and Observability

### Available Metrics (Console)

- **Token Count**: Input and output tokens per request
- **Response Time**: Latency for each request
- **Cost Estimate**: Approximate cost per request
- **Model Selection**: Which model was used

### Production Monitoring (API)

- **CloudWatch Metrics**: Invocation count, errors, latency
- **CloudTrail Logs**: API call history and parameters
- **Cost Explorer**: Detailed cost breakdown by model
- **Custom Metrics**: Application-specific tracking

## Troubleshooting Guide

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Model access denied | Access not requested | Request access in console settings |
| Poor quality output | Suboptimal parameters | Adjust temperature, refine prompt |
| Truncated responses | Token limit too low | Increase max tokens parameter |
| Inconsistent results | High temperature | Lower temperature for determinism |
| Slow responses | Large model selected | Use smaller model for simple tasks |

## Integration Patterns

### Console → SDK Migration

```python
# Console settings
Model: amazon.nova-lite-v1:0
Temperature: 0.7
Top-P: 0.9
Max Tokens: 512

# Equivalent SDK code
import boto3

bedrock = boto3.client('bedrock-runtime')

response = bedrock.invoke_model(
    modelId='amazon.nova-lite-v1:0',
    body=json.dumps({
        'prompt': 'Your prompt here',
        'temperature': 0.7,
        'topP': 0.9,
        'maxTokens': 512
    })
)
```

## Key Takeaways

✅ Console provides rapid experimentation without coding  
✅ Multiple playgrounds for different use cases (text, chat, image)  
✅ Parameter tuning significantly impacts output quality  
✅ Model selection depends on task complexity and cost  
✅ Security handled by IAM and model access controls  
✅ Console is for testing; production requires SDK/API integration

