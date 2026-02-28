#!/bin/bash

# Git Workflow Script
# This script automates the git workflow for pushing changes to CodeCommit

set -e

echo "=== Git Workflow for Integration Testing ==="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Check for uncommitted changes
if [[ -z $(git status -s) ]]; then
    echo "No changes to commit"
    exit 0
fi

# Show current status
echo ""
echo "Current changes:"
git status -s

# Add all changes
echo ""
echo "Adding all changes..."
git add .

# Prompt for commit message
echo ""
read -p "Enter commit message (or press Enter for default): " COMMIT_MSG

if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="Update integration tests and configuration"
fi

# Commit changes
echo ""
echo "Committing changes..."
git commit -m "$COMMIT_MSG"

# Push to remote
echo ""
echo "Pushing to CodeCommit..."
git push origin main

echo ""
echo "=== Changes pushed successfully ==="
echo ""
echo "Next steps:"
echo "1. Navigate to AWS CodePipeline console"
echo "2. Watch your pipeline automatically trigger"
echo "3. Monitor the IntegrationTest stage"
echo "4. Verify all stages complete successfully"
