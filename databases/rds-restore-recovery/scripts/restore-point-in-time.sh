#!/bin/bash

# Restore RDS Instance to Point in Time
# This script performs point-in-time recovery to a specific timestamp

set -e

# Configuration
SOURCE_DB_INSTANCE="mydb"
TARGET_DB_INSTANCE="mydb-restored-$(date +%Y%m%d-%H%M%S)"
REGION="us-east-1"

echo "=== RDS Point-in-Time Recovery ==="
echo ""

# Get latest restorable time
LATEST_RESTORABLE=$(aws rds describe-db-instances \
    --db-instance-identifier "$SOURCE_DB_INSTANCE" \
    --region "$REGION" \
    --query 'DBInstances[0].LatestRestorableTime' \
    --output text)

echo "Source DB Instance: $SOURCE_DB_INSTANCE"
echo "Latest Restorable Time: $LATEST_RESTORABLE"
echo ""

# Prompt for restore time
read -p "Enter restore time (YYYY-MM-DDTHH:MM:SSZ) or press Enter for latest: " RESTORE_TIME

if [ -z "$RESTORE_TIME" ]; then
    RESTORE_TIME="$LATEST_RESTORABLE"
    echo "Using latest restorable time: $RESTORE_TIME"
fi

echo ""
echo "Initiating point-in-time restore..."
echo "Target DB Instance: $TARGET_DB_INSTANCE"
echo "Restore Time: $RESTORE_TIME"

# Perform PITR
aws rds restore-db-instance-to-point-in-time \
    --source-db-instance-identifier "$SOURCE_DB_INSTANCE" \
    --target-db-instance-identifier "$TARGET_DB_INSTANCE" \
    --restore-time "$RESTORE_TIME" \
    --region "$REGION"

echo "Restore initiated. Waiting for instance to become available..."
echo "This may take 30-60 minutes depending on database size."

# Wait for instance to be available
aws rds wait db-instance-available \
    --db-instance-identifier "$TARGET_DB_INSTANCE" \
    --region "$REGION"

# Get endpoint
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$TARGET_DB_INSTANCE" \
    --region "$REGION" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo ""
echo "=== Restore Complete ==="
echo "Restored DB Instance: $TARGET_DB_INSTANCE"
echo "Endpoint: $DB_ENDPOINT"
echo "Restore Time: $RESTORE_TIME"
echo ""
echo "Next steps:"
echo "1. Connect to restored instance and verify data"
echo "2. Update application connection strings if needed"
echo "3. Delete old instance if replacing: aws rds delete-db-instance --db-instance-identifier $SOURCE_DB_INSTANCE"
