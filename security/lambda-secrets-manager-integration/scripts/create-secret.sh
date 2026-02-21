#!/bin/bash

# Create Secret for Lambda Function
# This script creates a secret in Secrets Manager for Lambda to access

set -e

echo "Creating secret in Secrets Manager..."

# Secret value (database credentials example)
SECRET_VALUE='{
  "username": "dbadmin",
  "password": "SecurePassword123!",
  "engine": "mysql",
  "host": "mydb.example.com",
  "port": 3306,
  "dbname": "production"
}'

# Create secret
SECRET_ARN=$(aws secretsmanager create-secret \
  --name db-credentials \
  --description "Database credentials for Lambda function access" \
  --secret-string "$SECRET_VALUE" \
  --query 'ARN' \
  --output text)

echo "Secret created: $SECRET_ARN"

# Save secret information
echo "$SECRET_ARN" > secret-arn.txt
echo "db-credentials" > secret-name.txt

echo "✓ Secret created successfully"
echo ""
echo "Secret Configuration:"
echo "  - Name: db-credentials"
echo "  - ARN: $SECRET_ARN"
echo "  - Encryption: AWS managed key (default)"
echo ""
echo "Secret contains:"
echo "  - Database username"
echo "  - Database password"
echo "  - Database host"
echo "  - Database port"
echo "  - Database name"
echo ""
echo "Note: In production, use a customer-managed KMS key for encryption"
