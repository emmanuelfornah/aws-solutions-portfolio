#!/bin/bash

# Update Security Group Script
# Usage: ./update-security-group.sh <SG_NAME_OR_ID> <PROTOCOL> <SOURCE>
#
# This script updates a security group's inbound rules using AWS CLI.
# Useful for automating security group modifications during the lab.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    echo "Install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

# Check arguments
if [ $# -lt 3 ]; then
    echo -e "${RED}Error: Insufficient arguments${NC}"
    echo "Usage: $0 <SG_NAME_OR_ID> <PROTOCOL> <SOURCE>"
    echo ""
    echo "Examples:"
    echo "  $0 AppServerSG ssh 10.0.1.10/32"
    echo "  $0 sg-0123456789abcdef0 http 0.0.0.0/0"
    echo "  $0 ApacheServerSG https sg-0123456789abcdef0"
    echo ""
    echo "Supported protocols: ssh, http, https, mysql, postgresql, rdp, custom"
    exit 1
fi

SG_INPUT=$1
PROTOCOL=$2
SOURCE=$3

echo "=========================================="
echo "Security Group Update Script"
echo "=========================================="
echo "Security Group: $SG_INPUT"
echo "Protocol: $PROTOCOL"
echo "Source: $SOURCE"
echo "=========================================="
echo ""

# Resolve security group ID if name is provided
if [[ $SG_INPUT == sg-* ]]; then
    SG_ID=$SG_INPUT
    echo "Using Security Group ID: $SG_ID"
else
    echo "Resolving Security Group name to ID..."
    SG_ID=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=$SG_INPUT" \
        --query 'SecurityGroups[0].GroupId' \
        --output text)
    
    if [ "$SG_ID" == "None" ] || [ -z "$SG_ID" ]; then
        echo -e "${RED}Error: Security Group '$SG_INPUT' not found${NC}"
        exit 1
    fi
    echo -e "${GREEN}Found Security Group ID: $SG_ID${NC}"
fi
echo ""

# Determine port and protocol based on input
case $PROTOCOL in
    ssh)
        PORT=22
        IP_PROTOCOL="tcp"
        DESCRIPTION="SSH access"
        ;;
    http)
        PORT=80
        IP_PROTOCOL="tcp"
        DESCRIPTION="HTTP access"
        ;;
    https)
        PORT=443
        IP_PROTOCOL="tcp"
        DESCRIPTION="HTTPS access"
        ;;
    mysql)
        PORT=3306
        IP_PROTOCOL="tcp"
        DESCRIPTION="MySQL access"
        ;;
    postgresql)
        PORT=5432
        IP_PROTOCOL="tcp"
        DESCRIPTION="PostgreSQL access"
        ;;
    rdp)
        PORT=3389
        IP_PROTOCOL="tcp"
        DESCRIPTION="RDP access"
        ;;
    custom)
        echo -e "${YELLOW}Custom protocol selected${NC}"
        read -p "Enter port number: " PORT
        read -p "Enter IP protocol (tcp/udp/icmp): " IP_PROTOCOL
        read -p "Enter description: " DESCRIPTION
        ;;
    *)
        echo -e "${RED}Error: Unsupported protocol '$PROTOCOL'${NC}"
        echo "Supported: ssh, http, https, mysql, postgresql, rdp, custom"
        exit 1
        ;;
esac

echo "Port: $PORT"
echo "IP Protocol: $IP_PROTOCOL"
echo "Description: $DESCRIPTION"
echo ""

# Check if source is a security group or CIDR
if [[ $SOURCE == sg-* ]]; then
    SOURCE_TYPE="security-group"
    echo "Source Type: Security Group"
    echo "Source SG: $SOURCE"
    
    # Verify source security group exists
    SOURCE_SG_EXISTS=$(aws ec2 describe-security-groups \
        --group-ids "$SOURCE" \
        --query 'SecurityGroups[0].GroupId' \
        --output text 2>/dev/null || echo "None")
    
    if [ "$SOURCE_SG_EXISTS" == "None" ]; then
        echo -e "${RED}Error: Source Security Group '$SOURCE' not found${NC}"
        exit 1
    fi
else
    SOURCE_TYPE="cidr"
    echo "Source Type: CIDR Block"
    echo "Source CIDR: $SOURCE"
    
    # Validate CIDR format (basic check)
    if [[ ! $SOURCE =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
        echo -e "${YELLOW}Warning: Source doesn't look like a valid CIDR block${NC}"
        read -p "Continue anyway? (y/n): " CONTINUE
        if [ "$CONTINUE" != "y" ]; then
            exit 1
        fi
    fi
fi
echo ""

# Show current inbound rules
echo -e "${YELLOW}Current Inbound Rules:${NC}"
aws ec2 describe-security-groups \
    --group-ids "$SG_ID" \
    --query 'SecurityGroups[0].IpPermissions' \
    --output table
echo ""

# Confirm before making changes
read -p "Add this rule to the security group? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Operation cancelled"
    exit 0
fi
echo ""

# Add the inbound rule
echo "Adding inbound rule..."

if [ "$SOURCE_TYPE" == "security-group" ]; then
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --ip-permissions \
        IpProtocol="$IP_PROTOCOL",FromPort="$PORT",ToPort="$PORT",UserIdGroupPairs="[{GroupId=$SOURCE,Description='$DESCRIPTION'}]"
else
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --ip-permissions \
        IpProtocol="$IP_PROTOCOL",FromPort="$PORT",ToPort="$PORT",IpRanges="[{CidrIp=$SOURCE,Description='$DESCRIPTION'}]"
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Rule added successfully${NC}"
else
    echo -e "${RED}✗ Failed to add rule${NC}"
    echo "The rule may already exist or there may be a permission issue"
    exit 1
fi
echo ""

# Show updated inbound rules
echo -e "${YELLOW}Updated Inbound Rules:${NC}"
aws ec2 describe-security-groups \
    --group-ids "$SG_ID" \
    --query 'SecurityGroups[0].IpPermissions' \
    --output table
echo ""

echo "=========================================="
echo -e "${GREEN}Security Group updated successfully${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Test connectivity to verify the rule works"
echo "2. Document the change in your security group inventory"
echo "3. Review other rules for compliance with least privilege"
