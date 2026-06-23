# Architecture: Incident Response Automation in AWS

## Architecture Diagram

┌────────────────────────────────────────────────────────────────────────────┐
│                          AWS Account - Production                           │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │                        Detection Layer                                │ │
│  │                                                                       │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐ │ │
│  │  │  AWS CloudTrail │  │ Amazon GuardDuty│  │ CloudWatch Alarms   │ │ │
│  │  │  - API calls    │  │  - Threats      │  │  - Metrics          │ │ │
│  │  │  - Auth events  │  │  - Anomalies    │  │  - Thresholds       │ │ │
│  │  └────────┬────────┘  └────────┬────────┘  └──────────┬──────────┘ │ │
│  │           │                    │                       │            │ │
│  │           └────────────────────┼───────────────────────┘            │ │
│  │                                │                                    │ │
│  └────────────────────────────────┼────────────────────────────────────┘ │
│                                   │                                       │
│                                   │ Security Events                       │
│                                   ▼                                       │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │                    Amazon EventBridge                                 │ │
│  │                                                                       │ │
│  │  Rule 1: Compromised Instance                                        │ │
│  │  Pattern: GuardDuty finding type = "CryptoCurrency:EC2/*"            │ │
│  │  Target: Lambda (IsolateInstance)                                    │ │
│  │                                                                       │ │
│  │  Rule 2: Unauthorized Access                                         │ │
│  │  Pattern: CloudTrail errorCode = "AccessDenied"                      │ │
│  │  Target: Lambda (DisableCredentials)                                 │ │
│  │                                                                       │ │
│  │  Rule 3: Data Exfiltration                                           │ │
│  │  Pattern: S3 GetObject count > threshold                             │ │
│  │  Target: Lambda (BlockAccess)                                        │ │
│  └──────────────────────────────┬────────────────────────────────────────┘ │
│                                 │                                          │
│                                 │ Trigger                                  │
│                                 ▼                                          │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │                    AWS Lambda Functions                               │ │
│  │                                                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐│ │
│  │  │  Function: IsolateInstance                                      ││ │
│  │  │  Trigger: EventBridge (compromised instance)                    ││ │
│  │  │  Actions:                                                        ││ │
│  │  │    1. Capture instance metadata                                 ││ │
│  │  │    2. Create EBS snapshots                                      ││ │
│  │  │    3. Replace security group (isolation)                        ││ │
│  │  │    4. Tag instance (Quarantined)                                ││ │
│  │  │    5. Send SNS notification                                     ││ │
│  │  └─────────────────────────────────────────────────────────────────┘│ │
│  │                                                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐│ │
│  │  │  Function: AnalyzeLogs                                          ││ │
│  │  │  Trigger: Scheduled (every 5 minutes)                           ││ │
│  │  │  Actions:                                                        ││ │
│  │  │    1. Query CloudWatch Logs Insights                            ││ │
│  │  │    2. Identify security events                                  ││ │
│  │  │    3. Correlate events                                          ││ │
│  │  │    4. Send alerts if threats found                              ││ │
│  │  └─────────────────────────────────────────────────────────────────┘│ │
│  │                                                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐│ │
│  │  │  Function: DisableCredentials                                   ││ │
│  │  │  Trigger: EventBridge (unauthorized access)                     ││ │
│  │  │  Actions:                                                        ││ │
│  │  │    1. Disable IAM access keys                                   ││ │
│  │  │    2. Revoke active sessions                                    ││ │
│  │  │    3. Log incident details                                      ││ │
│  │  │    4. Send notification                                         ││ │
│  │  └─────────────────────────────────────────────────────────────────┘│ │
│  └──────────────────────────────┬────────────────────────────────────────┘ │
│                                 │                                          │
└─────────────────────────────────┼──────────────────────────────────────────┘
                                  │
                                  │ Actions
                                  ▼

