# Security Monitoring with Amazon CloudWatch Alarms

## Overview

This project demonstrates operational monitoring and alerting using Amazon CloudWatch Alarms to track EC2 instance performance. You'll create CloudWatch alarms for CPU utilization, configure SNS email notifications, stress test EC2 instances to trigger alarms, and build CloudWatch dashboards for visualization. This hands-on experience teaches proactive monitoring strategies essential for maintaining application availability and performance.

## AWS Services Used

- **Amazon CloudWatch** - Metrics collection and alarm management
- **Amazon CloudWatch Alarms** - Automated alerting based on metric thresholds
- **Amazon SNS** - Email notification delivery
- **Amazon EC2** - Compute instances for monitoring
- **CloudWatch Dashboards** - Metric visualization and operational insights

## Architecture

The monitoring architecture follows a proactive alerting pattern:

1. **EC2 Instances**: Generate CloudWatch metrics (CPU, network, disk)
2. **CloudWatch Metrics**: Automatically collected every 5 minutes (standard) or 1 minute (detailed)
3. **CloudWatch Alarms**: Evaluate metrics against thresholds
4. **SNS Topic**: Delivers notifications when alarms trigger
5. **CloudWatch Dashboard**: Visualizes metrics and alarm states

See [architecture.md](./architecture.md) for detailed architecture diagrams and metric flow.

## Objectives

- Understand CloudWatch metrics and their collection intervals
- Create CloudWatch alarms with threshold-based conditions
- Configure SNS topics and email subscriptions for notifications
- Stress test EC2 instances to simulate high CPU utilization
- Analyze alarm state transitions (OK, ALARM, INSUFFICIENT_DATA)
- Build CloudWatch dashboards for operational visibility
- Implement best practices for alarm threshold selection

## Key Learnings

- **CloudWatch Metrics**: EC2 instances automatically send metrics to CloudWatch every 5 minutes (basic monitoring) or 1 minute (detailed monitoring). No agent required for basic metrics like CPU, network, and disk I/O.

- **Alarm States**: Alarms have three states:
  - **OK**: Metric is within acceptable range
  - **ALARM**: Metric has breached threshold
  - **INSUFFICIENT_DATA**: Not enough data to evaluate (new alarm or missing metrics)

- **Evaluation Periods**: Alarms evaluate metrics over multiple periods to reduce false positives. Example: "3 out of 3 datapoints" means the threshold must be breached for 3 consecutive periods.

- **Alarm Actions**: Alarms can trigger multiple actions: SNS notifications, Auto Scaling policies, EC2 actions (stop, terminate, reboot), Systems Manager actions.

- **Threshold Selection**: Set thresholds based on application baselines. Too sensitive = alert fatigue, too lenient = missed incidents. Start conservative and tune based on operational experience.

- **Detailed Monitoring**: Costs $0.14 per instance per month but provides 1-minute granularity instead of 5-minute. Essential for applications requiring rapid response to performance issues.

- **Composite Alarms**: Combine multiple alarms using AND/OR logic for complex alerting scenarios (e.g., high CPU AND high memory).

## Setup Instructions

### Prerequisites

- AWS account with EC2 and CloudWatch permissions
- Running EC2 instance (Amazon Linux 2 or Amazon Linux 2023)
- SSH access to EC2 instance
- Valid email address for SNS notifications

### Step 1: Launch EC2 Instance (if needed)

1. Navigate to **EC2** > **Instances** > **Launch Instance**
2. Configure instance:
   - **Name**: `MonitoringTestInstance`
   - **AMI**: Amazon Linux 2023
   - **Instance type**: t2.micro (free tier eligible)
   - **Key pair**: Select existing or create new
   - **Network**: Default VPC
   - **Security group**: Allow SSH (port 22) from your IP
   - **Monitoring**: Enable detailed monitoring (1-minute intervals)
3. Click **Launch instance**
4. Wait for instance to reach **Running** state

### Step 2: Create SNS Topic for Notifications

1. Navigate to **Amazon SNS** > **Topics**
2. Click **Create topic**
3. Configure topic:
   - **Type**: Standard
   - **Name**: `EC2PerformanceAlerts`
   - **Display name**: `EC2 Performance Alerts`
