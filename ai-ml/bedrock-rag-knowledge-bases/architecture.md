# Architecture: RAG with Knowledge Bases

## RAG Architecture

User Query → Embedding → Vector Search → Context Retrieval → LLM Generation → Response with Citations

## Components

1. **S3 Data Source**: Company documents
2. **Titan Embeddings**: Text → Vectors
3. **OpenSearch Serverless**: Vector similarity search
4. **Foundation Model**: Context-aware generation
5. **Citations**: Source attribution

## Key Benefits

✅ No custom vector DB code  
✅ Managed ingestion pipeline  
✅ Automatic chunking  
✅ Source citations  
✅ Real-time updates

