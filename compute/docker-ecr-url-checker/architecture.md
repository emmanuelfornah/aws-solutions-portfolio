# Docker and ECR Architecture

## Overview

This document describes the architecture of containerizing the URL checker application using Docker and storing it in Amazon Elastic Container Registry (ECR). The architecture demonstrates the fundamental pattern of building, storing, and deploying containerized applications in AWS.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Development Flow                         │ │
│  │                                                              │ │
│  │  ┌──────────────────┐                                       │ │
│  │  │  EC2 Instance    │                                       │ │
│  │  │  (Development)   │                                       │ │
│  │  │                  │                                       │ │
│  │  │  ┌────────────┐  │                                       │ │
│  │  │  │  Docker    │  │    1. Build Image                    │ │
│  │  │  │  Engine    │  │    ─────────────►                    │ │
│  │  │  └────────────┘  │                                       │ │
│  │  │                  │                                       │ │
│  │  │  ┌────────────┐  │                                       │ │
│  │  │  │Dockerfile  │  │                                       │ │
│  │  │  │url_checker │  │                                       │ │
│  │  │  │requirements│  │                                       │ │
│  │  │  └────────────┘  │                                       │ │
│  │  └──────────────────┘                                       │ │
│  │           │                                                  │ │
│  │           │ 2. Push Image                                   │ │
│  │           ▼                                                  │ │
│  │  ┌──────────────────┐                                       │ │
│  │  │   Amazon ECR     │                                       │ │
│  │  │                  │                                       │ │
│  │  │  ┌────────────┐  │                                       │ │
│  │  │  │ Repository │  │                                       │ │
│  │  │  │url-checker │  │                                       │ │
│  │  │  │            │  │                                       │ │
│  │  │  │ Image:     │  │                                       │ │
│  │  │  │  latest    │  │                                       │ │
│  │  │  │  v1.0      │  │                                       │ │
│  │  │  └────────────┘  │                                       │ │
│  │  └──────────────────┘                                       │ │
│  │           │                                                  │ │
│  │           │ 3. Pull Image                                   │ │
│  │           ▼                                                  │ │
│  │  ┌──────────────────┐                                       │ │
│  │  │  EC2 Instance    │                                       │ │
│  │  │  (Production)    │                                       │ │
│  │  │                  │                                       │ │
│  │  │  ┌────────────┐  │                                       │ │
│  │  │  │  Docker    │  │    4. Run Container                  │ │
│  │  │  │  Engine    │  │    ─────────────►                    │ │
│  │  │  └────────────┘  │                                       │ │
│  │  │                  │                                       │ │
│  │  │  ┌────────────┐  │                                       │ │
│  │  │  │ Container  │  │                                       │ │
│  │  │  │url-checker │  │                                       │ │
│  │  │  │  running   │  │                                       │ │
│  │  │  └────────────┘  │                                       │ │
│  │  └──────────────────┘                                       │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    IAM Permissions                          │ │
│  │                                                              │ │
│  │  EC2 Instance Role:                                         │ │
│  │  - ecr:GetAuthorizationToken                                │ │
│  │  - ecr:BatchCheckLayerAvailability                          │ │
│  │  - ecr:GetDownloadUrlForLayer                               │ │
│  │  - ecr:BatchGetImage                                        │ │
│  │  - ecr:PutImage                                             │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Docker Engine

**Purpose**: Container runtime that builds and runs containers

**Key Functions**:
- Reads Dockerfile instructions
- Builds layered container images
- Manages running containers
- Handles container networking and storage

**Installation**: Installed on Amazon Linux 2023 via `yum install docker`

**Configuration**:
- Service runs as systemd unit
- Socket accessible to docker group members
- Configured to start on boot

### 2. Dockerfile

**Purpose**: Declarative instructions for building container image

**Structure**:
```dockerfile
FROM python:3.9-slim          # Base image
WORKDIR /app                  # Working directory
COPY . /app                   # Copy application files
RUN pip install -r requirements.txt  # Install dependencies
ENTRYPOINT ["python", "url_checker.py"]  # Default command
```

**Layer Optimization**:
- Each instruction creates a new layer
- Layers are cached for faster rebuilds
- Order matters: change less frequently modified files first

### 3. Amazon ECR (Elastic Container Registry)

**Purpose**: Private Docker registry for storing container images

**Key Features**:
- Fully managed by AWS
- Integrated with IAM for access control
- Encrypted at rest and in transit
- Lifecycle policies for image management
- Image scanning for vulnerabilities

**Repository Structure**:
```
<account-id>.dkr.ecr.<region>.amazonaws.com/
  └── url-checker/
      ├── latest
      ├── v1.0
      └── v1.1
```

**Authentication Flow**:
1. Request token: `aws ecr get-login-password`
2. Login Docker: `docker login` with token
3. Token valid for 12 hours
4. Automatic refresh via AWS CLI

### 4. Container Image

**Purpose**: Packaged application with all dependencies

