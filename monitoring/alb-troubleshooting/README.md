# Troubleshooting Website Reachability Behind a Load Balancer

## Overview

This focused troubleshooting lab teaches systematic diagnosis of Application Load Balancer (ALB) connectivity issues. You'll investigate why a website is unreachable through the load balancer, analyze Target Group health checks, review security group configurations, and implement fixes to restore high availability. This practical scenario mirrors real-world production incidents requiring rapid resolution.

## AWS Services Used

- **Application Load Balancer (ALB)** - Layer 7 load balancing
- **EC2 Target Groups** - Instance health monitoring and traffic distribution
- **Amazon EC2** - Web server instances
- **VPC Security Groups** - Network access control
- **Amazon CloudWatch** - ALB and Target Group metrics

## Architecture

The high-availability web architecture includes:

1. **Application Load Balancer**: Public-facing entry point
2. **Target Group**: Manages backend EC2 instances
3. **EC2 Instances**: Web servers in multiple Availability Zones
4. **Security Groups**: ALB security group and instance security group
5. **Health Checks**: HTTP-based availability monitoring

See [architecture.md](./architecture.md) for detailed architecture diagrams.

## Objectives

- Diagnose ALB connectivity issues using systematic troubleshooting
- Analyze Target Group health check failures
- Identify security group misconfigurations
- Understand ALB → Target Group → EC2 traffic flow
- Configure proper security group rules for high availability
- Verify fixes using health checks and browser testing

## Key Learnings

- **503 Service Unavailable**: ALB returns 503 when no healthy targets are available. Always check Target Group health first.

- **Security Group Chaining**: ALB security group allows inbound from internet (0.0.0.0/0:80), instance security group allows inbound from ALB security group (not ALB IP addresses).

- **Health Check Parameters**: Healthy threshold (consecutive successes needed), unhealthy threshold (consecutive failures needed), timeout, interval, HTTP status codes.

- **Target Registration**: Instances can be in states: initial, healthy, unhealthy, draining, unused. Only healthy targets receive traffic.

- **Cross-Zone Load Balancing**: ALB distributes traffic across all registered targets in all enabled AZs, even if unbalanced.

- **Connection Draining**: When deregistering targets, ALB waits for in-flight requests to complete (default: 300 seconds).

## Problem Statement

**Symptom**: Website is unreachable when accessing ALB DNS name. Browser shows "503 Service Unavailable" error.

**Expected Behavior**: Website should load successfully through ALB, with traffic distributed across multiple EC2 instances.

**Environment**:
- Application Load Balancer: `web-alb`
- Target Group: `web-targets`
- EC2 Instances: 2 instances in different AZs
- Application: Simple web server on port 80

## Troubleshooting Methodology

### Step 1: Verify ALB Status

1. Navigate to **EC2** > **Load Balancers**
2. Select `web-alb`
3. Check **State**: Should be **active**
4. Note **DNS name**: `web-alb-123456789.us-east-1.elb.amazonaws.com`
5. Check **Availability Zones**: Should span multiple AZs
6. **Finding**: ALB is active and properly configured

### Step 2: Check Listeners

1. Click **Listeners** tab
2. Verify listener exists:
   - **Protocol**: HTTP
   - **Port**: 80
   - **Default action**: Forward to `web-targets`
3. **Finding**: Listener is correctly configured

### Step 3: Analyze Target Group Health

1. Navigate to **EC2** > **Target Groups**
2. Select `web-targets`
3. Click **Targets** tab
4. **Critical Finding**: All targets show **unhealthy** status
5. Click on a target to see health check details:
   - **Health status**: Unhealthy
   - **Reason**: Health checks failed
   - **Description**: "Health checks failed with these codes: [Connection refused]"

### Step 4: Review Health Check Configuration

1. Click **Health checks** tab
2. Note configuration:
   - **Protocol**: HTTP
   - **Path**: `/` or `/health`
   - **Port**: Traffic port (80)
   - **Healthy threshold**: 5 consecutive successes
   - **Unhealthy threshold**: 2 consecutive failures
   - **Timeout**: 5 seconds
   - **Interval**: 30 seconds
   - **Success codes**: 200
3. **Finding**: Health check configuration is correct

### Step 5: Check ALB Security Group

1. Navigate to **EC2** > **Load Balancers** > Select `web-alb`
2. Click **Security** tab
3. Note **Security groups**: `alb-sg`
4. Click security group link
5. Review **Inbound rules**:
   - Type: HTTP (80)
   - Source: 0.0.0.0/0 (internet)
6. Review **Outbound rules**:
   - Type: All traffic
   - Destination: 0.0.0.0/0
7. **Finding**: ALB security group is correctly configured

### Step 6: Check Instance Security Group

1. Navigate to **EC2** > **Instances**
2. Select instance from target group
3. Click **Security** tab
4. Note **Security groups**: `web-instance-sg`
5. Click security group link
6. Review **Inbound rules**:
   - **Critical Finding**: NO rule allowing HTTP (port 80) from ALB
   - Existing rules may only allow SSH (port 22)

**Root Cause Identified**: Instance security group does not allow HTTP traffic from ALB security group.

### Step 7: Fix Security Group Configuration

