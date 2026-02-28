#!/bin/bash

# Configure API Gateway Resource Policy
# Implements Zero Trust by restricting access to specific principals and VPC endpoints

set -e

API_ID=$(cat api-id.txt)
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
VPC_ENDPOINT_ID="${1:-vpce-12345}"  # Pass VPC endpoint ID as argument

echo "Configuring API Gateway resource policy..."
echo "API ID: $API_ID"
echo "VPC Endpoint: $VPC_ENDPOINT_ID"

# Create resource policy
cat > resource-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::$ACCOUNT_ID:role/ServiceA-Role"
      },
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*",
      "Condition": {
        "StringEquals": {
          "aws:SourceVpce": "$VPC_ENDPOINT_ID"
        }
      }
    },
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*",
      "Condition": {
        "StringNotEquals": {
          "aws:SourceVpce": "$VPC_ENDPOINT_ID"
        }
      }
    }
  ]
}
EOF

echo "Resource policy created:"
cat resource-policy.json

# Update API Gateway with resource policy
aws apigateway update-rest-api \
  --rest-api-id "$API_ID" \
  --patch-operations op=replace,path=/policy,value="$(cat resource-policy.json | jq -c .)" \
  --region "$REGION"

# Redeploy API to apply changes
aws apigateway create-deployment \
  --rest-api-id "$API_ID" \
  --stage-name prod \
  --description "Updated resource policy" \
  --region "$REGION"

echo ""
echo "Resource policy configured successfully!"
echo "Policy enforces:"
echo "  - Only ServiceA-Role can invoke"
echo "  - Must come through VPC endpoint $VPC_ENDPOINT_ID"
echo "  - All other access explicitly denied"
