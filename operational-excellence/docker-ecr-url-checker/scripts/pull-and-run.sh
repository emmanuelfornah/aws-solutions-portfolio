#!/bin/bash

################################################################################
# ECR Pull and Run Script
#
# This script pulls the url-checker image from Amazon ECR and runs it.
# It demonstrates container portability by running the same image that was
# built on a different instance.
#
# Usage:
#   ./pull-and-run.sh <account-id> <region>
#
# Example:
#   ./pull-and-run.sh 123456789012 us-east-1
#
# Prerequisites:
# - Docker must be installed
# - AWS CLI must be installed and configured
# - IAM permissions for ECR pull operations
# - Image must exist in ECR repository
################################################################################

set -e  # Exit on any error

echo "========================================"
echo "Pulling and Running Container from ECR"
echo "========================================"
echo ""

# Check arguments
if [ $# -ne 2 ]; then
    echo "Error: Missing required arguments"
    echo ""
    echo "Usage: $0 <account-id> <region>"
    echo ""
    echo "Example:"
    echo "  $0 123456789012 us-east-1"
    echo ""
    exit 1
fi

ACCOUNT_ID=$1
REGION=$2
REPOSITORY_NAME="url-checker"
IMAGE_TAG="latest"

# Construct ECR repository URI
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
FULL_ECR_URI="${ECR_URI}/${REPOSITORY_NAME}:${IMAGE_TAG}"

echo "Configuration:"
echo "  Account ID: $ACCOUNT_ID"
echo "  Region: $REGION"
echo "  Repository: $REPOSITORY_NAME"
echo "  Image URI: $FULL_ECR_URI"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running or you don't have permission to access it."
    echo "Try running: newgrp docker"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed."
    echo "Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

echo "Step 1: Authenticating Docker with ECR..."
aws ecr get-login-password --region $REGION | \
    docker login --username AWS --password-stdin $ECR_URI

echo ""
echo "Step 2: Pulling image from ECR..."
docker pull $FULL_ECR_URI

echo ""
echo "Step 3: Verifying image..."
docker images $REPOSITORY_NAME

echo ""
echo "========================================"
echo "Pull Complete!"
echo "========================================"
echo ""

# Run the container with sample URLs
echo "Step 4: Running container with sample URLs..."
echo ""

docker run --rm $FULL_ECR_URI \
    https://aws.amazon.com \
    https://www.google.com \
    https://github.com

echo ""
echo "========================================"
echo "Container Execution Complete!"
echo "========================================"
echo ""
echo "The container ran successfully, demonstrating portability!"
echo ""
echo "To run with your own URLs:"
echo "  docker run --rm $FULL_ECR_URI https://example.com https://yoursite.com"
echo ""
echo "To run interactively:"
echo "  docker run -it --rm $FULL_ECR_URI /bin/bash"
echo ""
echo "To list running containers:"
echo "  docker ps"
echo ""
echo "To list all containers (including stopped):"
echo "  docker ps -a"
echo ""
echo "To remove the image:"
echo "  docker rmi $FULL_ECR_URI"
echo ""
