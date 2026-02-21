#!/bin/bash

# Create Secret in Secrets Manager
# This script stores a secret encrypted with the KMS customer managed key

set -e

# Read KMS key ID
if [ ! -f kms-key-id.txt ]; then
  echo "Error: kms-key-id.txt not found. Run create-kms-key.sh first."
  exit 1
fi

KMS_KEY_ID=$(cat kms-key-id.txt)

echo "Creating secret in Secrets Manager..."

# Secret value (database credentials example)
SECRET_VALUE='{
  "username": "admin",
  "password": "MySecurePassword123!",
  "engine": "mysql",
  "host": "mydb.example.com",
  "port": 3306,
  "dbname": "production"
}'

# Create secret
SECRET_ARN=$(aws secretsmanager create-secret \
  --name db-credentials \
  --description "Database credentials encrypted with customer managed KMS key" \
  --kms-key-id "$KMS_KEY_ID" \
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
echo "  - KMS Key: $KMS_KEY_ID"
echo "  - Encryption: AES-256-GCM (envelope encryption)"
echo ""
echo "Secret contains:"
echo "  - Database username"
echo "  - Database password"
echo "  - Database host"
echo "  - Database port"
echo "  - Database name"
