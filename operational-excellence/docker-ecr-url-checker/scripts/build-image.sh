#!/bin/bash

################################################################################
# Docker Image Build Script
#
# This script builds a Docker image from the Dockerfile in the current directory.
# It tags the image as 'url-checker:latest' for easy reference.
#
# Usage:
#   cd application/
#   ../scripts/build-image.sh
#
# The script will:
# 1. Verify Dockerfile exists
# 2. Build the Docker image
# 3. Display build progress
# 4. List the created image
################################################################################

set -e  # Exit on any error

echo "========================================"
echo "Building Docker Image"
echo "========================================"
echo ""

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    echo "Error: Dockerfile not found in current directory."
    echo "Please run this script from the application/ directory:"
    echo "  cd application/"
    echo "  ../scripts/build-image.sh"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running or you don't have permission to access it."
    echo "Try running: newgrp docker"
    exit 1
fi

# Define image name and tag
IMAGE_NAME="url-checker"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

echo "Building image: $FULL_IMAGE_NAME"
echo ""

# Build the Docker image
docker build -t $FULL_IMAGE_NAME .

echo ""
echo "========================================"
echo "Build Complete!"
echo "========================================"
echo ""

# Display the created image
echo "Image details:"
docker images $IMAGE_NAME

echo ""
echo "To run the container:"
echo "  docker run $FULL_IMAGE_NAME https://example.com"
echo ""
echo "To run interactively:"
echo "  docker run -it $FULL_IMAGE_NAME /bin/bash"
echo ""
echo "To test with custom URLs:"
echo "  docker run $FULL_IMAGE_NAME https://aws.amazon.com https://google.com"
echo ""
