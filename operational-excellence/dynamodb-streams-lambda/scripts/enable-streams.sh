#!/bin/bash

# Enable DynamoDB Streams on Table
# This script enables streams with NEW_AND_OLD_IMAGES view type

set -e

# Configuration
TABLE_NAME="Users"
STREAM_VIEW_TYPE="NEW_AND_OLD_IMAGES"
REGION="us-east-1"

echo "Enabling DynamoDB Streams on table: $TABLE_NAME"
echo "Stream View Type: $STREAM_VIEW_TYPE"

# Enable streams
aws dynamodb update-table \
    --table-name "$TABLE_NAME" \
    --stream-specification \
        StreamEnabled=true,StreamViewType="$STREAM_VIEW_TYPE" \
    --region "$REGION"

echo "Streams enabled. Waiting for update to complete..."

# Wait for table update
aws dynamodb wait table-exists \
    --table-name "$TABLE_NAME" \
    --region "$REGION"

# Get stream ARN
STREAM_ARN=$(aws dynamodb describe-table \
    --table-name "$TABLE_NAME" \
    --region "$REGION" \
    --query 'Table.LatestStreamArn' \
    --output text)

echo ""
echo "DynamoDB Streams enabled successfully!"
echo "Stream ARN: $STREAM_ARN"
echo ""
echo "Next steps:"
echo "1. Create Lambda function to process stream events"
echo "2. Create event source mapping: aws lambda create-event-source-mapping --function-name MyFunction --event-source-arn $STREAM_ARN"
