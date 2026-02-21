# Building Decoupled Architectures with Amazon EventBridge

## Overview

This lab demonstrates building a **pizza ordering system** using event-driven architecture with Amazon EventBridge. The system showcases how to create loosely coupled microservices that communicate through events, enabling scalability, flexibility, and real-time updates via WebSocket connections.

## AWS Services Used

- **Amazon EventBridge** - Custom event bus and event routing
- **AWS Lambda** - Event processing and business logic
- **Amazon API Gateway** - HTTP API for orders, WebSocket API for real-time updates
- **Amazon DynamoDB** - WebSocket connection tracking
- **AWS IAM** - Service permissions and roles
- **Amazon CloudWatch** - Logging and monitoring

## Architecture

This lab implements a decoupled pizza ordering system where components communicate exclusively through events:

### Architecture Diagram

```
┌─────────────┐
│   Client    │
│  (Browser)  │
└──────┬──────┘
       │
       │ HTTP POST /order
       ▼
┌─────────────────────┐
│   API Gateway       │
│   (HTTP API)        │
└──────┬──────────────┘
       │
       │ Invoke
       ▼
┌─────────────────────┐         ┌──────────────────────┐
│  Order Lambda       │────────>│   EventBridge        │
│  (Create Order)     │  Emit   │   Custom Event Bus   │
└─────────────────────┘  Event  └──────┬───────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
                    ▼                   ▼                   ▼
            ┌───────────────┐   ┌──────────────┐   ┌──────────────┐
            │ Kitchen Lambda│   │ Notify Lambda│   │ Other Lambda │
            │ (Process)     │   │ (WebSocket)  │   │ (Future)     │
            └───────────────┘   └──────┬───────┘   └──────────────┘
                                       │
                                       │ Send message
                                       ▼
                                ┌──────────────────┐
                                │  API Gateway     │
                                │  (WebSocket API) │
                                └──────┬───────────┘
                                       │
                                       ▼
                                ┌──────────────────┐
                                │    DynamoDB      │
                                │  (Connections)   │
                                └──────────────────┘
                                       │
                                       │ Real-time update
                                       ▼
                                ┌──────────────────┐
                                │     Client       │
                                │   (Browser)      │
                                └──────────────────┘
```

### Component Overview

1. **HTTP API Endpoint** - Receives pizza orders from clients
2. **Order Lambda** - Validates order and publishes event to EventBridge
3. **Custom Event Bus** - Routes events based on rules and patterns
4. **Kitchen Lambda** - Processes orders (simulates kitchen operations)
5. **Notification Lambda** - Sends real-time updates via WebSocket
6. **WebSocket API** - Manages bidirectional connections with clients
7. **DynamoDB Table** - Stores WebSocket connection IDs for message delivery

## Key Concepts

### Event-Driven Architecture Principles

1. **Loose Coupling**
   - Components don't directly call each other
   - Changes to one service don't affect others
   - Easy to add new event consumers

2. **Event Bus Pattern**
   - Central hub for event routing
   - Publishers don't know about subscribers
   - Rule-based event filtering and routing

3. **Custom Event Patterns**
   - Structured event schemas
   - Pattern matching for selective routing
   - Event metadata for context

### EventBridge Features

- **Custom Event Buses** - Isolated event routing domains
- **Event Rules** - Filter and route events to targets
- **Event Patterns** - JSON-based matching criteria
- **Multiple Targets** - Route single event to multiple services
- **Schema Registry** - Define and version event schemas
- **Archive and Replay** - Event history and debugging

### WebSocket Communication

- **Persistent Connections** - Real-time bidirectional communication
- **Connection Management** - Connect, disconnect, and message routes
- **Connection Tracking** - DynamoDB stores active connection IDs
- **Push Notifications** - Server-initiated messages to clients

## Objectives

