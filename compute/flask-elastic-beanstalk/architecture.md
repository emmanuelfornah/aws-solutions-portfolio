# Architecture: Flask Application on AWS Elastic Beanstalk

## Overview

This architecture demonstrates a fully managed Platform-as-a-Service (PaaS) deployment of a Flask RESTful API using AWS Elastic Beanstalk. The platform automatically handles infrastructure provisioning, load balancing, auto-scaling, monitoring, and application health management.

## Architecture Components

### 1. Elastic Beanstalk Environment

The core orchestration layer that manages all infrastructure components:

- **Platform**: Python 3.9 running on 64-bit Amazon Linux 2
- **Environment Type**: Web server environment with load balancing
- **Deployment Policy**: Rolling updates for zero-downtime deployments
- **Configuration Management**: Automated through EB CLI and console

### 2. EC2 Instances

Compute resources running the Flask application:

- **Instance Type**: t2.micro (Free Tier eligible)
- **Operating System**: Amazon Linux 2
- **Python Runtime**: Python 3.9 with pip package manager
- **WSGI Server**: Gunicorn (managed by Elastic Beanstalk)
- **Application Code**: Flask RESTful API serving JSON responses
- **Security**: Runs in private subnet with security group controls

### 3. Auto Scaling Group

Automatically adjusts capacity based on demand:

- **Minimum Instances**: 1 (ensures high availability)
- **Maximum Instances**: 4 (cost control and capacity limit)
- **Scaling Triggers**: 
  - Scale up when CPU > 70% for 5 minutes
  - Scale down when CPU < 30% for 10 minutes
- **Health Checks**: Replaces unhealthy instances automatically
- **Availability Zones**: Distributes instances across multiple AZs

### 4. Elastic Load Balancer (Application Load Balancer)

Distributes incoming traffic across healthy instances:

- **Type**: Application Load Balancer (Layer 7)
- **Listeners**: HTTP on port 80, HTTPS on port 443 (optional)
- **Health Check Path**: `/health` endpoint
- **Health Check Interval**: 30 seconds
- **Healthy Threshold**: 2 consecutive successful checks
- **Unhealthy Threshold**: 5 consecutive failed checks
- **Connection Draining**: 20 seconds during instance termination
- **Sticky Sessions**: Disabled (stateless API)

### 5. S3 Bucket

Stores application source code and deployment artifacts:

- **Purpose**: Version storage for application deployments
- **Naming**: `elasticbeanstalk-[region]-[account-id]`
- **Versioning**: Enabled for rollback capability
- **Lifecycle**: Automatic cleanup of old versions
- **Access**: Restricted to EB service role only

### 6. CloudWatch Monitoring

Provides metrics, logs, and alarms:

**Metrics Collected**:
- CPU Utilization (per instance and aggregate)
- Network In/Out (bandwidth monitoring)
- Request Count (traffic volume)
- HTTP 4xx/5xx Errors (application health)
- Latency (response time percentiles: p50, p90, p99)
- Healthy/Unhealthy Host Count

**Logs**:
- Application logs (`/var/log/eb-engine.log`)
- Web server logs (`/var/log/nginx/access.log`, `/var/log/nginx/error.log`)
- Deployment logs (EB activity logs)

**Alarms**:
- High CPU utilization (triggers auto-scaling)
- Elevated error rates (alerts for investigation)
- Instance health degradation

### 7. CloudFormation Stack

Infrastructure-as-Code management:

- **Stack Name**: `awseb-[environment-name]-stack`
- **Resources Managed**: All EB environment resources
- **Change Sets**: Preview infrastructure changes before applying
- **Rollback**: Automatic rollback on deployment failures
- **Drift Detection**: Identifies manual changes to resources

### 8. Security Components

**Security Groups**:
- Load Balancer SG: Allows inbound HTTP/HTTPS from internet (0.0.0.0/0)
- EC2 Instance SG: Allows inbound traffic only from Load Balancer SG
- Outbound: Allows all traffic for package downloads and AWS API calls

**IAM Roles**:
- `aws-elasticbeanstalk-ec2-role`: Instance profile for EC2 instances
  - Permissions: S3 access, CloudWatch logs, X-Ray (optional)
