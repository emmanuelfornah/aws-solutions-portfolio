#!/bin/bash

# Configure RAID 0 Array with mdadm
# Creates RAID 0 array from multiple EBS volumes

set -e

echo "Configuring RAID 0 array..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# List available block devices
echo "Available block devices:"
lsblk -d -n -o NAME,SIZE,TYPE | grep disk

echo ""
read -p "Enter device names for RAID array (space-separated, e.g., nvme1n1 nvme2n1 nvme3n1 nvme4n1): " DEVICES

# Convert to array
DEVICE_ARRAY=($DEVICES)
DEVICE_COUNT=${#DEVICE_ARRAY[@]}

if [ $DEVICE_COUNT -lt 2 ]; then
    echo "Error: At least 2 devices required for RAID 0"
    exit 1
fi

echo ""
echo "Creating RAID 0 array with $DEVICE_COUNT devices:"
for dev in "${DEVICE_ARRAY[@]}"; do
    echo "  - /dev/$dev"
done

# Build device list with full paths
DEVICE_PATHS=""
for dev in "${DEVICE_ARRAY[@]}"; do
    DEVICE_PATHS="$DEVICE_PATHS /dev/$dev"
done

# Create RAID 0 array
echo ""
echo "Creating RAID 0 array /dev/md0..."
mdadm --create /dev/md0 \
    --level=0 \
    --raid-devices=$DEVICE_COUNT \
    --chunk=256 \
    $DEVICE_PATHS

# Wait for array to be ready
echo "Waiting for array to be ready..."
sleep 2

# Check RAID status
echo ""
echo "RAID array status:"
cat /proc/mdstat

# Get array details
echo ""
echo "RAID array details:"
mdadm --detail /dev/md0

# Save RAID configuration
echo ""
echo "Saving RAID configuration..."
mdadm --detail --scan >> /etc/mdadm.conf

# Update initramfs (for boot persistence)
if command -v dracut &> /dev/null; then
    echo "Updating initramfs with dracut..."
    dracut -f
elif command -v update-initramfs &> /dev/null; then
    echo "Updating initramfs..."
    update-initramfs -u
fi

echo ""
echo "RAID 0 array created successfully!"
echo "Device: /dev/md0"
echo "Level: RAID 0 (striping)"
echo "Devices: $DEVICE_COUNT"
echo "Chunk size: 256 KB"
echo ""
echo "Next steps:"
echo "  1. Create file system: mkfs.ext4 /dev/md0"
echo "  2. Mount the array: mount /dev/md0 /mnt/raid0"
echo "  3. Add to /etc/fstab for persistent mounting"
