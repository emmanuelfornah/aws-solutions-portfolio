# Practicing Prompt Engineering Methods

## Lab Overview

**Duration:** 60 minutes  
**Complexity:** Intermediate  
**Course:** AI for Developers

## Scenario

You're a cloud developer tasked with optimizing AI model performance through advanced prompt engineering techniques. This lab teaches you how to craft effective prompts using zero-shot, few-shot, and chain-of-thought methods to achieve optimal results from foundation models.

## AWS Services Used

- **Amazon Bedrock** - Managed foundation model service
- **Amazon Nova Micro** - Efficient text generation model
- **Meta Llama 3 8B Instruct** - Instruction-tuned foundation model

## Learning Objectives

By completing this lab, you will:

1. Master zero-shot, one-shot, and few-shot prompting techniques
2. Implement chain-of-thought prompting for complex reasoning
3. Develop iterative prompt refinement strategies
4. Optimize prompts for text summarization, Q&A, and content generation
5. Tune temperature and Top-P parameters for different use cases
6. Apply prompt engineering best practices for production systems

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                  Prompt Engineering Workflow                  │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Step 1: Define Task & Desired Output              │     │
│  │  • What do you want the model to do?               │     │
│  │  • What format should the output be?               │     │
│  └────────────┬───────────────────────────────────────┘     │
│               │                                              │
│               ▼                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Step 2: Select Prompting Technique                │     │
│  │  • Zero-shot: No examples                          │     │
│  │  • Few-shot: Provide examples                      │     │
│  │  • Chain-of-thought: Show reasoning                │     │
│  └────────────┬───────────────────────────────────────┘     │
│               │                                              │
│               ▼                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Step 3: Craft Initial Prompt                      │     │
│  │  • Clear instructions                              │     │
│  │  • Relevant context                                │     │
│  │  • Examples (if few-shot)                          │     │
│  └────────────┬───────────────────────────────────────┘     │
│               │                                              │
│               ▼                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Step 4: Test & Evaluate                           │     │
│  │  • Run prompt with test cases                      │     │
│  │  • Assess output quality                           │     │
│  │  • Identify issues                                 │     │
│  └────────────┬───────────────────────────────────────┘     │
│               │                                              │
│               ▼                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Step 5: Iterate & Refine                          │     │
│  │  • Adjust instructions                             │     │
│  │  • Add/modify examples                             │     │
│  │  • Tune parameters                                 │     │
│  └────────────┬───────────────────────────────────────┘     │
│               │                                              │
│               ▼                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Step 6: Production Deployment                     │     │
│  │  • Document final prompt                           │     │
│  │  • Set optimal parameters                          │     │
│  │  • Implement error handling                        │     │
│  └────────────────────────────────────────────────────┘     │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## Key Concepts

### 1. Zero-Shot Prompting

**Definition**: Asking the model to perform a task without providing examples.

**When to Use**:
- Simple, well-defined tasks
- Model has strong pre-training on the task
- Quick prototyping and testing
- Cost-sensitive applications (fewer tokens)

**Example**:
```
Prompt: "Summarize the following article in 3 sentences: [article text]"

No examples provided - model relies on pre-training.
```

**Pros**:
- Fastest to implement
- Minimal token usage
- Works well for common tasks

**Cons**:
- Less control over output format
- May not handle edge cases well
- Quality varies by model capability

### 2. One-Shot Prompting

**Definition**: Providing a single example to guide the model's response.

**When to Use**:
- Specific output format required
- Task is somewhat ambiguous
- Balance between simplicity and guidance
- Token budget is moderate

**Example**:
```
Prompt: "Extract key information from customer reviews.

Example:
Review: "Great product! Fast shipping but packaging was damaged."
Output: {"sentiment": "positive", "issues": ["damaged packaging"], "praise": ["fast shipping"]}

Now extract from this review:
Review: "Terrible quality. Broke after one use. Waste of money."
Output:
```

**Pros**:
- Clear format demonstration
- Better consistency than zero-shot
- Efficient token usage

**Cons**:
- Single example may not cover variations
- Less robust than few-shot

### 3. Few-Shot Prompting

**Definition**: Providing multiple examples (typically 2-5) to establish a pattern.

**When to Use**:
- Complex or nuanced tasks
- Specific format or style required
- Edge cases need to be handled
- Quality is more important than cost

**Example**:
```
Prompt: "Classify customer inquiries into categories.

Example 1:
Inquiry: "How do I reset my password?"
Category: Account Management

Example 2:
Inquiry: "My order hasn't arrived yet."
Category: Shipping

Example 3:
Inquiry: "Do you offer student discounts?"
Category: Pricing

Now classify:
Inquiry: "Can I change my delivery address?"
Category:
```

