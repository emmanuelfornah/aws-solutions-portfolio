# CodePipeline Unit Testing Architecture

## Overview

This document describes the architecture and workflow of the AWS CodePipeline implementation for automated unit testing and deployment of the Presidents application.

## Architecture Diagram

┌─────────────────────────────────────────────────────────────────────┐
│                         Developer Workflow                          │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  │ git push
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS CodeCommit                              │
│                     Git Repository (main branch)                    │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  │ Detects changes
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       AWS CodePipeline                              │
│                                                                     │
│  ┌───────────────┐    ┌───────────────┐    ┌───────────────┐     │
│  │  Source Stage │───▶│  Test Stage   │───▶│ Deploy Stage  │     │
│  │               │    │               │    │               │     │
│  │  CodeCommit   │    │  Run pytest   │    │  CodeDeploy   │     │
│  │  Pull Code    │    │  Unit Tests   │    │  to EC2       │     │
│  └───────────────┘    └───────────────┘    └───────────────┘     │
│                              │                                      │
│                              │ Tests Pass/Fail                      │
│                              ▼                                      │
│                       ┌─────────────┐                              │
│                       │ Quality Gate│                              │
│                       │ (Pass/Fail) │                              │
│                       └─────────────┘                              │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  │ Deploy if tests pass
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        AWS CodeDeploy                               │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │  Deployment Steps (defined in appspec.yml)              │     │
│  │  1. ApplicationStop                                      │     │
│  │  2. BeforeInstall                                        │     │
│  │  3. Install (copy files)                                 │     │
│  │  4. AfterInstall                                         │     │
│  │  5. ApplicationStart                                     │     │
│  │  6. ValidateService                                      │     │
│  └──────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  │ Deploys application
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         Amazon EC2 Instance                         │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │  Flask Application (presidents.py)                       │     │
│  │  - Serves web interface                                  │     │
│  │  - Calculates president ages using relativedelta         │     │
│  │  - Queries DynamoDB for data                             │     │
│  └──────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  │ Queries data
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Amazon DynamoDB                              │
│                     Presidents Table                                │
│  - President names                                                  │
│  - Birth dates                                                      │
│  - Death dates                                                      │
│  - Other biographical data                                          │
└─────────────────────────────────────────────────────────────────────┘

## Pipeline Stages

### Stage 1: Source

**Purpose:** Retrieve the latest code from the repository

**Components:**
- **AWS CodeCommit** - Git repository hosting the application code
- **Branch:** main (or master)
- **Trigger:** Automatic on code push

**Actions:**
1. CodePipeline monitors CodeCommit repository for changes
2. When a commit is pushed, pipeline automatically triggers
3. Source code is pulled and made available to subsequent stages

**Outputs:**
- Source artifact containing all repository files
- Artifact is stored in S3 bucket managed by CodePipeline

### Stage 2: Test

**Purpose:** Run automated unit tests to verify code quality

**Components:**
- **Test Framework:** pytest
- **Test Files:** Located in `tests/` directory
- **Dependencies:** pytest, pytest-mock, pytest-cov, pylint

**Actions:**
1. Install test dependencies from `tests/requirements.txt`
2. Install application dependencies from `app/requirements.txt`
3. Execute test script: `./run_tests.sh`
4. pytest runs all test files matching `test_*.py` pattern
5. Generate test results and coverage reports

**Test Execution:**
```bash
#!/bin/bash
# run_tests.sh

# Install dependencies
pip install -r app/requirements.txt
pip install -r tests/requirements.txt

# Run tests with coverage
pytest tests/ --cov=app --cov-report=term-missing

# Run linting
pylint app/

**Quality Gate:**
- **Pass:** All tests pass → Pipeline continues to Deploy stage
- **Fail:** Any test fails → Pipeline stops, deployment prevented

**Outputs:**
- Test results (pass/fail status)
- Code coverage metrics
- Linting results

### Stage 3: Deploy

**Purpose:** Deploy the application to EC2 instance

**Components:**
- **AWS CodeDeploy** - Deployment orchestration service
- **CodeDeploy Agent** - Runs on EC2 instance
- **Deployment Configuration:** appspec.yml

**Actions:**
1. CodeDeploy receives deployment artifact from pipeline
2. Agent on EC2 instance downloads new application version
3. Executes deployment lifecycle hooks defined in appspec.yml
4. Replaces old application files with new version
5. Restarts application services
6. Validates deployment success

**Deployment Lifecycle:**
```yaml
# appspec.yml structure
version: 0.0
os: linux
files:
  - source: /
    destination: /var/www/presidents-app