- `aws-elasticbeanstalk-service-role`: Service role for EB operations
  - Permissions: EC2, ELB, Auto Scaling, CloudFormation management

**Network Security**:
- VPC: Default VPC or custom VPC
- Subnets: Public subnets for load balancer, private subnets for instances
- NAT Gateway: Enables outbound internet access for private instances

## Traffic Flow

```
Internet User
    ↓
    ↓ (HTTP/HTTPS Request)
    ↓
Application Load Balancer (Port 80/443)
    ↓
    ↓ (Health Check: /health)
    ↓ (Routes to healthy instances)
    ↓
EC2 Instance 1 (Gunicorn → Flask App)
EC2 Instance 2 (Gunicorn → Flask App)
EC2 Instance N (Gunicorn → Flask App)
    ↓
    ↓ (JSON Response)
    ↓
Application Load Balancer
    ↓
    ↓ (HTTP Response)
    ↓
Internet User
```

## Deployment Flow

```
Developer
    ↓
    ↓ (eb deploy command)
    ↓
EB CLI
    ↓
    ↓ (Uploads application bundle)
    ↓
S3 Bucket (Stores version)
    ↓
    ↓ (Triggers deployment)
    ↓
Elastic Beanstalk Service
    ↓
    ↓ (Rolling update strategy)
    ↓
CloudFormation (Updates stack)
    ↓
    ↓ (Deploys to instances)
    ↓
EC2 Instances (Install dependencies, restart app)
    ↓
    ↓ (Health checks)
    ↓
Load Balancer (Routes traffic to new version)
```

## High Availability Design

1. **Multi-AZ Deployment**: Instances distributed across availability zones
2. **Auto Scaling**: Automatically replaces failed instances
3. **Load Balancing**: Distributes traffic only to healthy instances
4. **Health Monitoring**: Continuous health checks at application and instance level
5. **Rolling Updates**: Zero-downtime deployments with gradual rollout
6. **Automatic Rollback**: Reverts to previous version on deployment failure

## Monitoring and Observability

- **Real-time Metrics**: CloudWatch dashboard with key performance indicators
- **Log Aggregation**: Centralized logging in CloudWatch Logs
- **Alarms**: Proactive notifications for anomalies
- **Health Dashboard**: EB console shows environment health status
- **Request Tracing**: Optional AWS X-Ray integration for distributed tracing

## Cost Optimization

- **Free Tier**: t2.micro instances eligible for AWS Free Tier
- **Auto Scaling**: Scales down during low traffic periods
- **Reserved Instances**: Option for predictable workloads
- **S3 Lifecycle**: Automatic cleanup of old deployment versions
- **CloudWatch**: Logs retention policies to control storage costs

## Scalability

- **Horizontal Scaling**: Add more instances via Auto Scaling
- **Vertical Scaling**: Change instance type via EB configuration
- **Load Balancer**: Handles thousands of concurrent connections
- **Stateless Design**: Enables seamless scaling without session management

## Security Best Practices

- **Least Privilege IAM**: Minimal permissions for instance and service roles
- **Security Groups**: Restrictive inbound rules, principle of least access
- **HTTPS**: SSL/TLS termination at load balancer (optional)
- **Secrets Management**: Environment variables for configuration (use AWS Secrets Manager for sensitive data)
- **Patch Management**: Automatic OS and platform updates via EB managed updates
- **Network Isolation**: Private subnets for application instances

## Disaster Recovery

- **Version History**: S3 stores all deployment versions for rollback
- **Automated Backups**: CloudFormation templates enable environment recreation
- **Multi-Region**: Can deploy identical environments in multiple regions
- **RTO/RPO**: Near-zero RTO with auto-scaling, RPO depends on data persistence strategy

## Key Advantages of Elastic Beanstalk

1. **Managed Infrastructure**: No need to manually configure EC2, ELB, Auto Scaling
2. **Developer Productivity**: Focus on code, not infrastructure
3. **Built-in Best Practices**: HA, monitoring, security configured by default
4. **Easy Updates**: Simple deployments with rollback capability
5. **Cost Effective**: Pay only for underlying resources (EC2, ELB, etc.)
6. **Platform Support**: Multiple languages and frameworks supported
7. **Customization**: Full control via configuration files when needed
