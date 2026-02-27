#!/bin/bash

# Lambda Function Deployment Script (AWS CLI)
# This script deploys the URL Checker Lambda function using AWS CLI commands.
# It creates the IAM execution role, attaches policies, and creates/updates the Lambda function.

set -e  # Exit on any error

echo "=========================================="
echo "Lambda URL Checker - AWS CLI Deployment"
echo "=========================================="

# Configuration
FUNCTION_NAME="URLChecker"
RUNTIME="python3.13"
HANDLER="app.lambda_handler"
ROLE_NAME="LambdaURLCheckerRole"
ZIP_FILE="lambda-deployment-package.zip"
TIMEOUT=10
MEMORY_SIZE=128

# Check if deployment package exists
if [ ! -f "$ZIP_FILE" ]; then
    echo "Error: Deployment package not found!"
    echo "Please run ./package-lambda.sh first to create the deployment package."
    exit 1
fi

# Step 1: Create IAM execution role
echo ""
echo "Step 1: Creating IAM execution role..."

# Create trust policy document
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role (ignore error if already exists)
aws iam create-role \
  --role-name $ROLE_NAME \
  --assume-role-policy-document file://trust-policy.json \
  --description "Execution role for URL Checker Lambda function" \
  2>/dev/null || echo "Role already exists, continuing..."

# Attach basic execution policy for CloudWatch Logs
echo "Attaching CloudWatch Logs policy..."
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)
echo "Role ARN: $ROLE_ARN"

# Wait for role to be available
echo "Waiting for IAM role to propagate..."
sleep 10

# Step 2: Create or update Lambda function
echo ""
echo "Step 2: Deploying Lambda function..."

# Check if function exists
if aws lambda get-function --function-name $FUNCTION_NAME 2>/dev/null; then
    echo "Function exists, updating code..."
    aws lambda update-function-code \
      --function-name $FUNCTION_NAME \
      --zip-file fileb://$ZIP_FILE
    
    echo "Updating function configuration..."
    aws lambda update-function-configuration \
      --function-name $FUNCTION_NAME \
      --runtime $RUNTIME \
      --handler $HANDLER \
      --timeout $TIMEOUT \
      --memory-size $MEMORY_SIZE
else
    echo "Creating new function..."
    aws lambda create-function \
      --function-name $FUNCTION_NAME \
      --runtime $RUNTIME \
      --role $ROLE_ARN \
      --handler $HANDLER \
      --zip-file fileb://$ZIP_FILE \
      --timeout $TIMEOUT \
      --memory-size $MEMORY_SIZE \
      --description "URL health checker function"
fi

# Step 3: Test the function
echo ""
echo "Step 3: Testing the function..."

# Create test event
cat > test-event.json << EOF
{
  "url": "https://aws.amazon.com"
}
EOF

echo "Invoking function with test URL..."
aws lambda invoke \
  --function-name $FUNCTION_NAME \
  --payload file://test-event.json \
  response.json

echo ""
echo "Function response:"
cat response.json | python3 -m json.tool

# Clean up temporary files
rm -f trust-policy.json test-event.json

echo ""
echo "=========================================="
echo "Deployment completed successfully!"
echo "=========================================="
echo "Function name: $FUNCTION_NAME"
echo "Runtime: $RUNTIME"
echo "Handler: $HANDLER"
echo "Role: $ROLE_NAME"
echo ""
echo "Next Steps:"
echo "1. View function in AWS Console: https://console.aws.amazon.com/lambda"
echo "2. Check CloudWatch Logs: /aws/lambda/$FUNCTION_NAME"
echo "3. Invoke function: aws lambda invoke --function-name $FUNCTION_NAME --payload '{\"url\":\"https://example.com\"}' output.json"
echo ""
