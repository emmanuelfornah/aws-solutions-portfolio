# Performing RAG with Knowledge Bases for Amazon Bedrock

## Lab Overview

**Duration:** 75 minutes | **Complexity:** Advanced | **Course:** AI for Developers

## Scenario

Implement Retrieval Augmented Generation (RAG) to enable foundation models to query proprietary company data using Amazon Bedrock Knowledge Bases, without writing custom vector database code.

## AWS Services Used

- **Amazon Bedrock Knowledge Bases** - Managed RAG solution
- **Amazon S3** - Document storage
- **OpenSearch Serverless** - Vector database
- **Amazon Titan Embeddings v2** - Text vectorization
- **Python (Boto3)** - API integration

## Learning Objectives

1. Create Amazon Bedrock knowledge base with S3 data sources
2. Implement RAG without custom vector database code
3. Configure vector embeddings with Titan Text Embeddings v2
4. Test knowledge base with console and RetrieveAndGenerate API
5. Analyze source attribution and citations
6. Query proprietary data with foundation models

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    User Application                           │
│  • Query: "What is our return policy?"                        │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         │ RetrieveAndGenerate API
                         │
┌────────────────────────▼─────────────────────────────────────┐
│              Amazon Bedrock Knowledge Base                    │
│  ┌────────────────────────────────────────────────────┐     │
│  │ Step 1: Retrieve                                    │     │
│  │ • Convert query to vector embedding                 │     │
│  │ • Search OpenSearch for similar documents           │     │
│  │ • Return top K relevant chunks                      │     │
│  └────────────────┬───────────────────────────────────┘     │
│                   │                                          │
│                   ▼                                          │
│  ┌────────────────────────────────────────────────────┐     │
│  │ Step 2: Generate                                    │     │
│  │ • Create prompt with retrieved context              │     │
│  │ • Invoke foundation model                           │     │
│  │ • Generate grounded response                        │     │
│  │ • Include source citations                          │     │
│  └────────────────────────────────────────────────────┘     │
└───────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌───────────────────────────────────────────────────────────────┐
│                    Data Sources                                │
├───────────────────────────────────────────────────────────────┤
│  Amazon S3                OpenSearch Serverless               │
│  • Company docs           • Vector embeddings                 │
│  • PDFs, TXT, MD          • Similarity search                 │
│  • Policies, FAQs         • Metadata filtering                │
└───────────────────────────────────────────────────────────────┘
```

## Key Concepts

### Retrieval Augmented Generation (RAG)

**Problem**: Foundation models don't know your proprietary data
**Solution**: Retrieve relevant documents, include in prompt

**Benefits**:
- Access to current, proprietary information
- Source attribution and citations
- No model fine-tuning required
- Easy to update knowledge base
- Reduces hallucinations

### RAG vs Fine-Tuning

| Aspect | RAG | Fine-Tuning |
|--------|-----|-------------|
| Data updates | Real-time | Requires retraining |
| Cost | Lower | Higher |
| Setup time | Hours | Days/weeks |
| Source attribution | Yes | No |
| Use case | Dynamic data | Specific style/format |

### Vector Embeddings

**Purpose**: Convert text to numerical vectors for similarity search

```python
# Text → Vector Embedding
"What is AWS Lambda?" → [0.23, -0.45, 0.67, ..., 0.12]  # 1536 dimensions

# Similar questions have similar vectors
"Explain AWS Lambda" → [0.25, -0.43, 0.69, ..., 0.14]  # Close in vector space
```

### Knowledge Base Components

1. **Data Source**: S3 bucket with documents
2. **Embedding Model**: Titan Text Embeddings v2
3. **Vector Store**: OpenSearch Serverless
4. **Foundation Model**: For generation (Nova, Claude, etc.)

## Sample Code

### Create Knowledge Base (Python)

```python
import boto3

bedrock_agent = boto3.client('bedrock-agent')

# Create knowledge base
response = bedrock_agent.create_knowledge_base(
    name='CompanyKnowledgeBase',
    description='Company policies and documentation',
    roleArn='arn:aws:iam::[ACCOUNT-ID]:role/BedrockKBRole',
    knowledgeBaseConfiguration={
        'type': 'VECTOR',
        'vectorKnowledgeBaseConfiguration': {
            'embeddingModelArn': 'arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0'
        }
    },
    storageConfiguration={
        'type': 'OPENSEARCH_SERVERLESS',
        'opensearchServerlessConfiguration': {
            'collectionArn': 'arn:aws:aoss:[REGION]:[ACCOUNT-ID]:collection/[COLLECTION-ID]',
            'vectorIndexName': 'bedrock-knowledge-base-index',
            'fieldMapping': {
                'vectorField': 'vector',
                'textField': 'text',
                'metadataField': 'metadata'
            }
        }
    }
)

