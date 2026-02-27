# Implementing AWS CloudFormation Intrinsic Functions and Keywords

## Overview

This lab teaches advanced CloudFormation template development through hands-on implementation of intrinsic functions, conditions, and rules. As AnyCompany transitions to Infrastructure as Code (IaC), you enhance an existing CloudFormation template by implementing key utilities that enable dynamic resource configuration, cross-stack references, and environment-specific deployments. The fill-in-the-blanks approach reinforces learning by requiring active implementation rather than passive observation.

## AWS Services Used

- **AWS CloudFormation** - Infrastructure as Code service for declarative resource provisioning
- **Amazon EC2** - Compute instances configured dynamically based on environment
- **Amazon VPC** - Virtual Private Cloud for network isolation
- **AWS IAM** - Identity and Access Management for resource permissions
- **AWS Code Editor** - Cloud-based IDE for template development

## Architecture

The CloudFormation template creates a multi-environment EC2 deployment with dynamic configuration:

1. **Parameters**: Environment selection (Development/Production) and AMI ID input
2. **Mappings**: EnvironmentConfigMap defining instance types per environment
3. **Cross-Stack References**: Import VPC and Subnet IDs from existing infrastructure stack
4. **EC2 Instance**: Dynamically configured with environment-specific settings
5. **Security Group**: Allows HTTP traffic for web server access
6. **UserData Script**: Apache HTTP server with dynamic HTML displaying instance metadata
7. **Outputs**: Instance DNS name and website URL for easy access

**Key Intrinsic Functions Demonstrated:**
- `!Ref` - Reference parameters and resources
- `!FindInMap` - Retrieve values from mappings based on keys
- `!ImportValue` - Cross-stack references for shared resources
- `!GetAtt` - Retrieve resource attributes (e.g., PublicDnsName)
- `!Sub` - String substitution with variable interpolation
- `Fn::Base64` - Encode UserData scripts for EC2

## Objectives

- Understand CloudFormation intrinsic functions and their use cases
- Implement `!Ref` function to reference parameters and resources
- Use `!FindInMap` to retrieve environment-specific configuration values
- Implement `!ImportValue` for cross-stack resource references
- Apply `!GetAtt` to retrieve resource attributes dynamically
- Use `!Sub` for string substitution in UserData scripts and outputs
- Deploy and validate a multi-environment CloudFormation stack
- Test dynamic configuration by accessing the deployed web application

## Key Learnings

- **Intrinsic Functions Enable Dynamic Templates**: Functions like `!Ref`, `!FindInMap`, and `!Sub` transform static YAML into dynamic infrastructure code that adapts to different environments and inputs.

- **Cross-Stack References Promote Reusability**: `!ImportValue` allows stacks to share resources (VPCs, subnets, security groups) without duplication, enabling modular infrastructure design.

- **Mappings Support Multi-Environment Deployments**: The EnvironmentConfigMap pattern allows a single template to deploy different instance types for Development (t2.micro) vs Production (t2.small) environments.

- **!GetAtt Retrieves Runtime Attributes**: Many resource properties (like EC2 PublicDnsName) are only known after creation. `!GetAtt` enables dynamic output generation and resource chaining.

- **!Sub Simplifies String Construction**: String substitution with `!Sub` eliminates complex concatenation, making UserData scripts and URLs more readable and maintainable.

- **UserData Enables Instance Bootstrapping**: The Fn::Base64 encoded UserData script automatically installs Apache and creates a custom webpage during instance launch, demonstrating infrastructure automation.

- **Parameters Provide Template Flexibility**: Parameterized templates can be reused across accounts, regions, and environments without modification, following IaC best practices.

## Setup Instructions

### Prerequisites

- AWS account with CloudFormation, EC2, and VPC permissions
- Existing VPC stack with exported outputs (LabVPCId, PublicSubnetId)
- AWS Code Editor IDE access (or local text editor)
- Basic understanding of YAML syntax and CloudFormation concepts

### Step 1: Access AWS Code Editor and Open Template

1. Navigate to AWS Code Editor in the AWS Console
2. Open the `LabTemplate.yaml` file in the editor
3. Review the template structure: Parameters, Mappings, Resources, Outputs
4. Identify the sections marked with `# TODO: Implement` comments

### Step 2: Implement !Ref Function

The `!Ref` function returns the value of a parameter or the physical ID of a resource.

**Task 2.1: Reference LatestAmiId Parameter**

Locate the `LabInstance` resource and implement the ImageId property:

```yaml
Resources:
  LabInstance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId  # References the parameter value
```

**Task 2.2: Reference InstanceSecurityGroup Resource**

