#!/bin/bash

# Configure Cognito App Client for API Gateway
# This script creates an app client with appropriate auth flows

set -e

# Read user pool ID
if [ ! -f user-pool-id.txt ]; then
  echo "Error: user-pool-id.txt not found. Run create-user-pool.sh first."
  exit 1
fi

USER_POOL_ID=$(cat user-pool-id.txt)

echo "Configuring App Client for User Pool: $USER_POOL_ID"

# Create app client
APP_CLIENT_ID=$(aws cognito-idp create-user-pool-client \
  --user-pool-id "$USER_POOL_ID" \
  --client-name api-gateway-client \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --token-validity-units '{
    "AccessToken": "hours",
    "IdToken": "hours",
    "RefreshToken": "days"
  }' \
  --access-token-validity 1 \
  --id-token-validity 1 \
  --refresh-token-validity 30 \
  --read-attributes email name \
  --write-attributes email name \
  --query 'UserPoolClient.ClientId' \
  --output text)

echo "App Client created: $APP_CLIENT_ID"

# Save app client ID
echo "$APP_CLIENT_ID" > app-client-id.txt

echo "✓ App Client configured successfully"
echo ""
echo "App Client Configuration:"
echo "  - Client ID: $APP_CLIENT_ID"
echo "  - Auth Flows: USER_PASSWORD_AUTH, REFRESH_TOKEN_AUTH"
echo "  - ID Token Validity: 1 hour"
echo "  - Access Token Validity: 1 hour"
echo "  - Refresh Token Validity: 30 days"
