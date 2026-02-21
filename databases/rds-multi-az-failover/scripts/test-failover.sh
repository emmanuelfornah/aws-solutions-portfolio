#!/bin/bash

# Test RDS Multi-AZ Failover
# This script initiates a failover and measures downtime

set -e

# Configuration
DB_INSTANCE_ID="mydb"
SECRET_NAME="rds/mydb/credentials"
REGION="us-east-1"

echo "=== RDS Multi-AZ Failover Test ==="
echo ""

# Get database endpoint
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo "Database endpoint: $DB_ENDPOINT"
echo "Current Multi-AZ status:"
aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --query 'DBInstances[0].[MultiAZ,AvailabilityZone,SecondaryAvailabilityZone]' \
    --output table

echo ""
echo "Starting failover test..."
echo "Recording start time: $(date)"
START_TIME=$(date +%s)

# Initiate failover
aws rds reboot-db-instance \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --force-failover

echo "Failover initiated"
echo "Monitoring database availability..."

# Monitor connection availability
DOWNTIME_START=$(date +%s)
CONNECTION_RESTORED=false

while [ "$CONNECTION_RESTORED" = false ]; do
    sleep 5
    
    # Try to connect
    if timeout 5 bash -c "echo > /dev/tcp/$DB_ENDPOINT/3306" 2>/dev/null; then
        CONNECTION_RESTORED=true
        DOWNTIME_END=$(date +%s)
        echo "Connection restored at: $(date)"
    else
        echo "Connection unavailable... ($(( $(date +%s) - DOWNTIME_START )) seconds elapsed)"
    fi
done

# Wait for instance to be fully available
echo "Waiting for instance to be fully available..."
aws rds wait db-instance-available \
    --db-instance-identifier "$DB_INSTANCE_ID"

END_TIME=$(date +%s)

# Calculate downtime
TOTAL_TIME=$(( END_TIME - START_TIME ))
DOWNTIME=$(( DOWNTIME_END - DOWNTIME_START ))

echo ""
echo "=== Failover Test Results ==="
echo "Total failover time: $TOTAL_TIME seconds"
echo "Connection downtime: $DOWNTIME seconds"
echo "Failover completed at: $(date)"

# Verify new AZ
echo ""
echo "Post-failover status:"
aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --query 'DBInstances[0].[MultiAZ,AvailabilityZone,SecondaryAvailabilityZone]' \
    --output table

echo ""
echo "Failover test completed successfully!"
