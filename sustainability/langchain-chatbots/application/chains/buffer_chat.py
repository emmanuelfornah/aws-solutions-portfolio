# Simple chatbot with buffer memory (full conversation history)

from langchain_aws import ChatBedrock
from langchain.memory import ConversationBufferMemory
from langchain.chains import ConversationChain

# Initialize model
llm = ChatBedrock(
    model_id="amazon.nova-lite-v1:0",
    model_kwargs={"temperature": 0.7}
)

# Create buffer memory (stores full conversation)
memory = ConversationBufferMemory()

# Create conversation chain
conversation = ConversationChain(
    llm=llm,
    memory=memory,
    verbose=True
)

# Chat loop
print("Chatbot with Buffer Memory")
print("Type 'quit' to exit\n")

while True:
    user_input = input("You: ")
    
    if user_input.lower() == 'quit':
        break
    
    response = conversation.predict(input=user_input)
    print(f"Bot: {response}\n")
