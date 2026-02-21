# Responding to Incidents in an AWS Environment

## Overview

This lab demonstrates implementing comprehensive incident response procedures for AWS environments. The implementation includes capturing instance metadata for forensics, creating EBS snapshots for evidence preservation, analyzing CloudWatch logs for security events, isolating compromised instances with security groups, automating incident response with EventBridge rules, and deploying Lambda functions for automated threat response and remediation.

## AWS Services Used

- **Amazon EC2** - Instance isolation and forensics
- **Amazon EBS** - Snapshot creation for evidence preservation
- **Amazon CloudWatch** - Log analysis and monitoring
- **AWS CloudTrail** - API activity auditing
- **Amazon EventBridge** - Event-driven automation
- **AWS Lambda** - Automated incident response
- **AWS Systems Manager** - Instance management and automation
- **Amazon SNS** - Incident notifications
- **AWS IAM** - Incident response roles and policies
- **Amazon S3** - Evidence storage

## Key Technologies

- **Incident Response** - Security incident handling procedures
- **Digital Forensics** - Evidence collection and preservation
- **Security Automation** - Automated threat response
- **Log Analysis** - CloudWatch Logs Insights queries
- **Instance Isolation** - Network-level containment
- **Evidence Preservation** - EBS snapshots and metadata
- **Event-Driven Architecture** - EventBridge automation
- **Serverless Response** - Lambda-based remediation

## Architecture Overview

The architecture implements automated incident response using event-driven patterns. EventBridge monitors CloudTrail and CloudWatch for security events (unauthorized access, suspicious API calls, GuardDuty findings). When threats are detected, EventBridge triggers Lambda functions that automatically isolate compromised instances, create forensic snapshots, capture metadata, send notifications, and initiate investigation workflows. All actions are logged for audit trails and compliance.

See [architecture.md](./architecture.md) for detailed incident response architecture and automation flows.

## Objectives

- Implement incident detection and alerting
- Capture instance metadata for forensic analysis
- Create EBS snapshots for evidence preservation
- Analyze CloudWatch logs for security events
- Isolate compromised instances with security groups
- Automate incident response with EventBridge
- Deploy Lambda functions for automated remediation
- Create incident response playbooks
- Implement notification workflows
- Maintain audit trails and compliance

## Key Learnings

- **Incident Response Lifecycle**: Preparation, detection, containment, eradication, recovery
- **Digital Forensics**: Evidence collection and chain of custody
- **Security Automation**: Event-driven incident response
- **Log Analysis**: CloudWatch Logs Insights for investigation
- **Instance Isolation**: Network containment techniques
- **Evidence Preservation**: Snapshot creation and storage
- **Compliance**: Audit trails and documentation
- **Playbook Development**: Standardized response procedures

## Setup Instructions

### Prerequisites

- AWS account with EC2, Lambda, and EventBridge permissions
- Understanding of incident response procedures
- AWS CLI configured with appropriate credentials
- CloudTrail enabled for API logging
- CloudWatch Logs for application logging
- Understanding of security best practices

### Step 1: Deploy Incident Response Infrastructure

Set up Lambda functions and EventBridge rules:

```bash
./scripts/deploy-ir-infrastructure.sh
```

### Step 2: Configure EventBridge Rules

Create rules for security event detection:

```bash
./scripts/configure-eventbridge-rules.sh
```

### Step 3: Deploy Isolation Security Group

Create forensic isolation security group:

```bash
./scripts/create-isolation-security-group.sh
```

### Step 4: Set Up SNS Notifications

Configure incident alerting:

```bash
./scripts/configure-sns-notifications.sh
```

### Step 5: Test Incident Response

Simulate security incident:

```bash
./scripts/simulate-security-incident.sh
```

### Step 6: Verify Automated Response

Check automated actions:

```bash
./scripts/verify-automated-response.sh
```

## Testing

### Test 1: Instance Isolation

Test automated instance isolation:

```bash
./scripts/test-instance-isolation.sh
```

Expected: Instance security group replaced with isolation SG, all traffic blocked

### Test 2: Snapshot Creation

Test forensic snapshot creation:

```bash
./scripts/test-snapshot-creation.sh
```

