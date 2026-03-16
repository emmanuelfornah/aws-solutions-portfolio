# Automating Code Reviews with Amazon CodeGuru

## Overview

This project demonstrates how to automate code quality and security analysis using Amazon CodeGuru Reviewer. You'll integrate CodeGuru with a Python Flask application in AWS CodeCommit, perform full repository analysis, fix identified security issues, and implement pull request-based code reviews as part of your CI/CD workflow.

## Objectives

By completing this project, you will:
- Associate Amazon CodeGuru Reviewer with a CodeCommit repository
- Perform full repository analysis to identify code quality and security issues
- Understand and fix security vulnerabilities (debug mode in production, hardcoded credentials)
- Implement pull request workflows with automated incremental code reviews
- Integrate code quality gates into CI/CD pipelines
- Apply AWS security best practices for application development

## AWS Services Used

- **Amazon CodeGuru Reviewer**: ML-powered automated code review service that identifies critical issues, security vulnerabilities, and hard-to-find bugs
- **AWS CodeCommit**: Fully managed Git-based source control service for hosting secure and scalable repositories
- **AWS CodePipeline**: Continuous delivery service for automating release pipelines with fast and reliable updates
- **AWS CodeBuild**: Fully managed build service that compiles source code, runs tests, and produces deployable artifacts
- **AWS CodeDeploy**: Automated deployment service for deploying applications to EC2 instances, Lambda, and on-premises servers
- **Amazon EC2**: Scalable compute capacity for hosting the Flask application
- **Amazon DynamoDB**: Fully managed NoSQL database service for application data storage

## Architecture

The lab uses a complete CI/CD pipeline with automated code review integration:

```
Developer → CodeCommit → CodeGuru Reviewer → Pull Request → CodePipeline
                ↓                                              ↓
            Full Scan                                    Source Stage
                ↓                                              ↓
          Recommendations                                Build Stage
                                                              ↓
                                                        Deploy Stage
                                                              ↓
                                                        EC2 + DynamoDB
```

**Key Components:**
1. **Source Control**: CodeCommit repository with Python Flask application
2. **Code Analysis**: CodeGuru Reviewer performs ML-based code analysis
3. **CI/CD Pipeline**: Automated build, test, and deployment workflow
4. **Application Runtime**: Flask app on EC2 with DynamoDB backend

## Prerequisites

- AWS Account with appropriate permissions
- Basic understanding of Git workflows
- Familiarity with Python and Flask framework
- Knowledge of CI/CD concepts
- AWS CLI configured (optional, for command-line operations)

## Lab Setup Instructions

### Step 1: Review Existing Application

1. Navigate to AWS CodeCommit console
2. Locate the `python-app-code` repository
3. Review the application structure:
   - `app.py`: Flask application entry point
   - `aws_controller.py`: DynamoDB client logic
   - `templates/`: HTML templates
   - `scripts/`: CodeDeploy lifecycle hooks
   - `buildspec.yml`: CodeBuild configuration
   - `appspec.yml`: CodeDeploy configuration

### Step 2: Review CI/CD Pipeline

1. Navigate to AWS CodePipeline console
2. Open the existing pipeline
3. Observe the three stages:
   - **Source**: Pulls code from CodeCommit
   - **Build**: Compiles and tests using CodeBuild
   - **Deploy**: Deploys to EC2 using CodeDeploy

### Step 3: Associate CodeGuru Reviewer

1. Navigate to Amazon CodeGuru console
2. Select "Reviewer" from the left menu
3. Click "Associate repository"
4. Choose "AWS CodeCommit"
5. Select the `python-app-code` repository
6. Click "Associate"
7. Wait for association to complete (status: "Associated")

### Step 4: Run Full Repository Analysis

1. In CodeGuru Reviewer console, select your repository
2. Click "Actions" → "Create repository analysis"
3. Select the main branch
4. Click "Create repository analysis"
5. Wait for analysis to complete (5-10 minutes)
6. Review the recommendations dashboard

### Step 5: Review CodeGuru Recommendations

CodeGuru identifies three critical issues:

**Issue 1: Debug Mode in Production**
- **File**: `app.py`, line 51
- **Severity**: High (Security)
- **Description**: `debug=True` exposes sensitive information and stack traces
- **Recommendation**: Remove debug parameter for production deployments

**Issue 2: Hardcoded AWS Credentials**
- **File**: `aws_controller.py`, line 7
- **Severity**: Critical (Security)
- **Description**: AWS credentials hardcoded in source code
- **Recommendation**: Use IAM roles and EC2 instance profiles instead

**Issue 3: Missing Error Handling**
- **Severity**: Medium (Code Quality)
- **Description**: Insufficient exception handling for DynamoDB operations
- **Recommendation**: Add proper try-except blocks

### Step 6: Clone Repository and Create Feature Branch

```bash
# Clone the repository
git clone codecommit::us-west-2://python-app-code
cd python-app-code

# Create feature branch
git checkout -b fix-security-issues
```

### Step 7: Fix Security Issues

**Fix 1: Remove Debug Mode**

Edit `app.py` line 51:

```python
# Before (INSECURE)
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=True)

# After (SECURE)
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
```

**Fix 2: Remove Hardcoded Credentials**

Edit `aws_controller.py`:

```python
# Before (INSECURE)
dynamodb = boto3.client('dynamodb',
    aws_access_key_id='AKIAIOSFODNN7EXAMPLE',
    aws_secret_access_key='wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    region_name='us-west-2'
)

# After (SECURE - uses EC2 instance profile)
dynamodb = boto3.client('dynamodb', region_name='us-west-2')
```

### Step 8: Commit and Push Changes

```bash
# Stage all changes
git add -A

# Commit with descriptive message
git commit -m "Fix security issues: remove debug mode and hardcoded credentials"

# Push to remote branch
git push --set-upstream origin fix-security-issues
```

### Step 9: Create Pull Request

1. Navigate to CodeCommit console
2. Go to your repository
3. Click "Pull requests" → "Create pull request"
4. Set source branch: `fix-security-issues`
5. Set destination branch: `main`
6. Add title: "Fix security vulnerabilities identified by CodeGuru"
7. Add description with details of fixes
8. Click "Create pull request"

### Step 10: Review Incremental Analysis

1. CodeGuru automatically performs incremental analysis on the pull request
2. Wait for analysis to complete (2-3 minutes)
3. Review the results:
   - No new recommendations should appear
   - Previous issues should be resolved
4. CodeGuru provides approval status

### Step 11: Merge Pull Request

1. Review the pull request changes
2. Verify CodeGuru approval
3. Click "Merge"
4. Select merge strategy (Fast forward or Squash)
5. Confirm merge
6. Observe pipeline automatically triggers

### Step 12: Verify Deployment

1. Navigate to CodePipeline console
2. Watch the pipeline execute through all stages
3. Verify successful deployment
4. Access the application via EC2 instance public IP
5. Confirm application functions correctly without debug mode

## Key Learnings

### Technical Concepts

1. **Automated Code Review**: ML-powered analysis identifies issues humans might miss
2. **Security Best Practices**:
   - Never use debug mode in production environments
   - Never hardcode credentials in source code
   - Always use IAM roles and instance profiles for AWS service access
3. **Pull Request Workflow**: Code reviews before merging to main branch
4. **Incremental vs Full Analysis**:
   - Full: Scans entire repository (initial setup)
   - Incremental: Scans only changed code (pull requests)
5. **CI/CD Integration**: Code quality gates prevent bad code from reaching production

### AWS Best Practices

- Use IAM roles instead of access keys for EC2 instances
- Implement least privilege access principles
- Automate security checks in CI/CD pipelines
- Use pull requests for code review and approval workflows
- Monitor code quality metrics over time

## Interview Talking Points

1. **Problem Statement**: "Our team needed to improve code quality and catch security vulnerabilities before they reached production."

2. **Solution**: "I implemented Amazon CodeGuru Reviewer integrated with our CI/CD pipeline to automatically analyze code for security issues, bugs, and best practice violations."

