#!/bin/bash

################################################################################
# Update Security Group with Security Group Reference (Task 4)
#
# This script updates AppServerSG to reference BastionHostSG instead of a
# specific IP address, and assigns BastionHostSG to the Public Server.
#
# Usage:
#   ./update-security-group-reference.sh [--dry-run]
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
# Function: Get security group IDs
################################################################################
get_security_groups() {
    print_info "Gathering security group information..."
    
    # Get AppServerSG
    APPSERVER_SG=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=AppServerSG" \
        --query "SecurityGroups[0].GroupId" \
        --output text)
    
    if [ "$APPSERVER_SG" == "None" ] || [ -z "$APPSERVER_SG" ]; then
        print_error "Could not find AppServerSG"
        exit 1
    fi
    
    print_success "AppServerSG ID: $APPSERVER_SG"
    
    # Get BastionHostSG
    BASTION_SG=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=BastionHostSG" \
        --query "SecurityGroups[0].GroupId" \
        --output text)
    
    if [ "$BASTION_SG" == "None" ] || [ -z "$BASTION_SG" ]; then
        print_error "Could not find BastionHostSG"
        exit 1
    fi
    
    print_success "BastionHostSG ID: $BASTION_SG"
    
    # Get PublicServerSG
    PUBLIC_SG=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=PublicServerSG" \
        --query "SecurityGroups[0].GroupId" \
        --output text)
    
    if [ "$PUBLIC_SG" == "None" ] || [ -z "$PUBLIC_SG" ]; then
        print_warning "Could not find PublicServerSG (may not exist)"
        PUBLIC_SG=""
    else
        print_success "PublicServerSG ID: $PUBLIC_SG"
    fi
}

################################################################################
# Function: Get instance information
################################################################################
get_instance_info() {
    print_info "Gathering instance information..."
    
    # Get Bastion Host IP
    BASTION_IP=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=Bastion Host" "Name=instance-state-name,Values=running" \
        --query "Reservations[0].Instances[0].PrivateIpAddress" \
        --output text)
    
    if [ "$BASTION_IP" == "None" ] || [ -z "$BASTION_IP" ]; then
        print_error "Could not find Bastion Host instance"
        exit 1
    fi
    
    print_success "Bastion Host IP: $BASTION_IP"
    
    # Get Public Server instance ID
    PUBLIC_INSTANCE=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=Public Server" "Name=instance-state-name,Values=running" \
        --query "Reservations[0].Instances[0].InstanceId" \
        --output text)
    
    if [ "$PUBLIC_INSTANCE" == "None" ] || [ -z "$PUBLIC_INSTANCE" ]; then
        print_error "Could not find Public Server instance"
        exit 1
    fi
    
    print_success "Public Server ID: $PUBLIC_INSTANCE"
    
    # Get App Server IP
    APP_SERVER_IP=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=App Server" "Name=instance-state-name,Values=running" \
        --query "Reservations[0].Instances[0].PrivateIpAddress" \
        --output text)
    
    print_success "App Server IP: $APP_SERVER_IP"
}

################################################################################
# Function: Display current AppServerSG rules
################################################################################
display_current_appserver_rules() {
    print_info "Current AppServerSG inbound rules:"
    
    aws ec2 describe-security-groups \
        --group-ids $APPSERVER_SG \
        --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp,UserIdGroupPairs[0].GroupId]" \
        --output table
}

################################################################################
# Function: Display current Public Server security groups
################################################################################
display_current_public_server_sgs() {
    print_info "Current Public Server security groups:"
    
    aws ec2 describe-instances \
        --instance-ids $PUBLIC_INSTANCE \
        --query "Reservations[0].Instances[0].SecurityGroups[].[GroupId,GroupName]" \
        --output table
}

