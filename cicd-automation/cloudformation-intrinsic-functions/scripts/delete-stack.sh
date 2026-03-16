#!/bin/bash

# CloudFormation Stack Deletion Script
# Deletes the CloudFormation Intrinsic Functions stack and all resources

set -e

STACK_NAME="CloudFormationUtilities"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CloudFormation Stack Deletion${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if stack exists
STACK_EXISTS=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].StackName' \
    --output text 2>/dev/null || echo "")

if [ -z "$STACK_EXISTS" ]; then
    echo -e "${YELLOW}Stack ${STACK_NAME} does not exist or has already been deleted.${NC}"
    exit 0
fi

# Display stack resources before deletion
echo -e "${BLUE}Stack resources to be deleted:${NC}"
aws cloudformation describe-stack-resources \
    --stack-name ${STACK_NAME} \
    --query 'StackResources[*].[ResourceType,LogicalResourceId,PhysicalResourceId]' \
    --output table

echo ""
echo -e "${YELLOW}WARNING: This will delete all resources created by the stack.${NC}"
echo -e "${YELLOW}This action cannot be undone.${NC}"
echo ""

# Prompt for confirmation
read -p "Are you sure you want to delete the stack? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${BLUE}Stack deletion cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Deleting stack: ${STACK_NAME}${NC}"

aws cloudformation delete-stack \
    --stack-name ${STACK_NAME}

echo -e "${BLUE}Waiting for stack deletion to complete...${NC}"
echo -e "${BLUE}This may take 5-10 minutes...${NC}"

aws cloudformation wait stack-delete-complete \
    --stack-name ${STACK_NAME}

echo ""
echo -e "${GREEN}✓ Stack deletion completed successfully${NC}"
echo ""
echo -e "${GREEN}All resources have been cleaned up.${NC}"
