#!/bin/bash

# Imperative Pod Deployment Script
# This script demonstrates deploying a pod using kubectl run command
# Imperative approach is quick for testing but not recommended for production

# Configuration
CLUSTER_NAME="url-checker-cluster"
POD_NAME="url-checker"
ECR_IMAGE="<account-id>.dkr.ecr.us-east-1.amazonaws.com/url-checker:latest"

# URLs to check
URLS=(
  "https://aws.amazon.com"
  "https://kubernetes.io"
  "https://github.com"
  "https://stackoverflow.com"
)

echo "=========================================="
echo "Imperative Pod Deployment"
echo "=========================================="
echo ""

# Verify cluster connection
echo "Verifying cluster connection..."
if ! kubectl cluster-info &> /dev/null; then
  echo "Error: Cannot connect to cluster. Run: aws eks update-kubeconfig --name $CLUSTER_NAME"
  exit 1
fi
echo "✓ Connected to cluster"
echo ""

# Replace placeholder in image URI
echo "Enter your AWS Account ID:"
read -r ACCOUNT_ID
ECR_IMAGE="${ECR_IMAGE/<account-id>/$ACCOUNT_ID}"

echo "Using image: $ECR_IMAGE"
echo ""

# Create pod imperatively
echo "Creating pod '$POD_NAME' using kubectl run..."
kubectl run "$POD_NAME" \
  --image="$ECR_IMAGE" \
  --restart=Never \
  --command -- python url_checker.py "${URLS[@]}"

if [ $? -eq 0 ]; then
  echo "✓ Pod created successfully"
else
  echo "✗ Failed to create pod"
  exit 1
fi
echo ""

# Wait for pod to complete
echo "Waiting for pod to complete..."
kubectl wait --for=condition=Ready pod/"$POD_NAME" --timeout=60s 2>/dev/null || true

# Give it a moment to run
sleep 5

# Check pod status
echo ""
echo "Pod status:"
kubectl get pod "$POD_NAME"
echo ""

# View pod logs
echo "=========================================="
echo "Pod Logs:"
echo "=========================================="
kubectl logs "$POD_NAME"
echo ""

# Describe pod for details
echo "=========================================="
echo "Pod Details:"
echo "=========================================="
kubectl describe pod "$POD_NAME"
echo ""

# Cleanup prompt
echo "=========================================="
echo "Cleanup"
echo "=========================================="
echo "To delete the pod, run:"
echo "  kubectl delete pod $POD_NAME"
echo ""
echo "Or run this script with 'cleanup' argument:"
echo "  $0 cleanup"

# Handle cleanup argument
if [ "$1" == "cleanup" ]; then
  echo ""
  echo "Deleting pod..."
  kubectl delete pod "$POD_NAME"
  echo "✓ Pod deleted"
fi
