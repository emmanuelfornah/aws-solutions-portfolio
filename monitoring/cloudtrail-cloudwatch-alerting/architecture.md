# Architecture: Monitoring and Alerting with CloudTrail and CloudWatch

## Architecture Overview

This lab implements a comprehensive security monitoring and alerting architecture using AWS CloudTrail for API activity logging and Amazon CloudWatch for metric-based alerting. The architecture captures all AWS API calls, streams them to CloudWatch Logs, applies metric filters to detect security events, and triggers automated notifications through Amazon SNS.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS Account                                  │
│                                                                      │
│  ┌──────────────┐                                                   │
│  │  IAM Users   │                                                   │
│  │  & Services  │                                                   │
│  └──────┬───────┘                                                   │
│         │ API Calls                                                 │
│         ▼                                                            │
│  ┌──────────────────────────────────────────────────────────┐      │
│  │              AWS CloudTrail                               │      │
│  │  ┌────────────────────────────────────────────────────┐  │      │
│  │  │  SecurityMonitoringTrail                           │  │      │
│  │  │  - Multi-region: Yes                               │  │      │
│  │  │  - Management events: Read/Write                   │  │      │
│  │  │  - Log file validation: Enabled                    │  │      │
│  │  └────────────────────────────────────────────────────┘  │      │
│  └──────┬───────────────────────────────┬───────────────────┘      │
│         │                                │                          │
│         │ Stream logs                    │ Store logs               │
│         ▼                                ▼                          │
│  ┌──────────────────────┐        ┌──────────────┐                  │
│  │  CloudWatch Logs     │        │   Amazon S3  │                  │
│  │  ┌────────────────┐  │        │  ┌────────┐  │                  │
│  │  │ Log Group:     │  │        │  │ Bucket │  │                  │
│  │  │ CloudTrail/    │  │        │  │ Trail  │  │                  │
│  │  │ SecurityLogs   │  │        │  │ Logs   │  │                  │
│  │  │                │  │        │  └────────┘  │                  │
│  │  │ Log Streams    │  │        │  (Long-term  │                  │
│  │  │ (per region)   │  │        │   storage)   │                  │
│  │  └────────┬───────┘  │        └──────────────┘                  │
│  └───────────┼──────────┘                                           │
│              │                                                       │
│              │ Apply filter                                         │
│              ▼                                                       │
│  ┌──────────────────────────────────────────────────────┐          │
│  │         Metric Filter                                 │          │
│  │  ┌────────────────────────────────────────────────┐  │          │
│  │  │  Filter Pattern:                               │  │          │
│  │  │  { ($.eventName = ConsoleLogin) &&             │  │          │
│  │  │    ($.errorMessage = "Failed authentication") }│  │          │
│  │  │                                                 │  │          │
│  │  │  Metric: Security/Authentication/              │  │          │
│  │  │          FailedLoginAttempts                   │  │          │
│  │  └────────────────────────────────────────────────┘  │          │
│  └──────────────────────────┬───────────────────────────┘          │
│                             │ Publish metric                        │
│                             ▼                                        │
│  ┌──────────────────────────────────────────────────────┐          │
│  │         CloudWatch Metrics                            │          │
│  │  ┌────────────────────────────────────────────────┐  │          │
│  │  │  Namespace: Security/Authentication            │  │          │
│  │  │  Metric: FailedLoginAttempts                   │  │          │
│  │  │  Statistic: Sum                                │  │          │
│  │  │  Period: 5 minutes                             │  │          │
│  │  └────────────────────────────────────────────────┘  │          │
│  └──────────────────────────┬───────────────────────────┘          │
│                             │ Evaluate threshold                    │
│                             ▼                                        │
│  ┌──────────────────────────────────────────────────────┐          │
│  │         CloudWatch Alarm                              │          │
│  │  ┌────────────────────────────────────────────────┐  │          │
│  │  │  Alarm: FailedLoginAlarm                       │  │          │
│  │  │  Condition: Sum > 2 (5 min period)             │  │          │
│  │  │  States: OK | ALARM | INSUFFICIENT_DATA        │  │          │
│  │  └────────────────────────────────────────────────┘  │          │
│  └──────────────────────────┬───────────────────────────┘          │
│                             │ Trigger notification                  │
│                             ▼                                        │
│  ┌──────────────────────────────────────────────────────┐          │
│  │         Amazon SNS                                    │          │
│  │  ┌────────────────────────────────────────────────┐  │          │
│  │  │  Topic: SecurityAlerts                         │  │          │
│  │  │  Protocol: Email                               │  │          │
│  │  │  Endpoint: [EMAIL-ADDRESS]                     │  │          │
│  │  └────────────────────────────────────────────────┘  │          │
│  └──────────────────────────┬───────────────────────────┘          │
│                             │                                        │
└─────────────────────────────┼────────────────────────────────────────┘
                              │ Send email
                              ▼
                      ┌───────────────┐
                      │  Security     │
                      │  Team Email   │
                      └───────────────┘
