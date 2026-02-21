# Benchmarking Amazon EBS RAID 0 Compared to Standalone Amazon EBS Volumes

## Overview

This lab demonstrates the performance benefits of RAID 0 (striping) configuration with Amazon EBS volumes compared to standalone EBS volumes. The implementation includes creating multiple EBS volumes, configuring RAID 0 using mdadm, creating ext4 file systems, configuring persistent mounts via fstab, and conducting comprehensive performance benchmarking using FIO (Flexible I/O Tester). The lab also covers multi-volume snapshots for backup and recovery.

## AWS Services Used

- **Amazon EBS** - Block storage volumes for EC2 instances
- **Amazon EC2** - Compute instance for RAID configuration and testing
- **EBS Snapshots** - Point-in-time backups of EBS volumes
- **CloudWatch** - Monitoring EBS performance metrics

## Key Technologies

- **mdadm** - Linux software RAID management tool
- **FIO** - Flexible I/O Tester for performance benchmarking
- **ext4** - Fourth extended file system
- **fstab** - File system table for persistent mounts
- **RAID 0** - Disk striping for improved performance
- **Linux LVM** - Logical Volume Manager (alternative approach)

## Architecture Overview

The architecture consists of an EC2 instance with multiple EBS volumes attached. One volume serves as a standalone baseline, while multiple volumes are combined into a RAID 0 array using mdadm. Both configurations are benchmarked using FIO to measure IOPS, throughput, and latency under various workload patterns (sequential read/write, random read/write, mixed workloads).

See [architecture.md](./architecture.md) for detailed architecture description and performance analysis.

## Objectives

- Understand EBS volume types and performance characteristics
- Configure Linux software RAID 0 using mdadm
- Create and mount ext4 file systems
- Configure persistent mounts using /etc/fstab
- Conduct comprehensive I/O performance benchmarking with FIO
- Analyze performance differences between standalone and RAID 0 configurations
- Create multi-volume snapshots for backup
- Understand RAID 0 benefits and limitations

## Key Learnings

- **RAID 0 Performance**: Striping data across multiple volumes increases aggregate IOPS and throughput
- **mdadm Configuration**: Creating, managing, and monitoring Linux software RAID arrays
- **File System Creation**: Formatting RAID devices and standalone volumes with ext4
- **Persistent Mounts**: Configuring /etc/fstab for automatic mounting at boot
- **FIO Benchmarking**: Using FIO to measure IOPS, bandwidth, and latency with various I/O patterns
- **Performance Analysis**: Interpreting benchmark results and understanding workload characteristics
- **EBS Volume Types**: Comparing gp3, io2, and st1 performance characteristics
- **Snapshot Strategy**: Creating coordinated snapshots of RAID arrays
- **RAID 0 Limitations**: Understanding data loss risk and lack of redundancy

## Setup Instructions

### Prerequisites

- AWS account with EC2 and EBS permissions
- EC2 instance running Amazon Linux 2023 or Ubuntu
- Multiple EBS volumes attached to the instance
- SSH access to EC2 instance
- Root or sudo privileges

### Step 1: Attach EBS Volumes

Create and attach EBS volumes to your EC2 instance:

```bash
# Run from your local machine with AWS CLI
./scripts/create-ebs-volumes.sh
```

This creates:
- 1x 100 GB gp3 volume for standalone testing
- 4x 100 GB gp3 volumes for RAID 0 array

### Step 2: Install Required Tools

Install mdadm and FIO on the EC2 instance:

```bash
# SSH into your EC2 instance, then run:
./scripts/install-tools.sh
```

### Step 3: Configure RAID 0 Array

Create RAID 0 array from multiple EBS volumes:

```bash
./scripts/configure-raid0.sh
```

This script:
- Identifies attached EBS volumes
- Creates RAID 0 array using mdadm
- Saves RAID configuration to /etc/mdadm.conf
- Updates initramfs for boot persistence

### Step 4: Create File Systems

Format both standalone volume and RAID array:

```bash
./scripts/create-filesystems.sh
```

This creates ext4 file systems with optimized parameters.

### Step 5: Configure Persistent Mounts

Set up automatic mounting via /etc/fstab:

```bash
./scripts/configure-fstab.sh
```

This configures:
- /mnt/standalone - Standalone EBS volume mount point
- /mnt/raid0 - RAID 0 array mount point

### Step 6: Run Performance Benchmarks

Execute comprehensive FIO benchmarks:

```bash
./scripts/run-benchmarks.sh
```

This runs multiple test scenarios:
- Sequential read/write
- Random read/write
- Mixed read/write (70/30)
- Various block sizes (4K, 16K, 64K, 1M)
- Different queue depths

### Step 7: Analyze Results

Review benchmark results and generate comparison report:

```bash
./scripts/analyze-results.sh
```

### Step 8: Create Multi-Volume Snapshots

Create coordinated snapshots of RAID array:

```bash
./scripts/create-snapshots.sh
```

## Scripts and Configurations

### Scripts

All scripts are located in the `scripts/` directory:

- **create-ebs-volumes.sh** - Creates and attaches EBS volumes to EC2 instance
- **install-tools.sh** - Installs mdadm, FIO, and other required tools
- **configure-raid0.sh** - Creates RAID 0 array using mdadm
- **create-filesystems.sh** - Formats volumes with ext4 file system
- **configure-fstab.sh** - Sets up persistent mounts in /etc/fstab
- **run-benchmarks.sh** - Executes comprehensive FIO performance tests
- **analyze-results.sh** - Parses FIO output and generates comparison report
- **create-snapshots.sh** - Creates coordinated snapshots of all volumes
- **cleanup.sh** - Removes RAID array and unmounts file systems

