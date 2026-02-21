# Architecture: EC2 URL Checker

## Overview

This document describes the architecture of the URL Checker application deployed on Amazon EC2. The architecture demonstrates a traditional, manual deployment model that serves as a baseline for comparing more advanced deployment methods like serverless computing, containerization, and orchestration platforms.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                            │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                    VPC (Default)                        │ │
│  │                                                          │ │
│  │  ┌────────────────────────────────────────────────┐    │ │
│  │  │              Public Subnet                      │    │ │
│  │  │                                                  │    │ │
│  │  │  ┌──────────────────────────────────────┐      │    │ │
│  │  │  │      EC2 Instance (t2.micro)         │      │    │ │
│  │  │  │   Amazon Linux 2023                  │      │    │ │
│  │  │  │                                       │      │    │ │
│  │  │  │  ┌─────────────────────────────┐    │      │    │ │
│  │  │  │  │   Python 3.11 Runtime       │    │      │    │ │
│  │  │  │  │                              │    │      │    │ │
│  │  │  │  │  ┌────────────────────┐     │    │      │    │ │
│  │  │  │  │  │  url_checker.py    │     │    │      │    │ │
│  │  │  │  │  │  - requests lib    │     │    │      │    │ │
│  │  │  │  │  │  - tabulate lib    │     │    │      │    │ │
│  │  │  │  │  └────────────────────┘     │    │      │    │ │
│  │  │  │  └─────────────────────────────┘    │      │    │ │
│  │  │  │                                       │      │    │ │
│  │  │  │  IAM Instance Profile                │      │    │ │
│  │  │  │  - SSM Permissions                   │      │    │ │
│  │  │  │  - S3 Permissions                    │      │    │ │
│  │  │  └──────────────────────────────────────┘      │    │ │
│  │  │                                                  │    │ │
│  │  │  Security Group                                 │    │ │
│  │  │  - Outbound: HTTPS (443) - Allow               │    │ │
│  │  │  - Inbound: None required                       │    │ │
│  │  └────────────────────────────────────────────────┘    │ │
│  │                                                          │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │         AWS Systems Manager (Session Manager)          │ │
│  │         - Secure shell access                          │ │
│  │         - No SSH keys required                         │ │
│  │         - Audit logging                                │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Amazon S3 (Optional)                      │ │
│  │              - Application artifacts                   │ │
│  │              - Log storage                             │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ HTTPS Requests
                           ▼
                  ┌─────────────────┐
                  │  External URLs  │
                  │  - aws.amazon   │
                  │  - github.com   │
                  │  - example.com  │
                  └─────────────────┘
```

## Components

### 1. Amazon EC2 Instance

**Purpose**: Virtual server hosting the Python application

**Configuration**:
- **Instance Type**: t2.micro (1 vCPU, 1 GB RAM)
- **AMI**: Amazon Linux 2023
- **Storage**: 8 GB EBS volume (gp3)
- **Availability Zone**: Single AZ deployment

**Characteristics**:
- Always running (incurs hourly charges)
- Manual scaling required
- Single point of failure
- Requires OS and security patch management

### 2. VPC and Networking

**VPC Configuration**:
- **Type**: Default VPC or custom VPC
- **CIDR Block**: 10.0.0.0/16 (typical)
- **Subnets**: Public subnet with internet gateway
- **Route Table**: Routes to internet gateway for outbound traffic

**Network Flow**:
1. EC2 instance in public subnet
2. Internet Gateway provides internet access
3. Outbound HTTPS traffic to check external URLs
4. No inbound traffic required (Session Manager uses AWS backbone)

### 3. Security Group

**Purpose**: Virtual firewall controlling instance traffic

**Rules**:
- **Outbound**:
  - HTTPS (443): Allow to 0.0.0.0/0 (for URL checking)
  - HTTP (80): Optional, for non-HTTPS URLs
  - HTTPS (443): To AWS endpoints (SSM, S3)
- **Inbound**:
  - None required (Session Manager doesn't need open ports)

**Security Benefits**:
- No SSH port (22) exposure
- Minimal attack surface
- Principle of least privilege

### 4. IAM Instance Profile

**Purpose**: Grant EC2 instance permissions to access AWS services

**Required Policies**:
- **AmazonSSMManagedInstanceCore**: Session Manager access
- **S3 Read/Write**: Optional, for artifact storage
- **CloudWatch Logs**: Optional, for log streaming

**IAM Role Trust Policy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### 5. AWS Systems Manager (Session Manager)

**Purpose**: Secure, auditable shell access without SSH

**Benefits**:
- No SSH keys to manage or rotate
- No bastion hosts required
- No open inbound ports (port 22)
- Centralized access logging
- IAM-based access control
- Encrypted connections

**How It Works**:
1. SSM agent runs on EC2 instance
2. Agent polls SSM service for commands
3. User initiates session via console/CLI
4. Session established over AWS backbone
5. All commands logged to CloudWatch (optional)

### 6. Python Application Stack

**Runtime Environment**:
- **Python Version**: 3.11
- **Package Manager**: pip
- **Virtual Environment**: Optional (recommended for production)

**Dependencies**:
- **requests (2.31.0)**: HTTP client library
  - Handles HTTP/HTTPS requests
  - Connection pooling
  - Timeout management
  - Error handling
- **tabulate (0.9.0)**: Table formatting library
  - ASCII table generation
  - Multiple table formats
  - Unicode support

**Application Flow**:
```
1. Parse command-line arguments (URLs)
2. For each URL:
   a. Send HTTP GET request
   b. Check response status code
   c. Handle errors (timeout, connection, etc.)
