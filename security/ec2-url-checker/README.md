# Applying Key Amazon EC2 Functions to Applications (URL Checker on EC2)

## Overview

This lab demonstrates the baseline manual deployment approach for running applications on AWS using Amazon EC2. A Python-based URL checker application is deployed on an EC2 instance running Amazon Linux 2023, showcasing the traditional infrastructure management model. This serves as the foundation for comparing more advanced deployment methods like serverless (Lambda), containerization (Docker/ECS), and orchestration (Fargate/EKS).

The application performs HTTP GET requests to check URL availability and displays results in a formatted table, demonstrating practical use of EC2 for compute workloads.

## AWS Services Used

- **Amazon EC2**: Virtual server hosting the Python application
- **Amazon S3**: Storage for application artifacts and logs
- **AWS Systems Manager (Session Manager)**: Secure shell access without SSH keys or bastion hosts
- **IAM**: Instance profile and roles for secure AWS service access

## Architecture

The architecture follows a simple single-instance deployment model:

- EC2 instance in a VPC subnet with internet access
- Security group allowing outbound HTTPS traffic for URL checking
- IAM instance profile granting Systems Manager and S3 permissions
- Session Manager for secure, auditable remote access
- Manual Python environment setup and dependency installation

For detailed architecture diagrams and component descriptions, see [architecture.md](./architecture.md).

## Key Technologies

- **Python 3.11**: Application runtime
- **Amazon Linux 2023**: Modern, secure Linux distribution optimized for AWS
- **requests library**: HTTP client for URL checking
- **tabulate library**: Formatted table output
- **pip**: Python package manager

## Objectives

- Launch and configure an EC2 instance for application hosting
- Set up Python 3.11 development environment on Amazon Linux 2023
- Install application dependencies using pip
- Deploy and run a command-line Python application
- Use Session Manager for secure instance access
- Understand manual deployment operational overhead

## Key Learnings

### Manual Deployment Challenges

This lab highlights the operational overhead of traditional EC2 deployments:

1. **Infrastructure Management**: Manual instance provisioning, OS updates, security patching
2. **Environment Setup**: Installing and configuring runtime environments (Python, pip)
3. **Dependency Management**: Manual installation of application libraries
4. **Scaling Limitations**: Single instance with no automatic scaling
5. **Availability**: No built-in redundancy or fault tolerance
6. **Maintenance Burden**: Ongoing responsibility for OS and runtime updates

### Comparison to Serverless

Compared to AWS Lambda (covered in the Lambda URL Checker lab):

| Aspect | EC2 (This Lab) | Lambda (Serverless) |
|--------|----------------|---------------------|
| **Setup Time** | 15-20 minutes | 2-3 minutes |
| **Infrastructure** | Manual provisioning | Fully managed |
| **Scaling** | Manual or Auto Scaling | Automatic |
| **Pricing** | Pay for running time | Pay per invocation |
| **Maintenance** | OS patches, updates | None required |
| **Availability** | Single point of failure | Multi-AZ by default |

This comparison sets the foundation for understanding when to use EC2 (long-running, stateful applications) versus Lambda (event-driven, stateless functions).

### Session Manager Benefits

Using AWS Systems Manager Session Manager instead of traditional SSH provides:

- No need to manage SSH keys or open port 22
- Centralized access logging and auditing
- Integration with IAM for fine-grained access control
- No bastion hosts or jump boxes required
- Encrypted connections by default

## Setup Instructions

### Prerequisites

- AWS account with appropriate permissions
- IAM role with EC2, Systems Manager, and S3 access
- Basic familiarity with Linux command line

### Step 1: Launch EC2 Instance

1. Navigate to EC2 console
2. Click "Launch Instance"
3. Configure instance:
   - **Name**: url-checker-instance
   - **AMI**: Amazon Linux 2023
   - **Instance Type**: t2.micro (free tier eligible)
   - **Key Pair**: Not required (using Session Manager)
   - **Network**: Default VPC, public subnet
   - **Security Group**: Allow outbound HTTPS (443)
   - **IAM Instance Profile**: Role with SSM and S3 permissions
4. Launch instance and wait for "Running" state

### Step 2: Connect via Session Manager

1. Select the instance in EC2 console
2. Click "Connect" button
3. Choose "Session Manager" tab
4. Click "Connect" to open browser-based shell

