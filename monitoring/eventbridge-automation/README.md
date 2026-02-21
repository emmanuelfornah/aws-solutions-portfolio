# Using Amazon EventBridge for Event-Driven Automation

## Overview

This lab demonstrates event-driven automation using Amazon EventBridge (formerly CloudWatch Events) to respond to AWS service events and scheduled triggers. You'll create EventBridge rules that detect Auto Scaling events, trigger Lambda functions, and execute scheduled tasks using cron expressions. This architecture enables reactive and proactive automation without manual intervention.

## AWS Services Used

- **Amazon EventBridge** - Event bus and rule engine for event-driven automation
- **AWS Lambda** - Serverless functions triggered by events
- **Amazon EC2 Auto Scaling** - Generates scaling events
- **Amazon CloudWatch Logs** - Lambda execution logging
- **AWS IAM** - Lambda execution roles and permissions

## Architecture

The event-driven architecture follows a reactive automation pattern:

1. **Event Sources**: Auto Scaling groups, scheduled cron expressions
2. **EventBridge Rules**: Match event patterns and route to targets
3. **Lambda Functions**: Execute automation logic in response to events
4. **CloudWatch Logs**: Capture Lambda execution details

See [architecture.md](./architecture.md) for detailed architecture diagrams and event flow.

## Objectives

- Create EventBridge rules for AWS service events (Auto Scaling)
- Configure event patterns to filter specific event types
- Trigger Lambda functions from EventBridge rules
- Implement scheduled rules using cron expressions
- Understand cron syntax for complex scheduling (monthly third Monday)
- Integrate EventBridge with CloudWatch Logs for monitoring
- Design event-driven automation workflows

## Key Learnings

- **EventBridge vs CloudWatch Events**: EventBridge is the evolution of CloudWatch Events with additional features (custom event buses, schema registry, third-party integrations). CloudWatch Events is now considered legacy.

- **Event Patterns**: JSON-based filters that match specific events. Example: Match only Auto Scaling launch events, not termination events.

- **Cron Expressions**: EventBridge uses 6-field cron syntax: `cron(minute hour day-of-month month day-of-week year)`. Example: `cron(0 23 ? * 2#3 *)` = Third Monday of every month at 23:00 UTC.

- **Event Targets**: Rules can trigger multiple targets: Lambda, SNS, SQS, Step Functions, ECS tasks, Systems Manager, and more.

- **Event Replay**: EventBridge can archive events and replay them for testing or disaster recovery.

- **Cross-Account Events**: EventBridge supports cross-account event delivery for centralized monitoring.

## Setup Instructions

### Prerequisites

- AWS account with EventBridge, Lambda, and Auto Scaling permissions
- Existing Auto Scaling group (or create one for testing)
- Basic understanding of Lambda and Python

### Step 1: Create Lambda Function for Auto Scaling Events

1. Navigate to **Lambda** > **Functions** > **Create function**
2. Configure function:
   - **Function name**: `LogAutoScalingEvent`
   - **Runtime**: Python 3.13
   - **Architecture**: x86_64
   - **Execution role**: Create new role with basic Lambda permissions
3. Click **Create function**
4. Replace function code with:
   ```python
   import json
   import logging
   
   logger = logging.getLogger()
   logger.setLevel(logging.INFO)
   
   def lambda_handler(event, context):
       logger.info("Auto Scaling Event Received:")
       logger.info(json.dumps(event, indent=2))
       
       detail = event.get('detail', {})
       auto_scaling_group = detail.get('AutoScalingGroupName', 'Unknown')
       cause = detail.get('Cause', 'Unknown')
       
       logger.info(f"Auto Scaling Group: {auto_scaling_group}")
       logger.info(f"Cause: {cause}")
       
       return {
           'statusCode': 200,
           'body': json.dumps('Event logged successfully')
       }
   ```
5. Click **Deploy**

See [application/log-autoscaling-event.py](./application/log-autoscaling-event.py) for complete code.

### Step 2: Create EventBridge Rule for Auto Scaling Events

