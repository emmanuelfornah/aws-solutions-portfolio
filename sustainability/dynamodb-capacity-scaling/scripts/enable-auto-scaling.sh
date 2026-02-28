#!/bin/bash

# Enable Auto Scaling for DynamoDB Table
# This script configures auto scaling for read and write capacity

set -e

# Configuration
TABLE_NAME="Users"
MIN_READ_CAPACITY=5
MAX_READ_CAPACITY=100
TARGET_READ_UTILIZATION=70
MIN_WRITE_CAPACITY=5
MAX_WRITE_CAPACITY=100
TARGET_WRITE_UTILIZATION=70
REGION="us-east-1"

echo "Enabling auto scaling for table: $TABLE_NAME"
echo "Read Capacity: $MIN_READ_CAPACITY - $MAX_READ_CAPACITY (Target: ${TARGET_READ_UTILIZATION}%)"
echo "Write Capacity: $MIN_WRITE_CAPACITY - $MAX_WRITE_CAPACITY (Target: ${TARGET_WRITE_UTILIZATION}%)"

# Register scalable target for read capacity
aws application-autoscaling register-scalable-target \
    --service-namespace dynamodb \
    --resource-id "table/$TABLE_NAME" \
    --scalable-dimension dynamodb:table:ReadCapacityUnits \
    --min-capacity "$MIN_READ_CAPACITY" \
    --max-capacity "$MAX_READ_CAPACITY" \
    --region "$REGION"

# Register scalable target for write capacity
aws application-autoscaling register-scalable-target \
    --service-namespace dynamodb \
    --resource-id "table/$TABLE_NAME" \
    --scalable-dimension dynamodb:table:WriteCapacityUnits \
    --min-capacity "$MIN_WRITE_CAPACITY" \
    --max-capacity "$MAX_WRITE_CAPACITY" \
    --region "$REGION"

# Create scaling policy for read capacity
aws application-autoscaling put-scaling-policy \
    --service-namespace dynamodb \
    --resource-id "table/$TABLE_NAME" \
    --scalable-dimension dynamodb:table:ReadCapacityUnits \
    --policy-name "${TABLE_NAME}-read-scaling-policy" \
    --policy-type TargetTrackingScaling \
    --target-tracking-scaling-policy-configuration "{
        \"TargetValue\": $TARGET_READ_UTILIZATION,
        \"PredefinedMetricSpecification\": {
            \"PredefinedMetricType\": \"DynamoDBReadCapacityUtilization\"
        },
        \"ScaleOutCooldown\": 60,
        \"ScaleInCooldown\": 60
    }" \
    --region "$REGION"

# Create scaling policy for write capacity
aws application-autoscaling put-scaling-policy \
    --service-namespace dynamodb \
    --resource-id "table/$TABLE_NAME" \
    --scalable-dimension dynamodb:table:WriteCapacityUnits \
    --policy-name "${TABLE_NAME}-write-scaling-policy" \
    --policy-type TargetTrackingScaling \
    --target-tracking-scaling-policy-configuration "{
        \"TargetValue\": $TARGET_WRITE_UTILIZATION,
        \"PredefinedMetricSpecification\": {
            \"PredefinedMetricType\": \"DynamoDBWriteCapacityUtilization\"
        },
        \"ScaleOutCooldown\": 60,
        \"ScaleInCooldown\": 60
    }" \
    --region "$REGION"

echo ""
echo "Auto scaling enabled successfully!"
echo ""
echo "Scaling Configuration:"
echo "- Read Capacity: $MIN_READ_CAPACITY - $MAX_READ_CAPACITY units"
echo "- Write Capacity: $MIN_WRITE_CAPACITY - $MAX_WRITE_CAPACITY units"
echo "- Target Utilization: ${TARGET_READ_UTILIZATION}% (read), ${TARGET_WRITE_UTILIZATION}% (write)"
echo "- Cooldown Period: 60 seconds"
echo ""
echo "Monitor scaling activity:"
echo "aws application-autoscaling describe-scaling-activities --service-namespace dynamodb --resource-id table/$TABLE_NAME"
