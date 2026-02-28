#!/bin/bash
# configure-database.sh
# Configures MariaDB and creates WordPress database with user

set -e  # Exit on any error

echo "=========================================="
echo "MariaDB Configuration for WordPress"
echo "=========================================="
echo ""

# Start and enable MariaDB service
echo "[1/4] Starting MariaDB service..."
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Verify MariaDB is running
if sudo systemctl is-active --quiet mariadb; then
    echo "✓ MariaDB is running"
else
    echo "✗ MariaDB failed to start"
    exit 1
fi

echo ""
echo "[2/4] Securing MariaDB installation..."
echo "Note: This script sets a root password and removes test databases"
echo ""

# Secure MariaDB installation (automated)
# In production, use mysql_secure_installation interactively
sudo mysql -e "UPDATE mysql.user SET Password=PASSWORD('your_root_password_here') WHERE User='root';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
sudo mysql -e "DROP DATABASE IF EXISTS test;"
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "✓ MariaDB secured"
echo ""

# Create WordPress database
echo "[3/4] Creating WordPress database..."
DB_NAME="wordpress_db"
DB_USER="wordpress_user"
DB_PASSWORD="wordpress_password_change_me"

sudo mysql -u root -pyour_root_password_here <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "✓ Database created: ${DB_NAME}"
echo "✓ User created: ${DB_USER}"
echo ""

# Verify database creation
echo "[4/4] Verifying database setup..."
if sudo mysql -u root -pyour_root_password_here -e "USE ${DB_NAME};" 2>/dev/null; then
    echo "✓ Database verification successful"
else
    echo "✗ Database verification failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "Database Configuration Complete!"
echo "=========================================="
echo ""
echo "Database details:"
echo "  Database Name: ${DB_NAME}"
echo "  Database User: ${DB_USER}"
echo "  Database Password: ${DB_PASSWORD}"
echo "  Database Host: localhost"
echo ""
echo "⚠️  SECURITY WARNING:"
echo "  Change the default passwords in this script before production use!"
echo "  Store credentials securely (e.g., AWS Secrets Manager)"
echo ""
echo "Next steps:"
echo "  Run configure-wordpress.sh to install WordPress"
echo ""
