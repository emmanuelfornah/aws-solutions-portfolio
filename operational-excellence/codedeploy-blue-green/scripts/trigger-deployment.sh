#!/bin/bash

# Script to trigger a blue/green deployment by updating code and pushing to CodeCommit
# This script updates the deployment number in the application and pushes changes

set -e

echo "=== Blue/Green Deployment Trigger Script ==="
echo ""

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo "Error: Not in a git repository. Please run this script from your application root."
    exit 1
fi

# Get current deployment number from user
read -p "Enter current deployment number (e.g., 1): " CURRENT_NUM
read -p "Enter new deployment number (e.g., 2): " NEW_NUM

# Find and update deployment number in HTML files
echo "Updating deployment number from $CURRENT_NUM to $NEW_NUM..."

# Update index.html or main application file
if [ -f "index.html" ]; then
    sed -i "s/Deployment $CURRENT_NUM/Deployment $NEW_NUM/g" index.html
    echo "✓ Updated index.html"
elif [ -f "templates/index.html" ]; then
    sed -i "s/Deployment $CURRENT_NUM/Deployment $NEW_NUM/g" templates/index.html
    echo "✓ Updated templates/index.html"
else
    echo "Warning: Could not find index.html. Please update deployment number manually."
fi

# Show changes
echo ""
echo "Changes to be committed:"
git diff

# Confirm before committing
echo ""
read -p "Proceed with commit and push? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "Deployment cancelled."
    exit 0
fi

# Git workflow
echo ""
echo "Committing changes..."
git add .
git commit -m "Update to Deployment $NEW_NUM for blue/green deployment test"

echo ""
echo "Pushing to CodeCommit..."
git push origin main

echo ""
echo "=== Deployment Triggered ==="
echo "✓ Code pushed to CodeCommit"
echo "✓ CodePipeline will automatically start"
echo "✓ CodeDeploy will begin blue/green deployment"
echo ""
echo "Next steps:"
echo "1. Navigate to AWS CodeDeploy console"
echo "2. Monitor the 4-step deployment process"
echo "3. Verify new instances at Step 3 (Test traffic)"
echo "4. Manually reroute traffic when ready"
echo "5. Monitor instance termination after wait period"
echo ""
echo "Deployment number updated: $CURRENT_NUM → $NEW_NUM"