1. Navigate to **EventBridge** > **Rules** > **Create rule**
2. Configure rule:
   - **Name**: `AutoScalingEventRule`
   - **Description**: `Trigger Lambda on Auto Scaling events`
   - **Event bus**: default
   - **Rule type**: Rule with an event pattern
3. Click **Next**
4. Configure event pattern:
   - **Event source**: AWS events or EventBridge partner events
   - **Event pattern**:
     ```json
     {
       "source": ["aws.autoscaling"],
       "detail-type": ["EC2 Instance Launch Successful", "EC2 Instance Terminate Successful"]
     }
     ```
5. Click **Next**
6. Configure target:
   - **Target types**: AWS service
   - **Select a target**: Lambda function
   - **Function**: `LogAutoScalingEvent`
7. Click **Next** > **Create rule**

### Step 3: Create Lambda Function for Scheduled Reboot

1. Navigate to **Lambda** > **Functions** > **Create function**
2. Configure function:
   - **Function name**: `RebootEC2`
   - **Runtime**: Python 3.13
   - **Execution role**: Create new role
3. Click **Create function**
4. Add EC2 permissions to execution role:
   - Navigate to **Configuration** > **Permissions**
   - Click role name
   - Attach policy: `AmazonEC2FullAccess` (or create custom policy with `ec2:RebootInstances`)
5. Replace function code with:
   ```python
   import boto3
   import os
   
   ec2 = boto3.client('ec2')
   
   def lambda_handler(event, context):
       instance_id = os.environ.get('INSTANCE_ID')
       
       if not instance_id:
           return {
               'statusCode': 400,
               'body': 'INSTANCE_ID environment variable not set'
           }
       
       try:
           response = ec2.reboot_instances(InstanceIds=[instance_id])
           print(f"Rebooted instance: {instance_id}")
           return {
               'statusCode': 200,
               'body': f'Successfully rebooted {instance_id}'
           }
       except Exception as e:
           print(f"Error rebooting instance: {str(e)}")
           return {
               'statusCode': 500,
               'body': f'Error: {str(e)}'
           }
   ```
6. Add environment variable:
   - Navigate to **Configuration** > **Environment variables**
   - Add: `INSTANCE_ID` = `[YOUR-INSTANCE-ID]`
7. Click **Deploy**

See [application/reboot-ec2.py](./application/reboot-ec2.py) for complete code.

### Step 4: Create Scheduled EventBridge Rule (Cron)

1. Navigate to **EventBridge** > **Rules** > **Create rule**
2. Configure rule:
   - **Name**: `MonthlyThirdMondayReboot`
   - **Description**: `Reboot EC2 instance on third Monday of each month at 23:00 UTC`
   - **Event bus**: default
   - **Rule type**: Schedule
3. Click **Next**
4. Configure schedule:
   - **Schedule pattern**: Cron-based schedule
   - **Cron expression**: `cron(0 23 ? * 2#3 *)`
   - **Timezone**: UTC
5. Click **Next**
6. Configure target:
   - **Target types**: AWS service
   - **Select a target**: Lambda function
   - **Function**: `RebootEC2`
7. Click **Next** > **Create rule**

