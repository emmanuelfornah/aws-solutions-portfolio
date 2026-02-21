#!/bin/bash

# Configure S3 Bucket for Static Website Hosting
# Sets up index and error documents

set -e

# Load bucket names
if [ ! -f bucket-names.txt ]; then
    echo "Error: bucket-names.txt not found. Run create-buckets.sh first."
    exit 1
fi

source bucket-names.txt

echo "Configuring static website hosting for: ${WEBSITE_BUCKET}"

# Configure website hosting
echo "Setting website configuration..."
aws s3api put-bucket-website \
    --bucket "${WEBSITE_BUCKET}" \
    --website-configuration file://../configs/website-configuration.json

echo "✓ Website configuration applied"

# Upload website files
echo ""
echo "Uploading website files..."
aws s3 sync ../assets/website/ "s3://${WEBSITE_BUCKET}/"

echo "✓ Website files uploaded"

# Get website endpoint
WEBSITE_ENDPOINT="${WEBSITE_BUCKET}.s3-website-${REGION}.amazonaws.com"

echo ""
echo "Static website hosting configured successfully!"
echo ""
echo "Website Endpoint: http://${WEBSITE_ENDPOINT}"
echo ""
echo "Note: You need to configure public access and bucket policy to make the website accessible."
echo "Run configure-public-access.sh next."
