# Monitoring Applications and Infrastructure with CloudWatch

## Overview

This project demonstrates end-to-end monitoring using Amazon CloudWatch, including CloudWatch agent installation via Systems Manager, custom metric collection, dashboard creation, alarm configuration, and automated testing with Lambda. It covers monitoring both infrastructure metrics (CPU, memory, disk) and application metrics using a unified monitoring platform.

## AWS Services Used

- **Amazon CloudWatch** - Unified monitoring and observability
- **CloudWatch Agent** - Custom metric collection (memory, disk, logs)
- **AWS Systems Manager** - Agent deployment and configuration management
- **Parameter Store** - CloudWatch agent configuration storage
- **Amazon SNS** - Alarm notifications
- **AWS Lambda** - Automated alarm testing (Canary function)
- **AWS CLI** - Command-line alarm testing

## Architecture

The comprehensive monitoring architecture includes:

1. **CloudWatch Agent**: Installed on EC2 instances via Systems Manager
2. **Parameter Store**: Stores agent configuration
3. **CloudWatch Metrics**: Collects standard and custom metrics
4. **CloudWatch Alarms**: Monitors thresholds and triggers notifications
5. **SNS Topics**: Delivers alarm notifications
6. **CloudWatch Dashboards**: Visualizes metrics
7. **Lambda Canary**: Automated alarm testing

See [architecture.md](./architecture.md) for detailed architecture diagrams.

## Objectives

- Install CloudWatch agent using Systems Manager
- Configure agent via Parameter Store
- Collect custom metrics (memory, disk usage, application logs)
- Create CloudWatch dashboards for visualization
- Configure CloudWatch alarms with SNS notifications
- Test alarms using AWS CLI
- Implement Lambda Canary function for automated testing
- Understand unified CloudWatch agent vs legacy monitoring scripts

## Technical Highlights

- **Unified CloudWatch Agent**: Replaces legacy monitoring scripts. Collects metrics and logs in single agent. Supports EC2 and on-premises servers.

- **Systems Manager Integration**: Agent installation via Run Command eliminates manual SSH. Configuration via Parameter Store enables centralized management.

- **Custom Metrics**: CloudWatch agent collects OS-level metrics not available by default (memory utilization, disk usage, swap usage).

- **Metric Namespaces**: Organize metrics logically (e.g., `CWAgent`, `Application/WebServer`). Custom namespaces separate from AWS service metrics.

- **Dashboard Best Practices**: Group related metrics, use consistent time ranges, include alarm status widgets, add text widgets for documentation.

- **Alarm Testing**: Use AWS CLI `set-alarm-state` for testing without waiting for actual threshold breaches.

- **Lambda Canary**: Automated testing function that periodically validates alarm configuration and notification delivery.

## Setup Instructions

### Prerequisites

- AWS account with EC2, CloudWatch, Systems Manager, and Lambda permissions
- EC2 instance with Systems Manager agent (pre-installed on Amazon Linux 2/2023)
- IAM instance profile with `CloudWatchAgentServerPolicy` and `AmazonSSMManagedInstanceCore`
- Valid email address for SNS notifications

### Step 1: Verify Systems Manager Connectivity

1. Navigate to **Systems Manager** > **Fleet Manager**
2. Verify your EC2 instance appears in the list
3. If not visible:
   - Check instance has IAM role with `AmazonSSMManagedInstanceCore` policy
   - Verify instance has internet connectivity (or VPC endpoints for Systems Manager)
   - Wait 5-10 minutes for initial registration

### Step 2: Create CloudWatch Agent Configuration

1. Create configuration file `cloudwatch-agent-config.json`:
   ```json
   {
     "agent": {
       "metrics_collection_interval": 60,
       "run_as_user": "root"
     },
     "metrics": {
       "namespace": "CWAgent",
       "metrics_collected": {
         "cpu": {
           "measurement": [
             {"name": "cpu_usage_idle", "rename": "CPU_IDLE", "unit": "Percent"},
             {"name": "cpu_usage_iowait", "rename": "CPU_IOWAIT", "unit": "Percent"},
             "cpu_time_guest"
           ],
           "metrics_collection_interval": 60,
           "totalcpu": false
         },
         "disk": {
           "measurement": [
             {"name": "used_percent", "rename": "DISK_USED", "unit": "Percent"}
           ],
           "metrics_collection_interval": 60,
           "resources": ["*"]
         },
         "diskio": {
           "measurement": [
             "io_time"
           ],
           "metrics_collection_interval": 60,
           "resources": ["*"]
         },
         "mem": {
           "measurement": [
             {"name": "mem_used_percent", "rename": "MEM_USED", "unit": "Percent"}
           ],
           "metrics_collection_interval": 60
         },
         "swap": {
           "measurement": [
             {"name": "swap_used_percent", "rename": "SWAP_USED", "unit": "Percent"}
           ],
           "metrics_collection_interval": 60
         }
       }
     }
   }
   ```

