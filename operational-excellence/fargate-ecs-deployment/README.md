# Deploying Containers on AWS Fargate Using Amazon ECS and Amazon ECR

## Lab Overview

Build, deploy, and run containerized applications using Amazon ECS, ECR, and Fargate. This lab walks through setting up an ECS cluster, defining task definitions, and launching containers on Fargate—AWS's serverless compute engine for containers.

**Duration:** 60 minutes  
**Complexity:** Intermediate

## Objectives

- Locate container image in Amazon ECR
- Author task definitions to describe application containers
- Create Amazon ECS cluster to run tasks and services
- Add containerized tasks to the cluster on Fargate

## Prerequisites

- AWS account with appropriate permissions
- Container image already pushed to Amazon ECR (url-checker repository)
- Basic understanding of Docker and containerization
- Familiarity with AWS networking concepts (VPC, security groups)

## Architecture

This lab demonstrates serverless container deployment using:
- **Amazon ECR**: Container registry storing the url-checker image
- **Amazon ECS**: Container orchestration service managing tasks and services
- **AWS Fargate**: Serverless compute engine (no EC2 instances to manage)
- **CloudWatch Logs**: Centralized logging for container output
- **VPC Networking**: Secure networking with public IP assignment

See [architecture.md](./architecture.md) for detailed architecture information.

## Tasks

### Task 1: Locate the Container Image in Amazon ECR

The url-checker container image has already been pushed to ECR. You need to locate it and record its URI.

**Console Steps:**

1. Navigate to the **Amazon ECR console**
2. In the left navigation pane, choose **Repositories**
3. Locate the **url-checker** repository
4. Click on the repository name to view details
5. Copy the **Image URI** (format: `AccountID.dkr.ecr.us-west-2.amazonaws.com/url-checker:latest`)
6. Save this URI—you'll need it for the task definition

**CLI Alternative:**

```bash
# List ECR repositories
aws ecr describe-repositories --region us-west-2

# Get image details
aws ecr describe-images \
  --repository-name url-checker \
  --region us-west-2
```

**Expected Output:**
- Repository name: `url-checker`
- Image tag: `latest`
- Image URI: `<account-id>.dkr.ecr.us-west-2.amazonaws.com/url-checker:latest`

---

### Task 2: Create a Task Definition

Task definitions are blueprints that describe how containers should run in ECS.

**Console Steps:**

1. Navigate to the **Amazon ECS console**
2. In the left navigation pane, choose **Task Definitions**
3. Click **Create new Task Definition**
4. Configure the task definition:
   - **Task definition family:** `url-checker`
   - **Launch type:** `AWS Fargate`
   - **Operating system/Architecture:** `Linux/X86_64`
   - **Task size:**
     - **CPU:** `0.5 vCPU` (512 units)
     - **Memory:** `1 GB` (1024 MB)
5. Under **Container - 1**, configure:
   - **Container name:** `url-checker`
   - **Image URI:** Paste the ECR image URI from Task 1
   - **Essential container:** Yes (checked)
6. Expand **Environment variables - optional**
7. Under **Command override**, add:
   ```
   https://aws.amazon.com,https://expired.badssl.com,https://self-signed.badssl.com
   ```
8. Expand **Logging - optional**:
   - **Log driver:** `awslogs`
   - **Log group:** Auto-created (or specify custom)
   - **Region:** `us-west-2`
   - **Stream prefix:** `url-checker`
9. Click **Create**

**CLI Alternative:**

```bash
# Use the provided task definition template
./scripts/create-task-definition.sh
```

**Expected Output:**
- Task definition created: `url-checker:1` (revision 1)
- Status: ACTIVE
- Launch type compatibility: FARGATE

---

### Task 3: Create an Amazon ECS Cluster

ECS clusters are logical groupings of tasks and services.

**Console Steps:**

1. In the **Amazon ECS console**, choose **Clusters** from the left navigation
2. Click **Create Cluster**
3. Configure the cluster:
   - **Cluster name:** `lab-cluster-fargate`
   - **Infrastructure:** Select **AWS Fargate (serverless)**
   - Leave other settings as default
4. Click **Create**

**CLI Alternative:**

```bash
./scripts/create-cluster.sh
```

**Expected Output:**
- Cluster created: `lab-cluster-fargate`
- Status: ACTIVE
- Capacity providers: FARGATE, FARGATE_SPOT

---

### Task 4: Create and Configure an ECS Service

Services maintain a specified number of running tasks and can integrate with load balancers.

**Console Steps:**

1. Navigate to your cluster: **lab-cluster-fargate**
2. On the **Services** tab, click **Create**
3. Configure the service:
   - **Compute options:** `Launch type`
   - **Launch type:** `FARGATE`
   - **Application type:** `Service`
   - **Task definition:**
     - **Family:** `url-checker`
     - **Revision:** `LATEST`
   - **Service name:** `url-checker-service`
   - **Desired tasks:** `1`
4. Under **Networking**:
   - **VPC:** Select `Lab VPC`
   - **Subnets:** Select available public subnets
   - **Security group:** Select `URLCheckerAppSecurityGroup`
     - Should allow HTTP (port 80) from Anywhere
   - **Public IP:** `ENABLED` (turn on)
5. Leave **Load balancing** as `None`
6. Review and click **Create**