### Configuration Files

Configuration templates are located in the `configs/` directory:

- **fio-sequential-read.fio** - FIO job file for sequential read test
- **fio-sequential-write.fio** - FIO job file for sequential write test
- **fio-random-read.fio** - FIO job file for random read test
- **fio-random-write.fio** - FIO job file for random write test
- **fio-mixed-rw.fio** - FIO job file for mixed read/write test
- **mdadm.conf.template** - Template for mdadm configuration
- **fstab.template** - Template for fstab entries

## FIO Benchmark Parameters

### Test Scenarios

**Sequential Read:**
- Block size: 1M
- I/O depth: 32
- Direct I/O: enabled
- Measures: Maximum throughput (MB/s)

**Sequential Write:**
- Block size: 1M
- I/O depth: 32
- Direct I/O: enabled
- Measures: Maximum throughput (MB/s)

**Random Read:**
- Block size: 4K
- I/O depth: 64
- Direct I/O: enabled
- Measures: IOPS and latency

**Random Write:**
- Block size: 4K
- I/O depth: 64
- Direct I/O: enabled
- Measures: IOPS and latency

**Mixed Workload:**
- Block size: 4K
- Read/Write ratio: 70/30
- I/O depth: 32
- Measures: Combined IOPS and latency

### Expected Performance Improvements

With 4-volume RAID 0 array:
- **Sequential throughput**: ~4x improvement
- **Random IOPS**: ~4x improvement
- **Latency**: Similar or slightly improved

## Performance Analysis

### RAID 0 Benefits

**Increased Throughput:**
- Data striped across multiple volumes
- Parallel I/O operations
- Aggregate bandwidth of all volumes

**Improved IOPS:**
- Multiple volumes handle concurrent requests
- Linear scaling with number of volumes
- Better performance for random workloads

**Cost Efficiency:**
- Use multiple smaller volumes instead of one large high-performance volume
- Potentially lower cost per IOPS/throughput

### RAID 0 Limitations

**No Redundancy:**
- Single volume failure loses entire array
- Higher risk with more volumes
- Not suitable for critical data without backups

**Snapshot Complexity:**
- Must snapshot all volumes
- Requires coordination for consistency
- Recovery requires all snapshots

**Management Overhead:**
- Additional configuration complexity
- Monitoring multiple volumes
- RAID array maintenance

## Troubleshooting

### RAID Array Issues

**Array Not Assembling:**
```bash
# Check RAID status
cat /proc/mdstat

# Manually assemble array
sudo mdadm --assemble /dev/md0 /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1 /dev/nvme4n1

# Scan and assemble all arrays
sudo mdadm --assemble --scan
```

**Volume Not Detected:**
```bash
# List block devices
lsblk

# Check device names
ls -l /dev/nvme*

# Verify volumes are attached in AWS Console
```

### File System Issues

**Mount Failures:**
```bash
# Check file system
sudo fsck -f /dev/md0

# Verify fstab syntax
sudo mount -a

# Check mount points exist
ls -ld /mnt/standalone /mnt/raid0
```

**Permission Issues:**
```bash
# Fix ownership
sudo chown -R ec2-user:ec2-user /mnt/raid0

# Fix permissions
sudo chmod 755 /mnt/raid0
```

### FIO Benchmark Issues

**FIO Not Found:**
```bash
# Install FIO
sudo yum install -y fio  # Amazon Linux
sudo apt-get install -y fio  # Ubuntu
```

**Insufficient Space:**
```bash
# Check available space
df -h /mnt/raid0

# Reduce test file size in FIO job files
```

**Permission Denied:**
```bash
# Run FIO with sudo
sudo fio job-file.fio

# Or fix directory permissions
sudo chown ec2-user:ec2-user /mnt/raid0
```

## Security Considerations

- EBS volumes are encrypted at rest by default (if enabled)
- Use IAM roles for EC2 instances instead of access keys
- Restrict SSH access to specific IP addresses
- Enable CloudWatch monitoring for volume metrics
- Implement regular snapshot schedules
- Use KMS customer-managed keys for encryption
- Enable EBS encryption by default in account settings

## Cost Optimization

### Storage Costs

- Choose appropriate volume type (gp3 vs io2 vs st1)
- Right-size volumes based on actual performance needs
- Delete unused snapshots
- Use lifecycle policies for snapshot retention
- Consider gp3 for cost-effective baseline performance

### Performance Optimization

- Use gp3 volumes with custom IOPS/throughput settings
- Adjust RAID stripe size for workload
- Use io2 Block Express for highest performance needs
- Monitor CloudWatch metrics to identify bottlenecks
- Use EBS-optimized instance types

## Next Steps

- Implement automated snapshot scheduling with AWS Backup
- Test RAID 0 recovery from snapshots
- Compare RAID 0 with RAID 10 (striping + mirroring)
- Implement CloudWatch alarms for volume metrics
- Test different EBS volume types (io2, st1)
- Explore EBS Multi-Attach for shared storage
- Implement LVM as alternative to mdadm
- Test performance with different instance types

## Lab Metadata

- **Domain**: Storage
- **Complexity Level**: Advanced
- **Estimated Time**: 60 minutes
- **AWS Services**: EBS, EC2, CloudWatch, EBS Snapshots
- **Key Concepts**: RAID 0, mdadm, FIO benchmarking, ext4, fstab, performance optimization
- **Certification Alignment**: AWS Certified Solutions Architect - Professional (Storage optimization, performance tuning)