3. Collect results
4. Format as table using tabulate
5. Display results and summary
```

### 7. Amazon S3 (Optional)

**Purpose**: Storage for application artifacts and logs

**Use Cases**:
- Store application code and scripts
- Archive application logs
- Store URL check results
- Backup configuration files

**Integration**:
- EC2 instance uses IAM role to access S3
- No credentials stored on instance
- Secure, encrypted storage

## Data Flow

### URL Checking Process

1. **User Invocation**:
   - User connects to EC2 via Session Manager
   - Executes: `python3 url_checker.py <urls>`

2. **Application Execution**:
   - Script parses command-line arguments
   - Validates URL format
   - Initiates HTTP GET requests

3. **Network Request**:
   - Request leaves EC2 instance
   - Passes through security group (outbound 443)
   - Routes through internet gateway
   - Reaches external URL

4. **Response Processing**:
   - Receives HTTP response
   - Checks status code (200-299 = success)
   - Handles errors (timeout, connection failure)

5. **Result Display**:
   - Formats results as table
   - Displays in terminal
   - Shows summary statistics

## Deployment Model

### Manual Deployment Characteristics

**Advantages**:
- Full control over environment
- Predictable performance
- Suitable for long-running processes
- Can run stateful applications
- Direct access to file system

**Disadvantages**:
- Manual provisioning and configuration
- Ongoing maintenance burden (OS patches, updates)
- No automatic scaling
- Single point of failure
- Always running (cost inefficiency for sporadic workloads)
- Requires monitoring and alerting setup

### Operational Overhead

**Initial Setup** (15-20 minutes):
- Launch EC2 instance
- Configure security groups
- Attach IAM instance profile
- Install Python and dependencies
- Deploy application code

**Ongoing Maintenance**:
- OS security patches (monthly)
- Python runtime updates (quarterly)
- Dependency updates (as needed)
- Monitoring and log management
- Backup and disaster recovery

## Comparison to Alternative Architectures

### vs. AWS Lambda (Serverless)

| Aspect | EC2 (This Architecture) | Lambda |
|--------|-------------------------|--------|
| **Provisioning** | Manual instance launch | Automatic |
| **Scaling** | Manual or Auto Scaling | Automatic, instant |
| **Pricing** | Hourly (always running) | Per invocation |
| **Cold Start** | None (always warm) | 100-500ms |
| **Execution Time** | Unlimited | 15 minutes max |
| **State** | Can maintain state | Stateless |
| **Maintenance** | OS patches required | Fully managed |
| **Availability** | Single AZ | Multi-AZ default |

**When to Use EC2**:
- Long-running applications
- Stateful applications
- Predictable, constant workload
- Need for specific OS or runtime
- Applications requiring > 15 minutes execution

**When to Use Lambda**:
- Event-driven workloads
- Sporadic or unpredictable traffic
- Stateless functions
- Short execution times (< 15 min)
- Want zero maintenance

### vs. Containers (ECS/Fargate)

| Aspect | EC2 (This Architecture) | ECS/Fargate |
|--------|-------------------------|-------------|
| **Packaging** | Direct on OS | Docker container |
| **Portability** | OS-dependent | Portable across environments |
| **Isolation** | Process-level | Container-level |
| **Scaling** | Instance-based | Container-based |
| **Deployment** | Manual scripts | Orchestrated |
| **Infrastructure** | Manage EC2 | Fargate: serverless containers |

**When to Use Containers**:
- Need application portability
- Microservices architecture
- Want consistent dev/prod environments
- Need better resource utilization
- Want orchestration capabilities

## Security Considerations

### Network Security

- **No SSH Access**: Session Manager eliminates SSH key management
- **Minimal Inbound Rules**: No open ports for external access
- **Outbound Restrictions**: Only HTTPS allowed for URL checking
- **VPC Isolation**: Instance in private subnet (optional enhancement)

### IAM Security

- **Least Privilege**: Instance role has only required permissions
- **No Credentials on Instance**: Uses IAM role for AWS service access
- **Audit Trail**: CloudTrail logs all IAM actions
- **Session Logging**: Session Manager logs all commands

### Application Security

- **Dependency Management**: Pin library versions in requirements.txt
- **Input Validation**: Validate URLs before processing
- **Error Handling**: Graceful handling of network errors
- **Timeout Protection**: 5-second timeout prevents hanging

### OS Security

- **Regular Patching**: Amazon Linux 2023 receives security updates
- **Minimal Software**: Only install required packages
- **Security Groups**: Defense in depth with network controls

## Monitoring and Observability

### CloudWatch Integration (Optional Enhancement)

**Metrics to Monitor**:
- CPU utilization
- Network in/out
- Disk I/O
- Memory usage (requires CloudWatch agent)

**Logs to Collect**:
- Application logs (URL check results)
- System logs (OS events)
- Session Manager logs (access audit)

**Alarms to Configure**:
- High CPU utilization (> 80%)
- Instance status check failures
- Disk space low (> 80% used)

### Application Logging

**Current Implementation**:
- Console output only
- No persistent logging

**Production Enhancements**:
- Log to file: `/var/log/url-checker/`
- Stream to CloudWatch Logs
- Structured logging (JSON format)
- Log rotation and retention

## Scalability and High Availability

### Current Limitations

- **Single Instance**: No redundancy
- **Single AZ**: No AZ-level fault tolerance
- **Manual Scaling**: No automatic capacity adjustment
- **No Load Balancing**: Single point of access

### Production Enhancements

**High Availability**:
1. Deploy instances in multiple AZs
2. Use Application Load Balancer
3. Implement health checks
4. Auto Scaling group for redundancy

**Scalability**:
1. Auto Scaling based on CPU/memory
2. Scheduled scaling for predictable patterns
3. Target tracking scaling policies
4. Consider Lambda for better scaling

## Cost Optimization

### Current Cost Structure

**EC2 Instance** (t2.micro):
- On-Demand: ~$0.0116/hour = ~$8.50/month
- Reserved Instance (1-year): ~$5/month (40% savings)
- Spot Instance: ~$3.50/month (60% savings)

**Data Transfer**:
- Outbound: $0.09/GB (first 10 TB)
- Inbound: Free

**Session Manager**:
- Free (no additional charges)

### Cost Optimization Strategies

1. **Right-Sizing**: Use t2.micro for low-traffic applications
2. **Reserved Instances**: Commit to 1-3 years for savings
3. **Spot Instances**: Use for non-critical workloads
4. **Auto Scaling**: Scale down during low-traffic periods
5. **Lambda Alternative**: Consider serverless for sporadic workloads

### Cost Comparison

**EC2 (24/7 operation)**:
- t2.micro: $8.50/month
- Annual: $102

**Lambda (1000 invocations/day)**:
- Compute: $0.20/month
- Requests: $0.06/month
- Annual: $3.12

**Conclusion**: For sporadic workloads, Lambda is 97% cheaper than EC2.

## Future Enhancements

### Short-Term Improvements

1. **Logging**: Implement CloudWatch Logs integration
2. **Monitoring**: Set up CloudWatch alarms
3. **Automation**: Use user data script for setup
4. **Configuration**: Externalize configuration to S3

### Long-Term Evolution

1. **Containerization**: Package as Docker container
2. **ECS Deployment**: Deploy on ECS Fargate
3. **Lambda Migration**: Convert to serverless function
4. **API Gateway**: Expose as REST API
5. **DynamoDB**: Store results in database
6. **EventBridge**: Schedule periodic checks

## Conclusion

This architecture demonstrates the traditional EC2 deployment model, highlighting both its strengths (control, flexibility) and weaknesses (operational overhead, manual scaling). It serves as an essential baseline for understanding when to use EC2 versus more modern approaches like serverless computing, containerization, and orchestration platforms.

The key takeaway: EC2 is powerful but requires significant operational investment. For simple, event-driven workloads like URL checking, serverless alternatives (Lambda) offer better cost efficiency, automatic scaling, and zero maintenance.
