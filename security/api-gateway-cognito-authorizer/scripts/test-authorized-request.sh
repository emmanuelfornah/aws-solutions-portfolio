#!/bin/bash

# Test Authorized API Request
# This script makes an authenticated request to the API

set -e

# Read configuration
if [ ! -f api-endpoint.txt ] || [ ! -f id-token.txt ]; then
  echo "Error: Configuration files not found."
  echo "Run deploy-api.sh and authenticate-user.sh first."
  exit 1
fi

API_ENDPOINT=$(cat api-endpoint.txt)
ID_TOKEN=$(cat id-token.txt)

echo "Testing authorized request to API..."
echo "Endpoint: $API_ENDPOINT/items"
echo ""

# Make authenticated GET request
echo "1. GET /items (List items)"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json" \
  "$API_ENDPOINT/items")

HTTP_STATUS=$(echo "$RESPONSE" | grep HTTP_STATUS | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

echo "Status: $HTTP_STATUS"
echo "Response: $BODY"
echo ""

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✓ Authorized request successful"
else
  echo "✗ Request failed with status $HTTP_STATUS"
  exit 1
fi

# Make authenticated POST request
echo "2. POST /items (Create item)"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item","description":"Created via authenticated API"}' \
  "$API_ENDPOINT/items")

HTTP_STATUS=$(echo "$RESPONSE" | grep HTTP_STATUS | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS/d')

echo "Status: $HTTP_STATUS"
echo "Response: $BODY"
echo ""

if [ "$HTTP_STATUS" = "201" ] || [ "$HTTP_STATUS" = "200" ]; then
  echo "✓ Authorized POST request successful"
else
  echo "✗ Request failed with status $HTTP_STATUS"
fi

echo ""
echo "All authorized requests completed successfully!"
