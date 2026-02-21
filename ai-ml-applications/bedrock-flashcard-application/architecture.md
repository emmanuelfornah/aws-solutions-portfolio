# Architecture: Serverless Flashcard Application

## End-to-End Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Frontend (React on S3)                        │
│  • User inputs study notes                                      │
│  • Displays generated flashcards                                │
│  • Hosted as static website on S3                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ HTTPS POST
                         │
┌────────────────────────▼────────────────────────────────────────┐
│              Amazon API Gateway (REST API)                       │
│  • /generate-flashcards endpoint                                │
│  • CORS configuration                                            │
│  • Lambda proxy integration                                      │
│  • Request/response transformation                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Invoke
                         │
┌────────────────────────▼────────────────────────────────────────┐
│              AWS Lambda Function                                 │
│  ┌──────────────────────────────────────────────────────┐      │
│  │ 1. Parse request body                                 │      │
│  │ 2. Validate input                                     │      │
│  │ 3. Create system prompt                               │      │
│  │ 4. Invoke Bedrock                                     │      │
│  │ 5. Parse JSON response                                │      │
│  │ 6. Return flashcards                                  │      │
│  └──────────────────────────────────────────────────────┘      │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ invoke_model()
                         │
┌────────────────────────▼────────────────────────────────────────┐
│              Amazon Bedrock                                      │
│  • Processes system prompt + notes                              │
│  • Generates structured flashcards                              │
│  • Returns JSON array                                            │
└──────────────────────────────────────────────────────────────────┘
```

## Request/Response Flow

```
User Input → API Gateway → Lambda → Bedrock → Lambda → API Gateway → User

1. User submits notes (POST /generate-flashcards)
2. API Gateway validates and forwards to Lambda
3. Lambda creates prompt with system instructions
4. Bedrock generates flashcards as JSON
5. Lambda parses and validates JSON
6. API Gateway returns flashcards to frontend
7. React displays flashcards to user
```

## Key Design Decisions

✅ **Serverless**: Auto-scaling, pay-per-use  
✅ **REST API**: Simple, widely supported  
✅ **JSON Output**: Structured, parseable  
✅ **Low Temperature**: Consistent formatting  
✅ **S3 Hosting**: Cost-effective, scalable

