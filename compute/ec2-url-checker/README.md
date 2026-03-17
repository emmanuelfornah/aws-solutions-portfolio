# Python URL Checker on EC2

## Overview

Deploys a Python URL availability checker on an EC2 instance, accessed securely via AWS Systems Manager Session Manager — eliminating the need for SSH keys or open inbound ports.

## AWS Services Used

- **Amazon EC2** - Compute instance running the URL checker
- **AWS Systems Manager (SSM)** - Secure shell access without SSH
- **AWS IAM** - Instance profile with SSM permissions
- **Amazon VPC** - Network isolation

## Architecture

```
┌──────────────┐     Session Manager     ┌──────────────────┐
│   Operator   │ ──────────────────────> │   EC2 Instance   │
│              │   (no SSH, no port 22)  │                  │
└──────────────┘                         │  Python Script   │
                                         │  url_checker.py  │
                                         └────────┬─────────┘
                                                  │
                                                  │ HTTP/HTTPS
                                                  ▼
                                         ┌──────────────────┐
                                         │  Target URLs     │
                                         └──────────────────┘
```

## Technical Highlights

- EC2 instance launched with SSM-enabled AMI and instance profile
- Session Manager provides encrypted, auditable shell access
- No security group ingress rules required (zero inbound ports)
- Python script checks URL availability and response codes
- CloudWatch Logs integration for monitoring check results
