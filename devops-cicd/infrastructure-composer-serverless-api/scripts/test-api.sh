#!/bin/bash

# API Testing Script for Serverless Product Catalog
# Tests all CRUD operations on the API Gateway endpoint

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Serverless API Testing Script"
echo "=========================================="
echo ""

# Check if API_URL is provided
if [ -z "$1" ]; then
    echo "${RED}ERROR: API URL is required${NC}"
    echo ""
    echo "Usage: $0 <API_URL>"
    echo "Example: $0 https://abc123.execute-api.us-east-1.amazonaws.com/prod"
    echo ""
    echo "To find your API URL:"
    echo "1. Go to API Gateway console"
    echo "2. Select your API"
    echo "3. Click 'Stages' -> 'prod'"
    echo "4. Copy the 'Invoke URL'"
    exit 1
fi

API_URL="$1"
BASE_URL="${API_URL}/items"

echo "API Base URL: ${BASE_URL}"
echo ""

# Test 1: Create Item
echo "${YELLOW}Test 1: CREATE Item (POST /items)${NC}"
echo "----------------------------------------"
CREATE_RESPONSE=$(curl -s -X POST "${BASE_URL}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "laptop-001",
    "name": "Gaming Laptop",
    "price": 1299.99,
    "category": "Electronics",
    "stock": 15
  }')

echo "Response: ${CREATE_RESPONSE}"
echo ""

if echo "${CREATE_RESPONSE}" | grep -q "created successfully"; then
    echo "${GREEN}✓ CREATE test passed${NC}"
else
    echo "${RED}✗ CREATE test failed${NC}"
fi
echo ""

# Test 2: Create Another Item
echo "${YELLOW}Test 2: CREATE Another Item${NC}"
echo "----------------------------------------"
CREATE_RESPONSE_2=$(curl -s -X POST "${BASE_URL}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "mouse-001",
    "name": "Wireless Mouse",
    "price": 29.99,
    "category": "Accessories",
    "stock": 50
  }')

echo "Response: ${CREATE_RESPONSE_2}"
echo ""

if echo "${CREATE_RESPONSE_2}" | grep -q "created successfully"; then
    echo "${GREEN}✓ CREATE test 2 passed${NC}"
else
    echo "${RED}✗ CREATE test 2 failed${NC}"
fi
echo ""

# Test 3: Read All Items
echo "${YELLOW}Test 3: READ All Items (GET /items)${NC}"
echo "----------------------------------------"
READ_ALL_RESPONSE=$(curl -s -X GET "${BASE_URL}")

echo "Response: ${READ_ALL_RESPONSE}"
echo ""

if echo "${READ_ALL_RESPONSE}" | grep -q "items"; then
    echo "${GREEN}✓ READ ALL test passed${NC}"
    
    # Count items
    ITEM_COUNT=$(echo "${READ_ALL_RESPONSE}" | grep -o '"count":[0-9]*' | grep -o '[0-9]*')
    echo "  Found ${ITEM_COUNT} items"
else
    echo "${RED}✗ READ ALL test failed${NC}"
fi
echo ""

# Test 4: Read Item by ID
echo "${YELLOW}Test 4: READ Item by ID (GET /items/{id})${NC}"
echo "----------------------------------------"
READ_BY_ID_RESPONSE=$(curl -s -X GET "${BASE_URL}/laptop-001")

echo "Response: ${READ_BY_ID_RESPONSE}"
echo ""

if echo "${READ_BY_ID_RESPONSE}" | grep -q "Gaming Laptop"; then
    echo "${GREEN}✓ READ BY ID test passed${NC}"
else
    echo "${RED}✗ READ BY ID test failed${NC}"
fi
echo ""

# Test 5: Update Item
echo "${YELLOW}Test 5: UPDATE Item (PUT /items/{id})${NC}"
echo "----------------------------------------"
UPDATE_RESPONSE=$(curl -s -X PUT "${BASE_URL}/laptop-001" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Premium Gaming Laptop",
    "price": 1499.99,
    "stock": 10
  }')

echo "Response: ${UPDATE_RESPONSE}"
echo ""

if echo "${UPDATE_RESPONSE}" | grep -q "updated successfully"; then
    echo "${GREEN}✓ UPDATE test passed${NC}"
else
    echo "${RED}✗ UPDATE test failed${NC}"
fi
echo ""

# Test 6: Verify Update
echo "${YELLOW}Test 6: Verify UPDATE (GET /items/{id})${NC}"
echo "----------------------------------------"
VERIFY_UPDATE_RESPONSE=$(curl -s -X GET "${BASE_URL}/laptop-001")

echo "Response: ${VERIFY_UPDATE_RESPONSE}"
echo ""

if echo "${VERIFY_UPDATE_RESPONSE}" | grep -q "Premium Gaming Laptop" && \
   echo "${VERIFY_UPDATE_RESPONSE}" | grep -q "1499.99"; then
    echo "${GREEN}✓ UPDATE verification passed${NC}"
else
    echo "${RED}✗ UPDATE verification failed${NC}"
fi
echo ""

# Test 7: Read Non-Existent Item (404)
echo "${YELLOW}Test 7: READ Non-Existent Item (404 Expected)${NC}"
echo "----------------------------------------"
NOT_FOUND_RESPONSE=$(curl -s -X GET "${BASE_URL}/nonexistent-item")

echo "Response: ${NOT_FOUND_RESPONSE}"
echo ""

if echo "${NOT_FOUND_RESPONSE}" | grep -q "not found"; then
    echo "${GREEN}✓ 404 test passed${NC}"
else
    echo "${RED}✗ 404 test failed${NC}"
fi
echo ""

# Test 8: Invalid Request (400)
echo "${YELLOW}Test 8: Invalid CREATE Request (400 Expected)${NC}"
echo "----------------------------------------"
INVALID_RESPONSE=$(curl -s -X POST "${BASE_URL}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "No ID Provided"
  }')

echo "Response: ${INVALID_RESPONSE}"
echo ""

if echo "${INVALID_RESPONSE}" | grep -q "required"; then
    echo "${GREEN}✓ 400 validation test passed${NC}"
else
    echo "${RED}✗ 400 validation test failed${NC}"
fi
echo ""

# Optional: Test DELETE if implemented
echo "${YELLOW}Test 9: DELETE Item (Optional)${NC}"
echo "----------------------------------------"
DELETE_RESPONSE=$(curl -s -X DELETE "${BASE_URL}/mouse-001")

echo "Response: ${DELETE_RESPONSE}"
echo ""

if echo "${DELETE_RESPONSE}" | grep -q "deleted successfully"; then
    echo "${GREEN}✓ DELETE test passed${NC}"
elif echo "${DELETE_RESPONSE}" | grep -q "Method Not Allowed"; then
    echo "${YELLOW}⊘ DELETE not implemented (optional)${NC}"
else
    echo "${RED}✗ DELETE test failed${NC}"
fi
echo ""

# Summary
echo "=========================================="
echo "Testing Complete"
echo "=========================================="
echo ""
echo "All CRUD operations have been tested."
echo "Check the responses above for any failures."
echo ""
echo "To view items in DynamoDB:"
echo "1. Go to DynamoDB console"
echo "2. Select 'Items' table"
echo "3. Click 'Explore table items'"
echo ""
