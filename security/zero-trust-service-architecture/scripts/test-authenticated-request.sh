#!/bin/bash

# Test Authenticated Request with SigV4 Signing
# Demonstrates Zero Trust authentication

set -e

API_ID=$(cat api-id.txt)
REGION="us-east-1"
ENDPOINT="https://$API_ID.execute-api.$REGION.amazonaws.com/prod/users"

echo "Testing authenticated request with SigV4 signing..."
echo "Endpoint: $ENDPOINT"
echo ""

# Use AWS CLI to make signed request (automatically uses IAM credentials)
echo "Making signed request..."
RESPONSE=$(aws apigatewaymanagementapi get-connection \
  --connection-id test \
  --endpoint-url "$ENDPOINT" 2>&1 || true)

# Alternative: Use curl with aws-sigv4
echo "Using curl with SigV4 signing..."
curl -X GET "$ENDPOINT" \
  --aws-sigv4 "aws:amz:$REGION:execute-api" \
  --user "$(aws configure get aws_access_key_id):$(aws configure get aws_secret_access_key)" \
  -H "x-amz-security-token: $(aws configure get aws_session_token)" \
  -v

echo ""
echo ""
echo "Request completed!"
echo "Expected: 200 OK if IAM role has permissions"
echo "Expected: 403 Forbidden if IAM role lacks permissions"
