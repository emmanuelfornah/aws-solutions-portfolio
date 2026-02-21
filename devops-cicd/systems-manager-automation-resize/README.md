# Using AWS Systems Manager Automation to Resize EC2 Instances

## Overview

This lab demonstrates automated EC2 instance management using AWS Systems Manager Automation. You'll use the AWS-ResizeInstance automation document to resize multiple EC2 instances simultaneously, configure rate control and concurrency limits, set error thresholds, and use tag-based targeting. This approach enables safe, controlled, and auditable infrastructure changes at scale.

## AWS Services Used

- **AWS Systems Manager Automation** - Automated workflow execution
- **AWS Systems Manager Documents** - Pre-built automation runbooks
- **Amazon EC2** - Compute instances to resize
- **AWS IAM** - Automation execution role and permissions
- **AWS CloudTrail** - Audit trail for automation executions

## Objectives

- Execute Systems Manager Automation workflows
- Use AWS-ResizeInstance document to change instance types
- Configure rate control and concurrency for safe deployments
- Set error thresholds to prevent widespread failures
- Target instances using tags
- Monitor automation execution and handle failures
- Understand automation best practices for production changes

## Key Learnings

- **Automation Documents**: Pre-built runbooks for common tasks (resize instances, patch AMIs, backup volumes). Custom documents support complex workflows.

- **Rate Control**: Limits how many targets are processed simultaneously. Prevents overwhelming infrastructure or causing widespread outages.

- **Concurrency**: Absolute (e.g., 5 instances) or percentage (e.g., 10% of fleet). Choose based on fleet size and risk tolerance.

- **Error Threshold**: Maximum failures before automation stops. Prevents cascading failures across fleet.

- **Tag-Based Targeting**: Select instances using tags (e.g., `Environment=Dev`, `Application=WebServer`). More flexible than instance ID lists.

- **Automation Execution**: Asynchronous by default. Monitor progress in Systems Manager console or via CloudWatch Events.

- **Rollback Capability**: Some automation documents support automatic rollback on failure. AWS-ResizeInstance does not (manual rollback required).

## Setup Instructions

### Prerequisites

- AWS account with Systems Manager and EC2 permissions
- Multiple EC2 instances (3+) for testing
- Instances tagged for targeting (e.g., `Environment=Dev`)
- IAM role for automation execution

### Step 1: Tag EC2 Instances for Targeting

1. Navigate to **EC2** > **Instances**
2. Select instances to resize
3. Click **Actions** > **Manage tags**
4. Add tags:
   - Key: `Environment`, Value: `Dev`
   - Key: `ResizeGroup`, Value: `Batch1`
5. Click **Save**

### Step 2: Create IAM Role for Automation

1. Navigate to **IAM** > **Roles** > **Create role**
2. Select **AWS service** > **Systems Manager**
3. Select use case: **Systems Manager - Automation**
4. Attach policies:
   - `AmazonSSMAutomationRole` (managed policy)
5. Role name: `SSMAutomationRole`
6. Click **Create role**
7. Add inline policy for EC2 actions:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "ec2:DescribeInstances",
           "ec2:StopInstances",
           "ec2:StartInstances",
           "ec2:ModifyInstanceAttribute",
           "ec2:DescribeInstanceStatus"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

### Step 3: Review AWS-ResizeInstance Document

1. Navigate to **Systems Manager** > **Documents**
2. Search for: `AWS-ResizeInstance`
3. Click document name
4. Review **Content** tab:
   - **Parameters**: InstanceId, InstanceType
   - **Steps**: Stop instance → Modify instance type → Start instance
   - **Outputs**: New instance type, instance state
5. Note: Document stops instance, changes type, and restarts

### Step 4: Execute Automation - Single Instance Test