- Create a custom EventBridge event bus
- Configure event rules with custom patterns
- Build Lambda functions that publish and consume events
- Implement WebSocket API for real-time updates
- Manage WebSocket connections with DynamoDB
- Design loosely coupled, event-driven microservices

## Setup Instructions

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- Python 3.x installed
- Basic understanding of Lambda and API Gateway

### Step 1: Create Custom Event Bus

```bash
aws events create-event-bus --name pizza-orders-bus
```

### Step 2: Create DynamoDB Table for WebSocket Connections

```bash
aws dynamodb create-table \
    --table-name WebSocketConnections \
    --attribute-definitions AttributeName=connectionId,AttributeType=S \
    --key-schema AttributeName=connectionId,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
```

### Step 3: Deploy Lambda Functions

Deploy the following Lambda functions (see `scripts/` directory):

1. **order-handler** - Receives orders and publishes events
2. **kitchen-processor** - Processes order events
3. **websocket-notifier** - Sends WebSocket updates
4. **websocket-connect** - Handles WebSocket connections
5. **websocket-disconnect** - Cleans up connections

### Step 4: Create EventBridge Rules

Create rules to route events to Lambda targets:

```bash
# Rule for kitchen processing
aws events put-rule \
    --name pizza-order-to-kitchen \
    --event-bus-name pizza-orders-bus \
    --event-pattern file://configs/kitchen-rule-pattern.json

# Rule for notifications
aws events put-rule \
    --name pizza-order-to-notify \
    --event-bus-name pizza-orders-bus \
    --event-pattern file://configs/notify-rule-pattern.json
```

### Step 5: Create API Gateway Endpoints

1. **HTTP API** - For receiving orders
2. **WebSocket API** - For real-time updates

### Step 6: Test the System

```bash
# Place an order
curl -X POST https://<api-id>.execute-api.<region>.amazonaws.com/order \
  -H "Content-Type: application/json" \
  -d '{
    "pizzaType": "Margherita",
    "size": "Large",
    "toppings": ["basil", "mozzarella"]
  }'
```

## Scripts and Configurations

### Lambda Functions

- `scripts/order_handler.py` - Order creation and event publishing
- `scripts/kitchen_processor.py` - Order processing logic
- `scripts/websocket_notifier.py` - WebSocket message sender
- `scripts/websocket_connect.py` - Connection handler
- `scripts/websocket_disconnect.py` - Disconnection handler

### Event Patterns

- `configs/kitchen-rule-pattern.json` - Kitchen event routing
- `configs/notify-rule-pattern.json` - Notification event routing
- `configs/sample-order-event.json` - Example event structure

### IAM Policies

- `configs/lambda-eventbridge-policy.json` - Lambda to EventBridge permissions
- `configs/lambda-websocket-policy.json` - Lambda to API Gateway permissions

## Real-World Applications

### E-Commerce Order Processing
- Order placement triggers inventory check
- Payment processing event
- Shipping notification event
- Customer notification event

### IoT Device Management
- Device status events
- Alert and alarm events
- Firmware update events
- Analytics and reporting events

### Financial Transaction Processing
- Transaction validation
- Fraud detection
- Audit logging
- Customer notifications

## Interview Talking Points

### Architecture Decisions

**Q: Why use EventBridge instead of direct Lambda invocations?**
- **Loose Coupling**: Services don't need to know about each other
- **Flexibility**: Easy to add new consumers without changing producers
- **Scalability**: EventBridge handles routing and fan-out automatically
- **Observability**: Centralized event monitoring and debugging
- **Future-Proofing**: Can add SaaS integrations or additional services easily

**Q: How does this architecture scale?**
- **Horizontal Scaling**: Lambda functions scale independently
- **Event Bus Capacity**: EventBridge handles millions of events per second
- **No Bottlenecks**: No single point of failure in event routing
- **Async Processing**: Non-blocking event publishing

