#!/bin/bash

# Authenticate User and Get JWT Tokens
# This script authenticates with Cognito and retrieves JWT tokens

set -e

# Read configuration
if [ ! -f user-pool-id.txt ] || [ ! -f app-client-id.txt ]; then
  echo "Error: Configuration files not found."
  exit 1
fi

USER_POOL_ID=$(cat user-pool-id.txt)
APP_CLIENT_ID=$(cat app-client-id.txt)

# Read test credentials
if [ ! -f test-credentials.txt ]; then
  echo "Error: test-credentials.txt not found. Run create-test-user.sh first."
  exit 1
fi

TEST_EMAIL="testuser@example.com"
TEST_PASSWORD="TestPassword123"

echo "Authenticating user: $TEST_EMAIL"

# Authenticate and get tokens
AUTH_RESPONSE=$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id "$APP_CLIENT_ID" \
  --auth-parameters USERNAME="$TEST_EMAIL",PASSWORD="$TEST_PASSWORD")

# Extract tokens
ID_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.AuthenticationResult.IdToken')
ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.AuthenticationResult.AccessToken')
REFRESH_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.AuthenticationResult.RefreshToken')
EXPIRES_IN=$(echo "$AUTH_RESPONSE" | jq -r '.AuthenticationResult.ExpiresIn')

# Save tokens
echo "$ID_TOKEN" > id-token.txt
echo "$ACCESS_TOKEN" > access-token.txt
echo "$REFRESH_TOKEN" > refresh-token.txt

echo "✓ Authentication successful"
echo ""
echo "Tokens Retrieved:"
echo "  - ID Token: ${ID_TOKEN:0:50}..."
echo "  - Access Token: ${ACCESS_TOKEN:0:50}..."
echo "  - Refresh Token: ${REFRESH_TOKEN:0:50}..."
echo "  - Expires In: $EXPIRES_IN seconds"
echo ""
echo "Tokens saved to:"
echo "  - id-token.txt"
echo "  - access-token.txt"
echo "  - refresh-token.txt"
echo ""
echo "Decode token at: https://jwt.io/"
