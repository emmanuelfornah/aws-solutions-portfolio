#!/bin/bash

# Create S3 Buckets for Lab
# This script creates multiple S3 buckets for different purposes

set -e

# Configuration
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Bucket names (must be globally unique)
STORAGE_BUCKET="lab-storage-${ACCOUNT_ID}-${TIMESTAMP}"
WEBSITE_BUCKET="lab-website-${ACCOUNT_ID}-${TIMESTAMP}"
BATCH_BUCKET="lab-batch-ops-${ACCOUNT_ID}-${TIMESTAMP}"

echo "Creating S3 buckets..."

# Create general storage bucket
echo "Creating storage bucket: ${STORAGE_BUCKET}"
aws s3api create-bucket \
    --bucket "${STORAGE_BUCKET}" \
    --region "${REGION}"

# Enable versioning on storage bucket
aws s3api put-bucket-versioning \
    --bucket "${STORAGE_BUCKET}" \
    --versioning-configuration Status=Enabled

# Enable encryption on storage bucket
aws s3api put-bucket-encryption \
    --bucket "${STORAGE_BUCKET}" \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'

echo "Storage bucket created: ${STORAGE_BUCKET}"

# Create website hosting bucket
echo "Creating website bucket: ${WEBSITE_BUCKET}"
aws s3api create-bucket \
    --bucket "${WEBSITE_BUCKET}" \
    --region "${REGION}"

echo "Website bucket created: ${WEBSITE_BUCKET}"

# Create batch operations bucket
echo "Creating batch operations bucket: ${BATCH_BUCKET}"
aws s3api create-bucket \
    --bucket "${BATCH_BUCKET}" \
    --region "${REGION}"

echo "Batch operations bucket created: ${BATCH_BUCKET}"

# Save bucket names to file for use by other scripts
cat > bucket-names.txt <<EOF
STORAGE_BUCKET=${STORAGE_BUCKET}
WEBSITE_BUCKET=${WEBSITE_BUCKET}
BATCH_BUCKET=${BATCH_BUCKET}
REGION=${REGION}
EOF

echo ""
echo "All buckets created successfully!"
echo "Bucket names saved to bucket-names.txt"
echo ""
echo "Storage Bucket: ${STORAGE_BUCKET}"
echo "Website Bucket: ${WEBSITE_BUCKET}"
echo "Batch Ops Bucket: ${BATCH_BUCKET}"
