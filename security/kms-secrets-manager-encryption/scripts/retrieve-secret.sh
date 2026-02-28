#!/bin/bash

# Retrieve Secret from Secrets Manager
# This script demonstrates programmatic secret retrieval

set -e

# Read secret name
if [ ! -f secret-name.txt ]; then
  echo "Error: secret-name.txt not found. Run create-secret.sh first."
  exit 1
fi

SECRET_NAME=$(cat secret-name.txt)

echo "Retrieving secret: $SECRET_NAME"
echo ""

# Get secret value
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --query 'SecretString' \
  --output text)

echo "Secret retrieved successfully!"
echo ""
echo "Secret Value:"
echo "$SECRET_JSON" | jq '.'
echo ""

# Extract individual values
USERNAME=$(echo "$SECRET_JSON" | jq -r '.username')
HOST=$(echo "$SECRET_JSON" | jq -r '.host')
PORT=$(echo "$SECRET_JSON" | jq -r '.port')
DBNAME=$(echo "$SECRET_JSON" | jq -r '.dbname')

echo "Parsed Values:"
echo "  - Username: $USERNAME"
echo "  - Host: $HOST"
echo "  - Port: $PORT"
echo "  - Database: $DBNAME"
echo "  - Password: [REDACTED]"
echo ""

# Example: Use secret to connect to database
echo "Example connection string:"
echo "mysql -h $HOST -P $PORT -u $USERNAME -p $DBNAME"
echo ""

# Get secret metadata
echo "Secret Metadata:"
aws secretsmanager describe-secret \
  --secret-id "$SECRET_NAME" \
  --query '{Name:Name,KmsKeyId:KmsKeyId,RotationEnabled:RotationEnabled,LastRotatedDate:LastRotatedDate,LastAccessedDate:LastAccessedDate}' \
  --output table
