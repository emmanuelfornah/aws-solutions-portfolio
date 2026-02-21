#!/bin/bash

################################################################################
# Docker Installation Script for Amazon Linux 2023
#
# This script installs Docker on Amazon Linux 2023 and configures it for use.
# It performs the following steps:
# 1. Updates system packages
# 2. Installs Docker
# 3. Starts Docker service
# 4. Adds current user to docker group
# 5. Enables Docker to start on boot
#
# Usage:
#   ./install-docker.sh
#
# Note: You may need to log out and back in for group changes to take effect
################################################################################

set -e  # Exit on any error

echo "========================================"
echo "Docker Installation for Amazon Linux 2023"
echo "========================================"
echo ""

# Check if running on Amazon Linux
if [ ! -f /etc/os-release ]; then
    echo "Error: Cannot determine OS. This script is for Amazon Linux 2023."
    exit 1
fi

source /etc/os-release
if [[ "$ID" != "amzn" ]]; then
    echo "Error: This script is designed for Amazon Linux 2023."
    echo "Detected OS: $PRETTY_NAME"
    exit 1
fi

echo "Step 1: Updating system packages..."
sudo yum update -y

echo ""
echo "Step 2: Installing Docker..."
sudo yum install -y docker

echo ""
echo "Step 3: Starting Docker service..."
sudo systemctl start docker

echo ""
echo "Step 4: Enabling Docker to start on boot..."
sudo systemctl enable docker

echo ""
echo "Step 5: Adding current user ($USER) to docker group..."
sudo usermod -aG docker $USER

echo ""
echo "Step 6: Verifying Docker installation..."
docker --version

echo ""
echo "========================================"
echo "Docker Installation Complete!"
echo "========================================"
echo ""
echo "IMPORTANT: You need to log out and log back in for group changes to take effect."
echo "Alternatively, run: newgrp docker"
echo ""
echo "To verify Docker is working, run:"
echo "  docker run hello-world"
echo ""
echo "To check Docker service status:"
echo "  sudo systemctl status docker"
echo ""