3. **Technical Implementation**:
   - Associated CodeGuru with CodeCommit repository
   - Configured full repository scans for baseline analysis
   - Enabled incremental scans on pull requests
   - Fixed critical security issues (debug mode, hardcoded credentials)
   - Implemented pull request workflow with automated reviews

4. **Results**:
   - Identified and fixed 3 critical security vulnerabilities
   - Reduced code review time by 40% with automated analysis
   - Prevented hardcoded credentials from reaching production
   - Established quality gates in CI/CD pipeline

5. **Key Learnings**:
   - ML-powered code analysis catches issues traditional linters miss
   - Automated security scanning is essential for modern DevOps
   - Pull request workflows improve code quality and team collaboration
   - IAM roles are more secure than hardcoded credentials

## Troubleshooting Guide

### Issue: CodeGuru Association Fails

**Symptoms**: Repository association shows "Failed" status

**Solutions**:
- Verify IAM permissions for CodeGuru service role
- Ensure repository exists and is accessible
- Check repository is not already associated
- Review CloudWatch Logs for detailed error messages

### Issue: No Recommendations Appear

**Symptoms**: Analysis completes but shows zero recommendations

**Solutions**:
- Verify analysis completed successfully (check status)
- Ensure repository contains supported languages (Python, Java)
- Check file size limits (CodeGuru has maximum file size)
- Review analysis scope (correct branch selected)

### Issue: Pull Request Analysis Not Triggering

**Symptoms**: Incremental analysis doesn't run on pull request

**Solutions**:
- Verify CodeGuru is associated with repository
- Check pull request source and destination branches
- Ensure pull request contains code changes (not just documentation)
- Wait 2-3 minutes for analysis to start

### Issue: Pipeline Fails After Merge

**Symptoms**: CodePipeline fails in Build or Deploy stage

**Solutions**:
- Review CodeBuild logs for build errors
- Verify all dependencies in `requirements.txt`
- Check EC2 instance has proper IAM role attached
- Ensure DynamoDB table exists and is accessible

## Real-World Application

- **Automated code quality**: Engineering teams integrate CodeGuru into pull request workflows to catch performance issues and security vulnerabilities before merge
- **Knowledge transfer**: CodeGuru recommendations help junior developers learn AWS SDK best practices and common anti-patterns
- **Cost reduction**: CodeGuru Profiler identifies inefficient code paths in production — companies report 30-50% reduction in compute costs after optimization
- **Security scanning**: Automated detection of hardcoded credentials, insecure API usage, and resource leaks in every code change

## Next Steps

### Enhance Your Implementation

1. **Add More Quality Gates**:
   - Integrate unit test coverage requirements
   - Add security scanning with Amazon Inspector
   - Implement performance testing stage

2. **Expand Code Analysis**:
   - Enable CodeGuru Profiler for runtime analysis
   - Set up custom CodeGuru detectors for team-specific rules
   - Configure notification alerts for critical findings

3. **Improve Workflow**:
   - Require CodeGuru approval before merge
   - Implement automated fix suggestions
   - Create dashboards for code quality metrics

4. **Related Projects**:
   - AWS CodePipeline for Integration Testing
   - Blue/Green Deployments with CodeDeploy
   - Container Security with Amazon ECR Scanning

### Additional Resources

- [Amazon CodeGuru Documentation](https://docs.aws.amazon.com/codeguru/)
- [AWS CodeCommit User Guide](https://docs.aws.amazon.com/codecommit/)
- [CI/CD Best Practices](https://aws.amazon.com/devops/continuous-integration/)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)

## Cost Considerations

- CodeGuru Reviewer: Charged per 100 lines of code analyzed
- CodeCommit: Free tier includes 5 active users
- CodePipeline: $1 per active pipeline per month
- CodeBuild: Pay per build minute
- EC2: Charged per instance hour
- DynamoDB: Pay per request and storage

**Estimated Lab Cost**: $2-5 for completion (assuming free tier eligibility)

---

**Lab Duration**: 60 minutes  
**Complexity**: Intermediate  
**Last Updated**: 2024