**Pros**:
- High accuracy and consistency
- Handles edge cases better
- Clear pattern establishment

**Cons**:
- Higher token usage (cost)
- Requires careful example selection
- Longer prompts

### 4. Chain-of-Thought (CoT) Prompting

**Definition**: Encouraging the model to show its reasoning process step-by-step.

**When to Use**:
- Complex reasoning tasks
- Mathematical or logical problems
- Multi-step processes
- Debugging or explanation needed

**Example**:
```
Prompt: "Solve this problem step by step:

Problem: A store has 150 items. They sell 40% on Monday and 30% of the remaining on Tuesday. How many items are left?

Let's think through this step by step:
1. Calculate Monday sales: 150 × 0.40 = 60 items sold
2. Remaining after Monday: 150 - 60 = 90 items
3. Calculate Tuesday sales: 90 × 0.30 = 27 items sold
4. Final remaining: 90 - 27 = 63 items

Answer: 63 items remain.

Now solve this problem step by step:
Problem: A company has 200 employees. 25% work remotely and 40% of office workers are in sales. How many office workers are NOT in sales?
```

**Pros**:
- Improved accuracy on complex tasks
- Transparent reasoning process
- Better handling of multi-step problems
- Easier to debug errors

**Cons**:
- Significantly higher token usage
- Slower response times
- May be overkill for simple tasks

## Prompt Engineering Best Practices

### 1. Be Specific and Clear

❌ **Bad**: "Tell me about AWS"
✅ **Good**: "Explain the three main benefits of using AWS Lambda for serverless applications in 2-3 sentences."

### 2. Provide Context

❌ **Bad**: "Is this good?"
✅ **Good**: "As a technical reviewer, evaluate this code snippet for security vulnerabilities: [code]"

### 3. Specify Output Format

❌ **Bad**: "List AWS services"
✅ **Good**: "List 5 AWS compute services in JSON format: {\"service\": \"name\", \"description\": \"brief description\"}"

### 4. Use Delimiters

✅ **Good**:
```
Summarize the text between triple quotes:

\"\"\"
[Long text here]
\"\"\"

Summary:
```

### 5. Iterate and Refine

```
Version 1: "Summarize this article"
↓ (Too vague)
Version 2: "Summarize this article in 3 sentences"
↓ (Better, but no focus)
Version 3: "Summarize this article in 3 sentences, focusing on key technical innovations"
↓ (Good!)
```

## Parameter Tuning for Prompt Engineering

### Temperature Settings

```
Task Type              | Recommended Temperature | Reasoning
-----------------------|------------------------|---------------------------
Code generation        | 0.0 - 0.3              | Deterministic, correct syntax
Data extraction        | 0.0 - 0.2              | Factual, consistent
Summarization          | 0.3 - 0.5              | Balanced accuracy
Q&A systems            | 0.3 - 0.5              | Factual with some flexibility
Creative writing       | 0.7 - 0.9              | Diverse, creative output
Brainstorming          | 0.8 - 1.0              | Maximum creativity
```

### Top-P (Nucleus Sampling)

```
Top-P Value | Use Case                    | Output Characteristics
------------|-----------------------------|-----------------------
0.1 - 0.3   | Factual tasks, code         | Very focused, predictable
0.4 - 0.6   | Balanced tasks              | Moderate diversity
0.7 - 0.9   | Creative tasks              | High diversity
0.95 - 1.0  | Maximum creativity          | Unpredictable, varied
```

## Lab Tasks

### Task 1: Zero-Shot Prompting
1. Create prompts for text summarization without examples
2. Test with different article types
3. Evaluate output quality and consistency
4. Document when zero-shot is sufficient

### Task 2: Few-Shot Prompting
1. Design prompts with 2-3 examples
2. Test sentiment analysis with examples
3. Compare results with zero-shot approach
4. Optimize number of examples needed

### Task 3: Chain-of-Thought Prompting
1. Create CoT prompts for reasoning tasks
2. Test mathematical problem solving
3. Analyze reasoning quality
4. Compare with direct answer prompts

### Task 4: Iterative Refinement
1. Start with basic prompt
2. Test and identify issues
3. Refine instructions and context
4. Document improvement process

### Task 5: Parameter Optimization
1. Test same prompt with different temperatures
2. Compare Top-P values for creative vs factual tasks
3. Find optimal settings for each use case
4. Document parameter recommendations

## Common Use Cases

### Text Summarization

**Zero-Shot**:
```
Summarize the following article in 3 bullet points: [article]
```

