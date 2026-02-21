#!/bin/bash

# Create VPC Endpoints for Private Connectivity
# Enables Zero Trust by eliminating internet exposure

set -e

VPC_ID="${1:-vpc-12345}"
SUBNET_IDS="${2:-subnet-abc,subnet-def}"
SECURITY_GROUP_ID="${3:-sg-12345}"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
API_ID=$(cat api-id.txt)

echo "Creating VPC endpoint for API Gateway..."
echo "VPC: $VPC_ID"
echo "Subnets: $SUBNET_IDS"
echo "Security Group: $SECURITY_GROUP_ID"

# Create endpoint policy
cat > endpoint-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*"
    }
  ]
}
EOF

# Create VPC endpoint for API Gateway
ENDPOINT_ID=$(aws ec2 create-vpc-endpoint \
  --vpc-id "$VPC_ID" \
  --vpc-endpoint-type Interface \
  --service-name "com.amazonaws.$REGION.execute-api" \
  --subnet-ids $(echo $SUBNET_IDS | tr ',' ' ') \
  --security-group-ids "$SECURITY_GROUP_ID" \
  --private-dns-enabled \
  --policy-document file://endpoint-policy.json \
  --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=API-Gateway-Endpoint},{Key=Purpose,Value=ZeroTrust}]" \
  --query 'VpcEndpoint.VpcEndpointId' \
  --output text)

echo ""
echo "VPC Endpoint created successfully!"
echo "Endpoint ID: $ENDPOINT_ID"

# Save endpoint ID
echo "$ENDPOINT_ID" > vpc-endpoint-id.txt

# Wait for endpoint to be available
echo ""
echo "Waiting for endpoint to become available..."
aws ec2 wait vpc-endpoint-available --vpc-endpoint-ids "$ENDPOINT_ID"

# Get endpoint DNS names
echo ""
echo "Endpoint DNS names:"
aws ec2 describe-vpc-endpoints \
  --vpc-endpoint-ids "$ENDPOINT_ID" \
  --query 'VpcEndpoints[0].DnsEntries[*].DnsName' \
  --output table

echo ""
echo "Private DNS enabled: Services can use standard API Gateway URLs"
echo "Traffic will route through VPC endpoint instead of internet"
