# EBS RAID 0 Benchmarking Architecture

## Architecture Overview

This architecture demonstrates Amazon EBS volume performance optimization through RAID 0 (striping) configuration. The design compares standalone EBS volume performance against a RAID 0 array of multiple volumes, using FIO benchmarking to measure IOPS, throughput, and latency across various workload patterns.

## Components

### 1. EC2 Instance

The EC2 instance hosts the RAID configuration and runs performance benchmarks.

**Instance Requirements:**
- EBS-optimized instance type (t3, m5, c5, or higher)
- Sufficient network bandwidth for EBS throughput
- Amazon Linux 2023 or Ubuntu 20.04/22.04
- Minimum 2 vCPUs and 4 GB RAM
- Enhanced networking enabled

**Recommended Instance Types:**
- **t3.xlarge**: 4 vCPUs, 16 GB RAM, up to 2,780 Mbps EBS bandwidth
- **m5.xlarge**: 4 vCPUs, 16 GB RAM, up to 4,750 Mbps EBS bandwidth
- **c5.2xlarge**: 8 vCPUs, 16 GB RAM, up to 4,750 Mbps EBS bandwidth

### 2. EBS Volumes

Multiple EBS volumes are attached to the EC2 instance for testing.

**Standalone Volume:**
- **Type**: gp3 (General Purpose SSD)
- **Size**: 100 GB
- **Baseline Performance**: 3,000 IOPS, 125 MB/s throughput
- **Purpose**: Baseline performance comparison

**RAID 0 Array Volumes:**
- **Count**: 4 volumes
- **Type**: gp3 (General Purpose SSD)
- **Size per volume**: 100 GB
- **Individual Performance**: 3,000 IOPS, 125 MB/s each
- **Aggregate Performance**: 12,000 IOPS, 500 MB/s (theoretical)

**EBS Volume Types Comparison:**

| Type | Use Case | IOPS | Throughput | Latency |
|------|----------|------|------------|---------|
| gp3 | General purpose | 3,000-16,000 | 125-1,000 MB/s | Single-digit ms |
| io2 | High performance | 64,000+ | 1,000 MB/s | Sub-millisecond |
| st1 | Throughput optimized | 500 | 500 MB/s | Low |
| sc1 | Cold storage | 250 | 250 MB/s | Low |

### 3. RAID 0 Configuration

RAID 0 stripes data across multiple volumes for improved performance.

**RAID 0 Characteristics:**
- **Striping**: Data split across all volumes
- **Capacity**: Sum of all volume sizes (400 GB with 4x100 GB)
- **Performance**: Aggregate of all volumes
- **Redundancy**: None (single volume failure loses all data)
- **Stripe Size**: 256 KB (configurable)

**mdadm Configuration:**
```bash
mdadm --create /dev/md0 \
    --level=0 \
    --raid-devices=4 \
    --chunk=256 \
    /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1 /dev/nvme4n1
```

**Stripe Size Considerations:**
- **Small (64-128 KB)**: Better for random I/O, databases
- **Medium (256-512 KB)**: Balanced for mixed workloads
- **Large (1-2 MB)**: Better for sequential I/O, large files

### 4. File Systems

Both standalone and RAID volumes use ext4 file system.

**ext4 Configuration:**
- **Block size**: 4 KB (default)
- **Inode size**: 256 bytes
- **Reserved blocks**: 5% (default)
- **Journal**: Enabled for data integrity
- **Mount options**: noatime, nodiratime for performance

**File System Creation:**
```bash
mkfs.ext4 -L standalone /dev/nvme1n1
mkfs.ext4 -L raid0 /dev/md0
```

**Mount Options:**
```
/dev/md0 /mnt/raid0 ext4 defaults,noatime,nodiratime 0 2
```

### 5. FIO Benchmarking Tool

FIO (Flexible I/O Tester) measures storage performance.

**FIO Capabilities:**
- Multiple I/O engines (sync, libaio, io_uring)
- Various access patterns (sequential, random, mixed)
- Configurable block sizes and queue depths
- Direct I/O bypass of OS cache
- Detailed latency statistics

**Key FIO Parameters:**
- **ioengine**: libaio (Linux native async I/O)
- **direct**: 1 (bypass page cache)
- **iodepth**: Queue depth (32-64 typical)
- **bs**: Block size (4K for random, 1M for sequential)
- **rw**: Read/write pattern (read, write, randread, randwrite, randrw)
- **size**: Test file size
- **runtime**: Test duration

### 6. Performance Monitoring

CloudWatch monitors EBS volume metrics.

**Key Metrics:**
- **VolumeReadOps/VolumeWriteOps**: IOPS
- **VolumeReadBytes/VolumeWriteBytes**: Throughput
- **VolumeThroughputPercentage**: Throughput utilization
- **VolumeConsumedReadWriteOps**: IOPS utilization
- **BurstBalance**: Credit balance for gp2/gp3 bursting

## Data Flow

### RAID 0 Write Operation

