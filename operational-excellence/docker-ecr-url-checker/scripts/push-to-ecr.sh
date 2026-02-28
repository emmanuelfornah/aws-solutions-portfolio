#!/bin/bash

################################################################################
# ECR Push Script
#
# This script authenticates Docker with Amazon ECR and pushes the url-checker
# image to an ECR repository.
#
# Usage:
#   ./push-to-ecr.sh <account-id> <region>
#
# Example:
#   ./push-to-ecr.sh 123456789012 us-east-1
#
# Prerequisites:
# - Docker image 'url-checker:latest' must be built
# - AWS CLI must be installed and configured
# - IAM permissions for ECR operations
# - ECR repository 'url-checker' must exist
################################################################################

set -e  # Exit on any error

echo "========================================"
echo "Pushing Docker Image to Amazon ECR"
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
echo "  ECR URI: $FULL_ECR_URI"
echo ""

# Check if Docker image exists
if ! docker images url-checker:latest | grep -q url-checker; then
    echo "Error: Docker image 'url-checker:latest' not found."
    echo "Please build the image first:"
    echo "  cd application/"
    echo "  ../scripts/build-image.sh"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed."
    echo "Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

# Check if ECR repository exists
echo "Step 1: Verifying ECR repository exists..."
if ! aws ecr describe-repositories --repository-names $REPOSITORY_NAME --region $REGION &> /dev/null; then
    echo "Warning: Repository '$REPOSITORY_NAME' not found."
    echo "Creating repository..."
    aws ecr create-repository \
        --repository-name $REPOSITORY_NAME \
        --region $REGION \
        --image-scanning-configuration scanOnPush=true
    echo "Repository created successfully!"
fi

echo ""
echo "Step 2: Authenticating Docker with ECR..."
aws ecr get-login-password --region $REGION | \
    docker login --username AWS --password-stdin $ECR_URI

echo ""
echo "Step 3: Tagging image for ECR..."
docker tag url-checker:latest $FULL_ECR_URI

echo ""
echo "Step 4: Pushing image to ECR..."
docker push $FULL_ECR_URI

echo ""
echo "========================================"
echo "Push Complete!"
echo "========================================"
echo ""
echo "Image pushed to: $FULL_ECR_URI"
echo ""
echo "To verify the image in ECR:"
echo "  aws ecr describe-images --repository-name $REPOSITORY_NAME --region $REGION"
echo ""
echo "To pull this image on another instance:"
echo "  aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URI"
echo "  docker pull $FULL_ECR_URI"
echo ""
echo "To run the container:"
echo "  docker run $FULL_ECR_URI https://example.com"
echo ""