See [configs/cloudwatch-agent-config.json](./configs/cloudwatch-agent-config.json) for complete configuration.

### Step 3: Store Configuration in Parameter Store

1. Navigate to **Systems Manager** > **Parameter Store**
2. Click **Create parameter**
3. Configure parameter:
   - **Name**: `/cloudwatch-agent/config`
   - **Description**: `CloudWatch agent configuration for EC2 monitoring`
   - **Tier**: Standard
   - **Type**: String
   - **Value**: Paste JSON configuration from Step 2
4. Click **Create parameter**

**Alternative: AWS CLI**:
```bash
aws ssm put-parameter \
  --name "/cloudwatch-agent/config" \
  --type "String" \
  --value file://cloudwatch-agent-config.json \
  --description "CloudWatch agent configuration"
```

### Step 4: Install CloudWatch Agent via Systems Manager

1. Navigate to **Systems Manager** > **Run Command**
2. Click **Run command**
3. Search for and select: `AWS-ConfigureAWSPackage`
4. Configure command:
   - **Action**: Install
   - **Name**: `AmazonCloudWatchAgent`
   - **Version**: Leave empty (latest)
5. **Targets**: Select your EC2 instance(s)
6. Click **Run**
7. Wait for command to complete (Status: Success)

### Step 5: Configure and Start CloudWatch Agent

1. Navigate to **Systems Manager** > **Run Command**
2. Click **Run command**
3. Search for and select: `AmazonCloudWatch-ManageAgent`
4. Configure command:
   - **Action**: configure
   - **Mode**: ec2
   - **Optional Configuration Source**: ssm
   - **Optional Configuration Location**: `/cloudwatch-agent/config`
   - **Optional Restart**: yes
5. **Targets**: Select your EC2 instance(s)
6. Click **Run**
7. Wait for command to complete (Status: Success)

### Step 6: Verify Metrics in CloudWatch

1. Navigate to **CloudWatch** > **Metrics** > **All metrics**
2. Select **CWAgent** namespace
3. Browse metrics:
   - **CPU_IDLE**, **CPU_IOWAIT**
   - **DISK_USED**
   - **MEM_USED**
   - **SWAP_USED**
4. Select metrics and view graph
5. Wait 2-3 minutes for initial data points

### Step 7: Create SNS Topic for Notifications

1. Navigate to **Amazon SNS** > **Topics**
2. Click **Create topic**
3. Configure topic:
   - **Type**: Standard
   - **Name**: `InfrastructureAlerts`
4. Click **Create topic**
5. Create email subscription (confirm via email)

### Step 8: Create CloudWatch Alarms

**Alarm 1: High Memory Utilization**

1. Navigate to **CloudWatch** > **Alarms** > **Create alarm**
2. Select metric: `CWAgent > InstanceId > MEM_USED`
3. Configure:
   - **Statistic**: Average
   - **Period**: 5 minutes
   - **Threshold**: Greater than 80
   - **Datapoints**: 2 out of 3
4. Configure action: SNS topic `InfrastructureAlerts`
5. Alarm name: `HighMemoryUtilization-[INSTANCE-ID]`

**Alarm 2: High Disk Usage**

1. Create alarm on `CWAgent > InstanceId, device, fstype, path > DISK_USED`
2. Configure:
   - **Threshold**: Greater than 85
   - **Period**: 5 minutes
3. Configure action: SNS topic `InfrastructureAlerts`
4. Alarm name: `HighDiskUsage-[INSTANCE-ID]`

See [configs/alarm-definitions.json](./configs/alarm-definitions.json) for all alarm configurations.

### Step 9: Test Alarms with AWS CLI

Test alarm without waiting for actual threshold breach:

```bash
# Set alarm to ALARM state
aws cloudwatch set-alarm-state \
  --alarm-name "HighMemoryUtilization-[INSTANCE-ID]" \
  --state-value ALARM \
  --state-reason "Testing alarm notification"

# Check email for notification

# Reset alarm to OK state
aws cloudwatch set-alarm-state \
  --alarm-name "HighMemoryUtilization-[INSTANCE-ID]" \
  --state-value OK \
  --state-reason "Test complete"
```

