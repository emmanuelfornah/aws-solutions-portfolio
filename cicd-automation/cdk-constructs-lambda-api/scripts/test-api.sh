#!/bin/bash

# API Testing Script
# Tests the deployed Lambda-backed API endpoint

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

STACK_NAME="${1:-LambdaApiStack}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}API Endpoint Testing${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Get API URL from stack outputs
echo -e "${BLUE}Retrieving API endpoint URL...${NC}"

API_URL=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' \
    --output text 2>/dev/null)

if [ -z "$API_URL" ]; then
    echo -e "${RED}✗ Could not retrieve API URL. Stack may not exist or outputs are not available.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ API URL: ${API_URL}${NC}"
echo ""

# Test root endpoint
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test 1: Root Endpoint (/)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${BLUE}Request: GET ${API_URL}${NC}"
echo ""

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" ${API_URL})
HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

echo -e "${BLUE}Response (HTTP ${HTTP_STATUS}):${NC}"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Root endpoint test passed${NC}"
else
    echo -e "${RED}✗ Root endpoint test failed (HTTP ${HTTP_STATUS})${NC}"
fi

echo ""

# Test custom path
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test 2: Custom Path (/hello)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${BLUE}Request: GET ${API_URL}hello${NC}"
echo ""

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" ${API_URL}hello)
HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

echo -e "${BLUE}Response (HTTP ${HTTP_STATUS}):${NC}"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Custom path test passed${NC}"
else
    echo -e "${RED}✗ Custom path test failed (HTTP ${HTTP_STATUS})${NC}"
fi

echo ""

# Test with query parameters
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test 3: Query Parameters${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${BLUE}Request: GET ${API_URL}greet?name=CDK&language=Python${NC}"
echo ""

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "${API_URL}greet?name=CDK&language=Python")
HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

echo -e "${BLUE}Response (HTTP ${HTTP_STATUS}):${NC}"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Query parameters test passed${NC}"
else
    echo -e "${RED}✗ Query parameters test failed (HTTP ${HTTP_STATUS})${NC}"
fi

echo ""

# Performance test
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test 4: Response Time${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${BLUE}Measuring response time (5 requests)...${NC}"
echo ""

TOTAL_TIME=0
for i in {1..5}; do
    TIME=$(curl -s -o /dev/null -w "%{time_total}" ${API_URL})
    echo -e "  Request $i: ${TIME}s"
    TOTAL_TIME=$(echo "$TOTAL_TIME + $TIME" | bc)
done

AVG_TIME=$(echo "scale=3; $TOTAL_TIME / 5" | bc)
echo ""
echo -e "${BLUE}Average response time: ${AVG_TIME}s${NC}"

if (( $(echo "$AVG_TIME < 1.0" | bc -l) )); then
    echo -e "${GREEN}✓ Performance test passed (< 1s average)${NC}"
else
    echo -e "${YELLOW}⚠ Performance test warning (> 1s average)${NC}"
fi

echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}All tests completed!${NC}"
echo ""
echo -e "${BLUE}API Endpoint: ${API_URL}${NC}"
echo ""
echo -e "${BLUE}Additional testing:${NC}"
echo -e "  - Open in browser: ${API_URL}"
echo -e "  - View Lambda logs: aws logs tail /aws/lambda/HelloFunction --follow"
echo -e "  - Test with Postman or other API clients"