################################################################################
# Function: Check for existing rules
################################################################################
check_existing_rules() {
    print_info "Checking for existing rules..."
    
    # Check for IP-based SSH rule
    IP_SSH_RULE=$(aws ec2 describe-security-groups \
        --group-ids $APPSERVER_SG \
        --query "SecurityGroups[0].IpPermissions[?FromPort==\`22\` && ToPort==\`22\` && IpRanges[?CidrIp==\`${BASTION_IP}/32\`]].IpRanges[0].CidrIp" \
        --output text)
    
    if [ "$IP_SSH_RULE" == "${BASTION_IP}/32" ]; then
        print_warning "Found IP-based SSH rule for ${BASTION_IP}/32 (will be removed)"
        REMOVE_IP_RULE=true
    else
        print_info "No IP-based SSH rule found"
        REMOVE_IP_RULE=false
    fi
    
    # Check for security group reference rule
    SG_SSH_RULE=$(aws ec2 describe-security-groups \
        --group-ids $APPSERVER_SG \
        --query "SecurityGroups[0].IpPermissions[?FromPort==\`22\` && ToPort==\`22\` && UserIdGroupPairs[?GroupId==\`${BASTION_SG}\`]].UserIdGroupPairs[0].GroupId" \
        --output text)
    
    if [ "$SG_SSH_RULE" == "$BASTION_SG" ]; then
        print_warning "Security group reference rule already exists"
        ADD_SG_RULE=false
    else
        print_info "Security group reference rule not found (will be added)"
        ADD_SG_RULE=true
    fi
    
    # Check if Public Server already has BastionHostSG
    PUBLIC_HAS_BASTION=$(aws ec2 describe-instances \
        --instance-ids $PUBLIC_INSTANCE \
        --query "Reservations[0].Instances[0].SecurityGroups[?GroupId==\`${BASTION_SG}\`].GroupId" \
        --output text)
    
    if [ "$PUBLIC_HAS_BASTION" == "$BASTION_SG" ]; then
        print_warning "Public Server already has BastionHostSG"
        ASSIGN_BASTION_SG=false
    else
        print_info "Public Server does not have BastionHostSG (will be assigned)"
        ASSIGN_BASTION_SG=true
    fi
}

################################################################################
# Function: Remove IP-based SSH rule
################################################################################
remove_ip_ssh_rule() {
    if [ "$REMOVE_IP_RULE" = true ]; then
        print_info "Removing IP-based SSH rule for ${BASTION_IP}/32..."
        
        if [ "$DRY_RUN" = true ]; then
            print_warning "DRY RUN: Would remove SSH rule for ${BASTION_IP}/32"
        else
            aws ec2 revoke-security-group-ingress \
                --group-id $APPSERVER_SG \
                --protocol tcp \
                --port 22 \
                --cidr ${BASTION_IP}/32
            
            print_success "Removed IP-based SSH rule"
        fi
    fi
}

################################################################################
# Function: Add security group reference rule
################################################################################
add_sg_reference_rule() {
    if [ "$ADD_SG_RULE" = true ]; then
        print_info "Adding SSH rule referencing BastionHostSG..."
        
        if [ "$DRY_RUN" = true ]; then
            print_warning "DRY RUN: Would add SSH rule referencing $BASTION_SG"
        else
            aws ec2 authorize-security-group-ingress \
                --group-id $APPSERVER_SG \
                --protocol tcp \
                --port 22 \
                --source-group $BASTION_SG \
                --group-rule-description "SSH from bastion hosts"
            
            print_success "Added security group reference rule"
        fi
    fi
}

################################################################################
# Function: Assign BastionHostSG to Public Server
################################################################################
assign_bastion_sg_to_public() {
    if [ "$ASSIGN_BASTION_SG" = true ]; then
        print_info "Assigning BastionHostSG to Public Server..."
        
        if [ "$DRY_RUN" = true ]; then
            print_warning "DRY RUN: Would assign $BASTION_SG to $PUBLIC_INSTANCE"
        else
            # Get current security groups
            CURRENT_SGS=$(aws ec2 describe-instances \
                --instance-ids $PUBLIC_INSTANCE \
                --query "Reservations[0].Instances[0].SecurityGroups[*].GroupId" \
                --output text)
            
            # Add BastionHostSG to the list
            NEW_SGS="$BASTION_SG"
            
            # Keep other security groups except PublicServerSG
            for sg in $CURRENT_SGS; do
                if [ "$sg" != "$PUBLIC_SG" ]; then
                    NEW_SGS="$NEW_SGS $sg"
                fi
            done
            
            # Assign security groups
            aws ec2 modify-instance-attribute \
                --instance-id $PUBLIC_INSTANCE \
                --groups $NEW_SGS
            
            print_success "Assigned BastionHostSG to Public Server"
            
            if [ ! -z "$PUBLIC_SG" ]; then
                print_info "Removed PublicServerSG from Public Server"
            fi
        fi
    fi
}