┌────────────────────────────────────────────────────────────────────────────┐
│                          Response Actions                                   │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │  Amazon EC2 - Compromised Instance                                    │ │
│  │                                                                       │ │
│  │  Before Isolation:                    After Isolation:               │ │
│  │  ┌─────────────────────┐             ┌─────────────────────┐        │ │
│  │  │ Instance i-abc123   │             │ Instance i-abc123   │        │ │
│  │  │ Status: Running     │             │ Status: Running     │        │ │
│  │  │ SG: web-server-sg   │    ───>     │ SG: forensic-iso-sg │        │ │
│  │  │ - Inbound: 80, 443  │             │ - Inbound: NONE     │        │ │
│  │  │ - Outbound: ALL     │             │ - Outbound: NONE    │        │ │
│  │  │ Tags: Production    │             │ Tags: Quarantined   │        │ │
│  │  └─────────────────────┘             └─────────────────────┘        │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │  Amazon EBS - Forensic Snapshots                                      │ │
│  │                                                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐│ │
│  │  │ Snapshot: snap-forensic-001                                     ││ │
│  │  │ Volume: vol-abc123 (Root)                                       ││ │
│  │  │ Size: 100 GB                                                    ││ │
│  │  │ Created: 2024-01-15 14:30:00 UTC                                ││ │
│  │  │ Tags:                                                            ││ │
│  │  │   - IncidentId: INC-2024-001                                    ││ │
│  │  │   - Purpose: Forensics                                          ││ │
│  │  │   - InstanceId: i-abc123                                        ││ │
│  │  │   - CreatedBy: Lambda-IsolateInstance                           ││ │
│  │  └─────────────────────────────────────────────────────────────────┘│ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │  Amazon S3 - Evidence Storage                                         │ │
│  │                                                                       │ │
│  │  s3://incident-response-evidence-bucket/                             │ │
│  │  ├── INC-2024-001/                                                   │ │
│  │  │   ├── metadata/                                                   │ │
│  │  │   │   ├── instance-metadata.json                                 │ │
│  │  │   │   ├── network-config.json                                    │ │
│  │  │   │   └── iam-role-info.json                                     │ │
│  │  │   ├── logs/                                                       │ │
│  │  │   │   ├── cloudtrail-events.json                                 │ │
│  │  │   │   ├── cloudwatch-logs.txt                                    │ │
│  │  │   │   └── vpc-flow-logs.txt                                      │ │
│  │  │   ├── snapshots/                                                  │ │
│  │  │   │   └── snapshot-ids.txt                                       │ │
│  │  │   └── timeline.json                                              │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │  Amazon SNS - Notifications                                           │ │
│  │                                                                       │ │
│  │  Topic: SecurityIncidentAlerts                                       │ │
│  │  Subscriptions:                                                       │ │
│  │    - Email: security-team@company.com                                │ │
│  │    - SMS: +1-555-0100                                                │ │
│  │    - Lambda: CreateJiraTicket                                        │ │
│  │    - SQS: IncidentQueue                                              │ │
│  │                                                                       │ │
│  │  Message Format:                                                      │ │
│  │  {                                                                    │ │
│  │    "IncidentId": "INC-2024-001",                                     │ │
│  │    "Severity": "HIGH",                                               │ │
│  │    "Type": "Compromised Instance",                                   │ │
│  │    "InstanceId": "i-abc123",                                         │ │
│  │    "DetectionTime": "2024-01-15T14:25:00Z",                          │ │
│  │    "ResponseTime": "2024-01-15T14:26:30Z",                           │ │
│  │    "Actions": ["Isolated", "Snapshotted", "Tagged"],                │ │
│  │    "SnapshotIds": ["snap-forensic-001", "snap-forensic-002"]        │ │
│  │  }                                                                    │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────────┐
│                    Forensic Analysis Environment                            │
│                    (Separate AWS Account)                                   │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │  Forensic VPC (Isolated)                                              │ │
│  │                                                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐│ │
│  │  │  Forensic Workstation (EC2)                                     ││ │
│  │  │  - Forensic tools installed                                     ││ │
│  │  │  - No internet access                                           ││ │
│  │  │  - Access via Systems Manager Session Manager                   ││ │
│  │  │                                                                  ││ │
│  │  │  Mounted Volumes:                                                ││ │
│  │  │  - /mnt/evidence/vol-abc123 (from snapshot)                     ││ │
│  │  │  - /mnt/evidence/vol-def456 (from snapshot)                     ││ │
│  │  └─────────────────────────────────────────────────────────────────┘│ │
│  │                                                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐│ │
│  │  │  Evidence Storage (S3)                                          ││ │
│  │  │  - Cross-account access from production                         ││ │
│  │  │  - Versioning enabled                                           ││ │
│  │  │  - MFA Delete enabled                                           ││ │
│  │  │  - Encryption at rest (KMS)                                     ││ │
│  │  │  - Access logging enabled                                       ││ │
│  │  └─────────────────────────────────────────────────────────────────┘│ │
│  └──────────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────────┘

