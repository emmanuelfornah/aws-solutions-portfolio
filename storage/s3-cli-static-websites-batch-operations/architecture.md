# S3 CLI, Static Websites, and Batch Operations Architecture

## Architecture Overview

This architecture demonstrates comprehensive Amazon S3 usage patterns including bucket management via AWS CLI, static website hosting with public access configuration, presigned URL generation for temporary access, and S3 Batch Operations for bulk object tagging. The design showcases both high-level (aws s3) and low-level (aws s3api) CLI commands for different use cases.

## Components

### 1. S3 Buckets

Multiple S3 buckets serve different purposes in this architecture.

**General Storage Bucket:**
- Standard storage class for frequently accessed data
- Private access by default with IAM-based permissions
- Versioning enabled for data protection
- Server-side encryption (SSE-S3) for data at rest

**Static Website Bucket:**
- Configured for static website hosting
- Public read access via bucket policy
- Index document: index.html
- Error document: error.html
- Website endpoint: bucket-name.s3-website-region.amazonaws.com

**Batch Operations Bucket:**
- Stores manifest files for batch jobs
- Stores batch operation results and reports
- Private access with IAM role permissions

### 2. AWS CLI Interface

The AWS CLI provides two command sets for S3 operations.

**High-Level Commands (aws s3):**
- Simplified commands for common operations
- Automatic multipart upload for large files
- Recursive operations for directories
- Commands: ls, cp, mv, rm, sync, mb, rb
- Best for: Daily operations, file transfers, directory syncing

**Low-Level API Commands (aws s3api):**
- Direct access to S3 API operations
- Fine-grained control over request parameters
- Access to advanced features (tagging, metadata, ACLs)
- Commands: create-bucket, put-object, get-object, head-object, put-object-tagging
- Best for: Automation, advanced configurations, metadata management

### 3. Static Website Hosting

S3 static website hosting serves HTML, CSS, JavaScript, and media files directly from S3.

**Configuration:**
- Index document: index.html (default page)
- Error document: error.html (404 and other errors)
- Website endpoint format: http://bucket-name.s3-website-region.amazonaws.com
- Alternative format: http://bucket-name.s3-website.region.amazonaws.com

**Supported Content:**
- HTML pages
- CSS stylesheets
- JavaScript files
- Images (JPEG, PNG, GIF, SVG)
- Fonts and other static assets

**Limitations:**
- No server-side processing (PHP, Python, etc.)
- No HTTPS on S3 website endpoint (use CloudFront for HTTPS)
- No custom domain without Route 53 or CloudFront

### 4. Block Public Access Settings

S3 Block Public Access provides centralized controls to prevent public access.

**Four Settings:**
1. **BlockPublicAcls**: Blocks new public ACLs and uploading public objects
2. **IgnorePublicAcls**: Ignores all public ACLs on bucket and objects
3. **BlockPublicPolicy**: Blocks new public bucket policies
4. **RestrictPublicBuckets**: Restricts access to buckets with public policies

**Configuration for Static Website:**
- BlockPublicAcls: false (allow public ACLs if needed)
- IgnorePublicAcls: false (respect public ACLs)
- BlockPublicPolicy: false (allow public bucket policy)
- RestrictPublicBuckets: false (allow public access via policy)

### 5. Bucket Policies

JSON-based policies control access to S3 buckets and objects.

