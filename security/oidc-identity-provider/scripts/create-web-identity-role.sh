#!/bin/bash

# Create IAM Role for Web Identity Federation
# This role trusts the OIDC provider and can be assumed with JWT tokens

set -e

# Configuration
ROLE_NAME="WebIdentityRole"
PROVIDER_ARN=$(cat provider-arn.txt)
PROVIDER_URL="${PROVIDER_ARN##*/}"
CLIENT_ID="your-client-id"  # Replace with your client ID

echo "Creating IAM Role for Web Identity..."

# Create trust policy
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "$PROVIDER_ARN"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "$PROVIDER_URL:aud": "$CLIENT_ID"
        }
      }
    }
  ]
}
EOF

echo "Trust policy created:"
cat trust-policy.json

# Create IAM role
aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document file://trust-policy.json \
  --description "Role for web identity federation with OIDC provider" \
  --tags Key=Purpose,Value=WebIdentityFederation Key=Environment,Value=Lab

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)

echo ""
echo "IAM Role created successfully!"
echo "Role Name: $ROLE_NAME"
echo "Role ARN: $ROLE_ARN"

# Save role ARN
echo "$ROLE_ARN" > role-arn.txt

echo ""
echo "Next step: Attach permissions to the role using configure-role-permissions.sh"
