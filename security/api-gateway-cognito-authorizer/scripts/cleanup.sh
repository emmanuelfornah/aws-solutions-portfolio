#!/bin/bash

# Cleanup API Gateway and Cognito Resources
# This script removes all resources created during setup

set -e

echo "Cleaning up API Gateway and Cognito resources..."

# Delete API Gateway (if exists)
if [ -f api-id.txt ]; then
  API_ID=$(cat api-id.txt)
  echo "Deleting API Gateway: $API_ID"
  aws apigateway delete-rest-api --rest-api-id "$API_ID" || true
  rm -f api-id.txt api-endpoint.txt authorizer-id.txt
fi

# Delete Cognito User Pool (if exists)
if [ -f user-pool-id.txt ]; then
  USER_POOL_ID=$(cat user-pool-id.txt)
  echo "Deleting Cognito User Pool: $USER_POOL_ID"
  aws cognito-idp delete-user-pool --user-pool-id "$USER_POOL_ID" || true
  rm -f user-pool-id.txt user-pool-arn.txt app-client-id.txt
fi

# Delete Lambda function (if exists)
if [ -f lambda-function-name.txt ]; then
  FUNCTION_NAME=$(cat lambda-function-name.txt)
  echo "Deleting Lambda function: $FUNCTION_NAME"
  aws lambda delete-function --function-name "$FUNCTION_NAME" || true
  rm -f lambda-function-name.txt
fi

# Clean up token files
rm -f id-token.txt access-token.txt refresh-token.txt test-credentials.txt

echo "✓ Cleanup completed successfully"
echo ""
echo "All resources have been removed."