**Image Layers**:
```
┌─────────────────────────┐
│  url_checker.py         │  ← Application layer
├─────────────────────────┤
│  Python packages        │  ← Dependencies layer
│  (requests, tabulate)   │
├─────────────────────────┤
│  pip, setuptools        │  ← Python tools layer
├─────────────────────────┤
│  Python 3.9 runtime     │  ← Runtime layer
├─────────────────────────┤
│  Debian slim base       │  ← Base OS layer
└─────────────────────────┘
```

**Image Metadata**:
- Image ID: SHA256 hash
- Tags: Human-readable labels (latest, v1.0)
- Size: ~150MB for Python slim base
- Created: Timestamp of build

### 5. Running Container

**Purpose**: Isolated execution environment for application

**Container Properties**:
- Own filesystem (from image layers)
- Own network interface
- Own process namespace
- Resource limits (CPU, memory)

**Runtime Behavior**:
```bash
docker run url-checker:latest https://example.com
# Creates new container from image
# Executes entrypoint with arguments
# Streams output to terminal
# Exits when process completes
```

## Container vs Virtual Machine

### Architecture Comparison

```
┌─────────────────────────────────────────────────────────────┐
│                    Virtual Machines                          │
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │  App A   │  │  App B   │  │  App C   │                  │
│  ├──────────┤  ├──────────┤  ├──────────┤                  │
│  │  Bins/   │  │  Bins/   │  │  Bins/   │                  │
│  │  Libs    │  │  Libs    │  │  Libs    │                  │
│  ├──────────┤  ├──────────┤  ├──────────┤                  │
│  │ Guest OS │  │ Guest OS │  │ Guest OS │  ← Full OS each  │
│  └──────────┘  └──────────┘  └──────────┘                  │
│  ┌───────────────────────────────────────┐                  │
│  │           Hypervisor                  │                  │
│  └───────────────────────────────────────┘                  │
│  ┌───────────────────────────────────────┐                  │
│  │           Host OS                     │                  │
│  └───────────────────────────────────────┘                  │
│  ┌───────────────────────────────────────┐                  │
│  │           Hardware                    │                  │
│  └───────────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      Containers                              │
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │  App A   │  │  App B   │  │  App C   │                  │
│  ├──────────┤  ├──────────┤  ├──────────┤                  │
│  │  Bins/   │  │  Bins/   │  │  Bins/   │  ← Shared OS     │
│  │  Libs    │  │  Libs    │  │  Libs    │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
│  ┌───────────────────────────────────────┐                  │
│  │        Docker Engine                  │                  │
│  └───────────────────────────────────────┘                  │
│  ┌───────────────────────────────────────┐                  │
│  │           Host OS                     │                  │
│  └───────────────────────────────────────┘                  │
│  ┌───────────────────────────────────────┐                  │
│  │           Hardware                    │                  │
│  └───────────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

### Key Differences

| Aspect | Virtual Machines | Containers |
|--------|------------------|------------|
| **Isolation** | Hardware-level | Process-level |
| **Startup Time** | Minutes | Seconds |
| **Size** | Gigabytes | Megabytes |
| **Performance** | Overhead from hypervisor | Near-native |
| **Portability** | Limited | High |
| **Resource Usage** | Heavy | Lightweight |

## ECR Authentication Flow

### Detailed Authentication Process

```
┌──────────────┐
│  Developer   │
└──────┬───────┘
       │
       │ 1. Request token
       ▼
┌──────────────────────────────────────────┐
│  aws ecr get-login-password              │
│  --region us-east-1                      │
└──────┬───────────────────────────────────┘
       │
       │ 2. IAM validates credentials
       ▼
┌──────────────────────────────────────────┐
│  AWS IAM                                 │
│  - Checks EC2 instance role              │
│  - Verifies ecr:GetAuthorizationToken    │
└──────┬───────────────────────────────────┘
       │
       │ 3. Returns base64 token
       ▼
┌──────────────────────────────────────────┐
│  Base64 encoded token                    │
│  (valid for 12 hours)                    │
└──────┬───────────────────────────────────┘
       │
       │ 4. Login Docker
       ▼
┌──────────────────────────────────────────┐
│  docker login                            │
│  --username AWS                          │
│  --password-stdin                        │
│  <account>.dkr.ecr.<region>.amazonaws.com│
└──────┬───────────────────────────────────┘
       │
       │ 5. Docker stores credentials
       ▼
┌──────────────────────────────────────────┐
│  ~/.docker/config.json                   │
│  {                                       │
│    "auths": {                            │
│      "<ecr-uri>": {                      │
│        "auth": "<token>"                 │
│      }                                   │
│    }                                     │
│  }                                       │
└──────────────────────────────────────────┘
```

## Image Layers and Caching

### Layer Structure

Each Dockerfile instruction creates a layer:

```dockerfile
FROM python:3.9-slim          # Layer 1: Base image (120MB)
WORKDIR /app                  # Layer 2: Metadata only (0MB)
COPY requirements.txt .       # Layer 3: Requirements file (1KB)
RUN pip install -r requirements.txt  # Layer 4: Python packages (30MB)
COPY . .                      # Layer 5: Application code (10KB)
ENTRYPOINT ["python", "url_checker.py"]  # Layer 6: Metadata only (0MB)
```

### Build Cache Optimization

**First Build**:
```
Step 1/6 : FROM python:3.9-slim
 ---> Pulling from library/python
 ---> Downloaded (120MB)
