#!/bin/bash

# CDK Project Initialization Script
# Initializes a new CDK project with Python and sets up the development environment

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_NAME="${1:-lambda-api}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}AWS CDK Project Initialization${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if CDK CLI is installed
if ! command -v cdk &> /dev/null; then
    echo -e "${RED}✗ AWS CDK CLI is not installed${NC}"
    echo -e "${BLUE}Installing CDK CLI...${NC}"
    npm install -g aws-cdk
    echo -e "${GREEN}✓ CDK CLI installed${NC}"
else
    CDK_VERSION=$(cdk --version)
    echo -e "${GREEN}✓ CDK CLI is installed: ${CDK_VERSION}${NC}"
fi

echo ""

# Create project directory
echo -e "${BLUE}Creating project directory: ${PROJECT_NAME}${NC}"
mkdir -p ${PROJECT_NAME}
cd ${PROJECT_NAME}

# Initialize CDK app
echo -e "${BLUE}Initializing CDK app with Python...${NC}"
cdk init app --language python

echo -e "${GREEN}✓ CDK project initialized${NC}"
echo ""

# Create Python virtual environment
echo -e "${BLUE}Creating Python virtual environment...${NC}"
python3 -m venv .venv

echo -e "${GREEN}✓ Virtual environment created${NC}"
echo ""

# Activate virtual environment and install dependencies
echo -e "${BLUE}Installing Python dependencies...${NC}"

# Detect OS for activation command
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    source .venv/Scripts/activate
else
    source .venv/bin/activate
fi

pip install --upgrade pip
pip install -r requirements.txt

echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Display project structure
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Project Structure${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
tree -L 2 -I '.venv|__pycache__|*.pyc' || ls -la

echo ""
echo -e "${GREEN}CDK project initialization complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Activate virtual environment:"
echo -e "     source .venv/bin/activate  # Linux/Mac"
echo -e "     .venv\\Scripts\\activate.bat  # Windows"
echo ""
echo -e "  2. Create Lambda function handler (hello.py)"
echo ""
echo -e "  3. Define infrastructure in lambda_api/lambda_api_stack.py"
echo ""
echo -e "  4. Synthesize CloudFormation template:"
echo -e "     cdk synth"
echo ""
echo -e "  5. Deploy the stack:"
echo -e "     cdk deploy"
echo ""
echo -e "${BLUE}Useful CDK commands:${NC}"
echo -e "  cdk ls          List all stacks"
echo -e "  cdk synth       Synthesize CloudFormation template"
echo -e "  cdk diff        Compare deployed stack with current state"
echo -e "  cdk deploy      Deploy stack to AWS"
echo -e "  cdk destroy     Delete stack from AWS"
echo -e "  cdk bootstrap   Prepare AWS environment for CDK deployments"
