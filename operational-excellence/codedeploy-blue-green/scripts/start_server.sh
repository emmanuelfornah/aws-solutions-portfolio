#!/bin/bash

# CodeDeploy lifecycle hook: ApplicationStart
# Starts the web server after deployment
# Runs on GREEN instances during blue/green deployment

set -e

echo "=== ApplicationStart Hook ==="
echo "Starting Apache web server..."

# Enable Apache to start on boot
systemctl enable httpd
echo "✓ Apache enabled on boot"

# Start Apache
systemctl start httpd
echo "✓ Apache started"

# Wait for Apache to fully start
sleep 3

# Verify Apache is running
if systemctl is-active --quiet httpd; then
    echo "✓ Apache is running successfully"
else
    echo "❌ Error: Apache failed to start"
    systemctl status httpd
    exit 1
fi

# Optional: Start application-specific services
# Example: Start a Node.js application
# if [ -f /var/www/html/app.js ]; then
#     cd /var/www/html
#     nohup node app.js > /var/log/app.log 2>&1 &
#     echo "✓ Node.js application started"
# fi

# Optional: Start background workers
# Example: Start Laravel queue workers
# if [ -f /var/www/html/artisan ]; then
#     cd /var/www/html
#     nohup php artisan queue:work --daemon > /var/log/queue.log 2>&1 &
#     echo "✓ Queue workers started"
# fi

echo "ApplicationStart hook completed"
exit 0
