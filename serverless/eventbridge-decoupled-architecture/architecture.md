# EventBridge Decoupled Architecture - Technical Architecture

## System Architecture

### Overview

This architecture implements a fully decoupled pizza ordering system using Amazon EventBridge as the central event bus. The system demonstrates event-driven microservices patterns with real-time client notifications via WebSocket API.

## Architecture Components

### 1. API Layer

#### HTTP API (Order Submission)
- **Purpose**: Receive pizza orders from clients
- **Type**: Amazon API Gateway HTTP API
- **Endpoints**:
  - `POST /order` - Submit new pizza order
- **Integration**: Lambda proxy integration
- **CORS**: Enabled for web client access

#### WebSocket API (Real-Time Updates)
- **Purpose**: Bidirectional real-time communication
- **Type**: Amazon API Gateway WebSocket API
- **Routes**:
  - `$connect` - Connection establishment
  - `$disconnect` - Connection cleanup
  - `$default` - Default message handler
- **Connection Management**: DynamoDB-backed

### 2. Event Processing Layer

#### Custom Event Bus
- **Name**: `pizza-orders-bus`
- **Purpose**: Central event routing hub
- **Event Sources**:
  - Order Handler Lambda (order placement)
  - Kitchen Processor Lambda (status updates)
- **Event Targets**:
  - Kitchen Processor Lambda
  - WebSocket Notifier Lambda
  - Future services (extensible)

#### Event Rules

**Kitchen Processing Rule**
```json
{
  "source": ["pizza.orders"],
  "detail-type": ["Order Placed"],
  "detail": {
    "status": ["RECEIVED"]
  }
}
- **Target**: Kitchen Processor Lambda
- **Purpose**: Route new orders to kitchen

**Notification Rule**
```json
{
  "source": ["pizza.kitchen"],
  "detail-type": ["Order Status Update"]
}
- **Target**: WebSocket Notifier Lambda
- **Purpose**: Send status updates to clients

### 3. Compute Layer (Lambda Functions)

#### Order Handler
- **Trigger**: API Gateway HTTP API
- **Purpose**: Validate and publish order events
- **Event Published**: `pizza.orders` / `Order Placed`
- **Runtime**: Python 3.x
- **Memory**: 256 MB
- **Timeout**: 10 seconds

#### Kitchen Processor
- **Trigger**: EventBridge rule (order placement)
- **Purpose**: Process orders and publish status updates
- **Events Published**: `pizza.kitchen` / `Order Status Update`
- **Processing Stages**:
  1. PREPARING - Ingredient preparation
  2. COOKING - Pizza in oven
  3. READY - Order complete
- **Runtime**: Python 3.x
- **Memory**: 512 MB
- **Timeout**: 30 seconds

#### WebSocket Notifier
- **Trigger**: EventBridge rule (status updates)
- **Purpose**: Send real-time updates to connected clients
- **Operations**:
  - Scan DynamoDB for active connections
  - Post messages to WebSocket API
  - Clean up stale connections
- **Runtime**: Python 3.x
- **Memory**: 256 MB
- **Timeout**: 15 seconds

#### WebSocket Connect Handler
- **Trigger**: WebSocket API `$connect` route
- **Purpose**: Store new connection IDs
- **Operations**:
  - Save connection ID to DynamoDB
  - Set TTL for automatic cleanup
- **Runtime**: Python 3.x
- **Memory**: 128 MB
- **Timeout**: 5 seconds

#### WebSocket Disconnect Handler
- **Trigger**: WebSocket API `$disconnect` route
- **Purpose**: Clean up connection records
- **Operations**:
  - Delete connection ID from DynamoDB
- **Runtime**: Python 3.x
- **Memory**: 128 MB
- **Timeout**: 5 seconds

### 4. Data Layer

#### DynamoDB Table: WebSocketConnections
- **Purpose**: Track active WebSocket connections
- **Primary Key**: `connectionId` (String)
- **Attributes**:
  - `connectionId` - WebSocket connection identifier
  - `connectedAt` - ISO timestamp of connection
  - `ttl` - Time-to-live for automatic cleanup
