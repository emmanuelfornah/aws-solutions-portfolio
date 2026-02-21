#!/bin/bash
# WordPress on EC2 - File Permissions Script
# This script sets proper ownership and permissions for WordPress files

set -e  # Exit on error

echo "=== WordPress File Permissions Configuration ==="

WP_DIR="/var/www/html"

# Set ownership to apache user and group
echo "Setting file ownership to apache:apache..."
sudo chown -R apache:apache ${WP_DIR}

# Set directory permissions to 755 (rwxr-xr-x)
echo "Setting directory permissions to 755..."
sudo find ${WP_DIR} -type d -exec chmod 755 {} \;

# Set file permissions to 644 (rw-r--r--)
echo "Setting file permissions to 644..."
sudo find ${WP_DIR} -type f -exec chmod 644 {} \;

# Set wp-config.php to 600 for security (rw-------)
if [ -f "${WP_DIR}/wp-config.php" ]; then
    echo "Setting wp-config.php to 600 for security..."
    sudo chmod 600 ${WP_DIR}/wp-config.php
fi

# Verify permissions
echo ""
echo "=== Permissions Set Successfully ==="
echo "Verifying ownership and permissions..."
ls -la ${WP_DIR} | head -10

echo ""
echo "✅ File permissions configured:"
echo "   - Owner: apache:apache"
echo "   - Directories: 755 (rwxr-xr-x)"
echo "   - Files: 644 (rw-r--r--)"
echo "   - wp-config.php: 600 (rw-------)"
echo ""
echo "WordPress is ready! Access your EC2 public IP to complete the installation."
