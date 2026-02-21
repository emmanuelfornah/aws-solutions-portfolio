# Deploying Containerized Applications to Amazon EKS

## Overview

This lab demonstrates deploying containerized applications to **Amazon Elastic Kubernetes Service (EKS)**, AWS's managed Kubernetes service. It represents the final and most advanced step in the deployment evolution series, showcasing enterprise-grade container orchestration with Kubernetes on AWS.

EKS provides a production-ready Kubernetes control plane that's highly available, scalable, and integrated with AWS services. This lab covers cluster creation, imperative and declarative deployment approaches, and demonstrates how Kubernetes abstracts infrastructure complexity while providing powerful orchestration capabilities.

## AWS Services Used

- **Amazon EKS** - Managed Kubernetes control plane
- **Amazon EC2** - Worker nodes for running containers
- **Amazon ECR** - Container image registry
- **Amazon VPC** - Network isolation for EKS cluster
- **AWS IAM** - Authentication and authorization
- **AWS CloudFormation** - Infrastructure provisioning (used by eksctl)
- **AWS Code Editor** - Cloud-based development environment

## Deployment Evolution Context

This lab completes the deployment evolution journey:

1. **EC2** - Manual instance configuration and application deployment
2. **Lambda** - Serverless functions with automatic scaling
3. **Elastic Beanstalk** - Platform-as-a-Service with managed infrastructure
4. **Docker/ECR** - Containerization and image registry
5. **ECS/Fargate** - AWS-native container orchestration
6. **EKS** ← You are here - Kubernetes-based orchestration (most advanced)

EKS represents the pinnacle of deployment flexibility and control, offering:
- **Kubernetes ecosystem** - Access to vast cloud-native tooling
- **Multi-cloud portability** - Kubernetes runs anywhere
- **Advanced orchestration** - Complex deployment patterns and workflows
- **Enterprise features** - RBAC, network policies, service mesh integration

## Key Technologies

- **Kubernetes** - Container orchestration platform
- **kubectl** - Kubernetes command-line tool
- **eksctl** - EKS cluster management CLI
- **Docker containers** - Application packaging format
- **YAML manifests** - Declarative infrastructure definitions
- **Kubernetes Jobs** - Run-to-completion workloads
- **Managed Node Groups** - EC2 worker nodes managed by EKS

## Kubernetes Concepts

### Control Plane
The Kubernetes control plane manages the cluster state, scheduling, and orchestration. In EKS, AWS manages the control plane (API server, etcd, scheduler, controller manager), providing high availability and automatic updates.

### Worker Nodes
EC2 instances that run containerized applications. EKS supports:
- **Managed Node Groups** - AWS manages EC2 lifecycle
- **Self-managed Nodes** - Full control over EC2 configuration
- **Fargate** - Serverless compute for pods

### Pods
The smallest deployable unit in Kubernetes. A pod contains one or more containers that share networking and storage. Pods are ephemeral and managed by higher-level controllers.

### Jobs
A Kubernetes Job creates one or more pods and ensures they successfully complete. Jobs are ideal for batch processing, data processing, and run-to-completion tasks like our URL checker application.

### Deployments
Controllers that manage stateless applications, providing rolling updates, rollbacks, and replica management. Deployments are the standard way to run long-running services.

### Services
Abstractions that expose applications running on pods. Services provide stable networking endpoints and load balancing across pod replicas.

## Objectives

By completing this lab, you will:

1. Install and configure kubectl and eksctl CLI tools
2. Create an EKS cluster with managed node groups
3. Configure kubeconfig for cluster authentication
4. Deploy applications using imperative commands (kubectl run)
5. Deploy applications using declarative manifests (kubectl apply)
6. Understand Kubernetes Jobs for run-to-completion workloads
7. View pod logs and troubleshoot deployments
8. Scale worker nodes in managed node groups
9. Compare imperative vs declarative Kubernetes management
10. Understand EKS architecture and AWS integration

## Architecture

