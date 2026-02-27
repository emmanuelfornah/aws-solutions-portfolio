#!/bin/bash
# configure-wordpress.sh
# Downloads WordPress and configures wp-config.php with database credentials

set -e  # Exit on any error

echo "=========================================="
echo "WordPress Installation and Configuration"
echo "=========================================="
echo ""

# Configuration variables
WP_DIR="/var/www/html"
DB_NAME="wordpress_db"
DB_USER="wordpress_user"
DB_PASSWORD="wordpress_password_change_me"
DB_HOST="localhost"

# Download WordPress
echo "[1/5] Downloading latest WordPress..."
cd /tmp
wget -q https://wordpress.org/latest.tar.gz
echo "✓ WordPress downloaded"

# Extract WordPress
echo "[2/5] Extracting WordPress files..."
tar -xzf latest.tar.gz
echo "✓ WordPress extracted"

# Move WordPress files to web root
echo "[3/5] Moving WordPress files to ${WP_DIR}..."
sudo rm -rf ${WP_DIR}/*
sudo mv wordpress/* ${WP_DIR}/
sudo rm -rf wordpress latest.tar.gz
echo "✓ WordPress files moved"

# Create wp-config.php from sample
echo "[4/5] Creating wp-config.php..."
cd ${WP_DIR}
sudo cp wp-config-sample.php wp-config.php

# Configure database settings
sudo sed -i "s/database_name_here/${DB_NAME}/" wp-config.php
sudo sed -i "s/username_here/${DB_USER}/" wp-config.php
sudo sed -i "s/password_here/${DB_PASSWORD}/" wp-config.php
sudo sed -i "s/localhost/${DB_HOST}/" wp-config.php

echo "✓ Database settings configured"

# Generate and set WordPress security keys
echo "[5/5] Generating WordPress security keys..."
SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

# Create a temporary file with the new salts
sudo tee /tmp/wp-salts.txt > /dev/null <<EOF
${SALT}
EOF

# Replace the salt section in wp-config.php
sudo sed -i "/AUTH_KEY/,/NONCE_SALT/d" wp-config.php
sudo sed -i "/put your unique phrase here/r /tmp/wp-salts.txt" wp-config.php
sudo rm /tmp/wp-salts.txt

echo "✓ Security keys generated"

# Add WordPress debugging configuration (disabled by default)
sudo tee -a wp-config.php > /dev/null <<'EOF'

/* WordPress Debugging */
define('WP_DEBUG', false);
define('WP_DEBUG_LOG', false);
define('WP_DEBUG_DISPLAY', false);

/* WordPress Memory Limits */
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');

/* WordPress Auto-Updates */
define('WP_AUTO_UPDATE_CORE', 'minor');
EOF

echo "✓ Additional WordPress settings configured"

echo ""
echo "=========================================="
echo "WordPress Installation Complete!"
echo "=========================================="
echo ""
echo "WordPress configuration:"
echo "  Installation Directory: ${WP_DIR}"
echo "  Database Name: ${DB_NAME}"
echo "  Database User: ${DB_USER}"
echo "  Database Host: ${DB_HOST}"
echo ""
echo "⚠️  SECURITY WARNING:"
echo "  The database password is stored in wp-config.php"
echo "  Ensure proper file permissions are set (run configure-permissions.sh)"
echo ""
echo "Next steps:"
echo "  1. Run configure-ssl.sh to enable HTTPS"
echo "  2. Run configure-permissions.sh to set file permissions"
echo "  3. Access your site to complete WordPress setup wizard"
echo ""
