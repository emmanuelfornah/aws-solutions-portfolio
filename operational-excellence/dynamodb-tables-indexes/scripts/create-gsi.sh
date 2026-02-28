#!/bin/bash

# Create Global Secondary Index on DynamoDB Table
# This script adds a GSI for alternate query patterns

set -e

# Configuration
TABLE_NAME="Users"
INDEX_NAME="EmailIndex"
PARTITION_KEY="Email"
REGION="us-east-1"

echo "Creating Global Secondary Index: $INDEX_NAME"
echo "Table: $TABLE_NAME"
echo "GSI Partition Key: $PARTITION_KEY (String)"

# Update table to add GSI
aws dynamodb update-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions \
        AttributeName="$PARTITION_KEY",AttributeType=S \
    --global-secondary-index-updates \
        "[{
            \"Create\": {
                \"IndexName\": \"$INDEX_NAME\",
                \"KeySchema\": [{
                    \"AttributeName\": \"$PARTITION_KEY\",
                    \"KeyType\": \"HASH\"
                }],
                \"Projection\": {
                    \"ProjectionType\": \"ALL\"
                },
                \"ProvisionedThroughput\": {
                    \"ReadCapacityUnits\": 5,
                    \"WriteCapacityUnits\": 5
                }
            }
        }]" \
    --region "$REGION"

echo "GSI creation initiated. Waiting for index to become active..."
echo "This may take several minutes..."

# Wait for table update to complete
aws dynamodb wait table-exists \
    --table-name "$TABLE_NAME" \
    --region "$REGION"

echo "Global Secondary Index created successfully!"

# Describe table with GSI
aws dynamodb describe-table \
    --table-name "$TABLE_NAME" \
    --region "$REGION" \
    --query 'Table.GlobalSecondaryIndexes'
