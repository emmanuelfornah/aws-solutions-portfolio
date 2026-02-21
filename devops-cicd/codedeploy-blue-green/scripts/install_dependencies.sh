#!/bin/bash

# CodeDeploy lifecycle hook: BeforeInstall
# Installs dependencies and prepares the environment
# Runs on GREEN instances during blue/green deployment

set -e

echo "=== BeforeInstall Hook ==="
echo "Installing dependencies and preparing environment..."

# Update package manager
echo "Updating package manager..."
yum update -y

# Install Apache if not already installed
if ! command -v httpd &> /dev/null; then
    echo "Installing Apache web server..."
    yum install -y httpd
    echo "✓ Apache installed"
else
    echo "✓ Apache already installed"
fi

# Install PHP if needed (example for PHP applications)
# if ! command -v php &> /dev/null; then
#     echo "Installing PHP..."
#     yum install -y php php-mysql
#     echo "✓ PHP installed"
# fi

# Create application directory if it doesn't exist
if [ ! -d /var/www/html ]; then
    echo "Creating application directory..."
    mkdir -p /var/www/html
    echo "✓ Directory created"
fi

# Set proper ownership
chown -R apache:apache /var/www/html

# Clear any old application files
echo "Cleaning up old application files..."
rm -rf /var/www/html/*
echo "✓ Cleanup completed"

# Optional: Install application-specific dependencies
# Example: Install Node.js dependencies
# if [ -f /tmp/package.json ]; then
#     cd /tmp
#     npm install
#     echo "✓ Node.js dependencies installed"
# fi

echo "BeforeInstall hook completed"
exit 0
