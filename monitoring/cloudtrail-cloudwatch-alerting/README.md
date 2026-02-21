# Monitoring and Alerting with AWS CloudTrail and Amazon CloudWatch

## Overview

This lab demonstrates comprehensive security monitoring and alerting using AWS CloudTrail and Amazon CloudWatch. You'll create a CloudTrail trail to capture API activity, stream logs to CloudWatch Logs, configure metric filters to detect failed login attempts, and set up SNS notifications for security events. This architecture provides real-time visibility into AWS account activity and automated alerting for suspicious behavior.

## AWS Services Used

- **AWS CloudTrail** - API activity logging and audit trail
- **Amazon CloudWatch Logs** - Centralized log aggregation and analysis
- **Amazon CloudWatch Alarms** - Automated alerting based on metric thresholds
- **Amazon SNS** - Email notifications for security events
- **CloudWatch Logs Insights** - Advanced log querying and analysis
- **AWS IAM** - User authentication and failed login simulation

## Architecture

The monitoring and alerting architecture follows a security-focused pattern:

1. **CloudTrail Trail**: Captures all API calls across AWS services
2. **CloudWatch Logs Integration**: Streams CloudTrail events to log groups
3. **Metric Filters**: Extracts failed login attempts from log data
4. **CloudWatch Alarms**: Triggers when failed login threshold is exceeded
5. **SNS Topic**: Delivers email notifications to security team
6. **Logs Insights**: Enables ad-hoc querying for security investigations

See [architecture.md](./architecture.md) for detailed architecture diagrams and data flow.

## Objectives

- Create and configure CloudTrail trails for API activity logging
- Integrate CloudTrail with CloudWatch Logs for centralized monitoring
- Design metric filters to detect security events (failed logins)
- Configure CloudWatch alarms with SNS email notifications
- Simulate security events to test alerting mechanisms
- Use CloudWatch Logs Insights for security investigations
- Understand the difference between CloudTrail and CloudWatch

## Key Learnings

- **CloudTrail vs CloudWatch**: CloudTrail records WHO did WHAT and WHEN (API audit trail), while CloudWatch monitors HOW resources are performing (metrics, logs, alarms). They complement each other for comprehensive monitoring.

- **Metric Filters**: Transform log data into CloudWatch metrics. They use filter patterns to match specific log events (like failed logins) and increment metric values, enabling alarms on log-based events.

- **Security Event Detection**: Failed console login attempts generate CloudTrail events with `eventName: ConsoleLogin` and `errorMessage: "Failed authentication"`. Metric filters detect these patterns in real-time.

- **SNS Topic Subscriptions**: Email subscriptions require confirmation. Check spam folders and confirm subscription before alarms can deliver notifications.

- **CloudWatch Logs Insights**: Provides SQL-like query language for log analysis. More powerful than basic log filtering, enabling aggregations, statistics, and complex pattern matching.

- **Trail Configuration**: Trails can be single-region or multi-region. Multi-region trails capture activity across all regions, essential for comprehensive security monitoring.

- **Log Retention**: CloudWatch Logs retention can be configured from 1 day to 10 years. Balance cost with compliance requirements. CloudTrail stores logs in S3 indefinitely by default.

## Setup Instructions

### Prerequisites

- AWS account with CloudTrail, CloudWatch, and SNS permissions
- Valid email address for SNS notifications
- IAM user credentials for failed login simulation
- AWS Console access

### Step 1: Create CloudTrail Trail

1. Navigate to **CloudTrail** in AWS Console
2. Click **Create trail**
3. Configure trail settings:
   - **Trail name**: `SecurityMonitoringTrail`
   - **Storage location**: Create new S3 bucket (auto-generated name)
   - **Log file SSE-KMS encryption**: Disabled (for simplicity)
   - **Log file validation**: Enabled
   - **SNS notification delivery**: Disabled
   - **CloudWatch Logs**: Enabled
     - **Log group**: `CloudTrail/SecurityLogs`
     - **IAM Role**: Create new role (auto-generated)
4. Choose **Management events** (read and write)
5. Click **Create trail**

### Step 2: Verify CloudWatch Logs Integration

1. Navigate to **CloudWatch** > **Logs** > **Log groups**
2. Find log group: `CloudTrail/SecurityLogs`
3. Wait 5-10 minutes for initial log streams to appear
4. Click on a log stream to view CloudTrail events

### Step 3: Create SNS Topic for Notifications

1. Navigate to **Amazon SNS** > **Topics**
2. Click **Create topic**
3. Configure topic:
   - **Type**: Standard
   - **Name**: `SecurityAlerts`
   - **Display name**: `Security Alerts`
4. Click **Create topic**
5. Click **Create subscription**:
   - **Protocol**: Email
   - **Endpoint**: Your email address
6. Click **Create subscription**
7. Check email and click **Confirm subscription**

### Step 4: Create Metric Filter for Failed Logins

1. Navigate to **CloudWatch** > **Logs** > **Log groups**
2. Select `CloudTrail/SecurityLogs` log group
3. Click **Actions** > **Create metric filter**
4. Configure filter pattern:
   ```
   { ($.eventName = ConsoleLogin) && ($.errorMessage = "Failed authentication") }
   ```
5. Click **Test pattern** to validate (may show no results if no failed logins yet)
6. Click **Next**
7. Configure metric:
   - **Filter name**: `FailedConsoleLogins`
   - **Metric namespace**: `Security/Authentication`
   - **Metric name**: `FailedLoginAttempts`
   - **Metric value**: `1`
   - **Default value**: Leave empty
