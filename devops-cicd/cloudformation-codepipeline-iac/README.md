# Deploying Infrastructure as Code with AWS CodePipeline

## Overview

This lab teaches how to create a CloudFormation template and configure CodePipeline to automatically deploy infrastructure when changes are made to the source code repository. You'll build a complete web application infrastructure including VPC, EC2 instances, Application Load Balancer, and security groups, then implement a CI/CD pipeline that automatically deploys infrastructure changes. The lab culminates in fixing a security vulnerability by removing SSH access through the pipeline.

**Duration:** 75 minutes  
**Complexity:** Intermediate  
**Category:** DevOps & CI/CD

## Objectives

By completing this lab, you will:

- Clone an Infrastructure as Code repository into AWS Code Editor
- Build a CloudFormation template defining complete application infrastructure
- Create VPC with multi-AZ architecture (public and private subnets)
- Deploy EC2 web servers with Apache using UserData scripts
- Configure Application Load Balancer with target groups
- Create CodePipeline with source, build, and deploy stages
- Configure CodeBuild project for infrastructure validation
- Deploy CloudFormation stack automatically via pipeline
- Identify and fix security vulnerabilities in infrastructure code
- Verify automatic redeployment when changes are pushed

## AWS Services Used

- **AWS CloudFormation** - Infrastructure as Code template deployment
- **AWS CodePipeline** - CI/CD orchestration for infrastructure
- **AWS CodeBuild** - Build and validation of CloudFormation templates
- **AWS CodeCommit** - Git-based source control for IaC
- **Amazon EC2** - Web server instances (t2.micro)
- **Application Load Balancer** - Distributes traffic across web servers
- **Amazon VPC** - Network isolation with public/private subnets
- **IAM** - Service roles for pipeline, build, and CloudFormation

## Architecture

The lab implements a multi-tier web application infrastructure with automated deployment:

### Infrastructure Components

1. **VPC** - IAC VPC (10.0.0.0/16) spanning 2 Availability Zones
2. **Public Subnets** - 10.0.1.0/24 (AZ1), 10.0.3.0/24 (AZ2)
3. **Private Subnets** - 10.0.2.0/24 (AZ1), 10.0.4.0/24 (AZ2)
4. **Application Load Balancer** - Distributes HTTP traffic to web servers
5. **EC2 Web Servers** - 2 instances running Apache in private subnets
6. **Security Groups** - WebServerSecurityGroup, LoadBalancerSecurityGroup
7. **IAM Roles** - WebServerInstanceProfile for EC2 permissions

### CI/CD Pipeline

1. **Source Stage** - CodeCommit repository (iac-code-repo)
2. **Build Stage** - CodeBuild project (IacBuildProject) validates templates
3. **Deploy Stage** - CloudFormation deploys stack (iac-stack)

### IAM Roles

- **ApplicationPipelineRole** - Permissions for CodePipeline orchestration
- **ApplicationBuildProjectRole** - Permissions for CodeBuild execution
- **PipelineCloudformation** - Permissions for CloudFormation stack operations

## Prerequisites

- AWS account with appropriate permissions
- AWS Code Editor or Cloud9 IDE environment
- CodeCommit repository (iac-code-repo)
- IAM roles pre-configured for pipeline, build, and CloudFormation

## Setup Instructions

### Step 1: Clone the IaC Repository

Clone the infrastructure code repository:
```bash
cd ~/environment
git clone https://git-codecommit.REGION.amazonaws.com/v1/repos/iac-code-repo
cd iac-code-repo
```

### Step 2: Create CloudFormation Template

Create `infrastructure.yml` with the following resources:

**VPC Configuration:**
```yaml
Resources:
  IACVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: IAC VPC
```

**Subnets (2 AZs, Public and Private):**
```yaml
  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref IACVPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      MapPublicIpOnLaunch: true

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref IACVPC
      CidrBlock: 10.0.3.0/24
      AvailabilityZone: !Select [1, !GetAZs '']
      MapPublicIpOnLaunch: true

  PrivateSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref IACVPC
      CidrBlock: 10.0.2.0/24
      AvailabilityZone: !Select [0, !GetAZs '']

  PrivateSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref IACVPC
      CidrBlock: 10.0.4.0/24
      AvailabilityZone: !Select [1, !GetAZs '']
```

**Security Groups:**
```yaml
  WebServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for web servers
      VpcId: !Ref IACVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          SourceSecurityGroupId: !Ref LoadBalancerSecurityGroup
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0  # SECURITY VULNERABILITY - Will be removed

  LoadBalancerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for load balancer
      VpcId: !Ref IACVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
```

