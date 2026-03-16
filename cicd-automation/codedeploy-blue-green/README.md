# Creating Blue/Green Deployments with AWS CodeDeploy and Amazon EC2

## Overview

This project demonstrates implementing a blue/green deployment strategy using AWS CodeDeploy to eliminate downtime during application updates. It transforms an existing CodePipeline from in-place deployments (causing downtime) to blue/green deployments across two EC2 instances behind an Application Load Balancer. This approach verifies new instances before routing traffic, ensuring zero-downtime deployments.

**Duration:** 90 minutes  
**Complexity:** Intermediate  
**Category:** DevOps & CI/CD

## The Problem

The existing deployment uses an **in-place deployment** strategy where CodeDeploy updates the application directly on running instances. This causes downtime because:
- The application stops during the update
- Users see errors or connection failures
- No ability to verify the new version before it goes live
- Rollback requires another deployment

## The Solution: Blue/Green Deployment

Blue/green deployment creates a **parallel environment** (green) alongside the existing one (blue):
1. New instances are launched with the updated application
2. You verify the new instances work correctly
3. Traffic is rerouted from old instances (blue) to new instances (green)
4. Old instances are terminated after a wait period
5. **Zero downtime** - users never experience interruptions

## Objectives

By completing this project, you will:

- Understand the difference between in-place and blue/green deployment strategies
- Review an existing CodePipeline with in-place deployment
- Configure an Application Load Balancer and target groups for traffic management
- Create a new CodeDeploy deployment group for blue/green deployments
- Configure deployment settings (traffic rerouting, instance termination)
- Modify CodePipeline to use the new deployment group
- Trigger a blue/green deployment by updating application code
- Observe the 4-step deployment process
- Manually verify new instances before rerouting traffic
- Monitor traffic rerouting and instance termination

## AWS Services Used

- **AWS CodeDeploy** - Orchestrates blue/green deployment across EC2 instances
- **AWS CodePipeline** - Automates the CI/CD workflow
- **AWS CodeCommit** - Git-based source control repository
- **Amazon EC2** - Hosts the web application instances
- **Application Load Balancer (ALB)** - Routes traffic between blue and green environments
- **Auto Scaling** - Manages instance lifecycle and capacity
- **Amazon CloudWatch Events** - Triggers pipeline on code changes

## Architecture

### Before: In-Place Deployment

```
CodeCommit → CodePipeline → CodeDeploy (In-Place) → EC2 Instance
                                                      ↓
                                                   DOWNTIME
```

### After: Blue/Green Deployment

```
CodeCommit → CodePipeline → CodeDeploy (Blue/Green)
                                ↓
                    ┌───────────┴───────────┐
                    ↓                       ↓
            Blue Environment        Green Environment
            (Current Instances)     (New Instances)
                    ↓                       ↓
            Application Load Balancer
                    ↓
            Traffic Rerouting (Manual Control)
                    ↓
            Terminate Blue Instances (After 1 hour)
```

**Key Components:**
- **Application Load Balancer**: Routes traffic to target groups
- **Target Groups**: Blue (current) and Green (replacement) instance groups
- **Auto Scaling Group**: Maintains 2 instances (desired, min, max)
- **Deployment Configuration**: CodeDeployDefault.AllAtOnce (all instances simultaneously)

## Prerequisites

- AWS account with appropriate permissions
- Existing CodeCommit repository with web application
- Existing CodePipeline with Source and Deploy stages
- Application Load Balancer configured with target group
- Auto Scaling group with 2 EC2 instances
- CodeDeploy application and in-place deployment group

## Setup Instructions

### Step 1: Review Existing Pipeline and Application

1. Navigate to **AWS CodePipeline** console
2. Locate your pipeline (e.g., `presidents-pipeline`)
3. Note the two stages:
   - **Source**: Pulls code from CodeCommit
   - **Deploy**: Uses CodeDeploy for in-place deployment
4. Access the application URL and note the **deployment number** (e.g., "Deployment 1")
5. Note the **instance ID** displayed on the page

### Step 2: Review Application Load Balancer

