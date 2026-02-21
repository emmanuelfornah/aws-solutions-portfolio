# Building Serverless Workflows with AWS Step Functions

## Overview

This lab demonstrates orchestrating complex serverless workflows using AWS Step Functions. You'll build a trivia game application that coordinates multiple Lambda functions using state machines with conditional logic, wait states, and error handling.

## AWS Services Used

- **AWS Step Functions** - Workflow orchestration
- **AWS Lambda** - Business logic functions
- **Amazon API Gateway** - WebSocket API for real-time updates
- **Amazon DynamoDB** - Game state storage
- **Amazon CloudWatch** - Monitoring and logging

## Architecture

```
┌──────────────────┐
│   API Gateway    │
│  (Start Game)    │
└────────┬─────────┘
         │
         │ Start Execution
         ▼
┌─────────────────────────────────────────┐
│      Step Functions State Machine       │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  1. Initialize Game             │   │
│  │     (Lambda)                    │   │
│  └──────────┬──────────────────────┘   │
│             │                           │
│             ▼                           │
│  ┌─────────────────────────────────┐   │
│  │  2. Ask Question                │   │
│  │     (Lambda)                    │   │
│  └──────────┬──────────────────────┘   │
│             │                           │
│             ▼                           │
│  ┌─────────────────────────────────┐   │
│  │  3. Wait for Answer             │   │
│  │     (Wait State - 30 seconds)   │   │
│  └──────────┬──────────────────────┘   │
│             │                           │
│             ▼                           │
│  ┌─────────────────────────────────┐   │
│  │  4. Check Answer                │   │
│  │     (Lambda)                    │   │
│  └──────────┬──────────────────────┘   │
│             │                           │
│             ▼                           │
│  ┌─────────────────────────────────┐   │
│  │  5. Choice State                │   │
│  │     More questions?             │   │
│  └──┬───────────────────────────┬──┘   │
│     │ Yes                       │ No   │
│     │ (Loop back)               │      │
│     ▼                           ▼      │
│  (Question 2)          ┌──────────┐    │
│                        │ End Game │    │
│                        │ (Lambda) │    │
│                        └──────────┘    │
└─────────────────────────────────────────┘
```

## Key Concepts

### State Machine Patterns

**Task State**: Execute Lambda function or other service  
**Wait State**: Delay for specified time  
**Choice State**: Conditional branching  
**Parallel State**: Execute branches concurrently  
**Map State**: Iterate over array items  
**Pass State**: Pass input to output (testing)  
**Succeed/Fail State**: Terminal states

### Workflow Orchestration Benefits
- **Visual Workflows**: See execution flow in console
- **Error Handling**: Automatic retries and catch blocks
- **Long-Running**: Up to 1 year execution time
- **State Management**: Automatic state passing
- **Audit Trail**: Complete execution history

### When to Use Step Functions
- Multi-step workflows with branching logic
- Long-running processes (hours/days)
- Human approval steps
- Complex error handling requirements
- Workflow visualization needs

## Objectives

- Design state machine for trivia game workflow
- Implement Lambda functions for each step
- Configure Choice states for conditional logic
- Add Wait states for user interaction time
- Handle errors with Retry and Catch
- Test workflow execution
- Monitor with CloudWatch

## Setup Instructions

### Step 1: Create State Machine

```bash
aws stepfunctions create-state-machine \
    --name TriviaGameWorkflow \
    --definition file://state-machine/trivia-game.json \
    --role-arn arn:aws:iam::ACCOUNT_ID:role/StepFunctionsExecutionRole
```

### Step 2: Deploy Lambda Functions

Functions needed:
- `initialize_game.py` - Set up game session
- `ask_question.py` - Retrieve and present question
- `check_answer.py` - Validate user response
- `end_game.py` - Calculate final score

### Step 3: Start Execution

```bash
aws stepfunctions start-execution \
    --state-machine-arn arn:aws:states:REGION:ACCOUNT_ID:stateMachine:TriviaGameWorkflow \
    --input file://test-input.json
```

### Step 4: Monitor Execution

```bash
# Get execution status
aws stepfunctions describe-execution \
    --execution-arn <execution-arn>

# View execution history
aws stepfunctions get-execution-history \
    --execution-arn <execution-arn>
```

## State Machine Definition

```json
{
  "Comment": "Trivia Game Workflow",
  "StartAt": "InitializeGame",
  "States": {
    "InitializeGame": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:REGION:ACCOUNT_ID:function:InitializeGame",
      "Next": "AskQuestion"
    },
    "AskQuestion": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:REGION:ACCOUNT_ID:function:AskQuestion",
      "Next": "WaitForAnswer"
    },
    "WaitForAnswer": {
      "Type": "Wait",
      "Seconds": 30,
      "Next": "CheckAnswer"
    },
    "CheckAnswer": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:REGION:ACCOUNT_ID:function:CheckAnswer",
      "Next": "MoreQuestions"
    },
    "MoreQuestions": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.questionNumber",
          "NumericLessThan": 10,
          "Next": "AskQuestion"
        }
      ],
      "Default": "EndGame"
    },
    "EndGame": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:REGION:ACCOUNT_ID:function:EndGame",
      "End": true
    }
  }
}
```

## Interview Talking Points

**Q: When to use Step Functions vs direct Lambda invocation?**
- **Step Functions**: Multi-step workflows, long-running, complex logic
- **Direct Lambda**: Simple, single-step operations
- **Cost**: Step Functions adds cost but provides orchestration value

**Q: How do you handle errors in Step Functions?**
- **Retry**: Automatic retry with exponential backoff
- **Catch**: Handle specific error types
- **Fallback**: Alternative execution path
- **DLQ**: Capture failed executions

**Q: What are the limits of Step Functions?**
- **Execution Time**: 1 year maximum
- **Execution History**: 25,000 events
- **State Machine Size**: 1 MB definition
- **Throughput**: Varies by region (thousands per second)

## Best Practices Implemented

✅ **Idempotent Functions**: Safe to retry  
✅ **Error Handling**: Retry and catch blocks  
✅ **Timeouts**: Prevent infinite waits  
✅ **Logging**: CloudWatch integration  
✅ **State Passing**: Minimal data transfer  
✅ **Modular Design**: Single-purpose functions

## Metadata

- **Completion Date**: 2024
- **Complexity Level**: Advanced
- **Estimated Time**: 60 minutes
- **Prerequisites**: Lambda, state machine concepts
