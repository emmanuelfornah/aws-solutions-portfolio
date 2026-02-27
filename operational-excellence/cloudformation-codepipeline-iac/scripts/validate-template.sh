#!/bin/bash

# Local CloudFormation Template Validation
# Validates the infrastructure template before pushing to repository

set -e

echo "=========================================="
echo "CloudFormation Template Validator"
echo "=========================================="
echo ""

TEMPLATE_FILE="infrastructure.yml"

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "ERROR: Template file '$TEMPLATE_FILE' not found"
    echo "Please run this script from the iac-code-repo directory"
    exit 1
fi

echo "Validating template: $TEMPLATE_FILE"
echo ""

# Check if cfn-lint is installed
if ! command -v cfn-lint &> /dev/null; then
    echo "cfn-lint not found. Installing..."
    pip install cfn-lint
    echo ""
fi

# Run cfn-lint validation
echo "Running cfn-lint validation..."
echo "----------------------------------------"
cfn-lint "$TEMPLATE_FILE" --format pretty
lint_result=$?
echo ""

if [ $lint_result -eq 0 ]; then
    echo "✓ cfn-lint validation passed"
else
    echo "✗ cfn-lint validation failed"
    exit 1
fi

# Check for common security issues
echo "Checking for security issues..."
echo "----------------------------------------"

security_issues=0

# Check for SSH open to internet
if grep -q "FromPort: 22" "$TEMPLATE_FILE" && grep -q "0.0.0.0/0" "$TEMPLATE_FILE"; then
    echo "⚠ WARNING: SSH (Port 22) may be open to 0.0.0.0/0"
    echo "  This is a security risk in production environments"
    security_issues=$((security_issues + 1))
fi

# Check for RDP open to internet
if grep -q "FromPort: 3389" "$TEMPLATE_FILE" && grep -q "0.0.0.0/0" "$TEMPLATE_FILE"; then
    echo "⚠ WARNING: RDP (Port 3389) may be open to 0.0.0.0/0"
    echo "  This is a security risk in production environments"
    security_issues=$((security_issues + 1))
fi

# Check for wildcard IAM policies
if grep -q "Action: \"\\*\"" "$TEMPLATE_FILE" || grep -q "Resource: \"\\*\"" "$TEMPLATE_FILE"; then
    echo "⚠ WARNING: Wildcard IAM permissions detected"
    echo "  Consider using least privilege principle"
    security_issues=$((security_issues + 1))
fi

echo ""

if [ $security_issues -eq 0 ]; then
    echo "✓ No obvious security issues detected"
else
    echo "⚠ Found $security_issues potential security issue(s)"
    echo "  Review warnings above before deploying"
fi

echo ""

# Validate with AWS CloudFormation (requires AWS CLI and credentials)
if command -v aws &> /dev/null; then
    echo "Running AWS CloudFormation validation..."
    echo "----------------------------------------"
    
    aws cloudformation validate-template --template-body file://"$TEMPLATE_FILE" > /dev/null 2>&1
    aws_result=$?
    
    if [ $aws_result -eq 0 ]; then
        echo "✓ AWS CloudFormation validation passed"
    else
        echo "✗ AWS CloudFormation validation failed"
        echo "  Check AWS credentials and template syntax"
    fi
    echo ""
else
    echo "AWS CLI not found - skipping AWS validation"
    echo ""
fi

echo "=========================================="
echo "Validation Complete"
echo "=========================================="
echo ""

if [ $lint_result -eq 0 ]; then
    echo "Template is valid and ready to deploy!"
    echo ""
    echo "To deploy, run:"
    echo "  ./scripts/deploy-infrastructure.sh"
else
    echo "Please fix validation errors before deploying"
    exit 1
fi
