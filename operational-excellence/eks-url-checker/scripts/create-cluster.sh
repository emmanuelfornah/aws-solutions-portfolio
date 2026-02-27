#!/bin/bash

# Create Amazon EKS Cluster with Managed Node Group
# This script creates a production-ready EKS cluster using eksctl

set -e  # Exit on error

# Configuration
CLUSTER_NAME="url-checker-cluster"
REGION="us-east-1"
NODE_TYPE="t3.medium"
NODES_MIN=1
NODES_DESIRED=3
NODES_MAX=4
NODEGROUP_NAME="standard-workers"

echo "=========================================="
echo "Amazon EKS Cluster Creation"
echo "=========================================="
echo ""

# Verify prerequisites
echo "Verifying prerequisites..."
echo ""

# Check eksctl
if ! command -v eksctl &> /dev/null; then
  echo "✗ eksctl is not installed"
  echo "Run: ./install-tools.sh"
  exit 1
fi
echo "✓ eksctl is installed: $(eksctl version)"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
  echo "✗ kubectl is not installed"
  echo "Run: ./install-tools.sh"
  exit 1
fi
echo "✓ kubectl is installed"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
  echo "✗ AWS CLI is not installed"
  exit 1
fi
echo "✓ AWS CLI is installed"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
  echo "✗ AWS credentials are not configured"
  echo "Run: aws configure"
  exit 1
fi
echo "✓ AWS credentials are configured"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "  Account ID: $ACCOUNT_ID"

echo ""

# Display cluster configuration
echo "=========================================="
echo "Cluster Configuration"
echo "=========================================="
echo ""
echo "Cluster Name:       $CLUSTER_NAME"
echo "Region:             $REGION"
echo "Node Type:          $NODE_TYPE"
echo "Node Count:         $NODES_DESIRED (min: $NODES_MIN, max: $NODES_MAX)"
echo "Node Group Name:    $NODEGROUP_NAME"
echo ""

# Confirm creation
read -p "Create cluster with this configuration? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cluster creation cancelled"
  exit 0
fi

echo ""

# Check if cluster already exists
echo "Checking for existing cluster..."
if eksctl get cluster --name "$CLUSTER_NAME" --region "$REGION" &> /dev/null; then
  echo "✗ Cluster '$CLUSTER_NAME' already exists in region '$REGION'"
  echo ""
  read -p "Delete existing cluster and recreate? (y/n): " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deleting existing cluster..."
    eksctl delete cluster --name "$CLUSTER_NAME" --region "$REGION" --wait
    echo "✓ Cluster deleted"
  else
    echo "Using existing cluster"
    exit 0
  fi
fi

echo ""

# Create cluster
echo "=========================================="
echo "Creating EKS Cluster"
echo "=========================================="
echo ""
echo "This will take approximately 15-20 minutes..."
echo "Creating:"
echo "  • EKS control plane (multi-AZ, highly available)"
echo "  • VPC with public and private subnets"
echo "  • Managed node group with $NODES_DESIRED EC2 instances"
echo "  • IAM roles and security groups"
echo "  • CloudFormation stacks"
echo ""

START_TIME=$(date +%s)

eksctl create cluster \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  --nodegroup-name "$NODEGROUP_NAME" \
  --node-type "$NODE_TYPE" \
  --nodes "$NODES_DESIRED" \
  --nodes-min "$NODES_MIN" \
  --nodes-max "$NODES_MAX" \
  --managed \
  --with-oidc \
  --ssh-access=false \
  --external-dns-access \
  --full-ecr-access \
  --appmesh-access \
  --alb-ingress-access

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "✓ Cluster created successfully in ${MINUTES}m ${SECONDS}s"
echo ""

# Verify cluster
echo "=========================================="
echo "Verifying Cluster"
echo "=========================================="
echo ""

# Update kubeconfig
echo "Updating kubeconfig..."
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"
echo "✓ kubeconfig updated"
echo ""

# Get cluster info
echo "Cluster information:"
kubectl cluster-info
echo ""

# List nodes
echo "Cluster nodes:"
kubectl get nodes -o wide
echo ""

# Get node count
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
echo "✓ $NODE_COUNT nodes are ready"
echo ""

# Display cluster details
echo "=========================================="
echo "Cluster Details"
echo "=========================================="
echo ""

eksctl get cluster --name "$CLUSTER_NAME" --region "$REGION"
echo ""

eksctl get nodegroup --cluster "$CLUSTER_NAME" --region "$REGION"
echo ""

# Display next steps
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Verify cluster access:"
echo "   kubectl get nodes"
echo "   kubectl get pods --all-namespaces"
echo ""
echo "2. Deploy applications:"
echo "   ./deploy-imperative.sh"
echo "   ./deploy-declarative.sh"
echo ""
echo "3. View cluster in AWS Console:"
echo "   https://console.aws.amazon.com/eks/home?region=$REGION#/clusters/$CLUSTER_NAME"
echo ""
echo "4. Monitor costs:"
echo "   • Control plane: \$0.10/hour (~\$73/month)"
echo "   • Worker nodes: $NODES_DESIRED x $NODE_TYPE instances"
echo ""
echo "5. When finished, delete cluster to avoid charges:"
echo "   eksctl delete cluster --name $CLUSTER_NAME --region $REGION"
echo ""

# Save cluster info
CLUSTER_INFO_FILE="cluster-info.txt"
cat > "$CLUSTER_INFO_FILE" << EOF
EKS Cluster Information
=======================

Cluster Name: $CLUSTER_NAME
Region: $REGION
Created: $(date)
Account ID: $ACCOUNT_ID

Node Configuration:
- Node Type: $NODE_TYPE
- Node Count: $NODES_DESIRED (min: $NODES_MIN, max: $NODES_MAX)
- Node Group: $NODEGROUP_NAME

Access:
- Update kubeconfig: aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION
- View in console: https://console.aws.amazon.com/eks/home?region=$REGION#/clusters/$CLUSTER_NAME

Cleanup:
- Delete cluster: eksctl delete cluster --name $CLUSTER_NAME --region $REGION
EOF

echo "Cluster information saved to: $CLUSTER_INFO_FILE"
echo ""
