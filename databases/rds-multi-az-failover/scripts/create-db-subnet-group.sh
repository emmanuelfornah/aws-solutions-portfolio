#!/bin/bash

# Create DB Subnet Group for Multi-AZ RDS Deployment
# This script creates a DB subnet group spanning multiple Availability Zones

set -e

# Configuration
DB_SUBNET_GROUP_NAME="mydb-subnet-group"
DESCRIPTION="DB subnet group for Multi-AZ deployment"
VPC_ID="vpc-xxxxx"  # Replace with your VPC ID
SUBNET_1="subnet-xxxxx"  # Replace with subnet in AZ 1
SUBNET_2="subnet-yyyyy"  # Replace with subnet in AZ 2

echo "Creating DB subnet group: $DB_SUBNET_GROUP_NAME"

aws rds create-db-subnet-group \
    --db-subnet-group-name "$DB_SUBNET_GROUP_NAME" \
    --db-subnet-group-description "$DESCRIPTION" \
    --subnet-ids "$SUBNET_1" "$SUBNET_2" \
    --tags Key=Name,Value="$DB_SUBNET_GROUP_NAME" \
           Key=Environment,Value=Production

echo "DB subnet group created successfully"

# Verify creation
aws rds describe-db-subnet-groups \
    --db-subnet-group-name "$DB_SUBNET_GROUP_NAME"
