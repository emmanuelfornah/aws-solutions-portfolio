#!/bin/bash

# Configure IAM Role Permissions
# Attach policies to allow access to AWS resources

set -e

ROLE_NAME="WebIdentityRole"

echo "Configuring role permissions..."

# Create custom policy for S3 access
cat > s3-access-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": "arn:aws:s3:::federated-user-data-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::federated-user-data-*/\${aws:userid}/*"
    }
  ]
}
EOF

# Create policy
POLICY_ARN=$(aws iam create-policy \
  --policy-name FederatedUserS3Access \
  --policy-document file://s3-access-policy.json \
  --description "S3 access for federated users" \
  --query 'Policy.Arn' \
  --output text)

echo "Policy created: $POLICY_ARN"

# Attach policy to role
aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn "$POLICY_ARN"

# Attach CloudWatch Logs policy
aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"

echo ""
echo "Permissions configured successfully!"
echo "Role can now access:"
echo "  - S3 buckets: federated-user-data-*"
echo "  - CloudWatch Logs"

# List attached policies
echo ""
echo "Attached policies:"
aws iam list-attached-role-policies --role-name "$ROLE_NAME"
