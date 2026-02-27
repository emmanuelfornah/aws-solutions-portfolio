# Creating a Package in Distributor, a Capability of AWS Systems Manager

## Overview

This lab teaches how to create custom software packages using AWS Systems Manager Distributor. You'll package the CloudWatch agent as a custom Distributor package, store it in S3, and deploy it to EC2 instances using Run Command. Distributor simplifies software distribution across your EC2 fleet without manual downloads or configuration management tools.

## AWS Services Used

- **AWS Systems Manager Distributor** - Software package distribution
- **AWS Systems Manager Run Command** - Remote command execution
- **Amazon S3** - Package storage
- **Amazon EC2** - Target instances for package deployment
- **AWS IAM** - Permissions for Distributor and Run Command

## Objectives

- Understand Distributor package structure and manifest format
- Create custom Distributor package for CloudWatch agent
- Store package in S3 bucket
- Deploy package using Run Command
- Verify package installation across EC2 fleet
- Compare Distributor to traditional software deployment methods

## Key Learnings

- **Distributor vs Traditional Deployment**: Distributor eliminates manual downloads, SSH sessions, and configuration management complexity. Centralized package management with version control.

- **Package Structure**: Distributor packages contain manifest.json (metadata), install/uninstall scripts, and software binaries. Supports multiple OS platforms in single package.

- **Manifest Format**: JSON file defining package name, version, platform support, install/uninstall commands, and file locations.

- **Run Command Integration**: Distributor uses `AWS-ConfigureAWSPackage` document to install, update, or uninstall packages across fleet.

- **Version Management**: Distributor supports multiple package versions. Specify version during deployment or use "latest".

- **Platform Support**: Single package can support multiple platforms (Amazon Linux, Ubuntu, Windows) with platform-specific scripts.

## Package Structure

Distributor package directory structure:

```
cloudwatch-agent-package/
├── manifest.json                 # Package metadata and commands
├── amazon-cloudwatch-agent.rpm   # RPM package for Amazon Linux
└── install.sh                    # Optional custom install script
```

### Manifest.json Format

```json
{
  "schemaVersion": "2.0",
  "version": "1.0.0",
  "packages": {
    "amazon": {
      "_any": {
        "x86_64": {
          "file": "amazon-cloudwatch-agent.rpm"
        }
      }
    }
  }
}
```

See [configs/manifest-template.json](./configs/manifest-template.json) for complete manifest examples.

## Setup Instructions

### Prerequisites

- AWS account with Systems Manager and S3 permissions
- EC2 instances with Systems Manager agent
- CloudWatch agent RPM file (download from AWS)
- S3 bucket for package storage

### Step 1: Download CloudWatch Agent

1. Download CloudWatch agent RPM:
   ```bash
   wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
   ```

2. Verify download:
   ```bash
   ls -lh amazon-cloudwatch-agent.rpm
   ```

### Step 2: Create Package Directory Structure

1. Create package directory:
   ```bash
   mkdir -p cloudwatch-agent-package
   cd cloudwatch-agent-package
   ```

2. Move RPM file:
   ```bash
   mv ../amazon-cloudwatch-agent.rpm .
   ```

### Step 3: Create Manifest File

1. Create `manifest.json`:
   ```json
   {
     "schemaVersion": "2.0",
     "version": "1.0.0",
     "publisher": "Your Organization",
     "packages": {
       "amazon": {
         "_any": {
           "x86_64": {
             "file": "amazon-cloudwatch-agent.rpm"
           }
         }
       }
     }
   }
   ```

2. Validate JSON syntax:
   ```bash
   cat manifest.json | python -m json.tool
   ```

### Step 4: Create S3 Bucket for Distributor Packages

1. Create S3 bucket:
   ```bash
   aws s3 mb s3://distributor-packages-[ACCOUNT-ID]-[REGION]
   ```

2. Enable versioning (recommended):
   ```bash
   aws s3api put-bucket-versioning \
     --bucket distributor-packages-[ACCOUNT-ID]-[REGION] \
     --versioning-configuration Status=Enabled
   ```

