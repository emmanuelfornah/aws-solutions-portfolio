#!/bin/bash

# Create DynamoDB Table with Partition and Sort Keys
# This script creates a DynamoDB table with appropriate key schema

set -e

# Configuration
TABLE_NAME="Users"
PARTITION_KEY="UserId"
SORT_KEY="Timestamp"
REGION="us-east-1"

echo "Creating DynamoDB table: $TABLE_NAME"
echo "Partition Key: $PARTITION_KEY (String)"
echo "Sort Key: $SORT_KEY (Number)"

# Create table with provisioned capacity
aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions \
        AttributeName="$PARTITION_KEY",AttributeType=S \
        AttributeName="$SORT_KEY",AttributeType=N \
    --key-schema \
        AttributeName="$PARTITION_KEY",KeyType=HASH \
        AttributeName="$SORT_KEY",KeyType=RANGE \
    --provisioned-throughput \
        ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --tags \
        Key=Name,Value="$TABLE_NAME" \
        Key=Environment,Value=Development \
    --region "$REGION"

echo "Table creation initiated. Waiting for table to become active..."

# Wait for table to be active
aws dynamodb wait table-exists \
    --table-name "$TABLE_NAME" \
    --region "$REGION"

echo "Table created successfully!"

# Describe table
aws dynamodb describe-table \
    --table-name "$TABLE_NAME" \
    --region "$REGION" \
    --query 'Table.[TableName,TableStatus,KeySchema,AttributeDefinitions,ProvisionedThroughput]'
