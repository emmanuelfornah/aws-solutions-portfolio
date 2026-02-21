# Monitoring and Troubleshooting EC2 Workloads with Detective Controls

## Overview

This lab teaches systematic troubleshooting of EC2 workloads using CloudWatch metrics and detective controls. You'll diagnose two real-world scenarios: an unreachable application due to security group misconfiguration, and an under-performing application due to incorrect instance type selection. Through hands-on troubleshooting, you'll learn to use Application Load Balancers, Target Groups, CloudWatch metrics, and Auto Scaling diagnostics.

## AWS Services Used

- **Application Load Balancer (ALB)** - Layer 7 load balancing and health checks
- **EC2 Target Groups** - Instance registration and health monitoring
- **Amazon EC2** - Compute instances and Auto Scaling
- **Amazon CloudWatch** - Metrics analysis and performance monitoring
- **Auto Scaling Groups** - Dynamic capacity management
- **Launch Templates** - Instance configuration templates

## Architecture

The troubleshooting architecture includes:

1. **Application Load Balancer**: Distributes traffic to EC2 instances
2. **Target Group**: Manages instance health checks and registration
3. **Auto Scaling Group**: Maintains desired instance count
4. **CloudWatch Metrics**: Provides performance and health data
5. **Launch Template**: Defines instance configuration

See [architecture.md](./architecture.md) for detailed diagrams.

## Objectives

- Diagnose application unreachability using ALB and Target Group health checks
- Troubleshoot security group misconfigurations blocking traffic
- Identify performance issues using CloudWatch metrics
- Analyze instance type selection for workload requirements
- Use Auto Scaling group diagnostics
- Implement systematic troubleshooting methodology

## Key Learnings

- **Health Check Mechanics**: Target Groups perform periodic health checks (default: every 30 seconds). Instances must pass health checks before receiving traffic.

- **Security Group Layering**: ALB security group must allow inbound traffic from internet, Target instance security group must allow inbound from ALB security group.

- **Instance Type Selection**: Wrong instance type causes performance issues. CPU-optimized (c-family), memory-optimized (r-family), general-purpose (t/m-family).

- **CloudWatch Metrics for Troubleshooting**: Key metrics include CPUUtilization, NetworkIn/Out, StatusCheckFailed, TargetResponseTime, UnHealthyHostCount.

- **Systematic Troubleshooting**: Follow OSI model (Layer 7 → Layer 4 → Layer 3): Check application logs → Check security groups → Check network ACLs → Check route tables.

## Scenario 1: Application Unreachable

### Problem Statement

Users report the application is unreachable via the Application Load Balancer. The ALB returns 503 Service Unavailable errors.

### Troubleshooting Steps

1. **Check ALB Status**:
   - Navigate to **EC2** > **Load Balancers**
   - Verify ALB state is **active**
   - Check **Listeners** tab (should have HTTP:80 or HTTPS:443)

2. **Check Target Group Health**:
   - Navigate to **EC2** > **Target Groups**
   - Select target group
   - Click **Targets** tab
   - **Finding**: All targets show **unhealthy** status
   - Click target to see health check failure reason

3. **Analyze Health Check Configuration**:
   - Click **Health checks** tab
   - Note settings:
     - Protocol: HTTP
     - Path: `/health` or `/`
     - Port: 80
     - Healthy threshold: 5
     - Unhealthy threshold: 2
     - Timeout: 5 seconds
     - Interval: 30 seconds

4. **Check Instance Security Group**:
   - Navigate to **EC2** > **Instances**
   - Select instance from target group
   - Click **Security** tab
   - Review **Inbound rules**
   - **Root Cause Found**: Security group does NOT allow HTTP (port 80) from ALB security group

5. **Fix Security Group**:
   - Navigate to **EC2** > **Security Groups**
   - Select instance security group
   - Click **Edit inbound rules**
   - Add rule:
     - Type: HTTP (80)
     - Source: ALB security group ID (sg-xxxxx)
     - Description: Allow HTTP from ALB
   - Click **Save rules**

6. **Verify Fix**:
   - Wait 30-60 seconds for health checks
   - Navigate to **Target Groups** > **Targets** tab
   - **Result**: Targets now show **healthy** status
   - Test ALB DNS name in browser → Application loads successfully

### Lessons Learned

- **Security Group Dependencies**: ALB → Target instances requires explicit security group rule
- **Health Check Failures**: Always check Target Group health status first when ALB returns 503
- **Troubleshooting Order**: Start with health checks, then security groups, then application logs

See [scripts/scenario1-troubleshooting.md](./scripts/scenario1-troubleshooting.md) for detailed commands.

## Scenario 2: EC2 Under-Performing

### Problem Statement

Application is reachable but extremely slow. Users report page load times of 10+ seconds (should be < 2 seconds).

### Troubleshooting Steps

1. **Check ALB Metrics**:
   - Navigate to **EC2** > **Load Balancers** > Select ALB
   - Click **Monitoring** tab
   - Review metrics:
     - **TargetResponseTime**: 8-12 seconds (very high)
     - **RequestCount**: Normal
     - **HealthyHostCount**: 2 (all targets healthy)
   - **Finding**: High response time indicates backend performance issue

