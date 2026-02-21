#!/bin/bash

################################################################################
# Apache Server Troubleshooting Script (Challenge)
#
# This script helps diagnose and fix connectivity issues with the Apache Server.
# It checks Apache service status, security group rules, and provides commands
# to add the missing HTTP rule.
#
# Usage:
#   ./troubleshoot-apache.sh [--diagnose|--fix|--test]
#
# Options:
#   --diagnose   Diagnose the issue (default)
#   --fix        Apply the fix (add HTTP rule)
#   --test       Test HTTP connectivity
################################################################################

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
MODE="diagnose"

################################################################################
# Function: Print colored output
################################################################################
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_step() { echo -e "${CYAN}▶ $1${NC}"; }

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
# Function: Get Apache Server information
################################################################################
get_apache_info() {
    print_info "Gathering Apache Server information..."
    
    # Get Apache Server details
    APACHE_INFO=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=Apache Server" "Name=instance-state-name,Values=running" \
        --query "Reservations[0].Instances[0].[InstanceId,PrivateIpAddress,PublicIpAddress,SecurityGroups[0].GroupId]" \
        --output text)
    
    if [ -z "$APACHE_INFO" ]; then
        print_error "Could not find Apache Server instance"
        exit 1
    fi
    
    APACHE_INSTANCE=$(echo $APACHE_INFO | awk '{print $1}')
    APACHE_PRIVATE_IP=$(echo $APACHE_INFO | awk '{print $2}')
    APACHE_PUBLIC_IP=$(echo $APACHE_INFO | awk '{print $3}')
    APACHE_SG=$(echo $APACHE_INFO | awk '{print $4}')
    
    print_success "Apache Server Instance ID: $APACHE_INSTANCE"
    print_success "Apache Server Private IP: $APACHE_PRIVATE_IP"
    print_success "Apache Server Public IP: $APACHE_PUBLIC_IP"
    print_success "ApacheServerSG ID: $APACHE_SG"
}

################################################################################
# Function: Check Apache service status (requires Session Manager)
################################################################################
check_apache_service() {
    print_step "Step 1: Checking Apache Service Status"
    echo ""
    
    print_info "To check if Apache is running, connect via Session Manager:"
    echo ""
    echo "  1. Go to EC2 Console"
    echo "  2. Select Apache Server instance ($APACHE_INSTANCE)"
    echo "  3. Click 'Connect' > 'Session Manager' > 'Connect'"
    echo "  4. Run the following commands:"
    echo ""
    echo "     # Check Apache status"
    echo "     sudo systemctl status httpd"
    echo ""
    echo "     # Test locally"
    echo "     curl localhost"
    echo ""
    
    print_info "Expected results:"
    echo "  • Apache status: active (running) ✅"
    echo "  • curl localhost: Returns HTML content ✅"
    echo ""
}

################################################################################
# Function: Check security group rules
################################################################################
check_security_group() {
    print_step "Step 2: Checking Security Group Rules"
    echo ""
    
    print_info "Current ApacheServerSG inbound rules:"
    echo ""
    
    aws ec2 describe-security-groups \
        --group-ids $APACHE_SG \
        --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp,IpRanges[0].Description]" \
        --output table
    
    echo ""
    
    # Check for HTTP rule
    HTTP_RULE=$(aws ec2 describe-security-groups \
        --group-ids $APACHE_SG \
        --query "SecurityGroups[0].IpPermissions[?FromPort==\`80\` && ToPort==\`80\`].FromPort" \
        --output text)
    
    if [ "$HTTP_RULE" == "80" ]; then
        print_success "HTTP rule (port 80) found"
        HTTP_RULE_EXISTS=true
    else
        print_error "HTTP rule (port 80) NOT found - This is the problem!"
        HTTP_RULE_EXISTS=false
    fi
    
    echo ""
    
    # Check for HTTPS rule
    HTTPS_RULE=$(aws ec2 describe-security-groups \
        --group-ids $APACHE_SG \
        --query "SecurityGroups[0].IpPermissions[?FromPort==\`443\` && ToPort==\`443\`].FromPort" \
        --output text)
    
    if [ "$HTTPS_RULE" == "443" ]; then
        print_success "HTTPS rule (port 443) found"
    else
        print_warning "HTTPS rule (port 443) not found (optional)"
    fi
    
    echo ""
}