### Step 3: Set Up Python Environment

Run the environment setup script:

```bash
cd /home/ec2-user
chmod +x setup-environment.sh
./setup-environment.sh
```

This script installs Python 3.11 and pip on Amazon Linux 2023.

### Step 4: Install Application Dependencies

Install required Python libraries:

```bash
chmod +x install-dependencies.sh
./install-dependencies.sh
```

This installs the `requests` and `tabulate` libraries from requirements.txt.

### Step 5: Run the URL Checker Application

Execute the application with sample URLs:

```bash
chmod +x run-application.sh
./run-application.sh
```

Or run manually with custom URLs:

```bash
python3 url_checker.py https://aws.amazon.com https://github.com https://example.com
```

## Application Explanation

### URL Checker Script

The `url_checker.py` script performs the following operations:

1. **Command-Line Argument Parsing**: Accepts URLs as command-line arguments
2. **HTTP GET Requests**: Uses the `requests` library to check each URL
3. **Status Code Validation**: Determines if URL is reachable (200-299 status codes)
4. **Error Handling**: Catches connection errors, timeouts, and invalid URLs
5. **Formatted Output**: Displays results in a table using `tabulate`

### Sample Output

```
URL Checker Results
╒═══════════════════════════╤══════════╤═════════════╕
│ URL                       │ Status   │ Status Code │
╞═══════════════════════════╪══════════╪═════════════╡
│ https://aws.amazon.com    │ Success  │ 200         │
├───────────────────────────┼──────────┼─────────────┤
│ https://github.com        │ Success  │ 200         │
├───────────────────────────┼──────────┼─────────────┤
│ https://invalid-url.xyz   │ Failed   │ N/A         │
╘═══════════════════════════╧══════════╧═════════════╛
```

## Scripts and Configurations

### application/url_checker.py

Python script that checks URL availability using HTTP GET requests. Includes error handling for network issues and invalid URLs.

### application/requirements.txt

Python dependencies:
- `requests`: HTTP library for making GET requests
- `tabulate`: Library for creating formatted ASCII tables

### scripts/setup-environment.sh

Bash script to install Python 3.11 and pip on Amazon Linux 2023. Updates system packages and configures Python environment.

### scripts/install-dependencies.sh

Bash script to install Python packages from requirements.txt using pip. Creates virtual environment if needed.

### scripts/run-application.sh

Bash script to execute the URL checker with sample URLs. Demonstrates typical application invocation.

## Troubleshooting

### Python Not Found

If `python3` command is not found after installation:

```bash
# Verify Python installation
which python3.11
# Create symlink if needed
sudo ln -s /usr/bin/python3.11 /usr/bin/python3
```

### Pip Installation Issues

If pip fails to install packages:

```bash
# Upgrade pip
python3 -m pip install --upgrade pip
# Install with user flag
python3 -m pip install --user -r requirements.txt
```

### Session Manager Connection Fails

If unable to connect via Session Manager:

1. Verify IAM instance profile is attached
2. Check SSM agent is running: `sudo systemctl status amazon-ssm-agent`
3. Ensure instance has internet access (for SSM endpoint)
4. Verify security group allows outbound HTTPS

### URL Checker Errors

If application fails to check URLs:

1. Verify internet connectivity: `ping -c 3 8.8.8.8`
2. Check security group allows outbound HTTPS (port 443)
3. Test with simple URL: `curl -I https://aws.amazon.com`

## Next Steps

After completing this lab, explore more advanced deployment methods:

1. **Lambda URL Checker**: Serverless deployment with automatic scaling
2. **Containerized Deployment**: Package application in Docker container
3. **ECS/Fargate**: Managed container orchestration
4. **EKS**: Kubernetes-based container orchestration

## Estimated Time

- **Setup**: 15-20 minutes
- **Deployment**: 5-10 minutes
- **Testing**: 5 minutes
- **Total**: 25-35 minutes

## Complexity Level

**Basic** - Suitable for beginners learning AWS fundamentals and EC2 basics.

## Completion Date

*To be filled in upon completion*

## Tags

`ec2` `python` `compute` `systems-manager` `session-manager` `manual-deployment` `baseline` `url-checker` `amazon-linux`
