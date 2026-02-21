#!/bin/bash
# WordPress on EC2 - Environment Setup Script
# This script installs all required packages for WordPress on Amazon Linux 2023

set -e  # Exit on error

echo "=== WordPress Environment Setup ==="
echo "Installing Apache, PHP, MariaDB, and dependencies..."

# Update system packages
sudo dnf update -y

# Install Apache HTTP Server
echo "Installing Apache HTTP Server..."
sudo dnf install -y httpd

# Install PHP 8.2 and required extensions
echo "Installing PHP 8.2 and extensions..."
sudo dnf install -y \
    php \
    php-mysqlnd \
    php-gd \
    php-xml \
    php-mbstring \
    php-json

# Install MariaDB 10.5
echo "Installing MariaDB 10.5..."
sudo dnf install -y mariadb105-server

# Install wget for downloading WordPress
echo "Installing wget..."
sudo dnf install -y wget

# Install mod_ssl for HTTPS support
echo "Installing mod_ssl for SSL/TLS..."
sudo dnf install -y mod_ssl

# Start and enable Apache
echo "Starting Apache HTTP Server..."
sudo systemctl start httpd
sudo systemctl enable httpd

# Start and enable MariaDB
echo "Starting MariaDB..."
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Verify services are running
echo ""
echo "=== Service Status ==="
sudo systemctl status httpd --no-pager | grep "Active:"
sudo systemctl status mariadb --no-pager | grep "Active:"

echo ""
echo "=== Environment Setup Complete ==="
echo "Apache and MariaDB are running"
echo "Next step: Run configure-database.sh"
