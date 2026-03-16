#!/bin/bash

# Website Availability Testing Script
# Tests the deployed website and displays content

set -e

STACK_NAME="CloudFormationUtilities"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Website Availability Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Get website URL from stack outputs
echo -e "${BLUE}Retrieving website URL from stack outputs...${NC}"

WEBSITE_URL=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`WebsiteURL`].OutputValue' \
    --output text 2>/dev/null)

if [ -z "$WEBSITE_URL" ]; then
    echo -e "${RED}✗ Could not retrieve website URL. Stack may not exist or outputs are not available.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Website URL: ${WEBSITE_URL}${NC}"
echo ""

# Test website availability
echo -e "${BLUE}Testing website availability...${NC}"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${WEBSITE_URL} || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Website is accessible (HTTP ${HTTP_STATUS})${NC}"
else
    echo -e "${RED}✗ Website is not accessible (HTTP ${HTTP_STATUS})${NC}"
    exit 1
fi

echo ""

# Fetch and display website content
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Website Content Preview${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

CONTENT=$(curl -s ${WEBSITE_URL})

# Extract key information from HTML
ENVIRONMENT=$(echo "$CONTENT" | grep -oP '(?<=<strong>Environment:</strong>).*?(?=</p>)' | sed 's/<[^>]*>//g' | xargs || echo "N/A")
INSTANCE_ID=$(echo "$CONTENT" | grep -oP '(?<=<strong>Instance ID:</strong>).*?(?=</p>)' | sed 's/<[^>]*>//g' | xargs || echo "N/A")
AZ=$(echo "$CONTENT" | grep -oP '(?<=<strong>Availability Zone:</strong>).*?(?=</p>)' | sed 's/<[^>]*>//g' | xargs || echo "N/A")

echo -e "${BLUE}Environment:${NC} $ENVIRONMENT"
echo -e "${BLUE}Instance ID:${NC} $INSTANCE_ID"
echo -e "${BLUE}Availability Zone:${NC} $AZ"

echo ""
echo -e "${GREEN}Website test completed successfully!${NC}"
echo ""
echo -e "${BLUE}Open in browser: ${WEBSITE_URL}${NC}"
