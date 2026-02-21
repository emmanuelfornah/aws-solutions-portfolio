#!/bin/bash

# Create RDS MySQL Instance with Multi-AZ
# This script creates an RDS instance with Multi-AZ deployment enabled

set -e

# Configuration
DB_INSTANCE_ID="mydb"
DB_ENGINE="mysql"
DB_ENGINE_VERSION="8.0.35"
DB_INSTANCE_CLASS="db.t3.micro"
ALLOCATED_STORAGE=20
DB_SUBNET_GROUP="mydb-subnet-group"
SECURITY_GROUP="sg-xxxxx"  # Replace with your security group ID
SECRET_NAME="rds/mydb/credentials"
REGION="us-east-1"

echo "Retrieving database credentials from Secrets Manager..."
SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --query SecretString \
    --output text)

DB_USERNAME=$(echo "$SECRET_JSON" | jq -r '.username')
DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')

echo "Creating RDS MySQL instance: $DB_INSTANCE_ID"

aws rds create-db-instance \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --db-instance-class "$DB_INSTANCE_CLASS" \
    --engine "$DB_ENGINE" \
    --engine-version "$DB_ENGINE_VERSION" \
    --master-username "$DB_USERNAME" \
    --master-user-password "$DB_PASSWORD" \
    --allocated-storage "$ALLOCATED_STORAGE" \
    --storage-type gp3 \
    --storage-encrypted \
    --multi-az \
    --db-subnet-group-name "$DB_SUBNET_GROUP" \
    --vpc-security-group-ids "$SECURITY_GROUP" \
    --backup-retention-period 7 \
    --preferred-backup-window "03:00-04:00" \
    --preferred-maintenance-window "mon:04:00-mon:05:00" \
    --enable-cloudwatch-logs-exports '["error","slowquery"]' \
    --monitoring-interval 60 \
    --monitoring-role-arn "arn:aws:iam::[ACCOUNT-ID]:role/rds-monitoring-role" \
    --tags Key=Name,Value="$DB_INSTANCE_ID" \
           Key=Environment,Value=Production

echo "RDS instance creation initiated"
echo "Waiting for instance to become available (this may take 10-15 minutes)..."

aws rds wait db-instance-available \
    --db-instance-identifier "$DB_INSTANCE_ID"

echo "RDS instance is now available"

# Get endpoint and update secret
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo "Database endpoint: $DB_ENDPOINT"

# Update secret with endpoint
UPDATED_SECRET=$(echo "$SECRET_JSON" | jq --arg endpoint "$DB_ENDPOINT" \
    '. + {host: $endpoint, dbInstanceIdentifier: "'$DB_INSTANCE_ID'"}')

aws secretsmanager update-secret \
    --secret-id "$SECRET_NAME" \
    --secret-string "$UPDATED_SECRET" \
    --region "$REGION"

echo "Secret updated with database endpoint"
echo "RDS instance created successfully!"
