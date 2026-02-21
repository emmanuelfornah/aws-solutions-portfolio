#!/bin/bash

# CDK Template Synthesis Script
# Synthesizes CloudFormation template from CDK code without deploying

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CDK Template Synthesis${NC}"
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

# Synthesize CloudFormation template
echo -e "${BLUE}Synthesizing CloudFormation template...${NC}"

cdk synth

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Template synthesis successful${NC}"
    echo ""
    
    # Display template location
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Generated Templates${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    if [ -d "cdk.out" ]; then
        echo -e "${BLUE}Templates location: cdk.out/${NC}"
        echo ""
        ls -lh cdk.out/*.template.json 2>/dev/null || echo "No templates found"
        echo ""
        
        # Display template summary
        TEMPLATE_FILE=$(ls cdk.out/*.template.json | head -n 1)
        if [ -f "$TEMPLATE_FILE" ]; then
            echo -e "${BLUE}Template Summary:${NC}"
            echo ""
            
            # Count resources
            RESOURCE_COUNT=$(jq '.Resources | length' "$TEMPLATE_FILE")
            echo -e "  Resources: ${RESOURCE_COUNT}"
            
            # List resource types
            echo -e "  Resource Types:"
            jq -r '.Resources | to_entries[] | "    - \(.value.Type)"' "$TEMPLATE_FILE" | sort | uniq
            
            echo ""
            
            # List outputs
            OUTPUT_COUNT=$(jq '.Outputs | length' "$TEMPLATE_FILE" 2>/dev/null || echo "0")
            if [ "$OUTPUT_COUNT" -gt 0 ]; then
                echo -e "  Outputs:"
                jq -r '.Outputs | to_entries[] | "    - \(.key): \(.value.Description // "No description")"' "$TEMPLATE_FILE"
            fi
        fi
    fi
    
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "  1. Review the generated template in cdk.out/"
    echo -e "  2. Deploy with: cdk deploy"
    echo -e "  3. Preview changes with: cdk diff"
else
    echo ""
    echo -e "${RED}✗ Template synthesis failed${NC}"
    exit 1
fi
