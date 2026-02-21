#!/bin/bash

# Run Comprehensive FIO Benchmarks
# Tests both standalone volume and RAID 0 array

set -e

# Configuration
STANDALONE_MOUNT="/mnt/standalone"
RAID_MOUNT="/mnt/raid0"
RESULTS_DIR="./benchmark-results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Create results directory
mkdir -p "$RESULTS_DIR"

echo "========================================="
echo "EBS RAID 0 Performance Benchmarking"
echo "========================================="
echo "Timestamp: $TIMESTAMP"
echo "Standalone mount: $STANDALONE_MOUNT"
echo "RAID 0 mount: $RAID_MOUNT"
echo "Results directory: $RESULTS_DIR"
echo ""

# Check if mounts exist
if [ ! -d "$STANDALONE_MOUNT" ]; then
    echo "Error: Standalone mount point not found: $STANDALONE_MOUNT"
    exit 1
fi

if [ ! -d "$RAID_MOUNT" ]; then
    echo "Error: RAID mount point not found: $RAID_MOUNT"
    exit 1
fi

# Function to run FIO test
run_fio_test() {
    local test_name=$1
    local mount_point=$2
    local config=$3
    local output_file="$RESULTS_DIR/${test_name}_${TIMESTAMP}.json"
    
    echo "Running: $test_name on $mount_point"
    
    fio --name="$test_name" \
        --directory="$mount_point" \
        --output-format=json \
        --output="$output_file" \
        $config
    
    echo "  ✓ Completed: $output_file"
}

echo "========================================="
echo "Test 1: Sequential Read Performance"
echo "========================================="

run_fio_test "standalone_seq_read" "$STANDALONE_MOUNT" \
    "--rw=read --bs=1M --iodepth=32 --direct=1 --size=1G --numjobs=1 --runtime=60 --time_based"

run_fio_test "raid0_seq_read" "$RAID_MOUNT" \
    "--rw=read --bs=1M --iodepth=32 --direct=1 --size=1G --numjobs=1 --runtime=60 --time_based"

echo ""
echo "========================================="
echo "Test 2: Sequential Write Performance"
echo "========================================="

run_fio_test "standalone_seq_write" "$STANDALONE_MOUNT" \
    "--rw=write --bs=1M --iodepth=32 --direct=1 --size=1G --numjobs=1 --runtime=60 --time_based"

run_fio_test "raid0_seq_write" "$RAID_MOUNT" \
    "--rw=write --bs=1M --iodepth=32 --direct=1 --size=1G --numjobs=1 --runtime=60 --time_based"

echo ""
echo "========================================="
echo "Test 3: Random Read Performance (4K)"
echo "========================================="

run_fio_test "standalone_rand_read_4k" "$STANDALONE_MOUNT" \
    "--rw=randread --bs=4K --iodepth=64 --direct=1 --size=1G --numjobs=1 --runtime=60 --time_based"

run_fio_test "raid0_rand_read_4k" "$RAID_MOUNT" \
    "--rw=randread --bs=4K --iodepth=64 --direct=1 --size=1G --numjobs=1 --runtime=60 --time_based"

echo ""
echo "========================================="
echo "Test 4: Random Write Performance (4K)"
echo "========================================="

run_fio_test "standalone_rand_write_4k" "$STANDALONE_MOUNT" \
    "--rw=randwrite --bs=4K --iodepth=64 --direct=1 --size=1G --numjobs=1 --runtime=60 --time_based"

run_fio_test "raid0_rand_write_4k" "$RAID_MOUNT" \
    "--rw=randwrite --bs=4K --iodepth=64 --direct=1 --size=1G --numjobs=1 --runtime=60 --time_based"

echo ""
echo "========================================="
echo "Test 5: Mixed Workload (70% Read, 30% Write)"
echo "========================================="

run_fio_test "standalone_mixed_70_30" "$STANDALONE_MOUNT" \
    "--rw=randrw --rwmixread=70 --bs=4K --iodepth=32 --direct=1 --size=1G --numjobs=1 --runtime=60 --time_based"

run_fio_test "raid0_mixed_70_30" "$RAID_MOUNT" \
    "--rw=randrw --rwmixread=70 --bs=4K --iodepth=32 --direct=1 --size=1G --numjobs=1 --runtime=60 --time_based"

echo ""
echo "========================================="
echo "All benchmarks completed!"
echo "========================================="
echo "Results saved to: $RESULTS_DIR"
echo ""
echo "To analyze results, run: ./analyze-results.sh"
