# Storage

Domain category for AWS storage services including S3, EBS, and EFS.

## Labs in This Category

### Using Amazon S3 with the CLI, Hosting Static Websites, and Updating Tags with Batch Operations

**Services:** S3, AWS CLI, S3 Batch Operations

**Description:** Comprehensive S3 operations using AWS CLI including bucket management, object operations (cp, sync, mv), static website hosting with public access configuration, presigned URLs for temporary access, and S3 Batch Operations for bulk tagging. Demonstrates both high-level (aws s3) and low-level (aws s3api) commands.

**Key Concepts:** Object storage, static website hosting, presigned URLs, batch operations, bucket policies, Block Public Access

**Complexity:** Intermediate | **Duration:** 60 minutes

[View Lab →](./s3-cli-static-websites-batch-operations/)

---

### Benchmarking Amazon EBS RAID 0 Compared to Standalone Amazon EBS Volumes

**Services:** EBS, EC2, CloudWatch

**Description:** Performance comparison between standalone EBS volumes and RAID 0 arrays using mdadm. Includes comprehensive FIO benchmarking to measure IOPS, throughput, and latency across various workload patterns (sequential, random, mixed). Demonstrates file system creation, fstab configuration, and multi-volume snapshots.

**Key Concepts:** RAID 0, mdadm, FIO benchmarking, ext4, performance optimization, multi-volume snapshots

**Complexity:** Advanced | **Duration:** 60 minutes

[View Lab →](./ebs-raid0-benchmarking/)

---

### Using Amazon EFS with AWS Backup and Lifecycle Management

**Services:** EFS, EC2, AWS Backup, VPC, IAM

**Description:** Implementation of Amazon EFS with automated backup strategies using AWS Backup and cost optimization through lifecycle management. Includes security group configuration for NFS access, mounting EFS with amazon-efs-utils, persistent mounts via fstab, backup plans with retention policies, and lifecycle policies for automatic transition to Infrequent Access storage class.

**Key Concepts:** NFS, distributed file systems, backup strategies, lifecycle management, cost optimization, security groups

**Complexity:** Intermediate | **Duration:** 60 minutes

[View Lab →](./efs-backup-lifecycle/)

---

## Storage Services Overview

### Amazon S3 (Simple Storage Service)

Object storage service offering industry-leading scalability, data availability, security, and performance. Ideal for data lakes, websites, backups, archives, and big data analytics.

**Use Cases:**
- Static website hosting
- Data lakes and analytics
- Backup and disaster recovery
- Application data storage
- Content distribution

### Amazon EBS (Elastic Block Store)

Block-level storage volumes for use with EC2 instances. Provides persistent storage that persists independently from the life of an instance.

**Volume Types:**
- **gp3/gp2:** General Purpose SSD
- **io2/io1:** Provisioned IOPS SSD
- **st1:** Throughput Optimized HDD
- **sc1:** Cold HDD

**Use Cases:**
- Boot volumes for EC2 instances
- Database storage
- Enterprise applications
- Big data analytics engines

### Amazon EFS (Elastic File System)

Fully managed elastic NFS file system for use with AWS Cloud services and on-premises resources. Automatically grows and shrinks as you add and remove files.

**Storage Classes:**
- **Standard:** Frequently accessed files
- **Infrequent Access (IA):** Cost-optimized for files accessed less frequently

**Use Cases:**
- Shared file storage for applications
- Content management systems
- Web serving
- Container storage
- Big data analytics

## Key Concepts

### Storage Performance

- **IOPS:** Input/Output Operations Per Second
- **Throughput:** Data transfer rate (MB/s or GB/s)
- **Latency:** Time to complete an I/O operation
- **Durability:** Protection against data loss (11 9s for S3/EFS)
- **Availability:** Uptime and accessibility (99.99% for EFS)

### Cost Optimization

- **Storage Classes:** Choose appropriate tier (Standard, IA, Glacier)
- **Lifecycle Policies:** Automatic transition to cheaper storage
- **Right-Sizing:** Match storage to actual needs
- **Compression:** Reduce storage footprint
- **Deduplication:** Eliminate redundant data

### Backup Strategies

- **RPO (Recovery Point Objective):** Maximum acceptable data loss
- **RTO (Recovery Time Objective):** Maximum acceptable downtime
- **Backup Frequency:** Daily, hourly, continuous
- **Retention Policies:** How long to keep backups
- **Testing:** Regular restore testing

## Skills Demonstrated

- AWS CLI proficiency for storage operations
- Storage performance benchmarking and analysis
- RAID configuration and management
- File system creation and mounting
- Backup automation with AWS Backup
- Cost optimization through lifecycle management
- Security configuration (security groups, encryption)
- Performance tuning and optimization
- Disaster recovery planning

## Certification Alignment

These labs align with the following AWS certification exam domains:

**AWS Certified Solutions Architect - Associate:**
- Domain 1: Design Resilient Architectures (EFS multi-AZ, backups)
- Domain 2: Design High-Performing Architectures (EBS RAID, performance optimization)
- Domain 3: Design Secure Applications (encryption, security groups, IAM)
- Domain 4: Design Cost-Optimized Architectures (lifecycle policies, storage classes)

**AWS Certified Solutions Architect - Professional:**
- Domain 1: Design for Organizational Complexity (multi-account backup strategies)
- Domain 2: Design for New Solutions (storage architecture design)
- Domain 3: Migration Planning (data migration strategies)
- Domain 4: Cost Control (advanced cost optimization)

## Additional Resources

- [Amazon S3 Documentation](https://docs.aws.amazon.com/s3/)
- [Amazon EBS Documentation](https://docs.aws.amazon.com/ebs/)
- [Amazon EFS Documentation](https://docs.aws.amazon.com/efs/)
- [AWS Backup Documentation](https://docs.aws.amazon.com/aws-backup/)
- [AWS Storage Blog](https://aws.amazon.com/blogs/storage/)
