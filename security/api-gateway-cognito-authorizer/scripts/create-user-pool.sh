#!/bin/bash

# Create Cognito User Pool for API Gateway Authorization
# This script creates a user pool with appropriate settings for API authentication

set -e

echo "Creating Cognito User Pool..."

# Create user pool
USER_POOL_ID=$(aws cognito-idp create-user-pool \
  --pool-name api-auth-user-pool \
  --policies '{
    "PasswordPolicy": {
      "MinimumLength": 8,
      "RequireUppercase": true,
      "RequireLowercase": true,
      "RequireNumbers": true,
      "RequireSymbols": false
    }
  }' \
  --auto-verified-attributes email \
  --username-attributes email \
  --schema '[
    {
      "Name": "email",
      "AttributeDataType": "String",
      "Required": true,
      "Mutable": true
    },
    {
      "Name": "name",
      "AttributeDataType": "String",
      "Required": false,
      "Mutable": true
    }
  ]' \
  --query 'UserPool.Id' \
  --output text)

echo "User Pool created: $USER_POOL_ID"

# Save user pool ID for other scripts
echo "$USER_POOL_ID" > user-pool-id.txt

# Get user pool ARN
USER_POOL_ARN=$(aws cognito-idp describe-user-pool \
  --user-pool-id "$USER_POOL_ID" \
  --query 'UserPool.Arn' \
  --output text)

echo "User Pool ARN: $USER_POOL_ARN"
echo "$USER_POOL_ARN" > user-pool-arn.txt

echo "✓ User Pool created successfully"
echo ""
echo "User Pool Configuration:"
echo "  - ID: $USER_POOL_ID"
echo "  - Sign-in: Email"
echo "  - Password: Min 8 chars, uppercase, lowercase, numbers"
echo "  - Auto-verified: Email"