### EKS Cluster Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                             │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │              Amazon EKS Control Plane              │    │
│  │  (Managed by AWS - Multi-AZ, Highly Available)    │    │
│  │                                                     │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │    │
│  │  │   API    │  │   etcd   │  │  Scheduler   │   │    │
│  │  │  Server  │  │          │  │  Controller  │   │    │
│  │  └──────────┘  └──────────┘  └──────────────┘   │    │
│  └────────────────────────────────────────────────────┘    │
│                          │                                   │
│                          │ kubectl commands                  │
│                          │                                   │
│  ┌────────────────────────────────────────────────────┐    │
│  │              VPC (10.0.0.0/16)                     │    │
│  │                                                     │    │
│  │  ┌─────────────────────────────────────────────┐  │    │
│  │  │      Managed Node Group                     │  │    │
│  │  │                                              │  │    │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐ │  │    │
│  │  │  │  Node 1  │  │  Node 2  │  │  Node 3  │ │  │    │
│  │  │  │  (EC2)   │  │  (EC2)   │  │  (EC2)   │ │  │    │
│  │  │  │          │  │          │  │          │ │  │    │
│  │  │  │ ┌──────┐ │  │ ┌──────┐ │  │ ┌──────┐ │ │  │    │
│  │  │  │ │ Pod  │ │  │ │ Pod  │ │  │ │ Pod  │ │ │  │    │
│  │  │  │ │(Job) │ │  │ │      │ │  │ │      │ │ │  │    │
│  │  │  │ └──────┘ │  │ └──────┘ │  │ └──────┘ │ │  │    │
│  │  │  └──────────┘  └──────────┘  └──────────┘ │  │    │
│  │  └─────────────────────────────────────────────┘  │    │
│  │                                                     │    │
│  │  ┌─────────────────────────────────────────────┐  │    │
│  │  │         Amazon ECR                          │  │    │
│  │  │  (Container Image Registry)                 │  │    │
│  │  │  • url-checker:latest                       │  │    │
│  │  └─────────────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Component Interactions

1. **Developer** uses kubectl to interact with EKS API server
2. **API Server** authenticates requests via IAM and processes commands
3. **Scheduler** assigns pods to worker nodes based on resources
4. **Kubelet** (on each node) pulls images from ECR and runs containers
5. **Pods** execute application workloads
6. **Controller Manager** ensures desired state matches actual state

## Setup Instructions

### Prerequisites

- AWS account with appropriate permissions
- AWS CLI configured with credentials
- Access to AWS Code Editor or local terminal
- Existing ECR repository with url-checker image (from Docker/ECR lab)

### Step 1: Install kubectl

kubectl is the Kubernetes command-line tool for interacting with clusters.

```bash
# Download kubectl binary
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/amd64/kubectl

# Make executable
chmod +x ./kubectl

# Move to PATH
mkdir -p $HOME/bin && mv ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH

# Verify installation
kubectl version --client
```

### Step 2: Install eksctl

eksctl is a CLI tool for creating and managing EKS clusters.

```bash
# Download eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp

# Move to PATH
sudo mv /tmp/eksctl /usr/local/bin

# Verify installation
eksctl version
```

### Step 3: Create EKS Cluster

Create a production-ready EKS cluster with managed node groups:

```bash
# Create cluster (takes 15-20 minutes)
eksctl create cluster \
  --name url-checker-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed
```

This command:
- Creates EKS control plane in multiple availability zones
- Creates VPC with public and private subnets
- Creates managed node group with 3 t3.medium EC2 instances
- Configures IAM roles and security groups
- Updates kubeconfig for kubectl access

### Step 4: Verify Cluster

```bash
# View cluster info
kubectl cluster-info

# List nodes
kubectl get nodes

# View node details
kubectl get nodes -o wide
```

Expected output shows 3 nodes in Ready state.

### Step 5: Configure ECR Access

Ensure worker nodes can pull images from ECR:

```bash
# Get ECR repository URI
aws ecr describe-repositories --repository-names url-checker

# The managed node group IAM role already has ECR pull permissions
# Verify by checking node IAM role
kubectl describe node <node-name> | grep "ProviderID"
```

## Deployment Approaches

### Imperative Deployment (kubectl run)

Imperative commands create resources directly via CLI. Quick for testing but not reproducible.

```bash
# Run URL checker as a pod
kubectl run url-checker \
  --image=<account-id>.dkr.ecr.us-east-1.amazonaws.com/url-checker:latest \
  --restart=Never \
  --command -- python url_checker.py https://aws.amazon.com https://kubernetes.io

# View pod status
kubectl get pods

# View pod logs
kubectl logs url-checker

# Delete pod
kubectl delete pod url-checker
```

