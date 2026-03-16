#!/bin/bash

# Cleanup OIDC Provider and IAM Role
# Remove all resources created during setup

set -e

ROLE_NAME="WebIdentityRole"
POLICY_NAME="FederatedUserS3Access"

echo "Cleaning up project resources..."

# Get policy ARN
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME"

# Detach policies from role
echo "Detaching policies from role..."
aws iam detach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn "$POLICY_ARN" 2>/dev/null || true

aws iam detach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess" 2>/dev/null || true

# Delete custom policy
echo "Deleting custom policy..."
aws iam delete-policy --policy-arn "$POLICY_ARN" 2>/dev/null || true

# Delete IAM role
echo "Deleting IAM role..."
aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null || true

# Delete OIDC provider
if [ -f provider-arn.txt ]; then
  PROVIDER_ARN=$(cat provider-arn.txt)
  echo "Deleting OIDC provider..."
  aws iam delete-open-id-connect-provider \
    --open-id-connect-provider-arn "$PROVIDER_ARN" 2>/dev/null || true
fi

# Remove temporary files
echo "Removing temporary files..."
rm -f provider-arn.txt role-arn.txt trust-policy.json s3-access-policy.json
rm -f temp-credentials.json temp-credentials.sh

echo ""
echo "Cleanup completed successfully!"
