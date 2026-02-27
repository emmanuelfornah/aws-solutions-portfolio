#!/bin/bash

# Deploy URL Checker using Declarative kubectl apply
# This script demonstrates the declarative approach to Kubernetes deployments

set -e  # Exit on error

# Configuration
CLUSTER_NAME="url-checker-cluster"
REGION="us-east-1"
JOB_MANIFEST="../kubernetes/job.yaml"
JOB_NAME="url-checker-job"

echo "=========================================="
echo "Declarative Deployment with kubectl apply"
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

# Check manifest file exists
if [ ! -f "$JOB_MANIFEST" ]; then
  echo "✗ Job manifest not found: $JOB_MANIFEST"
  exit 1
fi
echo "✓ Job manifest found: $JOB_MANIFEST"

echo ""

# Get ECR repository URI
echo "Preparing manifest..."
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

# Create temporary manifest with actual ECR URI
TEMP_MANIFEST="/tmp/job-$(date +%s).yaml"
sed "s|<account-id>|$ACCOUNT_ID|g" "$JOB_MANIFEST" > "$TEMP_MANIFEST"

echo "Manifest prepared with ECR URI: $ECR_URI"
echo ""

# Display manifest
echo "=========================================="
echo "Job Manifest"
echo "=========================================="
echo ""
cat "$TEMP_MANIFEST"
echo ""

# Check if job already exists
if kubectl get job "$JOB_NAME" &> /dev/null; then
  echo "Job '$JOB_NAME' already exists"
  echo ""
  read -p "Delete existing job and recreate? (y/n): " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deleting existing job..."
    kubectl delete job "$JOB_NAME" --wait=true
    echo "✓ Job deleted"
    echo ""
  else
    echo "Using existing job"
    kubectl get job "$JOB_NAME"
    exit 0
  fi
fi

# Apply manifest
echo "=========================================="
echo "Applying Manifest"
echo "=========================================="
echo ""
echo "Running: kubectl apply -f $TEMP_MANIFEST"
echo ""

kubectl apply -f "$TEMP_MANIFEST"

if [ $? -eq 0 ]; then
  echo "✓ Job created successfully"
else
  echo "✗ Failed to create job"
  rm -f "$TEMP_MANIFEST"
  exit 1
fi

echo ""

# Wait for job to create pod
echo "Waiting for job to create pod..."
sleep 3

# Monitor job status
echo ""
echo "=========================================="
echo "Job Status"
echo "=========================================="
echo ""

# Show job status
kubectl get job "$JOB_NAME"
echo ""

# Show pods created by job
echo "Pods created by job:"
kubectl get pods --selector=job-name="$JOB_NAME"
echo ""

# Get pod name
POD_NAME=$(kubectl get pods --selector=job-name="$JOB_NAME" -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
  echo "✗ No pod found for job"
  kubectl describe job "$JOB_NAME"
  rm -f "$TEMP_MANIFEST"
  exit 1
fi

echo "Pod name: $POD_NAME"
echo ""

# Wait for pod to complete (timeout after 60 seconds)
echo "Waiting for pod to complete (timeout: 60s)..."
kubectl wait --for=condition=Ready pod/"$POD_NAME" --timeout=60s 2>/dev/null || true

# Give it a moment to run
sleep 5

# Check job completion
JOB_STATUS=$(kubectl get job "$JOB_NAME" -o jsonpath='{.status.conditions[0].type}')
echo ""
echo "Job status: $JOB_STATUS"
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

# Show job details
echo "=========================================="
echo "Job Details"
echo "=========================================="
echo ""

kubectl describe job "$JOB_NAME"
echo ""

# Show pod details
echo "=========================================="
echo "Pod Details"
echo "=========================================="
echo ""

kubectl describe pod "$POD_NAME"
echo ""

# Declarative approach benefits
echo "=========================================="
echo "Declarative Approach Benefits"
echo "=========================================="
echo ""
echo "✓ Reproducible: Same manifest produces same result"
echo "✓ Version Control: Manifest can be committed to Git"
echo "✓ Infrastructure as Code: Declarative configuration"
echo "✓ Auditable: Changes tracked in version control"
echo "✓ GitOps Ready: Can be automated with CI/CD"
echo ""
echo "The manifest file (job.yaml) can be:"
echo "  • Stored in Git for version control"
echo "  • Reviewed in pull requests"
echo "  • Applied automatically in CI/CD pipelines"
echo "  • Modified and reapplied for updates"
echo ""

# Kubernetes Job features
echo "=========================================="
echo "Kubernetes Job Features"
echo "=========================================="
echo ""
echo "Jobs are designed for run-to-completion workloads:"
echo "  • Ensures pods run to successful completion"
echo "  • Retries on failure (backoffLimit: 3)"
echo "  • Automatic cleanup (ttlSecondsAfterFinished: 3600)"
echo "  • Parallel execution support"
echo "  • CronJob integration for scheduled tasks"
echo ""
echo "Job vs Pod:"
echo "  • Job: Managed, retries on failure, tracks completion"
echo "  • Pod: Unmanaged, no automatic retries"
echo ""

# Cleanup options
echo "=========================================="
echo "Cleanup"
echo "=========================================="
echo ""
echo "To view job status:"
echo "  kubectl get job $JOB_NAME"
echo ""
echo "To view pod logs:"
echo "  kubectl logs $POD_NAME"
echo "  kubectl logs job/$JOB_NAME"
echo ""
echo "To delete the job (and its pods):"
echo "  kubectl delete job $JOB_NAME"
echo "  kubectl delete -f $JOB_MANIFEST"
echo ""
echo "To view all jobs:"
echo "  kubectl get jobs"
echo ""

# Interactive cleanup
read -p "Delete job now? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Deleting job..."
  kubectl delete job "$JOB_NAME"
  echo "✓ Job deleted"
else
  echo "Job '$JOB_NAME' is still present"
  echo "Delete it manually when finished"
fi

# Cleanup temp manifest
rm -f "$TEMP_MANIFEST"

echo ""
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Modify the manifest to add more URLs"
echo "2. Create a Deployment for long-running services"
echo "3. Add a Service to expose the application"
echo "4. Implement Helm charts for package management"
echo "5. Set up CI/CD pipeline for automated deployments"
echo ""
