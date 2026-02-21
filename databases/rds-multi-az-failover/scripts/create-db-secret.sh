#!/bin/bash

# Create Secrets Manager Secret for RDS Credentials
# This script creates a secret to store database credentials securely

set -e

# Configuration
SECRET_NAME="rds/mydb/credentials"
DB_USERNAME="admin"
DB_PASSWORD=$(openssl rand -base64 32)  # Generate secure password
REGION="us-east-1"

echo "Creating Secrets Manager secret: $SECRET_NAME"

# Create secret with initial credentials
aws secretsmanager create-secret \
    --name "$SECRET_NAME" \
    --description "RDS MySQL database credentials" \
    --secret-string "{
        \"username\": \"$DB_USERNAME\",
        \"password\": \"$DB_PASSWORD\",
        \"engine\": \"mysql\",
        \"port\": 3306
    }" \
    --region "$REGION" \
    --tags Key=Name,Value="$SECRET_NAME" \
           Key=Environment,Value=Production

echo "Secret created successfully"
echo "Username: $DB_USERNAME"
echo "Password stored in Secrets Manager"

# Retrieve secret to verify
aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --query SecretString \
    --output text | jq .