### Step 5: Create Package ZIP File

1. Create ZIP archive:
   ```bash
   zip -r cloudwatch-agent-package.zip manifest.json amazon-cloudwatch-agent.rpm
   ```

2. Verify ZIP contents:
   ```bash
   unzip -l cloudwatch-agent-package.zip
   ```

### Step 6: Upload Package to S3

1. Upload ZIP to S3:
   ```bash
   aws s3 cp cloudwatch-agent-package.zip \
     s3://distributor-packages-[ACCOUNT-ID]-[REGION]/cloudwatch-agent/1.0.0/
   ```

2. Verify upload:
   ```bash
   aws s3 ls s3://distributor-packages-[ACCOUNT-ID]-[REGION]/cloudwatch-agent/1.0.0/
   ```

### Step 7: Create Distributor Package

1. Navigate to **Systems Manager** > **Distributor** > **Create package**
2. Configure package:
   - **Name**: `CloudWatchAgentCustom`
   - **Version name**: `1.0.0`
   - **S3 bucket**: `distributor-packages-[ACCOUNT-ID]-[REGION]`
   - **S3 key prefix**: `cloudwatch-agent/1.0.0/`
   - **Manifest**: Upload `manifest.json` or paste content
3. Click **Create package**

**Alternative: AWS CLI**:
```bash
aws ssm create-document \
  --name "CloudWatchAgentCustom" \
  --document-type "Package" \
  --content file://manifest.json \
  --attachments Key=S3FileUrl,Values=s3://distributor-packages-[ACCOUNT-ID]-[REGION]/cloudwatch-agent/1.0.0/cloudwatch-agent-package.zip
```

### Step 8: Deploy Package Using Run Command

1. Navigate to **Systems Manager** > **Run Command**
2. Click **Run command**
3. Search for and select: `AWS-ConfigureAWSPackage`
4. Configure command:
   - **Action**: Install
   - **Name**: `CloudWatchAgentCustom`
   - **Version**: `1.0.0` (or leave empty for latest)
5. **Targets**: Select EC2 instances
6. Click **Run**
7. Monitor execution status

**Alternative: AWS CLI**:
```bash
aws ssm send-command \
  --document-name "AWS-ConfigureAWSPackage" \
  --parameters '{"action":["Install"],"name":["CloudWatchAgentCustom"],"version":["1.0.0"]}' \
  --targets "Key=tag:Environment,Values=Production" \
  --comment "Install CloudWatch agent via Distributor"
```

See [scripts/deploy-package.sh](./scripts/deploy-package.sh) for automated deployment script.

### Step 9: Verify Package Installation

1. SSH to EC2 instance:
   ```bash
   ssh -i key.pem ec2-user@[INSTANCE-IP]
   ```

2. Verify CloudWatch agent installed:
   ```bash
   # Check RPM installation
   rpm -qa | grep amazon-cloudwatch-agent
   
   # Check agent status
   sudo systemctl status amazon-cloudwatch-agent
   ```

3. View Run Command output:
   - Navigate to **Systems Manager** > **Run Command**
   - Click command ID
   - Select instance
   - View **Output** tab

### Step 10: Update Package Version

To deploy updated version:

1. Create new package version (e.g., 1.0.1)
2. Upload to S3: `s3://bucket/cloudwatch-agent/1.0.1/`
3. Update Distributor package with new version
4. Deploy using Run Command with new version number

## Package Management Operations

### Install Package

```bash
aws ssm send-command \
  --document-name "AWS-ConfigureAWSPackage" \
  --parameters '{"action":["Install"],"name":["CloudWatchAgentCustom"]}' \
  --targets "Key=instanceids,Values=i-1234567890abcdef0"
```

### Update Package

```bash
aws ssm send-command \
  --document-name "AWS-ConfigureAWSPackage" \
  --parameters '{"action":["Install"],"name":["CloudWatchAgentCustom"],"version":["1.0.1"]}' \
  --targets "Key=instanceids,Values=i-1234567890abcdef0"
```

