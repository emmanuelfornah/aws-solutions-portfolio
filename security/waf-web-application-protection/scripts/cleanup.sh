#!/bin/bash

# Cleanup AWS WAF Resources
# This script removes all WAF resources created during setup

set -e

echo "Cleaning up AWS WAF resources..."

# Disassociate Web ACL from ALB (if associated)
if [ -f web-acl-arn.txt ] && [ -f alb-arn.txt ]; then
  WEB_ACL_ARN=$(cat web-acl-arn.txt)
  ALB_ARN=$(cat alb-arn.txt)
  
  echo "Disassociating Web ACL from ALB..."
  aws wafv2 disassociate-web-acl \
    --resource-arn "$ALB_ARN" \
    --region us-east-1 || true
fi

# Delete Web ACL
if [ -f web-acl-id.txt ]; then
  WEB_ACL_ID=$(cat web-acl-id.txt)
  
  echo "Deleting Web ACL: $WEB_ACL_ID"
  
  # Get lock token
  LOCK_TOKEN=$(aws wafv2 get-web-acl \
    --scope REGIONAL \
    --id "$WEB_ACL_ID" \
    --name WebAppProtectionACL \
    --region us-east-1 \
    --query 'LockToken' \
    --output text) || true
  
  if [ -n "$LOCK_TOKEN" ]; then
    aws wafv2 delete-web-acl \
      --scope REGIONAL \
      --id "$WEB_ACL_ID" \
      --name WebAppProtectionACL \
      --lock-token "$LOCK_TOKEN" \
      --region us-east-1 || true
  fi
  
  rm -f web-acl-id.txt web-acl-arn.txt
fi

# Delete IP sets (if created)
if [ -f ip-set-id.txt ]; then
  IP_SET_ID=$(cat ip-set-id.txt)
  echo "Deleting IP Set: $IP_SET_ID"
  
  LOCK_TOKEN=$(aws wafv2 get-ip-set \
    --scope REGIONAL \
    --id "$IP_SET_ID" \
    --name AdminIPSet \
    --region us-east-1 \
    --query 'LockToken' \
    --output text) || true
  
  if [ -n "$LOCK_TOKEN" ]; then
    aws wafv2 delete-ip-set \
      --scope REGIONAL \
      --id "$IP_SET_ID" \
      --name AdminIPSet \
      --lock-token "$LOCK_TOKEN" \
      --region us-east-1 || true
  fi
  
  rm -f ip-set-id.txt
fi

# Clean up local files
rm -f alb-arn.txt alb-endpoint.txt

echo "✓ Cleanup completed successfully"
echo ""
echo "All WAF resources have been removed."
