#!/bin/bash

# CDK Stack Deployment Script
# Deploys the Lambda API stack to AWS

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

STACK_NAME="${1:-LambdaApiStack}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CDK Stack Deployment${NC}"
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

# Check if bootstrap is required
echo -e "${BLUE}Checking CDK bootstrap status...${NC}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region || echo "us-east-1")

BOOTSTRAP_STACK=$(aws cloudformation describe-stacks \
    --stack-name CDKToolkit \
    --query 'Stacks[0].StackName' \
    --output text 2>/dev/null || echo "")

if [ -z "$BOOTSTRAP_STACK" ]; then
    echo -e "${YELLOW}⚠ CDK bootstrap not detected${NC}"
    echo -e "${BLUE}Bootstrapping CDK environment...${NC}"
    cdk bootstrap aws://${ACCOUNT_ID}/${REGION}
    echo -e "${GREEN}✓ Bootstrap complete${NC}"
else
    echo -e "${GREEN}✓ CDK bootstrap detected${NC}"
fi

echo ""

# Synthesize template first
echo -e "${BLUE}Synthesizing CloudFormation template...${NC}"
cdk synth ${STACK_NAME}

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Template synthesis failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Template synthesis successful${NC}"
echo ""

# Show diff if stack already exists
echo -e "${BLUE}Checking for existing stack...${NC}"
EXISTING_STACK=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].StackName' \
    --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_STACK" ]; then
    echo -e "${YELLOW}Stack ${STACK_NAME} already exists${NC}"
    echo -e "${BLUE}Showing differences...${NC}"
    echo ""
    cdk diff ${STACK_NAME}
    echo ""
fi

# Deploy stack
echo -e "${BLUE}Deploying stack: ${STACK_NAME}${NC}"
echo -e "${BLUE}This may take a few minutes...${NC}"
echo ""

cdk deploy ${STACK_NAME} --require-approval never

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Stack deployment successful${NC}"
    echo ""
    
    # Display stack outputs
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Stack Outputs${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    aws cloudformation describe-stacks \
        --stack-name ${STACK_NAME} \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue,Description]' \
        --output table
    
    echo ""
    
    # Get API URL
    API_URL=$(aws cloudformation describe-stacks \
        --stack-name ${STACK_NAME} \
        --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$API_URL" ]; then
        echo -e "${GREEN}API Endpoint: ${API_URL}${NC}"
        echo ""
        echo -e "${BLUE}Test the API:${NC}"
        echo -e "  curl ${API_URL}"
        echo -e "  curl ${API_URL}hello"
    fi
    
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "  1. Test the API endpoint"
    echo -e "  2. View Lambda logs: aws logs tail /aws/lambda/HelloFunction --follow"
    echo -e "  3. Update code and redeploy: cdk deploy"
    echo -e "  4. Clean up: cdk destroy"
else
    echo ""
    echo -e "${RED}✗ Stack deployment failed${NC}"
    exit 1
fi
