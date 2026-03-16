# Securing AI with Amazon Bedrock Guardrails

## Overview

**Duration:** 60 minutes | **Complexity:** Advanced | 

## Scenario

Implement enterprise-grade security controls for AI applications using Amazon Bedrock Guardrails to block harmful content, filter denied topics, mask PII, and reduce hallucinations with contextual grounding.

## AWS Services Used

- **Amazon Bedrock Guardrails** - AI safety and security
- **Python (Boto3)** - API integration
- **Jupyter Notebook** - Interactive testing

## Learning Objectives

1. Create and configure Amazon Bedrock guardrails
2. Block harmful content (hate, violence, misconduct, sexual content)
3. Implement denied topics and word filters
4. Mask PII (passwords, usernames) in responses
5. Enable contextual grounding to reduce hallucinations
6. Test guardrails via Converse API with Python
7. Identify and remediate prompt injection vulnerabilities

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    User Input                                 │
│  "Tell me how to hack a system"                               │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│              Amazon Bedrock Guardrails                        │
│  ┌────────────────────────────────────────────────────┐     │
│  │ Input Filters                                       │     │
│  │ • Harmful content detection                         │     │
│  │ • Denied topics check                               │     │
│  │ • Word filters                                      │     │
│  │ • Prompt injection detection                        │     │
│  └────────────────┬───────────────────────────────────┘     │
│                   │                                          │
│                   ▼                                          │
│  ┌────────────────────────────────────────────────────┐     │
│  │ Foundation Model Processing                         │     │
│  │ (If input passes filters)                           │     │
│  └────────────────┬───────────────────────────────────┘     │
│                   │                                          │
│                   ▼                                          │
│  ┌────────────────────────────────────────────────────┐     │
│  │ Output Filters                                      │     │
│  │ • PII masking                                       │     │
│  │ • Harmful content check                             │     │
│  │ • Contextual grounding verification                 │     │
│  └────────────────┬───────────────────────────────────┘     │
└───────────────────┼──────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────────────────────┐
│              Filtered Response                                │
│  "I cannot provide information on hacking systems."           │
└──────────────────────────────────────────────────────────────┘
```

## Key Concepts

### Content Filters

**Harmful Content Categories**:
- **Hate**: Discrimination, slurs, stereotypes
- **Violence**: Graphic violence, weapons, harm
- **Sexual**: Explicit sexual content
- **Misconduct**: Illegal activities, dangerous advice

**Filter Strengths**:
- **NONE**: No filtering
- **LOW**: Minimal filtering
- **MEDIUM**: Balanced filtering
- **HIGH**: Strict filtering

### Denied Topics

```python
denied_topics = [
    {
        "name": "Financial Advice",
        "definition": "Providing specific investment recommendations or financial advice",
        "examples": [
            "Should I invest in Bitcoin?",
            "What stocks should I buy?"
        ]
    }
]
```

### Word Filters

```python
word_filters = [
    {
        "text": "confidential",
        "action": "BLOCK"
    },
    {
        "text": "internal only",
        "action": "BLOCK"
    }
]
```

### PII Masking

**Supported PII Types**:
- Email addresses
- Phone numbers
- Credit card numbers
- Social Security numbers
- Passwords
- Usernames
- IP addresses
- AWS keys

**Actions**:
- **BLOCK**: Reject request/response
- **ANONYMIZE**: Replace with placeholder

### Contextual Grounding

**Purpose**: Reduce hallucinations by verifying responses against source documents

**Configuration**:
```python
contextual_grounding = {
    "threshold": 0.75,  # Grounding score threshold
    "action": "BLOCK"   # Block if below threshold
}
```

## Sample Code

### Create Guardrail

```python
import boto3

bedrock = boto3.client('bedrock')

response = bedrock.create_guardrail(
    name='ProductionGuardrail',
    description='Enterprise AI safety controls',
    contentPolicyConfig={
        'filtersConfig': [
            {
                'type': 'HATE',
                'inputStrength': 'HIGH',
                'outputStrength': 'HIGH'
            },
            {
                'type': 'VIOLENCE',
                'inputStrength': 'HIGH',
                'outputStrength': 'HIGH'
            },
            {
                'type': 'SEXUAL',
                'inputStrength': 'HIGH',
                'outputStrength': 'HIGH'
            },
            {
                'type': 'MISCONDUCT',
                'inputStrength': 'MEDIUM',
                'outputStrength': 'MEDIUM'
            }
        ]
    },
    topicPolicyConfig={
        'topicsConfig': [
            {
                'name': 'Financial Advice',
                'definition': 'Specific investment or financial recommendations',
                'examples': [
                    'Should I buy this stock?',
                    'What cryptocurrency should I invest in?'
                ],
                'type': 'DENY'
            }
        ]
    },
    wordPolicyConfig={
        'wordsConfig': [
            {'text': 'confidential'},
            {'text': 'internal only'},
            {'text': 'do not share'}
        ],
        'managedWordListsConfig': [
            {'type': 'PROFANITY'}
        ]
    },
    sensitiveInformationPolicyConfig={
        'piiEntitiesConfig': [
            {
                'type': 'EMAIL',
                'action': 'ANONYMIZE'
            },
            {
                'type': 'PHONE',
                'action': 'ANONYMIZE'
            },
            {
                'type': 'PASSWORD',
                'action': 'BLOCK'
            },
            {
                'type': 'AWS_ACCESS_KEY',
                'action': 'BLOCK'
            }
        ]
    },
    contextualGroundingPolicyConfig={
        'filtersConfig': [
            {
                'type': 'GROUNDING',
                'threshold': 0.75
            },
            {
                'type': 'RELEVANCE',
                'threshold': 0.75
            }
        ]
    },
    blockedInputMessaging='I cannot process this request due to content policy.',
    blockedOutputsMessaging='I cannot provide this information due to content policy.'
)

