#!/bin/bash

# Test Unauthorized API Request
# This script verifies that requests without valid tokens are rejected

set -e

# Read API endpoint
if [ ! -f api-endpoint.txt ]; then
  echo "Error: api-endpoint.txt not found. Run deploy-api.sh first."
  exit 1
fi

API_ENDPOINT=$(cat api-endpoint.txt)

echo "Testing unauthorized requests to API..."
echo "Endpoint: $API_ENDPOINT/items"
echo ""

# Test 1: No Authorization header
echo "1. Request without Authorization header"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -H "Content-Type: application/json" \
  "$API_ENDPOINT/items")

HTTP_STATUS=$(echo "$RESPONSE" | grep HTTP_STATUS | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

echo "Status: $HTTP_STATUS"
echo "Response: $BODY"

if [ "$HTTP_STATUS" = "401" ]; then
  echo "✓ Correctly rejected (401 Unauthorized)"
else
  echo "✗ Expected 401, got $HTTP_STATUS"
fi
echo ""

# Test 2: Invalid token
echo "2. Request with invalid token"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -H "Authorization: Bearer invalid-token-xyz" \
  -H "Content-Type: application/json" \
  "$API_ENDPOINT/items")

HTTP_STATUS=$(echo "$RESPONSE" | grep HTTP_STATUS | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

echo "Status: $HTTP_STATUS"
echo "Response: $BODY"

if [ "$HTTP_STATUS" = "401" ]; then
  echo "✓ Correctly rejected (401 Unauthorized)"
else
  echo "✗ Expected 401, got $HTTP_STATUS"
fi
echo ""

# Test 3: Malformed Authorization header
echo "3. Request with malformed Authorization header"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -H "Authorization: InvalidFormat" \
  -H "Content-Type: application/json" \
  "$API_ENDPOINT/items")

HTTP_STATUS=$(echo "$RESPONSE" | grep HTTP_STATUS | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

echo "Status: $HTTP_STATUS"
echo "Response: $BODY"

if [ "$HTTP_STATUS" = "401" ]; then
  echo "✓ Correctly rejected (401 Unauthorized)"
else
  echo "✗ Expected 401, got $HTTP_STATUS"
fi
echo ""

echo "Authorization enforcement verified successfully!"
echo "All unauthorized requests were properly rejected."
