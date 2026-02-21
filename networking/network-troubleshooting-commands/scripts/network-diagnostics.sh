#!/bin/bash
# network-diagnostics.sh
# Comprehensive network troubleshooting script for AWS EC2 instances
# Usage: ./network-diagnostics.sh <target-host>

TARGET_HOST=$1

if [ -z "$TARGET_HOST" ]; then
    echo "Usage: $0 <target-host>"
    echo "Example: $0 10.0.1.100"
    exit 1
fi

echo "========================================="
echo "Network Diagnostics for $TARGET_HOST"
echo "========================================="
echo ""

# 1. Interface Configuration
echo "1. Network Interface Configuration:"
echo "-----------------------------------"
if command -v ifconfig &> /dev/null; then
    ifconfig | grep -A 7 "^eth0"
else
    ip addr show eth0
fi
echo ""

# 2. Traceroute
echo "2. Network Path (Traceroute):"
echo "-----------------------------------"
if command -v traceroute &> /dev/null; then
    traceroute -m 10 $TARGET_HOST
else
    echo "traceroute not installed. Install with: sudo yum install traceroute -y"
fi
echo ""

# 3. DNS Lookup
echo "3. DNS Resolution:"
echo "-----------------------------------"
if command -v dig &> /dev/null; then
    dig +short $TARGET_HOST
else
    nslookup $TARGET_HOST
fi
echo ""

# 4. TCP Port 80 Test
echo "4. TCP Port 80 Connectivity:"
echo "-----------------------------------"
timeout 5 bash -c "echo >/dev/tcp/$TARGET_HOST/80" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "Port 80: OPEN"
else
    echo "Port 80: CLOSED or FILTERED"
fi
echo ""

# 5. HTTP Connectivity
echo "5. HTTP Response:"
echo "-----------------------------------"
if command -v curl &> /dev/null; then
    curl -I -s --connect-timeout 5 http://$TARGET_HOST | head -n 5
else
    echo "curl not installed"
fi
echo ""

# 6. Active Connections
echo "6. Active Network Connections:"
echo "-----------------------------------"
if command -v netstat &> /dev/null; then
    netstat -an | grep ESTABLISHED | head -n 10
else
    ss -an | grep ESTAB | head -n 10
fi
echo ""

# 7. Listening Ports
echo "7. Listening Ports:"
echo "-----------------------------------"
if command -v netstat &> /dev/null; then
    sudo netstat -tulnp | grep LISTEN
else
    sudo ss -tulnp | grep LISTEN
fi
echo ""

# 8. Ping Test
echo "8. ICMP Connectivity (Ping):"
echo "-----------------------------------"
ping -c 4 $TARGET_HOST
echo ""

echo "========================================="
echo "Diagnostics Complete"
echo "========================================="
