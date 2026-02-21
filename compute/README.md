# Compute

Domain category for AWS compute services including EC2, Lambda, and Elastic Beanstalk.

## Labs

### [Hosting a WordPress Blog on EC2](./wordpress-on-ec2/)

**Services:** EC2, VPC, Network Load Balancer, Security Groups

**Description:** Deploy a production-ready WordPress blog on Amazon EC2 with a complete LAMP stack (Linux, Apache, MariaDB, PHP). Includes SSL/TLS encryption, Network Load Balancer configuration, and security best practices.

**Key Technologies:** Apache HTTP Server, MariaDB, PHP 8.2, WordPress, SSL/TLS, mod_ssl

**Complexity:** Intermediate | **Time:** 2-3 hours

**Key Learnings:**
- LAMP stack configuration and integration
- WordPress manual installation and configuration
- SSL/TLS certificate generation and Apache configuration
- Security hardening with file permissions and security groups
- Network Load Balancer integration with target groups
- VPC networking with public/private subnets

---

### [Deploying a Flask Application to Elastic Beanstalk](./flask-elastic-beanstalk/)

**Services:** Elastic Beanstalk, EC2, Auto Scaling, Elastic Load Balancing, S3, CloudWatch, CloudFormation

**Description:** Deploy a Python Flask RESTful API to AWS Elastic Beanstalk, demonstrating Platform-as-a-Service (PaaS) capabilities with automatic infrastructure provisioning, load balancing, auto-scaling, and zero-downtime deployments.

**Key Technologies:** Python, Flask, EB CLI, Gunicorn, AWS Code Editor

**Complexity:** Intermediate | **Time:** 45-60 minutes

**Key Learnings:**
- Platform-as-a-Service (PaaS) deployment model
- Flask RESTful API development and design
- Elastic Beanstalk environment configuration and management
- Automatic infrastructure provisioning (EC2, ALB, Auto Scaling)
- Rolling deployments with zero downtime
- CloudWatch monitoring and log aggregation
- Application version management and rollback strategies

---

### [Applying Key Amazon EC2 Functions to Applications (URL Checker on EC2)](./ec2-url-checker/)

**Services:** Amazon EC2, Amazon S3, AWS Systems Manager (Session Manager), IAM

**Description:** Deploy a Python URL checker application on EC2 using Amazon Linux 2023, demonstrating the baseline manual deployment approach. This lab serves as the foundation for comparing more advanced deployment methods like serverless (Lambda), containerization (Docker/ECS), and orchestration (Fargate/EKS).

**Key Technologies:** Python 3.11, pip, Amazon Linux 2023, requests library, tabulate library

**Complexity:** Basic | **Time:** 25-35 minutes

**Key Learnings:**
- Manual EC2 deployment and operational overhead
- Python environment setup on Amazon Linux 2023
- Session Manager for secure instance access without SSH
- Understanding infrastructure management responsibilities
- Comparison of EC2 vs serverless deployment models
- Security group configuration for outbound traffic
- IAM instance profiles for AWS service access

---

### [Applying Key Lambda Functions to Applications (URL Checker)](./lambda-url-checker/)

**Services:** AWS Lambda, S3, CloudWatch, IAM

**Description:** Build a serverless URL health checker using AWS Lambda with Python 3.13. Demonstrates the serverless paradigm shift from traditional EC2 deployments, including deployment packaging with external dependencies, IAM execution roles, and CloudWatch logging integration.

**Key Technologies:** Python 3.13, requests library, AWS CLI, Lambda deployment packages

**Complexity:** Intermediate | **Time:** 45-60 minutes

**Key Learnings:**
- Serverless computing paradigm vs traditional EC2 deployment
- Lambda deployment packaging with external dependencies (requests library)
- Event-driven execution with JSON payloads
- IAM execution roles and least privilege permissions
- CloudWatch Logs integration for monitoring and debugging
- Cold start vs warm start performance characteristics
- Pay-per-execution pricing model and cost optimization
- Stateless function design patterns

