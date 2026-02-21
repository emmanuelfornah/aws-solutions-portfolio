#!/bin/bash

# Git Workflow Script
# This script guides you through committing and pushing changes to CodeCommit

set -e  # Exit on any error

echo "=========================================="
echo "Git Workflow for CodeCommit"
echo "=========================================="

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "Error: Not a git repository!"
    echo "Please run this script from the project root directory."
    exit 1
fi

# Check for uncommitted changes
if [ -z "$(git status --porcelain)" ]; then
    echo "No changes to commit. Working directory is clean."
    exit 0
fi

echo ""
echo "Current git status:"
echo "--------------------------------------"
git status --short

echo ""
echo "Modified files will be committed and pushed to CodeCommit."
echo ""

# Prompt for confirmation (can be skipped with -y flag)
if [ "$1" != "-y" ]; then
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Stage all changes
echo ""
echo "Staging changes..."
echo "--------------------------------------"
git add .
echo "✓ Changes staged"

# Prompt for commit message
echo ""
read -p "Enter commit message (or press Enter for default): " COMMIT_MSG

if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="Fix age calculation using relativedelta"
fi

# Commit changes
echo ""
echo "Committing changes..."
echo "--------------------------------------"
git commit -m "$COMMIT_MSG"
echo "✓ Changes committed"

# Show current branch
CURRENT_BRANCH=$(git branch --show-current)
echo ""
echo "Current branch: $CURRENT_BRANCH"

# Push to CodeCommit
echo ""
echo "Pushing to CodeCommit..."
echo "--------------------------------------"
git push origin "$CURRENT_BRANCH"

if [ $? -eq 0 ]; then
    echo "✓ Changes pushed successfully!"
else
    echo "✗ Failed to push changes"
    echo ""
    echo "Troubleshooting:"
    echo "  - Verify AWS credentials are configured"
    echo "  - Check CodeCommit repository permissions"
    echo "  - Ensure remote 'origin' is set correctly"
    exit 1
fi

echo ""
echo "=========================================="
echo "Git Workflow Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Navigate to AWS CodePipeline console"
echo "2. Watch your pipeline automatically trigger"
echo "3. Monitor the Source, Test, and Deploy stages"
echo "4. Verify deployment completes successfully"
echo "5. Test the application to confirm the bug is fixed"
echo ""
echo "Pipeline URL: https://console.aws.amazon.com/codesuite/codepipeline/pipelines"
echo ""