Expected: EBS snapshots created with forensic tags

### Test 3: Metadata Capture

Test instance metadata collection:

```bash
./scripts/test-metadata-capture.sh
```

Expected: Instance metadata saved to S3 with timestamp

### Test 4: Log Analysis

Test CloudWatch Logs analysis:

```bash
./scripts/test-log-analysis.sh
```

Expected: Security events identified and reported

### Test 5: Notification Workflow

Test SNS notification delivery:

```bash
./scripts/test-notifications.sh
```

Expected: Email/SMS notifications sent to security team

### Test 6: End-to-End Response

Test complete incident response workflow:

```bash
./scripts/test-end-to-end-response.sh
```

Expected: Detection → Isolation → Snapshot → Notification → Documentation

## Key Concepts

### Incident Response Lifecycle

Six phases of incident response:
1. **Preparation**: Tools, procedures, training
2. **Detection**: Identify security incidents
3. **Containment**: Isolate affected systems
4. **Eradication**: Remove threat from environment
5. **Recovery**: Restore systems to normal operation
6. **Lessons Learned**: Post-incident review and improvement

### Digital Forensics in AWS

Evidence collection and preservation:
- **Instance Metadata**: System information, network config, IAM role
- **EBS Snapshots**: Point-in-time disk images
- **Memory Capture**: RAM contents (if possible)
- **Log Collection**: CloudWatch, CloudTrail, VPC Flow Logs
- **Network Traffic**: VPC Flow Logs, packet captures
- **Chain of Custody**: Document all evidence handling

### Instance Isolation

Containment techniques:
- **Security Group Replacement**: Block all inbound/outbound traffic
- **Network ACL**: Subnet-level blocking
- **Route Table Modification**: Remove internet gateway route
- **Instance Stop**: Preserve state while preventing activity
- **Snapshot Before Isolation**: Capture pre-isolation state

### Automated Response

Event-driven incident handling:
- **EventBridge Rules**: Detect security events
- **Lambda Functions**: Execute response actions
- **Step Functions**: Orchestrate complex workflows
- **SNS Notifications**: Alert security team
- **Systems Manager**: Execute commands on instances
- **CloudWatch Alarms**: Threshold-based detection

## Incident Response Procedures

### Procedure 1: Compromised EC2 Instance

```
1. Detection
   ├── GuardDuty finding: Cryptocurrency mining
   ├── CloudWatch alarm: High CPU usage
   └── CloudTrail: Unauthorized API calls

2. Automated Response (Lambda)
   ├── Create EBS snapshots (evidence)
   ├── Capture instance metadata
   ├── Tag instance: Status=Quarantined
   ├── Replace security group (isolation)
   └── Send SNS notification

3. Manual Investigation
   ├── Review CloudWatch logs
   ├── Analyze CloudTrail events
   ├── Examine EBS snapshot
   ├── Identify attack vector
   └── Document findings

4. Remediation
   ├── Terminate compromised instance
   ├── Launch new instance from clean AMI
   ├── Apply security patches
   ├── Update security groups
   └── Implement preventive controls

5. Recovery
   ├── Restore application from backup
   ├── Verify system integrity
   ├── Monitor for recurrence
   └── Update runbooks
```

### Procedure 2: Unauthorized Access

```
1. Detection
   ├── CloudTrail: Failed authentication attempts
   ├── GuardDuty: Brute force attack
   └── CloudWatch: Unusual access patterns

2. Automated Response
   ├── Disable compromised IAM credentials
   ├── Revoke active sessions
   ├── Enable MFA requirement
   ├── Log all access attempts
   └── Send alert to security team

3. Investigation
   ├── Review CloudTrail logs
   ├── Identify compromised credentials
   ├── Determine scope of access
   ├── Check for data exfiltration
   └── Document timeline

4. Remediation
   ├── Rotate all credentials
   ├── Update IAM policies
   ├── Enable CloudTrail insights
   ├── Implement SCPs
   └── Review access patterns

5. Prevention
   ├── Enforce MFA for all users
   ├── Implement least privilege
   ├── Enable GuardDuty
   ├── Set up CloudWatch alarms
   └── Regular access reviews
```

### Procedure 3: Data Exfiltration

