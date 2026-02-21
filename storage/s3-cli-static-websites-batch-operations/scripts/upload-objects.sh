#!/bin/bash

# Upload Objects to S3 Using Various Methods
# Demonstrates aws s3 cp, sync, and mv commands

set -e

# Load bucket names
if [ ! -f bucket-names.txt ]; then
    echo "Error: bucket-names.txt not found. Run create-buckets.sh first."
    exit 1
fi

source bucket-names.txt

echo "Uploading objects to S3 bucket: ${STORAGE_BUCKET}"

# Create sample files if they don't exist
mkdir -p ../assets/sample-files
cd ../assets/sample-files

# Create sample text files
echo "This is sample file 1" > file1.txt
echo "This is sample file 2" > file2.txt
echo "This is sample file 3" > file3.txt

# Create a sample JSON file
cat > data.json <<EOF
{
  "name": "Sample Data",
  "version": "1.0",
  "items": [
    {"id": 1, "value": "Item 1"},
    {"id": 2, "value": "Item 2"}
  ]
}
EOF

# Create a sample CSV file
cat > data.csv <<EOF
id,name,category
1,Product A,Electronics
2,Product B,Books
3,Product C,Clothing
EOF

cd ../../scripts

echo ""
echo "Method 1: Using 'aws s3 cp' to upload single file"
aws s3 cp ../assets/sample-files/file1.txt "s3://${STORAGE_BUCKET}/uploads/file1.txt"
echo "✓ Uploaded file1.txt"

echo ""
echo "Method 2: Using 'aws s3 cp' with --recursive for directory"
aws s3 cp ../assets/sample-files/ "s3://${STORAGE_BUCKET}/batch-upload/" --recursive
echo "✓ Uploaded all files from sample-files directory"

echo ""
echo "Method 3: Using 'aws s3 sync' to synchronize directory"
aws s3 sync ../assets/sample-files/ "s3://${STORAGE_BUCKET}/synced-files/"
echo "✓ Synced sample-files directory"

echo ""
echo "Method 4: Using 'aws s3 cp' with metadata"
aws s3 cp ../assets/sample-files/data.json "s3://${STORAGE_BUCKET}/data/data.json" \
    --metadata "project=lab,environment=test"
echo "✓ Uploaded data.json with custom metadata"

echo ""
echo "Method 5: Using 'aws s3api put-object' with tags"
aws s3api put-object \
    --bucket "${STORAGE_BUCKET}" \
    --key "tagged-files/data.csv" \
    --body ../assets/sample-files/data.csv \
    --tagging "Department=Engineering&Project=Lab&Environment=Test"
echo "✓ Uploaded data.csv with tags"

echo ""
echo "Method 6: Upload with storage class specification"
aws s3 cp ../assets/sample-files/file2.txt "s3://${STORAGE_BUCKET}/archive/file2.txt" \
    --storage-class STANDARD_IA
echo "✓ Uploaded file2.txt to STANDARD_IA storage class"

echo ""
echo "Listing uploaded objects:"
aws s3 ls "s3://${STORAGE_BUCKET}/" --recursive

echo ""
echo "All uploads completed successfully!"
