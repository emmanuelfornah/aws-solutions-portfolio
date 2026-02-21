#!/bin/bash

################################################################################
# Update Security Group with IP-Based Rule (Task 3)
#
# This script updates AppServerSG to allow SSH only from the Bastion Host's
# specific IP address, implementing the principle of least privilege.
#
# Usage:
#   ./update-security-group-ip.sh [--dry-run]
#
# Options:
#   --dry-run    Show what would be done without making changes
################################################################################

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DRY_RUN=false

################################################################################
# Function: Print colored output
################################################################################
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

################################################################################
# Function: Check prerequisites
################################################################################
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install AWS CLI."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run 'aws configure'."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

################################################################################
# Function: Get instance information
################################################################################
get_instance_info() {
    print_info "Gathering instance information..."
    
    # Get Bastion Host private IP
    BASTION_IP=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=Bastion Host" "Name=instance-state-name,Values=running" \
        --query "Reservations[0].Instances[0].PrivateIpAddress" \
        --output text)
    
    if [ "$BASTION_IP" == "None" ] || [ -z "$BASTION_IP" ]; then
        print_error "Could not find Bastion Host instance"
        exit 1
    fi
    
    print_success "Bastion Host IP: $BASTION_IP"
    
    # Get App Server instance ID and security group
    APP_SERVER_INFO=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=App Server" "Name=instance-state-name,Values=running" \
        --query "Reservations[0].Instances[0].[InstanceId,PrivateIpAddress,SecurityGroups[0].GroupId]" \
        --output text)
    
    if [ -z "$APP_SERVER_INFO" ]; then
        print_error "Could not find App Server instance"
        exit 1
    fi
    
    APP_INSTANCE_ID=$(echo $APP_SERVER_INFO | awk '{print $1}')
    APP_SERVER_IP=$(echo $APP_SERVER_INFO | awk '{print $2}')
    APPSERVER_SG=$(echo $APP_SERVER_INFO | awk '{print $3}')
    
    print_success "App Server IP: $APP_SERVER_IP"
    print_success "AppServerSG ID: $APPSERVER_SG"
}

################################################################################
# Function: Display current security group rules
################################################################################
display_current_rules() {
    print_info "Current AppServerSG inbound rules:"
    
    aws ec2 describe-security-groups \
        --group-ids $APPSERVER_SG \
        --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp,IpRanges[0].Description]" \
        --output table
}

################################################################################
# Function: Check for existing SSH rules
################################################################################
check_existing_rules() {
    print_info "Checking for existing SSH rules..."
    
    # Check for 0.0.0.0/0 rule
    OPEN_SSH_RULE=$(aws ec2 describe-security-groups \
        --group-ids $APPSERVER_SG \
        --query "SecurityGroups[0].IpPermissions[?FromPort==\`22\` && ToPort==\`22\` && IpRanges[?CidrIp==\`0.0.0.0/0\`]].IpRanges[0].CidrIp" \
        --output text)
    
    if [ "$OPEN_SSH_RULE" == "0.0.0.0/0" ]; then
        print_warning "Found SSH rule allowing 0.0.0.0/0 (will be removed)"
        REMOVE_OPEN_RULE=true
    else
        print_info "No open SSH rule found (0.0.0.0/0)"
        REMOVE_OPEN_RULE=false
    fi
    
    # Check for existing Bastion IP rule
    BASTION_RULE=$(aws ec2 describe-security-groups \
        --group-ids $APPSERVER_SG \
        --query "SecurityGroups[0].IpPermissions[?FromPort==\`22\` && ToPort==\`22\` && IpRanges[?CidrIp==\`${BASTION_IP}/32\`]].IpRanges[0].CidrIp" \
        --output text)
    
    if [ "$BASTION_RULE" == "${BASTION_IP}/32" ]; then
        print_warning "Bastion Host IP rule already exists"
        ADD_BASTION_RULE=false
    else
        print_info "Bastion Host IP rule not found (will be added)"
        ADD_BASTION_RULE=true
    fi
}

################################################################################
# Function: Remove open SSH rule
################################################################################
remove_open_ssh_rule() {
    if [ "$REMOVE_OPEN_RULE" = true ]; then
        print_info "Removing SSH rule for 0.0.0.0/0..."
        
        if [ "$DRY_RUN" = true ]; then
            print_warning "DRY RUN: Would remove SSH rule for 0.0.0.0/0"
        else
            aws ec2 revoke-security-group-ingress \
                --group-id $APPSERVER_SG \
                --protocol tcp \
                --port 22 \
                --cidr 0.0.0.0/0
            
            print_success "Removed SSH rule for 0.0.0.0/0"
        fi
    fi
}

