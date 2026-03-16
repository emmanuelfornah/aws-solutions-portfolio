#!/bin/bash

# Run Unit Tests Script
# This script executes the pytest test suite with coverage reporting

set -e  # Exit on any error

echo "=========================================="
echo "Running Presidents App Unit Tests"
echo "=========================================="

# Check if we're in the correct directory
if [ ! -d "tests" ]; then
    echo "Error: tests/ directory not found!"
    echo "Please run this script from the project root directory."
    exit 1
fi

if [ ! -d "app" ]; then
    echo "Error: app/ directory not found!"
    echo "Please run this script from the project root directory."
    exit 1
fi

# Check if pytest is installed
if ! command -v pytest &> /dev/null; then
    echo "Error: pytest is not installed!"
    echo "Please run: pip install -r tests/requirements.txt"
    exit 1
fi

# Set Python path to include app directory
export PYTHONPATH="${PYTHONPATH}:$(pwd)/app"

echo ""
echo "Running pytest with coverage..."
echo "--------------------------------------"

# Run pytest with coverage
pytest tests/ \
    --verbose \
    --cov=app \
    --cov-report=term-missing \
    --cov-report=html \
    --cov-fail-under=80

TEST_EXIT_CODE=$?

echo ""
echo "--------------------------------------"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✓ All tests passed!"
    echo ""
    echo "Coverage report generated in htmlcov/index.html"
    echo "Open it in a browser to view detailed coverage."
else
    echo "✗ Tests failed!"
    echo ""
    echo "Please review the test output above to identify failures."
    echo "Common issues:"
    echo "  - Age calculation logic needs to use relativedelta"
    echo "  - Expected values in tests need to be updated"
    echo "  - Missing dependencies"
    exit 1
fi

# Optional: Run linting
echo ""
echo "Running code quality checks..."
echo "--------------------------------------"

if command -v pylint &> /dev/null; then
    pylint app/*.py --disable=C0111,R0903 || true
    echo "✓ Linting complete"
else
    echo "⚠ pylint not installed, skipping linting"
fi

echo ""
echo "=========================================="
echo "Test Execution Complete!"
echo "=========================================="
echo ""

exit $TEST_EXIT_CODE
