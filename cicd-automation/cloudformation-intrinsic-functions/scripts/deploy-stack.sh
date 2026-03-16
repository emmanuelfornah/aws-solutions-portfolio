#!/bin/bash

# CloudFormation Stack Deployment Script
# Deploys the CloudFormation Intrinsic Functions stack

set -e

# Configuration
STACK_NAME="CloudFormationUtilities"
TEMPLATE_FILE="../configs/cfn-template.yaml"
ENVIRONMENT="${1:-Development}"  # Default to Development if not specified

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CloudFormation Stack Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Validate template
echo -e "${BLUE}Validating CloudFormation template...${NC}"
aws cloudformation validate-template \
    --template-body file://${TEMPLATE_FILE} \
    > /dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Template validation successful${NC}"
else
    echo -e "${RED}✗ Template validation failed${NC}"
    exit 1
fi

echo ""

# Check if stack already exists
STACK_EXISTS=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].StackName' \
    --output text 2>/dev/null || echo "")

if [ -n "$STACK_EXISTS" ]; then
    echo -e "${BLUE}Stack ${STACK_NAME} already exists. Updating...${NC}"
    
    aws cloudformation update-stack \
        --stack-name ${STACK_NAME} \
        --template-body file://${TEMPLATE_FILE} \
        --parameters ParameterKey=Environment,ParameterValue=${ENVIRONMENT} \
        --capabilities CAPABILITY_IAM
    
    echo -e "${BLUE}Waiting for stack update to complete...${NC}"
    aws cloudformation wait stack-update-complete \
        --stack-name ${STACK_NAME}
    
    echo -e "${GREEN}✓ Stack update completed successfully${NC}"
else
    echo -e "${BLUE}Creating new stack: ${STACK_NAME}${NC}"
    echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
    echo ""
    
    aws cloudformation create-stack \
        --stack-name ${STACK_NAME} \
        --template-body file://${TEMPLATE_FILE} \
        --parameters ParameterKey=Environment,ParameterValue=${ENVIRONMENT} \
        --capabilities CAPABILITY_IAM \
        --tags Key=Project,Value=CloudFormationIntrinsics Key=Environment,Value=${ENVIRONMENT}
    
    echo -e "${BLUE}Waiting for stack creation to complete...${NC}"
    echo -e "${BLUE}This may take 5-10 minutes...${NC}"
    
    aws cloudformation wait stack-create-complete \
        --stack-name ${STACK_NAME}
    
    echo -e "${GREEN}✓ Stack creation completed successfully${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Stack Outputs${NC}"
echo -e "${BLUE}========================================${NC}"

# Retrieve and display stack outputs
aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
    --output table

echo ""
echo -e "${GREEN}Deployment complete!${NC}"
echo ""
echo -e "${BLUE}To access the website, copy the WebsiteURL from the outputs above.${NC}"
echo ""

# Get the website URL
WEBSITE_URL=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`WebsiteURL`].OutputValue' \
    --output text)

echo -e "${GREEN}Website URL: ${WEBSITE_URL}${NC}"
echo ""
echo -e "${BLUE}Usage:${NC}"
echo -e "  Deploy Development: ./deploy-stack.sh Development"
echo -e "  Deploy Production:  ./deploy-stack.sh Production"
