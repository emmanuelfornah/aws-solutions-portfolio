#!/bin/bash

# CodeDeploy lifecycle hook: ApplicationStop
# Stops the web server before deployment
# Runs on BLUE instances during blue/green deployment

set -e

echo "=== ApplicationStop Hook ==="
echo "Stopping Apache web server..."

# Check if Apache is running
if systemctl is-active --quiet httpd; then
    echo "Apache is running, stopping now..."
    systemctl stop httpd
    echo "✓ Apache stopped successfully"
else
    echo "Apache is not running, nothing to stop"
fi

# Optional: Stop any application-specific services
# Example: Stop a Node.js application
# if pgrep -f "node app.js" > /dev/null; then
#     pkill -f "node app.js"
#     echo "✓ Node.js application stopped"
# fi

echo "ApplicationStop hook completed"
exit 0