**Few-Shot**:
```
Summarize articles in 3 bullet points.

Article: [example 1]
Summary:
• Point 1
• Point 2
• Point 3

Article: [example 2]
Summary:
• Point 1
• Point 2
• Point 3

Article: [new article]
Summary:
```

### Sentiment Analysis

**Few-Shot with CoT**:
```
Analyze sentiment with reasoning.

Review: "Great product but slow shipping"
Reasoning: Positive product feedback, negative shipping experience
Sentiment: Mixed (60% positive, 40% negative)

Review: [new review]
Reasoning:
Sentiment:
```

### Content Generation

**One-Shot with Style**:
```
Write product descriptions in this style:

Example:
Product: Wireless Headphones
Description: "Immerse yourself in crystal-clear audio with our premium wireless headphones. Featuring 30-hour battery life and active noise cancellation, these headphones transform your listening experience."

Product: Smart Watch
Description:
```

## Interview Talking Points

### Prompt Engineering Strategy

**Q: How do you approach prompt engineering for a new use case?**

1. **Understand Requirements**: Define task, output format, quality criteria
2. **Start Simple**: Begin with zero-shot, add complexity as needed
3. **Test Systematically**: Use representative test cases
4. **Iterate Based on Results**: Refine instructions, add examples
5. **Optimize Parameters**: Tune temperature and top-p
6. **Document**: Record successful prompts and settings

### Few-Shot vs Fine-Tuning

**Q: When should you use few-shot prompting vs fine-tuning?**

**Use Few-Shot When**:
- Quick deployment needed
- Task changes frequently
- Limited training data
- Cost-sensitive (no training costs)
- Multiple tasks with one model

**Use Fine-Tuning When**:
- Consistent task over time
- Large training dataset available
- Specific domain terminology
- Lower inference cost needed (shorter prompts)
- Maximum accuracy required

### Cost Optimization

**Q: How do you balance prompt quality with cost?**

1. **Start with zero-shot**: Test if sufficient
2. **Add examples incrementally**: Find minimum needed
3. **Optimize prompt length**: Remove unnecessary context
4. **Cache common prompts**: Reuse responses (API)
5. **Choose appropriate model**: Smaller models for simple tasks
6. **Monitor token usage**: Track and optimize

## Troubleshooting

### Issue: Inconsistent Output Format

**Solution**:
- Add explicit format instructions
- Use few-shot examples showing exact format
- Add "Output format:" section to prompt
- Lower temperature for consistency

### Issue: Model Ignores Instructions

**Solution**:
- Make instructions more explicit
- Use stronger directive language ("You must...")
- Add examples demonstrating compliance
- Place instructions at beginning and end

### Issue: Hallucinations (Incorrect Facts)

**Solution**:
- Lower temperature (0.0-0.3)
- Add "Only use information provided" instruction
- Implement RAG for factual grounding
- Use chain-of-thought to show reasoning

### Issue: Output Too Verbose

**Solution**:
- Specify exact length ("in 50 words or less")
- Add "Be concise" instruction
- Provide brief examples
- Adjust max tokens parameter

## Best Practices Summary

✅ **Do**:
- Start simple, add complexity as needed
- Test with diverse examples
- Document successful prompts
- Iterate based on results
- Consider token costs
- Use appropriate parameters

❌ **Don't**:
- Assume first prompt is optimal
- Use same prompt for all models
- Ignore output format specification
- Forget to test edge cases
- Overlook parameter tuning
- Skip documentation

## Next Steps

After completing this lab:

1. **Python SDK Lab**: Implement prompts programmatically
2. **Application Integration**: Use prompts in production apps
3. **RAG Implementation**: Combine prompting with knowledge bases
4. **Guardrails Lab**: Add safety controls to prompts

## Additional Resources

- [Prompt Engineering Guide](https://www.promptingguide.ai/)
- [Amazon Bedrock Prompt Engineering](https://docs.aws.amazon.com/bedrock/latest/userguide/prompt-engineering.html)
- [Chain-of-Thought Paper](https://arxiv.org/abs/2201.11903)
- [Few-Shot Learning Research](https://arxiv.org/abs/2005.14165)

## Key Takeaways

✅ Prompt engineering significantly impacts model performance  
✅ Zero-shot works for simple tasks; few-shot for complex ones  
✅ Chain-of-thought improves reasoning on complex problems  
✅ Iteration and testing are essential for optimization  
✅ Parameter tuning complements prompt design  
✅ Documentation enables reproducibility and improvement

---

**Lab Status:** ✅ Complete  
**Skills Gained:** Zero-shot prompting, few-shot prompting, chain-of-thought, iterative refinement, parameter tuning

