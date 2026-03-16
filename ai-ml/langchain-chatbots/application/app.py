# Streamlit Chatbot with LangChain and DynamoDB Memory

import streamlit as st
from langchain_aws import ChatBedrock
from langchain.memory import DynamoDBChatMessageHistory, ConversationBufferMemory
from langchain.chains import ConversationChain
import boto3

# Configuration
MODEL_ID = "amazon.nova-lite-v1:0"
DYNAMODB_TABLE = "ChatHistory"

# Initialize session state
if 'conversation' not in st.session_state:
    # Create DynamoDB message history
    message_history = DynamoDBChatMessageHistory(
        table_name=DYNAMODB_TABLE,
        session_id=st.session_state.get('session_id', 'default')
    )
    
    # Create memory
    memory = ConversationBufferMemory(
        chat_memory=message_history,
        return_messages=True
    )
    
    # Create LLM
    llm = ChatBedrock(
        model_id=MODEL_ID,
        model_kwargs={"temperature": 0.7}
    )
    
    # Create conversation chain
    st.session_state.conversation = ConversationChain(
        llm=llm,
        memory=memory,
        verbose=True
    )
    
    st.session_state.messages = []

# UI
st.title("🤖 AI Chatbot with Memory")
st.caption("Powered by Amazon Bedrock and LangChain")

# Sidebar
with st.sidebar:
    st.header("Settings")
    
    # Session management
    if st.button("New Conversation"):
        st.session_state.clear()
        st.rerun()
    
    # Display session info
    st.info(f"Session: {st.session_state.get('session_id', 'default')}")

# Display chat history
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

# Chat input
if prompt := st.chat_input("Type your message..."):
    # Add user message to chat history
    st.session_state.messages.append({"role": "user", "content": prompt})
    
    # Display user message
    with st.chat_message("user"):
        st.markdown(prompt)
    
    # Get bot response
    with st.chat_message("assistant"):
        with st.spinner("Thinking..."):
            response = st.session_state.conversation.predict(input=prompt)
            st.markdown(response)
    
    # Add assistant response to chat history
    st.session_state.messages.append({"role": "assistant", "content": response})
