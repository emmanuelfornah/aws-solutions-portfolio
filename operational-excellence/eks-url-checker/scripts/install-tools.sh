#!/bin/bash

# Install kubectl and eksctl for EKS cluster management
# This script installs the necessary CLI tools for working with Amazon EKS

set -e  # Exit on error

echo "=========================================="
echo "Installing EKS Tools"
echo "=========================================="
echo ""

# Detect OS
OS=$(uname -s)
ARCH=$(uname -m)

echo "Detected OS: $OS"
echo "Detected Architecture: $ARCH"
echo ""

# Install kubectl
echo "=========================================="
echo "Installing kubectl"
echo "=========================================="
echo ""

if command -v kubectl &> /dev/null; then
  echo "kubectl is already installed:"
  kubectl version --client
  echo ""
  read -p "Reinstall kubectl? (y/n): " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping kubectl installation"
  else
    INSTALL_KUBECTL=true
  fi
else
  INSTALL_KUBECTL=true
fi

if [ "$INSTALL_KUBECTL" = true ]; then
  echo "Downloading kubectl..."
  
  # Download kubectl for Linux
  if [ "$OS" = "Linux" ]; then
    curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/amd64/kubectl
  elif [ "$OS" = "Darwin" ]; then
    # macOS
    curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/darwin/amd64/kubectl
  else
    echo "Unsupported OS: $OS"
    exit 1
  fi
  
  # Make executable
  chmod +x ./kubectl
  
  # Move to PATH
  mkdir -p "$HOME/bin"
  mv ./kubectl "$HOME/bin/kubectl"
  
  # Add to PATH if not already there
  if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo 'export PATH=$HOME/bin:$PATH' >> "$HOME/.bashrc"
    export PATH=$HOME/bin:$PATH
  fi
  
  echo "✓ kubectl installed successfully"
  kubectl version --client
fi

echo ""

# Install eksctl
echo "=========================================="
echo "Installing eksctl"
echo "=========================================="
echo ""

if command -v eksctl &> /dev/null; then
  echo "eksctl is already installed:"
  eksctl version
  echo ""
  read -p "Reinstall eksctl? (y/n): " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping eksctl installation"
  else
    INSTALL_EKSCTL=true
  fi
else
  INSTALL_EKSCTL=true
fi

if [ "$INSTALL_EKSCTL" = true ]; then
  echo "Downloading eksctl..."
  
  # Download and extract eksctl
  if [ "$OS" = "Linux" ]; then
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
  elif [ "$OS" = "Darwin" ]; then
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Darwin_amd64.tar.gz" | tar xz -C /tmp
  else
    echo "Unsupported OS: $OS"
    exit 1
  fi
  
  # Move to PATH
  sudo mv /tmp/eksctl /usr/local/bin
  
  echo "✓ eksctl installed successfully"
  eksctl version
fi

echo ""

# Verify AWS CLI
echo "=========================================="
echo "Verifying AWS CLI"
echo "=========================================="
echo ""

if command -v aws &> /dev/null; then
  echo "✓ AWS CLI is installed:"
  aws --version
  echo ""
  
  # Check AWS credentials
  echo "Checking AWS credentials..."
  if aws sts get-caller-identity &> /dev/null; then
    echo "✓ AWS credentials are configured"
    aws sts get-caller-identity
  else
    echo "✗ AWS credentials are not configured"
    echo "Run: aws configure"
  fi
else
  echo "✗ AWS CLI is not installed"
  echo "Install AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
fi

echo ""

# Summary
echo "=========================================="
echo "Installation Summary"
echo "=========================================="
echo ""

if command -v kubectl &> /dev/null; then
  echo "✓ kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
  echo "✗ kubectl: Not installed"
fi

if command -v eksctl &> /dev/null; then
  echo "✓ eksctl: $(eksctl version)"
else
  echo "✗ eksctl: Not installed"
fi

if command -v aws &> /dev/null; then
  echo "✓ aws-cli: $(aws --version)"
else
  echo "✗ aws-cli: Not installed"
fi

echo ""
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Ensure AWS credentials are configured:"
echo "   aws configure"
echo ""
echo "2. Create an EKS cluster:"
echo "   ./create-cluster.sh"
echo ""
echo "3. Deploy applications:"
echo "   ./deploy-imperative.sh"
echo "   ./deploy-declarative.sh"
echo ""