1. Navigate to **Systems Manager** > **Automation** > **Execute automation**
2. Search for and select: `AWS-ResizeInstance`
3. Configure parameters:
   - **InstanceId**: Select one test instance
   - **InstanceType**: `t2.small` (or desired type)
   - **Automation assume role**: `SSMAutomationRole` ARN
4. Click **Execute**
5. Monitor execution:
   - **Status**: Pending → In Progress → Success
   - **Steps**: View each step's status
   - **Outputs**: View new instance type
6. Verify instance:
   - Navigate to **EC2** > **Instances**
   - Check instance type changed
   - Verify instance is running

### Step 5: Execute Automation - Multiple Instances with Rate Control

1. Navigate to **Systems Manager** > **Automation** > **Execute automation**
2. Select: `AWS-ResizeInstance`
3. Configure parameters:
   - **InstanceId**: Leave empty (use targets instead)
   - **InstanceType**: `t2.medium`
   - **Automation assume role**: `SSMAutomationRole` ARN
4. **Targets**:
   - **Parameter**: InstanceId
   - **Targets**: Specify tags
   - **Tag key**: `Environment`
   - **Tag value**: `Dev`
5. **Rate control**:
   - **Concurrency**: 2 (process 2 instances at a time)
   - **Error threshold**: 1 (stop if 1 instance fails)
6. Click **Execute**
7. Monitor execution:
   - View **Execution progress** for each target
   - Check **Success** and **Failed** counts
   - View individual execution details

### Step 6: Configure Advanced Rate Control

For large fleets, use percentage-based concurrency:

1. Execute automation with:
   - **Concurrency**: 10% (process 10% of fleet at a time)
   - **Error threshold**: 5% (stop if 5% of fleet fails)
2. Example: 100 instances
   - Processes 10 instances at a time
   - Stops if 5 instances fail

### Step 7: Monitor Automation Execution

1. Navigate to **Systems Manager** > **Automation** > **Execution history**
2. Click execution ID
3. View details:
   - **Status**: Success, Failed, Cancelled, TimedOut
   - **Executed by**: IAM user or role
   - **Start time** and **End time**
   - **Targets**: Number of instances
   - **Success rate**: Percentage of successful executions
4. Click **Execution ID** for individual target to see step-by-step details

### Step 8: Handle Failed Executions

If automation fails:

1. Click failed execution
2. Review **Failure message**
3. Common failures:
   - **Insufficient permissions**: Add missing IAM permissions
   - **Instance not found**: Verify instance ID or tags
   - **Instance state invalid**: Instance must be running or stopped
   - **Timeout**: Increase timeout in document parameters
4. Fix issue and re-execute automation

### Step 9: Create CloudWatch Alarm for Automation Failures

1. Navigate to **CloudWatch** > **Alarms** > **Create alarm**
2. Select metric: `AWS/SSM > AutomationExecutionStatus`
3. Configure:
   - **Statistic**: Sum
   - **Period**: 5 minutes
   - **Threshold**: Greater than 0 (for failed executions)
4. Configure action: SNS notification
5. Alarm name: `AutomationExecutionFailures`

### Step 10: Review Automation in CloudTrail

1. Navigate to **CloudTrail** > **Event history**
2. Filter by:
   - **Event name**: `StartAutomationExecution`
   - **User name**: Your IAM user
3. View event details:
   - **Request parameters**: Document name, parameters, targets
   - **Response elements**: Execution ID
   - **Source IP**: Where automation was triggered from

## Automation Best Practices

### Rate Control Guidelines

| Fleet Size | Concurrency | Error Threshold | Rationale |
|------------|-------------|-----------------|-----------|
| 1-10 instances | 1-2 | 1 | Small fleet, process slowly |
| 10-50 instances | 5 or 10% | 2 or 5% | Medium fleet, moderate speed |
| 50-100 instances | 10 or 10% | 5 or 5% | Large fleet, controlled rollout |
| 100+ instances | 10% | 5% | Very large fleet, percentage-based |

### Pre-Execution Checklist

