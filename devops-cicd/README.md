# DevOps & CI/CD

AWS DevOps services including Systems Manager, AWS Config, automation, and infrastructure management.

## Labs

### 1. [Auditing AWS Resources with AWS Systems Manager and AWS Config](./systems-manager-config-audit/)
**Duration**: 60 minutes | **Complexity**: Intermediate

Comprehensive resource auditing using Systems Manager Inventory, Session Manager, Fleet Manager, and AWS Config rules for compliance monitoring.

**Key Services**: Systems Manager, Inventory, Session Manager, Fleet Manager, AWS Config, Config Rules

### 2. [Using AWS Config for Compliance and Security Automation](./config-compliance-automation/)
**Duration**: 60 minutes | **Complexity**: Intermediate

Automated compliance monitoring and remediation using AWS Config rules and Systems Manager Automation documents. Includes automatic remediation for S3 and EC2 security violations.

**Key Services**: AWS Config, Config Rules, Systems Manager Automation, EC2, S3, IAM

### 3. [Creating a Package in Distributor, a Capability of AWS Systems Manager](./distributor-package-creation/)
**Duration**: 30 minutes | **Complexity**: Intermediate

Create custom software packages using Systems Manager Distributor. Package CloudWatch agent and deploy across EC2 fleet using Run Command.

**Key Services**: Systems Manager Distributor, Run Command, S3, EC2, IAM

### 4. [Using AWS Systems Manager Automation to Resize EC2 Instances](./systems-manager-automation-resize/)
**Duration**: 30 minutes | **Complexity**: Intermediate

Automated EC2 instance management using Systems Manager Automation. Configure rate control, concurrency, error thresholds, and tag-based targeting for safe fleet-wide changes.

**Key Services**: Systems Manager Automation, EC2, IAM, CloudTrail

### 5. [Using AWS CodePipeline for Unit Testing](./codepipeline-unit-testing/)
**Duration**: 60 minutes | **Complexity**: Intermediate

Implement automated unit testing in a CI/CD pipeline using AWS CodePipeline. Fix a bug in a Flask Presidents application using test-driven development, where age calculation uses relativedelta instead of simple year subtraction. Push changes to CodeCommit and watch CodePipeline automatically test and deploy.

**Key Services**: AWS CodePipeline, AWS CodeCommit, AWS CodeDeploy, AWS Cloud9/Code Editor, Amazon EC2, Amazon DynamoDB, pytest

### 6. [Using AWS CodePipeline for Integration Testing](./codepipeline-integration-testing/)
**Duration**: 60 minutes | **Complexity**: Intermediate

Integrate automated integration testing into a CI/CD pipeline using AWS CodePipeline and CodeBuild. Create a CodeBuild project for integration testing, add an integration test stage to an existing pipeline, and configure tests that validate Flask application functionality. Fix intentional test errors and verify successful deployment to EC2.

**Key Services**: AWS CodePipeline, AWS CodeBuild, AWS CodeCommit, AWS CodeDeploy, Amazon EC2, pytest, Flask

### 7. [Creating Blue/Green Deployments with AWS CodeDeploy and Amazon EC2](./codedeploy-blue-green/)
**Duration**: 90 minutes | **Complexity**: Intermediate

Implement zero-downtime blue/green deployment strategy using AWS CodeDeploy. Transform an existing in-place deployment to blue/green by creating a new deployment group, configuring an Application Load Balancer for traffic management, and deploying across two EC2 instances. Manually verify new instances before rerouting traffic, eliminating downtime during application updates.

**Key Services**: AWS CodeDeploy, AWS CodePipeline, AWS CodeCommit, Amazon EC2, Application Load Balancer, Auto Scaling, CloudWatch Events

### 8. [Deploying Infrastructure as Code with AWS CodePipeline](./cloudformation-codepipeline-iac/)
**Duration**: 75 minutes | **Complexity**: Intermediate

Build a complete Infrastructure as Code pipeline using CloudFormation and CodePipeline. Create a multi-tier web application infrastructure with VPC, EC2 instances, Application Load Balancer, and security groups. Configure automated deployment pipeline with source, build (cfn-lint validation), and deploy stages. Fix security vulnerabilities by removing SSH access through the pipeline, demonstrating automated infrastructure updates.

**Key Services**: AWS CloudFormation, AWS CodePipeline, AWS CodeBuild, AWS CodeCommit, Amazon EC2, Application Load Balancer, Amazon VPC, IAM

### 9. [Building a Serverless API with AWS Infrastructure Composer](./infrastructure-composer-serverless-api/)
**Duration**: 90 minutes | **Complexity**: Intermediate

Use AWS Infrastructure Composer to visually design and build a serverless product catalog management system. Create a complete REST API with CRUD operations on DynamoDB, exposed through API Gateway and Lambda functions. Learn visual IaC design, serverless architecture patterns, Boto3 DynamoDB operations, and CloudFormation stack management through a drag-and-drop interface.

**Key Services**: AWS Infrastructure Composer, AWS CloudFormation, Amazon API Gateway, AWS Lambda, Amazon DynamoDB, IAM, Amazon S3

## Skills Developed

- Systems Manager operational management
- AWS Config compliance monitoring
- Automated remediation workflows
- Software package distribution
- Infrastructure automation at scale
- Rate control and error handling
- Tag-based resource targeting
- Audit and compliance reporting
- CI/CD pipeline automation
- Automated unit testing with pytest
- Integration testing with Flask test client
- Multi-stage testing strategies
- CodeBuild project configuration
- Test-driven development practices
- Git workflow with CodeCommit
- Automated deployment with CodeDeploy
- Debugging CI/CD pipeline failures
- Blue/green deployment strategies
- Zero-downtime deployment techniques
- Application Load Balancer traffic management
- Auto Scaling integration with CodeDeploy
- Manual traffic rerouting and verification
- Deployment rollback strategies
- Infrastructure as Code with CloudFormation
- CloudFormation template design and validation
- cfn-lint for template validation
- Multi-AZ architecture design
- Security group configuration and hardening
- VPC design with public/private subnets
- Infrastructure security vulnerability remediation
- Visual IaC design with Infrastructure Composer
- Serverless architecture patterns
- API Gateway REST API design
- Lambda function development with Python
- Boto3 DynamoDB operations (CRUD)
- AWS_PROXY integration patterns
- CloudFormation stack lifecycle management

## Certification Alignment

- **AWS Certified SysOps Administrator Associate**: Systems Manager, automation, operational management
- **AWS Certified Solutions Architect Associate**: Config architecture, automation design, VPC design, multi-AZ architecture
- **AWS Certified Security Specialty**: Compliance automation, security remediation, security group hardening
- **AWS Certified DevOps Engineer Professional**: Infrastructure automation, deployment strategies, CloudFormation, CI/CD pipelines
- **AWS Certified Developer Associate**: Lambda development, API Gateway, DynamoDB, serverless architecture