```
1. Detection
   ├── GuardDuty: Unusual S3 API activity
   ├── CloudWatch: High data transfer
   ├── VPC Flow Logs: Large outbound traffic
   └── CloudTrail: Bulk download operations

2. Immediate Actions
   ├── Block source IP addresses
   ├── Disable compromised credentials
   ├── Enable S3 Block Public Access
   ├── Review bucket policies
   └── Capture evidence

3. Investigation
   ├── Identify exfiltrated data
   ├── Determine exfiltration method
   ├── Review access logs
   ├── Check for backdoors
   └── Assess impact

4. Containment
   ├── Remove public access
   ├── Update bucket policies
   ├── Enable MFA Delete
   ├── Implement VPC endpoints
   └── Monitor for recurrence

5. Recovery
   ├── Notify affected parties
   ├── Implement encryption
   ├── Enable versioning
   ├── Set up access logging
   └── Update security controls
```

## Lambda Functions

### Function 1: Isolate Instance

```python
import boto3
import json
from datetime import datetime

ec2 = boto3.client('ec2')
s3 = boto3.client('s3')

def lambda_handler(event, context):
    instance_id = event['detail']['instance-id']
    
    # Capture metadata before isolation
    metadata = capture_metadata(instance_id)
    save_metadata(metadata, instance_id)
    
    # Create snapshots
    snapshot_ids = create_snapshots(instance_id)
    
    # Isolate instance
    isolation_sg = get_isolation_security_group()
    isolate_instance(instance_id, isolation_sg)
    
    # Tag instance
    tag_instance(instance_id, 'Quarantined')
    
    # Send notification
    send_notification(instance_id, snapshot_ids)
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'instance_id': instance_id,
            'snapshots': snapshot_ids,
            'status': 'isolated'
        })
    }
```

### Function 2: Analyze Logs

```python
import boto3
import json
from datetime import datetime, timedelta

logs = boto3.client('logs')
sns = boto3.client('sns')

def lambda_handler(event, context):
    log_group = event['log_group']
    
    # Query for security events
    query = """
    fields @timestamp, @message
    | filter @message like /unauthorized|failed|denied/
    | sort @timestamp desc
    | limit 100
    """
    
    # Execute query
    results = execute_query(log_group, query)
    
    # Analyze results
    security_events = analyze_events(results)
    
    if security_events:
        # Send alert
        send_security_alert(security_events)
    
    return {
        'statusCode': 200,
        'events_found': len(security_events)
    }
```

### Function 3: Disable Credentials

```python
import boto3
import json

iam = boto3.client('iam')
sns = boto3.client('sns')

def lambda_handler(event, context):
    user_name = event['detail']['userIdentity']['userName']
    access_key_id = event['detail']['userIdentity']['accessKeyId']
    
    # Disable access key
    iam.update_access_key(
        UserName=user_name,
        AccessKeyId=access_key_id,
        Status='Inactive'
    )
    
    # Revoke active sessions
    iam.delete_login_profile(UserName=user_name)
    
    # Send notification
    send_notification(user_name, access_key_id)
    
    return {
        'statusCode': 200,
        'user': user_name,
        'action': 'credentials_disabled'
    }
```

## CloudWatch Logs Insights Queries

### Query 1: Failed Authentication Attempts

```sql
fields @timestamp, userIdentity.principalId, sourceIPAddress, errorCode
| filter eventName = "ConsoleLogin" and errorCode = "Failed authentication"
| stats count() by sourceIPAddress
| sort count desc
```

### Query 2: Unauthorized API Calls

```sql
fields @timestamp, eventName, userIdentity.arn, errorCode, errorMessage
| filter errorCode in ["AccessDenied", "UnauthorizedOperation"]
| stats count() by eventName, userIdentity.arn
| sort count desc
```

### Query 3: Data Exfiltration Indicators

```sql
fields @timestamp, eventName, requestParameters.bucketName, sourceIPAddress
| filter eventName in ["GetObject", "ListObjects"] 
| stats count() by sourceIPAddress, requestParameters.bucketName
| filter count > 100
```

### Query 4: Privilege Escalation Attempts

