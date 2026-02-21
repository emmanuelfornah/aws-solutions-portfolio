# Amazon EKS Architecture

## Overview

This document provides a comprehensive architectural overview of Amazon Elastic Kubernetes Service (EKS) and how it orchestrates containerized applications. EKS represents the most advanced deployment option in the evolution series, offering enterprise-grade container orchestration with Kubernetes on AWS.

## What is Amazon EKS?

Amazon EKS is a managed Kubernetes service that eliminates the complexity of running Kubernetes control planes. AWS handles:
- Control plane provisioning and scaling
- High availability across multiple availability zones
- Automatic version upgrades and patching
- Integration with AWS services (IAM, VPC, ECR, CloudWatch)
- Security and compliance certifications

You focus on deploying and managing applications while AWS manages the Kubernetes infrastructure.

## EKS Architecture Components

### 1. Control Plane (Managed by AWS)

The Kubernetes control plane consists of multiple components that manage the cluster:

**API Server**
- Entry point for all cluster operations
- Processes kubectl commands and API requests
- Authenticates and authorizes requests via IAM
- Validates and persists cluster state to etcd

**etcd**
- Distributed key-value store for cluster state
- Stores all cluster configuration and resource definitions
- Highly available across multiple availability zones
- Automatically backed up by AWS

**Scheduler**
- Assigns pods to worker nodes
- Considers resource requirements, constraints, and policies
- Optimizes for resource utilization and availability

**Controller Manager**
- Runs controller processes that regulate cluster state
- Node controller: Monitors node health
- Replication controller: Maintains desired pod replicas
- Endpoints controller: Populates service endpoints
- Service account controller: Creates default accounts

**Cloud Controller Manager**
- Integrates Kubernetes with AWS APIs
- Manages AWS load balancers for Services
- Provisions EBS volumes for PersistentVolumes
- Updates node metadata from EC2 API

### 2. Data Plane (Worker Nodes)

Worker nodes run containerized applications. EKS supports three node types:

**Managed Node Groups** (Used in this lab)
- AWS manages EC2 instance lifecycle
- Automatic updates and patching
- Integration with Auto Scaling groups
- Simplified node management
- Recommended for most workloads

**Self-Managed Nodes**
- Full control over EC2 configuration
- Custom AMIs and instance types
- More operational overhead
- Use for specialized requirements

**AWS Fargate**
- Serverless compute for pods
- No node management required
- Pay per pod resource usage
- Ideal for batch jobs and variable workloads

### 3. Node Components

Each worker node runs these Kubernetes components:

**kubelet**
- Primary node agent that communicates with API server
- Ensures containers are running in pods
- Pulls container images from ECR
- Reports node and pod status
- Executes pod lifecycle hooks

**kube-proxy**
- Network proxy that maintains network rules
- Implements Kubernetes Service abstraction
- Forwards traffic to appropriate pods
- Supports multiple load balancing modes

**Container Runtime**
- Runs containers (Docker, containerd, CRI-O)
- EKS uses containerd by default
- Manages container lifecycle
- Implements Container Runtime Interface (CRI)

**AWS VPC CNI Plugin**
- Provides native VPC networking for pods
- Assigns VPC IP addresses to pods
- Enables pod-to-pod communication
- Supports security groups for pods

## Kubernetes Resource Types

### Pods

The smallest deployable unit in Kubernetes. A pod:
- Contains one or more containers
- Shares network namespace (IP address, ports)
- Shares storage volumes
- Is ephemeral and disposable
- Scheduled as a unit on a single node

**Pod Lifecycle:**
1. Pending: Accepted but not yet scheduled
2. Running: Bound to node, containers running
3. Succeeded: All containers completed successfully
4. Failed: At least one container failed
5. Unknown: Pod state cannot be determined

### Jobs

Controllers that create pods for run-to-completion tasks. Jobs:
- Ensure pods run to successful completion
- Retry on failure (configurable backoffLimit)
- Support parallel execution
- Automatically clean up completed pods (ttlSecondsAfterFinished)
- Track completion status

