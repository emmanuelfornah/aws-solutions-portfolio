# Creating Chatbots with LangChain

## Lab Overview

**Duration:** 90 minutes | **Complexity:** Advanced | **Course:** AI for Developers

## Scenario

Build advanced chatbots with conversation memory using LangChain chains, parallel execution (RunnableParallel), and persistent state storage in DynamoDB with Streamlit GUI.

## AWS Services Used

- **Amazon Bedrock** - Foundation models
- **Amazon DynamoDB** - Conversation memory storage
- **LangChain** - Chatbot framework
- **Streamlit** - GUI framework
- **Python** - Development language

## Learning Objectives

1. Organize LangChain components using chains and pipes (LCEL)
2. Chain runnables in parallel and sequence (RunnableParallel)
3. Manage conversation history with buffer, window, and summary memory
4. Use DynamoDB for stateful chatbot memory storage
5. Integrate AI tools into GUI with Streamlit
6. Build trivia assistant with persistent conversation state

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Streamlit GUI                              │
│  • User input                                                 │
│  • Chat history display                                       │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│              LangChain Chatbot                                │
│  ┌────────────────────────────────────────────────────┐     │
│  │ Conversation Chain                                  │     │
│  │ • Prompt template                                   │     │
│  │ • Memory (buffer/window/summary)                    │     │
│  │ • Model (Bedrock)                                   │     │
│  │ • Output parser                                     │     │
│  └────────────────┬───────────────────────────────────┘     │
│                   │                                          │
│                   ▼                                          │
│  ┌────────────────────────────────────────────────────┐     │
│  │ Memory Management                                   │     │
│  │ • Load conversation history                         │     │
│  │ • Add new messages                                  │     │
│  │ • Save to DynamoDB                                  │     │
│  └────────────────────────────────────────────────────┘     │
└───────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌───────────────────────────────────────────────────────────────┐
│              Amazon DynamoDB                                   │
│  • Session ID (partition key)                                 │
│  • Timestamp (sort key)                                       │
│  • Message history                                            │
│  • Metadata                                                   │
└───────────────────────────────────────────────────────────────┘
```

## Key Concepts

### Memory Types

**1. Buffer Memory**: Full conversation history
```python
from langchain.memory import ConversationBufferMemory

memory = ConversationBufferMemory()
```

**2. Window Memory**: Recent N messages
```python
from langchain.memory import ConversationBufferWindowMemory

memory = ConversationBufferWindowMemory(k=5)  # Last 5 messages
```

**3. Summary Memory**: Compressed history
```python
from langchain.memory import ConversationSummaryMemory

memory = ConversationSummaryMemory(llm=llm)
```

**4. DynamoDB Memory**: Persistent storage
```python
from langchain.memory import DynamoDBChatMessageHistory

history = DynamoDBChatMessageHistory(
    table_name="ChatHistory",
    session_id="user123"
)
```

### LangChain Expression Language (LCEL)

**Sequential Chains**:
```python
chain = prompt | model | output_parser
```

**Parallel Chains**:
```python
from langchain.schema.runnable import RunnableParallel

chain = RunnableParallel({
    "summary": summary_chain,
    "sentiment": sentiment_chain
})
```

## Sample Code

### DynamoDB-Backed Chatbot

```python
from langchain_aws import ChatBedrock
from langchain.memory import DynamoDBChatMessageHistory
from langchain.memory import ConversationBufferMemory
from langchain.chains import ConversationChain

# Initialize model
llm = ChatBedrock(
    model_id="amazon.nova-lite-v1:0",
    model_kwargs={"temperature": 0.7}
)

# Create DynamoDB message history
message_history = DynamoDBChatMessageHistory(
    table_name="ChatHistory",
    session_id="user123"
)

# Create memory with DynamoDB backend
memory = ConversationBufferMemory(
    chat_memory=message_history,
    return_messages=True
)

# Create conversation chain
conversation = ConversationChain(
    llm=llm,
    memory=memory,
    verbose=True
)

# Chat
response = conversation.predict(input="Hello!")
print(response)
```

### Streamlit Integration

```python
import streamlit as st
from langchain_aws import ChatBedrock
from langchain.memory import ConversationBufferMemory
from langchain.chains import ConversationChain

# Initialize session state
if 'memory' not in st.session_state:
    st.session_state.memory = ConversationBufferMemory()
    st.session_state.conversation = ConversationChain(
        llm=ChatBedrock(model_id="amazon.nova-lite-v1:0"),
        memory=st.session_state.memory
    )

# UI
st.title("AI Chatbot")

user_input = st.text_input("You:", key="input")

if user_input:
    response = st.session_state.conversation.predict(input=user_input)
    st.write(f"Bot: {response}")
```

## Best Practices

### Memory Management

✅ **Do**:
- Use window memory for long conversations
- Implement session timeouts
- Clear old sessions periodically
- Monitor DynamoDB costs
- Use summary memory for very long chats

### Cost Optimization

- Window memory reduces token usage
- Summary memory compresses history
- Set appropriate TTL on DynamoDB items
- Cache common responses
- Monitor conversation lengths

## Interview Talking Points

**Q: How do you scale stateful chatbots?**
- Use DynamoDB for distributed state
- Implement session management
- Load balance across Lambda instances
- Cache conversation summaries
- Monitor memory usage

**Q: How do you handle long conversations?**
- Use window memory (last N messages)
- Implement summary memory
- Periodic conversation reset
- Token limit monitoring
- Conversation branching

## Key Takeaways

✅ LangChain simplifies chatbot development  
✅ Multiple memory types for different use cases  
✅ DynamoDB enables persistent, scalable state  
✅ LCEL enables complex chain composition  
✅ Streamlit provides quick GUI development

---

**Lab Status:** ✅ Complete  
**Skills Gained:** LangChain chatbots, conversation memory, DynamoDB integration, Streamlit

