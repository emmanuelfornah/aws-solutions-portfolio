#!/bin/bash

# Create DAX Cluster for DynamoDB Caching
# This script creates a DAX cluster with multiple nodes

set -e

# Configuration
CLUSTER_NAME="my-dax-cluster"
NODE_TYPE="dax.t3.small"
REPLICATION_FACTOR=3
IAM_ROLE_ARN="arn:aws:iam::[ACCOUNT-ID]:role/DAXServiceRole"
SUBNET_GROUP_NAME="my-dax-subnet-group"
SECURITY_GROUP_IDS="sg-xxxxx"
REGION="us-east-1"

echo "Creating DAX cluster: $CLUSTER_NAME"
echo "Node Type: $NODE_TYPE"
echo "Replication Factor: $REPLICATION_FACTOR nodes"

# Create DAX cluster
aws dax create-cluster \
    --cluster-name "$CLUSTER_NAME" \
    --node-type "$NODE_TYPE" \
    --replication-factor "$REPLICATION_FACTOR" \
    --iam-role-arn "$IAM_ROLE_ARN" \
    --subnet-group-name "$SUBNET_GROUP_NAME" \
    --security-group-ids "$SECURITY_GROUP_IDS" \
    --description "DAX cluster for DynamoDB caching" \
    --tags Key=Name,Value="$CLUSTER_NAME" \
           Key=Environment,Value=Production \
    --region "$REGION"

echo "DAX cluster creation initiated"
echo "Waiting for cluster to become available (this may take 10-15 minutes)..."

# Wait for cluster to be available
while true; do
    STATUS=$(aws dax describe-clusters \
        --cluster-names "$CLUSTER_NAME" \
        --region "$REGION" \
        --query 'Clusters[0].Status' \
        --output text)
    
    if [ "$STATUS" = "available" ]; then
        break
    fi
    
    echo "Current status: $STATUS. Waiting..."
    sleep 30
done

# Get cluster endpoint
CLUSTER_ENDPOINT=$(aws dax describe-clusters \
    --cluster-names "$CLUSTER_NAME" \
    --region "$REGION" \
    --query 'Clusters[0].ClusterDiscoveryEndpoint.Address' \
    --output text)

echo ""
echo "DAX cluster created successfully!"
echo "Cluster Name: $CLUSTER_NAME"
echo "Cluster Endpoint: $CLUSTER_ENDPOINT"
echo "Port: 8111"
echo ""
echo "Next steps:"
echo "1. Update application code to use DAX endpoint"
echo "2. Test performance improvements"
echo "3. Monitor DAX metrics in CloudWatch"
