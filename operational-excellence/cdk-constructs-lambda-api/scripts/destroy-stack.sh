#!/bin/bash

# CDK Stack Destruction Script
# Destroys the Lambda API stack and all associated resources

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

STACK_NAME="${1:-LambdaApiStack}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CDK Stack Destruction${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if in CDK project directory
if [ ! -f "cdk.json" ]; then
    echo -e "${RED}✗ Not in a CDK project directory (cdk.json not found)${NC}"
    exit 1
fi

# Activate virtual environment if it exists
if [ -d ".venv" ]; then
    echo -e "${BLUE}Activating virtual environment...${NC}"
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        source .venv/Scripts/activate
    else
        source .venv/bin/activate
    fi
    echo -e "${GREEN}✓ Virtual environment activated${NC}"
    echo ""
fi

# Check if stack exists
echo -e "${BLUE}Checking if stack exists...${NC}"

STACK_EXISTS=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].StackName' \
    --output text 2>/dev/null || echo "")

if [ -z "$STACK_EXISTS" ]; then
    echo -e "${YELLOW}Stack ${STACK_NAME} does not exist or has already been deleted.${NC}"
    exit 0
fi

echo -e "${GREEN}✓ Stack found: ${STACK_NAME}${NC}"
echo ""

# Display stack resources
echo -e "${BLUE}Stack resources to be deleted:${NC}"
echo ""

aws cloudformation describe-stack-resources \
    --stack-name ${STACK_NAME} \
    --query 'StackResources[*].[ResourceType,LogicalResourceId,PhysicalResourceId]' \
    --output table

echo ""
echo -e "${YELLOW}WARNING: This will delete all resources created by the stack.${NC}"
echo -e "${YELLOW}This action cannot be undone.${NC}"
echo ""

# Prompt for confirmation
read -p "Are you sure you want to destroy the stack? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${BLUE}Stack destruction cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Destroying stack: ${STACK_NAME}${NC}"
echo -e "${BLUE}This may take a few minutes...${NC}"
echo ""

cdk destroy ${STACK_NAME} --force

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Stack destruction completed successfully${NC}"
    echo ""
    echo -e "${GREEN}All resources have been cleaned up.${NC}"
    echo ""
    
    # Verify deletion
    STACK_STATUS=$(aws cloudformation describe-stacks \
        --stack-name ${STACK_NAME} \
        --query 'Stacks[0].StackStatus' \
        --output text 2>/dev/null || echo "DELETED")
    
    if [ "$STACK_STATUS" = "DELETED" ] || [ -z "$STACK_STATUS" ]; then
        echo -e "${GREEN}✓ Stack deletion verified${NC}"
    else
        echo -e "${YELLOW}⚠ Stack status: ${STACK_STATUS}${NC}"
        echo -e "${BLUE}Check CloudFormation console for details${NC}"
    fi
else
    echo ""
    echo -e "${RED}✗ Stack destruction failed${NC}"
    echo -e "${BLUE}Check CloudFormation console for error details${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Note: CDK bootstrap resources (CDKToolkit stack) are not deleted.${NC}"
echo -e "${BLUE}To remove bootstrap resources, manually delete the CDKToolkit stack.${NC}"