- [ ] Test automation on single instance first
- [ ] Verify IAM role has required permissions
- [ ] Confirm instances are in correct state (running or stopped)
- [ ] Set appropriate rate control and error thresholds
- [ ] Schedule during maintenance window (for production)
- [ ] Notify stakeholders of planned changes
- [ ] Have rollback plan ready

### Post-Execution Validation

- [ ] Verify all instances resized successfully
- [ ] Check application functionality
- [ ] Review CloudWatch metrics for performance impact
- [ ] Document execution results
- [ ] Update runbooks with lessons learned

## Common Automation Documents

| Document | Purpose | Use Case |
|----------|---------|----------|
| AWS-ResizeInstance | Change instance type | Rightsizing, performance optimization |
| AWS-StopEC2Instance | Stop instances | Cost savings, maintenance |
| AWS-StartEC2Instance | Start instances | Resume operations |
| AWS-RestartEC2Instance | Reboot instances | Apply updates, troubleshooting |
| AWS-CreateSnapshot | Create EBS snapshots | Backup, disaster recovery |
| AWS-DeleteSnapshot | Delete old snapshots | Cost optimization |
| AWS-UpdateLinuxAmi | Patch and create AMI | Golden image creation |
| AWS-UpdateWindowsAmi | Patch Windows and create AMI | Golden image creation |

See [configs/automation-documents.json](./configs/automation-documents.json) for document parameters.

## Testing and Validation

### Test Scenario 1: Single Instance Resize

**Action**: Resize one t2.micro instance to t2.small

**Expected Results**:
- Automation execution succeeds
- Instance stops, resizes, and restarts
- Instance type changes to t2.small
- Total downtime: 2-3 minutes

### Test Scenario 2: Batch Resize with Rate Control

**Action**: Resize 5 instances with concurrency=2, error threshold=1

**Expected Results**:
- First 2 instances process simultaneously
- After completion, next 2 instances process
- If 1 instance fails, automation stops
- Successful instances remain resized

### Test Scenario 3: Tag-Based Targeting

**Action**: Resize all instances with tag `Environment=Dev`

**Expected Results**:
- Automation targets only tagged instances
- Other instances are not affected
- Execution history shows all targeted instances

## Cleanup

1. Resize instances back to original type (if needed):
   ```bash
   aws ssm start-automation-execution \
     --document-name "AWS-ResizeInstance" \
     --parameters "InstanceId=i-1234567890abcdef0,InstanceType=t2.micro" \
     --target-parameter-name "InstanceId" \
     --targets "Key=tag:Environment,Values=Dev"
   ```

2. Delete CloudWatch alarm (if created)
3. Remove test tags from instances

## Real-World Applications

- **Cost Optimization**: Downsize over-provisioned instances during off-peak hours
- **Performance Scaling**: Upsize instances before high-traffic events
- **Disaster Recovery**: Automate instance recovery and resizing
- **Compliance**: Enforce instance type policies across fleet
- **Maintenance Windows**: Batch resize instances during scheduled maintenance

## Interview Talking Points

- **Explain rate control**: Limits concurrent executions to prevent overwhelming infrastructure
- **Describe error thresholds**: Stops automation if too many failures occur, preventing widespread issues
- **Discuss tag-based targeting**: More flexible than instance ID lists, supports dynamic fleets
- **Compare to manual resizing**: Automation provides consistency, auditability, and scale

## Complexity Level

**Intermediate** - Requires understanding of Systems Manager Automation, EC2, and IAM.

## Estimated Time

**30 minutes** - Including IAM role creation, automation execution, and validation.

## AWS Certification Alignment

- **AWS Certified SysOps Administrator Associate**: Automation, operational management, fleet management
- **AWS Certified Solutions Architect Associate**: Automation architecture, scaling strategies
- **AWS Certified DevOps Engineer Professional**: Infrastructure automation, deployment strategies

## Completion Date

2024-01-15