**Use Cases:**
- Batch processing
- Data transformations
- Database migrations
- Report generation
- One-time tasks

### Deployments

Controllers for stateless applications. Deployments:
- Manage ReplicaSets
- Provide rolling updates
- Support rollback to previous versions
- Ensure desired number of replicas
- Self-healing (restart failed pods)

**Use Cases:**
- Web applications
- API services
- Microservices
- Stateless workers

### Services

Abstractions that expose applications. Services:
- Provide stable networking endpoints
- Load balance across pod replicas
- Support service discovery
- Enable pod-to-pod communication

**Service Types:**
- **ClusterIP**: Internal cluster access only (default)
- **NodePort**: Exposes service on each node's IP
- **LoadBalancer**: Provisions AWS ELB/ALB/NLB
- **ExternalName**: Maps to external DNS name

### ConfigMaps and Secrets

Configuration management resources:

**ConfigMaps:**
- Store non-sensitive configuration data
- Key-value pairs or file content
- Injected as environment variables or volumes
- Decouples configuration from container images

**Secrets:**
- Store sensitive data (passwords, tokens, keys)
- Base64 encoded (not encrypted by default)
- Integrate with AWS Secrets Manager
- Mounted as volumes or environment variables

### Namespaces

Virtual clusters within a physical cluster:
- Logical isolation for resources
- Resource quotas and limits
- RBAC policies per namespace
- Multi-tenancy support

**Default Namespaces:**
- `default`: Default namespace for resources
- `kube-system`: Kubernetes system components
- `kube-public`: Publicly accessible resources
- `kube-node-lease`: Node heartbeat data

## EKS Networking Architecture

### VPC Integration

EKS clusters run within your VPC:
- Control plane ENIs in your VPC subnets
- Worker nodes in public or private subnets
- Security groups control traffic
- Network ACLs provide subnet-level filtering

**Recommended VPC Design:**
- Public subnets: Load balancers, NAT gateways
- Private subnets: Worker nodes, pods
- Multiple availability zones for high availability
- Separate subnets for control plane ENIs

### Pod Networking (AWS VPC CNI)

EKS uses AWS VPC CNI plugin for pod networking:
- Pods receive VPC IP addresses
- Pods communicate directly with VPC resources
- No overlay network required
- Native VPC routing and security

**IP Address Management:**
- Each node has primary ENI with primary IP
- Secondary IPs allocated to pods
- IP addresses from VPC CIDR range
- Plan VPC CIDR for pod density

**Benefits:**
- Native VPC performance
- Security groups for pods
- VPC Flow Logs for pod traffic
- Direct communication with RDS, ElastiCache, etc.

### Service Networking

Services use virtual IPs (ClusterIP) from service CIDR:
- Separate from VPC CIDR
- kube-proxy implements service routing
- iptables or IPVS mode
- Load balancing across pod endpoints

## IAM and Security

### Authentication

EKS uses AWS IAM for cluster authentication:
- IAM users and roles authenticate to API server
- aws-iam-authenticator generates tokens
- kubectl uses AWS credentials
- No separate Kubernetes credentials needed

**Authentication Flow:**
1. kubectl sends request with AWS credentials
2. aws-iam-authenticator validates credentials
3. IAM identity mapped to Kubernetes user/group
4. API server authorizes request via RBAC

### Authorization (RBAC)

Kubernetes Role-Based Access Control:
- Roles define permissions (verbs on resources)
- RoleBindings assign roles to users/groups
- ClusterRoles for cluster-wide permissions
- ClusterRoleBindings for cluster-wide assignments

**Common Roles:**
- `cluster-admin`: Full cluster access
- `admin`: Namespace admin access
- `edit`: Read/write access to resources
- `view`: Read-only access

### Pod Security

