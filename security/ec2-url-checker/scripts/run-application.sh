#!/bin/bash
# Run the URL Checker application with sample URLs
# This script demonstrates typical application invocation

set -e  # Exit on any error

echo "=========================================="
echo "Running URL Checker Application"
echo "=========================================="

# Navigate to application directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/../application"

cd "$APP_DIR"

# Check if url_checker.py exists
if [ ! -f "url_checker.py" ]; then
    echo "Error: url_checker.py not found in $APP_DIR"
    exit 1
fi

# Sample URLs to check
URLS=(
    "https://aws.amazon.com"
    "https://github.com"
    "https://www.python.org"
    "https://example.com"
)

echo "Checking sample URLs..."
echo ""

# Run the URL checker with sample URLs
python3 url_checker.py "${URLS[@]}"

echo ""
echo "=========================================="
echo "Application execution complete!"
echo "=========================================="
echo ""
echo "To check custom URLs, run:"
echo "  python3 url_checker.py <url1> <url2> ..."
