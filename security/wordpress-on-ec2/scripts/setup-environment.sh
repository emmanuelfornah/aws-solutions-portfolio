#!/bin/bash
# setup-environment.sh
# Installs LAMP stack components on Amazon Linux 2023
# Components: Apache HTTP Server, MariaDB, PHP 8.2, mod_ssl

set -e  # Exit on any error

echo "=========================================="
echo "WordPress LAMP Stack Environment Setup"
echo "=========================================="
echo ""

# Update system packages
echo "[1/5] Updating system packages..."
sudo dnf update -y

# Install Apache HTTP Server
echo "[2/5] Installing Apache HTTP Server..."
sudo dnf install -y httpd

# Install MariaDB server and client
echo "[3/5] Installing MariaDB server and client..."
sudo dnf install -y mariadb105-server mariadb105

# Install PHP 8.2 and required extensions
echo "[4/5] Installing PHP 8.2 and extensions..."
sudo dnf install -y \
    php8.2 \
    php8.2-mysqlnd \
    php8.2-pdo \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-opcache

# Install mod_ssl for Apache
echo "[5/5] Installing mod_ssl for HTTPS support..."
sudo dnf install -y mod_ssl

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Installed components:"
echo "  - Apache HTTP Server (httpd)"
echo "  - MariaDB 10.5 Server"
echo "  - PHP 8.2 with extensions"
echo "  - mod_ssl for Apache"
echo ""
echo "Next steps:"
echo "  1. Run configure-database.sh to set up MariaDB"
echo "  2. Run configure-wordpress.sh to install WordPress"
echo "  3. Run configure-ssl.sh to enable HTTPS"
echo "  4. Run configure-permissions.sh to set file permissions"
echo ""

# Start and enable Apache
echo "Starting Apache HTTP Server..."
sudo systemctl start httpd
sudo systemctl enable httpd

# Verify Apache is running
if sudo systemctl is-active --quiet httpd; then
    echo "✓ Apache is running"
else
    echo "✗ Apache failed to start"
    exit 1
fi

echo ""
echo "Environment setup complete!"