**Q: What are the trade-offs of event-driven architecture?**
- **Pros**: Scalability, flexibility, resilience, loose coupling
- **Cons**: Eventual consistency, debugging complexity, event ordering challenges
- **Mitigation**: Event correlation IDs, distributed tracing, idempotent consumers

### WebSocket Implementation

**Q: Why use WebSocket instead of polling?**
- **Efficiency**: Persistent connection reduces overhead
- **Real-Time**: Immediate updates without client requests
- **Reduced Latency**: No polling interval delays
- **Cost**: Fewer API calls compared to frequent polling

**Q: How do you handle WebSocket connection failures?**
- **Reconnection Logic**: Client-side exponential backoff
- **Connection Tracking**: DynamoDB TTL for stale connections
- **Error Handling**: Graceful degradation to polling if needed
- **Monitoring**: CloudWatch metrics for connection health

### Event Design

**Q: How do you design event schemas?**
- **Versioning**: Include schema version in events
- **Backward Compatibility**: Additive changes only
- **Required Fields**: Minimal required, maximal optional
- **Event Metadata**: Timestamp, correlation ID, source
- **Schema Registry**: EventBridge schema registry for validation

## Best Practices Implemented

### Security
- ✅ IAM roles with least privilege principle
- ✅ API Gateway authorization
- ✅ Encrypted data in transit (HTTPS/WSS)
- ✅ DynamoDB encryption at rest

### Reliability
- ✅ Dead letter queues for failed events
- ✅ Retry logic with exponential backoff
- ✅ Idempotent event processing
- ✅ Connection cleanup on disconnect

### Performance
- ✅ Asynchronous event processing
- ✅ Lambda memory optimization
- ✅ DynamoDB on-demand billing for variable load
- ✅ WebSocket connection pooling

### Observability
- ✅ CloudWatch Logs for all Lambda functions
- ✅ EventBridge event monitoring
- ✅ Custom CloudWatch metrics
- ✅ X-Ray tracing for distributed requests

## Troubleshooting

### Events Not Reaching Targets

**Issue**: Lambda functions not triggered by events

**Solutions**:
- Verify event pattern matches published events
- Check Lambda resource-based policy allows EventBridge
- Confirm event bus name in rules and publishers
- Review CloudWatch Logs for event delivery failures

### WebSocket Connection Issues

**Issue**: Clients can't receive real-time updates

**Solutions**:
- Verify connection ID stored in DynamoDB
- Check API Gateway WebSocket permissions
- Confirm Lambda has execute-api:ManageConnections permission
- Test WebSocket endpoint with wscat tool

### Event Pattern Matching

**Issue**: Events not matching expected patterns

**Solutions**:
- Use EventBridge test event pattern feature
- Validate JSON structure of published events
- Check for typos in event field names
- Review event pattern syntax (exact match vs prefix)

## Cost Optimization

- **EventBridge**: $1.00 per million events (first 1M free)
- **Lambda**: Pay per invocation and duration
- **API Gateway**: WebSocket $1.00 per million messages
- **DynamoDB**: On-demand pricing for variable traffic
- **Optimization**: Use Lambda reserved concurrency for predictable workloads

## Metadata

- **Completion Date**: 2024
- **Complexity Level**: Advanced
- **Estimated Time**: 60 minutes
- **Prerequisites**: Lambda, API Gateway, DynamoDB basics
- **Learning Path**: Event-driven architecture fundamentals

## Next Steps

- Explore **SNS/SQS Fan-out Pattern** for simpler messaging
- Learn **Step Functions** for workflow orchestration
- Implement **EventBridge Schema Registry** for event validation
- Add **EventBridge Archive** for event replay and debugging
- Integrate **SaaS applications** as event sources or targets

## Additional Resources

- [EventBridge Documentation](https://docs.aws.amazon.com/eventbridge/)
- [WebSocket API Documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api.html)
- [Event-Driven Architecture Patterns](https://aws.amazon.com/event-driven-architecture/)
- [Serverless Land Patterns](https://serverlessland.com/patterns)
