#!/bin/bash

################################################################################
# SSH Connectivity Test Script
# 
# This script provides commands for testing SSH connectivity to the App Server
# from different sources (Bastion Host and Public Server).
#
# Usage:
#   1. Connect to source instance via Session Manager
#   2. Run the commands in this script
#   3. Verify expected results
################################################################################

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_SERVER_IP="10.0.20.10"  # Update with your App Server private IP

################################################################################
# Function: Display header
################################################################################
print_header() {
    echo "========================================================================"
    echo "$1"
    echo "========================================================================"
}

################################################################################
# Function: Test SSH connectivity
################################################################################
test_ssh_connection() {
    local target_ip=$1
    local source_name=$2
    local expected_result=$3
    
    echo -e "\n${YELLOW}Testing SSH from ${source_name} to App Server (${target_ip})${NC}"
    echo "Expected result: ${expected_result}"
    echo ""
    
    # Start SSH agent
    echo "Starting SSH agent..."
    eval $(ssh-agent -s)
    
    # Display current hostname
    echo -e "\nCurrent host:"
    hostname
    
    # Attempt SSH connection
    echo -e "\nAttempting SSH connection..."
    echo "Command: ssh -A -o ConnectTimeout=10 ec2-user@${target_ip}"
    echo ""
    
    # Note: This will attempt the connection
    # Use Ctrl+C to cancel if it hangs
    ssh -A -o ConnectTimeout=10 ec2-user@${target_ip} 'hostname && echo "Connection successful!"'
    
    local result=$?
    
    if [ $result -eq 0 ]; then
        echo -e "${GREEN}✅ Connection succeeded${NC}"
    else
        echo -e "${RED}❌ Connection failed (timeout or refused)${NC}"
    fi
    
    return $result
}

################################################################################
# Function: Display manual test instructions
################################################################################
display_manual_instructions() {
    local source=$1
    
    print_header "Manual SSH Test Instructions - ${source}"
    
    echo "1. Connect to ${source} via Session Manager:"
    echo "   - Go to EC2 Console"
    echo "   - Select the ${source} instance"
    echo "   - Click 'Connect' > 'Session Manager' > 'Connect'"
    echo ""
    
    echo "2. Start SSH agent:"
    echo "   ssh-agent -s"
    echo ""
    
    echo "3. Verify current hostname:"
    echo "   hostname"
    echo ""
    
    echo "4. SSH to App Server:"
    echo "   ssh -A ec2-user@${APP_SERVER_IP}"
    echo ""
    
    echo "5. Once connected, verify you're on App Server:"
    echo "   hostname"
    echo "   # Should show: ip-10-0-20-xxx"
    echo ""
    
    echo "6. Exit the SSH session:"
    echo "   exit"
    echo ""
}