**Application Load Balancer:**
```yaml
  ApplicationLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: IacApplicationLoadBalancer
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
      SecurityGroups:
        - !Ref LoadBalancerSecurityGroup

  Listener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      LoadBalancerArn: !Ref ApplicationLoadBalancer
      Port: 80
      Protocol: HTTP
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref TargetGroup

  TargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: AppTargetGroup
      Port: 80
      Protocol: HTTP
      VpcId: !Ref IACVPC
      HealthCheckPath: /
      HealthCheckProtocol: HTTP
      Targets:
        - Id: !Ref WebServer1
        - Id: !Ref WebServer2
```

**EC2 Web Servers:**
```yaml
  WebServerInstanceProfile:
    Type: AWS::IAM::InstanceProfile
    Properties:
      Roles:
        - !Ref WebServerRole

  WebServer1:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: t2.micro
      ImageId: !Ref LatestAmiId
      SubnetId: !Ref PrivateSubnet1
      SecurityGroupIds:
        - !Ref WebServerSecurityGroup
      IamInstanceProfile: !Ref WebServerInstanceProfile
      UserData:
        Fn::Base64: !Sub |
          #!/bin/bash
          yum update -y
          yum install -y httpd
          systemctl start httpd
          systemctl enable httpd
          echo "<h1>Web Server 1 - Deployed via IaC Pipeline</h1>" > /var/www/html/index.html

  WebServer2:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: t2.micro
      ImageId: !Ref LatestAmiId
      SubnetId: !Ref PrivateSubnet2
      SecurityGroupIds:
        - !Ref WebServerSecurityGroup
      IamInstanceProfile: !Ref WebServerInstanceProfile
      UserData:
        Fn::Base64: !Sub |
          #!/bin/bash
          yum update -y
          yum install -y httpd
          systemctl start httpd
          systemctl enable httpd
          echo "<h1>Web Server 2 - Deployed via IaC Pipeline</h1>" > /var/www/html/index.html
```

See [configs/infrastructure.yml](./configs/infrastructure.yml) for the complete template.

### Step 3: Create CodePipeline

Create a pipeline named `iac-pipeline` with three stages:

**Source Stage:**
- Source provider: AWS CodeCommit
- Repository: iac-code-repo
- Branch: main
- Change detection: Amazon CloudWatch Events

**Build Stage:**
- Build provider: AWS CodeBuild
- Project name: IacBuildProject
- Build specification: Use buildspec.yml from source

**Deploy Stage:**
- Deploy provider: AWS CloudFormation
- Action mode: Create or update stack
- Stack name: iac-stack
- Template: BuildArtifact::infrastructure.yml
- Role: PipelineCloudformation

### Step 4: Create CodeBuild Project

Create `buildspec.yml` for infrastructure validation:

```yaml
version: 0.2

phases:
  install:
    runtime-versions:
      python: 3.9
    commands:
      - pip install cfn-lint
  
  build:
    commands:
      - echo "Validating CloudFormation template..."
      - cfn-lint infrastructure.yml
      - echo "Template validation successful"

artifacts:
  files:
    - infrastructure.yml
```

See [configs/buildspec.yml](./configs/buildspec.yml) for the complete build specification.

### Step 5: Deploy Initial Stack

Commit and push the infrastructure code:
```bash
git add infrastructure.yml buildspec.yml
git commit -m "Initial infrastructure template"
git push origin main
```

Or use the provided script:
```bash
./scripts/deploy-infrastructure.sh
```

Monitor the pipeline execution in the CodePipeline console.

### Step 6: Verify Deployment

1. Navigate to CloudFormation console
2. Find the `iac-stack` stack
3. Check the Outputs tab for the Load Balancer DNS name
4. Access the Load Balancer URL in your browser
5. Verify you see the web server response

### Step 7: Fix Security Vulnerability

The initial template has Port 22 (SSH) open to the internet (0.0.0.0/0). Remove this security risk:

**Update WebServerSecurityGroup in infrastructure.yml:**
```yaml
  WebServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for web servers
      VpcId: !Ref IACVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          SourceSecurityGroupId: !Ref LoadBalancerSecurityGroup
        # SSH rule removed for security
```

### Step 8: Deploy Security Fix

Commit and push the security fix:
```bash
git add infrastructure.yml
git commit -m "Remove SSH access - security fix"
git push origin main
```

Watch the pipeline automatically trigger and deploy the updated stack.

### Step 9: Verify Security Fix

1. Navigate to EC2 console
2. Find the web server instances
3. Check their security groups
4. Verify Port 22 is no longer in the inbound rules

## Key Learnings

### Infrastructure as Code Benefits

- **Version Control** - Infrastructure changes tracked in Git
- **Repeatability** - Same template creates identical infrastructure
- **Automation** - No manual console clicking required
- **Consistency** - Eliminates configuration drift
- **Auditability** - All changes have commit history
- **Rollback** - Easy to revert to previous infrastructure state

### CloudFormation Best Practices

**Intrinsic Functions:**
- `!Ref` - Reference other resources
- `!GetAtt` - Get resource attributes
- `!Sub` - Substitute variables in strings
- `!Select` - Select from lists (e.g., AZs)
- `!GetAZs` - Get availability zones dynamically