**Pros:**
- Fast and simple for testing
- No manifest files needed
- Good for one-off tasks

**Cons:**
- Not reproducible
- No version control
- Hard to manage at scale

### Declarative Deployment (kubectl apply)

Declarative manifests define desired state in YAML files. Reproducible and version-controlled.

```bash
# Apply Job manifest
kubectl apply -f kubernetes/job.yaml

# View job status
kubectl get jobs

# View pods created by job
kubectl get pods

# View job logs
kubectl logs job/url-checker-job

# Delete job
kubectl delete -f kubernetes/job.yaml
```

**Pros:**
- Reproducible and version-controlled
- Infrastructure as code
- Easy to review and audit
- Supports GitOps workflows

**Cons:**
- Requires manifest creation
- More verbose than imperative

## Key Learnings

### 1. Kubernetes Abstraction

Kubernetes abstracts infrastructure complexity:
- **Pods** abstract containers
- **Services** abstract networking
- **Deployments** abstract replica management
- **Jobs** abstract batch workloads

You declare desired state; Kubernetes handles implementation.

### 2. EKS vs Self-Managed Kubernetes

**EKS Advantages:**
- AWS manages control plane (HA, updates, patches)
- Integrated with AWS services (IAM, VPC, ECR, CloudWatch)
- Automatic control plane scaling
- Compliance certifications

**Self-Managed Considerations:**
- Full control over control plane
- More operational overhead
- Manual upgrades and patches

### 3. Managed Node Groups

EKS managed node groups simplify worker node management:
- Automatic EC2 provisioning and termination
- Automated updates and patches
- Integration with Auto Scaling groups
- Simplified node lifecycle management

### 4. Imperative vs Declarative

**Imperative** (kubectl run, create, delete):
- Good for: Testing, debugging, one-off tasks
- Bad for: Production, reproducibility, collaboration

**Declarative** (kubectl apply):
- Good for: Production, GitOps, collaboration, auditing
- Bad for: Quick experiments (more verbose)

**Best Practice:** Use declarative manifests for all production workloads.

### 5. Kubernetes Jobs for Batch Workloads

Jobs are ideal for:
- Data processing pipelines
- Batch computations
- Database migrations
- Scheduled tasks (with CronJobs)

Jobs ensure pods run to completion and handle failures with restart policies.

### 6. EKS Integration with AWS

EKS deeply integrates with AWS:
- **IAM** - Pod-level IAM roles (IRSA)
- **VPC** - Native VPC networking for pods
- **ECR** - Seamless image pulls
- **CloudWatch** - Logs and metrics
- **ALB/NLB** - Load balancer integration
- **EBS/EFS** - Persistent storage

### 7. kubectl and eksctl Roles

**kubectl:**
- Interacts with Kubernetes API
- Manages workloads (pods, deployments, services)
- Works with any Kubernetes cluster

**eksctl:**
- EKS-specific cluster management
- Creates/deletes clusters
- Manages node groups
- Simplifies EKS operations

### 8. Scaling and High Availability

EKS provides multiple scaling dimensions:
- **Horizontal Pod Autoscaling** - Scale pods based on metrics
- **Cluster Autoscaler** - Scale nodes based on pod demand
- **Vertical Pod Autoscaling** - Adjust pod resource requests
- **Multi-AZ** - Control plane and nodes across availability zones

### 9. Cost Considerations

EKS costs include:
- **Control plane:** $0.10/hour per cluster (~$73/month)
- **Worker nodes:** EC2 instance costs (t3.medium ~$30/month each)
- **Data transfer:** Standard AWS rates
- **Storage:** EBS volumes for persistent data

**Cost optimization:**
- Use Fargate for variable workloads
- Use Spot instances for fault-tolerant workloads
- Right-size node instance types
- Use Cluster Autoscaler to scale down during low usage

### 10. When to Use EKS

**Choose EKS when you need:**
- Kubernetes ecosystem and tooling
- Multi-cloud or hybrid cloud portability
- Complex orchestration requirements
- Advanced networking (service mesh, network policies)
- Existing Kubernetes expertise
- GitOps workflows

