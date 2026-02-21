"""
Flask Web Application for AWS Elastic Beanstalk
Entry point must be named 'application.py' and Flask app must be named 'application'
"""

from flask import Flask, render_template_string

# Create Flask application
# IMPORTANT: Must be named 'application' for Elastic Beanstalk
application = Flask(__name__)

# Home route
@application.route('/')
def home():
    """Home page with welcome message"""
    html = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Flask on AWS Elastic Beanstalk</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                max-width: 800px;
                margin: 50px auto;
                padding: 20px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
            }
            .container {
                background: rgba(255, 255, 255, 0.1);
                padding: 40px;
                border-radius: 10px;
                backdrop-filter: blur(10px);
                box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            }
            h1 {
                font-size: 2.5em;
                margin-bottom: 20px;
            }
            .badge {
                display: inline-block;
                background: rgba(255, 255, 255, 0.2);
                padding: 5px 15px;
                border-radius: 20px;
                margin: 5px;
                font-size: 0.9em;
            }
            .info {
                margin-top: 30px;
                padding: 20px;
                background: rgba(255, 255, 255, 0.1);
                border-radius: 5px;
            }
            a {
                color: #ffd700;
                text-decoration: none;
            }
            a:hover {
                text-decoration: underline;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Flask on AWS Elastic Beanstalk</h1>
            <p>Welcome! This Python Flask application is running on AWS Elastic Beanstalk.</p>
            
            <div style="margin: 30px 0;">
                <span class="badge">Python</span>
                <span class="badge">Flask</span>
                <span class="badge">AWS Elastic Beanstalk</span>
                <span class="badge">Auto Scaling</span>
                <span class="badge">Load Balanced</span>
            </div>
            
            <div class="info">
                <h3>✨ Features</h3>
                <ul>
                    <li>Automated deployment with EB CLI</li>
                    <li>Load balancing across multiple instances</li>
                    <li>Auto-scaling based on traffic</li>
                    <li>Integrated CloudWatch monitoring</li>
                    <li>Zero-downtime deployments</li>
                </ul>
            </div>
            
            <div class="info">
                <h3>📚 Learn More</h3>
                <p>Check out the <a href="/about">About</a> page for more information.</p>
            </div>
        </div>
    </body>
    </html>
    """
    return render_template_string(html)

# About route
@application.route('/about')
def about():
    """About page with lab information"""
    html = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>About - Flask on AWS</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                max-width: 800px;
                margin: 50px auto;
                padding: 20px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
            }
            .container {
                background: rgba(255, 255, 255, 0.1);
                padding: 40px;
                border-radius: 10px;
                backdrop-filter: blur(10px);
                box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            }
            h1 { font-size: 2.5em; margin-bottom: 20px; }
            h2 { font-size: 1.8em; margin-top: 30px; }
            .section {
                margin: 20px 0;
                padding: 20px;
                background: rgba(255, 255, 255, 0.1);
                border-radius: 5px;
            }
            a { color: #ffd700; text-decoration: none; }
            a:hover { text-decoration: underline; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>📖 About This Lab</h1>
            
            <div class="section">
                <h2>🎯 Lab Overview</h2>
                <p>This Flask application demonstrates deployment on AWS Elastic Beanstalk, 
                showcasing platform-as-a-service (PaaS) capabilities for Python web applications.</p>
            </div>
            
            <div class="section">
                <h2>🏗️ Architecture</h2>
                <ul>
                    <li><strong>Elastic Beanstalk:</strong> Managed application platform</li>
                    <li><strong>EC2 Instances:</strong> Auto-scaled compute resources</li>
                    <li><strong>Load Balancer:</strong> Distributes traffic across instances</li>
                    <li><strong>CloudWatch:</strong> Monitoring and logging</li>
                    <li><strong>S3:</strong> Application version storage</li>
                </ul>
            </div>
            
            <div class="section">
                <h2>💡 Key Skills</h2>
                <ul>
                    <li>Python Flask web development</li>
                    <li>AWS Elastic Beanstalk deployment</li>
                    <li>EB CLI automation</li>
                    <li>Auto-scaling configuration</li>
                    <li>Load balancing setup</li>
                    <li>Application monitoring</li>
                </ul>
            </div>
            
            <p style="margin-top: 30px;">
                <a href="/">← Back to Home</a>
            </p>
        </div>
    </body>
    </html>
    """
    return render_template_string(html)

# Health check endpoint for load balancer
@application.route('/health')
def health():
    """Health check endpoint for ELB"""
    return {'status': 'healthy', 'service': 'flask-app'}, 200

# Run the application
if __name__ == '__main__':
    # Run on port 5000 for local development
    # Elastic Beanstalk will use port 8000 in production
    application.run(host='0.0.0.0', port=5000, debug=True)
