#!/bin/bash
# configure-ssl.sh
# Generates self-signed SSL certificate and configures Apache for HTTPS

set -e  # Exit on any error

echo "=========================================="
echo "SSL/TLS Configuration for Apache"
echo "=========================================="
echo ""

# Configuration variables
CERT_DIR="/etc/pki/tls/certs"
KEY_DIR="/etc/pki/tls/private"
CERT_FILE="${CERT_DIR}/wordpress.crt"
KEY_FILE="${KEY_DIR}/wordpress.key"
DAYS_VALID=365

# Generate self-signed SSL certificate
echo "[1/3] Generating self-signed SSL certificate..."
echo "Note: This certificate is for testing only. Use a CA-signed certificate for production."
echo ""

sudo openssl req -x509 -nodes -days ${DAYS_VALID} -newkey rsa:2048 \
    -keyout ${KEY_FILE} \
    -out ${CERT_FILE} \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=wordpress.local"

echo "✓ SSL certificate generated"
echo "  Certificate: ${CERT_FILE}"
echo "  Private Key: ${KEY_FILE}"
echo "  Valid for: ${DAYS_VALID} days"
echo ""

# Set proper permissions on private key
sudo chmod 600 ${KEY_FILE}
sudo chmod 644 ${CERT_FILE}
echo "✓ Certificate permissions set"

# Configure Apache SSL
echo "[2/3] Configuring Apache SSL settings..."

# Backup original SSL configuration
if [ -f /etc/httpd/conf.d/ssl.conf ]; then
    sudo cp /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.backup
    echo "✓ Original SSL config backed up"
fi

# Update SSL certificate paths in ssl.conf
sudo sed -i "s|^SSLCertificateFile.*|SSLCertificateFile ${CERT_FILE}|" /etc/httpd/conf.d/ssl.conf
sudo sed -i "s|^SSLCertificateKeyFile.*|SSLCertificateKeyFile ${KEY_FILE}|" /etc/httpd/conf.d/ssl.conf

# Update DocumentRoot in SSL virtual host
sudo sed -i 's|^DocumentRoot.*|DocumentRoot "/var/www/html"|' /etc/httpd/conf.d/ssl.conf

echo "✓ Apache SSL configuration updated"

# Add security headers to SSL configuration
echo "[3/3] Adding security headers..."

sudo tee -a /etc/httpd/conf.d/ssl.conf > /dev/null <<'EOF'

# Security Headers
<IfModule mod_headers.c>
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
</IfModule>

# SSL Protocol and Cipher Configuration
SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite HIGH:!aNULL:!MD5:!3DES
SSLHonorCipherOrder on
EOF

echo "✓ Security headers added"

# Test Apache configuration
echo ""
echo "Testing Apache configuration..."
if sudo apachectl configtest 2>&1 | grep -q "Syntax OK"; then
    echo "✓ Apache configuration is valid"
else
    echo "✗ Apache configuration has errors"
    sudo apachectl configtest
    exit 1
fi

# Restart Apache to apply changes
echo ""
echo "Restarting Apache to apply SSL configuration..."
sudo systemctl restart httpd

if sudo systemctl is-active --quiet httpd; then
    echo "✓ Apache restarted successfully"
else
    echo "✗ Apache failed to restart"
    exit 1
fi

echo ""
echo "=========================================="
echo "SSL/TLS Configuration Complete!"
echo "=========================================="
echo ""
echo "SSL certificate details:"
echo "  Certificate: ${CERT_FILE}"
echo "  Private Key: ${KEY_FILE}"
echo "  Valid for: ${DAYS_VALID} days"
echo "  Type: Self-signed (testing only)"
echo ""
echo "⚠️  IMPORTANT NOTES:"
echo "  1. This is a self-signed certificate - browsers will show a warning"
echo "  2. For production, obtain a certificate from a trusted CA"
echo "  3. Consider using AWS Certificate Manager (ACM) with your load balancer"
echo "  4. The certificate is valid for 'wordpress.local' - update CN for your domain"
echo ""
echo "Your site is now accessible via HTTPS!"
echo "Next step: Run configure-permissions.sh to set file permissions"
echo ""