4. Click **Create topic**
5. Click **Create subscription**:
   - **Protocol**: Email
   - **Endpoint**: Your email address
6. Click **Create subscription**
7. Check email and click **Confirm subscription**

### Step 3: Create CloudWatch Alarm for High CPU

1. Navigate to **CloudWatch** > **Alarms** > **All alarms**
2. Click **Create alarm**
3. Click **Select metric**
4. Choose **EC2** > **Per-Instance Metrics**
5. Search for your instance ID
6. Select **CPUUtilization** metric
7. Click **Select metric**
8. Configure alarm conditions:
   - **Statistic**: Average
   - **Period**: 1 minute (if detailed monitoring enabled) or 5 minutes
   - **Threshold type**: Static
   - **Whenever CPUUtilization is**: Greater than `70`
   - **Datapoints to alarm**: 2 out of 3 (requires 2 consecutive breaches)
9. Click **Next**
10. Configure actions:
    - **Alarm state trigger**: In alarm
    - **Select an SNS topic**: `EC2PerformanceAlerts`
11. Click **Next**
12. Configure alarm name:
    - **Alarm name**: `HighCPUUtilization-[INSTANCE-ID]`
    - **Alarm description**: `Alert when CPU exceeds 70% for 2 minutes`
13. Click **Next** > **Create alarm**

### Step 4: Stress Test EC2 Instance

1. SSH into your EC2 instance:
   ```bash
   ssh -i your-key.pem ec2-user@[INSTANCE-PUBLIC-IP]
   ```

2. Install stress testing tool:
   ```bash
   # Amazon Linux 2023
   sudo dnf install -y stress-ng
   
   # Amazon Linux 2
   sudo yum install -y stress
   ```

3. Run CPU stress test:
   ```bash
   # Stress all CPU cores for 5 minutes
   stress-ng --cpu 0 --timeout 300s --metrics-brief
   
   # Alternative: stress command
   stress --cpu 4 --timeout 300
   ```

4. Monitor CPU in real-time (separate terminal):
   ```bash
   top
   # Press '1' to see per-CPU utilization
   # Press 'q' to quit
   ```

See [scripts/stress-test.sh](./scripts/stress-test.sh) for automated stress testing.

### Step 5: Verify Alarm Triggered

1. Navigate to **CloudWatch** > **Alarms**
2. Watch alarm state transition:
   - **INSUFFICIENT_DATA** → **OK** → **ALARM** (after 2 minutes of high CPU)
3. Check email for SNS notification
4. View alarm history:
   - Click alarm name
   - Select **History** tab
   - Review state change events

### Step 6: Create CloudWatch Dashboard

1. Navigate to **CloudWatch** > **Dashboards**
2. Click **Create dashboard**
3. Enter dashboard name: `EC2PerformanceMonitoring`
4. Click **Create dashboard**
5. Add widget:
   - Click **Add widget**
   - Select **Line** graph
   - Click **Next**
6. Configure widget:
   - Select **Metrics** tab
   - Choose **EC2** > **Per-Instance Metrics**
   - Select **CPUUtilization** for your instance
   - Click **Create widget**
7. Add alarm status widget:
   - Click **Add widget**
   - Select **Alarm status**
   - Select your CPU alarm
   - Click **Create widget**
8. Click **Save dashboard**

See [configs/dashboard-template.json](./configs/dashboard-template.json) for complete dashboard configuration.

### Step 7: Test Alarm Recovery

1. Stop the stress test (Ctrl+C in SSH session)
2. Wait 2-3 minutes for CPU to normalize
3. Navigate to **CloudWatch** > **Alarms**
4. Watch alarm transition from **ALARM** → **OK**
5. Check email for recovery notification (if configured)

## Additional Monitoring Scenarios

### Scenario 1: Network Monitoring

Create alarm for high network traffic:

1. Create alarm on **NetworkIn** or **NetworkOut** metric
2. Set threshold: Greater than 1,000,000 bytes (1 MB)
3. Period: 5 minutes
4. Datapoints: 3 out of 3

