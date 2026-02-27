#!/bin/bash

# Deploy URL Checker using Imperative kubectl Commands
# This script demonstrates the imperative approach to Kubernetes deployments

set -e  # Exit on error

# Configuration
CLUSTER_NAME="url-checker-cluster"
REGION="us-east-1"
POD_NAME="url-checker-imperative"

echo "=========================================="
echo "Imperative Deployment with kubectl run"
echo "=========================================="
echo ""

# Verify prerequisites
echo "Verifying prerequisites..."
echo ""

# Check kubectl
if ! command -v kubectl &> /dev/null; then
  echo "✗ kubectl is not installed"
  echo "Run: ./install-tools.sh"
  exit 1
fi
echo "✓ kubectl is installed"

# Check cluster connection
if ! kubectl cluster-info &> /dev/null; then
  echo "✗ Cannot connect to cluster"
  echo "Run: aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION"
  exit 1
fi
echo "✓ Connected to cluster"

# Get cluster name
CURRENT_CLUSTER=$(kubectl config current-context)
echo "  Current context: $CURRENT_CLUSTER"

echo ""

# Get ECR repository URI
echo "Getting ECR repository information..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO="url-checker"
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO:latest"

# Verify ECR repository exists
if ! aws ecr describe-repositories --repository-names "$ECR_REPO" --region "$REGION" &> /dev/null; then
  echo "✗ ECR repository '$ECR_REPO' not found"
  echo "Create the repository and push the url-checker image first"
  echo "See: compute/docker-ecr-url-checker/README.md"
  exit 1
fi

echo "✓ ECR repository found: $ECR_URI"
echo ""

# URLs to check
URLS=(
  "https://aws.amazon.com"
  "https://kubernetes.io"
  "https://github.com"
  "https://stackoverflow.com"
  "https://reddit.com"
)

echo "=========================================="
echo "Deployment Configuration"
echo "=========================================="
echo ""
echo "Pod Name:     $POD_NAME"
echo "Image:        $ECR_URI"
echo "URLs to check:"
for url in "${URLS[@]}"; do
  echo "  • $url"
done
echo ""

# Check if pod already exists
if kubectl get pod "$POD_NAME" &> /dev/null; then
  echo "Pod '$POD_NAME' already exists"
  echo ""
  read -p "Delete existing pod and recreate? (y/n): " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deleting existing pod..."
    kubectl delete pod "$POD_NAME" --wait=true
    echo "✓ Pod deleted"
    echo ""
  else
    echo "Using existing pod"
    kubectl get pod "$POD_NAME"
    exit 0
  fi
fi

# Create pod imperatively
echo "=========================================="
echo "Creating Pod"
echo "=========================================="
echo ""
echo "Running: kubectl run $POD_NAME --image=$ECR_URI --restart=Never --command -- python url_checker.py ${URLS[*]}"
echo ""

kubectl run "$POD_NAME" \
  --image="$ECR_URI" \
  --restart=Never \
  --command -- python url_checker.py "${URLS[@]}"

if [ $? -eq 0 ]; then
  echo "✓ Pod created successfully"
else
  echo "✗ Failed to create pod"
  exit 1
fi

echo ""

# Wait for pod to be scheduled
echo "Waiting for pod to be scheduled..."
sleep 3

# Monitor pod status
echo ""
echo "=========================================="
echo "Pod Status"
echo "=========================================="
echo ""

# Show pod status
kubectl get pod "$POD_NAME"
echo ""

# Wait for pod to complete or fail (timeout after 60 seconds)
echo "Waiting for pod to complete (timeout: 60s)..."
kubectl wait --for=condition=Ready pod/"$POD_NAME" --timeout=60s 2>/dev/null || true

# Give it a moment to run
sleep 5

# Check final status
POD_STATUS=$(kubectl get pod "$POD_NAME" -o jsonpath='{.status.phase}')
echo ""
echo "Pod status: $POD_STATUS"
echo ""

# View pod logs
echo "=========================================="
echo "Pod Logs"
echo "=========================================="
echo ""

if kubectl logs "$POD_NAME" &> /dev/null; then
  kubectl logs "$POD_NAME"
else
  echo "No logs available yet or pod failed to start"
  echo ""
  echo "Describing pod for troubleshooting:"
  kubectl describe pod "$POD_NAME"
fi

echo ""

# Show pod details
echo "=========================================="
echo "Pod Details"
echo "=========================================="
echo ""

kubectl describe pod "$POD_NAME"
echo ""

# Show pod YAML
echo "=========================================="
echo "Pod YAML (Generated)"
echo "=========================================="
echo ""
echo "The imperative command generated this pod specification:"
echo ""

kubectl get pod "$POD_NAME" -o yaml
echo ""

# Comparison with declarative approach
echo "=========================================="
echo "Imperative vs Declarative"
echo "=========================================="
echo ""
echo "Imperative Approach (what you just did):"
echo "  ✓ Quick and simple"
echo "  ✓ Good for testing and debugging"
echo "  ✗ Not reproducible"
echo "  ✗ No version control"
echo "  ✗ Hard to manage at scale"
echo ""
echo "Declarative Approach (recommended for production):"
echo "  ✓ Reproducible and version-controlled"
echo "  ✓ Infrastructure as code"
echo "  ✓ Easy to review and audit"
echo "  ✓ Supports GitOps workflows"
echo ""
echo "Try the declarative approach:"
echo "  ./deploy-declarative.sh"
echo ""

# Cleanup options
echo "=========================================="
echo "Cleanup"
echo "=========================================="
echo ""
echo "To view pod logs again:"
echo "  kubectl logs $POD_NAME"
echo ""
echo "To delete the pod:"
echo "  kubectl delete pod $POD_NAME"
echo ""
echo "To delete all pods:"
echo "  kubectl delete pods --all"
echo ""

# Interactive cleanup
read -p "Delete pod now? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Deleting pod..."
  kubectl delete pod "$POD_NAME"
  echo "✓ Pod deleted"
else
  echo "Pod '$POD_NAME' is still running"
  echo "Delete it manually when finished"
fi

echo ""
