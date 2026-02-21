#!/bin/bash

# Execute S3 Batch Operations Job
# Applies tags to objects listed in manifest file

set -e

# Load bucket names
if [ ! -f bucket-names.txt ]; then
    echo "Error: bucket-names.txt not found. Run create-buckets.sh first."
    exit 1
fi

source bucket-names.txt

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# IAM role ARN for batch operations (must be created beforehand)
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/S3BatchOperationsRole"

echo "Creating S3 Batch Operations job..."
echo "Account ID: ${ACCOUNT_ID}"
echo "Manifest: s3://${BATCH_BUCKET}/manifests/batch-job-manifest.csv"
echo ""

# Note: This script assumes the IAM role exists
# In a real scenario, you would create the role first

echo "Note: This script requires an IAM role with S3 Batch Operations permissions."
echo "Role ARN: ${ROLE_ARN}"
echo ""
echo "To create the role, use the AWS Console or CLI with the following trust policy:"
echo ""
cat <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "batchoperations.s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

echo ""
echo "And attach a policy with these permissions:"
echo ""
cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObjectTagging",
        "s3:PutObjectVersionTagging"
      ],
      "Resource": "arn:aws:s3:::${STORAGE_BUCKET}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion"
      ],
      "Resource": "arn:aws:s3:::${BATCH_BUCKET}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::${BATCH_BUCKET}/reports/*"
    }
  ]
}
EOF

echo ""
echo "Once the role is created, you can create the batch job with:"
echo ""
cat <<EOF
aws s3control create-job \\
    --account-id ${ACCOUNT_ID} \\
    --operation '{
        "S3PutObjectTagging": {
            "TagSet": [
                {"Key": "ProcessedBy", "Value": "BatchOperations"},
                {"Key": "ProcessedDate", "Value": "$(date +%Y-%m-%d)"},
                {"Key": "Environment", "Value": "Lab"}
            ]
        }
    }' \\
    --manifest '{
        "Spec": {
            "Format": "S3BatchOperations_CSV_20180820",
            "Fields": ["Bucket", "Key"]
        },
        "Location": {
            "ObjectArn": "arn:aws:s3:::${BATCH_BUCKET}/manifests/batch-job-manifest.csv",
            "ETag": "$(aws s3api head-object --bucket ${BATCH_BUCKET} --key manifests/batch-job-manifest.csv --query ETag --output text)"
        }
    }' \\
    --report '{
        "Bucket": "arn:aws:s3:::${BATCH_BUCKET}",
        "Prefix": "reports/",
        "Format": "Report_CSV_20180820",
        "Enabled": true,
        "ReportScope": "AllTasks"
    }' \\
    --priority 10 \\
    --role-arn ${ROLE_ARN} \\
    --region ${REGION} \\
    --description "Apply tags to lab objects"
EOF

echo ""
echo "After creating the job, monitor its status with:"
echo "aws s3control describe-job --account-id ${ACCOUNT_ID} --job-id <job-id>"
