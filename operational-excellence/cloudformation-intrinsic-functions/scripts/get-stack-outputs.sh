#!/bin/bash

# CloudFormation Stack Outputs Retrieval Script
# Displays all outputs from the deployed stack

set -e

STACK_NAME="CloudFormationUtilities"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CloudFormation Stack Outputs${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if stack exists
STACK_EXISTS=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].StackName' \
    --output text 2>/dev/null || echo "")

if [ -z "$STACK_EXISTS" ]; then
    echo -e "${RED}✗ Stack ${STACK_NAME} does not exist.${NC}"
    exit 1
fi

# Get stack status
STACK_STATUS=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].StackStatus' \
    --output text)

echo -e "${BLUE}Stack Name:${NC} ${STACK_NAME}"
echo -e "${BLUE}Stack Status:${NC} ${STACK_STATUS}"
echo ""

# Display outputs in table format
echo -e "${BLUE}Outputs:${NC}"
echo ""

aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue,Description]' \
    --output table

echo ""

# Display outputs in JSON format for scripting
echo -e "${BLUE}JSON Format (for scripting):${NC}"
echo ""

aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs' \
    --output json

echo ""

# Quick access commands
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Quick Access Commands${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

WEBSITE_URL=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`WebsiteURL`].OutputValue' \
    --output text)

INSTANCE_DNS=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`InstancePublicDNS`].OutputValue' \
    --output text)

INSTANCE_ID=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
    --output text)

echo -e "${GREEN}Open website in browser:${NC}"
echo "  ${WEBSITE_URL}"
echo ""

echo -e "${GREEN}Test website with curl:${NC}"
echo "  curl ${WEBSITE_URL}"
echo ""

echo -e "${GREEN}SSH to instance (if key pair configured):${NC}"
echo "  ssh -i your-key.pem ec2-user@${INSTANCE_DNS}"
echo ""

echo -e "${GREEN}View instance details:${NC}"
echo "  aws ec2 describe-instances --instance-ids ${INSTANCE_ID}"
echo ""

echo -e "${GREEN}View CloudWatch logs:${NC}"
echo "  aws logs tail /var/log/cloud-init-output.log --follow"
