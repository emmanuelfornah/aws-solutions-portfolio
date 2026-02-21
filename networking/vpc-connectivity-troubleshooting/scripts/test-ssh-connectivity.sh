#!/bin/bash

# Test SSH Connectivity Script
# Usage: ./test-ssh-connectivity.sh <TARGET_PRIVATE_IP>
#
# This script tests SSH connectivity to a target instance from the current instance.
# Use this from Bastion Host or Public Server to test access to App Server.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if target IP is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Target IP address required${NC}"
    echo "Usage: $0 <TARGET_PRIVATE_IP>"
    echo "Example: $0 10.0.2.20"
    exit 1
fi

TARGET_IP=$1

echo "=========================================="
echo "SSH Connectivity Test"
echo "=========================================="
echo "Target: $TARGET_IP"
echo "Source: $(hostname -I | awk '{print $1}')"
echo "Time: $(date)"
echo "=========================================="
echo ""

# Test 1: Ping test (ICMP)
echo -e "${YELLOW}Test 1: ICMP Ping Test${NC}"
if ping -c 3 -W 2 "$TARGET_IP" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ ICMP ping successful${NC}"
else
    echo -e "${RED}✗ ICMP ping failed (may be blocked by security group)${NC}"
fi
echo ""

# Test 2: TCP port 22 connectivity
echo -e "${YELLOW}Test 2: TCP Port 22 Connectivity${NC}"
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$TARGET_IP/22" 2>/dev/null; then
    echo -e "${GREEN}✓ Port 22 is reachable${NC}"
else
    echo -e "${RED}✗ Port 22 is not reachable${NC}"
    echo "  Possible causes:"
    echo "  - Security group blocking SSH (port 22)"
    echo "  - Network ACL blocking traffic"
    echo "  - Instance not running"
    echo "  - SSH service not running on target"
    exit 1
fi
echo ""

# Test 3: SSH connection attempt
echo -e "${YELLOW}Test 3: SSH Connection Attempt${NC}"
echo "Attempting SSH connection (will timeout after 10 seconds)..."
echo ""

# Attempt SSH with timeout
if timeout 10 ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ec2-user@"$TARGET_IP" "echo 'SSH connection successful'" 2>/dev/null; then
    echo -e "${GREEN}✓ SSH connection successful${NC}"
    echo ""
    echo "=========================================="
    echo -e "${GREEN}RESULT: All tests passed${NC}"
    echo "=========================================="
else
    echo -e "${RED}✗ SSH connection failed${NC}"
    echo ""
    echo "Port 22 is reachable but SSH connection failed."
    echo "Possible causes:"
    echo "  - SSH key authentication issue"
    echo "  - Wrong username (try 'ec2-user', 'ubuntu', or 'admin')"
    echo "  - SSH service not running on target"
    echo ""
    echo "To connect manually, run:"
    echo "  ssh ec2-user@$TARGET_IP"
    echo ""
    echo "=========================================="
    echo -e "${YELLOW}RESULT: Partial success (port open, auth failed)${NC}"
    echo "=========================================="
    exit 1
fi

# Test 4: Get instance information
echo ""
echo -e "${YELLOW}Test 4: Remote Instance Information${NC}"
echo "Hostname: $(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ec2-user@"$TARGET_IP" "hostname" 2>/dev/null || echo 'Unable to retrieve')"
echo "Uptime: $(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ec2-user@"$TARGET_IP" "uptime" 2>/dev/null || echo 'Unable to retrieve')"
echo ""

echo "=========================================="
echo "Test completed successfully"
echo "=========================================="
