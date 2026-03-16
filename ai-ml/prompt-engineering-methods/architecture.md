# Architecture: Prompt Engineering Methods

## Prompt Engineering Framework

### Conceptual Architecture

┌────────────────────────────────────────────────────────────────┐
│                    Prompt Engineering Lifecycle                 │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    │
│  │   Define     │───▶│   Design     │───▶│    Test      │    │
│  │   Task       │    │   Prompt     │    │   & Eval     │    │
│  └──────────────┘    └──────────────┘    └──────┬───────┘    │
│                                                   │             │
│  ┌──────────────┐    ┌──────────────┐           │             │
│  │   Deploy     │◀───│   Refine     │◀──────────┘             │
│  │  to Prod     │    │  & Optimize  │                          │
│  └──────────────┘    └──────────────┘                          │
│                                                                 │
└────────────────────────────────────────────────────────────────┘

## Prompting Technique Comparison

### Zero-Shot Architecture

┌─────────────────────────────────────────────────────────┐
│                    Zero-Shot Prompt                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │  Instruction                                    │    │
│  │  "Summarize the following text in 3 sentences" │    │
│  └────────────────────────────────────────────────┘    │
│                         │                               │
│                         ▼                               │
│  ┌────────────────────────────────────────────────┐    │
│  │  Input Data                                     │    │
│  │  [Article text to summarize]                    │    │
│  └────────────────────────────────────────────────┘    │
│                         │                               │
│                         ▼                               │
│  ┌────────────────────────────────────────────────┐    │
│  │  Foundation Model Processing                    │    │
│  │  • Relies on pre-training                       │    │
│  │  • No examples to learn from                    │    │
│  │  • Direct task execution                        │    │
│  └────────────────────────────────────────────────┘    │
│                         │                               │
│                         ▼                               │
│  ┌────────────────────────────────────────────────┐    │
│  │  Output                                         │    │
│  │  [3-sentence summary]                           │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  Token Usage: LOW (instruction + input only)            │
│  Consistency: MODERATE                                  │
│  Quality: GOOD for common tasks                         │
│                                                          │
└─────────────────────────────────────────────────────────┘

### Few-Shot Architecture

┌─────────────────────────────────────────────────────────┐
│                    Few-Shot Prompt                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │  Instruction                                    │    │
│  │  "Classify customer inquiries"                  │    │
│  └────────────────────────────────────────────────┘    │
│                         │                               │
│                         ▼                               │
│  ┌────────────────────────────────────────────────┐    │
│  │  Example 1                                      │    │
│  │  Input: "How do I reset my password?"          │    │
│  │  Output: "Account Management"                   │    │
│  └────────────────────────────────────────────────┘    │
│                         │                               │
│                         ▼                               │
│  ┌────────────────────────────────────────────────┐    │
│  │  Example 2                                      │    │
│  │  Input: "My order hasn't arrived"              │    │
│  │  Output: "Shipping"                             │    │
│  └────────────────────────────────────────────────┘    │
│                         │                               │
│                         ▼                               │
│  ┌────────────────────────────────────────────────┐    │
│  │  Example 3                                      │    │
│  │  Input: "Do you offer discounts?"              │    │
│  │  Output: "Pricing"                              │    │
│  └────────────────────────────────────────────────┘    │
│                         │                               │
│                         ▼                               │
│  ┌────────────────────────────────────────────────┐    │
│  │  New Input                                      │    │
│  │  "Can I change my delivery address?"           │    │
│  └────────────────────────────────────────────────┘    │
│                         │                               │
│                         ▼                               │
│  ┌────────────────────────────────────────────────┐    │
│  │  Foundation Model Processing                    │    │
│  │  • Learns pattern from examples                 │    │
│  │  • Applies pattern to new input                 │    │
│  │  • Higher consistency                           │    │
│  └────────────────────────────────────────────────┘    │
│                         │                               │
│                         ▼                               │
│  ┌────────────────────────────────────────────────┐    │
│  │  Output                                         │    │
│  │  "Shipping"                                     │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  Token Usage: HIGH (instruction + examples + input)     │
│  Consistency: HIGH                                      │
│  Quality: EXCELLENT for specific formats                │
│                                                          │
└─────────────────────────────────────────────────────────┘

