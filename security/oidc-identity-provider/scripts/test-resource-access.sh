#!/bin/bash

# Test Resource Access with Federated Credentials
# Verify that temporary credentials work for accessing AWS resources

set -e

# Load temporary credentials
if [ ! -f temp-credentials.sh ]; then
  echo "Error: Temporary credentials not found."
  echo "Run assume-role-web-identity.sh first."
  exit 1
fi

source temp-credentials.sh

echo "Testing resource access with federated credentials..."
echo ""

# Test 1: List S3 buckets
echo "Test 1: Listing S3 buckets..."
aws s3 ls | grep "federated-user-data" || echo "No matching buckets found"

# Test 2: Get caller identity
echo ""
echo "Test 2: Getting caller identity..."
aws sts get-caller-identity

# Test 3: Create test file and upload to S3
echo ""
echo "Test 3: Uploading file to S3..."
BUCKET_NAME="federated-user-data-test"
TEST_FILE="test-$(date +%s).txt"
echo "Test file created by federated user at $(date)" > "$TEST_FILE"

# Get user ID for path
USER_ID=$(aws sts get-caller-identity --query 'UserId' --output text)

aws s3 cp "$TEST_FILE" "s3://$BUCKET_NAME/$USER_ID/$TEST_FILE" || \
  echo "Upload failed - check bucket exists and permissions are correct"

# Test 4: List uploaded files
echo ""
echo "Test 4: Listing uploaded files..."
aws s3 ls "s3://$BUCKET_NAME/$USER_ID/" || echo "No files found"

# Test 5: Download file
echo ""
echo "Test 5: Downloading file..."
aws s3 cp "s3://$BUCKET_NAME/$USER_ID/$TEST_FILE" "downloaded-$TEST_FILE" || \
  echo "Download failed"

# Cleanup
rm -f "$TEST_FILE" "downloaded-$TEST_FILE"

echo ""
echo "Resource access tests completed!"
echo ""
echo "Credential expiration:"
jq -r '.Expiration' temp-credentials.json