1. Navigate to **EC2 Console** → **Load Balancers**
2. Select your Application Load Balancer
3. Review the **Listeners** tab (HTTP:80)
4. Review the **Target Groups** tab
5. Verify 2 healthy instances are registered

### Step 3: Review Auto Scaling Group

1. Navigate to **EC2 Console** → **Auto Scaling Groups**
2. Select your Auto Scaling group
3. Verify configuration:
   - **Desired capacity**: 2
   - **Minimum capacity**: 2
   - **Maximum capacity**: 2
4. Note the 2 running instances

### Step 4: Observe In-Place Deployment Downtime

1. Make a small code change (e.g., update a comment)
2. Push to CodeCommit to trigger the pipeline
3. Watch the deployment in CodeDeploy console
4. **Refresh the application URL during deployment**
5. Observe the application becomes unavailable (downtime)

### Step 5: Create Blue/Green Deployment Group

1. Navigate to **AWS CodeDeploy** console
2. Select your application
3. Click **Create deployment group**
4. Configure settings:
   - **Deployment group name**: `presidents-deployment-group-bg`
   - **Service role**: Select CodeDeploy service role
   - **Deployment type**: **Blue/green**
   - **Environment configuration**: 
     - Choose **Automatically copy Auto Scaling group**
     - Select your existing Auto Scaling group
   - **Deployment settings**:
     - **Traffic rerouting**: Reroute traffic immediately (or manually)
     - **Terminate original instances**: 1 hour after traffic rerouting
   - **Deployment configuration**: `CodeDeployDefault.AllAtOnce`
   - **Load balancer**: 
     - Enable load balancing
     - Select your Application Load Balancer
     - Select your target group

### Step 6: Configure Deployment Settings

**Traffic Rerouting Options:**
- **Immediately**: Automatic rerouting after successful deployment
- **Manual**: You control when to reroute (recommended for this project)

**Instance Termination Options:**
- **Immediately**: Terminate blue instances right after rerouting
- **Wait time**: Keep blue instances for rollback (1 hour recommended)

**For this project, use:**
- Traffic rerouting: **Manual** (1 hour wait time)
- Instance termination: **Automatic after 1 hour**

### Step 7: Update CodePipeline

1. Navigate to **AWS CodePipeline** console
2. Select your pipeline
3. Click **Edit**
4. In the **Deploy** stage, click **Edit action**
5. Update settings:
   - **Deployment group**: Select `presidents-deployment-group-bg`
6. Click **Done** and **Save**

### Step 8: Trigger Blue/Green Deployment

1. Open your application code in AWS Cloud9/Code Editor
2. Update the deployment number:
   ```html
   <!-- Change from Deployment 1 to Deployment 2 -->
   <h2>Deployment 2</h2>
   ```
3. Commit and push changes:
   ```bash
   git add .
   git commit -m "Update to Deployment 2 for blue/green test"
   git push origin main
   ```

Or use the provided script:
```bash
./scripts/trigger-deployment.sh
```

### Step 9: Observe the 4-Step Deployment Process

Navigate to **CodeDeploy** console and watch the deployment progress through 4 steps:

**Step 1: Provision replacement instances**
- CodeDeploy launches 2 new EC2 instances (green environment)
- Instances are added to a new Auto Scaling group
- Wait for instances to pass health checks

**Step 2: Install application on replacement instances**
- CodeDeploy agent installs the new application version
- Application starts on green instances
- Instances are registered with the load balancer (but not receiving traffic yet)

**Step 3: Reroute traffic to replacement instances**
- **Manual control**: You decide when to reroute
- Load balancer shifts traffic from blue to green target group
- Original instances (blue) remain running but receive no traffic

**Step 4: Terminate original instances**
- After the configured wait time (1 hour), blue instances are terminated
- Green instances become the new production environment
- Auto Scaling group is updated

### Step 10: Verify New Instances Before Rerouting

1. In the CodeDeploy console, the deployment will pause at **Step 3**
2. Click on the **Test traffic** link to access the green environment
3. Verify the application shows:
   - **Deployment 2** (updated version)
   - **New instance ID** (different from original)
