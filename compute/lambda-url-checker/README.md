# Serverless URL Checker with Lambda

## Overview

Implements a URL availability checker as an AWS Lambda function, packaged as a deployment package with external dependencies. Demonstrates Lambda packaging, layer management, and invocation patterns.

## AWS Services Used

- **AWS Lambda** - Serverless compute for URL checking
- **AWS IAM** - Execution role with least-privilege permissions
- **Amazon CloudWatch** - Function logs and metrics

## Architecture

```
┌──────────────────┐     Invoke      ┌──────────────────┐
│  Event Source     │ ─────────────> │  Lambda Function  │
│  (manual/scheduled)│               │  url_checker      │
└──────────────────┘                 └────────┬─────────┘
                                              │
                                              │ HTTP/HTTPS
                                              ▼
                                     ┌──────────────────┐
                                     │  Target URLs     │
                                     └──────────────────┘
```

## Technical Highlights

- Lambda deployment package with `requests` library bundled
- Function packaged as .zip with dependencies in `/python` directory
- Environment variables for configurable URL targets
- CloudWatch Logs for execution output and error tracking
- Comparison of Lambda vs EC2 for the same workload (cost, scaling, maintenance)