- **Billing Mode**: On-demand (PAY_PER_REQUEST)
- **TTL**: Enabled on `ttl` attribute (24 hours)

## Event Flow Diagrams

### Order Placement Flow

1. Client submits order
   ↓
2. HTTP API receives POST /order
   ↓
3. Order Handler Lambda validates request
   ↓
4. Order Handler publishes "Order Placed" event to EventBridge
   ↓
5. EventBridge routes event based on rules
   ↓
6. Kitchen Processor Lambda receives event
   ↓
7. Kitchen Processor simulates cooking stages
   ↓
8. Kitchen Processor publishes "Order Status Update" events
   ↓
9. WebSocket Notifier Lambda receives status events
   ↓
10. WebSocket Notifier sends updates to all connected clients

### WebSocket Connection Flow

1. Client establishes WebSocket connection
   ↓
2. WebSocket API triggers $connect route
   ↓
3. Connect Handler Lambda stores connection ID in DynamoDB
   ↓
4. Client receives connection confirmation
   ↓
5. Client listens for real-time updates
   ↓
6. When order status changes, Notifier Lambda:
   - Scans DynamoDB for active connections
   - Posts message to each connection via API Gateway
   - Removes stale connections
   ↓
7. Client receives real-time status update

## Event Schema Design

### Order Placed Event

```json
{
  "version": "0",
  "id": "event-id",
  "detail-type": "Order Placed",
  "source": "pizza.orders",
  "account": "ACCOUNT_ID",
  "time": "2024-01-15T10:30:00Z",
  "region": "us-east-1",
  "resources": [],
  "detail": {
    "orderId": "550e8400-e29b-41d4-a716-446655440000",
    "pizzaType": "Margherita",
    "size": "Large",
    "toppings": ["basil", "mozzarella"],
    "timestamp": "2024-01-15T10:30:00Z",
    "status": "RECEIVED"
  }
}

### Order Status Update Event

```json
{
  "version": "0",
  "id": "event-id",
  "detail-type": "Order Status Update",
  "source": "pizza.kitchen",
  "account": "ACCOUNT_ID",
  "time": "2024-01-15T10:32:00Z",
  "region": "us-east-1",
  "resources": [],
  "detail": {
    "orderId": "550e8400-e29b-41d4-a716-446655440000",
    "pizzaType": "Margherita",
    "size": "Large",
    "status": "COOKING",
    "message": "Pizza in the oven"
  }
}

## Security Architecture

### IAM Roles and Policies

#### Order Handler Role
- **Permissions**:
  - `events:PutEvents` on custom event bus
  - `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`

#### Kitchen Processor Role
- **Permissions**:
  - `events:PutEvents` on custom event bus
  - `logs:*` for CloudWatch Logs

#### WebSocket Notifier Role
- **Permissions**:
  - `execute-api:ManageConnections` on WebSocket API
  - `dynamodb:Scan` on WebSocketConnections table
  - `dynamodb:DeleteItem` for stale connection cleanup
  - `logs:*` for CloudWatch Logs

#### WebSocket Connection Handlers Role
- **Permissions**:
  - `dynamodb:PutItem`, `dynamodb:DeleteItem` on WebSocketConnections table
  - `logs:*` for CloudWatch Logs

### Network Security
- **API Gateway**: HTTPS/WSS only
- **Lambda**: VPC not required (using AWS service endpoints)
- **DynamoDB**: Encryption at rest enabled
- **EventBridge**: Events encrypted in transit

## Scalability Considerations

### Horizontal Scaling
- **Lambda**: Automatic scaling up to account limits
- **EventBridge**: Handles millions of events per second
- **API Gateway**: Scales automatically with traffic
- **DynamoDB**: On-demand scaling for variable workloads

### Performance Optimization
- **Lambda Memory**: Tuned based on function requirements
- **DynamoDB**: On-demand billing for unpredictable traffic
- **EventBridge**: Asynchronous processing eliminates bottlenecks
- **WebSocket**: Persistent connections reduce overhead

