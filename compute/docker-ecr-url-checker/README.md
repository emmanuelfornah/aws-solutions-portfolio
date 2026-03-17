# Containerized URL Checker with Docker and ECR

## Overview

Containerizes the Python URL checker application using Docker and pushes the image to Amazon ECR. Demonstrates the full container lifecycle — build, tag, push, and pull from a private registry.

## AWS Services Used

- **Amazon ECR** - Private container image registry
- **Docker** - Container build and runtime
- **AWS IAM** - ECR authentication and push permissions
- **AWS CLI** - ECR login and image management

## Architecture

```
┌──────────────┐     docker build     ┌──────────────┐     docker push     ┌─────────────┐
│  Dockerfile  │ ──────────────────> │  Local Image │ ──────────────────> │  Amazon ECR │
│  + app code  │                     │              │                     │  (private)  │
└──────────────┘                     └──────────────┘                     └─────────────┘
```

## Technical Highlights

- Multi-stage Dockerfile for minimal image size
- ECR repository with image scanning enabled
- AWS CLI authentication flow: `aws ecr get-login-password | docker login`
- Image tagging strategy with version and `latest` tags
- ECR lifecycle policy for image retention management