################################################################################
# Main Menu
################################################################################
main_menu() {
    print_header "VPC Connectivity Test Script"
    
    echo "This script helps test SSH connectivity to the App Server."
    echo ""
    echo "Select test scenario:"
    echo "  1) Task 2.1 - Test from Bastion Host (should succeed)"
    echo "  2) Task 2.2 - Test from Public Server (Task 2: should succeed, Task 3: should fail)"
    echo "  3) Task 3 - Verify IP restriction (Bastion: succeed, Public: fail)"
    echo "  4) Task 4 - Verify SG reference (both should succeed)"
    echo "  5) Display manual test instructions"
    echo "  6) Quick connectivity test"
    echo "  q) Quit"
    echo ""
    read -p "Enter choice: " choice
    
    case $choice in
        1)
            display_manual_instructions "Bastion Host"
            ;;
        2)
            display_manual_instructions "Public Server"
            ;;
        3)
            print_header "Task 3 Verification - IP Restriction"
            echo "After Task 3, AppServerSG should allow SSH only from Bastion Host IP."
            echo ""
            echo "Expected results:"
            echo "  ✅ Bastion Host → App Server: SUCCESS"
            echo "  ❌ Public Server → App Server: TIMEOUT"
            echo ""
            display_manual_instructions "Bastion Host"
            echo ""
            display_manual_instructions "Public Server"
            ;;
        4)
            print_header "Task 4 Verification - Security Group Reference"
            echo "After Task 4, AppServerSG should allow SSH from BastionHostSG."
            echo "Public Server should have BastionHostSG assigned."
            echo ""
            echo "Expected results:"
            echo "  ✅ Bastion Host → App Server: SUCCESS"
            echo "  ✅ Public Server → App Server: SUCCESS (now has BastionHostSG)"
            echo ""
            display_manual_instructions "Bastion Host"
            echo ""
            display_manual_instructions "Public Server"
            ;;
        5)
            echo ""
            echo "Select source:"
            echo "  1) Bastion Host"
            echo "  2) Public Server"
            read -p "Enter choice: " source_choice
            
            case $source_choice in
                1) display_manual_instructions "Bastion Host" ;;
                2) display_manual_instructions "Public Server" ;;
                *) echo "Invalid choice" ;;
            esac
            ;;
        6)
            print_header "Quick Connectivity Test"
            echo "This will attempt to SSH to the App Server from the current host."
            echo ""
            read -p "Enter App Server private IP [${APP_SERVER_IP}]: " input_ip
            if [ ! -z "$input_ip" ]; then
                APP_SERVER_IP=$input_ip
            fi
            
            test_ssh_connection "$APP_SERVER_IP" "Current Host" "Depends on security group configuration"
            ;;
        q|Q)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
}

################################################################################
# Automated Test Suite (requires AWS CLI and jq)
################################################################################
automated_test_suite() {
    print_header "Automated Test Suite"
    
    # Check for required tools
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}AWS CLI not found. Please install AWS CLI.${NC}"
        return 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}jq not found. Install jq for better output formatting.${NC}"
    fi
    
    echo "Gathering instance information..."
    
    # Get App Server IP
    APP_SERVER_IP=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=App Server" "Name=instance-state-name,Values=running" \
        --query "Reservations[0].Instances[0].PrivateIpAddress" \
        --output text)
    
    if [ "$APP_SERVER_IP" == "None" ] || [ -z "$APP_SERVER_IP" ]; then
        echo -e "${RED}Could not find App Server instance${NC}"
        return 1
    fi
    
    echo "App Server IP: $APP_SERVER_IP"
    
    # Get Bastion Host IP
    BASTION_IP=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=Bastion Host" "Name=instance-state-name,Values=running" \
        --query "Reservations[0].Instances[0].PrivateIpAddress" \
        --output text)
    
    echo "Bastion Host IP: $BASTION_IP"
    
    # Get Public Server IP
    PUBLIC_IP=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=Public Server" "Name=instance-state-name,Values=running" \
        --query "Reservations[0].Instances[0].PrivateIpAddress" \
        --output text)
    
    echo "Public Server IP: $PUBLIC_IP"
    
    # Get AppServerSG details
    echo -e "\n${YELLOW}Checking AppServerSG configuration...${NC}"
    
    APPSERVER_SG=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=App Server" \
        --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" \
        --output text)
    
    echo "AppServerSG ID: $APPSERVER_SG"
    
    echo -e "\nInbound Rules:"
    aws ec2 describe-security-groups \
        --group-ids $APPSERVER_SG \
        --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp,UserIdGroupPairs[0].GroupId]" \
        --output table
    
    echo -e "\n${GREEN}Test suite complete!${NC}"
    echo "Use the manual test instructions to verify connectivity."
}

################################################################################
# Entry Point
################################################################################

# Check if running with arguments
if [ $# -gt 0 ]; then
    case $1 in
        --auto)
            automated_test_suite
            ;;
        --help)
            echo "Usage: $0 [--auto|--help]"
            echo ""
            echo "Options:"
            echo "  --auto    Run automated test suite (requires AWS CLI)"
            echo "  --help    Display this help message"
            echo ""
            echo "Run without arguments for interactive menu."
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
else
    # Interactive mode
    while true; do
        main_menu
        echo ""
        read -p "Press Enter to continue or Ctrl+C to exit..."
        clear
    done
fi