**Security Context:**
- Run as non-root user
- Read-only root filesystem
- Drop unnecessary capabilities
- Set resource limits

**Pod Security Standards:**
- Privileged: Unrestricted
- Baseline: Minimally restrictive
- Restricted: Heavily restricted (recommended)

**Network Policies:**
- Control pod-to-pod traffic
- Ingress and egress rules
- Label-based selection
- Requires CNI plugin support

### IAM Roles for Service Accounts (IRSA)

Fine-grained IAM permissions for pods:
- Pods assume IAM roles
- No node-level IAM credentials needed
- Temporary credentials via STS
- Audit trail in CloudTrail

**Setup:**
1. Create OIDC provider for cluster
2. Create IAM role with trust policy
3. Annotate Kubernetes ServiceAccount
4. Pods use ServiceAccount to assume role

## Storage in EKS

### Persistent Volumes

Kubernetes abstracts storage with PersistentVolumes (PV):
- PV: Cluster-level storage resource
- PVC: User request for storage
- StorageClass: Dynamic provisioning template

**AWS Storage Options:**
- **EBS**: Block storage for single-node access
- **EFS**: File storage for multi-node access
- **FSx for Lustre**: High-performance computing
- **FSx for NetApp ONTAP**: Enterprise file storage

### EBS CSI Driver

Container Storage Interface driver for EBS:
- Dynamic volume provisioning
- Volume snapshots and restore
- Volume resizing
- Topology-aware scheduling

**Volume Types:**
- gp3/gp2: General purpose SSD
- io2/io1: Provisioned IOPS SSD
- st1: Throughput optimized HDD
- sc1: Cold HDD

### EFS CSI Driver

CSI driver for EFS:
- Shared storage across pods
- Multi-AZ access
- Automatic scaling
- No capacity planning

## Scaling in EKS

### Horizontal Pod Autoscaler (HPA)

Automatically scales pod replicas based on metrics:
- CPU utilization
- Memory utilization
- Custom metrics (from CloudWatch, Prometheus)
- External metrics

**Configuration:**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Vertical Pod Autoscaler (VPA)

Adjusts pod resource requests and limits:
- Recommends optimal resource values
- Automatically updates pod resources
- Prevents resource waste
- Improves cluster utilization

### Cluster Autoscaler

Automatically adjusts node count:
- Scales up when pods can't be scheduled
- Scales down when nodes are underutilized
- Integrates with Auto Scaling groups
- Respects pod disruption budgets

**How it works:**
1. Pods pending due to insufficient resources
2. Cluster Autoscaler detects pending pods
3. Adds nodes to Auto Scaling group
4. Pods scheduled on new nodes

### Karpenter (Advanced)

Modern node autoscaling alternative:
- Faster scaling than Cluster Autoscaler
- Provisions right-sized nodes
- Supports diverse instance types
- Consolidates underutilized nodes
- Direct EC2 API integration

## Monitoring and Logging

### CloudWatch Container Insights

Native AWS monitoring for EKS:
- Cluster, node, and pod metrics
- Performance dashboards
- Automatic metric collection
- Integration with CloudWatch Logs

**Metrics Collected:**
- CPU and memory utilization
- Network traffic
- Disk I/O
- Pod and container counts

### Control Plane Logging

EKS can send control plane logs to CloudWatch:
- API server logs
- Audit logs
- Authenticator logs
- Controller manager logs
- Scheduler logs

**Enable logging:**
```bash
eksctl utils update-cluster-logging \
  --cluster=my-cluster \
  --enable-types=all \
  --approve
```

### Application Logging

Options for application logs:
- **Fluent Bit**: Lightweight log forwarder
- **Fluentd**: Feature-rich log aggregator
- **CloudWatch Logs**: Native AWS integration
- **Elasticsearch**: Full-text search and analytics

### Prometheus and Grafana

Popular open-source monitoring stack:
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Alertmanager**: Alert routing and management
- **Node Exporter**: Node-level metrics
- **kube-state-metrics**: Kubernetes object metrics

