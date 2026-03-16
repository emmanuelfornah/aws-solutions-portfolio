#!/bin/bash

# CloudFormation Template Validation Script
# Validates template syntax and displays template summary

set -e

TEMPLATE_FILE="${1:-../configs/cfn-template.yaml}"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CloudFormation Template Validation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${BLUE}Template: ${TEMPLATE_FILE}${NC}"
echo ""

# Validate template
echo -e "${BLUE}Validating template syntax...${NC}"

VALIDATION_OUTPUT=$(aws cloudformation validate-template \
    --template-body file://${TEMPLATE_FILE} 2>&1)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Template validation successful${NC}"
    echo ""
    
    # Display template summary
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Template Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Parameters
    echo -e "${BLUE}Parameters:${NC}"
    echo "$VALIDATION_OUTPUT" | jq -r '.Parameters[] | "  - \(.ParameterKey): \(.Description // "No description")"'
    echo ""
    
    # Capabilities
    echo -e "${BLUE}Required Capabilities:${NC}"
    CAPABILITIES=$(echo "$VALIDATION_OUTPUT" | jq -r '.Capabilities[]?' 2>/dev/null || echo "  None")
    if [ "$CAPABILITIES" = "None" ]; then
        echo "  None"
    else
        echo "$CAPABILITIES" | sed 's/^/  - /'
    fi
    echo ""
    
    # Description
    echo -e "${BLUE}Description:${NC}"
    echo "$VALIDATION_OUTPUT" | jq -r '.Description // "No description"' | sed 's/^/  /'
    echo ""
    
    echo -e "${GREEN}Template is ready for deployment!${NC}"
else
    echo -e "${RED}✗ Template validation failed${NC}"
    echo ""
    echo -e "${RED}Error details:${NC}"
    echo "$VALIDATION_OUTPUT"
    exit 1
fi

echo ""
echo -e "${BLUE}Usage:${NC}"
echo -e "  Validate default template: ./validate-template.sh"
echo -e "  Validate specific file:    ./validate-template.sh path/to/template.yaml"
