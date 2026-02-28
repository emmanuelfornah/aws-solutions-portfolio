#!/bin/bash

# Install Dependencies Script
# This script installs both application and testing dependencies for the Presidents application

set -e  # Exit on any error

echo "=========================================="
echo "Installing Presidents App Dependencies"
echo "=========================================="

# Check if we're in the correct directory
if [ ! -f "app/requirements.txt" ]; then
    echo "Error: app/requirements.txt not found!"
    echo "Please run this script from the project root directory."
    exit 1
fi

if [ ! -f "tests/requirements.txt" ]; then
    echo "Error: tests/requirements.txt not found!"
    echo "Please run this script from the project root directory."
    exit 1
fi

# Install application dependencies
echo ""
echo "Installing application dependencies..."
echo "--------------------------------------"
pip install -r app/requirements.txt

if [ $? -eq 0 ]; then
    echo "✓ Application dependencies installed successfully"
else
    echo "✗ Failed to install application dependencies"
    exit 1
fi

# Install testing dependencies
echo ""
echo "Installing testing dependencies..."
echo "--------------------------------------"
pip install -r tests/requirements.txt

if [ $? -eq 0 ]; then
    echo "✓ Testing dependencies installed successfully"
else
    echo "✗ Failed to install testing dependencies"
    exit 1
fi

# Verify installations
echo ""
echo "Verifying installations..."
echo "--------------------------------------"

# Check Flask
python3 -c "import flask; print(f'Flask version: {flask.__version__}')" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✓ Flask installed"
else
    echo "✗ Flask not found"
fi

# Check boto3
python3 -c "import boto3; print(f'boto3 version: {boto3.__version__}')" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✓ boto3 installed"
else
    echo "✗ boto3 not found"
fi

# Check pytest
python3 -c "import pytest; print(f'pytest version: {pytest.__version__}')" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✓ pytest installed"
else
    echo "✗ pytest not found"
fi

# Check dateutil
python3 -c "import dateutil; print(f'python-dateutil installed')" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✓ python-dateutil installed"
else
    echo "✗ python-dateutil not found"
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Run unit tests: ./run_tests.sh"
echo "2. Fix the age calculation bug in app/presidents.py"
echo "3. Update unit tests in tests/test_handler.py"
echo "4. Push changes to CodeCommit: ./scripts/git-workflow.sh"
echo ""