```

## Component Details

### 1. AWS CloudTrail

**Purpose**: Captures all API activity across AWS services for audit and compliance.

**Configuration**:
- **Trail Name**: SecurityMonitoringTrail
- **Scope**: Multi-region (captures activity in all AWS regions)
- **Event Types**: Management events (read and write operations)
- **Log File Validation**: Enabled (ensures log integrity)
- **Storage**: S3 bucket (long-term retention) + CloudWatch Logs (real-time analysis)

**Events Captured**:
- Console login attempts (successful and failed)
- API calls via AWS CLI, SDKs, and Console
- Service-to-service API calls
- IAM policy changes
- Resource creation, modification, and deletion

### 2. CloudWatch Logs

**Purpose**: Centralized log aggregation and real-time log analysis.

**Configuration**:
- **Log Group**: `CloudTrail/SecurityLogs`
- **Log Streams**: One per region where API activity occurs
- **Retention**: Configurable (1 day to 10 years)
- **IAM Role**: CloudTrail service role with `logs:CreateLogStream` and `logs:PutLogEvents` permissions

**Log Format**: JSON-formatted CloudTrail events containing:
```json
{
  "eventVersion": "1.08",
  "userIdentity": {
    "type": "IAMUser",
    "userName": "john.doe",
    "arn": "arn:aws:iam::[ACCOUNT-ID]:user/john.doe"
  },
  "eventTime": "2024-01-15T10:30:45Z",
  "eventSource": "signin.amazonaws.com",
  "eventName": "ConsoleLogin",
  "sourceIPAddress": "[IP-ADDRESS]",
  "userAgent": "Mozilla/5.0...",
  "errorMessage": "Failed authentication",
  "responseElements": {"ConsoleLogin": "Failure"}
}
```

### 3. Metric Filter

**Purpose**: Transforms log data into CloudWatch metrics for alarming.

**Filter Pattern**:
```
{ ($.eventName = ConsoleLogin) && ($.errorMessage = "Failed authentication") }
```

**Pattern Explanation**:
- `$.eventName = ConsoleLogin`: Matches console login events
- `$.errorMessage = "Failed authentication"`: Matches only failed attempts
- `&&`: Both conditions must be true

**Metric Configuration**:
- **Namespace**: `Security/Authentication` (custom namespace for security metrics)
- **Metric Name**: `FailedLoginAttempts`
- **Metric Value**: `1` (increments by 1 for each failed login)
- **Unit**: Count

### 4. CloudWatch Alarm

**Purpose**: Monitors metric and triggers notifications when threshold is breached.

**Configuration**:
- **Alarm Name**: FailedLoginAlarm
- **Metric**: `Security/Authentication/FailedLoginAttempts`
- **Statistic**: Sum (total failed logins in period)
- **Period**: 5 minutes (evaluation window)
- **Threshold**: Greater than 2 (triggers on 3+ failed logins)
- **Evaluation Periods**: 1 (triggers immediately when threshold exceeded)
- **Datapoints to Alarm**: 1 out of 1

**Alarm States**:
- **OK**: Failed logins ≤ 2 in 5-minute period
- **ALARM**: Failed logins > 2 in 5-minute period
- **INSUFFICIENT_DATA**: No data points in evaluation period

### 5. Amazon SNS

**Purpose**: Delivers notifications to subscribers when alarm triggers.

**Configuration**:
- **Topic Name**: SecurityAlerts
- **Type**: Standard (not FIFO)
- **Protocol**: Email
- **Subscription**: Requires email confirmation

**Notification Content**:
```
You are receiving this email because your Amazon CloudWatch Alarm 
"FailedLoginAlarm" in the US East (N. Virginia) region has entered 
the ALARM state.

Alarm Details:
- Alarm Name: FailedLoginAlarm
- Alarm Description: Alert when 3+ failed login attempts in 5 minutes
- State Change: OK -> ALARM
- Reason: Threshold Crossed: 1 datapoint [3.0] was greater than 
  the threshold (2.0)
