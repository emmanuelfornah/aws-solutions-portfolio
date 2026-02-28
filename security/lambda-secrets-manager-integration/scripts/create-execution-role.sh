#!/bin/bash

# Create Lambda Execution Role
# This script creates an IAM role with permissions for Secrets Manager access

set -e

echo "Creating Lambda execution role..."

# Read secret ARN
if [ ! -f secret-arn.txt ]; then
  echo "Error: secret-arn.txt not found. Run create-secret.sh first."
  exit 1
fi

SECRET_ARN=$(cat secret-arn.txt)

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create trust policy
cat > trust-policy.json <<EOF
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

# Create IAM role
ROLE_ARN=$(aws iam create-role \
  --role-name LambdaSecretsManagerRole \
  --assume-role-policy-document file://trust-policy.json \
  --description "Execution role for Lambda with Secrets Manager access" \
  --query 'Role.Arn' \
  --output text)

echo "IAM role created: $ROLE_ARN"

# Create inline policy for Secrets Manager access
cat > secrets-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GetSecretValue",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "$SECRET_ARN"
    },
    {
      "Sid": "DecryptWithKMS",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "secretsmanager.us-east-1.amazonaws.com"
        }
      }
    }
  ]
}
EOF

# Attach inline policy
aws iam put-role-policy \
  --role-name LambdaSecretsManagerRole \
  --policy-name SecretsManagerAccess \
  --policy-document file://secrets-policy.json

echo "Secrets Manager policy attached"

# Attach AWS managed policy for CloudWatch Logs
aws iam attach-role-policy \
  --role-name LambdaSecretsManagerRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

echo "CloudWatch Logs policy attached"

# Save role ARN
echo "$ROLE_ARN" > lambda-role-arn.txt

# Clean up temporary files
rm -f trust-policy.json secrets-policy.json

# Wait for role to propagate
echo "Waiting for IAM role to propagate..."
sleep 10

echo "✓ Lambda execution role created successfully"
echo ""
echo "Role Configuration:"
echo "  - Role Name: LambdaSecretsManagerRole"
echo "  - Role ARN: $ROLE_ARN"
echo "  - Permissions:"
echo "    - Secrets Manager: GetSecretValue, DescribeSecret"
echo "    - KMS: Decrypt (via Secrets Manager)"
echo "    - CloudWatch Logs: CreateLogGroup, CreateLogStream, PutLogEvents"
