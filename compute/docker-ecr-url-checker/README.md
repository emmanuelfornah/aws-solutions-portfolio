# Using Dockerfile with Amazon ECR

## Overview

This lab demonstrates containerization of the URL checker application using Docker and Amazon Elastic Container Registry (ECR). It represents a critical step in the deployment evolution series, moving from traditional server deployments to containerized applications. By packaging the application in a Docker container and storing it in ECR, we achieve portability, consistency, and the foundation for orchestrated deployments with ECS, Fargate, and EKS.

## AWS Services Used

- **Amazon EC2**: Hosts Docker engine and runs containers
- **Amazon ECR**: Private container registry for storing Docker images
- **AWS Systems Manager (Session Manager)**: Secure shell access to EC2 instances
- **IAM**: Manages permissions for ECR access

## Key Technologies

- **Docker**: Container platform for packaging applications
- **Dockerfile**: Declarative instructions for building container images
- **Python 3**: Application runtime
- **Amazon Linux 2023**: Base operating system

## Architecture

This lab demonstrates a multi-instance container deployment pattern:

1. **Development Instance**: EC2 instance where Docker image is built
2. **Amazon ECR**: Central container registry storing the image
3. **Production Instance**: Separate EC2 instance pulling and running the container

### Container Benefits

- **Portability**: Run anywhere Docker is installed
- **Consistency**: Same environment from development to production
- **Isolation**: Application dependencies packaged together
- **Efficiency**: Lightweight compared to virtual machines
- **Scalability**: Easy to replicate across multiple instances

See [architecture.md](./architecture.md) for detailed architecture diagrams and explanations.

## Deployment Evolution Context

This lab is the **fourth step** in the deployment evolution series:

1. **EC2 Direct Deployment** - Manual setup on virtual machines
2. **Lambda Serverless** - Event-driven, fully managed compute
3. **Elastic Beanstalk** - Platform-as-a-Service with automatic scaling
4. **Docker/ECR** ← You are here - Containerization and registry
5. **ECS/Fargate** - Container orchestration (coming next)
6. **EKS** - Kubernetes-based orchestration (advanced)

Containerization bridges the gap between traditional deployments and modern orchestration platforms, providing the packaging format that ECS, Fargate, and EKS will use to manage applications at scale.

## Objectives

- Understand Docker containerization concepts and benefits
- Write a Dockerfile to containerize a Python application
- Install and configure Docker on Amazon Linux 2023
- Build Docker images from Dockerfiles
- Create and configure an Amazon ECR repository
- Authenticate Docker with ECR using AWS CLI
- Push Docker images to ECR
- Pull images from ECR on different EC2 instances
- Run containerized applications
- Demonstrate container portability across instances

## Setup Instructions

### Prerequisites

- AWS account with appropriate permissions
- Two EC2 instances running Amazon Linux 2023
- IAM role attached to instances with ECR permissions
- AWS Systems Manager Session Manager configured

### Step 1: Install Docker on EC2

On your development EC2 instance:

```bash
# Run the Docker installation script
./scripts/install-docker.sh

# Verify Docker installation
docker --version
docker info
```

### Step 2: Build the Docker Image

```bash
# Navigate to the application directory
cd application/

# Build the Docker image
../scripts/build-image.sh

# Verify the image was created
docker images
```

### Step 3: Create ECR Repository

```bash
# Create an ECR repository (replace region as needed)
aws ecr create-repository \
    --repository-name url-checker \
    --region us-east-1

# Note the repository URI from the output
```

### Step 4: Push Image to ECR

```bash
# Run the push script (update with your repository URI)
../scripts/push-to-ecr.sh <your-account-id> <region>

# Verify the image in ECR
aws ecr describe-images \
    --repository-name url-checker \
    --region us-east-1
```

### Step 5: Pull and Run on Another Instance

On your production EC2 instance:

```bash
# Install Docker
./scripts/install-docker.sh

# Pull and run the container
./scripts/pull-and-run.sh <your-account-id> <region>
```

## Scripts and Configurations

### application/Dockerfile