## EKS vs Self-Managed Kubernetes

### EKS Advantages

**Managed Control Plane:**
- AWS handles provisioning, scaling, patching
- Multi-AZ high availability
- Automatic version upgrades
- No control plane management overhead

**AWS Integration:**
- Native IAM authentication
- VPC networking for pods
- ECR image registry
- CloudWatch monitoring
- ELB/ALB/NLB load balancers
- EBS/EFS storage

**Security and Compliance:**
- SOC, PCI, HIPAA, ISO certifications
- Encrypted etcd
- Envelope encryption for secrets
- AWS security best practices

**Support:**
- AWS Support plans
- Kubernetes version support
- Security patches and updates

### Self-Managed Considerations

**When to self-manage:**
- Need specific Kubernetes version
- Custom control plane configuration
- On-premises or hybrid cloud
- Cost optimization (no control plane fee)
- Full control over all components

**Challenges:**
- Control plane high availability
- Upgrade management
- Security patching
- Monitoring and troubleshooting
- Operational complexity

## EKS vs ECS/Fargate

### Comparison Matrix

| Aspect | EKS | ECS/Fargate |
|--------|-----|-------------|
| **Orchestrator** | Kubernetes (open source) | AWS proprietary |
| **Portability** | Multi-cloud, on-premises | AWS-only |
| **Learning Curve** | Steep (Kubernetes complexity) | Moderate (AWS-specific) |
| **Ecosystem** | Vast (CNCF landscape) | AWS-focused |
| **Control Plane Cost** | $0.10/hour (~$73/month) | Free |
| **Tooling** | kubectl, Helm, Kustomize | AWS CLI, CloudFormation |
| **Community** | Large global community | AWS community |
| **Maturity** | Very mature (2014) | Mature (2015) |
| **Complexity** | High | Low to moderate |
| **Flexibility** | Extremely flexible | Opinionated |

### When to Choose EKS

**Choose EKS when you need:**
- Kubernetes ecosystem and tooling
- Multi-cloud or hybrid cloud strategy
- Existing Kubernetes expertise
- Complex orchestration requirements
- Service mesh (Istio, Linkerd, App Mesh)
- Advanced networking (network policies)
- GitOps workflows (Flux, ArgoCD)
- Helm charts and operators
- Portability across clouds

### When to Choose ECS/Fargate

**Choose ECS when you need:**
- Simpler AWS-native solution
- Lower operational overhead
- No control plane costs
- Tight AWS service integration
- Faster time to production
- Smaller team without Kubernetes expertise
- AWS-only deployment strategy

## Imperative vs Declarative Management

### Imperative Approach

**Commands:**
- `kubectl run`: Create pod
- `kubectl create`: Create resource
- `kubectl expose`: Create service
- `kubectl scale`: Scale deployment
- `kubectl delete`: Delete resource

**Characteristics:**
- Direct commands to API server
- Immediate execution
- No configuration files
- Not reproducible
- Hard to track changes

**Use Cases:**
- Quick testing and debugging
- One-off tasks
- Learning and experimentation
- Troubleshooting

**Example:**
```bash
kubectl run nginx --image=nginx:latest --port=80
kubectl expose pod nginx --type=LoadBalancer
kubectl scale deployment nginx --replicas=3
```

### Declarative Approach

**Commands:**
- `kubectl apply -f manifest.yaml`: Create or update resources
- `kubectl diff -f manifest.yaml`: Preview changes
- `kubectl delete -f manifest.yaml`: Delete resources

**Characteristics:**
- Define desired state in YAML/JSON
- Infrastructure as code
- Version controlled
- Reproducible
- Auditable

**Use Cases:**
- Production deployments
- GitOps workflows
- Team collaboration
- Compliance and auditing
- CI/CD pipelines

**Example:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

### Best Practices

