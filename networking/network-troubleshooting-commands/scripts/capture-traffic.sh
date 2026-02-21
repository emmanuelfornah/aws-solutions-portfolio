#!/bin/bash
# capture-traffic.sh
# Network packet capture script using tcpdump
# Usage: ./capture-traffic.sh [duration] [interface] [filter]

DURATION=${1:-60}
INTERFACE=${2:-eth0}
FILTER=${3:-""}
OUTPUT="capture-$(date +%Y%m%d-%H%M%S).pcap"

# Check if tcpdump is installed
if ! command -v tcpdump &> /dev/null; then
    echo "Error: tcpdump not found"
    echo "Install with: sudo yum install tcpdump -y"
    exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root or with sudo"
    echo "Usage: sudo $0 [duration] [interface] [filter]"
    exit 1
fi

echo "========================================="
echo "Network Packet Capture"
echo "========================================="
echo ""
echo "Configuration:"
echo "  Interface: $INTERFACE"
echo "  Duration: $DURATION seconds"
echo "  Output: $OUTPUT"
if [ -n "$FILTER" ]; then
    echo "  Filter: $FILTER"
fi
echo ""

# Verify interface exists
if ! ip link show $INTERFACE &> /dev/null; then
    echo "Error: Interface $INTERFACE not found"
    echo ""
    echo "Available interfaces:"
    ip link show | grep "^[0-9]" | awk '{print $2}' | sed 's/://'
    exit 1
fi

echo "Starting packet capture..."
echo "Press Ctrl+C to stop early"
echo ""

# Capture packets
if [ -n "$FILTER" ]; then
    timeout $DURATION tcpdump -i $INTERFACE -w $OUTPUT $FILTER
else
    timeout $DURATION tcpdump -i $INTERFACE -w $OUTPUT
fi

CAPTURE_EXIT=$?

echo ""
echo "========================================="
echo "Capture Complete"
echo "========================================="
echo ""

# Check if capture was successful
if [ -f "$OUTPUT" ]; then
    FILE_SIZE=$(ls -lh "$OUTPUT" | awk '{print $5}')
    PACKET_COUNT=$(tcpdump -r "$OUTPUT" 2>/dev/null | wc -l)
    
    echo "Capture Statistics:"
    echo "  File: $OUTPUT"
    echo "  Size: $FILE_SIZE"
    echo "  Packets: $PACKET_COUNT"
    echo ""
    echo "Analysis Commands:"
    echo "  View capture: sudo tcpdump -r $OUTPUT"
    echo "  View with details: sudo tcpdump -r $OUTPUT -v"
    echo "  View packet contents: sudo tcpdump -r $OUTPUT -X"
    echo "  Filter HTTP: sudo tcpdump -r $OUTPUT port 80"
    echo ""
    echo "Download and analyze in Wireshark for detailed inspection"
else
    echo "Error: Capture file not created"
    exit 1
fi
