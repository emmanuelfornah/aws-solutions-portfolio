#!/bin/bash
# port-scanner.sh
# Quick port scanner for common service ports
# Usage: ./port-scanner.sh <target-host>

TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <target-host>"
    echo "Example: $0 10.0.1.100"
    exit 1
fi

# Common ports to scan
# 22: SSH, 80: HTTP, 443: HTTPS, 3306: MySQL, 5432: PostgreSQL
# 6379: Redis, 8080: HTTP Alt, 3389: RDP, 27017: MongoDB
PORTS=(22 80 443 3306 5432 6379 8080 3389 27017)

echo "========================================="
echo "Port Scanner for $TARGET"
echo "========================================="
echo ""
echo "Scanning common service ports..."
echo ""

for PORT in "${PORTS[@]}"; do
    # Use timeout to prevent hanging on filtered ports
    timeout 2 bash -c "echo >/dev/tcp/$TARGET/$PORT" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "Port $PORT: OPEN"
        
        # Identify common services
        case $PORT in
            22) echo "  └─ Service: SSH" ;;
            80) echo "  └─ Service: HTTP" ;;
            443) echo "  └─ Service: HTTPS" ;;
            3306) echo "  └─ Service: MySQL" ;;
            5432) echo "  └─ Service: PostgreSQL" ;;
            6379) echo "  └─ Service: Redis" ;;
            8080) echo "  └─ Service: HTTP (Alternative)" ;;
            3389) echo "  └─ Service: RDP (Remote Desktop)" ;;
            27017) echo "  └─ Service: MongoDB" ;;
        esac
    else
        echo "Port $PORT: CLOSED or FILTERED"
    fi
done

echo ""
echo "========================================="
echo "Scan Complete"
echo "========================================="
echo ""
echo "Note: CLOSED means port is not accepting connections"
echo "      FILTERED means firewall may be blocking the port"