---

### [Using Dockerfile with Amazon ECR (URL Checker)](./docker-ecr-url-checker/)

**Services:** Amazon EC2, Amazon ECR, AWS Systems Manager (Session Manager), IAM

**Description:** Containerize the URL checker application using Docker and Amazon Elastic Container Registry (ECR). This lab demonstrates the critical step from traditional deployments to containerized applications, achieving portability, consistency, and the foundation for orchestrated deployments with ECS, Fargate, and EKS.

**Key Technologies:** Docker, Dockerfile, Python 3.9, Amazon Linux 2023, container registries

**Complexity:** Intermediate | **Time:** 60-90 minutes

**Key Learnings:**
- Docker containerization concepts and benefits
- Writing Dockerfiles for Python applications
- Docker image layers and caching optimization
- Amazon ECR as a private container registry
- ECR authentication flow with AWS credentials
- Multi-instance deployment pattern with containers
- Container vs VM architecture comparison
- Image build, tag, push, and pull workflows
- Container portability across EC2 instances
- Foundation for ECS, Fargate, and EKS orchestration

---

### [Deploying Containers on AWS Fargate Using Amazon ECS and Amazon ECR](./fargate-ecs-deployment/)

**Services:** Amazon ECS, AWS Fargate, Amazon ECR, CloudWatch Logs, VPC, IAM

**Description:** Build, deploy, and run containerized applications using Amazon ECS, ECR, and Fargate. This lab demonstrates serverless container orchestration, bridging the gap between manual Docker deployments and full Kubernetes orchestration. Walk through setting up an ECS cluster, defining task definitions, and launching containers on Fargate—AWS's serverless compute engine that eliminates EC2 instance management.

**Key Technologies:** Amazon ECS, AWS Fargate, Task Definitions, ECS Services, CloudWatch Logs

**Complexity:** Intermediate | **Time:** 60 minutes

**Key Learnings:**
- ECS architecture (clusters, tasks, services, task definitions)
- Fargate serverless compute model (no EC2 management)
- Task definition authoring with CPU, memory, and container configuration
- ECS service creation with desired count and networking
- awsvpc network mode with ENI per task
- CloudWatch Logs integration for container output
- VPC networking with security groups and public IP assignment
- Task lifecycle management (PENDING → RUNNING → STOPPED)
- Comparison: ECS/Fargate vs EKS (when to use each)
- Serverless containers vs Lambda vs EC2 deployment models
- Cost optimization with Fargate pricing model

---

### [Deploying Containerized Applications to Amazon EKS](./eks-url-checker/)

**Services:** Amazon EKS, Amazon ECR, Amazon EC2, AWS Code Editor, VPC, IAM, CloudFormation

**Description:** Deploy containerized applications to Amazon Elastic Kubernetes Service (EKS), AWS's managed Kubernetes service. This lab represents the final and most advanced step in the deployment evolution series, demonstrating enterprise-grade container orchestration with Kubernetes on AWS. Covers cluster creation with eksctl, imperative and declarative deployment approaches, and Kubernetes Jobs for batch workloads.

**Key Technologies:** Kubernetes, kubectl, eksctl, Docker containers, YAML manifests

**Complexity:** Advanced | **Time:** 2-3 hours

**Key Learnings:**
- Kubernetes architecture and core concepts (pods, jobs, deployments, services)
- EKS managed control plane and worker node management
- kubectl and eksctl CLI tools for cluster operations
- Imperative vs declarative deployment approaches
- Kubernetes Jobs for run-to-completion workloads
- Managed node groups with Auto Scaling integration
- EKS integration with AWS services (IAM, VPC, ECR, CloudWatch)
- Kubernetes YAML manifest structure and best practices
- Container orchestration at scale with automatic scheduling
- High availability and multi-AZ deployment patterns
- Cost considerations for EKS (control plane + worker nodes)
- When to choose EKS vs ECS/Fargate vs simpler alternatives
