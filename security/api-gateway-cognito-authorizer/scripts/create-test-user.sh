#!/bin/bash

# Create Test User in Cognito User Pool
# This script creates a test user and sets a permanent password

set -e

# Read user pool ID
if [ ! -f user-pool-id.txt ]; then
  echo "Error: user-pool-id.txt not found. Run create-user-pool.sh first."
  exit 1
fi

USER_POOL_ID=$(cat user-pool-id.txt)

# User credentials (sanitized for portfolio)
TEST_EMAIL="testuser@example.com"
TEST_PASSWORD="TestPassword123"

echo "Creating test user in User Pool: $USER_POOL_ID"

# Create user
aws cognito-idp admin-create-user \
  --user-pool-id "$USER_POOL_ID" \
  --username "$TEST_EMAIL" \
  --user-attributes Name=email,Value="$TEST_EMAIL" Name=email_verified,Value=true \
  --message-action SUPPRESS

echo "Test user created: $TEST_EMAIL"

# Set permanent password
aws cognito-idp admin-set-user-password \
  --user-pool-id "$USER_POOL_ID" \
  --username "$TEST_EMAIL" \
  --password "$TEST_PASSWORD" \
  --permanent

echo "Password set for user"

# Save credentials for testing
cat > test-credentials.txt <<EOF
Email: $TEST_EMAIL
Password: $TEST_PASSWORD
EOF

echo "✓ Test user created successfully"
echo ""
echo "Test User Credentials:"
echo "  - Email: $TEST_EMAIL"
echo "  - Password: $TEST_PASSWORD"
echo ""
echo "Note: Credentials saved to test-credentials.txt"
