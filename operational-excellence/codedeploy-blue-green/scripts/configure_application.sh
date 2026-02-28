#!/bin/bash

# CodeDeploy lifecycle hook: AfterInstall
# Configures the application after files are copied
# Runs on GREEN instances during blue/green deployment

set -e

echo "=== AfterInstall Hook ==="
echo "Configuring application..."

# Set proper file permissions
echo "Setting file permissions..."
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
find /var/www/html -type f -exec chmod 644 {} \;
echo "✓ Permissions set"

# Configure Apache (example: enable mod_rewrite)
echo "Configuring Apache..."

# Enable mod_rewrite if needed
if ! grep -q "LoadModule rewrite_module" /etc/httpd/conf/httpd.conf; then
    echo "LoadModule rewrite_module modules/mod_rewrite.so" >> /etc/httpd/conf/httpd.conf
    echo "✓ mod_rewrite enabled"
fi

# Update Apache configuration for the application
cat > /etc/httpd/conf.d/application.conf << 'EOF'
<Directory "/var/www/html">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

# Enable server status for health checks
<Location "/server-status">
    SetHandler server-status
    Require local
</Location>
EOF

echo "✓ Apache configuration updated"

# Optional: Configure environment variables
# Example: Set application environment
# echo "export APP_ENV=production" >> /etc/environment
# echo "export DB_HOST=database.example.com" >> /etc/environment

# Optional: Configure application-specific settings
# Example: Copy configuration file
# if [ -f /var/www/html/config.example.php ]; then
#     cp /var/www/html/config.example.php /var/www/html/config.php
#     echo "✓ Configuration file created"
# fi

# Optional: Run database migrations
# Example: Run Laravel migrations
# if [ -f /var/www/html/artisan ]; then
#     cd /var/www/html
#     php artisan migrate --force
#     echo "✓ Database migrations completed"
# fi

# Optional: Clear application cache
# Example: Clear Laravel cache
# if [ -f /var/www/html/artisan ]; then
#     cd /var/www/html
#     php artisan cache:clear
#     php artisan config:cache
#     echo "✓ Application cache cleared"
# fi

echo "AfterInstall hook completed"
exit 0