################################################################################
# Function: Test HTTP connectivity
################################################################################
test_http_connectivity() {
    print_step "Step 3: Testing HTTP Connectivity"
    echo ""
    
    if [ -z "$APACHE_PUBLIC_IP" ] || [ "$APACHE_PUBLIC_IP" == "None" ]; then
        print_error "Apache Server has no public IP address"
        return 1
    fi
    
    print_info "Testing HTTP connection to http://${APACHE_PUBLIC_IP}"
    echo ""
    
    # Test with curl
    if command -v curl &> /dev/null; then
        HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://${APACHE_PUBLIC_IP} 2>&1 || echo "timeout")
        
        if [ "$HTTP_RESPONSE" == "200" ]; then
            print_success "HTTP connection successful (HTTP 200)"
            echo ""
            echo "Apache Test Page content:"
            curl -s http://${APACHE_PUBLIC_IP} | head -20
        elif [ "$HTTP_RESPONSE" == "timeout" ]; then
            print_error "HTTP connection timed out"
            print_warning "This indicates a security group or network issue"
        else
            print_warning "HTTP connection returned status: $HTTP_RESPONSE"
        fi
    else
        print_warning "curl not found, skipping connectivity test"
        print_info "Test manually in browser: http://${APACHE_PUBLIC_IP}"
    fi
    
    echo ""
}

################################################################################
# Function: Diagnose the issue
################################################################################
diagnose_issue() {
    echo "========================================================================"
    echo "Apache Server Connectivity Diagnosis"
    echo "========================================================================"
    echo ""
    
    check_prerequisites
    get_apache_info
    echo ""
    
    check_apache_service
    check_security_group
    test_http_connectivity
    
    # Summary
    echo "========================================================================"
    echo "Diagnosis Summary"
    echo "========================================================================"
    echo ""
    
    if [ "$HTTP_RULE_EXISTS" = false ]; then
        print_error "ROOT CAUSE: Missing HTTP inbound rule in ApacheServerSG"
        echo ""
        echo "The Apache service is likely running, but the security group is"
        echo "blocking HTTP traffic on port 80 from the internet."
        echo ""
        print_info "Solution: Add HTTP (port 80) inbound rule to ApacheServerSG"
        echo ""
        echo "Run this script with --fix to apply the solution:"
        echo "  ./troubleshoot-apache.sh --fix"
    else
        print_success "HTTP rule exists in security group"
        echo ""
        echo "If you still cannot access the Apache server, check:"
        echo "  • Apache service is running (use Session Manager)"
        echo "  • Instance has a public IP address"
        echo "  • Network ACLs (if configured)"
        echo "  • Route table has route to Internet Gateway"
    fi
    
    echo ""
}

################################################################################
# Function: Fix the issue
################################################################################
fix_issue() {
    echo "========================================================================"
    echo "Apache Server Connectivity Fix"
    echo "========================================================================"
    echo ""
    
    check_prerequisites
    get_apache_info
    echo ""
    
    # Check if HTTP rule already exists
    HTTP_RULE=$(aws ec2 describe-security-groups \
        --group-ids $APACHE_SG \
        --query "SecurityGroups[0].IpPermissions[?FromPort==\`80\` && ToPort==\`80\`].FromPort" \
        --output text)
    
    if [ "$HTTP_RULE" == "80" ]; then
        print_warning "HTTP rule already exists in ApacheServerSG"
        echo ""
        print_info "Current inbound rules:"
        aws ec2 describe-security-groups \
            --group-ids $APACHE_SG \
            --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp]" \
            --output table
        echo ""
        print_info "If you still cannot access Apache, run with --diagnose for troubleshooting"
        return 0
    fi
    
    # Confirm before applying fix
    echo "This will add the following rule to ApacheServerSG:"
    echo ""
    echo "  Type: HTTP"
    echo "  Protocol: TCP"
    echo "  Port: 80"
    echo "  Source: 0.0.0.0/0 (allow from internet)"
    echo "  Description: Allow HTTP from internet"
    echo ""
    read -p "Proceed with adding HTTP rule? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_warning "Operation cancelled"
        exit 0
    fi
    
    echo ""
    print_info "Adding HTTP inbound rule to ApacheServerSG..."
    
    aws ec2 authorize-security-group-ingress \
        --group-id $APACHE_SG \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0 \
        --group-rule-description "Allow HTTP from internet"
    
    print_success "HTTP rule added successfully!"
    echo ""
    
    # Display updated rules
    print_info "Updated ApacheServerSG inbound rules:"
    aws ec2 describe-security-groups \
        --group-ids $APACHE_SG \
        --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp,IpRanges[0].Description]" \
        --output table
    
    echo ""
    print_success "Fix applied! Testing connectivity..."
    echo ""
    
    # Wait a moment for changes to propagate
    sleep 2
    
    # Test connectivity
    test_http_connectivity
    
    # Verification instructions
    echo ""
    echo "========================================================================"
    echo "Verification Steps"
    echo "========================================================================"
    echo ""
    echo "1. Open a web browser"
    echo "2. Navigate to: http://${APACHE_PUBLIC_IP}"
    echo "3. You should see the Apache Test Page"
    echo ""
    print_success "Challenge complete!"
    echo ""
}

