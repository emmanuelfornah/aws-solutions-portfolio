#!/bin/bash

# Create OIDC Identity Provider in IAM
# This script creates an OIDC provider for web identity federation

set -e

# Configuration
PROVIDER_URL="https://auth.provider.com"  # Replace with your OIDC provider URL
CLIENT_ID="your-client-id"                # Replace with your client ID

echo "Creating OIDC Identity Provider..."

# Get provider thumbprint (SSL certificate fingerprint)
# This retrieves the thumbprint of the top intermediate CA in the certificate chain
THUMBPRINT=$(echo | openssl s_client -servername ${PROVIDER_URL#https://} \
  -connect ${PROVIDER_URL#https://}:443 2>/dev/null | \
  openssl x509 -fingerprint -noout | \
  sed 's/://g' | \
  awk -F= '{print tolower($2)}')

echo "Provider thumbprint: $THUMBPRINT"

# Create OIDC provider
aws iam create-open-id-connect-provider \
  --url "$PROVIDER_URL" \
  --client-id-list "$CLIENT_ID" \
  --thumbprint-list "$THUMBPRINT" \
  --tags Key=Purpose,Value=WebIdentityFederation Key=Environment,Value=Dev

# Get provider ARN
PROVIDER_ARN=$(aws iam list-open-id-connect-providers --query \
  "OpenIDConnectProviderList[?contains(Arn, '${PROVIDER_URL#https://}')].Arn" \
  --output text)

echo "OIDC Provider created successfully!"
echo "Provider ARN: $PROVIDER_ARN"
echo ""
echo "Save this ARN for creating the IAM role trust policy."

# Save provider ARN to file
echo "$PROVIDER_ARN" > provider-arn.txt

# Verify provider configuration
echo ""
echo "Provider Configuration:"
aws iam get-open-id-connect-provider \
  --open-id-connect-provider-arn "$PROVIDER_ARN"
