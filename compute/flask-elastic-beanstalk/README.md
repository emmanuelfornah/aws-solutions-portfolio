# Flask API on Elastic Beanstalk

## Overview

Deploys a Flask REST API to AWS Elastic Beanstalk with rolling deployments. Demonstrates platform-as-a-service deployment where Beanstalk manages the underlying EC2 instances, load balancer, and auto scaling.

## AWS Services Used

- **AWS Elastic Beanstalk** - Managed application platform
- **Amazon EC2** - Compute (managed by Beanstalk)
- **Elastic Load Balancing** - Traffic distribution (managed by Beanstalk)
- **Amazon CloudWatch** - Health monitoring and logs

## Architecture

```
┌──────────┐     HTTP     ┌─────────────────────────────────────┐
│  Client  │ ──────────> │  Elastic Beanstalk Environment      │
│          │             │                                     │
└──────────┘             │  ┌─────┐    ┌──────┐   ┌──────┐   │
                         │  │ ALB │───>│ EC2  │   │ EC2  │   │
                         │  └─────┘    │Flask │   │Flask │   │
                         │             └──────┘   └──────┘   │
                         │         Auto Scaling Group         │
                         └─────────────────────────────────────┘
```

## Technical Highlights

- Flask application with `application.py` entry point (Beanstalk convention)
- `requirements.txt` for automatic dependency installation
- Rolling deployment policy for zero-downtime updates
- Beanstalk environment configuration via `.ebextensions/`
- Health check endpoint for load balancer target monitoring
