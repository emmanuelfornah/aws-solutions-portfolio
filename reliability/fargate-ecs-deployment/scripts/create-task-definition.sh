#!/bin/bash

# Create ECS Task Definition for URL Checker on Fargate
# This script registers a task definition using the JSON configuration file

set -e

# Configuration
REGION="us-west-2"
TASK_DEF_FILE="../configs/task-definition.json"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Creating ECS Task Definition..."
echo "Region: $REGION"
echo "Account ID: $ACCOUNT_ID"

# Replace placeholder with actual account ID
TEMP_FILE=$(mktemp)
sed "s/<ACCOUNT_ID>/$ACCOUNT_ID/g" "$TASK_DEF_FILE" > "$TEMP_FILE"

# Register the task definition
echo "Registering task definition..."
TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json file://"$TEMP_FILE" \
  --region "$REGION" \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

# Clean up temp file
rm "$TEMP_FILE"

echo "✓ Task definition registered successfully!"
echo "Task Definition ARN: $TASK_DEF_ARN"

# Display task definition details
echo ""
echo "Task Definition Details:"
aws ecs describe-task-definition \
  --task-definition url-checker \
  --region "$REGION" \
  --query 'taskDefinition.{Family:family,Revision:revision,Status:status,CPU:cpu,Memory:memory,NetworkMode:networkMode}' \
  --output table

echo ""
echo "Container Configuration:"
aws ecs describe-task-definition \
  --task-definition url-checker \
  --region "$REGION" \
  --query 'taskDefinition.containerDefinitions[0].{Name:name,Image:image,Essential:essential}' \
  --output table

echo ""
echo "Next steps:"
echo "1. Create an ECS cluster: ./create-cluster.sh"
echo "2. Create an ECS service: ./create-service.sh"