### Uninstall Package

```bash
aws ssm send-command \
  --document-name "AWS-ConfigureAWSPackage" \
  --parameters '{"action":["Uninstall"],"name":["CloudWatchAgentCustom"]}' \
  --targets "Key=instanceids,Values=i-1234567890abcdef0"
```

## Advanced Package Examples

### Multi-Platform Package

Support Amazon Linux and Ubuntu in single package:

```json
{
  "schemaVersion": "2.0",
  "version": "1.0.0",
  "packages": {
    "amazon": {
      "_any": {
        "x86_64": {
          "file": "amazon-cloudwatch-agent.rpm"
        }
      }
    },
    "ubuntu": {
      "_any": {
        "x86_64": {
          "file": "amazon-cloudwatch-agent.deb"
        }
      }
    }
  }
}
```

### Package with Custom Install Script

```json
{
  "schemaVersion": "2.0",
  "version": "1.0.0",
  "packages": {
    "amazon": {
      "_any": {
        "x86_64": {
          "file": "amazon-cloudwatch-agent.rpm"
        }
      }
    }
  },
  "files": {
    "install.sh": {
      "checksums": {
        "sha256": "abc123..."
      }
    }
  }
}
```

See [configs/advanced-manifests/](./configs/advanced-manifests/) for more examples.

## Testing and Validation

### Test Scenario 1: Package Installation

**Action**: Deploy package to EC2 instance

**Expected Results**:
- Run Command execution succeeds
- CloudWatch agent RPM is installed
- Agent service is running

### Test Scenario 2: Package Update

**Action**: Deploy newer package version

**Expected Results**:
- Old version is replaced
- New version is installed
- No manual intervention required

### Test Scenario 3: Fleet-Wide Deployment

**Action**: Deploy package to multiple instances using tags

**Expected Results**:
- All targeted instances receive package
- Deployment status visible in Run Command
- Failed installations are reported

## Cleanup

1. Uninstall package from instances:
   ```bash
   aws ssm send-command \
     --document-name "AWS-ConfigureAWSPackage" \
     --parameters '{"action":["Uninstall"],"name":["CloudWatchAgentCustom"]}' \
     --targets "Key=tag:Environment,Values=Production"
   ```

2. Delete Distributor package:
   ```bash
   aws ssm delete-document --name "CloudWatchAgentCustom"
   ```

3. Delete S3 package files:
   ```bash
   aws s3 rm s3://distributor-packages-[ACCOUNT-ID]-[REGION]/cloudwatch-agent/ --recursive
   ```

## Real-World Applications

- **Software Distribution**: Deploy custom applications, agents, and tools across EC2 fleet
- **Patch Management**: Distribute security patches and updates
- **Configuration Management**: Deploy configuration files and scripts
- **Compliance**: Ensure required software is installed on all instances
- **Disaster Recovery**: Quickly redeploy software after instance replacement

## Interview Talking Points

- **Explain Distributor benefits**: Centralized package management, version control, fleet-wide deployment, no SSH required
- **Describe package structure**: Manifest.json, binaries, install/uninstall scripts, multi-platform support
- **Discuss vs configuration management**: Simpler than Ansible/Chef/Puppet for basic software distribution
- **Explain Run Command integration**: AWS-ConfigureAWSPackage document handles install/update/uninstall

## Complexity Level

**Intermediate** - Requires understanding of Systems Manager, package management, and S3.

## Estimated Time

**30 minutes** - Including package creation, upload, and deployment.

## AWS Certification Alignment

- **AWS Certified SysOps Administrator Associate**: Systems Manager, software distribution, fleet management
- **AWS Certified Solutions Architect Associate**: Distributor architecture, deployment strategies
- **AWS Certified DevOps Engineer Professional**: Automation, configuration management, deployment pipelines

## Completion Date

2024-01-15
