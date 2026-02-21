#!/bin/bash

# Create Manifest File for S3 Batch Operations
# Lists objects to be processed by batch job

set -e

# Load bucket names
if [ ! -f bucket-names.txt ]; then
    echo "Error: bucket-names.txt not found. Run create-buckets.sh first."
    exit 1
fi

source bucket-names.txt

echo "Creating batch operations manifest file..."

# Create manifest CSV file
MANIFEST_FILE="../configs/batch-job-manifest.csv"

echo "Listing objects from storage bucket..."
aws s3api list-objects-v2 \
    --bucket "${STORAGE_BUCKET}" \
    --query 'Contents[].Key' \
    --output text | tr '\t' '\n' > /tmp/object-keys.txt

# Create CSV manifest
echo "${STORAGE_BUCKET},$(head -1 /tmp/object-keys.txt)" > "${MANIFEST_FILE}"

# Add more objects to manifest (up to 10 for demo)
tail -n +2 /tmp/object-keys.txt | head -9 | while read key; do
    echo "${STORAGE_BUCKET},${key}" >> "${MANIFEST_FILE}"
done

# Clean up
rm /tmp/object-keys.txt

# Upload manifest to batch operations bucket
echo ""
echo "Uploading manifest to batch operations bucket..."
aws s3 cp "${MANIFEST_FILE}" "s3://${BATCH_BUCKET}/manifests/batch-job-manifest.csv"

echo ""
echo "Manifest file created and uploaded successfully!"
echo "Local file: ${MANIFEST_FILE}"
echo "S3 location: s3://${BATCH_BUCKET}/manifests/batch-job-manifest.csv"
echo ""
echo "Manifest contents:"
cat "${MANIFEST_FILE}"
