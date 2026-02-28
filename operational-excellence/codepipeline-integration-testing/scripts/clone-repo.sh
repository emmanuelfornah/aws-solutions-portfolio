#!/bin/bash

# Clone CodeCommit Repository Script
# This script clones the Flask application repository from AWS CodeCommit

set -e

echo "=== Cloning CodeCommit Repository ==="

# Configuration
REPO_NAME="flask-app-repo"  # Replace with your repository name
REGION="us-east-1"          # Replace with your AWS region

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS CLI is not configured or credentials are invalid"
    exit 1
fi

# Clone the repository
echo "Cloning repository: $REPO_NAME"
cd ~/environment

if [ -d "$REPO_NAME" ]; then
    echo "Repository directory already exists. Pulling latest changes..."
    cd "$REPO_NAME"
    git pull origin main
else
    REPO_URL="https://git-codecommit.$REGION.amazonaws.com/v1/repos/$REPO_NAME"
    git clone "$REPO_URL"
    cd "$REPO_NAME"
fi

echo ""
echo "=== Repository cloned successfully ==="
echo "Location: ~/environment/$REPO_NAME"
echo ""
echo "Next steps:"
echo "1. cd ~/environment/$REPO_NAME"
echo "2. Create integration_buildspec.yml"
echo "3. Add integration tests"
echo "4. Commit and push changes"