Implement the SecurityGroupIds property:

```yaml
      SecurityGroupIds:
        - !Ref InstanceSecurityGroup  # References the security group resource
```

### Step 3: Implement !FindInMap Function

The `!FindInMap` function retrieves values from the Mappings section based on keys.

**Mapping Structure:**
```yaml
Mappings:
  EnvironmentConfigMap:
    Development:
      InstanceType: t2.micro
    Production:
      InstanceType: t2.small
```

**Task 3.1: Retrieve Instance Type Based on Environment**

```yaml
      InstanceType: !FindInMap
        - EnvironmentConfigMap      # Map name
        - !Ref Environment           # First-level key (Development or Production)
        - InstanceType               # Second-level key
```

### Step 4: Implement !ImportValue Function

The `!ImportValue` function references outputs exported by other CloudFormation stacks.

**Task 4.1: Import Subnet ID from Infrastructure Stack**

```yaml
      SubnetId: !ImportValue PublicSubnetId  # Imports exported value from another stack
```

**Task 4.2: Import VPC ID for Security Group**

```yaml
  InstanceSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      VpcId: !ImportValue LabVPCId  # References VPC from infrastructure stack
```

### Step 5: Implement !GetAtt Function

The `!GetAtt` function retrieves attributes of resources created by CloudFormation.

**Task 5.1: Get Instance Public DNS Name**

```yaml
Outputs:
  InstancePublicDNS:
    Description: Public DNS name of the EC2 instance
    Value: !GetAtt LabInstance.PublicDnsName  # Retrieves the DNS name attribute
```

### Step 6: Implement !Sub Function

The `!Sub` function performs string substitution with variable interpolation.

**Task 6.1: Substitute Variables in UserData Script**

```yaml
      UserData:
        Fn::Base64: !Sub |
          #!/bin/bash
          yum update -y
          yum install -y httpd
          systemctl start httpd
          systemctl enable httpd
          
          cat > /var/www/html/index.html <<EOF
          <html>
          <head><title>CloudFormation Utilities Lab</title></head>
          <body>
            <h1>CloudFormation Intrinsic Functions Demo</h1>
            <p><strong>Environment:</strong> ${Environment}</p>
            <p><strong>Instance ID:</strong> $(ec2-metadata --instance-id | cut -d " " -f 2)</p>
            <p><strong>Availability Zone:</strong> $(ec2-metadata --availability-zone | cut -d " " -f 2)</p>
          </body>
          </html>
          EOF
```

**Task 6.2: Construct Website URL with Instance DNS**

```yaml
  WebsiteURL:
    Description: URL of the deployed website
    Value: !Sub 'http://${LabInstance.PublicDnsName}'  # Combines string with attribute
```

### Step 7: Deploy CloudFormation Stack

1. Save the completed `LabTemplate.yaml` file
2. Navigate to CloudFormation in the AWS Console
3. Click "Create stack" → "With new resources"
4. Upload the template file
5. Configure stack details:
   - **Stack name**: `CloudFormationUtilities`
   - **Environment**: Select `Development` or `Production`
   - **LatestAmiId**: Use default or specify AMI ID
6. Review and create the stack
7. Monitor stack creation in the Events tab (5-10 minutes)

### Step 8: Validate Deployment

1. Navigate to the Outputs tab of the CloudFormation stack
2. Copy the `WebsiteURL` value
3. Open the URL in a web browser
4. Verify the webpage displays:
   - Environment name (Development or Production)
   - Instance ID
   - Availability Zone
5. Confirm the instance type matches the environment:
   - Development → t2.micro
   - Production → t2.small

### Step 9: Clean Up Resources

1. Navigate to CloudFormation in the AWS Console
2. Select the `CloudFormationUtilities` stack
3. Click "Delete" and confirm
4. Wait for stack deletion to complete (5-10 minutes)
5. Verify all resources (EC2 instance, security group) are terminated

## Configuration Files

### LabTemplate.yaml

The main CloudFormation template with intrinsic functions implementation:

- **[configs/LabTemplate.yaml](./configs/LabTemplate.yaml)** - Complete template with all intrinsic functions
- **[configs/LabTemplate-starter.yaml](./configs/LabTemplate-starter.yaml)** - Starter template with TODO comments for hands-on practice

### Key Template Sections

**Parameters:**
```yaml
Parameters:
  Environment:
    Type: String
    Default: Development
    AllowedValues:
      - Development
      - Production
    Description: Deployment environment
  
  LatestAmiId:
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2
```

**Mappings:**
```yaml
Mappings:
  EnvironmentConfigMap:
    Development:
      InstanceType: t2.micro
    Production:
      InstanceType: t2.small
```

