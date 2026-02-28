#!/bin/bash

# Deploy Lambda Function with Secrets Manager Integration
# This script creates and deploys a Lambda function

set -e

# Read IAM role ARN
if [ ! -f lambda-role-arn.txt ]; then
  echo "Error: lambda-role-arn.txt not found. Run create-execution-role.sh first."
  exit 1
fi

ROLE_ARN=$(cat lambda-role-arn.txt)
SECRET_NAME="db-credentials"

echo "Deploying Lambda function..."

# Create deployment package
echo "Creating deployment package..."
cd ../configs
zip -r ../scripts/lambda-function.zip lambda-function.py
cd ../scripts

# Create Lambda function
FUNCTION_ARN=$(aws lambda create-function \
  --function-name SecureDataAccessFunction \
  --runtime python3.9 \
  --role "$ROLE_ARN" \
  --handler lambda-function.lambda_handler \
  --zip-file fileb://lambda-function.zip \
  --timeout 30 \
  --memory-size 256 \
  --environment Variables="{SECRET_NAME=$SECRET_NAME,CACHE_TTL=300}" \
  --description "Lambda function demonstrating secure secret access" \
  --query 'FunctionArn' \
  --output text)

echo "Lambda function created: $FUNCTION_ARN"

# Save function information
echo "$FUNCTION_ARN" > lambda-function-arn.txt
echo "SecureDataAccessFunction" > lambda-function-name.txt

# Clean up deployment package
rm -f lambda-function.zip

# Wait for function to be active
echo "Waiting for function to be active..."
aws lambda wait function-active --function-name SecureDataAccessFunction

echo "✓ Lambda function deployed successfully"
echo ""
echo "Function Configuration:"
echo "  - Name: SecureDataAccessFunction"
echo "  - ARN: $FUNCTION_ARN"
echo "  - Runtime: Python 3.9"
echo "  - Memory: 256 MB"
echo "  - Timeout: 30 seconds"
echo "  - Environment:"
echo "    - SECRET_NAME: $SECRET_NAME"
echo "    - CACHE_TTL: 300"
