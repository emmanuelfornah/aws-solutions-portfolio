# Skills Progression

## Overview

This portfolio documents progression through **44 hands-on AWS projects** spanning **200+ hours** of practical experience — from foundational EC2 deployments to production AI applications with LangChain and Bedrock.

## Progression by Phase

### Phase 1: Cloud Fundamentals
**Focus:** Core compute, storage, and networking

- EC2 instance deployment with Session Manager
- WordPress on LAMP stack with NLB and TLS
- VPC connectivity troubleshooting
- Route 53 private hosted zones

### Phase 2: Databases & Data Management
**Focus:** Relational and NoSQL databases, high availability

- DynamoDB table design — partition keys, GSIs, query optimization
- DynamoDB Streams with Lambda for change data capture
- DynamoDB auto scaling — provisioned vs on-demand capacity
- DAX caching for microsecond-latency reads

### Phase 3: Security & Compliance
**Focus:** Authentication, encryption, incident response, Zero Trust

- Cognito + API Gateway JWT authentication
- OIDC federated identity with AssumeRoleWithWebIdentity
- KMS customer-managed keys with envelope encryption
- WAF with OWASP Top 10 protection and rate-based rules
- Inspector automated CVE detection and remediation
- Zero Trust architecture with SigV4 and VPC endpoints
- Automated incident response (<10s detection-to-isolation)

### Phase 4: Serverless & Event-Driven
**Focus:** Lambda, API Gateway, Step Functions, messaging

- Lambda CRUD with DynamoDB and S3 static hosting
- API Gateway HTTP API with Lambda proxy integration
- SAM CLI workflow — build, deploy, local testing
- Step Functions state machines with error handling
- SNS/SQS fan-out with dead letter queues
- EventBridge custom event buses with WebSocket real-time updates
- Kinesis streaming pipeline with OpenSearch analytics

### Phase 5: Containers & Orchestration
**Focus:** Docker, ECS, Fargate, Kubernetes

- Docker containerization with ECR private registry
- Elastic Beanstalk PaaS with rolling deployments
- ECS Fargate serverless containers with awsvpc networking
- EKS Kubernetes — imperative and declarative deployments

### Phase 6: CI/CD & Automation
**Focus:** Pipelines, IaC, compliance, systems management

- CodePipeline with automated unit and integration testing
- Blue/green deployments with CodeDeploy and ALB
- CloudFormation with cfn-lint validation in pipelines
- CDK with Python L2 constructs
- Systems Manager automation, Distributor, and Config compliance
- CloudWatch custom metrics, dashboards, and Lambda Canary monitoring

### Phase 7: AI/ML Applications
**Focus:** Generative AI, LangChain, RAG, AI security

- Amazon Bedrock foundation model exploration and parameter tuning
- Prompt engineering — zero-shot, few-shot, chain-of-thought
- Boto3 SDK for programmatic model invocation
- Serverless AI flashcard app (Lambda + Bedrock + API Gateway)
- RAG with Knowledge Bases and vector embeddings
- LangChain chains, memory, and DynamoDB-backed chatbots
- Bedrock Guardrails — content filtering, PII detection, prompt injection mitigation

## Deployment Evolution

```
EC2 (manual) → Lambda (serverless) → Docker/ECS (containers) → EKS (orchestration)
```

## Security Maturity

```
Security Groups → KMS/Secrets Manager → Cognito/OIDC → Zero Trust → Automated Incident Response
```

## IaC Progression

```
Console (manual) → CloudFormation → SAM → CDK (programmatic)
```
