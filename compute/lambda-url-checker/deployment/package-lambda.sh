#!/bin/bash

# Lambda Deployment Package Creation Script
# This script creates a deployment package for the URL Checker Lambda function
# including the application code and all required dependencies.

set -e  # Exit on any error

echo "=========================================="
echo "Lambda URL Checker - Package Creation"
echo "=========================================="

# Configuration
FUNCTION_NAME="URLChecker"
PACKAGE_DIR="package"
ZIP_FILE="lambda-deployment-package.zip"

# Clean up previous builds
echo "Cleaning up previous builds..."
rm -rf $PACKAGE_DIR
rm -f $ZIP_FILE

# Create package directory
echo "Creating package directory..."
mkdir -p $PACKAGE_DIR

# Install dependencies to package directory
echo "Installing Python dependencies..."
pip install -r ../application/requirements.txt -t $PACKAGE_DIR

# Copy application code to package directory
echo "Copying application code..."
cp ../application/app.py $PACKAGE_DIR/

# Create deployment ZIP file
echo "Creating deployment package..."
cd $PACKAGE_DIR
zip -r ../$ZIP_FILE . -q
cd ..

# Display package information
echo ""
echo "=========================================="
echo "Package created successfully!"
echo "=========================================="
echo "Package file: $ZIP_FILE"
echo "Package size: $(du -h $ZIP_FILE | cut -f1)"
echo ""
echo "Package contents:"
unzip -l $ZIP_FILE | head -20

# Clean up package directory
echo ""
echo "Cleaning up temporary files..."
rm -rf $PACKAGE_DIR

echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo "1. Upload $ZIP_FILE to Lambda via AWS Console, or"
echo "2. Run ./deploy-cli.sh to deploy using AWS CLI"
echo ""
