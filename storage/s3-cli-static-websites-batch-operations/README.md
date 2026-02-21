# Using Amazon S3 with the CLI, Hosting Static Websites, and Updating Tags with Batch Operations

## Overview

This lab demonstrates comprehensive Amazon S3 operations using the AWS CLI, including bucket management, object operations, static website hosting, and S3 Batch Operations for bulk tagging. The implementation covers essential S3 commands (aws s3 and aws s3api), presigned URLs for temporary access, Block Public Access configuration, bucket policies, and automated tag updates across multiple objects.

## AWS Services Used

- **Amazon S3** - Object storage and static website hosting
- **AWS CLI** - Command-line interface for S3 operations
- **S3 Batch Operations** - Bulk operations on S3 objects
- **IAM** - Permissions and access control

## Key Technologies

- **AWS CLI** - aws s3 and aws s3api commands
- **S3 Bucket Policies** - JSON-based access control
- **S3 Block Public Access** - Security feature to prevent public exposure
- **Presigned URLs** - Temporary access to private objects
- **S3 Object Tagging** - Metadata for object organization
- **Static Website Hosting** - Serving HTML/CSS/JS from S3

## Architecture Overview

The architecture demonstrates S3 bucket operations including creating buckets, uploading objects with various methods (cp, sync, mv), configuring static website hosting with index and error documents, implementing bucket policies for public read access, and using S3 Batch Operations with manifest files to update object tags at scale.

See [architecture.md](./architecture.md) for detailed architecture description and data flow.

## Objectives

- Master AWS CLI commands for S3 bucket and object management
- Understand differences between aws s3 and aws s3api command sets
- Configure S3 buckets for static website hosting
- Implement bucket policies and Block Public Access settings
- Generate and use presigned URLs for temporary object access
- Execute S3 Batch Operations for bulk tag updates
- Manage object metadata and tagging strategies

## Key Learnings

- **AWS CLI Proficiency**: Understanding aws s3 high-level commands (cp, sync, mv, rm) versus aws s3api low-level API commands
- **S3 Bucket Management**: Creating buckets with proper naming conventions and region specifications
- **Object Operations**: Uploading, downloading, moving, and deleting objects with various CLI options
- **Static Website Hosting**: Configuring index and error documents, understanding S3 website endpoints
- **Security Configuration**: Managing Block Public Access settings and bucket policies for controlled public access
- **Presigned URLs**: Generating temporary URLs for secure object sharing without permanent public access
- **S3 Batch Operations**: Creating manifest files, configuring batch jobs, and executing bulk operations
- **Object Tagging**: Using tags for organization, cost allocation, and lifecycle management
- **S3 Pricing Awareness**: Understanding storage classes, request costs, and data transfer charges

## Setup Instructions

### Prerequisites

- AWS account with appropriate S3 permissions
- AWS CLI installed and configured with credentials
- IAM role with S3 Batch Operations permissions
- Basic understanding of JSON for bucket policies

### Step 1: Create S3 Buckets

Create buckets for different purposes:

```bash
# Create a bucket for general storage
./scripts/create-buckets.sh

# Verify bucket creation
aws s3 ls
```

### Step 2: Upload Objects Using Various Methods

Upload files using different CLI commands:

```bash
# Upload using cp, sync, and mv commands
./scripts/upload-objects.sh

# Verify uploads
aws s3 ls s3://your-bucket-name/ --recursive
```

### Step 3: Configure Static Website Hosting

Set up a bucket for static website hosting:

```bash
# Configure website hosting with index and error documents
./scripts/configure-static-website.sh

# Upload website files
aws s3 sync ./assets/website/ s3://your-website-bucket/
```

### Step 4: Configure Block Public Access and Bucket Policy

Manage public access settings:

```bash
# Configure Block Public Access settings
./scripts/configure-public-access.sh

# Apply bucket policy for public read access
aws s3api put-bucket-policy --bucket your-website-bucket --policy file://configs/bucket-policy.json
```

### Step 5: Generate Presigned URLs

Create temporary access URLs for private objects:

```bash
# Generate presigned URL valid for 1 hour
./scripts/generate-presigned-url.sh your-bucket-name your-object-key 3600

# Test the presigned URL
curl -I "presigned-url-here"
```

### Step 6: Execute S3 Batch Operations

Run bulk tag updates using S3 Batch Operations:

```bash
# Create manifest file listing objects to tag
./scripts/create-batch-manifest.sh

# Create and execute batch job
./scripts/execute-batch-operations.sh
```

### Step 7: Verify and Monitor

Check the results of all operations:

```bash
# Verify website is accessible
curl http://your-website-bucket.s3-website-region.amazonaws.com

# Check object tags
aws s3api get-object-tagging --bucket your-bucket-name --key your-object-key

# Monitor batch job status
aws s3control describe-job --account-id your-account-id --job-id your-job-id
```

## Scripts and Configurations

### Scripts

All scripts are located in the `scripts/` directory:

- **create-buckets.sh** - Creates S3 buckets with proper naming and region configuration
- **upload-objects.sh** - Demonstrates various upload methods (cp, sync, mv)
- **configure-static-website.sh** - Configures S3 bucket for static website hosting
- **configure-public-access.sh** - Manages Block Public Access settings
- **generate-presigned-url.sh** - Creates presigned URLs for temporary object access
- **create-batch-manifest.sh** - Generates manifest file for S3 Batch Operations
- **execute-batch-operations.sh** - Creates and runs S3 Batch Operations job
- **cleanup.sh** - Removes all created resources