Defines the container image:
- Uses official Python 3.9 slim base image
- Sets up working directory
- Copies application files
- Installs Python dependencies
- Configures entrypoint for the URL checker

### application/url_checker.py

Python application that checks URL availability:
- Accepts URLs as command-line arguments
- Makes HTTP requests with error handling
- Displays results in a formatted table
- Handles connection errors and timeouts

### application/requirements.txt

Python dependencies:
- `requests`: HTTP library for making URL requests
- `tabulate`: Library for formatting output tables

### scripts/install-docker.sh

Installs Docker on Amazon Linux 2023:
- Updates system packages
- Installs Docker package
- Starts Docker service
- Adds ec2-user to docker group
- Enables Docker to start on boot

### scripts/build-image.sh

Builds the Docker image:
- Builds from Dockerfile in current directory
- Tags image as `url-checker:latest`
- Displays build progress

### scripts/push-to-ecr.sh

Authenticates and pushes to ECR:
- Retrieves ECR authentication token
- Logs Docker into ECR
- Tags image with ECR repository URI
- Pushes image to ECR

### scripts/pull-and-run.sh

Pulls and runs container from ECR:
- Authenticates with ECR
- Pulls the latest image
- Runs container with sample URLs
- Demonstrates container portability

## Key Learnings

### Docker Concepts

1. **Images vs Containers**: Images are templates; containers are running instances
2. **Layers**: Each Dockerfile instruction creates a layer, enabling caching
3. **Base Images**: Starting point for your image (e.g., python:3.9-slim)
4. **Entrypoint**: Command that runs when container starts

### Amazon ECR

1. **Private Registry**: Secure storage for Docker images within AWS
2. **Authentication**: Uses AWS credentials via `aws ecr get-login-password`
3. **Repository URI**: Format is `<account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>`
4. **Image Tags**: Version control for container images (e.g., latest, v1.0)

### Container Benefits Demonstrated

1. **Portability**: Same image runs on any EC2 instance with Docker
2. **Consistency**: No "works on my machine" problems
3. **Isolation**: Dependencies packaged with application
4. **Efficiency**: Fast startup compared to EC2 instance boot
5. **Scalability**: Easy to run multiple containers from same image

### Comparison to Previous Deployments

| Aspect | EC2 Direct | Lambda | Elastic Beanstalk | Docker/ECR |
|--------|-----------|--------|-------------------|------------|
| Setup Complexity | High | Low | Medium | Medium |
| Portability | Low | N/A | Medium | High |
| Consistency | Manual | Managed | Managed | High |
| Scaling | Manual | Automatic | Automatic | Manual (for now) |
| Control | Full | Limited | Medium | Full |
| Cost | Instance hours | Per request | Instance hours | Instance hours |

### Next Steps in Evolution

This containerized application is now ready for:
- **Amazon ECS**: Managed container orchestration
- **AWS Fargate**: Serverless container execution
- **Amazon EKS**: Kubernetes-based orchestration
- **CI/CD Integration**: Automated image builds and deployments

## Troubleshooting

### Docker Permission Denied

If you get "permission denied" errors:
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker
```

### ECR Authentication Failed

If ECR login fails:
```bash
# Verify IAM role has ECR permissions
aws sts get-caller-identity

# Check ECR policy allows ecr:GetAuthorizationToken
aws ecr get-login-password --region us-east-1
```

### Image Not Found in ECR

If pull fails:
```bash
# List images in repository
aws ecr describe-images --repository-name url-checker

# Verify repository URI is correct
aws ecr describe-repositories --repository-names url-checker
```

### Container Exits Immediately

If container stops right after starting:
```bash
# Check container logs
docker logs <container-id>

# Run container interactively for debugging
docker run -it url-checker:latest /bin/bash
```

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Amazon ECR User Guide](https://docs.aws.amazon.com/ecr/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker CLI Reference](https://docs.docker.com/engine/reference/commandline/cli/)

## Lab Metadata

- **Domain**: Compute
- **Complexity**: Intermediate
- **Estimated Time**: 60-90 minutes
- **AWS Services**: EC2, ECR, Systems Manager, IAM
- **Key Skills**: Docker, Containerization, Container Registries, Multi-instance Deployment
