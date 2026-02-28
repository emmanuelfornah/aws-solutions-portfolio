#!/bin/bash

# CodeDeploy lifecycle hook: ValidateService
# Validates that the application is running correctly
# Runs on GREEN instances during blue/green deployment
# If this script fails, the deployment is rolled back

set -e

echo "=== ValidateService Hook ==="
echo "Validating application deployment..."

# Check if Apache is running
echo "Checking Apache status..."
if ! systemctl is-active --quiet httpd; then
    echo "❌ Error: Apache is not running"
    exit 1
fi
echo "✓ Apache is running"

# Check if Apache is listening on port 80
echo "Checking if Apache is listening on port 80..."
if ! netstat -tuln | grep -q ":80 "; then
    echo "❌ Error: Apache is not listening on port 80"
    exit 1
fi
echo "✓ Apache is listening on port 80"

# Test HTTP response from localhost
echo "Testing HTTP response..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "000")

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ Error: HTTP request failed with code $HTTP_CODE"
    echo "Response body:"
    curl -s http://localhost/ || true
    exit 1
fi
echo "✓ HTTP request successful (200 OK)"

# Check if application files exist
echo "Checking application files..."
if [ ! -f /var/www/html/index.html ] && [ ! -f /var/www/html/index.php ]; then
    echo "❌ Error: No index file found in /var/www/html"
    ls -la /var/www/html/
    exit 1
fi
echo "✓ Application files present"

# Optional: Check application-specific endpoints
# Example: Test API health endpoint
# echo "Testing API health endpoint..."
# API_RESPONSE=$(curl -s http://localhost/api/health || echo "error")
# if [ "$API_RESPONSE" != "ok" ]; then
#     echo "❌ Error: API health check failed"
#     exit 1
# fi
# echo "✓ API health check passed"

# Optional: Check database connectivity
# Example: Test database connection
# echo "Testing database connection..."
# if ! mysql -h database.example.com -u appuser -ppassword -e "SELECT 1" > /dev/null 2>&1; then
#     echo "❌ Error: Database connection failed"
#     exit 1
# fi
# echo "✓ Database connection successful"

# Optional: Check application-specific functionality
# Example: Test critical application features
# echo "Testing application functionality..."
# RESPONSE=$(curl -s http://localhost/api/test)
# if [ -z "$RESPONSE" ]; then
#     echo "❌ Error: Application test failed"
#     exit 1
# fi
# echo "✓ Application functionality verified"

# Optional: Check for required environment variables
# echo "Checking environment variables..."
# if [ -z "$APP_ENV" ]; then
#     echo "⚠️  Warning: APP_ENV not set"
# fi

# Optional: Verify file permissions
echo "Verifying file permissions..."
if [ ! -r /var/www/html/index.html ] && [ ! -r /var/www/html/index.php ]; then
    echo "❌ Error: Application files are not readable"
    exit 1
fi
echo "✓ File permissions correct"

# Optional: Check disk space
echo "Checking disk space..."
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    echo "⚠️  Warning: Disk usage is at ${DISK_USAGE}%"
fi
echo "✓ Disk space sufficient"

# Optional: Check memory usage
echo "Checking memory usage..."
MEMORY_USAGE=$(free | awk 'NR==2 {printf "%.0f", $3/$2 * 100}')
if [ "$MEMORY_USAGE" -gt 90 ]; then
    echo "⚠️  Warning: Memory usage is at ${MEMORY_USAGE}%"
fi
echo "✓ Memory usage acceptable"

echo ""
echo "=== Validation Summary ==="
echo "✓ Apache is running and responding"
echo "✓ Application files are present and accessible"
echo "✓ All validation checks passed"
echo ""
echo "ValidateService hook completed successfully"
echo "Deployment is ready for traffic rerouting"
exit 0
