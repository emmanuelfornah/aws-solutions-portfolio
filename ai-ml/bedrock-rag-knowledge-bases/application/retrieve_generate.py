# RAG with Amazon Bedrock Knowledge Bases

import boto3
import json

# Initialize clients
bedrock_agent_runtime = boto3.client('bedrock-agent-runtime')

# Configuration
KNOWLEDGE_BASE_ID = '[KNOWLEDGE-BASE-ID]'
MODEL_ARN = 'arn:aws:bedrock:us-east-1::foundation-model/amazon.nova-lite-v1:0'

def query_knowledge_base(query, num_results=5):
    """
    Query knowledge base using RetrieveAndGenerate API.
    
    Args:
        query (str): User question
        num_results (int): Number of documents to retrieve
    
    Returns:
        dict: Response with answer and citations
    """
    try:
        response = bedrock_agent_runtime.retrieve_and_generate(
            input={'text': query},
            retrieveAndGenerateConfiguration={
                'type': 'KNOWLEDGE_BASE',
                'knowledgeBaseConfiguration': {
                    'knowledgeBaseId': KNOWLEDGE_BASE_ID,
                    'modelArn': MODEL_ARN,
                    'retrievalConfiguration': {
                        'vectorSearchConfiguration': {
                            'numberOfResults': num_results
                        }
                    }
                }
            }
        )
        
        # Extract answer
        answer = response['output']['text']
        
        # Extract citations
        sources = []
        for citation in response.get('citations', []):
            for reference in citation.get('retrievedReferences', []):
                sources.append({
                    'content': reference['content']['text'],
                    'location': reference['location']['s3Location']['uri'],
                    'score': reference.get('score', 0)
                })
        
        return {
            'answer': answer,
            'sources': sources,
            'session_id': response.get('sessionId')
        }
        
    except Exception as e:
        print(f"Error querying knowledge base: {str(e)}")
        return None


def retrieve_only(query, num_results=5):
    """
    Retrieve relevant documents without generation.
    
    Args:
        query (str): Search query
        num_results (int): Number of results
    
    Returns:
        list: Retrieved documents with scores
    """
    try:
        response = bedrock_agent_runtime.retrieve(
            knowledgeBaseId=KNOWLEDGE_BASE_ID,
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
        
    except Exception as e:
        print(f"Error retrieving documents: {str(e)}")
        return None


if __name__ == '__main__':
    # Example 1: Query with generation
    print("=== Example 1: RetrieveAndGenerate ===")
    result = query_knowledge_base("What is our company's return policy?")
    
    if result:
        print(f"Answer: {result['answer']}\n")
        print("Sources:")
        for i, source in enumerate(result['sources'], 1):
            print(f"{i}. {source['location']} (score: {source['score']:.2f})")
    
    # Example 2: Retrieve only
    print("\n=== Example 2: Retrieve Only ===")
    docs = retrieve_only("return policy", num_results=3)
    
    if docs:
        for i, doc in enumerate(docs, 1):
            print(f"\nDocument {i} (score: {doc['score']:.2f}):")
            print(f"Location: {doc['location']}")
            print(f"Content: {doc['content'][:200]}...")
