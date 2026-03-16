#!/bin/bash

# Cleanup Lambda and Secrets Manager Resources
# This script removes all resources created during setup

set -e

echo "Cleaning up Lambda and Secrets Manager resources..."

# Delete Lambda function
if [ -f lambda-function-name.txt ]; then
  FUNCTION_NAME=$(cat lambda-function-name.txt)
  echo "Deleting Lambda function: $FUNCTION_NAME"
  
  aws lambda delete-function --function-name "$FUNCTION_NAME" || true
  rm -f lambda-function-name.txt lambda-function-arn.txt
fi

# Delete IAM role
if [ -f lambda-role-arn.txt ]; then
  ROLE_NAME="LambdaSecretsManagerRole"
  echo "Deleting IAM role: $ROLE_NAME"
  
  # Detach managed policies
  aws iam detach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole || true
  
  # Delete inline policies
  aws iam delete-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name SecretsManagerAccess || true
  
  # Delete role
  aws iam delete-role --role-name "$ROLE_NAME" || true
  
  rm -f lambda-role-arn.txt
fi

# Delete secret
if [ -f secret-name.txt ]; then
  SECRET_NAME=$(cat secret-name.txt)
  echo "Scheduling secret deletion: $SECRET_NAME"
  
  aws secretsmanager delete-secret \
    --secret-id "$SECRET_NAME" \
    --recovery-window-in-days 7 || true
  
  rm -f secret-name.txt secret-arn.txt
fi

# Delete CloudWatch log group
LOG_GROUP="/aws/lambda/SecureDataAccessFunction"
echo "Deleting CloudWatch log group: $LOG_GROUP"
aws logs delete-log-group --log-group-name "$LOG_GROUP" || true

echo "✓ Cleanup completed successfully"
echo ""
echo "Resources removed:"
echo "  - Lambda function"
echo "  - IAM execution role"
echo "  - Secret (7-day recovery window)"
echo "  - CloudWatch log group"
