# Event-Driven Architecture

## Overview

Event-driven architecture (EDA) is a software design pattern where system components communicate through the production, detection, and consumption of events. This approach enables loosely coupled, scalable, and resilient applications that can respond to changes in real-time.

## Labs in This Category

### 1. Building Decoupled Architectures with Amazon EventBridge

**Services:** EventBridge, Lambda, API Gateway (HTTP & WebSocket), DynamoDB  
**Description:** Build a pizza ordering system demonstrating event-driven patterns with custom event buses, event rules, and real-time WebSocket updates  
**Duration:** ~60 minutes | **Complexity:** Advanced  
**Link:** [View Lab](./eventbridge-decoupled-architecture/)

### 2. Using Amazon SNS and SQS in Event-Driven Architectures

**Services:** S3, SNS, SQS, Lambda, CloudWatch  
**Description:** Implement an image processing pipeline using fan-out pattern with SNS and SQS for parallel processing  
**Duration:** 60 minutes | **Complexity:** Intermediate  
**Link:** [View Lab](./sns-sqs-fanout-pattern/)

### 3. Navigating through Kinesis

**Services:** Kinesis Data Streams, Kinesis Firehose, DynamoDB Streams, Lambda, OpenSearch, CloudWatch  
**Description:** Build real-time streaming data pipeline with Kinesis for processing and analyzing continuous data flows  
**Duration:** ~75 minutes | **Complexity:** Advanced  
**Link:** [View Lab](./kinesis-streaming-pipeline/)

## Skills Demonstrated

- Event-driven architecture design patterns
- Asynchronous message processing
- Real-time data streaming and processing
- Pub/sub and fan-out messaging patterns
- Event routing and filtering
- Decoupled microservices communication
- WebSocket real-time updates
- Stream processing and analytics
- Error handling and dead letter queues
- CloudWatch monitoring and observability

## Key Concepts

### Event-Driven Architecture Benefits
- **Loose Coupling** - Components don't need to know about each other
- **Scalability** - Independent scaling of producers and consumers
- **Resilience** - Failures in one component don't cascade
- **Flexibility** - Easy to add new event consumers
- **Real-Time Processing** - Immediate response to events

### AWS Messaging Services Comparison

| Service | Use Case | Pattern | Ordering | Retention |
|---------|----------|---------|----------|-----------|
| **EventBridge** | Complex routing, SaaS integration | Event bus | No | 24 hours (archive available) |
| **SNS** | Fan-out notifications | Pub/Sub | No | No retention |
| **SQS** | Message buffering, decoupling | Queue | FIFO available | Up to 14 days |
| **Kinesis** | Real-time streaming | Stream | Yes (per shard) | Up to 365 days |

## Architecture Patterns

### 1. Event Bus Pattern (EventBridge)
- Central event bus for routing
- Multiple event sources and targets
- Rule-based event filtering
- Schema registry for event contracts

### 2. Fan-Out Pattern (SNS + SQS)
- Single message to multiple consumers
- Parallel processing
- Independent consumer scaling
- Guaranteed delivery with SQS

### 3. Stream Processing Pattern (Kinesis)
- Continuous data ingestion
- Real-time analytics
- Multiple consumers on same stream
- Data replay capabilities

## Real-World Applications

- **E-commerce**: Order processing, inventory updates, shipping notifications
- **IoT**: Sensor data collection, real-time monitoring, alerting
- **Financial Services**: Transaction processing, fraud detection, audit logging
- **Media**: Content processing, transcoding, distribution
- **Gaming**: Player events, leaderboards, real-time multiplayer
