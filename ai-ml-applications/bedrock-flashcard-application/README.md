# Integrating Amazon Bedrock FMs Into an Application

## Lab Overview

**Duration:** 90 minutes | **Complexity:** Advanced | **Course:** AI for Developers

## Scenario

Build an end-to-end serverless flashcard generator application that converts study notes into flashcards using Amazon Bedrock foundation models, with Lambda backend, API Gateway REST API, and React frontend.

## AWS Services Used

- **AWS Lambda** - Serverless compute for Bedrock integration
- **Amazon API Gateway** - REST API with CORS
- **Amazon Bedrock** - Foundation model for flashcard generation
- **Amazon S3** - Static website hosting for React frontend
- **React** - Frontend application

## Learning Objectives

1. Build serverless backend with Lambda and Bedrock
2. Implement system prompts for structured JSON output
3. Create REST API with API Gateway and CORS configuration
4. Deploy React frontend to S3 static hosting
5. Test end-to-end AI-powered application
6. Handle variable LLM response times in production

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    User Browser                               │
│                  (React Application)                          │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         │ HTTPS POST /generate-flashcards
                         │ { "notes": "Study notes text" }
                         │
┌────────────────────────▼─────────────────────────────────────┐
│              Amazon API Gateway (REST API)                    │
│  • CORS enabled                                               │
│  • POST /generate-flashcards                                  │
│  • Lambda proxy integration                                   │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         │ Invoke Lambda
                         │
┌────────────────────────▼─────────────────────────────────────┐
│              AWS Lambda Function                              │
│  • Parse request body                                         │
│  • Create system prompt for JSON output                       │
│  • Invoke Bedrock model                                       │
│  • Parse and validate JSON response                           │
│  • Return flashcards array                                    │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         │ invoke_model()
                         │
┌────────────────────────▼─────────────────────────────────────┐
│              Amazon Bedrock                                   │
│  • Process system prompt + user notes                         │
│  • Generate structured flashcards                             │
│  • Return JSON array                                          │
└───────────────────────────────────────────────────────────────┘
```

## Key Concepts

### System Prompts for Structured Output

```python
system_prompt = """
You are a flashcard generator. Convert study notes into flashcards.

Output Format (JSON array):
[
  {
    "question": "Clear, specific question",
    "answer": "Concise, accurate answer"
  }
]

Rules:
- Generate 5-10 flashcards
- Questions should test key concepts
- Answers should be 1-2 sentences
- Output ONLY valid JSON, no additional text
"""
```

### Lambda Handler

```python
import json
import boto3

bedrock_runtime = boto3.client('bedrock-runtime')

def lambda_handler(event, context):
    try:
        # Parse request
        body = json.loads(event['body'])
        notes = body.get('notes', '')
        
        if not notes:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Notes required'})
            }
        
        # Create prompt
        prompt = f"""
        {system_prompt}
        
        Study Notes:
        {notes}
        
        Flashcards (JSON):
        """
        
        # Invoke Bedrock
        response = bedrock_runtime.invoke_model(
            modelId='amazon.nova-lite-v1:0',
            body=json.dumps({
                'prompt': prompt,
                'temperature': 0.3,  # Low for consistency
                'maxTokens': 2000
            })
        )
        
        # Parse response
        response_body = json.loads(response['body'].read())
        generated_text = response_body['results'][0]['outputText']
        
        # Extract JSON from response
        flashcards = json.loads(generated_text)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'flashcards': flashcards,
                'count': len(flashcards)
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }
```

### API Gateway CORS Configuration

```json
{
  "AllowOrigin": "*",
  "AllowMethods": "POST,OPTIONS",
  "AllowHeaders": "Content-Type,X-Amz-Date,Authorization,X-Api-Key"
}
```

### React Frontend Integration

```javascript
async function generateFlashcards(notes) {
  const API_ENDPOINT = '[API-ENDPOINT]';
  
  try {
    const response = await fetch(`${API_ENDPOINT}/generate-flashcards`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ notes })
    });
    
    const data = await response.json();
    return data.flashcards;
    
  } catch (error) {
    console.error('Error:', error);
    throw error;
  }
}
```

## Best Practices

### Prompt Engineering for JSON Output

✅ **Do**:
- Specify exact JSON structure
- Use low temperature (0.2-0.3)
- Add "Output ONLY JSON" instruction
- Validate and parse response
- Handle malformed JSON gracefully

### Error Handling

```python
def parse_flashcards_safely(generated_text):
    """
    Safely parse flashcards from LLM response.
    """
    try:
        # Try direct JSON parse
        return json.loads(generated_text)
    except json.JSONDecodeError:
        # Try to extract JSON from markdown code blocks
        import re
        json_match = re.search(r'```json\n(.*?)\n```', 
                               generated_text, re.DOTALL)
        if json_match:
            return json.loads(json_match.group(1))
        
        # Fallback: return error
        raise ValueError("Could not parse JSON from response")
```

### Cost Optimization

- Use Nova Lite for simple tasks
- Set appropriate max tokens
- Implement caching for identical notes
- Monitor Lambda execution time
- Use Lambda power tuning

## Interview Talking Points

**Q: How do you handle variable LLM response times?**
- Set appropriate Lambda timeout (30-60s)
- Show loading indicator in frontend
- Implement timeout handling in API calls
- Consider async processing for long tasks
- Use streaming for real-time feedback

**Q: How do you ensure consistent JSON output from LLMs?**
- Use system prompts with exact format
- Set low temperature (0.2-0.3)
- Validate and sanitize output
- Implement retry logic for malformed responses
- Consider fine-tuning for critical applications

**Q: How do you scale serverless AI applications?**
- Lambda auto-scales automatically
- Monitor concurrent executions
- Implement API Gateway throttling
- Use CloudWatch for monitoring
- Consider reserved concurrency for predictable load

## Key Takeaways

✅ Serverless architecture ideal for AI applications  
✅ System prompts enable structured output  
✅ CORS configuration essential for web apps  
✅ Error handling critical for LLM unpredictability  
✅ Low temperature improves JSON consistency  
✅ End-to-end testing validates integration

---

**Lab Status:** ✅ Complete  
**Skills Gained:** Serverless AI apps, Lambda-Bedrock integration, API Gateway, React integration

