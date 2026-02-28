#!/bin/bash

# Deploy Infrastructure via CodePipeline
# This script commits and pushes infrastructure changes to trigger the pipeline

set -e

echo "=========================================="
echo "Infrastructure Deployment Script"
echo "=========================================="
echo ""

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo "ERROR: Not in a git repository"
    echo "Please run this script from the iac-code-repo directory"
    exit 1
fi

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "Uncommitted changes detected:"
    git status --short
    echo ""
    
    # Add all changes
    echo "Adding all changes to git..."
    git add .
    
    # Prompt for commit message
    read -p "Enter commit message (or press Enter for default): " commit_msg
    
    if [ -z "$commit_msg" ]; then
        commit_msg="Update infrastructure configuration"
    fi
    
    # Commit changes
    echo "Committing changes..."
    git commit -m "$commit_msg"
    echo ""
else
    echo "No uncommitted changes found"
    echo ""
fi

# Get current branch
current_branch=$(git branch --show-current)
echo "Current branch: $current_branch"
echo ""

# Push to remote
echo "Pushing changes to remote repository..."
git push origin "$current_branch"
echo ""

echo "=========================================="
echo "Changes pushed successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Navigate to AWS CodePipeline console"
echo "2. Find the 'iac-pipeline' pipeline"
echo "3. Watch the pipeline execute automatically"
echo "4. Monitor the Source, Build, and Deploy stages"
echo "5. Check CloudFormation console for stack updates"
echo ""
echo "Pipeline URL:"
echo "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/iac-pipeline/view"
echo ""
