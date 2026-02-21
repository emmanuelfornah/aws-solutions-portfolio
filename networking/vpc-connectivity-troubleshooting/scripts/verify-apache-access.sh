#!/bin/bash

# Verify Apache Access Script
# Usage: ./verify-apache-access.sh <APACHE_SERVER_PUBLIC_IP>
#
# This script tests HTTP connectivity to an Apache web server.
# Use this to verify the Apache Server challenge fix.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if target IP is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Apache Server public IP address required${NC}"
    echo "Usage: $0 <APACHE_SERVER_PUBLIC_IP>"
    echo "Example: $0 54.123.45.67"
    exit 1
fi

TARGET_IP=$1

echo "=========================================="
echo "Apache HTTP Server Connectivity Test"
echo "=========================================="
echo "Target: $TARGET_IP"
echo "Time: $(date)"
echo "=========================================="
echo ""

# Test 1: TCP port 80 connectivity
echo -e "${YELLOW}Test 1: TCP Port 80 Connectivity${NC}"
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$TARGET_IP/80" 2>/dev/null; then
    echo -e "${GREEN}✓ Port 80 is reachable${NC}"
else
    echo -e "${RED}✗ Port 80 is not reachable${NC}"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check security group inbound rules for HTTP (port 80)"
    echo "2. Verify instance is in a public subnet"
    echo "3. Verify route table has route to Internet Gateway"
    echo "4. Check Network ACL rules"
    echo ""
    echo "To add HTTP rule to security group:"
    echo "  aws ec2 authorize-security-group-ingress \\"
    echo "    --group-id <SG_ID> \\"
    echo "    --protocol tcp \\"
    echo "    --port 80 \\"
    echo "    --cidr 0.0.0.0/0"
    echo ""
    exit 1
fi
echo ""

# Test 2: HTTP GET request
echo -e "${YELLOW}Test 2: HTTP GET Request${NC}"
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://$TARGET_IP" 2>/dev/null || echo "000")

if [ "$HTTP_RESPONSE" == "200" ]; then
    echo -e "${GREEN}✓ HTTP request successful (Status: 200 OK)${NC}"
elif [ "$HTTP_RESPONSE" == "000" ]; then
    echo -e "${RED}✗ HTTP request failed (Connection error)${NC}"
    exit 1
else
    echo -e "${YELLOW}⚠ HTTP request returned status: $HTTP_RESPONSE${NC}"
fi
echo ""

# Test 3: Retrieve and display content
echo -e "${YELLOW}Test 3: Retrieve Apache Test Page${NC}"
CONTENT=$(curl -s --connect-timeout 5 "http://$TARGET_IP" 2>/dev/null || echo "")

if [ -z "$CONTENT" ]; then
    echo -e "${RED}✗ Unable to retrieve content${NC}"
    exit 1
fi

# Check if it's an Apache test page
if echo "$CONTENT" | grep -qi "apache"; then
    echo -e "${GREEN}✓ Apache test page detected${NC}"
    echo ""
    echo "Page title:"
    echo "$CONTENT" | grep -oP '(?<=<title>).*?(?=</title>)' || echo "  (Title not found)"
elif echo "$CONTENT" | grep -qi "html"; then
    echo -e "${GREEN}✓ HTML content retrieved${NC}"
    echo ""
    echo "Page title:"
    echo "$CONTENT" | grep -oP '(?<=<title>).*?(?=</title>)' || echo "  (Title not found)"
else
    echo -e "${YELLOW}⚠ Content retrieved but doesn't appear to be HTML${NC}"
fi
echo ""

# Test 4: Check response headers
echo -e "${YELLOW}Test 4: HTTP Response Headers${NC}"
HEADERS=$(curl -s -I --connect-timeout 5 "http://$TARGET_IP" 2>/dev/null || echo "")

if [ -n "$HEADERS" ]; then
    echo "$HEADERS" | grep -i "server:" || echo "Server header not found"
    echo "$HEADERS" | grep -i "content-type:" || echo "Content-Type header not found"
else
    echo -e "${RED}✗ Unable to retrieve headers${NC}"
fi
echo ""

# Test 5: Check if Apache service is running (if we can SSH)
echo -e "${YELLOW}Test 5: Apache Service Status (Optional)${NC}"
echo "To check Apache service status, SSH to the instance and run:"
echo "  sudo systemctl status httpd    # Amazon Linux/RHEL"
echo "  sudo systemctl status apache2  # Ubuntu/Debian"
echo ""

# Summary
echo "=========================================="
echo -e "${GREEN}RESULT: Apache Server is accessible${NC}"
echo "=========================================="
echo ""
echo "Access the server in your browser:"
echo "  http://$TARGET_IP"
echo ""
echo "Additional tests you can perform:"
echo "1. Test HTTPS (port 443) if SSL is configured"
echo "2. Test specific application endpoints"
echo "3. Load test with tools like Apache Bench (ab)"
echo "4. Check access logs on the server"
echo ""

# Optional: Display a snippet of the page
echo -e "${YELLOW}Page Content Preview (first 500 characters):${NC}"
echo "----------------------------------------"
echo "$CONTENT" | head -c 500
echo ""
echo "----------------------------------------"
echo ""

echo "Test completed successfully!"