### Chain-of-Thought Architecture

┌─────────────────────────────────────────────────────────┐
│              Chain-of-Thought Prompt                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │  Instruction                                    │    │
│  │  "Solve this problem step by step"             │    │
│  └────────────────────────────────────────────────┘    │
│                         │                               │
│                         ▼                               │
│  ┌────────────────────────────────────────────────┐    │
│  │  Example with Reasoning                         │    │
│  │  Problem: Store has 150 items, sells 40%       │    │
│  │                                                 │    │
│  │  Step 1: Calculate sales: 150 × 0.40 = 60      │    │
│  │  Step 2: Remaining: 150 - 60 = 90              │    │
│  │  Answer: 90 items                               │    │
│  └────────────────────────────────────────────────┘    │
│                         │                               │
│                         ▼                               │
│  ┌────────────────────────────────────────────────┐    │
│  │  New Problem                                    │    │
│  │  [Complex multi-step problem]                   │    │
│  └────────────────────────────────────────────────┘    │
│                         │                               │
│                         ▼                               │
│  ┌────────────────────────────────────────────────┐    │
│  │  Foundation Model Processing                    │    │
│  │  • Generates intermediate reasoning steps       │    │
│  │  • Shows work before final answer               │    │
│  │  • Improves accuracy on complex tasks           │    │
│  └────────────────────────────────────────────────┘    │
│                         │                               │
│                         ▼                               │
│  ┌────────────────────────────────────────────────┐    │
│  │  Output with Reasoning                          │    │
│  │  Step 1: [calculation]                          │    │
│  │  Step 2: [calculation]                          │    │
│  │  Step 3: [calculation]                          │    │
│  │  Answer: [final result]                         │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  Token Usage: VERY HIGH (reasoning steps)               │
│  Consistency: HIGH                                      │
│  Quality: EXCELLENT for complex reasoning               │
│                                                          │
└─────────────────────────────────────────────────────────┘

## Parameter Impact on Prompting

### Temperature Effect on Different Prompting Techniques

┌─────────────────────────────────────────────────────────────┐
│              Temperature: 0.0 (Deterministic)                │
├─────────────────────────────────────────────────────────────┤
│  Zero-Shot:  Consistent, factual responses                  │
│  Few-Shot:   Strict adherence to example patterns           │
│  CoT:        Logical, step-by-step reasoning                │
│                                                              │
│  Best For: Code generation, data extraction, factual Q&A    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              Temperature: 0.7 (Balanced)                     │
├─────────────────────────────────────────────────────────────┤
│  Zero-Shot:  Varied but relevant responses                  │
│  Few-Shot:   Follows pattern with some creativity           │
│  CoT:        Logical with alternative approaches            │
│                                                              │
│  Best For: Summarization, Q&A, general content generation   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              Temperature: 1.0 (Creative)                     │
├─────────────────────────────────────────────────────────────┤
│  Zero-Shot:  Highly creative, unpredictable                 │
│  Few-Shot:   Creative variations on pattern                 │
│  CoT:        Multiple reasoning paths, creative solutions   │
│                                                              │
│  Best For: Creative writing, brainstorming, storytelling    │
└─────────────────────────────────────────────────────────────┘

## Decision Tree: Choosing Prompting Technique

                    Start: New Task
                          │
                          ▼
              ┌───────────────────────┐
              │ Is task well-defined  │
              │ and common?           │
              └───────┬───────────────┘
                      │
          ┌───────────┴───────────┐
          │                       │
         Yes                     No
          │                       │
          ▼                       ▼
    ┌──────────┐         ┌──────────────┐
    │Zero-Shot │         │ Specific      │
    │          │         │ format needed?│
    └──────────┘         └───────┬───────┘
                                 │
                     ┌───────────┴───────────┐
                     │                       │
                    Yes                     No
                     │                       │
                     ▼                       ▼
              ┌──────────┐         ┌──────────────┐
              │Few-Shot  │         │ Complex       │
              │(2-5 ex)  │         │ reasoning?    │
              └──────────┘         └───────┬───────┘
                                           │
                               ┌───────────┴───────────┐
                               │                       │
                              Yes                     No
                               │                       │
                               ▼                       ▼
                        ┌──────────┐         ┌──────────────┐
                        │Chain-of- │         │ One-Shot or  │
                        │Thought   │         │ Few-Shot     │
                        └──────────┘         └──────────────┘