1. **Application Write**: Application writes data to /mnt/raid0
2. **File System Layer**: ext4 processes write request
3. **RAID Layer**: mdadm splits data into stripes
4. **Stripe Distribution**: 
   - Stripe 1 → /dev/nvme1n1 (Volume 1)
   - Stripe 2 → /dev/nvme2n1 (Volume 2)
   - Stripe 3 → /dev/nvme3n1 (Volume 3)
   - Stripe 4 → /dev/nvme4n1 (Volume 4)
5. **Parallel Writes**: All volumes write simultaneously
6. **EBS Service**: AWS EBS service persists data
7. **Acknowledgment**: Write completion returned to application

### RAID 0 Read Operation

1. **Application Read**: Application reads data from /mnt/raid0
2. **File System Layer**: ext4 processes read request
3. **RAID Layer**: mdadm determines which stripes contain data
4. **Parallel Reads**: Multiple volumes read simultaneously
5. **Data Assembly**: mdadm reassembles stripes into original data
6. **Return Data**: Data returned to application

### Standalone Volume Operation

1. **Application I/O**: Application reads/writes to /mnt/standalone
2. **File System Layer**: ext4 processes request
3. **Block Device**: Direct I/O to /dev/nvme1n1
4. **EBS Service**: Single volume handles request
5. **Acknowledgment**: Completion returned to application

## Performance Analysis

### Sequential Read Performance

**Standalone Volume (gp3):**
- Throughput: ~125 MB/s (volume limit)
- IOPS: ~125 (with 1M blocks)
- Latency: 5-10 ms

**RAID 0 Array (4x gp3):**
- Throughput: ~500 MB/s (4x volume limit)
- IOPS: ~500 (with 1M blocks)
- Latency: 5-10 ms
- **Improvement**: 4x throughput

### Sequential Write Performance

**Standalone Volume (gp3):**
- Throughput: ~125 MB/s
- IOPS: ~125 (with 1M blocks)
- Latency: 5-10 ms

**RAID 0 Array (4x gp3):**
- Throughput: ~500 MB/s
- IOPS: ~500 (with 1M blocks)
- Latency: 5-10 ms
- **Improvement**: 4x throughput

### Random Read Performance

**Standalone Volume (gp3):**
- IOPS: ~3,000 (volume limit)
- Throughput: ~12 MB/s (with 4K blocks)
- Latency: 1-2 ms

**RAID 0 Array (4x gp3):**
- IOPS: ~12,000 (4x volume limit)
- Throughput: ~48 MB/s (with 4K blocks)
- Latency: 1-2 ms
- **Improvement**: 4x IOPS

### Random Write Performance

**Standalone Volume (gp3):**
- IOPS: ~3,000
- Throughput: ~12 MB/s (with 4K blocks)
- Latency: 1-2 ms

**RAID 0 Array (4x gp3):**
- IOPS: ~12,000
- Throughput: ~48 MB/s (with 4K blocks)
- Latency: 1-2 ms
- **Improvement**: 4x IOPS

### Mixed Workload (70% Read, 30% Write)

**Standalone Volume (gp3):**
- IOPS: ~3,000
- Read latency: 1-2 ms
- Write latency: 2-3 ms

**RAID 0 Array (4x gp3):**
- IOPS: ~12,000
- Read latency: 1-2 ms
- Write latency: 2-3 ms
- **Improvement**: 4x IOPS

## RAID 0 vs Other RAID Levels

### RAID 0 (Striping)

**Advantages:**
- Maximum performance (IOPS and throughput)
- Full capacity utilization
- Simple configuration

**Disadvantages:**
- No redundancy
- Single volume failure loses all data
- Not suitable for critical data

**Use Cases:**
- Temporary data processing
- Cache layers
- High-performance computing
- Video rendering

### RAID 1 (Mirroring)

**Advantages:**
- Data redundancy
- Read performance improvement
- Simple recovery

**Disadvantages:**
- 50% capacity utilization
- Write performance same as single volume
- Higher cost per usable GB

### RAID 10 (Striping + Mirroring)

**Advantages:**
- Performance and redundancy
- Can survive multiple drive failures
- Good for databases

**Disadvantages:**
- 50% capacity utilization
- Requires minimum 4 volumes
- Higher cost

### RAID 5 (Striping + Parity)

**Advantages:**
- Redundancy with better capacity utilization
- Can survive single drive failure
- Good read performance

**Disadvantages:**
- Write penalty due to parity calculation
- Complex recovery
- Not recommended for EBS (network overhead)

## Snapshot Strategy

### Multi-Volume Snapshots

Creating consistent snapshots of RAID 0 array:

1. **Freeze File System**: Ensure data consistency
   ```bash
   sudo fsfreeze -f /mnt/raid0
   ```

2. **Create Snapshots**: Snapshot all volumes simultaneously
   ```bash
   aws ec2 create-snapshots \
       --instance-specification InstanceId=i-xxx,ExcludeBootVolume=true \
       --description "RAID 0 array snapshot"
   ```