**Production Workloads:**
- Always use declarative manifests
- Store manifests in Git
- Use GitOps tools (Flux, ArgoCD)
- Implement CI/CD pipelines
- Review changes in pull requests

**Development and Testing:**
- Imperative commands for quick tests
- Declarative manifests for reproducibility
- Use namespaces for isolation
- Clean up resources after testing

## kubectl and eksctl Roles

### kubectl

**Purpose:** Kubernetes cluster management

**Capabilities:**
- Interact with Kubernetes API
- Manage workloads (pods, deployments, services)
- View logs and events
- Execute commands in containers
- Port forwarding and proxying
- Apply manifests

**Works with:**
- Any Kubernetes cluster (EKS, GKE, AKS, on-premises)
- Multiple clusters via kubeconfig contexts

**Common Commands:**
```bash
kubectl get pods
kubectl describe deployment app
kubectl logs pod-name
kubectl exec -it pod-name -- /bin/bash
kubectl apply -f manifest.yaml
kubectl port-forward pod-name 8080:80
```

### eksctl

**Purpose:** EKS cluster lifecycle management

**Capabilities:**
- Create and delete EKS clusters
- Manage node groups
- Update cluster configuration
- Enable add-ons (VPC CNI, CoreDNS)
- Configure IAM and OIDC
- Manage cluster logging

**EKS-specific:**
- Only works with Amazon EKS
- Uses CloudFormation under the hood
- Simplifies complex EKS operations

**Common Commands:**
```bash
eksctl create cluster --name my-cluster
eksctl get cluster
eksctl create nodegroup --cluster my-cluster
eksctl scale nodegroup --cluster my-cluster --name ng-1 --nodes 5
eksctl delete cluster --name my-cluster
```

## Advanced EKS Features

### Service Mesh

Service mesh provides advanced networking capabilities:

**AWS App Mesh:**
- AWS-managed service mesh
- Traffic routing and load balancing
- Circuit breaking and retries
- Observability and tracing
- mTLS encryption

**Istio:**
- Open-source service mesh
- Rich feature set
- Large community
- Complex to operate

**Linkerd:**
- Lightweight service mesh
- Simple to deploy
- Good performance
- Smaller feature set

### GitOps

Declarative continuous delivery:

**Flux:**
- CNCF project
- Git as source of truth
- Automatic synchronization
- Helm support

**ArgoCD:**
- Declarative GitOps
- Web UI for visualization
- Multi-cluster support
- RBAC and SSO

### Helm

Kubernetes package manager:
- Package applications as charts
- Templating and parameterization
- Version management
- Dependency management
- Rollback support

**Example:**
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-nginx bitnami/nginx
helm upgrade my-nginx bitnami/nginx
helm rollback my-nginx 1
```

### Operators

Kubernetes operators extend functionality:
- Custom Resource Definitions (CRDs)
- Custom controllers
- Automate complex operations
- Manage stateful applications

**Examples:**
- Prometheus Operator
- MySQL Operator
- Kafka Operator
- Cert-Manager

### Multi-Tenancy

Isolate workloads in shared clusters:
- Namespaces for logical isolation
- Resource quotas and limits
- Network policies
- RBAC for access control
- Pod security policies

## Cost Optimization

### Control Plane Costs

- $0.10/hour per cluster (~$73/month)
- Consider cluster consolidation
- Use namespaces for multi-tenancy
- Evaluate ECS for simpler workloads

### Worker Node Costs

**Instance Selection:**
- Right-size instance types
- Use Spot instances for fault-tolerant workloads
- Mix on-demand and Spot instances
- Consider Graviton instances (ARM)

**Autoscaling:**
- Cluster Autoscaler for dynamic scaling
- Scale down during off-hours
- Set appropriate min/max node counts
- Use Karpenter for efficient provisioning

**Fargate:**
- Pay per pod resource usage
- No idle node costs
- Good for variable workloads
- Higher per-resource cost than EC2

### Resource Optimization

- Set resource requests and limits
- Use Vertical Pod Autoscaler
- Implement pod disruption budgets
- Consolidate underutilized nodes
- Use namespace resource quotas

## High Availability and Disaster Recovery

### Control Plane HA

EKS control plane is highly available by default:
- Multiple API server instances
- etcd replicated across 3 AZs
- Automatic failover
- No single point of failure

### Worker Node HA

Design for high availability:
- Deploy nodes across multiple AZs
- Use managed node groups
- Set appropriate min node count
- Implement pod disruption budgets
- Use anti-affinity rules

### Application HA

**Deployment Strategies:**
- Multiple pod replicas
- Pod anti-affinity (spread across nodes/AZs)
- Readiness and liveness probes
- Graceful shutdown handling
- Circuit breakers and retries

**Example:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 3
  template:
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: app
              topologyKey: topology.kubernetes.io/zone
```