4. Test the application functionality
5. If satisfied, click **Reroute traffic** to proceed

### Step 11: Reroute Traffic to Green Environment

1. Click **Reroute traffic** in the CodeDeploy console
2. The load balancer updates its target group
3. Access the application URL (original URL)
4. Verify you now see:
   - **Deployment 2** (new version)
   - **New instance ID**
5. **No downtime occurred** - the application remained available throughout

### Step 12: Monitor Instance Termination

1. After 1 hour (or configured wait time), CodeDeploy terminates blue instances
2. Navigate to **EC2 Console** → **Instances**
3. Observe the original instances enter "Terminating" state
4. The green instances remain running as the new production environment

## Technical Highlights

### Blue/Green Deployment Benefits

- **Zero Downtime**: Traffic switches instantly from blue to green
- **Easy Rollback**: If issues arise, reroute traffic back to blue instances
- **Testing in Production**: Verify green environment before exposing to users
- **Reduced Risk**: New version is fully deployed and tested before traffic shift
- **Instant Cutover**: Load balancer reroutes all traffic simultaneously

### Deployment Strategy Comparison

| Aspect | In-Place Deployment | Blue/Green Deployment |
|--------|---------------------|----------------------|
| **Downtime** | Yes - application stops during update | No - traffic switches between environments |
| **Rollback** | Requires new deployment | Instant - reroute traffic back |
| **Testing** | Cannot test before users see it | Test green environment before rerouting |
| **Resource Cost** | Lower - uses existing instances | Higher - doubles instances temporarily |
| **Complexity** | Simple - update in place | More complex - requires load balancer |
| **Risk** | Higher - issues affect users immediately | Lower - verify before exposing to users |

### Application Load Balancer Role

- **Target Groups**: Separate groups for blue and green environments
- **Health Checks**: Ensures instances are ready before receiving traffic
- **Traffic Routing**: Switches traffic between target groups
- **Connection Draining**: Gracefully completes existing requests before switching

### Auto Scaling Integration

- **Replacement Instances**: CodeDeploy creates a new Auto Scaling group for green
- **Capacity Matching**: Green group matches blue group's capacity (2 instances)
- **Automatic Cleanup**: Blue Auto Scaling group is deleted after termination
- **Consistent Configuration**: Launch template ensures identical instance configuration

### Manual vs Automatic Traffic Rerouting

**Manual Rerouting (Recommended for Production):**
- Allows testing and verification before users see changes
- Provides control over deployment timing
- Enables smoke testing in production environment
- Reduces risk of deploying broken code

**Automatic Rerouting:**
- Faster deployment process
- Suitable for non-critical environments
- Requires high confidence in automated testing
- Still provides rollback capability

## Interview Talking Points

### Zero-Downtime Deployments

**"In this project, I implemented blue/green deployments using AWS CodeDeploy to achieve zero-downtime application updates. The strategy involved launching new EC2 instances with the updated application, verifying them behind an Application Load Balancer, and then instantly switching traffic from the old instances to the new ones. This eliminated the downtime we experienced with in-place deployments."**

### Risk Mitigation

**"Blue/green deployments significantly reduced deployment risk. Before rerouting traffic, I could test the new version in the production environment without affecting users. If issues were discovered, I could simply terminate the green instances without ever exposing users to problems. If issues appeared after rerouting, I could instantly roll back by switching traffic back to the blue instances."**

### Load Balancer Integration

**"The Application Load Balancer was crucial for blue/green deployments. It managed two target groups - one for blue instances and one for green. During deployment, CodeDeploy registered the new instances with the green target group, and once verified, the load balancer switched traffic by updating which target group received requests. This happened instantly without any connection drops."**

### Auto Scaling and Capacity Management

**"CodeDeploy integrated with Auto Scaling to automatically provision replacement instances matching the blue environment's capacity. In our case, it launched 2 new instances to match the 2 existing instances. After traffic rerouting and the wait period, CodeDeploy automatically terminated the blue instances and cleaned up the old Auto Scaling group, ensuring we didn't pay for unused resources."**

