# Chatbot with DynamoDB persistent memory

from langchain_aws import ChatBedrock
from langchain.memory import DynamoDBChatMessageHistory, ConversationBufferMemory
from langchain.chains import ConversationChain
import uuid

# Initialize model
llm = ChatBedrock(
    model_id="amazon.nova-lite-v1:0",
    model_kwargs={"temperature": 0.7}
)

# Create unique session ID
session_id = str(uuid.uuid4())

# Create DynamoDB message history
message_history = DynamoDBChatMessageHistory(
    table_name="ChatHistory",
    session_id=session_id
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

# Chat loop
print(f"Chatbot with DynamoDB Memory (Session: {session_id})")
print("Type 'quit' to exit\n")

while True:
    user_input = input("You: ")
    
    if user_input.lower() == 'quit':
        break
    
    response = conversation.predict(input=user_input)
    print(f"Bot: {response}\n")

print(f"\nConversation saved to DynamoDB with session ID: {session_id}")