hooks:
  ApplicationStop:
    - location: scripts/stop_application.sh
  BeforeInstall:
    - location: scripts/before_install.sh
  AfterInstall:
    - location: scripts/after_install.sh
  ApplicationStart:
    - location: scripts/start_application.sh
  ValidateService:
    - location: scripts/validate_service.sh

**Outputs:**
- Deployment status (success/failure)
- Application running on EC2 with latest code

## Component Details

### AWS CodeCommit

**Role:** Source code repository

**Features:**
- Git-based version control
- Integrated with IAM for authentication
- Triggers CodePipeline on push events
- Supports branching and pull requests

**Repository Structure:**
presidents-app/
├── app/
│   ├── presidents.py          # Main application
│   ├── requirements.txt       # App dependencies
│   └── templates/             # Flask templates
├── tests/
│   ├── test_handler.py        # Unit tests
│   └── requirements.txt       # Test dependencies
├── scripts/
│   ├── stop_application.sh
│   ├── start_application.sh
│   └── validate_service.sh
├── appspec.yml                # CodeDeploy configuration
└── run_tests.sh               # Test execution script

### AWS CodePipeline

**Role:** CI/CD orchestration

**Features:**
- Automated workflow execution
- Stage-based pipeline structure
- Integration with multiple AWS services
- Artifact management via S3
- Pipeline visualization in console

**Pipeline Configuration:**
- **Name:** presidents-app-pipeline
- **Service Role:** Allows CodePipeline to access CodeCommit, CodeDeploy, S3
- **Artifact Store:** S3 bucket for storing artifacts between stages

**Execution Flow:**
1. Developer pushes code to CodeCommit
2. CloudWatch Events triggers pipeline
3. Source stage pulls code
4. Test stage executes unit tests
5. If tests pass, Deploy stage activates
6. CodeDeploy deploys to EC2
7. Pipeline completes successfully

### AWS CodeDeploy

**Role:** Application deployment automation

**Features:**
- In-place deployments
- Blue/green deployment support
- Automatic rollback on failure
- Deployment lifecycle hooks
- Integration with Auto Scaling groups

**Deployment Configuration:**
- **Application Name:** presidents-app
- **Deployment Group:** production-servers
- **Deployment Type:** In-place
- **Service Role:** Allows CodeDeploy to access EC2 instances

**Agent:**
- Installed on EC2 instance
- Polls CodeDeploy for deployment instructions
- Executes deployment lifecycle hooks
- Reports deployment status

### Amazon EC2

**Role:** Application hosting

**Instance Configuration:**
- **AMI:** Amazon Linux 2
- **Instance Type:** t2.micro (or similar)
- **Security Group:** Allows HTTP (80), HTTPS (443), SSH (22)
- **IAM Role:** Allows instance to access DynamoDB

**Installed Software:**
- Python 3.7+
- Flask web framework
- boto3 (AWS SDK for Python)
- CodeDeploy agent
- nginx or Apache (web server)

**Application Setup:**
- Application files in `/var/www/presidents-app/`
- Virtual environment for Python dependencies
- Systemd service for application management
- Web server configured to proxy to Flask app

### Amazon DynamoDB

**Role:** Data storage

**Table Configuration:**
- **Table Name:** Presidents
- **Primary Key:** PresidentID (Number)
- **Attributes:** Name, Born, Died, Party, etc.

**Data Access:**
- Application uses boto3 to query table
- IAM role on EC2 provides access permissions
- Read-only access for application

## Unit Testing Workflow

### Test Structure