See [scripts/test-alarms.sh](./scripts/test-alarms.sh) for automated testing script.

### Step 10: Create CloudWatch Dashboard

1. Navigate to **CloudWatch** > **Dashboards** > **Create dashboard**
2. Dashboard name: `InfrastructureMonitoring`
3. Add widgets:
   - **Line graph**: CPU metrics (CPU_IDLE, CPU_IOWAIT)
   - **Line graph**: Memory utilization (MEM_USED)
   - **Line graph**: Disk usage (DISK_USED)
   - **Number widget**: Current memory usage
   - **Alarm status widget**: All alarms
4. Click **Save dashboard**

See [configs/dashboard-definition.json](./configs/dashboard-definition.json) for complete dashboard JSON.

### Step 11: Create Lambda Canary Function

Create automated testing function that validates alarm configuration:

1. Navigate to **Lambda** > **Create function**
2. Function name: `AlarmCanary`
3. Runtime: Python 3.13
4. Create function
5. Add CloudWatch permissions to execution role
6. Replace code with:
   ```python
   import boto3
   import os
   
   cloudwatch = boto3.client('cloudwatch')
   
   def lambda_handler(event, context):
       alarm_name = os.environ['ALARM_NAME']
       
       # Describe alarm to verify it exists
       response = cloudwatch.describe_alarms(AlarmNames=[alarm_name])
       
       if not response['MetricAlarms']:
           print(f"ERROR: Alarm {alarm_name} not found")
           return {'statusCode': 404, 'body': 'Alarm not found'}
       
       alarm = response['MetricAlarms'][0]
       print(f"Alarm {alarm_name} exists")
       print(f"Current state: {alarm['StateValue']}")
       
       # Test alarm by setting to ALARM state
       cloudwatch.set_alarm_state(
           AlarmName=alarm_name,
           StateValue='ALARM',
           StateReason='Canary test - automated alarm validation'
       )
       
       print(f"Set alarm to ALARM state for testing")
       
       return {
           'statusCode': 200,
           'body': f'Canary test completed for {alarm_name}'
       }
   ```
7. Add environment variable: `ALARM_NAME` = `HighMemoryUtilization-[INSTANCE-ID]`
8. Create EventBridge rule to run Lambda daily

See [application/alarm-canary.py](./application/alarm-canary.py) for complete code.

## Testing and Validation

### Test Scenario 1: Memory Stress Test

Trigger high memory alarm:

```bash
# SSH to EC2 instance
ssh -i key.pem ec2-user@[INSTANCE-IP]

# Install stress tool
sudo dnf install -y stress-ng

# Stress memory (allocate 80% of available RAM)
stress-ng --vm 1 --vm-bytes 80% --timeout 300s
```

Expected: Memory alarm triggers after 2 evaluation periods.

### Test Scenario 2: Disk Fill Test

Trigger high disk alarm:

```bash
# Create large file to fill disk
dd if=/dev/zero of=/tmp/largefile bs=1M count=10000

# Check disk usage
df -h

# Clean up
rm /tmp/largefile
```

Expected: Disk alarm triggers when usage exceeds 85%.

## Cleanup

1. Stop CloudWatch agent: Run Command → `AmazonCloudWatch-ManageAgent` (action: stop)
2. Delete CloudWatch alarms
3. Delete CloudWatch dashboard
4. Delete SNS topic
5. Delete Lambda function
6. Delete Parameter Store parameter
7. Delete CloudWatch log groups

## Real-World Applications

- **Infrastructure Monitoring**: Comprehensive visibility into EC2 fleet health
- **Application Performance**: Custom metrics for application-specific KPIs
- **Proactive Alerting**: Detect issues before users are impacted
- **Capacity Planning**: Historical metrics inform scaling decisions
- **Compliance**: Centralized logging and monitoring for audit requirements

## Interview Talking Points

- **Explain CloudWatch agent benefits**: Unified agent for metrics and logs, supports custom metrics, centralized configuration
- **Describe Systems Manager integration**: Agentless deployment, Parameter Store configuration, fleet-wide management
- **Discuss alarm testing strategies**: CLI testing, Lambda canaries, synthetic monitoring
- **Compare standard vs custom metrics**: Standard metrics (CPU, network) vs custom (memory, disk, application)

## Complexity Level

**Intermediate to Advanced** - Requires understanding of CloudWatch, Systems Manager, Lambda, and monitoring best practices.

## Estimated Time

**60 minutes** - Including agent installation, configuration, alarm setup, dashboard creation, and testing.