knowledge_base_id = response['knowledgeBase']['knowledgeBaseId']
print(f"Knowledge Base ID: {knowledge_base_id}")
```

### Add Data Source

```python
# Add S3 data source
response = bedrock_agent.create_data_source(
    knowledgeBaseId=knowledge_base_id,
    name='CompanyDocuments',
    dataSourceConfiguration={
        'type': 'S3',
        's3Configuration': {
            'bucketArn': 'arn:aws:s3:::[BUCKET-NAME]',
            'inclusionPrefixes': ['documents/']
        }
    }
)

data_source_id = response['dataSource']['dataSourceId']

# Start ingestion job
bedrock_agent.start_ingestion_job(
    knowledgeBaseId=knowledge_base_id,
    dataSourceId=data_source_id
)
```

### Query Knowledge Base

```python
import boto3
import json

bedrock_agent_runtime = boto3.client('bedrock-agent-runtime')

def query_knowledge_base(query, knowledge_base_id):
    """
    Query knowledge base using RetrieveAndGenerate API.
    
    Args:
        query (str): User question
        knowledge_base_id (str): Knowledge base ID
    
    Returns:
        dict: Response with answer and citations
    """
    try:
        response = bedrock_agent_runtime.retrieve_and_generate(
            input={'text': query},
            retrieveAndGenerateConfiguration={
                'type': 'KNOWLEDGE_BASE',
                'knowledgeBaseConfiguration': {
                    'knowledgeBaseId': knowledge_base_id,
                    'modelArn': 'arn:aws:bedrock:us-east-1::foundation-model/amazon.nova-lite-v1:0',
                    'retrievalConfiguration': {
                        'vectorSearchConfiguration': {
                            'numberOfResults': 5
                        }
                    }
                }
            }
        )
        
        # Extract answer and citations
        answer = response['output']['text']
        citations = response.get('citations', [])
        
        # Format citations
        sources = []
        for citation in citations:
            for reference in citation.get('retrievedReferences', []):
                sources.append({
                    'content': reference['content']['text'],
                    'location': reference['location']['s3Location']['uri']
                })
        
        return {
            'answer': answer,
            'sources': sources,
            'session_id': response.get('sessionId')
        }
        
    except Exception as e:
        print(f"Error querying knowledge base: {str(e)}")
        return None

# Usage
result = query_knowledge_base(
    query="What is our company's return policy?",
    knowledge_base_id='[KNOWLEDGE-BASE-ID]'
)

print(f"Answer: {result['answer']}")
print(f"\nSources:")
for i, source in enumerate(result['sources'], 1):
    print(f"{i}. {source['location']}")
```

### Retrieve Only (No Generation)

```python
def retrieve_documents(query, knowledge_base_id, num_results=5):
    """
    Retrieve relevant documents without generation.
    """
    response = bedrock_agent_runtime.retrieve(
        knowledgeBaseId=knowledge_base_id,
        retrievalQuery={'text': query},
        retrievalConfiguration={
            'vectorSearchConfiguration': {
                'numberOfResults': num_results
            }
        }
    )
    
    results = []
    for result in response['retrievalResults']:
        results.append({
            'content': result['content']['text'],
            'score': result['score'],
            'location': result['location']['s3Location']['uri']
        })
    
    return results
```

## Best Practices

### Document Preparation

✅ **Do**:
- Use clear, well-structured documents
- Include metadata (title, date, category)
- Break long documents into logical sections
- Use consistent formatting
- Remove unnecessary content

### Chunking Strategy

- **Default**: 300 tokens with 20% overlap
- **Short docs**: Smaller chunks (200 tokens)
- **Long docs**: Larger chunks (500 tokens)
- **Code**: Function-level chunks
- **FAQs**: Question-answer pairs

### Query Optimization

```python
# Good queries
"What is the return policy for electronics?"
"How do I reset my password?"
"What are the requirements for remote work?"

# Poor queries
"Tell me everything"  # Too broad
"Policy"  # Too vague
"asdfgh"  # Nonsensical
```

## Interview Talking Points

**Q: RAG vs Fine-Tuning - when to use each?**

**Use RAG when**:
- Data changes frequently
- Need source attribution
- Multiple knowledge domains
- Quick deployment required
- Cost-sensitive

**Use Fine-Tuning when**:
- Specific style/tone required
- Domain-specific terminology
- Consistent behavior needed
- Data is static
- Maximum accuracy required

**Q: How do you handle hallucinations in RAG?**
- Use contextual grounding (Bedrock Guardrails)
- Set appropriate number of retrieved documents
- Implement confidence scoring
- Add "I don't know" capability
- Monitor and log responses
- Use source citations for verification

**Q: How do you optimize RAG performance?**
- Tune number of retrieved documents (K)
- Optimize chunk size and overlap
- Use metadata filtering
- Implement caching for common queries
- Monitor retrieval relevance scores
- A/B test different embedding models

## Key Takeaways

✅ RAG enables LLMs to access proprietary data  
✅ No custom vector database code required  
✅ Source attribution reduces hallucinations  
✅ Real-time data updates without retraining  
✅ OpenSearch Serverless handles vector search  
✅ Titan Embeddings v2 for text vectorization

---

**Lab Status:** ✅ Complete  
**Skills Gained:** RAG implementation, knowledge bases, vector embeddings, source attribution