## Incident Response Workflow

### Automated Response Flow

1. Detection
   ├── GuardDuty Finding: CryptoCurrency:EC2/BitcoinTool.B!DNS
   ├── Severity: HIGH
   ├── Instance: i-abc123
   └── Timestamp: 2024-01-15T14:25:00Z

2. EventBridge Rule Triggered
   ├── Rule: CompromisedInstanceDetection
   ├── Pattern Match: GuardDuty finding type
   └── Target: Lambda IsolateInstance

3. Lambda Execution: IsolateInstance
   ├── Step 1: Capture Metadata (5 seconds)
   │   ├── Instance details (ID, type, AMI, launch time)
   │   ├── Network configuration (VPC, subnet, ENI, IPs)
   │   ├── IAM role and policies
   │   ├── Security groups (before isolation)
   │   ├── Tags and metadata
   │   └── Save to S3: s3://evidence/INC-2024-001/metadata/
   │
   ├── Step 2: Create EBS Snapshots (async, 10-30 min)
   │   ├── Identify all attached volumes
   │   ├── Create snapshot for each volume
   │   ├── Tag snapshots with incident ID
   │   ├── Snapshot IDs: [snap-001, snap-002]
   │   └── Copy snapshots to forensic account
   │
   ├── Step 3: Isolate Instance (2 seconds)
   │   ├── Get forensic isolation security group
   │   ├── Replace instance security groups
   │   ├── New SG: forensic-isolation-sg
   │   │   ├── Inbound: DENY ALL
   │   │   └── Outbound: DENY ALL
   │   └── Instance now isolated
   │
   ├── Step 4: Tag Instance (1 second)
   │   ├── Status: Quarantined
   │   ├── IncidentId: INC-2024-001
   │   ├── IsolatedAt: 2024-01-15T14:26:00Z
   │   └── IsolatedBy: Lambda-IsolateInstance
   │
   └── Step 5: Send Notification (1 second)
       ├── Publish to SNS topic
       ├── Include incident details
       ├── Include snapshot IDs
       └── Include next steps

4. Notification Delivery
   ├── Email to security team
   ├── SMS to on-call engineer
   ├── Create Jira ticket (via Lambda)
   └── Add to incident queue (SQS)

5. Manual Investigation (Security Team)
   ├── Review GuardDuty findings
   ├── Analyze CloudTrail logs
   ├── Examine CloudWatch logs
   ├── Mount forensic snapshots
   ├── Perform disk analysis
   └── Document findings

Total Automated Response Time: ~10 seconds (excluding snapshot creation)

## Lambda Function Architecture

### Function 1: IsolateInstance

