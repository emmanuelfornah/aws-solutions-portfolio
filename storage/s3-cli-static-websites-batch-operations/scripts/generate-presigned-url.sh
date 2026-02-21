#!/bin/bash

# Generate Presigned URL for S3 Object
# Provides temporary access to private objects

set -e

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <bucket-name> <object-key> [expiration-seconds]"
    echo ""
    echo "Example: $0 my-bucket path/to/file.txt 3600"
    echo ""
    echo "Default expiration: 3600 seconds (1 hour)"
    exit 1
fi

BUCKET_NAME=$1
OBJECT_KEY=$2
EXPIRATION=${3:-3600}  # Default 1 hour

echo "Generating presigned URL..."
echo "Bucket: ${BUCKET_NAME}"
echo "Object: ${OBJECT_KEY}"
echo "Expiration: ${EXPIRATION} seconds"
echo ""

# Generate presigned URL
PRESIGNED_URL=$(aws s3 presign "s3://${BUCKET_NAME}/${OBJECT_KEY}" --expires-in "${EXPIRATION}")

echo "Presigned URL generated successfully!"
echo ""
echo "${PRESIGNED_URL}"
echo ""
echo "This URL will expire in ${EXPIRATION} seconds"
echo ""
echo "Test the URL with:"
echo "curl -I \"${PRESIGNED_URL}\""
echo ""
echo "Or download the file with:"
echo "curl -o downloaded-file \"${PRESIGNED_URL}\""
