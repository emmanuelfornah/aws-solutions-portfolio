#!/bin/bash

# Script to verify blue/green deployment status
# Checks CodeDeploy deployment status and provides guidance

set -e

echo "=== Blue/Green Deployment Verification Script ==="
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Get deployment details
read -p "Enter CodeDeploy application name (e.g., presidents-app): " APP_NAME
read -p "Enter deployment group name (e.g., presidents-deployment-group-bg): " DEPLOYMENT_GROUP

echo ""
echo "Fetching latest deployment status..."
echo ""

# Get the latest deployment ID
DEPLOYMENT_ID=$(aws deploy list-deployments \
    --application-name "$APP_NAME" \
    --deployment-group-name "$DEPLOYMENT_GROUP" \
    --query 'deployments[0]' \
    --output text 2>/dev/null)

if [ -z "$DEPLOYMENT_ID" ] || [ "$DEPLOYMENT_ID" == "None" ]; then
    echo "No deployments found for application: $APP_NAME"
    echo "Deployment group: $DEPLOYMENT_GROUP"
    exit 1
fi

echo "Latest Deployment ID: $DEPLOYMENT_ID"
echo ""

# Get deployment details
DEPLOYMENT_INFO=$(aws deploy get-deployment \
    --deployment-id "$DEPLOYMENT_ID" \
    --output json)

# Extract key information
STATUS=$(echo "$DEPLOYMENT_INFO" | jq -r '.deploymentInfo.status')
CREATOR=$(echo "$DEPLOYMENT_INFO" | jq -r '.deploymentInfo.creator')
CREATE_TIME=$(echo "$DEPLOYMENT_INFO" | jq -r '.deploymentInfo.createTime')
DEPLOYMENT_TYPE=$(echo "$DEPLOYMENT_INFO" | jq -r '.deploymentInfo.deploymentStyle.deploymentType')

echo "=== Deployment Status ==="
echo "Status: $STATUS"
echo "Type: $DEPLOYMENT_TYPE"
echo "Creator: $CREATOR"
echo "Created: $CREATE_TIME"
echo ""

# Provide status-specific guidance
case $STATUS in
    "Created")
        echo "📋 Deployment has been created and is waiting to start."
        echo "   Next: Deployment will begin provisioning replacement instances."
        ;;
    "InProgress")
        echo "🔄 Deployment is in progress."
        echo "   Check the CodeDeploy console for current step:"
        echo "   - Step 1: Provision replacement instances"
        echo "   - Step 2: Install application on replacement instances"
        echo "   - Step 3: Reroute traffic to replacement instances (manual control)"
        echo "   - Step 4: Terminate original instances"
        ;;
    "Ready")
        echo "⏸️  Deployment is ready for manual traffic rerouting."
        echo "   Action required:"
        echo "   1. Test the green environment using the test traffic URL"
        echo "   2. Verify application functionality"
        echo "   3. Click 'Reroute traffic' in CodeDeploy console when ready"
        ;;
    "Succeeded")
        echo "✅ Deployment completed successfully!"
        echo "   - Traffic has been rerouted to new instances"
        echo "   - Original instances will terminate after wait period"
        echo "   - Verify application is working at production URL"
        ;;
    "Failed")
        echo "❌ Deployment failed."
        echo "   Check CodeDeploy console for error details."
        echo "   Common issues:"
        echo "   - Instance provisioning failures"
        echo "   - Application installation errors"
        echo "   - Health check failures"
        ;;
    "Stopped")
        echo "⛔ Deployment was stopped."
        echo "   This may be due to manual stop or timeout."
        ;;
    *)
        echo "Status: $STATUS"
        ;;
esac

echo ""
echo "=== Quick Links ==="
echo "CodeDeploy Console:"
echo "https://console.aws.amazon.com/codesuite/codedeploy/deployments/$DEPLOYMENT_ID"
echo ""
echo "EC2 Instances:"
echo "https://console.aws.amazon.com/ec2/v2/home#Instances:"
echo ""
echo "Load Balancers:"
echo "https://console.aws.amazon.com/ec2/v2/home#LoadBalancers:"
echo ""

# Check for blue/green specific information
if [ "$DEPLOYMENT_TYPE" == "BLUE_GREEN" ]; then
    echo "=== Blue/Green Deployment Details ==="
    
    # Get target group information
    TARGET_GROUP_INFO=$(echo "$DEPLOYMENT_INFO" | jq -r '.deploymentInfo.loadBalancerInfo.targetGroupInfoList[]?')
    
    if [ -n "$TARGET_GROUP_INFO" ]; then
        echo "Target groups are configured for traffic routing."
    fi
    
    echo ""
    echo "Blue/Green Deployment Steps:"
    echo "1. ✓ Provision replacement instances (green environment)"
    echo "2. ✓ Install application on green instances"
    echo "3. ⏳ Reroute traffic (manual control - verify before proceeding)"
    echo "4. ⏳ Terminate blue instances (after wait period)"
fi

echo ""
echo "=== Monitoring Commands ==="
echo ""
echo "# Watch deployment status (refresh every 10 seconds):"
echo "watch -n 10 'aws deploy get-deployment --deployment-id $DEPLOYMENT_ID --query deploymentInfo.status'"
echo ""
echo "# List all deployments for this application:"
echo "aws deploy list-deployments --application-name $APP_NAME --deployment-group-name $DEPLOYMENT_GROUP"
echo ""
echo "# Get detailed deployment info:"
echo "aws deploy get-deployment --deployment-id $DEPLOYMENT_ID"
echo ""