**CLI Alternative:**

```bash
./scripts/create-service.sh
```

**Expected Output:**
- Service created: `url-checker-service`
- Status: ACTIVE
- Desired count: 1
- Running count: 0 (initially, will increase to 1)

---

### Task 5: Monitor the Service and View Results

Watch the task lifecycle and view application output in CloudWatch Logs.

**Console Steps:**

1. In your cluster, click on the **url-checker-service**
2. On the **Tasks** tab, observe the task status:
   - **PENDING:** Task is being provisioned
   - **RUNNING:** Container is executing
   - **STOPPED:** Task completed (expected for this application)
3. Click on the **Task ID** to view details
4. Note the **Last status** and **Stopped reason**
5. Under **Logs**, click **View logs in CloudWatch**
6. Review the application output showing URL check results

**CLI Alternative:**

```bash
./scripts/monitor-service.sh
```

**Expected Output in CloudWatch Logs:**

```
Checking URLs...
✓ https://aws.amazon.com - Status: 200 OK
✗ https://expired.badssl.com - SSL Certificate Expired
✗ https://self-signed.badssl.com - Self-signed Certificate
URL check complete.
```

**Note:** The task is designed to run once and exit. This is normal behavior—the service will show 0 running tasks after completion.

---

## Verification Steps

1. **Task Definition:** Verify it appears in the ECS console with correct CPU/memory settings
2. **Cluster:** Confirm cluster is ACTIVE with Fargate capacity provider
3. **Service:** Check service shows ACTIVE status (even with 0 running tasks)
4. **Task Execution:** Verify task transitioned through PENDING → RUNNING → STOPPED
5. **Logs:** Confirm CloudWatch logs show URL check results
6. **Networking:** Verify task received a public IP address (visible in task details)

## Key Learnings

### Amazon ECS Concepts

- **Clusters:** Logical grouping of tasks and services
- **Task Definitions:** Blueprint describing container configuration
- **Tasks:** Instantiation of a task definition (running container)
- **Services:** Maintain desired count of tasks, handle failures and scaling

### AWS Fargate Benefits

- **Serverless:** No EC2 instances to provision or manage
- **Right-sizing:** Pay only for CPU and memory resources used
- **Security:** Task-level isolation with dedicated kernel runtime
- **Simplified Operations:** AWS manages infrastructure patching and scaling

### Task Definition Components

- **Family:** Logical name for task definition versions
- **Launch Type:** Fargate (serverless) or EC2 (self-managed)
- **Task Size:** CPU and memory allocation at task level
- **Container Definitions:** Image, commands, environment variables, ports
- **Network Mode:** `awsvpc` (required for Fargate, provides ENI per task)
- **Logging:** CloudWatch Logs integration for centralized logging

### Networking in Fargate

- Each task gets its own elastic network interface (ENI)
- Tasks can have public IP addresses for internet access
- Security groups control inbound/outbound traffic at task level
- VPC subnets determine task placement and network routing

## Comparison with Other Deployment Methods

### vs. Docker on EC2 (docker-ecr-url-checker)

- **Fargate:** Serverless, no instance management, automatic scaling
- **EC2:** Full control over host, persistent instances, manual scaling
- **Use Fargate when:** You want simplified operations and don't need host-level access
- **Use EC2 when:** You need custom instance types, GPU, or host-level customization

### vs. AWS Lambda

- **Fargate:** Long-running containers, any runtime, up to 120 GB memory
- **Lambda:** Event-driven functions, 15-minute timeout, 10 GB memory limit
- **Use Fargate when:** You have containerized apps or need longer execution times
- **Use Lambda when:** You have short-lived, event-driven workloads

### vs. Amazon EKS (eks-url-checker)

- **ECS/Fargate:** AWS-native, simpler learning curve, integrated with AWS services
- **EKS:** Kubernetes-based, portable across clouds, richer ecosystem
- **Use ECS when:** You're AWS-focused and want simplicity
- **Use EKS when:** You need Kubernetes features or multi-cloud portability

### vs. Elastic Beanstalk

- **Fargate:** Container-focused, fine-grained control, microservices-friendly
- **Beanstalk:** Application-focused, opinionated, monolith-friendly
- **Use Fargate when:** You have containerized microservices
- **Use Beanstalk when:** You want fastest deployment with minimal configuration

## Cleanup

To avoid ongoing charges:

```bash
# Delete the service
aws ecs delete-service \
  --cluster lab-cluster-fargate \
  --service url-checker-service \
  --force

# Delete the cluster
aws ecs delete-cluster \
  --cluster lab-cluster-fargate

# Deregister task definition (optional)
aws ecs deregister-task-definition \
  --task-definition url-checker:1
```

## Additional Resources

- [Amazon ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS Fargate Documentation](https://docs.aws.amazon.com/fargate/)
- [ECS Task Definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html)
- [Fargate Pricing](https://aws.amazon.com/fargate/pricing/)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)

## Next Steps

- Explore [EKS deployment](../eks-url-checker/) for Kubernetes-based orchestration
- Add Application Load Balancer for production services
- Implement auto-scaling based on CPU/memory metrics
- Set up CI/CD pipeline with AWS CodePipeline
- Configure service discovery with AWS Cloud Map
