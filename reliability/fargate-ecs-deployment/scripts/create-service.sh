#!/bin/bash

# Create ECS Service for URL Checker
# This script creates a Fargate service with networking configuration

set -e

# Configuration
CLUSTER_NAME="lab-cluster-fargate"
SERVICE_NAME="url-checker-service"
TASK_DEFINITION="url-checker"
REGION="us-west-2"
DESIRED_COUNT=1

echo "Creating ECS Service..."
echo "Cluster: $CLUSTER_NAME"
echo "Service: $SERVICE_NAME"
echo "Task Definition: $TASK_DEFINITION"
echo "Region: $REGION"

# Get VPC ID (assumes Lab VPC exists)
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=Lab VPC" \
  --region "$REGION" \
  --query 'Vpcs[0].VpcId' \
  --output text 2>/dev/null || echo "")

if [ -z "$VPC_ID" ] || [ "$VPC_ID" == "None" ]; then
  echo "Warning: Lab VPC not found. Using default VPC..."
  VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=isDefault,Values=true" \
    --region "$REGION" \
    --query 'Vpcs[0].VpcId' \
    --output text)
fi

echo "VPC ID: $VPC_ID"

# Get public subnets
SUBNETS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=map-public-ip-on-launch,Values=true" \
  --region "$REGION" \
  --query 'Subnets[*].SubnetId' \
  --output text | tr '\t' ',')

if [ -z "$SUBNETS" ]; then
  echo "Warning: No public subnets found. Using all subnets..."
  SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --region "$REGION" \
    --query 'Subnets[*].SubnetId' \
    --output text | tr '\t' ',')
fi

echo "Subnets: $SUBNETS"

# Get or create security group
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=URLCheckerAppSecurityGroup" "Name=vpc-id,Values=$VPC_ID" \
  --region "$REGION" \
  --query 'SecurityGroups[0].GroupId' \
  --output text 2>/dev/null || echo "")

if [ -z "$SG_ID" ] || [ "$SG_ID" == "None" ]; then
  echo "Creating security group..."
  SG_ID=$(aws ec2 create-security-group \
    --group-name URLCheckerAppSecurityGroup \
    --description "Security group for URL Checker ECS tasks" \
    --vpc-id "$VPC_ID" \
    --region "$REGION" \
    --query 'GroupId' \
    --output text)
  
  # Allow HTTP inbound (for demonstration)
  aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region "$REGION" 2>/dev/null || true
  
  # Allow all outbound (default)
  echo "✓ Security group created: $SG_ID"
else
  echo "Using existing security group: $SG_ID"
fi

# Create the service
echo ""
echo "Creating service..."
SERVICE_ARN=$(aws ecs create-service \
  --cluster "$CLUSTER_NAME" \
  --service-name "$SERVICE_NAME" \
  --task-definition "$TASK_DEFINITION" \
  --desired-count "$DESIRED_COUNT" \
  --launch-type FARGATE \
  --platform-version LATEST \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
  --region "$REGION" \
  --tags key=Environment,value=Lab key=ManagedBy,value=CLI \
  --query 'service.serviceArn' \
  --output text)

echo "✓ Service created successfully!"
echo "Service ARN: $SERVICE_ARN"

# Wait for service to stabilize
echo ""
echo "Waiting for service to stabilize (this may take a few minutes)..."
aws ecs wait services-stable \
  --cluster "$CLUSTER_NAME" \
  --services "$SERVICE_NAME" \
  --region "$REGION"

# Display service details
echo ""
echo "Service Details:"
aws ecs describe-services \
  --cluster "$CLUSTER_NAME" \
  --services "$SERVICE_NAME" \
  --region "$REGION" \
  --query 'services[0].{Name:serviceName,Status:status,DesiredCount:desiredCount,RunningCount:runningCount,PendingCount:pendingCount}' \
  --output table

echo ""
echo "Next steps:"
echo "1. Monitor the service: ./monitor-service.sh"
echo "2. View logs in CloudWatch Logs console"
echo ""
echo "Note: The url-checker task is designed to run once and exit."
echo "After completion, you'll see 0 running tasks, which is expected behavior."
