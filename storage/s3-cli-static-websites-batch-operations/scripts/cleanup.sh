#!/bin/bash

# Cleanup Script - Remove All Lab Resources
# Deletes all objects and buckets created during the lab

set -e

# Load bucket names
if [ ! -f bucket-names.txt ]; then
    echo "Error: bucket-names.txt not found. Nothing to clean up."
    exit 0
fi

source bucket-names.txt

echo "WARNING: This will delete all objects and buckets created during the lab."
echo ""
echo "Buckets to be deleted:"
echo "  - ${STORAGE_BUCKET}"
echo "  - ${WEBSITE_BUCKET}"
echo "  - ${BATCH_BUCKET}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "${CONFIRM}" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Starting cleanup..."

# Function to empty and delete bucket
empty_and_delete_bucket() {
    local bucket=$1
    echo ""
    echo "Processing bucket: ${bucket}"
    
    # Check if bucket exists
    if aws s3api head-bucket --bucket "${bucket}" 2>/dev/null; then
        echo "  Emptying bucket..."
        aws s3 rm "s3://${bucket}" --recursive
        
        # Delete all versions if versioning is enabled
        echo "  Checking for versioned objects..."
        aws s3api list-object-versions --bucket "${bucket}" --output json | \
            jq -r '.Versions[]?, .DeleteMarkers[]? | "\(.Key) \(.VersionId)"' | \
            while read key version; do
                if [ -n "${key}" ] && [ -n "${version}" ]; then
                    echo "    Deleting version: ${key} (${version})"
                    aws s3api delete-object --bucket "${bucket}" --key "${key}" --version-id "${version}"
                fi
            done
        
        echo "  Deleting bucket..."
        aws s3api delete-bucket --bucket "${bucket}"
        echo "  ✓ Bucket deleted: ${bucket}"
    else
        echo "  Bucket does not exist or already deleted: ${bucket}"
    fi
}

# Delete all buckets
empty_and_delete_bucket "${STORAGE_BUCKET}"
empty_and_delete_bucket "${WEBSITE_BUCKET}"
empty_and_delete_bucket "${BATCH_BUCKET}"

# Remove local files
echo ""
echo "Removing local configuration files..."
rm -f bucket-names.txt
rm -f ../configs/batch-job-manifest.csv

echo ""
echo "Cleanup completed successfully!"
echo "All lab resources have been removed."