**Cron Expression Breakdown**:
- `0` = Minute (0 = top of the hour)
- `23` = Hour (23:00 = 11 PM UTC)
- `?` = Day of month (? = no specific value, use day-of-week instead)
- `*` = Month (every month)
- `2#3` = Day of week (2 = Monday, #3 = third occurrence)
- `*` = Year (every year)

See [configs/cron-expressions.txt](./configs/cron-expressions.txt) for more examples.

### Step 5: Test Auto Scaling Event Rule

1. Navigate to **EC2** > **Auto Scaling Groups**
2. Select your Auto Scaling group
3. Click **Edit** > Increase **Desired capacity** by 1
4. Click **Update**
5. Wait for instance to launch (2-3 minutes)
6. Navigate to **Lambda** > **Functions** > `LogAutoScalingEvent`
7. Click **Monitor** > **View CloudWatch logs**
8. Verify event was logged

### Step 6: Test Scheduled Rule (Manual Trigger)

Since the cron runs monthly, test manually:

1. Navigate to **EventBridge** > **Rules**
2. Select `MonthlyThirdMondayReboot`
3. Click **Actions** > **Test rule**
4. Click **Test**
5. Navigate to **Lambda** > **Functions** > `RebootEC2`
6. Check CloudWatch logs for execution
7. Verify EC2 instance was rebooted (check instance uptime)

## Testing and Validation

### Test Scenario 1: Auto Scaling Launch Event

**Action**: Increase Auto Scaling group desired capacity

**Expected Results**:
- Auto Scaling launches new EC2 instance
- EventBridge rule matches "EC2 Instance Launch Successful" event
- Lambda function `LogAutoScalingEvent` is triggered
- CloudWatch Logs shows event details

### Test Scenario 2: Auto Scaling Termination Event

**Action**: Decrease Auto Scaling group desired capacity

**Expected Results**:
- Auto Scaling terminates EC2 instance
- EventBridge rule matches "EC2 Instance Terminate Successful" event
- Lambda function logs termination event

### Test Scenario 3: Scheduled Reboot

**Action**: Manually trigger scheduled rule or wait for cron execution

**Expected Results**:
- EventBridge triggers Lambda at scheduled time
- Lambda function reboots specified EC2 instance
- CloudWatch Logs shows successful reboot

## Cron Expression Examples

See [configs/cron-expressions.txt](./configs/cron-expressions.txt) for comprehensive examples:

- **Every 5 minutes**: `cron(0/5 * * * ? *)`
- **Every day at 2 AM**: `cron(0 2 * * ? *)`
- **Every Monday at 9 AM**: `cron(0 9 ? * 2 *)`
- **First day of month at midnight**: `cron(0 0 1 * ? *)`
- **Last day of month**: `cron(0 0 L * ? *)` (L = last)
- **Weekdays only at 8 AM**: `cron(0 8 ? * 2-6 *)` (Mon-Fri)
- **Third Monday at 11 PM**: `cron(0 23 ? * 2#3 *)` (lab example)

## Cleanup

1. Delete EventBridge rules: `AutoScalingEventRule`, `MonthlyThirdMondayReboot`
2. Delete Lambda functions: `LogAutoScalingEvent`, `RebootEC2`
3. Delete Lambda execution roles
4. Delete CloudWatch log groups: `/aws/lambda/LogAutoScalingEvent`, `/aws/lambda/RebootEC2`

## Real-World Applications

- **Auto Scaling Notifications**: Alert teams when instances scale out/in
- **Automated Remediation**: Restart unhealthy instances, fix security group misconfigurations
- **Scheduled Maintenance**: Reboot instances, run backups, rotate credentials
- **Cost Optimization**: Stop dev/test instances after hours, start before business hours
- **Compliance Automation**: Respond to Config rule violations, enforce tagging policies
- **Cross-Service Orchestration**: Trigger Step Functions workflows, update DynamoDB, send SNS notifications

## Interview Talking Points

- **Explain EventBridge vs CloudWatch Events**: EventBridge is the evolution with custom event buses, schema registry, and SaaS integrations
- **Describe event pattern matching**: JSON-based filters with source, detail-type, and detail fields
- **Discuss cron expression syntax**: 6-field format with special characters (?, #, L, W)
- **Compare event-driven vs polling**: EventBridge provides real-time reactions without constant polling overhead

## Complexity Level

**Intermediate** - Requires understanding of Lambda, EventBridge, Auto Scaling, and cron expressions.

## Estimated Time

**40 minutes** - Including Lambda creation, EventBridge rule configuration, and testing.

## AWS Certification Alignment

- **AWS Certified Solutions Architect Associate**: Event-driven architectures, Lambda integration, Auto Scaling
- **AWS Certified Developer Associate**: EventBridge patterns, Lambda development, serverless automation
- **AWS Certified SysOps Administrator Associate**: Operational automation, scheduled tasks, event monitoring

## Completion Date

2024-01-15
