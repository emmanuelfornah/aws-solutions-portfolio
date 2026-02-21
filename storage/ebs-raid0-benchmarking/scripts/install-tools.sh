#!/bin/bash

# Install Required Tools for EBS RAID Benchmarking
# Installs mdadm, FIO, and other utilities

set -e

echo "Installing required tools for EBS RAID benchmarking..."

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
    amzn|rhel|centos|fedora)
        echo "Detected Amazon Linux/RHEL/CentOS/Fedora"
        sudo yum update -y
        sudo yum install -y mdadm fio sysstat nvme-cli jq
        ;;
    ubuntu|debian)
        echo "Detected Ubuntu/Debian"
        sudo apt-get update
        sudo apt-get install -y mdadm fio sysstat nvme-cli jq
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

# Verify installations
echo ""
echo "Verifying installations..."

if command -v mdadm &> /dev/null; then
    echo "✓ mdadm installed: $(mdadm --version | head -1)"
else
    echo "✗ mdadm installation failed"
    exit 1
fi

if command -v fio &> /dev/null; then
    echo "✓ FIO installed: $(fio --version)"
else
    echo "✗ FIO installation failed"
    exit 1
fi

if command -v iostat &> /dev/null; then
    echo "✓ sysstat installed"
else
    echo "✗ sysstat installation failed"
    exit 1
fi

if command -v nvme &> /dev/null; then
    echo "✓ nvme-cli installed"
else
    echo "✗ nvme-cli installation failed"
    exit 1
fi

echo ""
echo "All tools installed successfully!"
echo ""
echo "Installed tools:"
echo "  - mdadm: Linux software RAID management"
echo "  - FIO: Flexible I/O Tester for benchmarking"
echo "  - sysstat: System performance monitoring (iostat)"
echo "  - nvme-cli: NVMe device management"
echo "  - jq: JSON processor for parsing results"