3. **Unfreeze File System**: Resume I/O operations
   ```bash
   sudo fsfreeze -u /mnt/raid0
   ```

### Recovery from Snapshots

1. **Create Volumes**: Create new volumes from all snapshots
2. **Attach Volumes**: Attach to EC2 instance
3. **Assemble Array**: Use mdadm to assemble RAID array
4. **Mount File System**: Mount the recovered array

## Performance Optimization

### Instance-Level Optimization

**EBS-Optimized Instances:**
- Dedicated bandwidth for EBS traffic
- Prevents network contention
- Required for consistent performance

**Instance Type Selection:**
- Choose instance with sufficient EBS bandwidth
- Consider CPU requirements for RAID overhead
- Use current generation instances (m5, c5, r5)

### Volume-Level Optimization

**Volume Type Selection:**
- gp3: Cost-effective, configurable performance
- io2: Highest performance, sub-millisecond latency
- io2 Block Express: Up to 256,000 IOPS per volume

**Volume Configuration:**
- Increase gp3 IOPS/throughput as needed
- Use multiple smaller volumes vs one large volume
- Consider volume placement across AZs for availability

### RAID Configuration Optimization

**Stripe Size:**
- Match to workload I/O size
- Larger stripes for sequential workloads
- Smaller stripes for random workloads

**Number of Volumes:**
- More volumes = higher performance
- Diminishing returns after 4-8 volumes
- Consider instance EBS bandwidth limit

### File System Optimization

**Mount Options:**
- noatime: Don't update access times
- nodiratime: Don't update directory access times
- discard: Enable TRIM for SSDs

**ext4 Tuning:**
- Adjust reserved blocks percentage
- Tune journal settings
- Consider XFS for large files

## Cost Analysis

### Standalone Volume Cost

**100 GB gp3 Volume:**
- Storage: 100 GB × $0.08/GB/month = $8.00/month
- IOPS: 3,000 (included)
- Throughput: 125 MB/s (included)
- **Total**: $8.00/month

### RAID 0 Array Cost

**4x 100 GB gp3 Volumes:**
- Storage: 400 GB × $0.08/GB/month = $32.00/month
- IOPS: 12,000 (included)
- Throughput: 500 MB/s (included)
- **Total**: $32.00/month

### Cost per Performance

**Standalone:**
- Cost per 1,000 IOPS: $2.67/month
- Cost per 100 MB/s: $6.40/month

**RAID 0:**
- Cost per 1,000 IOPS: $2.67/month
- Cost per 100 MB/s: $6.40/month

**Analysis**: Cost per performance unit is the same, but RAID 0 provides higher absolute performance.

### Alternative: Single High-Performance Volume

**400 GB gp3 with 12,000 IOPS:**
- Storage: 400 GB × $0.08/GB/month = $32.00/month
- Additional IOPS: 9,000 × $0.005/IOPS/month = $45.00/month
- **Total**: $77.00/month

**Comparison**: RAID 0 with 4x100 GB volumes ($32/month) is more cost-effective than single 400 GB volume with provisioned IOPS ($77/month).

## Monitoring and Alerting

### CloudWatch Metrics

**Volume Metrics:**
- VolumeReadOps, VolumeWriteOps
- VolumeReadBytes, VolumeWriteBytes
- VolumeThroughputPercentage
- VolumeConsumedReadWriteOps
- VolumeQueueLength

**Instance Metrics:**
- EBSReadOps, EBSWriteOps
- EBSReadBytes, EBSWriteBytes
- EBSIOBalance% (for burst-capable instances)

### Recommended Alarms

**High Latency:**
- Metric: VolumeQueueLength
- Threshold: > 10
- Action: Investigate I/O bottleneck

**Throughput Limit:**
- Metric: VolumeThroughputPercentage
- Threshold: > 95%
- Action: Increase volume throughput or add volumes

**IOPS Limit:**
- Metric: VolumeConsumedReadWriteOps
- Threshold: > 95%
- Action: Increase volume IOPS or add volumes

## Disaster Recovery

### Backup Strategy

**Regular Snapshots:**
- Daily snapshots of all RAID volumes
- Tag snapshots with RAID array identifier
- Retain snapshots based on retention policy

**Snapshot Consistency:**
- Use fsfreeze for file system consistency
- Create all snapshots simultaneously
- Test recovery procedures regularly

### Recovery Procedures

**Volume Failure:**
1. RAID 0 has no redundancy - data loss occurs
2. Restore from most recent snapshot set
3. Create new volumes from snapshots
4. Reassemble RAID array
5. Verify data integrity

**Complete Array Loss:**
1. Create volumes from snapshot set
2. Attach volumes to new or existing instance
3. Assemble RAID array with mdadm
4. Mount file system
5. Verify application functionality

### High Availability Alternatives

For critical data requiring high availability:
- Use RAID 10 instead of RAID 0
- Use Amazon EFS for shared file storage
- Use Amazon FSx for managed file systems
- Implement application-level replication
- Use RDS for database workloads