Step 2/6 : WORKDIR /app
 ---> Running in abc123
 ---> Created layer def456
Step 3/6 : COPY requirements.txt .
 ---> Created layer ghi789
Step 4/6 : RUN pip install -r requirements.txt
 ---> Running in jkl012
 ---> Created layer mno345 (30MB)
Step 5/6 : COPY . .
 ---> Created layer pqr678
Step 6/6 : ENTRYPOINT ["python", "url_checker.py"]
 ---> Created layer stu901
```

**Subsequent Build** (only code changed):
```
Step 1/6 : FROM python:3.9-slim
 ---> Using cache (def456)
Step 2/6 : WORKDIR /app
 ---> Using cache (ghi789)
Step 3/6 : COPY requirements.txt .
 ---> Using cache (jkl012)
Step 4/6 : RUN pip install -r requirements.txt
 ---> Using cache (mno345)  ← Skips 30MB download!
Step 5/6 : COPY . .
 ---> Created layer xyz123  ← Only this rebuilds
Step 6/6 : ENTRYPOINT ["python", "url_checker.py"]
 ---> Created layer abc456
```

### Best Practices for Layer Optimization

1. **Order by change frequency**: Least changing first
2. **Combine related commands**: Reduce layer count
3. **Use .dockerignore**: Exclude unnecessary files
4. **Multi-stage builds**: Separate build and runtime dependencies

## Multi-Instance Deployment Pattern

### Deployment Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Build Phase                               │
│                                                               │
│  Developer Machine / CI/CD                                   │
│  ┌────────────────────────────────────┐                     │
│  │ 1. Write Dockerfile                │                     │
│  │ 2. Build image locally             │                     │
│  │ 3. Test image                      │                     │
│  │ 4. Push to ECR                     │                     │
│  └────────────────────────────────────┘                     │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ Image stored in ECR
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  Distribution Phase                          │
│                                                               │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │ Instance 1   │    │ Instance 2   │    │ Instance N   │  │
│  │              │    │              │    │              │  │
│  │ 1. Pull      │    │ 1. Pull      │    │ 1. Pull      │  │
│  │ 2. Run       │    │ 2. Run       │    │ 2. Run       │  │
│  │              │    │              │    │              │  │
│  │ Same image   │    │ Same image   │    │ Same image   │  │
│  │ Same behavior│    │ Same behavior│    │ Same behavior│  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Benefits of This Pattern

1. **Consistency**: All instances run identical code
2. **Rapid Deployment**: Pull and run in seconds
3. **Easy Rollback**: Switch to previous image tag
4. **Version Control**: Tag images for different versions
5. **Scalability**: Add instances without rebuilding

## Security Considerations

### Image Security

1. **Base Image Selection**:
   - Use official images from trusted sources
   - Prefer slim/alpine variants (smaller attack surface)
   - Regularly update base images

2. **Dependency Management**:
   - Pin package versions in requirements.txt
   - Scan for vulnerabilities (ECR image scanning)
   - Remove unnecessary packages

3. **Secrets Management**:
   - Never hardcode credentials in Dockerfile
   - Use environment variables or AWS Secrets Manager
   - Don't commit .env files

### ECR Security

1. **Access Control**:
   - Use IAM roles for EC2 instances
   - Principle of least privilege
   - Separate read/write permissions

2. **Encryption**:
   - Images encrypted at rest (AES-256)
   - Transfer encrypted via HTTPS
   - KMS integration available

3. **Image Scanning**:
   - Automatic vulnerability scanning
   - Scan on push
   - Integration with AWS Security Hub

## Performance Considerations

### Image Size Optimization

```
# Unoptimized (500MB)
FROM python:3.9
COPY . /app
RUN pip install -r requirements.txt

# Optimized (150MB)
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
```

### Network Optimization

- **ECR VPC Endpoints**: Avoid internet gateway charges
- **Image Layer Caching**: Reuse layers across instances
- **Compression**: Layers compressed during transfer

### Startup Time

- **Container**: 1-2 seconds
- **EC2 Instance**: 30-60 seconds
- **Lambda Cold Start**: 1-5 seconds

## Next Steps: Container Orchestration

This Docker/ECR foundation enables:

### Amazon ECS (Elastic Container Service)
- Task definitions for container configuration
- Service management with load balancing
- Auto-scaling based on metrics
- Integration with ALB/NLB

### AWS Fargate
- Serverless container execution
- No EC2 instance management
- Pay per task
- Automatic scaling

### Amazon EKS (Elastic Kubernetes Service)
- Full Kubernetes orchestration
- Advanced scheduling and networking
- Multi-cloud portability
- Rich ecosystem of tools

## Conclusion

This architecture demonstrates the fundamental pattern of containerization in AWS:
1. Package applications in Docker containers
2. Store images in Amazon ECR
3. Deploy containers across multiple instances
4. Achieve consistency, portability, and scalability

The containerized application is now ready for orchestration platforms like ECS, Fargate, and EKS, which will automate deployment, scaling, and management at production scale.
