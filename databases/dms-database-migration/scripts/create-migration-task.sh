#!/bin/bash

# Create DMS Migration Task
# This script creates a migration task with full load and CDC

set -e

# Configuration
TASK_IDENTIFIER="mysql-to-aurora-migration"
REPLICATION_INSTANCE_ARN="arn:aws:dms:us-east-1:[ACCOUNT-ID]:rep:xxxxx"
SOURCE_ENDPOINT_ARN="arn:aws:dms:us-east-1:[ACCOUNT-ID]:endpoint:xxxxx"
TARGET_ENDPOINT_ARN="arn:aws:dms:us-east-1:[ACCOUNT-ID]:endpoint:xxxxx"
MIGRATION_TYPE="full-load-and-cdc"
TABLE_MAPPINGS_FILE="configs/table-mappings.json"
REGION="us-east-1"

echo "Creating DMS migration task: $TASK_IDENTIFIER"
echo "Migration Type: $MIGRATION_TYPE"
echo "Source: MySQL RDS"
echo "Target: Aurora MySQL"

# Read table mappings
TABLE_MAPPINGS=$(cat "$TABLE_MAPPINGS_FILE")

# Create migration task
aws dms create-replication-task \
    --replication-task-identifier "$TASK_IDENTIFIER" \
    --source-endpoint-arn "$SOURCE_ENDPOINT_ARN" \
    --target-endpoint-arn "$TARGET_ENDPOINT_ARN" \
    --replication-instance-arn "$REPLICATION_INSTANCE_ARN" \
    --migration-type "$MIGRATION_TYPE" \
    --table-mappings "$TABLE_MAPPINGS" \
    --replication-task-settings '{
        "TargetMetadata": {
            "SupportLobs": true,
            "FullLobMode": false,
            "LobChunkSize": 64,
            "LimitedSizeLobMode": true,
            "LobMaxSize": 32
        },
        "FullLoadSettings": {
            "TargetTablePrepMode": "DROP_AND_CREATE",
            "CreatePkAfterFullLoad": false,
            "StopTaskCachedChangesApplied": false,
            "StopTaskCachedChangesNotApplied": false,
            "MaxFullLoadSubTasks": 8,
            "TransactionConsistencyTimeout": 600
        },
        "Logging": {
            "EnableLogging": true,
            "LogComponents": [{
                "Id": "TRANSFORMATION",
                "Severity": "LOGGER_SEVERITY_DEFAULT"
            }, {
                "Id": "SOURCE_CAPTURE",
                "Severity": "LOGGER_SEVERITY_INFO"
            }, {
                "Id": "TARGET_APPLY",
                "Severity": "LOGGER_SEVERITY_INFO"
            }]
        },
        "ChangeProcessingDdlHandlingPolicy": {
            "HandleSourceTableDropped": true,
            "HandleSourceTableTruncated": true,
            "HandleSourceTableAltered": true
        },
        "ValidationSettings": {
            "EnableValidation": true,
            "ValidationMode": "ROW_LEVEL"
        }
    }' \
    --tags Key=Name,Value="$TASK_IDENTIFIER" \
           Key=Environment,Value=Production \
    --region "$REGION"

echo "Migration task created successfully!"
echo ""
echo "Task Identifier: $TASK_IDENTIFIER"
echo "Migration Type: $MIGRATION_TYPE"
echo ""
echo "To start the migration task:"
echo "aws dms start-replication-task --replication-task-arn <task-arn> --start-replication-task-type start-replication"
echo ""
echo "To monitor the migration:"
echo "./scripts/monitor-migration.sh"