### Backup and Recovery

**Cluster Backup:**
- Velero for cluster backup
- Backup etcd snapshots
- Export resource manifests
- Store in S3 or Git

**Disaster Recovery:**
- Multi-region clusters
- Cross-region replication
- Infrastructure as code (recreate clusters)
- Regular DR testing

## Security Best Practices

### Cluster Security

1. **Enable control plane logging**
2. **Use private API endpoint** (or restrict public access)
3. **Enable envelope encryption** for secrets
4. **Implement network policies**
5. **Use security groups for pods**
6. **Regular security updates** (node AMIs)
7. **Enable AWS GuardDuty** for EKS

### Pod Security

1. **Run as non-root user**
2. **Read-only root filesystem**
3. **Drop unnecessary capabilities**
4. **Set resource limits**
5. **Use security contexts**
6. **Scan images for vulnerabilities**
7. **Use minimal base images**

### Access Control

1. **Implement RBAC** with least privilege
2. **Use IAM roles for service accounts**
3. **Enable audit logging**
4. **Rotate credentials regularly**
5. **Use AWS SSO** for user access
6. **Implement pod security standards**

### Network Security

1. **Use private subnets** for worker nodes
2. **Implement network policies**
3. **Use security groups** for pod-level control
4. **Enable VPC Flow Logs**
5. **Use AWS WAF** for ingress protection
6. **Implement service mesh** for mTLS

## Troubleshooting Common Issues

### Pods Not Starting

**Check pod status:**
```bash
kubectl get pods
kubectl describe pod <pod-name>
```

**Common causes:**
- Image pull errors (ECR permissions)
- Insufficient resources
- Node selector mismatch
- Volume mount failures

### Node Issues

**Check node status:**
```bash
kubectl get nodes
kubectl describe node <node-name>
```

**Common causes:**
- IAM role issues
- Security group misconfiguration
- Subnet IP exhaustion
- Instance type limits

### Networking Issues

**Check service and endpoints:**
```bash
kubectl get svc
kubectl get endpoints
kubectl describe svc <service-name>
```

**Common causes:**
- Security group rules
- Network policy blocking traffic
- Service selector mismatch
- DNS resolution failures

## Conclusion

Amazon EKS provides enterprise-grade Kubernetes orchestration with deep AWS integration. It represents the most advanced deployment option in the evolution series, offering:

- **Flexibility**: Run any containerized workload
- **Scalability**: Horizontal and vertical scaling
- **Portability**: Kubernetes runs anywhere
- **Ecosystem**: Access to vast cloud-native tooling
- **Control**: Fine-grained configuration and policies

While EKS has a steeper learning curve than simpler alternatives like ECS or Elastic Beanstalk, it provides unmatched flexibility and control for complex, production-grade applications. The managed control plane eliminates operational overhead while maintaining full Kubernetes capabilities.

Choose EKS when you need Kubernetes ecosystem, multi-cloud portability, or complex orchestration requirements. For simpler AWS-native workloads, consider ECS or Elastic Beanstalk as more straightforward alternatives.