### Throttling and Limits
- **Lambda Concurrent Executions**: 1000 per region (default)
- **EventBridge**: 10,000 requests per second per event bus
- **API Gateway WebSocket**: 10,000 connections per second
- **DynamoDB**: No throughput limits with on-demand

## Reliability and Resilience

### Error Handling
- **Lambda Retries**: Automatic retries for EventBridge triggers (2 attempts)
- **Dead Letter Queues**: Configure SQS DLQ for failed events
- **Idempotency**: Use order IDs to prevent duplicate processing
- **Graceful Degradation**: WebSocket failures don't affect order processing

### Monitoring and Observability
- **CloudWatch Logs**: All Lambda functions log execution details
- **CloudWatch Metrics**:
  - Lambda invocations, errors, duration
  - EventBridge failed invocations
  - API Gateway request count, latency
  - DynamoDB read/write capacity
- **X-Ray Tracing**: Distributed tracing for request flows
- **EventBridge Monitoring**: Event delivery metrics

### Disaster Recovery
- **Multi-AZ**: All services are multi-AZ by default
- **Event Archive**: Enable EventBridge archive for event replay
- **DynamoDB Backups**: Point-in-time recovery enabled
- **Lambda Versioning**: Use aliases for safe deployments

## Cost Optimization

### Pricing Breakdown (Estimated)

**EventBridge**
- $1.00 per million events
- First 1 million events per month free

**Lambda**
- $0.20 per 1 million requests
- $0.0000166667 per GB-second
- First 1 million requests free

**API Gateway**
- HTTP API: $1.00 per million requests
- WebSocket: $1.00 per million messages
- First 1 million requests free

**DynamoDB**
- On-demand: $1.25 per million write requests
- $0.25 per million read requests
- First 25 GB storage free

### Cost Optimization Strategies
- Use on-demand billing for variable workloads
- Right-size Lambda memory allocations
- Implement connection pooling for WebSocket
- Use EventBridge archive only when needed
- Enable DynamoDB TTL for automatic cleanup

## Deployment Architecture

### Infrastructure as Code
- **CloudFormation**: Define all resources
- **AWS SAM**: Simplified serverless deployment
- **Terraform**: Alternative IaC option

### CI/CD Pipeline
1. Code commit to repository
2. Automated testing (unit, integration)
3. Build Lambda deployment packages
4. Deploy to staging environment
5. Run end-to-end tests
6. Deploy to production with canary deployment

### Multi-Environment Strategy
- **Development**: Separate event bus and resources
- **Staging**: Production-like environment for testing
- **Production**: Isolated resources with monitoring

## Extension Points

### Future Enhancements
1. **Payment Processing**: Add payment event handler
2. **Inventory Management**: Track ingredient availability
3. **Delivery Tracking**: GPS-based delivery updates
4. **Analytics**: Stream events to Kinesis for analysis
5. **SaaS Integration**: Connect to third-party services via EventBridge
6. **Schema Registry**: Validate events with EventBridge schemas
7. **Event Replay**: Use EventBridge archive for debugging

### Additional Event Consumers
- Email notifications (SES)
- SMS alerts (SNS)
- Mobile push notifications (SNS)
- Analytics dashboard (Kinesis + OpenSearch)
- Audit logging (S3 + Athena)

## Best Practices Implemented

✅ **Loose Coupling**: Services communicate only through events  
✅ **Single Responsibility**: Each Lambda has one clear purpose  
✅ **Idempotency**: Order IDs prevent duplicate processing  
✅ **Error Handling**: Comprehensive try-catch blocks  
✅ **Logging**: Structured logging for debugging  
✅ **Security**: Least privilege IAM policies  
✅ **Scalability**: Serverless auto-scaling  
✅ **Cost Optimization**: On-demand billing models  
✅ **Monitoring**: CloudWatch metrics and alarms  
✅ **Documentation**: Clear code comments and architecture docs
