# Dockerfile for URL Checker Application
# This Dockerfile containerizes a Python application that checks URL availability

# Use official Python 3.9 slim image as base
# Slim variant reduces image size while including essential packages
FROM python:3.9-slim

# Set metadata labels for the image
LABEL maintainer="AWS Labs Portfolio"
LABEL description="Containerized URL checker application"
LABEL version="1.0"

# Set working directory inside container
# All subsequent commands will run from this directory
WORKDIR /app

# Copy requirements file first (for better layer caching)
# If requirements don't change, this layer will be cached
COPY requirements.txt .

# Install Python dependencies
# --no-cache-dir reduces image size by not storing pip cache
# --upgrade ensures latest compatible versions
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
# This is done after installing dependencies for better caching
# If only code changes, dependencies layer is reused
COPY url_checker.py .

# Make the script executable (optional, but good practice)
RUN chmod +x url_checker.py

# Set the entrypoint to run the URL checker
# ENTRYPOINT defines the command that always runs
# Arguments passed to 'docker run' will be appended to this command
ENTRYPOINT ["python", "url_checker.py"]

# Default command (can be overridden)
# If no arguments provided to 'docker run', these URLs will be checked
CMD ["https://aws.amazon.com", "https://www.google.com"]

# Health check (optional, useful for orchestration)
# Checks if the container is healthy by running a simple command
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('https://aws.amazon.com', timeout=2)" || exit 1

# Expose metadata about the image
# Note: This application doesn't expose ports (it's a CLI tool)
# but in a web application, you would use: EXPOSE 8080

# Best practices applied:
# 1. Use slim base image to reduce size
# 2. Copy requirements before code for better caching
# 3. Use --no-cache-dir to reduce image size
# 4. Combine RUN commands to reduce layers
# 5. Set appropriate labels for documentation
# 6. Use ENTRYPOINT for the main command
# 7. Provide sensible defaults with CMD