## Token Usage Comparison

Technique      | Avg Tokens | Cost Factor | Use Case
---------------|------------|-------------|---------------------------
Zero-Shot      | 50-200     | 1x          | Simple, common tasks
One-Shot       | 150-400    | 2-3x        | Format demonstration
Few-Shot (3)   | 300-800    | 4-6x        | Pattern learning
Few-Shot (5)   | 500-1200   | 6-10x       | Complex patterns
Chain-of-Thought| 400-1500  | 8-15x       | Complex reasoning

## Iterative Refinement Process

┌─────────────────────────────────────────────────────────────┐
│                  Iteration Cycle                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Version 1: Basic Prompt                                    │
│  ┌────────────────────────────────────────────────┐        │
│  │ "Summarize this article"                        │        │
│  └────────────────────────────────────────────────┘        │
│           │                                                  │
│           ▼                                                  │
│  Test Results: Too vague, inconsistent length               │
│           │                                                  │
│           ▼                                                  │
│  Version 2: Add Specificity                                 │
│  ┌────────────────────────────────────────────────┐        │
│  │ "Summarize this article in 3 sentences"         │        │
│  └────────────────────────────────────────────────┘        │
│           │                                                  │
│           ▼                                                  │
│  Test Results: Better length, but misses key points         │
│           │                                                  │
│           ▼                                                  │
│  Version 3: Add Focus                                       │
│  ┌────────────────────────────────────────────────┐        │
│  │ "Summarize this article in 3 sentences,         │        │
│  │  focusing on key technical innovations"         │        │
│  └────────────────────────────────────────────────┘        │
│           │                                                  │
│           ▼                                                  │
│  Test Results: Good quality, meets requirements             │
│           │                                                  │
│           ▼                                                  │
│  Version 4: Add Format                                      │
│  ┌────────────────────────────────────────────────┐        │
│  │ "Summarize this article in 3 bullet points,     │        │
│  │  focusing on key technical innovations"         │        │
│  └────────────────────────────────────────────────┘        │
│           │                                                  │
│           ▼                                                  │
│  Test Results: Excellent - Deploy to production             │
│                                                              │
└─────────────────────────────────────────────────────────────┘

## Best Practices Architecture

### Prompt Structure Template

┌─────────────────────────────────────────────────────────────┐
│                  Optimal Prompt Structure                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Role/Context (Optional)                                 │
│     "You are an expert technical writer..."                 │
│                                                              │
│  2. Task Instruction (Required)                             │
│     "Summarize the following article..."                    │
│                                                              │
│  3. Format Specification (Recommended)                      │
│     "Provide output as 3 bullet points..."                  │
│                                                              │
│  4. Examples (If Few-Shot)                                  │
│     "Example 1: Input → Output"                             │
│     "Example 2: Input → Output"                             │
│                                                              │
│  5. Constraints (Optional)                                  │
│     "Do not include personal opinions..."                   │
│                                                              │
│  6. Input Data (Required)                                   │
│     "Article: [text]"                                       │
│                                                              │
│  7. Output Primer (Optional)                                │
│     "Summary:"                                              │
│                                                              │
└─────────────────────────────────────────────────────────────┘

## Key Takeaways

✅ Prompting technique selection impacts quality and cost  
✅ Zero-shot for simple tasks, few-shot for complex patterns  
✅ Chain-of-thought improves reasoning accuracy  
✅ Iteration is essential for optimization  
✅ Parameter tuning complements prompt design  
✅ Token usage scales with technique complexity