2. **Check Target Group Metrics**:
   - Navigate to **EC2** > **Target Groups** > Select target group
   - Click **Monitoring** tab
   - Review **TargetResponseTime** per target
   - **Finding**: All targets have high response times (not isolated to one instance)

3. **Check EC2 Instance Metrics**:
   - Navigate to **EC2** > **Instances** > Select instance
   - Click **Monitoring** tab
   - Review CloudWatch metrics:
     - **CPUUtilization**: 95-100% (maxed out)
     - **NetworkIn/Out**: Normal
     - **DiskReadOps/WriteOps**: Normal
   - **Root Cause Found**: CPU is bottleneck

4. **Check Instance Type**:
   - Click **Details** tab
   - Note **Instance type**: `t2.micro` (1 vCPU, 1 GB RAM)
   - **Finding**: Instance type too small for workload

5. **Check Auto Scaling Launch Template**:
   - Navigate to **EC2** > **Launch Templates**
   - Select template used by Auto Scaling group
   - Click **Actions** > **View**
   - **Finding**: Template specifies `t2.micro`

6. **Fix: Update Launch Template**:
   - Click **Actions** > **Modify template (Create new version)**
   - Change **Instance type**: `t2.medium` (2 vCPU, 4 GB RAM)
   - Click **Create template version**
   - Set new version as **Default version**

7. **Update Auto Scaling Group**:
   - Navigate to **EC2** > **Auto Scaling Groups**
   - Select Auto Scaling group
   - Click **Edit**
   - Update **Launch template version**: Latest
   - Click **Update**

8. **Replace Instances**:
   - Option A: Terminate old instances (Auto Scaling launches new ones with updated template)
   - Option B: Increase desired capacity temporarily, then decrease (rolling replacement)
   - **Chosen**: Terminate instances one at a time

9. **Verify Fix**:
   - Wait for new instances to launch and pass health checks
   - Navigate to **CloudWatch** > **Metrics**
   - Check **CPUUtilization** for new instances: 30-40% (healthy)
   - Test application: Page load time < 2 seconds ✓

### Lessons Learned

- **Right-Sizing**: Choose instance types based on workload requirements (CPU, memory, network)
- **CloudWatch Metrics**: High CPU utilization indicates compute bottleneck
- **Launch Templates**: Updating template doesn't affect running instances (must replace)
- **Rolling Updates**: Replace instances gradually to maintain availability

See [scripts/scenario2-troubleshooting.md](./scripts/scenario2-troubleshooting.md) for detailed commands.

## Troubleshooting Methodology

### Systematic Approach

1. **Define the Problem**: What is the symptom? (unreachable, slow, errors)
2. **Gather Data**: Check metrics, logs, health checks
3. **Form Hypothesis**: Based on data, what could be the cause?
4. **Test Hypothesis**: Make targeted changes or checks
5. **Verify Fix**: Confirm problem is resolved
6. **Document**: Record root cause and resolution

### Key Metrics for Troubleshooting

| Metric | Normal Range | High Value Indicates |
|--------|--------------|---------------------|
| CPUUtilization | < 70% | Compute bottleneck, need larger instance |
| TargetResponseTime | < 1 second | Backend performance issue |
| UnHealthyHostCount | 0 | Health check failures, check security groups |
| StatusCheckFailed | 0 | Instance or system issues |
| NetworkIn/Out | Varies | Network bottleneck if maxed |

## Cleanup

1. Delete Application Load Balancer
2. Delete Target Group
3. Delete Auto Scaling Group (terminates instances)
4. Delete Launch Template
5. Delete security groups (if created for lab)

## Real-World Applications

- **Production Troubleshooting**: Diagnose application issues using systematic methodology
- **Performance Optimization**: Identify bottlenecks and right-size resources
- **Incident Response**: Quickly resolve outages using health checks and metrics
- **Capacity Planning**: Use CloudWatch metrics to predict scaling needs

## Interview Talking Points

- **Describe troubleshooting methodology**: Systematic approach from symptoms to root cause
- **Explain security group layering**: ALB → Target instances requires explicit rules
- **Discuss instance type selection**: Match instance family to workload (CPU, memory, network)
- **Describe health check mechanics**: Frequency, thresholds, and impact on traffic routing

## Complexity Level

**Intermediate to Advanced** - Requires understanding of ALB, Target Groups, Auto Scaling, CloudWatch, and systematic troubleshooting.

## Estimated Time

**75 minutes** - Including setup, troubleshooting both scenarios, and verification.

## AWS Certification Alignment

- **AWS Certified Solutions Architect Associate**: ALB architecture, Auto Scaling, instance type selection
- **AWS Certified SysOps Administrator Associate**: Troubleshooting, CloudWatch metrics, operational best practices
- **AWS Certified Developer Associate**: Application performance, health checks, debugging

## Completion Date

2024-01-15