################################################################################
# Function: Display updated rules
################################################################################
display_updated_rules() {
    if [ "$DRY_RUN" = false ]; then
        echo ""
        print_info "Updated AppServerSG inbound rules:"
        
        aws ec2 describe-security-groups \
            --group-ids $APPSERVER_SG \
            --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp,UserIdGroupPairs[0].GroupId]" \
            --output table
        
        echo ""
        print_info "Updated Public Server security groups:"
        
        aws ec2 describe-instances \
            --instance-ids $PUBLIC_INSTANCE \
            --query "Reservations[0].Instances[0].SecurityGroups[].[GroupId,GroupName]" \
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
    echo "2. Test SSH from Public Server (should now succeed):"
    echo "   - Connect to Public Server via Session Manager"
    echo "   - Run: ssh -A ec2-user@${APP_SERVER_IP}"
    echo "   - Expected: Connection succeeds ✅ (Public Server is now a bastion)"
    echo ""
    echo "3. Verify AppServerSG rule:"
    echo "   - Go to EC2 Console > Security Groups"
    echo "   - Select AppServerSG"
    echo "   - Verify SSH rule references: $BASTION_SG (BastionHostSG)"
    echo ""
    echo "4. Verify Public Server security groups:"
    echo "   - Go to EC2 Console > Instances"
    echo "   - Select Public Server"
    echo "   - Verify it has BastionHostSG assigned"
    echo ""
}

################################################################################
# Function: Display key learnings
################################################################################
display_key_learnings() {
    echo ""
    echo "========================================================================"
    echo "Key Learnings"
    echo "========================================================================"
    echo ""
    echo "✅ Security group references are more flexible than IP-based rules"
    echo "✅ Multiple instances can share the same security group for access"
    echo "✅ Changes to instance SG assignments automatically update access"
    echo "✅ This pattern scales well for multiple bastion hosts"
    echo "✅ No need to update rules when IP addresses change"
    echo ""
    echo "Benefits of Security Group References:"
    echo "  • Dynamic: Automatically updates when instances change"
    echo "  • Scalable: Supports multiple bastion hosts easily"
    echo "  • Maintainable: No need to update rules when IPs change"
    echo "  • Flexible: Add/remove access by changing instance SG assignments"
    echo ""
}

################################################################################
# Function: Display rollback instructions
################################################################################
display_rollback() {
    echo ""
    echo "========================================================================"
    echo "Rollback Instructions"
    echo "========================================================================"
    echo ""
    echo "To revert to IP-based rule configuration:"
    echo ""
    echo "# Remove security group reference rule"
    echo "aws ec2 revoke-security-group-ingress \\"
    echo "  --group-id $APPSERVER_SG \\"
    echo "  --protocol tcp \\"
    echo "  --port 22 \\"
    echo "  --source-group $BASTION_SG"
    echo ""
    echo "# Add IP-based rule"
    echo "aws ec2 authorize-security-group-ingress \\"
    echo "  --group-id $APPSERVER_SG \\"
    echo "  --protocol tcp \\"
    echo "  --port 22 \\"
    echo "  --cidr ${BASTION_IP}/32"
    echo ""
    echo "# Remove BastionHostSG from Public Server"
    if [ ! -z "$PUBLIC_SG" ]; then
        echo "aws ec2 modify-instance-attribute \\"
        echo "  --instance-id $PUBLIC_INSTANCE \\"
        echo "  --groups $PUBLIC_SG"
    else
        echo "# (Restore original security groups manually)"
    fi
    echo ""
}

################################################################################
# Main execution
################################################################################
main() {
    echo "========================================================================"
    echo "Update Security Group with Security Group Reference (Task 4)"
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
    get_security_groups
    get_instance_info
    echo ""
    display_current_appserver_rules
    echo ""
    display_current_public_server_sgs
    echo ""
    check_existing_rules
    echo ""
    
    # Confirm before proceeding
    if [ "$DRY_RUN" = false ]; then
        echo "This script will:"
        echo "  1. Remove IP-based SSH rule from AppServerSG (if exists)"
        echo "  2. Add security group reference rule to AppServerSG"
        echo "  3. Assign BastionHostSG to Public Server"
        echo "  4. Remove PublicServerSG from Public Server"
        echo ""
        read -p "Proceed with security group update? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            print_warning "Operation cancelled"
            exit 0
        fi
        echo ""
    fi
    
    # Make changes
    remove_ip_ssh_rule
    add_sg_reference_rule
    assign_bastion_sg_to_public
    echo ""
    
    # Display results
    display_updated_rules
    
    if [ "$DRY_RUN" = false ]; then
        print_success "Security group update complete!"
        display_verification
        display_key_learnings
        display_rollback
    else
        print_info "Dry run complete. Run without --dry-run to apply changes."
    fi
}

# Run main function
main "$@"
