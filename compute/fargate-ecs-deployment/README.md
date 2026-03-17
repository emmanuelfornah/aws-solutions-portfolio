# Serverless Container Deployment with ECS Fargate

## Overview

Deploys a containerized application on Amazon ECS with Fargate launch type — serverless container orchestration without managing EC2 instances. Uses `awsvpc` networking for task-level network isolation.

## AWS Services Used

- **Amazon ECS** - Container orchestration
- **AWS Fargate** - Serverless compute engine for containers
- **Amazon ECR** - Container image registry
- **Elastic Load Balancing (ALB)** - Application-layer traffic routing
- **Amazon VPC** - `awsvpc` network mode for task-level ENIs

## Architecture

```
┌──────────┐     HTTP     ┌─────────┐           ┌─────────────────────┐
│  Client  │ ──────────> │   ALB   │ ────────> │  ECS Fargate Tasks  │
│          │             │         │           │                     │
└──────────┘             └─────────┘           │  ┌───────┐ ┌───────┐│
                                               │  │Task 1 │ │Task 2 ││
                                               │  │(ENI)  │ │(ENI)  ││
                                               │  └───────┘ └───────┘│
                                               │   Private Subnets   │
                                               └─────────────────────┘
```

## Technical Highlights

- Fargate launch type eliminates EC2 instance management
- `awsvpc` network mode assigns each task its own ENI and private IP
- Task definition with CPU/memory resource allocation
- ECS service with desired count and ALB target group integration
- Security group applied at the task level (not instance level)
- ECR image pull with task execution role
