#!/bin/bash

# Create KMS Customer Managed Key
# This script creates a KMS key for encrypting Secrets Manager secrets

set -e

echo "Creating KMS Customer Managed Key..."

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create KMS key
KEY_METADATA=$(aws kms create-key \
  --description "Customer managed key for Secrets Manager encryption" \
  --key-usage ENCRYPT_DECRYPT \
  --origin AWS_KMS \
  --multi-region false)

KEY_ID=$(echo "$KEY_METADATA" | jq -r '.KeyMetadata.KeyId')
KEY_ARN=$(echo "$KEY_METADATA" | jq -r '.KeyMetadata.Arn')

echo "KMS Key created: $KEY_ID"

# Save key information
echo "$KEY_ID" > kms-key-id.txt
echo "$KEY_ARN" > kms-key-arn.txt

# Create key alias
aws kms create-alias \
  --alias-name alias/secrets-manager-key \
  --target-key-id "$KEY_ID"

echo "Key alias created: alias/secrets-manager-key"

# Enable automatic key rotation
aws kms enable-key-rotation --key-id "$KEY_ID"

echo "Automatic key rotation enabled (annual)"

echo "✓ KMS key created successfully"
echo ""
echo "Key Configuration:"
echo "  - Key ID: $KEY_ID"
echo "  - Key ARN: $KEY_ARN"
echo "  - Alias: alias/secrets-manager-key"
echo "  - Key Spec: SYMMETRIC_DEFAULT"
echo "  - Key Usage: ENCRYPT_DECRYPT"
echo "  - Rotation: Enabled (annual)"
echo "  - Multi-Region: No"
