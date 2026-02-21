#!/bin/bash
# Install Python dependencies from requirements.txt
# This script installs the requests and tabulate libraries

set -e  # Exit on any error

echo "=========================================="
echo "Installing Python dependencies"
echo "=========================================="

# Navigate to application directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/../application"

cd "$APP_DIR"

# Check if requirements.txt exists
if [ ! -f "requirements.txt" ]; then
    echo "Error: requirements.txt not found in $APP_DIR"
    exit 1
fi

echo "Installing packages from requirements.txt..."
echo ""

# Install dependencies using pip
pip3 install --user -r requirements.txt

echo ""
echo "=========================================="
echo "Dependencies installed successfully!"
echo "=========================================="
echo ""
echo "Installed packages:"
pip3 list | grep -E "requests|tabulate"
