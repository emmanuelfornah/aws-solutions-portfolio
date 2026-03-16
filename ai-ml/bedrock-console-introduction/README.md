# Introduction to Amazon Bedrock Console

## Overview

**Duration:** 60 minutes  
**Complexity:** Intermediate

Hands-on exploration of Amazon Bedrock — testing various foundation models, experimenting with model parameters, and generating AI images with Amazon Nova Canvas.

## AWS Services Used

- **Amazon Bedrock** - Managed service for foundation models
- **Amazon Nova Lite** - Fast, cost-effective text generation model
- **Amazon Nova Canvas** - AI image generation model
- **Meta Llama 3** - Open-source foundation model for text generation

## Learning Objectives

By completing this project, you will:

1. Navigate the Amazon Bedrock console and understand its features
2. Test foundation models using text, chat, and image playgrounds
3. Experiment with model parameters (temperature, top-p, top-k)
4. Generate and modify AI images with Amazon Nova Canvas
5. Compare different foundation models for various use cases
6. Understand prompt engineering basics for optimal results

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Amazon Bedrock Console                    │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │     Text     │  │     Chat     │  │    Image     │      │
│  │  Playground  │  │  Playground  │  │  Playground  │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│         └──────────────────┼──────────────────┘              │
│                            │                                 │
│  ┌─────────────────────────▼──────────────────────────┐     │
│  │         Foundation Model Selection                  │     │
│  ├─────────────────────────────────────────────────────┤     │
│  │  • Amazon Nova Lite (text)                          │     │
│  │  • Amazon Nova Canvas (image)                       │     │
│  │  • Meta Llama 3 8B/70B (text)                       │     │
│  │  • Anthropic Claude (text)                          │     │
│  │  • Amazon Titan (text/embeddings)                   │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐     │
│  │         Model Parameters                            │     │
│  ├─────────────────────────────────────────────────────┤     │
│  │  • Temperature: 0.0 - 1.0 (creativity)              │     │
│  │  • Top-P: 0.0 - 1.0 (nucleus sampling)              │     │
│  │  • Top-K: 1 - 500 (token selection)                 │     │
│  │  • Max Tokens: Response length limit                │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Key Concepts

### Foundation Models

**Amazon Nova Lite**
- Fast, cost-effective text generation
- Ideal for simple tasks like summarization, Q&A
- Lower latency, lower cost per token
- Good for high-volume applications

**Amazon Nova Canvas**
- AI image generation from text prompts
- Supports image editing and variations
- Multiple aspect ratios and styles
- Watermark-free commercial use

**Meta Llama 3**
- Open-source foundation model
- Available in 8B and 70B parameter versions
- Strong reasoning and coding capabilities
- Customizable and fine-tunable

### Model Parameters

**Temperature (0.0 - 1.0)**
- Controls randomness in responses
- Low (0.0-0.3): Deterministic, focused, factual
- Medium (0.4-0.7): Balanced creativity and consistency
- High (0.8-1.0): Creative, diverse, unpredictable
- Use cases:
  - Low: Code generation, factual Q&A, data extraction
  - High: Creative writing, brainstorming, storytelling

**Top-P (Nucleus Sampling, 0.0 - 1.0)**
- Limits token selection to cumulative probability
- Lower values: More focused, consistent responses
- Higher values: More diverse token selection
- Often used instead of temperature
- Recommended: 0.9 for balanced results

**Top-K (1 - 500)**
- Limits selection to top K most likely tokens
- Lower values: More predictable responses
- Higher values: More diverse vocabulary
- Combines with Top-P for fine-tuned control

**Max Tokens**
- Maximum length of generated response
- Affects cost (charged per token)
- Set based on expected response length
- Typical ranges: 256-2048 tokens

## Tasks

### Task 1: Explore Bedrock Console
1. Navigate to Amazon Bedrock console
2. Review available foundation models
3. Check model access status
4. Understand pricing for different models

### Task 2: Text Playground
1. Select Amazon Nova Lite model
2. Test basic prompts for text generation
3. Experiment with temperature settings
4. Compare responses at different parameter values
5. Test summarization and Q&A tasks

### Task 3: Chat Playground
1. Switch to chat playground
2. Test multi-turn conversations
3. Observe conversation context handling
4. Compare Nova Lite vs Llama 3 responses
5. Test system prompts for role-playing

### Task 4: Image Generation
1. Access image playground
2. Generate images with Amazon Nova Canvas
3. Test different prompt styles
4. Modify generated images
5. Experiment with aspect ratios and styles

### Task 5: Parameter Tuning
1. Test same prompt with different temperatures
2. Compare Top-P vs Top-K effects
3. Observe token limit impact
4. Document optimal settings for different use cases

## Best Practices

### Prompt Engineering
- **Be Specific**: Clear, detailed instructions yield better results
- **Provide Context**: Include relevant background information
- **Use Examples**: Few-shot prompting improves accuracy
- **Iterate**: Refine prompts based on results
- **Set Constraints**: Specify format, length, style requirements

