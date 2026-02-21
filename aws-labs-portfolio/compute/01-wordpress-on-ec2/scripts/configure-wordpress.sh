#!/bin/bash
# WordPress on EC2 - WordPress Installation Script
# This script downloads and configures WordPress

set -e  # Exit on error

echo "=== WordPress Installation ==="

# Configuration variables
WP_DIR="/var/www/html"
WP_DOWNLOAD_URL="https://wordpress.org/latest.tar.gz"

# Download WordPress
echo "Downloading WordPress..."
cd /tmp
wget ${WP_DOWNLOAD_URL}

# Extract WordPress
echo "Extracting WordPress..."
tar -xzf latest.tar.gz

# Copy WordPress files to web root
echo "Installing WordPress to ${WP_DIR}..."
sudo cp -r wordpress/* ${WP_DIR}/

# Create wp-config.php from sample
echo "Creating wp-config.php..."
sudo cp ${WP_DIR}/wp-config-sample.php ${WP_DIR}/wp-config.php

echo ""
echo "=== WordPress Installation Complete ==="
echo ""
echo "⚠️  NEXT STEPS:"
echo "1. Edit ${WP_DIR}/wp-config.php with your database credentials:"
echo "   - DB_NAME: wordpress"
echo "   - DB_USER: wordpress_user"
echo "   - DB_PASSWORD: (your password from configure-database.sh)"
echo "   - DB_HOST: localhost"
echo ""
echo "2. Run configure-permissions.sh to set proper file ownership"
echo ""
echo "3. Access your EC2 instance's public IP in a browser to complete setup"
echo ""
echo "Example wp-config.php edit commands:"
echo "sudo sed -i 's/database_name_here/wordpress/' ${WP_DIR}/wp-config.php"
echo "sudo sed -i 's/username_here/wordpress_user/' ${WP_DIR}/wp-config.php"
echo "sudo sed -i 's/password_here/your_secure_password_here/' ${WP_DIR}/wp-config.php"