```python
import boto3
import json
from datetime import datetime
import os

ec2 = boto3.client('ec2')
s3 = boto3.client('s3')
sns = boto3.client('sns')

EVIDENCE_BUCKET = os.environ['EVIDENCE_BUCKET']
ISOLATION_SG = os.environ['ISOLATION_SECURITY_GROUP']
SNS_TOPIC = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    # Extract instance ID from GuardDuty finding
    instance_id = event['detail']['resource']['instanceDetails']['instanceId']
    incident_id = f"INC-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    
    print(f"Processing incident {incident_id} for instance {instance_id}")
    
    try:
        # Step 1: Capture metadata
        metadata = capture_instance_metadata(instance_id)
        save_metadata(metadata, incident_id, instance_id)
        
        # Step 2: Create snapshots
        snapshot_ids = create_forensic_snapshots(instance_id, incident_id)
        
        # Step 3: Isolate instance
        original_sgs = isolate_instance(instance_id)
        
        # Step 4: Tag instance
        tag_instance(instance_id, incident_id)
        
        # Step 5: Send notification
        send_incident_notification(incident_id, instance_id, snapshot_ids)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'incident_id': incident_id,
                'instance_id': instance_id,
                'snapshots': snapshot_ids,
                'status': 'isolated',
                'original_security_groups': original_sgs
            })
        }
    
    except Exception as e:
        print(f"Error processing incident: {str(e)}")
        send_error_notification(incident_id, instance_id, str(e))
        raise

def capture_instance_metadata(instance_id):
    """Capture comprehensive instance metadata"""
    response = ec2.describe_instances(InstanceIds=[instance_id])
    instance = response['Reservations'][0]['Instances'][0]
    
    metadata = {
        'instance_id': instance_id,
        'instance_type': instance['InstanceType'],
        'ami_id': instance['ImageId'],
        'launch_time': instance['LaunchTime'].isoformat(),
        'vpc_id': instance['VpcId'],
        'subnet_id': instance['SubnetId'],
        'private_ip': instance['PrivateIpAddress'],
        'public_ip': instance.get('PublicIpAddress'),
        'security_groups': [sg['GroupId'] for sg in instance['SecurityGroups']],
        'iam_role': instance.get('IamInstanceProfile', {}).get('Arn'),
        'tags': instance.get('Tags', []),
        'network_interfaces': [
            {
                'id': eni['NetworkInterfaceId'],
                'private_ip': eni['PrivateIpAddress'],
                'public_ip': eni.get('Association', {}).get('PublicIp')
            }
            for eni in instance['NetworkInterfaces']
        ],
        'block_devices': [
            {
                'device_name': bd['DeviceName'],
                'volume_id': bd['Ebs']['VolumeId']
            }
            for bd in instance['BlockDeviceMappings']
        ],
        'captured_at': datetime.now().isoformat()
    }
    
    return metadata

def save_metadata(metadata, incident_id, instance_id):
    """Save metadata to S3 evidence bucket"""
    key = f"{incident_id}/metadata/instance-{instance_id}.json"
    s3.put_object(
        Bucket=EVIDENCE_BUCKET,
        Key=key,
        Body=json.dumps(metadata, indent=2),
        ServerSideEncryption='AES256',
        Metadata={
            'incident-id': incident_id,
            'instance-id': instance_id,
            'evidence-type': 'metadata'
        }
    )
    print(f"Metadata saved to s3://{EVIDENCE_BUCKET}/{key}")

def create_forensic_snapshots(instance_id, incident_id):
    """Create snapshots of all attached volumes"""
    response = ec2.describe_instances(InstanceIds=[instance_id])
    instance = response['Reservations'][0]['Instances'][0]
    
    snapshot_ids = []
    for bd in instance['BlockDeviceMappings']:
        volume_id = bd['Ebs']['VolumeId']
        device_name = bd['DeviceName']
        
        snapshot = ec2.create_snapshot(
            VolumeId=volume_id,
            Description=f"Forensic snapshot for incident {incident_id}",
            TagSpecifications=[
                {
                    'ResourceType': 'snapshot',
                    'Tags': [
                        {'Key': 'IncidentId', 'Value': incident_id},
                        {'Key': 'InstanceId', 'Value': instance_id},
                        {'Key': 'VolumeId', 'Value': volume_id},
                        {'Key': 'DeviceName', 'Value': device_name},
                        {'Key': 'Purpose', 'Value': 'Forensics'},
                        {'Key': 'CreatedBy', 'Value': 'Lambda-IsolateInstance'},
                        {'Key': 'CreatedAt', 'Value': datetime.now().isoformat()}
                    ]
                }
            ]
        )
        
        snapshot_ids.append(snapshot['SnapshotId'])
        print(f"Created snapshot {snapshot['SnapshotId']} for volume {volume_id}")
    
    return snapshot_ids

def isolate_instance(instance_id):
    """Replace security groups with isolation SG"""
    # Get current security groups
    response = ec2.describe_instances(InstanceIds=[instance_id])
    instance = response['Reservations'][0]['Instances'][0]
    original_sgs = [sg['GroupId'] for sg in instance['SecurityGroups']]
    
    # Replace with isolation security group
    ec2.modify_instance_attribute(
        InstanceId=instance_id,
        Groups=[ISOLATION_SG]
    )
    
    print(f"Instance {instance_id} isolated. Original SGs: {original_sgs}")
    return original_sgs

def tag_instance(instance_id, incident_id):
    """Tag instance with incident information"""
    ec2.create_tags(
        Resources=[instance_id],
        Tags=[
            {'Key': 'Status', 'Value': 'Quarantined'},
            {'Key': 'IncidentId', 'Value': incident_id},
            {'Key': 'IsolatedAt', 'Value': datetime.now().isoformat()},
            {'Key': 'IsolatedBy', 'Value': 'Lambda-IsolateInstance'}
        ]
    )

def send_incident_notification(incident_id, instance_id, snapshot_ids):
    """Send SNS notification about incident"""
    message = {
        'IncidentId': incident_id,
        'Severity': 'HIGH',
        'Type': 'Compromised Instance',
        'InstanceId': instance_id,
        'DetectionTime': datetime.now().isoformat(),
        'Actions': ['Metadata Captured', 'Snapshots Created', 'Instance Isolated', 'Instance Tagged'],
        'SnapshotIds': snapshot_ids,
        'NextSteps': [
            'Review GuardDuty findings',
            'Analyze CloudTrail logs',
            'Mount forensic snapshots',
            'Perform disk analysis',
            'Document findings'
        ]
    }
    
    sns.publish(
        TopicArn=SNS_TOPIC,
        Subject=f"Security Incident: {incident_id}",
        Message=json.dumps(message, indent=2)
    )

## CloudWatch Logs Analysis

### Log Insights Query Examples

**Query 1: Failed SSH Attempts**
```sql
fields @timestamp, @message
| filter @message like /Failed password/
| parse @message /Failed password for * from * port/
| stats count() by user, source_ip
| sort count desc

