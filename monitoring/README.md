# Monitoring

AWS monitoring services including CloudWatch, CloudTrail, EventBridge, and operational troubleshooting.

## Labs

### 1. [Monitoring and Alerting with AWS CloudTrail and Amazon CloudWatch](./cloudtrail-cloudwatch-alerting/)
**Duration**: 60 minutes | **Complexity**: Intermediate

Comprehensive security monitoring using CloudTrail for API activity logging and CloudWatch for metric-based alerting. Includes metric filters, SNS notifications, and CloudWatch Logs Insights queries.

**Key Services**: CloudTrail, CloudWatch Logs, CloudWatch Alarms, SNS, Logs Insights

### 2. [Security Monitoring with Amazon CloudWatch Alarms](./security-monitoring-cloudwatch-alarms/)
**Duration**: 45 minutes | **Complexity**: Beginner to Intermediate

Operational monitoring and alerting for EC2 instances. Create CloudWatch alarms for CPU utilization, configure SNS notifications, stress test instances, and build dashboards.

**Key Services**: CloudWatch, CloudWatch Alarms, SNS, EC2, CloudWatch Dashboards

### 3. [Using Amazon EventBridge](./eventbridge-automation/)
**Duration**: 40 minutes | **Complexity**: Intermediate

Event-driven automation using EventBridge to respond to Auto Scaling events and scheduled triggers. Includes Lambda integration and complex cron expressions.

**Key Services**: EventBridge, Lambda, Auto Scaling, CloudWatch Logs

### 4. [Performing a Basic Audit of Your AWS Environment](./basic-aws-audit/)
**Duration**: Varies (30 min - 3 hours) | **Complexity**: Intermediate

Systematic AWS account auditing covering IAM permissions, IAM Policy Simulator, EC2 Security Groups, VPC configurations, Network ACLs, CloudWatch metrics, and CloudTrail logs.

**Key Services**: IAM, EC2, VPC, CloudWatch, CloudTrail, S3

### 5. [Monitoring and Troubleshooting EC2 Workloads with Detective Controls](./ec2-troubleshooting-detective-controls/)
**Duration**: 75 minutes | **Complexity**: Intermediate to Advanced

Systematic troubleshooting of EC2 workloads using CloudWatch metrics. Two scenarios: unreachable application (security group misconfiguration) and under-performing application (wrong instance type).

**Key Services**: Application Load Balancer, Target Groups, EC2, CloudWatch, Auto Scaling, Launch Templates

### 6. [Monitoring Applications and Infrastructure](./monitoring-applications-infrastructure/)
**Duration**: 60 minutes | **Complexity**: Intermediate to Advanced

End-to-end monitoring using CloudWatch agent, Systems Manager, custom metrics, dashboards, alarms, and Lambda Canary functions for automated testing.

**Key Services**: CloudWatch, CloudWatch Agent, Systems Manager, Parameter Store, SNS, Lambda

### 7. [Troubleshooting Website Reachability Behind a Load Balancer](./alb-troubleshooting/)
**Duration**: 60 minutes | **Complexity**: Intermediate

Focused troubleshooting of Application Load Balancer connectivity issues. Diagnose Target Group health check failures and security group misconfigurations.

**Key Services**: Application Load Balancer, Target Groups, EC2, Security Groups, CloudWatch

## Skills Developed

- CloudWatch metrics, alarms, and dashboards
- CloudTrail audit logging and analysis
- EventBridge event-driven automation
- Security monitoring and alerting
- Application Load Balancer troubleshooting
- Systems Manager integration
- Systematic troubleshooting methodology
- Compliance auditing

## Certification Alignment

- **AWS Certified Solutions Architect Associate**: Monitoring architecture, CloudWatch design, ALB patterns
- **AWS Certified SysOps Administrator Associate**: Operational monitoring, troubleshooting, alarm management
- **AWS Certified Security Specialty**: Security monitoring, audit logging, compliance
- **AWS Certified Developer Associate**: Application monitoring, EventBridge, Lambda integration