**Static Website Policy Structure:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::bucket-name/*"
    }
  ]
}
```

**Policy Components:**
- **Version**: Policy language version (always "2012-10-17")
- **Statement**: Array of permission statements
- **Sid**: Statement ID (optional, for identification)
- **Effect**: Allow or Deny
- **Principal**: Who the policy applies to (* for everyone)
- **Action**: S3 API actions (s3:GetObject, s3:PutObject, etc.)
- **Resource**: ARN of bucket or objects

### 6. Presigned URLs

Presigned URLs provide temporary access to private S3 objects without changing permissions.

**Characteristics:**
- Time-limited access (configurable expiration)
- Generated using IAM credentials
- No need to make object public
- Can be used for both GET and PUT operations
- URL includes authentication information in query parameters

**Use Cases:**
- Sharing private files temporarily
- Allowing uploads to specific locations
- Providing download links in applications
- Time-limited access for external users

**Generation:**
```bash
aws s3 presign s3://bucket-name/object-key --expires-in 3600
```

**Expiration:**
- Default: 3600 seconds (1 hour)
- Maximum: 604800 seconds (7 days) for IAM user credentials
- Maximum: 43200 seconds (12 hours) for IAM role credentials

### 7. S3 Batch Operations

S3 Batch Operations performs large-scale operations on billions of objects.

**Components:**

**Manifest File:**
- CSV or S3 Inventory report listing objects to process
- Format: bucket,key (minimum required columns)
- Stored in S3 bucket
- Can include version IDs for versioned buckets

**Batch Job:**
- Defines operation to perform (tag, copy, restore, invoke Lambda)
- References manifest file
- Specifies IAM role for permissions
- Generates completion report

**IAM Role:**
- Permissions to read manifest file
- Permissions to perform operation on objects
- Permissions to write completion report
- Trust relationship with S3 Batch Operations service

**Supported Operations:**
- Put object tagging
- Put object ACL
- Copy objects
- Restore objects from Glacier
- Invoke Lambda function
- Replace object tags
- Delete object tags

### 8. Object Tagging

Tags are key-value pairs attached to S3 objects for organization and management.

**Tag Characteristics:**
- Maximum 10 tags per object
- Key length: 1-128 Unicode characters
- Value length: 0-256 Unicode characters
- Case-sensitive
- Can be used in IAM policies and lifecycle rules

**Common Tag Use Cases:**
- Cost allocation and tracking
- Lifecycle management rules
- Access control policies
- Data classification (Public, Internal, Confidential)
- Environment identification (Dev, Test, Prod)
- Project or department attribution

## Data Flow

### Object Upload Flow

1. **User Initiates Upload**: User runs aws s3 cp or aws s3 sync command
2. **CLI Authentication**: AWS CLI uses configured credentials (access key or IAM role)
3. **API Request**: CLI sends PutObject API request to S3
4. **Bucket Validation**: S3 validates bucket exists and user has permissions
5. **Object Storage**: S3 stores object and returns success response
6. **Metadata Storage**: Object metadata (size, ETag, tags) stored with object
7. **Confirmation**: CLI displays upload confirmation to user

### Static Website Request Flow

1. **User Request**: User enters website endpoint URL in browser
2. **DNS Resolution**: DNS resolves to S3 website endpoint IP
3. **HTTP Request**: Browser sends GET request to S3
4. **Bucket Policy Check**: S3 validates public read access via bucket policy
5. **Object Retrieval**: S3 retrieves requested object (or index.html for root)
6. **Content Delivery**: S3 returns object with appropriate Content-Type header
7. **Browser Rendering**: Browser renders HTML/CSS/JavaScript
8. **Error Handling**: If object not found, S3 returns error.html (if configured)

### Presigned URL Flow

1. **URL Generation**: User runs aws s3 presign command with object key and expiration
2. **Signature Creation**: CLI creates signature using IAM credentials and expiration time
3. **URL Construction**: CLI builds URL with object path and signature parameters
4. **URL Sharing**: User shares presigned URL with recipient
5. **URL Access**: Recipient opens URL in browser or uses curl/wget
6. **Signature Validation**: S3 validates signature and checks expiration
7. **Object Delivery**: If valid, S3 returns object; if expired or invalid, returns error
8. **Expiration**: URL becomes invalid after expiration time

### S3 Batch Operations Flow

1. **Manifest Creation**: User creates CSV file listing objects to process
2. **Manifest Upload**: User uploads manifest to S3 bucket
3. **Job Creation**: User creates batch job via CLI or Console
   - Specifies operation type (e.g., PUT object tagging)
   - References manifest file location
   - Specifies IAM role ARN
   - Configures operation parameters (e.g., tag set)
4. **Job Validation**: S3 validates manifest format and IAM role permissions
5. **Job Execution**: S3 Batch Operations processes objects in manifest
   - Reads manifest file
   - Performs operation on each object
   - Tracks success and failure counts
6. **Progress Monitoring**: User monitors job status via CLI or Console
7. **Completion Report**: S3 generates report with results
   - Lists successful operations
   - Lists failed operations with error messages
   - Stored in specified S3 bucket
8. **Report Review**: User downloads and reviews completion report

## Security Architecture

### Access Control Layers

1. **IAM Policies**: Control who can perform S3 operations
2. **Bucket Policies**: Control access to specific buckets and objects
3. **ACLs**: Legacy access control (not recommended for new applications)
4. **Block Public Access**: Centralized controls to prevent public exposure
5. **VPC Endpoints**: Private connectivity from VPC to S3
6. **Presigned URLs**: Temporary access without permanent permissions

### Security Best Practices

**Bucket Level:**
- Enable Block Public Access by default
- Use bucket policies for public access only when necessary
- Enable versioning for data protection
- Enable server-side encryption (SSE-S3, SSE-KMS, or SSE-C)
- Enable access logging for audit trails
- Use S3 Object Lock for compliance requirements

**Object Level:**
- Use presigned URLs instead of public ACLs
- Implement least privilege IAM policies
- Use object tagging for access control
- Enable MFA Delete for versioned buckets
- Regularly review and remove unnecessary public access

**Network Level:**
- Use VPC endpoints for private S3 access
- Implement bucket policies with IP restrictions
- Use AWS PrivateLink for secure connectivity
- Enable VPC Flow Logs for network monitoring

### Encryption

**Server-Side Encryption (SSE):**
- **SSE-S3**: S3-managed keys (AES-256)
- **SSE-KMS**: AWS KMS-managed keys (audit trail, key rotation)
- **SSE-C**: Customer-provided keys (customer manages keys)

**Client-Side Encryption:**
- Encrypt data before uploading to S3
- Manage encryption keys independently
- Use AWS Encryption SDK or custom solution

**Encryption in Transit:**
- Use HTTPS for all S3 API calls
- Enforce SSL/TLS with bucket policy conditions
- Use VPC endpoints for private connectivity

## Performance Optimization

### Upload Performance

**Multipart Upload:**
- Automatically used by aws s3 cp for files > 8 MB
- Parallel upload of parts improves speed
- Resume capability for failed uploads
- Recommended for files > 100 MB

**Transfer Acceleration:**
- Uses CloudFront edge locations for faster uploads
- Beneficial for uploads from distant geographic locations
- Additional cost per GB transferred
- Enable on bucket: aws s3api put-bucket-accelerate-configuration

**Parallelization:**
- Use aws s3 sync with --exclude and --include for parallel transfers
- Use GNU parallel or xargs for batch operations
- Adjust --max-concurrent-requests in AWS CLI config

### Download Performance

**CloudFront Integration:**
- Cache frequently accessed content at edge locations
- Reduce latency for global users
- Reduce S3 GET request costs
- Support HTTPS for static websites

**S3 Select:**
- Retrieve subset of data using SQL expressions
- Reduce data transfer and processing time
- Supported formats: CSV, JSON, Parquet
- Up to 400% faster and 80% cheaper than retrieving full object

**Byte-Range Fetches:**
- Download specific byte ranges of objects
- Parallel downloads of different ranges
- Resume interrupted downloads
- Useful for large files

## Cost Optimization

### Storage Costs

**Storage Classes:**
- **S3 Standard**: Frequent access, millisecond latency
- **S3 Intelligent-Tiering**: Automatic cost optimization
- **S3 Standard-IA**: Infrequent access, lower storage cost
- **S3 One Zone-IA**: Single AZ, lowest IA cost
- **S3 Glacier**: Archive, minutes to hours retrieval
- **S3 Glacier Deep Archive**: Long-term archive, 12-hour retrieval

**Lifecycle Policies:**
- Transition objects to cheaper storage classes
- Delete objects after retention period
- Abort incomplete multipart uploads
- Example: Standard → IA after 30 days → Glacier after 90 days

### Request Costs

**Optimization Strategies:**
- Use CloudFront to cache content and reduce GET requests
- Minimize LIST operations (use prefixes, pagination)
- Use S3 Inventory instead of LIST for large buckets
- Batch operations instead of individual API calls
- Use S3 Select to retrieve only needed data

### Data Transfer Costs

**Cost Factors:**
- Data transfer IN to S3: Free
- Data transfer OUT to internet: Charged per GB
- Data transfer OUT to CloudFront: Free
- Data transfer between S3 and EC2 in same region: Free
- Data transfer between regions: Charged per GB

**Optimization:**
- Use CloudFront for content delivery
- Keep data in same region as compute resources
- Use VPC endpoints to avoid NAT gateway charges
- Compress files before uploading

## Monitoring and Logging

### CloudWatch Metrics

**Bucket-Level Metrics:**
- BucketSizeBytes: Total size of objects in bucket
- NumberOfObjects: Total count of objects
- AllRequests: Total number of HTTP requests
- GetRequests, PutRequests: Specific request types
- 4xxErrors, 5xxErrors: Error counts

**Request Metrics:**
- Enable for specific prefixes or entire bucket
- 1-minute CloudWatch metrics
- Additional cost per monitored prefix

### S3 Access Logging

**Log Information:**
- Requester account and IP address
- Bucket and object key
- Request time and HTTP status
- Error code (if applicable)
- Bytes sent
- Object size
- Total time and turn-around time
- Referrer and user agent

**Configuration:**
- Enable on source bucket
- Specify target bucket for logs
- Optional prefix for log objects
- Logs delivered within a few hours

### S3 Event Notifications

**Supported Events:**
- Object created (Put, Post, Copy, CompleteMultipartUpload)
- Object removed (Delete, DeleteMarkerCreated)
- Object restore (from Glacier)
- Replication events
- Lifecycle transitions

**Destinations:**
- SNS topics
- SQS queues
- Lambda functions

## Disaster Recovery

### Backup Strategies

**Versioning:**
- Keeps multiple versions of objects
- Protects against accidental deletion
- Protects against application errors
- Can be combined with lifecycle policies

**Cross-Region Replication (CRR):**
- Automatic replication to different region
- Disaster recovery and compliance
- Requires versioning on both buckets
- Can replicate to different storage class

**Same-Region Replication (SRR):**
- Replication within same region
- Aggregate logs from multiple buckets
- Replicate between production and test accounts
- Data sovereignty requirements

### Recovery Procedures

**Accidental Deletion:**
1. If versioning enabled: Restore previous version
2. If versioning not enabled: Cannot recover (use backups)
3. Use MFA Delete for additional protection

**Data Corruption:**
1. Restore from previous version (if versioning enabled)
2. Restore from replicated bucket (if CRR/SRR enabled)
3. Restore from backup (if separate backup exists)

**Region Failure:**
1. Failover to replicated bucket in different region
2. Update application to use replica bucket
3. Use Route 53 for automatic failover

## Compliance and Governance

### S3 Object Lock

**Retention Modes:**
- **Governance Mode**: Users with special permissions can override
- **Compliance Mode**: No one can override, including root user
- **Legal Hold**: Indefinite retention until explicitly removed

**Use Cases:**
- Regulatory compliance (SEC, FINRA, HIPAA)
- Data retention policies
- Prevent premature deletion
- Litigation holds

### S3 Inventory

**Features:**
- Scheduled reports of objects and metadata
- CSV, ORC, or Parquet format
- Daily or weekly frequency
- Includes: object key, size, storage class, encryption status, tags

**Use Cases:**
- Audit and compliance reporting
- Business intelligence and analytics
- Lifecycle policy planning
- Replication status verification

### AWS Config

**S3 Configuration Tracking:**
- Track bucket configuration changes
- Evaluate compliance with rules
- Automated remediation
- Historical configuration data

**Example Rules:**
- s3-bucket-public-read-prohibited
- s3-bucket-public-write-prohibited
- s3-bucket-ssl-requests-only
- s3-bucket-versioning-enabled

