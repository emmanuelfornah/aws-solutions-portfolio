"""
Flask RESTful Web Service for Elastic Beanstalk Deployment

This application demonstrates a simple RESTful API built with Flask
and deployed to AWS Elastic Beanstalk. It provides a "Hello World"
endpoint that returns JSON responses.

Author: AWS Cloud Fundamentals Lab
"""

from flask import Flask, jsonify

# Create Flask application instance
# Note: Elastic Beanstalk expects the application object to be named 'application'
application = Flask(__name__)


@application.route('/')
def hello_world():
    """
    Root endpoint that returns a welcome message.
    
    Returns:
        JSON response with a greeting message
    """
    return jsonify({
        'message': 'Hello World from Flask on Elastic Beanstalk!',
        'status': 'success'
    })


@application.route('/health')
def health_check():
    """
    Health check endpoint for monitoring and load balancer checks.
    
    Returns:
        JSON response indicating service health status
    """
    return jsonify({
        'status': 'healthy',
        'service': 'flask-api'
    })


@application.route('/api/info')
def api_info():
    """
    API information endpoint providing service details.
    
    Returns:
        JSON response with API metadata
    """
    return jsonify({
        'api_name': 'Flask RESTful Service',
        'version': '1.0.0',
        'description': 'A simple RESTful API deployed on AWS Elastic Beanstalk',
        'endpoints': [
            {'path': '/', 'method': 'GET', 'description': 'Welcome message'},
            {'path': '/health', 'method': 'GET', 'description': 'Health check'},
            {'path': '/api/info', 'method': 'GET', 'description': 'API information'}
        ]
    })


if __name__ == '__main__':
    # Run the application in debug mode for local development
    # In production (Elastic Beanstalk), this is handled by the WSGI server
    application.run(debug=True, host='0.0.0.0', port=5000)