- Timestamp: 2024-01-15T10:35:00.000Z
```

### 6. CloudWatch Logs Insights

**Purpose**: Advanced log querying and analysis for security investigations.

**Query Language**: SQL-like syntax with functions for filtering, aggregation, and statistics.

**Example Query**:
```
fields @timestamp, userIdentity.userName, sourceIPAddress, errorMessage
| filter eventName = "ConsoleLogin" and errorMessage = "Failed authentication"
| sort @timestamp desc
| limit 20
```

## Data Flow

### Normal Operation (No Failed Logins)

1. Users and services make API calls to AWS
2. CloudTrail captures all API events
3. Events are streamed to CloudWatch Logs in real-time
4. Events are also stored in S3 for long-term retention
5. Metric filter evaluates each log entry
6. No failed login events match filter pattern
7. Metric value remains at 0
8. CloudWatch alarm stays in **OK** state
9. No notifications sent

### Security Event Detection (Failed Logins)

1. User attempts console login with incorrect password
2. CloudTrail captures `ConsoleLogin` event with `errorMessage: "Failed authentication"`
3. Event is streamed to CloudWatch Logs within 5-10 minutes
4. Metric filter matches the event pattern
5. `FailedLoginAttempts` metric increments by 1
6. After 3 failed logins within 5 minutes, metric sum = 3
7. CloudWatch alarm evaluates: 3 > 2 (threshold)
8. Alarm transitions from **OK** to **ALARM** state
9. Alarm triggers SNS topic
10. SNS sends email notification to subscribed addresses
11. Security team receives alert and investigates

### Investigation Workflow

1. Security team receives alarm notification
2. Navigate to CloudWatch Logs Insights
3. Run query to find all failed login attempts
4. Analyze source IP addresses, usernames, and timestamps
5. Determine if activity is legitimate (user forgot password) or malicious (brute force attack)
6. Take appropriate action (password reset, IP blocking, MFA enforcement)

## Security Considerations

### Log Integrity

- **Log File Validation**: CloudTrail creates digest files with SHA-256 hashes to detect log tampering
- **S3 Bucket Policies**: Restrict access to CloudTrail logs using least privilege IAM policies
- **Encryption**: Enable SSE-S3 or SSE-KMS encryption for logs at rest

### Access Control

- **IAM Policies**: Limit who can modify CloudTrail trails, metric filters, and alarms
- **SNS Topic Policies**: Restrict who can publish to or subscribe to SecurityAlerts topic
- **CloudWatch Logs Permissions**: Use resource-based policies to control log access

### Monitoring the Monitors

- **CloudTrail Logging**: Enable CloudTrail for CloudTrail API calls (meta-monitoring)
- **Alarm on Alarm Deletion**: Create alarms to detect when security alarms are deleted
- **Config Rules**: Use AWS Config to ensure CloudTrail is always enabled

## Cost Optimization

### CloudTrail Costs

- **First trail**: Free for management events
- **Additional trails**: $2.00 per 100,000 management events
- **Data events**: $0.10 per 100,000 events (S3, Lambda)

### CloudWatch Logs Costs

- **Ingestion**: $0.50 per GB
- **Storage**: $0.03 per GB per month
- **Logs Insights queries**: $0.005 per GB scanned

### Cost Reduction Strategies

1. **Log Retention**: Set shorter retention periods (7-30 days) for CloudWatch Logs
2. **S3 Lifecycle Policies**: Move old CloudTrail logs to Glacier for cheaper storage
3. **Selective Logging**: Use advanced event selectors to log only critical events
4. **Query Optimization**: Use time ranges in Logs Insights queries to scan less data

## Scalability

- **CloudTrail**: Automatically scales to handle any volume of API calls
- **CloudWatch Logs**: No limits on log ingestion rate or storage
- **Metric Filters**: Process logs in real-time regardless of volume
- **SNS**: Supports up to 12.5 million subscriptions per topic

## High Availability

- **Multi-Region Trail**: Captures events from all regions, survives regional failures
- **S3 Replication**: Enable cross-region replication for CloudTrail S3 bucket
- **SNS Redundancy**: SNS is a highly available service with automatic failover

## Compliance Alignment

- **PCI-DSS**: Requirement 10 (logging and monitoring)
- **HIPAA**: Audit controls (§164.312(b))
- **SOC 2**: CC7.2 (system monitoring)
- **GDPR**: Article 32 (security of processing)
- **ISO 27001**: A.12.4.1 (event logging)

## Extension Opportunities

1. **Multi-Account Monitoring**: Use AWS Organizations to aggregate CloudTrail logs from all accounts
2. **Advanced Threat Detection**: Integrate with Amazon GuardDuty for ML-based threat detection
3. **Automated Remediation**: Use Lambda functions to automatically respond to security events
4. **SIEM Integration**: Forward CloudWatch Logs to Splunk, Datadog, or other SIEM platforms
5. **Custom Dashboards**: Build real-time security dashboards with CloudWatch or Grafana
