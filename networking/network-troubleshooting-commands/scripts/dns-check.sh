#!/bin/bash
# dns-check.sh
# Comprehensive DNS troubleshooting script
# Usage: ./dns-check.sh <domain>

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 google.com"
    exit 1
fi

echo "========================================="
echo "DNS Troubleshooting for $DOMAIN"
echo "========================================="
echo ""

# Check if dig is available
if ! command -v dig &> /dev/null; then
    echo "Error: dig command not found"
    echo "Install with: sudo yum install bind-utils -y"
    exit 1
fi

# 1. A Record (IPv4)
echo "1. A Record (IPv4 Address):"
echo "-----------------------------------"
dig +short $DOMAIN A
if [ $? -ne 0 ]; then
    echo "Failed to resolve A record"
fi
echo ""

# 2. AAAA Record (IPv6)
echo "2. AAAA Record (IPv6 Address):"
echo "-----------------------------------"
AAAA_RESULT=$(dig +short $DOMAIN AAAA)
if [ -z "$AAAA_RESULT" ]; then
    echo "No IPv6 address found"
else
    echo "$AAAA_RESULT"
fi
echo ""

# 3. MX Records (Mail Exchange)
echo "3. MX Records (Mail Servers):"
echo "-----------------------------------"
MX_RESULT=$(dig +short $DOMAIN MX)
if [ -z "$MX_RESULT" ]; then
    echo "No MX records found"
else
    echo "$MX_RESULT"
fi
echo ""

# 4. NS Records (Name Servers)
echo "4. NS Records (Authoritative Name Servers):"
echo "-----------------------------------"
dig +short $DOMAIN NS
echo ""

# 5. TXT Records
echo "5. TXT Records:"
echo "-----------------------------------"
TXT_RESULT=$(dig +short $DOMAIN TXT)
if [ -z "$TXT_RESULT" ]; then
    echo "No TXT records found"
else
    echo "$TXT_RESULT"
fi
echo ""

# 6. SOA Record (Start of Authority)
echo "6. SOA Record:"
echo "-----------------------------------"
dig +short $DOMAIN SOA
echo ""

# 7. DNS Resolution Time
echo "7. DNS Query Performance:"
echo "-----------------------------------"
dig $DOMAIN | grep "Query time"
echo ""

# 8. Nameserver Used
echo "8. DNS Server Used:"
echo "-----------------------------------"
dig $DOMAIN | grep "SERVER"
echo ""

# 9. Local DNS Configuration
echo "9. Local DNS Configuration:"
echo "-----------------------------------"
cat /etc/resolv.conf
echo ""

# 10. Test with Different Nameservers
echo "10. Testing with Public DNS Servers:"
echo "-----------------------------------"
echo "Google DNS (8.8.8.8):"
dig @8.8.8.8 +short $DOMAIN A
echo ""
echo "Cloudflare DNS (1.1.1.1):"
dig @1.1.1.1 +short $DOMAIN A
echo ""

echo "========================================="
echo "DNS Check Complete"
echo "========================================="