## Project Structure

```
devops-cicd/codedeploy-blue-green/
├── README.md                          # This file
├── scripts/
│   ├── trigger-deployment.sh          # Update code and push to trigger deployment
│   └── verify-deployment.sh           # Check deployment status
└── configs/
    ├── appspec.yml                    # CodeDeploy deployment specification
    └── deployment-group-config.json   # Blue/green deployment group configuration
```

## Scripts and Configurations

### appspec.yml

The AppSpec file defines deployment lifecycle hooks:

```yaml
version: 0.0
os: linux
files:
  - source: /
    destination: /var/www/html
hooks:
  BeforeInstall:
    - location: scripts/install_dependencies.sh
      timeout: 300
      runas: root
  ApplicationStart:
    - location: scripts/start_server.sh
      timeout: 300
      runas: root
  ApplicationStop:
    - location: scripts/stop_server.sh
      timeout: 300
      runas: root
```

See [configs/appspec.yml](./configs/appspec.yml) for the complete specification.

### Deployment Group Configuration

The deployment group configuration defines blue/green settings:

```json
{
  "deploymentGroupName": "presidents-deployment-group-bg",
  "deploymentConfigName": "CodeDeployDefault.AllAtOnce",
  "deploymentStyle": {
    "deploymentType": "BLUE_GREEN",
    "deploymentOption": "WITH_TRAFFIC_CONTROL"
  },
  "blueGreenDeploymentConfiguration": {
    "terminateBlueInstancesOnDeploymentSuccess": {
      "action": "TERMINATE",
      "terminationWaitTimeInMinutes": 60
    },
    "deploymentReadyOption": {
      "actionOnTimeout": "STOP_DEPLOYMENT",
      "waitTimeInMinutes": 60
    }
  }
}
```

See [configs/deployment-group-config.json](./configs/deployment-group-config.json) for the complete configuration.

## Additional Resources

- [AWS CodeDeploy Blue/Green Deployments](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployments-create-blue-green.html)
- [Application Load Balancer Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [Auto Scaling Groups](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html)
- [CodeDeploy AppSpec File Reference](https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file.html)

## Troubleshooting

### Deployment Fails at Step 1 (Provision Instances)

- **Cause**: Auto Scaling group cannot launch instances
- **Solution**: Check EC2 service limits, verify launch template, ensure subnet has available IPs

### Deployment Fails at Step 2 (Install Application)

- **Cause**: CodeDeploy agent not running or appspec.yml errors
- **Solution**: SSH to green instance, check `/var/log/aws/codedeploy-agent/`, verify appspec.yml syntax

### Cannot Access Test Traffic URL

- **Cause**: Security group blocks access or instances not healthy
- **Solution**: Verify security group allows HTTP traffic, check target group health checks

### Traffic Rerouting Doesn't Work

- **Cause**: Load balancer configuration issue or target group not registered
- **Solution**: Verify load balancer listener rules, check target group registration

### Blue Instances Not Terminating

- **Cause**: Wait time not elapsed or termination disabled
- **Solution**: Check deployment group configuration, verify wait time has passed

### Application Shows Old Version After Rerouting

- **Cause**: Browser cache or DNS propagation delay
- **Solution**: Clear browser cache, try incognito mode, wait a few minutes for DNS

## Next Steps

- Implement automated testing before traffic rerouting
- Add CloudWatch alarms to monitor deployment health
- Configure SNS notifications for deployment events
- Explore canary deployments (gradual traffic shifting)
- Implement linear or exponential traffic shifting strategies
- Add Lambda hooks for custom validation during deployment
- Integrate with AWS Systems Manager for instance configuration

## Real-World Applications

- **E-commerce Platforms**: Deploy updates during peak traffic without downtime
- **Financial Services**: Ensure continuous availability for critical applications
- **SaaS Applications**: Roll out new features without service interruptions
- **API Services**: Update backend services while maintaining API availability
- **Mobile App Backends**: Deploy server updates without affecting mobile users

## License

This project is for educational purposes as part of an AWS training portfolio.