1. Navigate to **EC2** > **Security Groups**
2. Select `web-instance-sg`
3. Click **Edit inbound rules**
4. Click **Add rule**:
   - **Type**: HTTP
   - **Protocol**: TCP
   - **Port range**: 80
   - **Source**: Custom → Select `alb-sg` (ALB security group)
   - **Description**: Allow HTTP from ALB
5. Click **Save rules**

### Step 8: Verify Fix

1. Wait 30-60 seconds for health checks to run
2. Navigate to **EC2** > **Target Groups** > `web-targets`
3. Click **Targets** tab
4. **Expected Result**: Targets transition from **unhealthy** to **healthy**
5. Open browser and navigate to ALB DNS name
6. **Expected Result**: Website loads successfully
7. Refresh multiple times to verify load balancing across instances

### Step 9: Verify High Availability

1. Navigate to **EC2** > **Instances**
2. Select one instance
3. Click **Instance state** > **Stop instance**
4. Wait for instance to stop
5. Navigate to **Target Groups** > **Targets** tab
6. **Expected Result**: Stopped instance shows **unhealthy**, other instance remains **healthy**
7. Test ALB DNS name in browser
8. **Expected Result**: Website still accessible (traffic routed to healthy instance)
9. Restart stopped instance to restore full capacity

## Troubleshooting Checklist

Use this checklist for systematic ALB troubleshooting:

- [ ] ALB state is **active**
- [ ] Listener is configured (HTTP:80 or HTTPS:443)
- [ ] Target Group has registered targets
- [ ] Targets are in **healthy** state
- [ ] Health check configuration is correct (path, port, codes)
- [ ] ALB security group allows inbound from internet
- [ ] Instance security group allows inbound from ALB security group
- [ ] Instances are running and application is listening on correct port
- [ ] Network ACLs allow traffic (if custom NACLs configured)
- [ ] Route tables route traffic correctly

See [scripts/troubleshooting-checklist.md](./scripts/troubleshooting-checklist.md) for detailed checklist.

## Common ALB Issues and Solutions

### Issue 1: 503 Service Unavailable

**Cause**: No healthy targets in Target Group

**Solutions**:
- Fix security group rules
- Fix health check configuration
- Ensure application is running on instances
- Check instance status checks

### Issue 2: Intermittent Connectivity

**Cause**: Some targets healthy, some unhealthy

**Solutions**:
- Investigate unhealthy targets individually
- Check application logs on unhealthy instances
- Verify consistent configuration across all instances

### Issue 3: Slow Response Times

**Cause**: Targets are healthy but slow

**Solutions**:
- Check CloudWatch metrics (TargetResponseTime)
- Investigate instance performance (CPU, memory)
- Consider scaling out (add more targets)
- Consider scaling up (larger instance types)

### Issue 4: Health Checks Failing

**Cause**: Health check path returns non-200 status

**Solutions**:
- Verify health check path exists (e.g., `/health`)
- Check application logs for errors
- Adjust health check parameters (timeout, interval)
- Update success codes if application returns different codes

## Testing and Validation

### Test Scenario 1: Security Group Fix

**Action**: Add HTTP rule to instance security group from ALB security group

**Expected Results**:
- Health checks succeed within 30-60 seconds
- Targets show **healthy** status
- Website accessible via ALB DNS name

### Test Scenario 2: High Availability

**Action**: Stop one EC2 instance

**Expected Results**:
- Stopped instance shows **unhealthy**
- Remaining instance continues serving traffic
- No downtime experienced by users

### Test Scenario 3: Load Distribution

**Action**: Make multiple requests to ALB

**Expected Results**:
- Requests distributed across healthy targets
- Each instance serves approximately equal number of requests
- Response includes instance ID or hostname (if configured)

## Cleanup

1. Delete Application Load Balancer
2. Delete Target Group
3. Terminate EC2 instances (if created for lab)
4. Delete security groups (if created for lab)

## Real-World Applications

- **Production Incident Response**: Rapidly diagnose and resolve ALB connectivity issues
- **High Availability Design**: Implement multi-AZ architectures with proper health checks
- **Security Configuration**: Properly configure security group chaining for ALB architectures
- **Monitoring and Alerting**: Set up CloudWatch alarms for UnHealthyHostCount metric

## Interview Talking Points

- **Explain ALB 503 errors**: No healthy targets available, check Target Group health first
- **Describe security group chaining**: ALB SG allows internet, instance SG allows ALB SG (not IPs)
- **Discuss health check mechanics**: Frequency, thresholds, and impact on traffic routing
- **Explain high availability**: Multi-AZ deployment, health checks, automatic failover

## Complexity Level

**Intermediate** - Requires understanding of ALB, Target Groups, security groups, and systematic troubleshooting.

## Estimated Time

**60 minutes** - Including problem diagnosis, security group configuration, and validation testing.

## AWS Certification Alignment

- **AWS Certified Solutions Architect Associate**: ALB architecture, high availability, security groups
- **AWS Certified SysOps Administrator Associate**: Troubleshooting, operational best practices, monitoring
- **AWS Certified Developer Associate**: Application deployment, load balancing, debugging

## Completion Date

2024-01-15
