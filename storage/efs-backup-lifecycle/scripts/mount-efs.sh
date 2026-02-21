#!/bin/bash

# Mount EFS File System
# Uses EFS mount helper with encryption in transit

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Get EFS file system ID
read -p "Enter EFS File System ID (e.g., fs-12345678): " FS_ID

if [ -z "$FS_ID" ]; then
    echo "Error: File system ID is required"
    exit 1
fi

# Mount point
MOUNT_POINT="/mnt/efs"

# Create mount point if it doesn't exist
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Creating mount point: $MOUNT_POINT"
    mkdir -p "$MOUNT_POINT"
fi

# Check if already mounted
if mountpoint -q "$MOUNT_POINT"; then
    echo "Warning: $MOUNT_POINT is already mounted"
    echo "Current mounts:"
    mount | grep "$MOUNT_POINT"
    read -p "Unmount and remount? (yes/no): " REMOUNT
    if [ "$REMOUNT" = "yes" ]; then
        echo "Unmounting $MOUNT_POINT..."
        umount "$MOUNT_POINT"
    else
        echo "Exiting without changes"
        exit 0
    fi
fi

# Mount EFS with encryption in transit
echo "Mounting EFS file system: $FS_ID"
echo "Mount point: $MOUNT_POINT"
echo "Options: TLS encryption enabled"

mount -t efs -o tls "$FS_ID":/ "$MOUNT_POINT"

# Verify mount
if mountpoint -q "$MOUNT_POINT"; then
    echo ""
    echo "✓ EFS mounted successfully!"
    echo ""
    echo "Mount details:"
    mount | grep "$MOUNT_POINT"
    echo ""
    echo "Disk usage:"
    df -h "$MOUNT_POINT"
    echo ""
    echo "Test the mount:"
    echo "  cd $MOUNT_POINT"
    echo "  touch test-file.txt"
    echo "  ls -la"
else
    echo "✗ Mount failed"
    exit 1
fi