### Model Selection
- **Task Complexity**: Match model capability to task requirements
- **Cost vs Performance**: Balance quality with budget constraints
- **Latency Requirements**: Smaller models for real-time applications
- **Customization Needs**: Open-source models for fine-tuning

### Parameter Optimization
- **Start Conservative**: Begin with temperature 0.7, top-p 0.9
- **Test Systematically**: Change one parameter at a time
- **Document Results**: Track what works for different use cases
- **Consider Cost**: Higher max tokens = higher costs

## Common Use Cases

### Text Generation
- **Content Creation**: Blog posts, marketing copy, product descriptions
- **Summarization**: Document summaries, meeting notes, article abstracts
- **Q&A Systems**: Customer support, knowledge base queries
- **Code Generation**: Function creation, code explanation, debugging

### Image Generation
- **Marketing Assets**: Social media graphics, ad creatives
- **Product Visualization**: Concept art, design mockups
- **Content Illustration**: Blog images, presentation graphics
- **Creative Exploration**: Brainstorming, mood boards

## Interview Talking Points

### Model Selection Decisions
**Q: How do you choose between different foundation models?**
- Consider task complexity (simple vs advanced reasoning)
- Evaluate cost constraints (tokens per dollar)
- Assess latency requirements (real-time vs batch)
- Review model capabilities (multimodal, code, languages)
- Test with representative prompts

### Parameter Tuning Strategy
**Q: How do you optimize model parameters for production?**
- Start with recommended defaults
- A/B test different configurations
- Monitor quality metrics (accuracy, relevance)
- Balance creativity with consistency
- Document optimal settings per use case

### Cost Optimization
**Q: How do you manage costs for foundation model usage?**
- Choose appropriate model size for task
- Set reasonable max token limits
- Implement caching for repeated queries
- Use batch processing where possible
- Monitor usage with CloudWatch metrics

## Troubleshooting

### Issue: Model Access Denied
**Solution**: Request model access in Bedrock console settings. Access approval may take a few minutes.

### Issue: Poor Quality Responses
**Solution**: 
- Refine prompt with more specific instructions
- Adjust temperature (lower for factual, higher for creative)
- Provide examples in prompt (few-shot learning)
- Try different foundation models

### Issue: Inconsistent Results
**Solution**:
- Lower temperature for more deterministic output
- Reduce top-p value for focused responses
- Use seed parameter for reproducibility (API only)

### Issue: Truncated Responses
**Solution**:
- Increase max tokens parameter
- Simplify prompt to reduce input tokens
- Break complex tasks into smaller prompts

## Security Considerations

- **Data Privacy**: Bedrock doesn't use customer data for model training
- **Access Control**: Use IAM policies for least privilege access
- **Audit Logging**: Enable CloudTrail for API call tracking
- **Content Filtering**: Consider Bedrock Guardrails for production
- **PII Protection**: Avoid sending sensitive data in prompts

## Cost Considerations

### Pricing Model
- **Input Tokens**: Charged per 1,000 tokens
- **Output Tokens**: Typically higher rate than input
- **Model Variation**: Larger models cost more per token
- **No Minimum**: Pay only for what you use

### Cost Optimization Tips
- Use smaller models (Nova Lite) for simple tasks
- Set appropriate max token limits
- Implement prompt caching for repeated queries
- Batch similar requests when possible
- Monitor usage with AWS Cost Explorer

## Real-World Application

- **Model evaluation**: Before committing to a foundation model, teams use Bedrock playgrounds to evaluate response quality, latency, and cost across models
- **Prompt prototyping**: Product managers and designers prototype AI features in the console before handing off to engineering for SDK integration
- **Cost estimation**: Testing prompts in the console with different models helps estimate per-request costs before building production applications
- **Stakeholder demos**: Non-technical stakeholders can see AI capabilities firsthand in the console — accelerating buy-in for AI initiatives

## Next Steps

After completing this project:

1. **Prompt Engineering Project**: Learn advanced prompting techniques
2. **Python SDK Project**: Programmatic model invocation with Boto3
3. **Application Integration**: Build serverless AI applications
4. **RAG Implementation**: Integrate proprietary data with knowledge bases

## Additional Resources

- [Amazon Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Foundation Model Comparison](https://aws.amazon.com/bedrock/models/)
- [Prompt Engineering Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/prompt-engineering.html)
- [Bedrock Pricing](https://aws.amazon.com/bedrock/pricing/)

## Key Takeaways

✅ Amazon Bedrock provides managed access to multiple foundation models  
✅ Model parameters significantly impact response quality and cost  
✅ Different models excel at different tasks (text, code, reasoning)  
✅ Prompt engineering is critical for optimal results  
✅ Console playgrounds enable rapid experimentation and testing  
✅ Cost scales with model size and token usage

---

**Status:** ✅ Complete  
**Skills Demonstrated:** Foundation model basics, prompt engineering, parameter tuning, multimodal AI