################################################################################
# Function: Test only
################################################################################
test_only() {
    echo "========================================================================"
    echo "Apache Server Connectivity Test"
    echo "========================================================================"
    echo ""
    
    check_prerequisites
    get_apache_info
    echo ""
    
    test_http_connectivity
    
    echo "========================================================================"
    echo "Browser Test"
    echo "========================================================================"
    echo ""
    echo "Open a web browser and navigate to:"
    echo ""
    echo "  http://${APACHE_PUBLIC_IP}"
    echo ""
    echo "Expected result: Apache Test Page displays 'It works!'"
    echo ""
}

################################################################################
# Function: Display help
################################################################################
display_help() {
    echo "Apache Server Troubleshooting Script"
    echo ""
    echo "Usage: $0 [--diagnose|--fix|--test|--help]"
    echo ""
    echo "Options:"
    echo "  --diagnose   Diagnose connectivity issues (default)"
    echo "  --fix        Apply the fix (add HTTP rule to security group)"
    echo "  --test       Test HTTP connectivity only"
    echo "  --help       Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Diagnose the issue"
    echo "  $0 --diagnose         # Diagnose the issue"
    echo "  $0 --fix              # Apply the fix"
    echo "  $0 --test             # Test connectivity"
    echo ""
}

################################################################################
# Function: Display manual fix instructions
################################################################################
display_manual_fix() {
    echo ""
    echo "========================================================================"
    echo "Manual Fix Instructions"
    echo "========================================================================"
    echo ""
    echo "To manually add the HTTP rule via AWS Console:"
    echo ""
    echo "1. Go to EC2 Console > Security Groups"
    echo "2. Select ApacheServerSG ($APACHE_SG)"
    echo "3. Click 'Edit inbound rules'"
    echo "4. Click 'Add rule'"
    echo "5. Configure the rule:"
    echo "   - Type: HTTP"
    echo "   - Protocol: TCP"
    echo "   - Port Range: 80"
    echo "   - Source: 0.0.0.0/0"
    echo "   - Description: Allow HTTP from internet"
    echo "6. Click 'Save rules'"
    echo ""
    echo "To add the HTTP rule via AWS CLI:"
    echo ""
    echo "aws ec2 authorize-security-group-ingress \\"
    echo "  --group-id $APACHE_SG \\"
    echo "  --protocol tcp \\"
    echo "  --port 80 \\"
    echo "  --cidr 0.0.0.0/0 \\"
    echo "  --group-rule-description \"Allow HTTP from internet\""
    echo ""
}

################################################################################
# Main execution
################################################################################
main() {
    # Parse arguments
    case "${1:-}" in
        --diagnose)
            MODE="diagnose"
            ;;
        --fix)
            MODE="fix"
            ;;
        --test)
            MODE="test"
            ;;
        --help|-h)
            display_help
            exit 0
            ;;
        "")
            MODE="diagnose"
            ;;
        *)
            echo "Unknown option: $1"
            display_help
            exit 1
            ;;
    esac
    
    # Execute based on mode
    case $MODE in
        diagnose)
            diagnose_issue
            display_manual_fix
            ;;
        fix)
            fix_issue
            ;;
        test)
            test_only
            ;;
    esac
}

# Run main function
main "$@"
