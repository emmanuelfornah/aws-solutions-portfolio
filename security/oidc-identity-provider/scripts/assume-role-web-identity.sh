#!/bin/bash

# Assume Role with Web Identity
# Exchange JWT token for temporary AWS credentials

set -e

# Configuration
ROLE_ARN=$(cat role-arn.txt)
JWT_TOKEN="$1"  # Pass JWT token as argument
SESSION_NAME="user-session-$(date +%s)"
DURATION=3600  # 1 hour

if [ -z "$JWT_TOKEN" ]; then
  echo "Usage: $0 <jwt-token>"
  echo "Example: $0 eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
  exit 1
fi

echo "Assuming role with web identity..."
echo "Role ARN: $ROLE_ARN"
echo "Session Name: $SESSION_NAME"
echo "Duration: $DURATION seconds"

# Assume role with web identity
CREDENTIALS=$(aws sts assume-role-with-web-identity \
  --role-arn "$ROLE_ARN" \
  --role-session-name "$SESSION_NAME" \
  --web-identity-token "$JWT_TOKEN" \
  --duration-seconds $DURATION)

# Extract credentials
ACCESS_KEY=$(echo "$CREDENTIALS" | jq -r '.Credentials.AccessKeyId')
SECRET_KEY=$(echo "$CREDENTIALS" | jq -r '.Credentials.SecretAccessKey')
SESSION_TOKEN=$(echo "$CREDENTIALS" | jq -r '.Credentials.SessionToken')
EXPIRATION=$(echo "$CREDENTIALS" | jq -r '.Credentials.Expiration')

echo ""
echo "Temporary credentials obtained successfully!"
echo "Access Key ID: $ACCESS_KEY"
echo "Expiration: $EXPIRATION"

# Save credentials to file
cat > temp-credentials.json <<EOF
{
  "AccessKeyId": "$ACCESS_KEY",
  "SecretAccessKey": "$SECRET_KEY",
  "SessionToken": "$SESSION_TOKEN",
  "Expiration": "$EXPIRATION"
}
EOF

# Export as environment variables
cat > temp-credentials.sh <<EOF
export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"
export AWS_SESSION_TOKEN="$SESSION_TOKEN"
EOF

echo ""
echo "Credentials saved to:"
echo "  - temp-credentials.json (JSON format)"
echo "  - temp-credentials.sh (environment variables)"
echo ""
echo "To use these credentials, run:"
echo "  source temp-credentials.sh"

# Display assumed role user info
echo ""
echo "Assumed Role User:"
echo "$CREDENTIALS" | jq '.AssumedRoleUser'

echo ""
echo "Subject from Web Identity Token:"
echo "$CREDENTIALS" | jq -r '.SubjectFromWebIdentityToken'
