#!/bin/bash

# Cleanup KMS and Secrets Manager Resources
# This script removes all resources created during setup

set -e

echo "Cleaning up KMS and Secrets Manager resources..."

# Delete secret (with recovery window)
if [ -f secret-name.txt ]; then
  SECRET_NAME=$(cat secret-name.txt)
  echo "Scheduling secret deletion: $SECRET_NAME"
  
  aws secretsmanager delete-secret \
    --secret-id "$SECRET_NAME" \
    --recovery-window-in-days 7 || true
  
  echo "Secret scheduled for deletion (7-day recovery window)"
  rm -f secret-name.txt secret-arn.txt
fi

# Schedule KMS key deletion
if [ -f kms-key-id.txt ]; then
  KMS_KEY_ID=$(cat kms-key-id.txt)
  echo "Scheduling KMS key deletion: $KMS_KEY_ID"
  
  # Delete key alias first
  aws kms delete-alias \
    --alias-name alias/secrets-manager-key || true
  
  # Schedule key deletion (minimum 7 days)
  aws kms schedule-key-deletion \
    --key-id "$KMS_KEY_ID" \
    --pending-window-in-days 7 || true
  
  echo "KMS key scheduled for deletion (7-day waiting period)"
  rm -f kms-key-id.txt kms-key-arn.txt
fi

# Clean up IAM role (if created)
if [ -f iam-role-name.txt ]; then
  ROLE_NAME=$(cat iam-role-name.txt)
  echo "Deleting IAM role: $ROLE_NAME"
  
  # Detach policies
  aws iam detach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/SecretsManagerReadWrite || true
  
  # Delete role
  aws iam delete-role --role-name "$ROLE_NAME" || true
  
  rm -f iam-role-name.txt
fi

echo "✓ Cleanup completed"
echo ""
echo "Resources scheduled for deletion:"
echo "  - Secret: 7-day recovery window"
echo "  - KMS Key: 7-day waiting period"
echo ""
echo "To cancel deletion:"
echo "  Secret: aws secretsmanager restore-secret --secret-id <secret-name>"
echo "  KMS Key: aws kms cancel-key-deletion --key-id <key-id>"