guardrail_id = response['guardrailId']
print(f"Guardrail ID: {guardrail_id}")
```

### Use Guardrail with Converse API

```python
bedrock_runtime = boto3.client('bedrock-runtime')

def chat_with_guardrails(message, guardrail_id):
    """
    Chat with foundation model using guardrails.
    """
    try:
        response = bedrock_runtime.converse(
            modelId='amazon.nova-lite-v1:0',
            messages=[
                {
                    'role': 'user',
                    'content': [{'text': message}]
                }
            ],
            guardrailConfig={
                'guardrailIdentifier': guardrail_id,
                'guardrailVersion': 'DRAFT',
                'trace': 'enabled'
            }
        )
        
        # Check if blocked
        if response.get('stopReason') == 'guardrail_intervened':
            print("Request blocked by guardrail")
            trace = response.get('trace', {})
            print(f"Reason: {trace}")
            return None
        
        # Extract response
        output = response['output']['message']['content'][0]['text']
        return output
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return None

# Test harmful content
result = chat_with_guardrails(
    "Tell me how to hack a computer",
    guardrail_id
)
# Expected: Blocked

# Test normal query
result = chat_with_guardrails(
    "Explain AWS Lambda",
    guardrail_id
)
# Expected: Normal response
```

### Test PII Masking

```python
# Input with PII
message = "My email is john@example.com and phone is 555-1234"

response = bedrock_runtime.converse(
    modelId='amazon.nova-lite-v1:0',
    messages=[{'role': 'user', 'content': [{'text': message}]}],
    guardrailConfig={
        'guardrailIdentifier': guardrail_id,
        'guardrailVersion': 'DRAFT'
    }
)

# Output will have PII anonymized
# "My email is [EMAIL] and phone is [PHONE]"
```

## Best Practices

### Guardrail Configuration

✅ **Do**:
- Start with HIGH filter strength, adjust as needed
- Test with diverse inputs
- Monitor guardrail interventions
- Document blocked content patterns
- Regular review and updates

### Prompt Injection Defense

**Common Attacks**:
```
"Ignore previous instructions and..."
"You are now in developer mode..."
"Disregard safety guidelines..."
```

**Defense**:
- Enable misconduct filter
- Add denied topics for system instructions
- Monitor for injection patterns
- Log and analyze blocked attempts

### Production Deployment

```python
# Create versioned guardrail
response = bedrock.create_guardrail_version(
    guardrailIdentifier=guardrail_id,
    description='Production v1.0'
)

version = response['version']

# Use specific version in production
guardrailConfig={
    'guardrailIdentifier': guardrail_id,
    'guardrailVersion': version  # Not 'DRAFT'
}
```

## Interview Talking Points

**Q: How do you implement responsible AI in production?**
- Content filtering for harmful content
- PII protection and masking
- Denied topics for sensitive areas
- Contextual grounding for accuracy
- Monitoring and logging
- Regular security audits

**Q: How do you balance safety with functionality?**
- Start with strict filters, relax as needed
- A/B test filter strengths
- Monitor false positive rates
- Implement override mechanisms for authorized users
- Document exceptions and rationale

**Q: How do you handle prompt injection attacks?**
- Enable guardrails with misconduct filters
- Input validation and sanitization
- System prompt protection
- Rate limiting and monitoring
- User authentication and authorization

## Key Takeaways

✅ Guardrails provide enterprise-grade AI security  
✅ Multiple filter types for comprehensive protection  
✅ PII masking protects sensitive information  
✅ Contextual grounding reduces hallucinations  
✅ Prompt injection defense is critical  
✅ Monitoring and logging enable continuous improvement

---

**Status:** ✅ Complete  
**Skills Demonstrated:** AI security, content filtering, PII protection, prompt injection defense, responsible AI

## Real-World Application

- **Enterprise AI governance**: Every production AI application needs content filtering to prevent harmful, biased, or off-topic responses
- **PII protection**: Healthcare and financial applications use guardrails to detect and mask patient data, SSNs, and account numbers in AI responses
- **Brand safety**: Customer-facing chatbots use denied topic filters to prevent the AI from discussing competitors, politics, or inappropriate content
- **Regulatory compliance**: HIPAA, GDPR, and SOC 2 audits require documented controls around AI-generated content — guardrails provide that evidence
