#!/bin/bash

# Configure API Gateway Cognito Authorizer
# This script creates a Cognito authorizer for API Gateway

set -e

# Read configuration
if [ ! -f user-pool-arn.txt ] || [ ! -f api-id.txt ]; then
  echo "Error: Required files not found."
  echo "Run create-user-pool.sh and deploy-api.sh first."
  exit 1
fi

USER_POOL_ARN=$(cat user-pool-arn.txt)
API_ID=$(cat api-id.txt)

echo "Configuring Cognito Authorizer for API: $API_ID"

# Create authorizer
AUTHORIZER_ID=$(aws apigateway create-authorizer \
  --rest-api-id "$API_ID" \
  --name CognitoAuthorizer \
  --type COGNITO_USER_POOLS \
  --provider-arns "$USER_POOL_ARN" \
  --identity-source method.request.header.Authorization \
  --authorizer-result-ttl-in-seconds 300 \
  --query 'id' \
  --output text)

echo "Authorizer created: $AUTHORIZER_ID"

# Save authorizer ID
echo "$AUTHORIZER_ID" > authorizer-id.txt

echo "✓ Cognito Authorizer configured successfully"
echo ""
echo "Authorizer Configuration:"
echo "  - ID: $AUTHORIZER_ID"
echo "  - Type: COGNITO_USER_POOLS"
echo "  - User Pool: $USER_POOL_ARN"
echo "  - Token Source: Authorization header"
echo "  - Cache TTL: 300 seconds (5 minutes)"
