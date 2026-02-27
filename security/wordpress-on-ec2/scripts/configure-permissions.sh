#!/bin/bash
# configure-permissions.sh
# Sets proper file ownership and permissions for WordPress installation

set -e  # Exit on any error

echo "=========================================="
echo "WordPress File Permissions Configuration"
echo "=========================================="
echo ""

# Configuration variables
WP_DIR="/var/www/html"
WP_OWNER="apache"
WP_GROUP="apache"

# Verify WordPress directory exists
if [ ! -d "${WP_DIR}" ]; then
    echo "✗ WordPress directory not found: ${WP_DIR}"
    exit 1
fi

# Set ownership
echo "[1/4] Setting file ownership to ${WP_OWNER}:${WP_GROUP}..."
sudo chown -R ${WP_OWNER}:${WP_GROUP} ${WP_DIR}
echo "✓ Ownership set"

# Set directory permissions
echo "[2/4] Setting directory permissions to 755..."
sudo find ${WP_DIR} -type d -exec chmod 755 {} \;
echo "✓ Directory permissions set"

# Set file permissions
echo "[3/4] Setting file permissions to 644..."
sudo find ${WP_DIR} -type f -exec chmod 644 {} \;
echo "✓ File permissions set"

# Secure wp-config.php
echo "[4/4] Securing wp-config.php..."
if [ -f "${WP_DIR}/wp-config.php" ]; then
    sudo chmod 600 ${WP_DIR}/wp-config.php
    echo "✓ wp-config.php secured (600)"
else
    echo "⚠️  wp-config.php not found - skipping"
fi

# Set special permissions for wp-content directories
echo ""
echo "Setting special permissions for wp-content directories..."

# wp-content/uploads - needs write access for media uploads
if [ -d "${WP_DIR}/wp-content/uploads" ]; then
    sudo chmod 755 ${WP_DIR}/wp-content/uploads
    echo "✓ wp-content/uploads: 755"
else
    sudo mkdir -p ${WP_DIR}/wp-content/uploads
    sudo chown ${WP_OWNER}:${WP_GROUP} ${WP_DIR}/wp-content/uploads
    sudo chmod 755 ${WP_DIR}/wp-content/uploads
    echo "✓ wp-content/uploads created: 755"
fi

# wp-content/plugins - needs write access for plugin installation
if [ -d "${WP_DIR}/wp-content/plugins" ]; then
    sudo chmod 755 ${WP_DIR}/wp-content/plugins
    echo "✓ wp-content/plugins: 755"
fi

# wp-content/themes - needs write access for theme installation
if [ -d "${WP_DIR}/wp-content/themes" ]; then
    sudo chmod 755 ${WP_DIR}/wp-content/themes
    echo "✓ wp-content/themes: 755"
fi

# Verify permissions
echo ""
echo "Verifying permissions..."
echo ""
echo "WordPress directory structure:"
ls -la ${WP_DIR} | head -10

echo ""
echo "wp-config.php permissions:"
ls -l ${WP_DIR}/wp-config.php 2>/dev/null || echo "wp-config.php not found"

echo ""
echo "=========================================="
echo "File Permissions Configuration Complete!"
echo "=========================================="
echo ""
echo "Permission summary:"
echo "  Owner: ${WP_OWNER}:${WP_GROUP}"
echo "  Directories: 755 (rwxr-xr-x)"
echo "  Files: 644 (rw-r--r--)"
echo "  wp-config.php: 600 (rw-------)"
echo "  wp-content/uploads: 755 (rwxr-xr-x)"
echo ""
echo "Security notes:"
echo "  ✓ wp-config.php is readable only by owner"
echo "  ✓ Directories allow Apache to read and execute"
echo "  ✓ Files allow Apache to read"
echo "  ✓ Upload directory allows Apache to write"
echo ""
echo "⚠️  SELinux Considerations:"
echo "  If SELinux is enabled, you may need to set contexts:"
echo "  sudo chcon -R -t httpd_sys_rw_content_t ${WP_DIR}/wp-content/uploads"
echo "  sudo chcon -R -t httpd_sys_rw_content_t ${WP_DIR}/wp-content/plugins"
echo "  sudo chcon -R -t httpd_sys_rw_content_t ${WP_DIR}/wp-content/themes"
echo ""
echo "WordPress is now ready to use!"
echo "Access your site via the Network Load Balancer DNS name to complete setup."
echo ""