**Consider alternatives when:**
- Simple applications → Use ECS or Elastic Beanstalk
- Serverless workloads → Use Lambda or Fargate
- Cost-sensitive → ECS has no control plane cost
- AWS-only → ECS provides tighter AWS integration

## Comparison to Other Deployment Methods

### vs. ECS/Fargate

| Aspect | EKS | ECS/Fargate |
|--------|-----|-------------|
| **Orchestrator** | Kubernetes | AWS proprietary |
| **Portability** | Multi-cloud | AWS-only |
| **Complexity** | Higher learning curve | Simpler |
| **Ecosystem** | Vast (CNCF) | AWS-focused |
| **Control Plane Cost** | $73/month | Free |
| **Tooling** | kubectl, Helm, etc. | AWS CLI, Console |
| **Best For** | Complex orchestration | AWS-native apps |

### vs. Elastic Beanstalk

| Aspect | EKS | Elastic Beanstalk |
|--------|-----|-------------------|
| **Abstraction** | Container orchestration | Platform-as-a-Service |
| **Control** | Full control | Limited control |
| **Complexity** | High | Low |
| **Scaling** | Highly configurable | Automatic |
| **Best For** | Microservices | Simple web apps |

### vs. Lambda

| Aspect | EKS | Lambda |
|--------|-----|--------|
| **Model** | Long-running containers | Event-driven functions |
| **Cold Start** | No cold starts | Cold starts possible |
| **Duration** | Unlimited | 15 minute max |
| **Cost Model** | Pay for nodes | Pay per invocation |
| **Best For** | Stateful apps | Event processing |

## Troubleshooting

### Cluster Creation Fails

```bash
# Check CloudFormation stacks
aws cloudformation describe-stacks --region us-east-1

# View eksctl logs
eksctl utils describe-stacks --cluster=url-checker-cluster --region=us-east-1
```

### Pods Not Starting

```bash
# Describe pod for events
kubectl describe pod <pod-name>

# Check pod logs
kubectl logs <pod-name>

# Check node resources
kubectl top nodes
```

### Image Pull Errors

```bash
# Verify ECR repository exists
aws ecr describe-repositories

# Check node IAM role has ECR permissions
aws iam get-role --role-name <node-role-name>

# Verify image URI is correct
kubectl describe pod <pod-name> | grep Image
```

### kubectl Connection Issues

```bash
# Update kubeconfig
aws eks update-kubeconfig --name url-checker-cluster --region us-east-1

# Verify cluster endpoint
kubectl cluster-info

# Check AWS credentials
aws sts get-caller-identity
```

## Cleanup

To avoid ongoing charges, delete the EKS cluster:

```bash
# Delete cluster (takes 10-15 minutes)
eksctl delete cluster --name url-checker-cluster --region us-east-1
```

This deletes:
- EKS control plane
- Managed node groups (EC2 instances)
- VPC and networking resources
- CloudFormation stacks

**Note:** ECR images are not deleted. Delete manually if no longer needed.

## Next Steps

1. **Explore Deployments**: Convert Job to Deployment for long-running service
2. **Add Services**: Expose application with LoadBalancer or Ingress
3. **Implement Helm**: Package application as Helm chart
4. **Set Up CI/CD**: Automate deployments with CodePipeline or GitLab CI
5. **Add Monitoring**: Integrate Prometheus and Grafana
6. **Implement RBAC**: Configure role-based access control
7. **Use Fargate**: Run pods without managing nodes
8. **Service Mesh**: Implement Istio or App Mesh for advanced networking

## Related Labs

- **Docker/ECR URL Checker**: Containerization foundation for this lab
- **ECS/Fargate**: AWS-native container orchestration alternative
- **Lambda URL Checker**: Serverless alternative
- **EC2 URL Checker**: Traditional compute approach

## Additional Resources

- [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [eksctl Documentation](https://eksctl.io/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [CNCF Cloud Native Landscape](https://landscape.cncf.io/)

---

**Lab Completed:** [Date]  
**Complexity Level:** Advanced  
**Estimated Time:** 2-3 hours  
**AWS Certification Alignment:** AWS Certified Solutions Architect - Associate/Professional, AWS Certified DevOps Engineer
