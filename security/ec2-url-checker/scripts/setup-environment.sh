#!/bin/bash
# Setup script for Python 3.11 environment on Amazon Linux 2023
# This script installs Python 3.11 and pip package manager

set -e  # Exit on any error

echo "=========================================="
echo "Setting up Python 3.11 environment"
echo "=========================================="

# Update system packages
echo "Updating system packages..."
sudo dnf update -y

# Install Python 3.11
echo "Installing Python 3.11..."
sudo dnf install -y python3.11

# Install pip for Python 3.11
echo "Installing pip..."
sudo dnf install -y python3.11-pip

# Verify installations
echo ""
echo "Verifying installations..."
python3.11 --version
pip3.11 --version

# Create symlinks for convenience (optional)
echo ""
echo "Creating symlinks..."
sudo ln -sf /usr/bin/python3.11 /usr/bin/python3
sudo ln -sf /usr/bin/pip3.11 /usr/bin/pip3

echo ""
echo "=========================================="
echo "Python environment setup complete!"
echo "=========================================="
echo "Python version: $(python3 --version)"
echo "Pip version: $(pip3 --version)"
