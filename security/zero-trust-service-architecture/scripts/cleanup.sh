#!/bin/bash

# Cleanup Zero Trust Resources
# Removes all created resources

set -e

REGION="us-east-1"

echo "Cleaning up Zero Trust resources..."

# Delete VPC endpoint
if [ -f vpc-endpoint-id.txt ]; then
  ENDPOINT_ID=$(cat vpc-endpoint-id.txt)
  echo "Deleting VPC endpoint: $ENDPOINT_ID"
  aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$ENDPOINT_ID" 2>/dev/null || true
fi

# Delete API Gateway
if [ -f api-id.txt ]; then
  API_ID=$(cat api-id.txt)
  echo "Deleting API Gateway: $API_ID"
  aws apigateway delete-rest-api --rest-api-id "$API_ID" --region "$REGION" 2>/dev/null || true
fi

# Delete IAM roles (if created)
echo "Deleting IAM roles..."
for ROLE in ServiceA-Role ServiceB-Role; do
  # Detach policies
  POLICIES=$(aws iam list-attached-role-policies --role-name "$ROLE" --query 'AttachedPolicies[*].PolicyArn' --output text 2>/dev/null || true)
  for POLICY in $POLICIES; do
    aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$POLICY" 2>/dev/null || true
  done
  
  # Delete inline policies
  INLINE_POLICIES=$(aws iam list-role-policies --role-name "$ROLE" --query 'PolicyNames[*]' --output text 2>/dev/null || true)
  for POLICY in $INLINE_POLICIES; do
    aws iam delete-role-policy --role-name "$ROLE" --policy-name "$POLICY" 2>/dev/null || true
  done
  
  # Delete role
  aws iam delete-role --role-name "$ROLE" 2>/dev/null || true
done

# Remove temporary files
echo "Removing temporary files..."
rm -f api-id.txt vpc-endpoint-id.txt resource-policy.json endpoint-policy.json
rm -f service-a-policy.json service-b-policy.json trust-policy.json

echo ""
echo "Cleanup completed successfully!"
