#!/bin/bash
# WordPress on EC2 - Database Configuration Script
# This script creates the WordPress database and user in MariaDB

set -e  # Exit on error

echo "=== WordPress Database Configuration ==="

# Database configuration variables
DB_NAME="wordpress"
DB_USER="wordpress_user"
DB_PASSWORD="your_secure_password_here"  # CHANGE THIS!

echo "Creating WordPress database and user..."
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo ""
echo "⚠️  IMPORTANT: Update DB_PASSWORD in this script before running!"
echo ""

# Create database and user
sudo mysql -u root <<EOF
-- Create WordPress database
CREATE DATABASE IF NOT EXISTS ${DB_NAME};

-- Create WordPress user with password
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';

-- Grant all privileges on WordPress database to user
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';

-- Apply privilege changes
FLUSH PRIVILEGES;

-- Show databases
SHOW DATABASES;

-- Show users
SELECT User, Host FROM mysql.user WHERE User = '${DB_USER}';
EOF

echo ""
echo "=== Database Configuration Complete ==="
echo "Database '${DB_NAME}' created"
echo "User '${DB_USER}' created with full privileges"
echo ""
echo "Next step: Run configure-wordpress.sh"
echo ""
echo "📝 Note: Save these credentials for wp-config.php:"
echo "   DB_NAME: ${DB_NAME}"
echo "   DB_USER: ${DB_USER}"
echo "   DB_PASSWORD: ${DB_PASSWORD}"