**Query 2: Privilege Escalation**
```sql
fields @timestamp, eventName, userIdentity.arn, requestParameters
| filter eventName in ["PutUserPolicy", "AttachUserPolicy", "CreateAccessKey", "PutRolePolicy"]
| sort @timestamp desc

**Query 3: Data Exfiltration Indicators**
```sql
fields @timestamp, eventName, requestParameters.bucketName, sourceIPAddress
| filter eventName = "GetObject"
| stats count() as download_count by sourceIPAddress, requestParameters.bucketName
| filter download_count > 100
| sort download_count desc

## Best Practices Summary

### Preparation
1. Deploy incident response infrastructure before incidents occur
2. Test automation regularly in non-production environments
3. Document incident response procedures and playbooks
4. Train security team on tools and procedures
5. Establish communication channels and escalation paths

### Detection
1. Enable GuardDuty in all regions
2. Configure CloudWatch alarms for security metrics
3. Enable CloudTrail in all regions with log file validation
4. Implement VPC Flow Logs for network visibility
5. Regular review of security findings

### Containment
1. Isolate compromised resources immediately
2. Create forensic snapshots before making changes
3. Preserve evidence with proper chain of custody
4. Document all containment actions
5. Maintain separate forensic environment

### Recovery
1. Terminate compromised instances (don't reuse)
2. Launch new instances from clean AMIs
3. Apply security patches and updates
4. Implement preventive controls
5. Monitor for recurrence

### Lessons Learned
1. Conduct post-incident reviews
2. Update procedures based on findings
3. Share lessons learned with team
4. Improve detection and response capabilities
5. Document improvements made

## AI Enhancement Architecture (Automated Incident Classification)

```text
GuardDuty/CloudTrail/SecurityHub
            |
            v
      EventBridge Rule
            |
            v
   Step Functions: IncidentAITriageWorkflow
      1) ClassifyIncidentWithBedrock (Lambda)
         - Calls Amazon Bedrock (Nova Lite) for incident categorization
         - Produces structured JSON (category, severity, confidence, team, actions)
      2) RouteIncidentActions (Lambda)
         - Maps category/severity -> owning team and response actions
         - Emits IncidentRouted event to EventBridge for downstream systems
      3) Choice state for HIGH/CRITICAL escalation
```

### Classification Output Contract

```json
{
  "category": "COMPROMISED_INSTANCE|UNAUTHORIZED_ACCESS|DATA_EXFILTRATION|MALWARE_ACTIVITY|CREDENTIAL_ABUSE|BENIGN",
  "severity": "LOW|MEDIUM|HIGH|CRITICAL",
  "confidence": 0.0,
  "routed_team": "SECOPS|IAM_TEAM|CLOUD_PLATFORM|SOC_L1",
  "recommended_actions": ["action 1", "action 2"],
  "reasoning": "short justification"
}
```
