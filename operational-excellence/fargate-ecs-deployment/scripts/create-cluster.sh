#!/bin/bash

# Create ECS Cluster for Fargate
# This script creates a serverless ECS cluster using Fargate capacity providers

set -e

# Configuration
CLUSTER_NAME="lab-cluster-fargate"
REGION="us-west-2"

echo "Creating ECS Cluster..."
echo "Cluster Name: $CLUSTER_NAME"
echo "Region: $REGION"
echo "Capacity Provider: FARGATE"

# Create the cluster
CLUSTER_ARN=$(aws ecs create-cluster \
  --cluster-name "$CLUSTER_NAME" \
  --capacity-providers FARGATE FARGATE_SPOT \
  --default-capacity-provider-strategy \
    capacityProvider=FARGATE,weight=1,base=1 \
  --region "$REGION" \
  --tags key=Environment,value=Lab key=ManagedBy,value=CLI \
  --query 'cluster.clusterArn' \
  --output text)

echo "✓ Cluster created successfully!"
echo "Cluster ARN: $CLUSTER_ARN"

# Wait for cluster to become active
echo ""
echo "Waiting for cluster to become active..."
aws ecs wait services-stable \
  --cluster "$CLUSTER_NAME" \
  --region "$REGION" 2>/dev/null || true

# Display cluster details
echo ""
echo "Cluster Details:"
aws ecs describe-clusters \
  --clusters "$CLUSTER_NAME" \
  --region "$REGION" \
  --query 'clusters[0].{Name:clusterName,Status:status,RegisteredTasks:registeredContainerInstancesCount,RunningTasks:runningTasksCount,PendingTasks:pendingTasksCount}' \
  --output table

echo ""
echo "Capacity Providers:"
aws ecs describe-clusters \
  --clusters "$CLUSTER_NAME" \
  --region "$REGION" \
  --include SETTINGS \
  --query 'clusters[0].capacityProviders' \
  --output table

echo ""
echo "Next steps:"
echo "1. Ensure task definition is created: ./create-task-definition.sh"
echo "2. Create an ECS service: ./create-service.sh"
