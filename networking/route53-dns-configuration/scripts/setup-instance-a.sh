#!/bin/bash
# Setup script for Instance A - Web Server Configuration
# This script installs and configures Apache httpd on Amazon Linux

set -e  # Exit on error

echo "=========================================="
echo "Instance A Setup - Web Server"
echo "=========================================="

# Update system packages
echo "[1/5] Updating system packages..."
sudo yum update -y

# Install Apache httpd
echo "[2/5] Installing Apache httpd..."
sudo yum install httpd -y

# Create a simple test page
echo "[3/5] Creating test web page..."
cat <<EOF | sudo tee /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Instance A - Route 53 DNS Lab</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f0f0f0;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #232f3e;
        }
        .info {
            background-color: #e7f3ff;
            padding: 15px;
            border-left: 4px solid #0073bb;
            margin: 20px 0;
        }
        .success {
            color: #28a745;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Hello from Instance A!</h1>
        <p class="success">✓ DNS Resolution Successful</p>
        <div class="info">
            <h3>Lab Information</h3>
            <p><strong>Lab:</strong> Configuring DNS on Amazon EC2</p>
            <p><strong>Service:</strong> Amazon Route 53 Private Hosted Zone</p>
            <p><strong>Domain:</strong> www.anycompany.corp</p>
            <p><strong>Instance:</strong> Instance A (Web Server)</p>
        </div>
        <p>If you can see this page, your Route 53 DNS configuration is working correctly!</p>
        <hr>
        <p><small>AWS Cloud Fundamentals - Networking Lab</small></p>
    </div>
</body>
</html>
EOF

# Start httpd service
echo "[4/5] Starting Apache httpd service..."
sudo systemctl start httpd

# Enable httpd to start on boot
echo "[5/5] Enabling httpd to start on boot..."
sudo systemctl enable httpd

# Verify httpd is running
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
sudo systemctl status httpd --no-pager
echo ""
echo "Testing local web server..."
curl -s localhost | grep -o "<title>.*</title>"
echo ""
echo "✓ Instance A is ready!"
echo "✓ Web server is running on port 80"
echo ""
echo "Next steps:"
echo "1. Allocate and associate an Elastic IP"
echo "2. Create Route 53 private hosted zone"
echo "3. Create A record pointing to this instance"
echo "4. Test DNS resolution from Instance B"
echo ""
