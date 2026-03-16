#!/bin/bash

# Pytest Test Execution Script
# Runs unit tests for the CDK stack

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CDK Stack Unit Tests${NC}"
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

# Check if pytest is installed
if ! python -c "import pytest" 2>/dev/null; then
    echo -e "${YELLOW}⚠ pytest not found, installing...${NC}"
    pip install pytest pytest-cov
    echo -e "${GREEN}✓ pytest installed${NC}"
    echo ""
fi

# Run tests with coverage
echo -e "${BLUE}Running pytest tests...${NC}"
echo ""

pytest tests/ -v --cov=lambda_api --cov-report=term-missing --cov-report=html

TEST_EXIT_CODE=$?

echo ""

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed${NC}"
    echo ""
    
    # Display coverage summary
    if [ -f "htmlcov/index.html" ]; then
        echo -e "${BLUE}Coverage report generated: htmlcov/index.html${NC}"
        echo -e "${BLUE}Open in browser to view detailed coverage${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Test Summary:${NC}"
    pytest tests/ --collect-only -q | tail -n 1
    
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Review test results above"
echo -e "  2. Check coverage report: open htmlcov/index.html"
echo -e "  3. Add more tests as needed"
echo -e "  4. Deploy stack: cdk deploy"