**Multi-AZ Architecture:**
- Distributes resources across availability zones
- Provides high availability and fault tolerance
- Load balancer spans multiple AZs
- Web servers deployed in different AZs

**Security Groups:**
- Principle of least privilege
- Only allow necessary ports
- Use security group references instead of CIDR blocks
- Never expose SSH to 0.0.0.0/0 in production

### CI/CD for Infrastructure

**Automated Validation:**
- cfn-lint checks template syntax and best practices
- Catches errors before deployment
- Faster feedback than waiting for CloudFormation

**Pipeline Stages:**
- Source: Detects infrastructure code changes
- Build: Validates templates and runs tests
- Deploy: Applies infrastructure changes

**Change Management:**
- All infrastructure changes go through pipeline
- No manual CloudFormation console deployments
- Peer review via pull requests
- Automated testing prevents misconfigurations

### Security Considerations

**Common Vulnerabilities:**
- SSH (Port 22) open to internet
- RDP (Port 3389) open to internet
- Database ports exposed publicly
- Overly permissive IAM roles

**Security Fixes:**
- Remove unnecessary ingress rules
- Use bastion hosts for SSH access
- Implement VPN or AWS Systems Manager Session Manager
- Apply security group rules with specific source IPs or security groups

## Interview Talking Points

### Infrastructure as Code Implementation

**"I implemented a complete Infrastructure as Code solution using CloudFormation that deployed a multi-tier web application across two availability zones. The infrastructure included a VPC with public and private subnets, an Application Load Balancer, two EC2 web servers running Apache, and properly configured security groups. All infrastructure was defined in code and version-controlled in Git."**

### CI/CD Pipeline for Infrastructure

**"I built a CI/CD pipeline using CodePipeline that automatically deployed infrastructure changes. The pipeline had three stages: Source (CodeCommit), Build (CodeBuild with cfn-lint validation), and Deploy (CloudFormation). This meant that any changes to the infrastructure template were automatically validated and deployed, eliminating manual console work and reducing deployment errors."**

### Security Vulnerability Remediation

**"During the lab, I identified a security vulnerability where SSH access (Port 22) was open to the entire internet (0.0.0.0/0). I fixed this by removing the SSH ingress rule from the security group and pushed the change through the pipeline. The automated deployment updated the running infrastructure, demonstrating how IaC enables rapid security fixes across all environments."**

### Multi-AZ High Availability

**"The infrastructure was designed for high availability using a multi-AZ architecture. The Application Load Balancer spanned two availability zones, and web servers were deployed in separate AZs in private subnets. This design ensures that if one availability zone fails, the application remains available. The load balancer automatically routes traffic only to healthy instances."**

## Project Structure

```
devops-cicd/cloudformation-codepipeline-iac/
├── README.md                          # This file
├── scripts/
│   ├── deploy-infrastructure.sh       # Git workflow for deploying changes
│   └── validate-template.sh           # Local CloudFormation validation
└── configs/
    ├── infrastructure.yml             # Complete CloudFormation template
    └── buildspec.yml                  # CodeBuild build specification
```

## Additional Resources

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [AWS CodePipeline User Guide](https://docs.aws.amazon.com/codepipeline/)
- [AWS CodeBuild Documentation](https://docs.aws.amazon.com/codebuild/)
- [CloudFormation Best Practices](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html)
- [cfn-lint Tool](https://github.com/aws-cloudformation/cfn-lint)
- [VPC Design Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-design.html)

## Troubleshooting

### Pipeline Fails at Build Stage

- Check buildspec.yml syntax
- Verify cfn-lint is installed correctly
- Review CloudFormation template for syntax errors
- Check CodeBuild logs for detailed error messages

### CloudFormation Stack Creation Fails

- Review CloudFormation Events tab for specific error
- Check IAM role permissions (PipelineCloudformation)
- Verify resource limits (VPC limit, EC2 instance limit)
- Ensure AMI ID is valid for the region

### Web Servers Not Accessible

- Verify security group rules allow HTTP (Port 80)
- Check that instances are in target group
- Ensure load balancer is in "active" state
- Verify UserData script executed successfully (check EC2 logs)

### Pipeline Doesn't Trigger on Push

- Verify CloudWatch Events rule is configured
- Check CodePipeline is monitoring correct branch
- Ensure IAM permissions allow CodePipeline to access CodeCommit

## Next Steps

- Add NAT Gateways for private subnet internet access
- Implement Auto Scaling for web servers
- Add RDS database to the infrastructure
- Create separate templates for network and application layers
- Implement CloudFormation nested stacks
- Add CloudFormation drift detection
- Configure CloudWatch alarms for infrastructure monitoring
- Implement blue/green deployment for infrastructure updates

## License

This lab is for educational purposes as part of an AWS training portfolio.