8. Click **Next** > **Create metric filter**

### Step 5: Create CloudWatch Alarm

1. From the metric filter page, click **Create alarm**
2. Configure alarm:
   - **Metric**: `Security/Authentication > FailedLoginAttempts`
   - **Statistic**: Sum
   - **Period**: 5 minutes
   - **Threshold type**: Static
   - **Whenever FailedLoginAttempts is**: Greater than `2`
3. Click **Next**
4. Configure actions:
   - **Alarm state trigger**: In alarm
   - **Select an SNS topic**: `SecurityAlerts`
5. Click **Next**
6. Configure alarm name:
   - **Alarm name**: `FailedLoginAlarm`
   - **Alarm description**: `Alert when 3+ failed login attempts in 5 minutes`
7. Click **Next** > **Create alarm**

### Step 6: Simulate Failed Login Attempts

1. Open an **incognito/private browser window**
2. Navigate to AWS Console login page
3. Enter a valid IAM username but **incorrect password**
4. Attempt login 3 times (will fail each time)
5. Wait 5-10 minutes for CloudTrail to process events

### Step 7: Verify Alarm Triggered

1. Navigate to **CloudWatch** > **Alarms**
2. Check `FailedLoginAlarm` status (should change to **In alarm**)
3. Check email for notification from SNS
4. View alarm history for trigger details

### Step 8: Query Logs with CloudWatch Logs Insights

1. Navigate to **CloudWatch** > **Logs Insights**
2. Select log group: `CloudTrail/SecurityLogs`
3. Run query to find failed logins:
   ```
   fields @timestamp, userIdentity.userName, sourceIPAddress, errorMessage
   | filter eventName = "ConsoleLogin" and errorMessage = "Failed authentication"
   | sort @timestamp desc
   | limit 20
   ```
4. Analyze results for security investigation

See [scripts/logs-insights-queries.txt](./scripts/logs-insights-queries.txt) for additional query examples.

## Testing and Validation

### Test Scenario 1: Failed Login Detection

**Action**: Attempt 3 failed console logins within 5 minutes

**Expected Results**:
- CloudTrail captures `ConsoleLogin` events with error messages
- Metric filter increments `FailedLoginAttempts` metric
- CloudWatch alarm transitions to **In alarm** state
- SNS sends email notification

### Test Scenario 2: Successful Login (No Alert)

**Action**: Successfully log in to AWS Console

**Expected Results**:
- CloudTrail captures successful `ConsoleLogin` event
- Metric filter does NOT increment (no error message)
- Alarm remains in **OK** state
- No email notification sent

### Test Scenario 3: Logs Insights Query

**Action**: Run Logs Insights query for all console logins

**Expected Results**:
- Query returns both successful and failed login attempts
- Results include timestamp, username, source IP, and status
- Data can be exported to CSV for further analysis

## Monitoring Dashboards

Create a CloudWatch dashboard to visualize security metrics:

1. Navigate to **CloudWatch** > **Dashboards**
2. Click **Create dashboard**: `SecurityMonitoring`
3. Add widgets:
   - **Line graph**: Failed login attempts over time
   - **Number widget**: Total failed logins (last 24 hours)
   - **Log widget**: Recent failed login events from Logs Insights

See [configs/dashboard-config.json](./configs/dashboard-config.json) for dashboard JSON template.

## Cleanup

To avoid ongoing charges:

1. Delete CloudWatch alarm: `FailedLoginAlarm`
2. Delete metric filter: `FailedConsoleLogins`
3. Delete SNS topic: `SecurityAlerts`
4. Delete CloudTrail trail: `SecurityMonitoringTrail`
5. Delete S3 bucket created by CloudTrail (empty bucket first)
6. Delete CloudWatch log group: `CloudTrail/SecurityLogs`

## Real-World Applications

- **Security Incident Response**: Detect and alert on suspicious API activity (unauthorized access attempts, privilege escalation, resource deletion)
- **Compliance Auditing**: Maintain audit trails for SOC 2, HIPAA, PCI-DSS compliance requirements
- **Operational Monitoring**: Track infrastructure changes (EC2 launches, security group modifications, IAM policy updates)
- **Cost Anomaly Detection**: Monitor expensive API calls (large EC2 instance launches, data transfer operations)
- **Forensic Analysis**: Investigate security incidents using historical CloudTrail logs

## Interview Talking Points

- **Explain the difference between CloudTrail and CloudWatch**: CloudTrail is for audit logging (who did what), CloudWatch is for operational monitoring (how resources perform)
- **Describe metric filter use cases**: Converting log patterns into metrics enables alarming on log-based events without custom code
- **Discuss security monitoring best practices**: Multi-region trails, log file validation, encrypted S3 storage, automated alerting, regular log analysis
- **Explain alarm threshold selection**: Balance between alert fatigue (too sensitive) and missed incidents (too lenient). 3 failed logins in 5 minutes is reasonable for most environments.

## Complexity Level

**Intermediate** - Requires understanding of CloudTrail, CloudWatch Logs, metric filters, alarms, and SNS integration.

## Estimated Time

**60 minutes** - Including trail creation, metric filter configuration, alarm setup, testing, and Logs Insights queries.

## AWS Certification Alignment

- **AWS Certified Solutions Architect Associate**: CloudTrail architecture, CloudWatch integration, security monitoring patterns
- **AWS Certified Security Specialty**: Security event detection, audit logging, compliance monitoring, incident response
- **AWS Certified SysOps Administrator Associate**: Operational monitoring, alarm configuration, log analysis

## Completion Date

2024-01-15
