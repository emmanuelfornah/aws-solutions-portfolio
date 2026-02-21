#!/bin/bash

# Configure Block Public Access and Bucket Policy
# Enables public read access for static website

set -e

# Load bucket names
if [ ! -f bucket-names.txt ]; then
    echo "Error: bucket-names.txt not found. Run create-buckets.sh first."
    exit 1
fi

source bucket-names.txt

echo "Configuring public access for website bucket: ${WEBSITE_BUCKET}"

# Disable Block Public Access for website bucket
echo "Disabling Block Public Access settings..."
aws s3api put-public-access-block \
    --bucket "${WEBSITE_BUCKET}" \
    --public-access-block-configuration \
        "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

echo "✓ Block Public Access disabled"

# Create bucket policy from template
echo ""
echo "Creating bucket policy..."
cat > /tmp/bucket-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${WEBSITE_BUCKET}/*"
    }
  ]
}
EOF

# Apply bucket policy
aws s3api put-bucket-policy \
    --bucket "${WEBSITE_BUCKET}" \
    --policy file:///tmp/bucket-policy.json

echo "✓ Bucket policy applied"

# Clean up temporary file
rm /tmp/bucket-policy.json

# Get website endpoint
WEBSITE_ENDPOINT="${WEBSITE_BUCKET}.s3-website-${REGION}.amazonaws.com"

echo ""
echo "Public access configured successfully!"
echo ""
echo "Your website is now accessible at:"
echo "http://${WEBSITE_ENDPOINT}"
echo ""
echo "Test with: curl http://${WEBSITE_ENDPOINT}"