### Scenario 2: Disk I/O Monitoring

Create alarm for disk read/write operations:

1. Create alarm on **DiskReadOps** or **DiskWriteOps** metric
2. Set threshold: Greater than 1000 operations
3. Period: 5 minutes
4. Datapoints: 2 out of 3

### Scenario 3: Status Check Monitoring

Create alarm for instance health:

1. Create alarm on **StatusCheckFailed** metric
2. Set threshold: Greater than 0
3. Period: 1 minute
4. Action: Send SNS notification + Reboot instance

See [configs/alarm-templates.json](./configs/alarm-templates.json) for additional alarm configurations.

## Testing and Validation

### Test Scenario 1: High CPU Alert

**Action**: Run stress test to push CPU to 100%

**Expected Results**:
- CloudWatch receives CPU metrics showing 90-100% utilization
- Alarm evaluates metric every period (1 or 5 minutes)
- After 2 consecutive breaches, alarm transitions to ALARM state
- SNS sends email notification within 1-2 minutes

### Test Scenario 2: Alarm Recovery

**Action**: Stop stress test and let CPU return to normal

**Expected Results**:
- CPU utilization drops below 70%
- After 2 consecutive periods below threshold, alarm returns to OK state
- SNS sends recovery notification (if configured)

### Test Scenario 3: Dashboard Visualization

**Action**: View dashboard during stress test

**Expected Results**:
- Line graph shows CPU spike in real-time
- Alarm status widget shows red (ALARM) state
- Dashboard auto-refreshes every 1 minute

## Troubleshooting

### Issue: Alarm Not Triggering

**Possible Causes**:
- Threshold too high (CPU not reaching 70%)
- Insufficient datapoints (only 1 out of 3 periods breached)
- Detailed monitoring not enabled (5-minute delay)

**Solutions**:
- Lower threshold to 50% for testing
- Reduce datapoints to 1 out of 1
- Enable detailed monitoring for 1-minute granularity

### Issue: No Email Notifications

**Possible Causes**:
- SNS subscription not confirmed
- Email in spam folder
- Wrong email address

**Solutions**:
- Check SNS subscription status (should be "Confirmed")
- Search spam/junk folders
- Verify email address in subscription

### Issue: Stress Test Not Increasing CPU

**Possible Causes**:
- Stress tool not installed correctly
- Insufficient CPU cores specified
- Instance too powerful (CPU not reaching threshold)

**Solutions**:
- Verify stress-ng installation: `stress-ng --version`
- Use `--cpu 0` to stress all cores
- Use smaller instance type (t2.micro) for easier testing

## Cleanup

To avoid ongoing charges:

1. Delete CloudWatch alarm: `HighCPUUtilization-[INSTANCE-ID]`
2. Delete CloudWatch dashboard: `EC2PerformanceMonitoring`
3. Delete SNS topic: `EC2PerformanceAlerts`
4. Stop or terminate EC2 instance (if created for lab)

## Real-World Applications

- **Application Performance Monitoring**: Alert on high CPU/memory before users experience slowdowns
- **Auto Scaling Triggers**: Use alarms to trigger EC2 Auto Scaling scale-out/scale-in actions
- **Cost Optimization**: Detect idle instances (low CPU) for rightsizing or termination
- **Incident Response**: Automated notifications enable rapid response to performance degradation
- **Capacity Planning**: Historical metric data informs infrastructure scaling decisions

## Interview Talking Points

- **Explain alarm evaluation logic**: Describe how datapoints, periods, and thresholds work together to reduce false positives
- **Discuss threshold selection**: Balance between sensitivity (catching issues early) and specificity (avoiding alert fatigue)
- **Describe alarm actions**: SNS notifications, Auto Scaling policies, EC2 actions (stop/terminate/reboot), Systems Manager automation
- **Compare basic vs detailed monitoring**: 5-minute vs 1-minute granularity, cost implications, use cases for each

## Complexity Level

**Beginner to Intermediate** - Requires basic understanding of EC2, CloudWatch metrics, and alarm configuration.

## Estimated Time

**45 minutes** - Including EC2 setup, alarm creation, stress testing, and dashboard configuration.