**Resources:**
- EC2 Instance with dynamic configuration
- Security Group allowing HTTP (port 80) traffic
- UserData script for Apache installation and webpage creation

**Outputs:**
- InstancePublicDNS: Public DNS name for SSH access
- WebsiteURL: HTTP URL for web browser access

## Scripts

### Deployment Automation

- **[scripts/deploy-stack.sh](./scripts/deploy-stack.sh)** - AWS CLI script for automated stack deployment
- **[scripts/validate-template.sh](./scripts/validate-template.sh)** - Template syntax validation
- **[scripts/delete-stack.sh](./scripts/delete-stack.sh)** - Clean up script for resource deletion

### Testing Scripts

- **[scripts/test-website.sh](./scripts/test-website.sh)** - Automated website availability testing
- **[scripts/get-stack-outputs.sh](./scripts/get-stack-outputs.sh)** - Retrieve stack outputs via CLI

## Troubleshooting

### Common Issues

**Issue**: Stack creation fails with "Export PublicSubnetId not found"
- **Cause**: Infrastructure stack with exported values doesn't exist
- **Solution**: Deploy the prerequisite VPC stack first, or modify template to create VPC resources inline

**Issue**: Website URL returns "Connection refused"
- **Cause**: Security group not allowing HTTP traffic or Apache not started
- **Solution**: Verify security group ingress rules allow port 80, check UserData script execution in EC2 logs

**Issue**: !FindInMap returns empty value
- **Cause**: Environment parameter doesn't match mapping keys
- **Solution**: Ensure Environment parameter value exactly matches mapping keys (case-sensitive)

**Issue**: !GetAtt fails with "Resource does not support attribute"
- **Cause**: Attribute name is incorrect or not supported by resource type
- **Solution**: Refer to CloudFormation documentation for valid attributes per resource type

**Issue**: !Sub variable not substituted in output
- **Cause**: Incorrect syntax or variable name mismatch
- **Solution**: Use `${VariableName}` syntax for parameters/resources, `$(command)` for bash commands in UserData

## Intrinsic Functions Reference

| Function | Purpose | Example |
|----------|---------|---------|
| **!Ref** | Reference parameter or resource | `!Ref MyParameter` |
| **!GetAtt** | Get resource attribute | `!GetAtt MyInstance.PublicIp` |
| **!FindInMap** | Retrieve mapping value | `!FindInMap [MapName, Key1, Key2]` |
| **!Sub** | String substitution | `!Sub 'Hello ${Name}'` |
| **!ImportValue** | Cross-stack reference | `!ImportValue ExportedValue` |
| **!Join** | Join strings with delimiter | `!Join [',', [a, b, c]]` |
| **!Select** | Select item from list | `!Select [0, !GetAZs '']` |
| **!Split** | Split string into list | `!Split [',', 'a,b,c']` |
| **Fn::Base64** | Base64 encode | `Fn::Base64: !Sub '#!/bin/bash'` |

## Real-World Applications

- **Multi-Environment Deployments**: Use mappings and parameters to deploy dev, staging, and production environments from a single template
- **Cross-Stack Resource Sharing**: Share VPCs, subnets, and security groups across multiple application stacks using exports and imports
- **Dynamic Configuration**: Adapt instance types, storage sizes, and configurations based on environment or region
- **Automated Bootstrapping**: Use UserData with !Sub to configure instances with environment-specific settings during launch
- **Modular Infrastructure**: Build reusable template components that reference shared infrastructure stacks

## Next Steps

- Implement CloudFormation conditions to conditionally create resources based on parameters
- Add CloudFormation rules to validate parameter combinations before deployment
- Explore CloudFormation custom resources for advanced automation
- Implement nested stacks for modular template organization
- Add CloudFormation change sets to preview infrastructure changes before deployment
- Integrate with AWS CodePipeline for continuous infrastructure deployment

## Complexity Level

**Intermediate** - Requires understanding of CloudFormation syntax, YAML formatting, intrinsic functions, and cross-stack references.

## Estimated Time

**75 minutes** - Including template implementation, stack deployment, validation, and cleanup.

## AWS Certification Alignment

- **AWS Certified Cloud Practitioner**: Understanding of Infrastructure as Code concepts
- **AWS Certified Solutions Architect Associate**: CloudFormation template design, intrinsic functions, cross-stack references
- **AWS Certified Developer Associate**: CloudFormation development, UserData scripting, dynamic resource configuration
- **AWS Certified DevOps Engineer Professional**: Advanced CloudFormation patterns, multi-environment deployments, IaC best practices

## Completion Date

2024-01-20