################################################################################
# Function: Add Bastion Host IP rule
################################################################################
add_bastion_ip_rule() {
    if [ "$ADD_BASTION_RULE" = true ]; then
        print_info "Adding SSH rule for Bastion Host IP (${BASTION_IP}/32)..."
        
        if [ "$DRY_RUN" = true ]; then
            print_warning "DRY RUN: Would add SSH rule for ${BASTION_IP}/32"
        else
            aws ec2 authorize-security-group-ingress \
                --group-id $APPSERVER_SG \
                --protocol tcp \
                --port 22 \
                --cidr ${BASTION_IP}/32 \
                --group-rule-description "SSH from Bastion Host only"
            
            print_success "Added SSH rule for ${BASTION_IP}/32"
        fi
    fi
}

################################################################################
# Function: Display updated rules
################################################################################
display_updated_rules() {
    if [ "$DRY_RUN" = false ]; then
        print_info "Updated AppServerSG inbound rules:"
        
        aws ec2 describe-security-groups \
            --group-ids $APPSERVER_SG \
            --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp,IpRanges[0].Description]" \
            --output table
    fi
}

################################################################################
# Function: Display verification instructions
################################################################################
display_verification() {
    echo ""
    echo "========================================================================"
    echo "Verification Steps"
    echo "========================================================================"
    echo ""
    echo "1. Test SSH from Bastion Host (should succeed):"
    echo "   - Connect to Bastion Host via Session Manager"
    echo "   - Run: ssh -A ec2-user@${APP_SERVER_IP}"
    echo "   - Expected: Connection succeeds ✅"
    echo ""
    echo "2. Test SSH from Public Server (should fail):"
    echo "   - Connect to Public Server via Session Manager"
    echo "   - Run: ssh -A ec2-user@${APP_SERVER_IP}"
    echo "   - Expected: Connection times out ❌"
    echo ""
    echo "3. Verify security group rule:"
    echo "   - Go to EC2 Console > Security Groups"
    echo "   - Select AppServerSG"
    echo "   - Verify SSH rule shows: ${BASTION_IP}/32"
    echo ""
}

################################################################################
# Function: Rollback instructions
################################################################################
display_rollback() {
    echo ""
    echo "========================================================================"
    echo "Rollback Instructions"
    echo "========================================================================"
    echo ""
    echo "To revert to the original configuration (allow SSH from anywhere):"
    echo ""
    echo "aws ec2 revoke-security-group-ingress \\"
    echo "  --group-id $APPSERVER_SG \\"
    echo "  --protocol tcp \\"
    echo "  --port 22 \\"
    echo "  --cidr ${BASTION_IP}/32"
    echo ""
    echo "aws ec2 authorize-security-group-ingress \\"
    echo "  --group-id $APPSERVER_SG \\"
    echo "  --protocol tcp \\"
    echo "  --port 22 \\"
    echo "  --cidr 0.0.0.0/0"
    echo ""
}

################################################################################
# Main execution
################################################################################
main() {
    echo "========================================================================"
    echo "Update Security Group with IP-Based Rule (Task 3)"
    echo "========================================================================"
    echo ""
    
    # Parse arguments
    if [ "$1" == "--dry-run" ]; then
        DRY_RUN=true
        print_warning "DRY RUN MODE - No changes will be made"
        echo ""
    fi
    
    # Execute steps
    check_prerequisites
    get_instance_info
    echo ""
    display_current_rules
    echo ""
    check_existing_rules
    echo ""
    
    # Confirm before proceeding
    if [ "$DRY_RUN" = false ]; then
        read -p "Proceed with security group update? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            print_warning "Operation cancelled"
            exit 0
        fi
        echo ""
    fi
    
    # Make changes
    remove_open_ssh_rule
    add_bastion_ip_rule
    echo ""
    
    # Display results
    display_updated_rules
    
    if [ "$DRY_RUN" = false ]; then
        print_success "Security group update complete!"
        display_verification
        display_rollback
    else
        print_info "Dry run complete. Run without --dry-run to apply changes."
    fi
}

# Run main function
main "$@"
