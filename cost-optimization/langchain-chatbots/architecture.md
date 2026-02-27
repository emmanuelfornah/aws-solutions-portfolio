# Architecture: LangChain Chatbots

## Chatbot Architecture

```
User Input → Streamlit → LangChain Chain → Memory (DynamoDB) → Bedrock → Response
```

## Memory Types

- **Buffer**: Full history
- **Window**: Recent N messages
- **Summary**: Compressed history
- **DynamoDB**: Persistent storage

## Key Benefits

✅ Stateful conversations  
✅ Persistent memory  
✅ Scalable with DynamoDB  
✅ Easy GUI with Streamlit