### Configuration Files

Configuration templates are located in the `configs/` directory:

- **bucket-policy.json** - Bucket policy for public read access to website content
- **website-configuration.json** - Static website hosting configuration
- **batch-job-manifest.csv** - Sample manifest file for batch operations
- **batch-job-tags.json** - Tag set to apply via batch operations

### Assets

Sample website files are located in the `assets/` directory:

- **website/index.html** - Sample homepage for static website
- **website/error.html** - Custom error page for 404 errors
- **website/styles.css** - Basic styling for website
- **sample-files/** - Sample files for upload demonstrations

## AWS CLI Command Reference

### High-Level Commands (aws s3)

```bash
# List buckets
aws s3 ls

# List objects in bucket
aws s3 ls s3://bucket-name/ --recursive

# Copy file to S3
aws s3 cp file.txt s3://bucket-name/

# Copy file from S3
aws s3 cp s3://bucket-name/file.txt ./

# Sync directory to S3
aws s3 sync ./local-dir/ s3://bucket-name/prefix/

# Move object within S3
aws s3 mv s3://bucket-name/old-key s3://bucket-name/new-key

# Remove object
aws s3 rm s3://bucket-name/file.txt

# Remove all objects (empty bucket)
aws s3 rm s3://bucket-name/ --recursive
```

### Low-Level API Commands (aws s3api)

```bash
# Create bucket
aws s3api create-bucket --bucket bucket-name --region us-east-1

# Put object with metadata
aws s3api put-object --bucket bucket-name --key file.txt --body file.txt --metadata key1=value1

# Get object metadata
aws s3api head-object --bucket bucket-name --key file.txt

# Put object tagging
aws s3api put-object-tagging --bucket bucket-name --key file.txt --tagging 'TagSet=[{Key=Environment,Value=Production}]'

# Get object tagging
aws s3api get-object-tagging --bucket bucket-name --key file.txt

# Put bucket policy
aws s3api put-bucket-policy --bucket bucket-name --policy file://policy.json

# Get bucket policy
aws s3api get-bucket-policy --bucket bucket-name

# Put bucket website configuration
aws s3api put-bucket-website --bucket bucket-name --website-configuration file://website-config.json

# Generate presigned URL
aws s3 presign s3://bucket-name/file.txt --expires-in 3600
```

## Troubleshooting

### Bucket Creation Issues

- Verify bucket name is globally unique and follows naming rules
- Check region specification matches your AWS CLI configuration
- Ensure IAM permissions include s3:CreateBucket

### Upload Failures

- Verify file paths are correct
- Check IAM permissions include s3:PutObject
- Ensure bucket exists and you have write access
- For large files, consider using multipart upload

### Static Website Access Issues

- Verify Block Public Access settings allow public access
- Check bucket policy grants public read permissions
- Ensure index.html exists in bucket root
- Use correct website endpoint format: bucket-name.s3-website-region.amazonaws.com

### Presigned URL Issues

- Verify URL hasn't expired
- Check object exists and key is correct
- Ensure IAM credentials used to generate URL are still valid
- URL must be used before expiration time

### Batch Operations Failures

- Verify manifest file format is correct (CSV with bucket and key columns)
- Check IAM role has necessary permissions for batch operations
- Ensure all objects in manifest exist
- Monitor job status for specific error messages

## Security Considerations

- Use Block Public Access by default; only disable when necessary for specific use cases
- Implement least privilege IAM policies for S3 access
- Enable S3 bucket versioning to protect against accidental deletions
- Use presigned URLs instead of making objects permanently public
- Enable S3 server-side encryption for sensitive data
- Implement bucket policies with specific conditions (IP restrictions, VPC endpoints)
- Enable S3 access logging for audit trails
- Use MFA Delete for additional protection on versioned buckets
- Regularly review and rotate IAM credentials

## Cost Optimization

### Storage Costs

- Use appropriate storage classes (Standard, Intelligent-Tiering, Glacier)
- Implement lifecycle policies to transition objects to cheaper storage
- Delete unnecessary objects and incomplete multipart uploads
- Use S3 Storage Lens for visibility into storage usage

### Request Costs

- Minimize LIST operations by using prefixes effectively
- Use CloudFront for frequently accessed content to reduce GET requests
- Batch operations instead of individual API calls
- Use S3 Select to retrieve only needed data

### Data Transfer Costs

- Use CloudFront to reduce data transfer charges
- Keep data transfers within same region when possible
- Use VPC endpoints for S3 to avoid NAT gateway charges
- Compress files before uploading to reduce transfer size

## Next Steps

- Implement S3 lifecycle policies for automatic object transitions
- Configure S3 Cross-Region Replication for disaster recovery
- Set up S3 Event Notifications with Lambda for automated processing
- Implement S3 Object Lock for compliance and retention
- Use S3 Inventory for large-scale object management
- Configure S3 Access Points for simplified access management
- Implement S3 Storage Lens for organization-wide visibility
- Use S3 Intelligent-Tiering for automatic cost optimization

## Lab Metadata

- **Domain**: Storage
- **Complexity Level**: Intermediate
- **Estimated Time**: 60 minutes
- **AWS Services**: S3, AWS CLI, S3 Batch Operations, IAM
- **Key Concepts**: Object storage, static website hosting, presigned URLs, batch operations, bucket policies
- **Certification Alignment**: AWS Certified Solutions Architect - Associate (S3 storage classes, security, lifecycle policies)

