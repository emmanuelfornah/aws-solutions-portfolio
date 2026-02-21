#!/bin/bash

# Install amazon-efs-utils Package
# Provides EFS mount helper and utilities

set -e

echo "Installing amazon-efs-utils..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS"
    exit 1
fi

# Install based on OS
case $OS in
    amzn)
        echo "Detected Amazon Linux"
        sudo yum install -y amazon-efs-utils
        ;;
    ubuntu|debian)
        echo "Detected Ubuntu/Debian"
        # Add package repository
        sudo apt-get update
        sudo apt-get install -y git binutils
        
        # Clone and build amazon-efs-utils
        cd /tmp
        git clone https://github.com/aws/efs-utils
        cd efs-utils
        ./build-deb.sh
        sudo apt-get install -y ./build/amazon-efs-utils*deb
        cd ~
        rm -rf /tmp/efs-utils
        ;;
    rhel|centos|fedora)
        echo "Detected RHEL/CentOS/Fedora"
        sudo yum install -y amazon-efs-utils
        ;;
    *)
        echo "Unsupported OS: $OS"
        echo "Please install amazon-efs-utils manually"
        exit 1
        ;;
esac

# Verify installation
if command -v mount.efs &> /dev/null; then
    echo "✓ amazon-efs-utils installed successfully"
    mount.efs --version
else
    echo "✗ amazon-efs-utils installation failed"
    exit 1
fi

echo ""
echo "amazon-efs-utils is ready to use!"
echo ""
echo "Mount EFS with:"
echo "  sudo mount -t efs -o tls fs-12345678:/ /mnt/efs"
