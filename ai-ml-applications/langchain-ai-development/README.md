# Simplifying AI Development with LangChain

## Lab Overview

**Duration:** 75 minutes | **Complexity:** Advanced | **Course:** AI for Developers

## Scenario

Learn the industry-standard LangChain framework for building production AI applications with reusable components, prompt templates, output parsers, and document loaders.

## AWS Services Used

- **Amazon Bedrock** - Foundation model access
- **LangChain** - AI application framework
- **Python** - Development language
- **Jupyter Notebook** - Interactive development

## Learning Objectives

1. Generate text with Bedrock models using LangChain
2. Utilize LangChain messages, prompt templates, and output parsers
3. Provide context to models with document loaders
4. Build chatbots with LangChain framework
5. Integrate LangChain components for production applications

## Key Concepts

### LangChain Components

**1. Models**: Foundation model wrappers
```python
from langchain_aws import ChatBedrock

llm = ChatBedrock(
    model_id="amazon.nova-lite-v1:0",
    model_kwargs={"temperature": 0.7}
)
```

**2. Prompt Templates**: Reusable prompts
```python
from langchain.prompts import PromptTemplate

template = PromptTemplate(
    input_variables=["product"],
    template="Write a description for {product}"
)
```

**3. Output Parsers**: Structured responses
```python
from langchain.output_parsers import PydanticOutputParser

parser = PydanticOutputParser(pydantic_object=Product)
```

**4. Document Loaders**: Context provision
```python
from langchain.document_loaders import S3FileLoader

loader = S3FileLoader("bucket", "key")
docs = loader.load()
```

## Sample Code

```python
from langchain_aws import ChatBedrock
from langchain.prompts import ChatPromptTemplate
from langchain.output_parsers import StrOutputParser

# Initialize model
llm = ChatBedrock(
    model_id="amazon.nova-lite-v1:0",
    model_kwargs={"temperature": 0.7}
)

# Create prompt template
prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant"),
    ("user", "{input}")
])

# Create chain
chain = prompt | llm | StrOutputParser()

# Invoke
result = chain.invoke({"input": "Explain AWS Lambda"})
print(result)
```

## Key Takeaways

✅ LangChain simplifies AI application development  
✅ Reusable components improve code quality  
✅ Prompt templates enable consistency  
✅ Output parsers structure responses  
✅ Document loaders provide context

---

**Lab Status:** ✅ Complete  
**Skills Gained:** LangChain framework, prompt templates, output parsers, document loaders