```python
# tests/test_handler.py

import pytest
from datetime import datetime
from app.presidents import calculate_age

def test_calculate_age_john_adams():
    """Test age calculation for John Adams"""
    born = datetime(1735, 10, 30)
    died = datetime(1826, 7, 4)
    
    age = calculate_age(born, died)
    
    # John Adams was 90 years old when he died
    assert age == 90, f"Expected 90, got {age}"

def test_calculate_age_george_washington():
    """Test age calculation for George Washington"""
    born = datetime(1732, 2, 22)
    died = datetime(1799, 12, 14)
    
    age = calculate_age(born, died)
    
    # George Washington was 67 years old when he died
    assert age == 67, f"Expected 67, got {age}"

### Test Execution Flow

1. **Setup Phase**
   - Install dependencies
   - Import application modules
   - Initialize test fixtures

2. **Execution Phase**
   - pytest discovers all test files
   - Runs each test function
   - Captures assertions and results

3. **Reporting Phase**
   - Displays pass/fail status
   - Shows code coverage metrics
   - Generates detailed error messages for failures

4. **Quality Gate Decision**
   - All tests pass → Pipeline continues
   - Any test fails → Pipeline stops

## Security Considerations

### IAM Roles and Permissions

**CodePipeline Service Role:**
- Read access to CodeCommit repository
- Write access to S3 artifact bucket
- Invoke CodeDeploy deployments
- CloudWatch Logs for pipeline logging

**CodeDeploy Service Role:**
- Read access to S3 artifact bucket
- Describe and update EC2 instances
- Create and manage Auto Scaling groups
- CloudWatch Logs for deployment logging

**EC2 Instance Role:**
- Read access to DynamoDB Presidents table
- CloudWatch Logs for application logging
- S3 access for CodeDeploy artifacts

### Network Security

- **Security Groups:** Restrict inbound traffic to necessary ports
- **VPC Configuration:** Deploy in private subnet with NAT gateway
- **HTTPS:** Use SSL/TLS for production deployments

## Monitoring and Logging

### CloudWatch Logs

- **CodePipeline:** Pipeline execution logs
- **CodeDeploy:** Deployment logs and lifecycle hook output
- **EC2 Application:** Application logs and errors
- **CodeDeploy Agent:** Agent activity and deployment status

### Metrics

- **Pipeline Success Rate:** Percentage of successful pipeline executions
- **Test Pass Rate:** Percentage of test runs that pass
- **Deployment Duration:** Time taken for deployments
- **Application Health:** EC2 instance health checks

## Best Practices Implemented

1. **Automated Testing** - Every code change is automatically tested
2. **Quality Gates** - Failed tests prevent deployment
3. **Fast Feedback** - Developers know immediately if changes break tests
4. **Deployment Automation** - No manual deployment steps
5. **Rollback Capability** - CodeDeploy can rollback failed deployments
6. **Infrastructure as Code** - Pipeline and deployment configs are version-controlled
7. **Separation of Concerns** - Clear stages for source, test, and deploy
8. **Monitoring** - CloudWatch integration for visibility

## Scalability Considerations

### Current Architecture
- Single EC2 instance
- In-place deployments
- Manual scaling

### Production Enhancements
- **Auto Scaling Group** - Multiple EC2 instances for high availability
- **Blue/Green Deployments** - Zero-downtime deployments
- **Load Balancer** - Distribute traffic across instances
- **Multi-Region** - Deploy to multiple AWS regions
- **Canary Deployments** - Gradual rollout to subset of instances

## Troubleshooting Guide

### Pipeline Fails at Source Stage
- Verify CodeCommit repository permissions
- Check branch name configuration
- Ensure repository exists and has commits

### Pipeline Fails at Test Stage
- Review test execution logs in CodePipeline console
- Check test dependencies are correctly specified
- Verify test assertions match expected behavior
- Run tests locally to reproduce failures

### Pipeline Fails at Deploy Stage
- Check CodeDeploy agent is running on EC2 instance
- Verify appspec.yml is correctly formatted
- Review deployment logs in CodeDeploy console
- Check EC2 instance IAM role permissions

### Application Not Accessible After Deployment
- Verify security group allows inbound HTTP traffic
- Check application service is running on EC2
- Review application logs for startup errors
- Confirm web server configuration is correct

## Future Enhancements

1. **Integration Tests** - Add tests that verify DynamoDB integration
2. **Performance Tests** - Load testing before production deployment
3. **Security Scanning** - Automated vulnerability scanning
4. **Manual Approval** - Add approval gate before production deployment
5. **Notifications** - SNS alerts for pipeline failures
6. **Parallel Testing** - Run tests in parallel for faster feedback
7. **Container Deployment** - Migrate to ECS or EKS for containerized deployment
8. **Infrastructure as Code** - Use CloudFormation or Terraform for complete infrastructure automation
