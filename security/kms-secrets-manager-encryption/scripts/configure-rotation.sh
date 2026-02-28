#!/bin/bash

# Configure Automatic Secret Rotation
# This script enables automatic rotation for the secret

set -e

# Read secret name
if [ ! -f secret-name.txt ]; then
  echo "Error: secret-name.txt not found. Run create-secret.sh first."
  exit 1
fi

SECRET_NAME=$(cat secret-name.txt)

echo "Configuring automatic rotation for secret: $SECRET_NAME"

# Note: For RDS/Aurora, Secrets Manager provides built-in rotation
# For custom secrets, you need to create a Lambda rotation function

# Enable rotation (30 days)
aws secretsmanager rotate-secret \
  --secret-id "$SECRET_NAME" \
  --rotation-rules AutomaticallyAfterDays=30

echo "✓ Automatic rotation configured"
echo ""
echo "Rotation Configuration:"
echo "  - Rotation Interval: 30 days"
echo "  - Rotation Lambda: AWS managed (for RDS)"
echo "  - Next Rotation: 30 days from now"
echo ""
echo "Note: For production use with RDS/Aurora:"
echo "  1. Use Secrets Manager's built-in rotation"
echo "  2. Specify rotation Lambda ARN"
echo "  3. Test rotation before enabling"
echo ""
echo "Example with RDS rotation:"
echo "  aws secretsmanager rotate-secret \\"
echo "    --secret-id $SECRET_NAME \\"
echo "    --rotation-lambda-arn arn:aws:lambda:region:account:function:SecretsManagerRotation \\"
echo "    --rotation-rules AutomaticallyAfterDays=30"