```sql
fields @timestamp, eventName, userIdentity.arn, requestParameters
| filter eventName in ["PutUserPolicy", "AttachUserPolicy", "CreateAccessKey"]
| sort @timestamp desc
```

## Security Considerations

### Evidence Preservation

- Create snapshots immediately upon detection
- Tag all evidence with incident ID and timestamp
- Store snapshots in separate account for isolation
- Implement snapshot encryption
- Document chain of custody
- Retain evidence per compliance requirements

### Incident Isolation

- Isolate before investigation to prevent further damage
- Use dedicated forensic security group (no inbound/outbound)
- Consider stopping instance vs. terminating
- Preserve instance state for analysis
- Document all isolation actions
- Maintain separate forensic VPC

### Automation Safety

- Implement approval workflows for critical actions
- Use Step Functions for complex orchestration
- Test automation in non-production first
- Implement rollback procedures
- Monitor automation execution
- Regular review of automated actions

## Troubleshooting

### Common Issues

**Issue**: Lambda function timeout during snapshot creation
- **Cause**: Large EBS volumes take time to snapshot
- **Solution**: Increase Lambda timeout, use async snapshot creation

**Issue**: Instance not isolated after EventBridge trigger
- **Cause**: Lambda execution role lacks EC2 permissions
- **Solution**: Add ec2:ModifyInstanceAttribute to Lambda role

**Issue**: Notifications not received
- **Cause**: SNS topic subscription not confirmed
- **Solution**: Check email for confirmation link, confirm subscription

**Issue**: Metadata capture fails
- **Cause**: Instance metadata service disabled or unreachable
- **Solution**: Use EC2 DescribeInstances API instead

## Performance Considerations

- **Snapshot Creation**: 5-30 minutes depending on volume size
- **Lambda Execution**: 1-5 seconds for isolation actions
- **EventBridge Latency**: Near real-time (seconds)
- **Log Analysis**: 10-60 seconds depending on log volume
- **Overall Response Time**: 1-2 minutes from detection to isolation

## Cost Optimization

- **EBS Snapshots**: $0.05 per GB-month (incremental)
- **Lambda**: First 1M requests free, $0.20 per 1M after
- **EventBridge**: First 1M events free, $1 per 1M after
- **CloudWatch Logs**: $0.50 per GB ingested
- **S3 Storage**: $0.023 per GB-month (Standard)

### Cost Reduction Tips

- Implement snapshot lifecycle policies
- Use CloudWatch Logs retention policies
- Archive old evidence to Glacier
- Use Lambda reserved concurrency
- Optimize log ingestion

## Real-World Applications

### Enterprise Security Operations

- 24/7 automated incident response
- Integration with SIEM systems
- Compliance reporting and auditing
- Multi-account incident handling
- Centralized security monitoring

### Compliance Requirements

- PCI DSS: Incident response procedures
- HIPAA: Breach notification and documentation
- SOC 2: Security incident management
- GDPR: Data breach response
- ISO 27001: Incident management process

## Best Practices

- ✅ Implement automated detection and response
- ✅ Create forensic snapshots immediately
- ✅ Isolate compromised instances quickly
- ✅ Maintain detailed audit trails
- ✅ Test incident response procedures regularly
- ✅ Document all response actions
- ✅ Implement notification workflows
- ✅ Use separate forensic account for evidence
- ✅ Enable CloudTrail in all regions
- ✅ Regular security training for team
- ✅ Develop incident response playbooks
- ✅ Conduct post-incident reviews
- ✅ Update procedures based on lessons learned
- ✅ Implement least privilege for automation
- ✅ Monitor automation execution

## Additional Resources

- [AWS Security Incident Response Guide](https://docs.aws.amazon.com/whitepapers/latest/aws-security-incident-response-guide/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [NIST Incident Response Guide](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-61r2.pdf)
- [AWS Systems Manager Incident Manager](https://docs.aws.amazon.com/incident-manager/)

## Lab Duration

**Estimated Time**: 75 minutes

## Difficulty Level

**Complexity**: Advanced

## Tags

`Incident Response` `Security Automation` `Forensics` `EventBridge` `Lambda` `CloudWatch` `CloudTrail` `EC2` `EBS Snapshots` `Security Operations`
