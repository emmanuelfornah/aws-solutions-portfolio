# Deploying a Flask Application to AWS Elastic Beanstalk

## Overview

This lab demonstrates deploying a Python Flask RESTful web service to AWS Elastic Beanstalk, a fully managed Platform-as-a-Service (PaaS) that automatically handles infrastructure provisioning, load balancing, auto-scaling, and application health monitoring. The project showcases modern cloud-native application deployment with zero infrastructure management overhead.

**Lab Type**: Hands-on deployment and configuration  
**Difficulty**: Intermediate  
**Estimated Time**: 45-60 minutes

## AWS Services Used

- **AWS Elastic Beanstalk** - Platform-as-a-Service for application deployment and management
- **Amazon EC2** - Compute instances running the Flask application
- **Auto Scaling** - Automatic capacity adjustment based on demand
- **Elastic Load Balancing (ALB)** - Traffic distribution across healthy instances
- **Amazon S3** - Storage for application source code and deployment versions
- **Amazon CloudWatch** - Monitoring, logging, and alarming
- **AWS CloudFormation** - Infrastructure-as-Code for environment management

## Key Technologies

- **Python 3.9** - Programming language and runtime
- **Flask 2.3.3** - Lightweight web framework for RESTful APIs
- **Gunicorn** - WSGI HTTP server (managed by Elastic Beanstalk)
- **EB CLI** - Command-line interface for Elastic Beanstalk operations
- **AWS Code Editor** - Cloud-based IDE for development

## Architecture Overview

The application runs on a highly available, auto-scaling architecture:

```
Internet → Application Load Balancer → EC2 Instances (Flask App)
                                      ↓
                                Auto Scaling Group
                                      ↓
                                CloudWatch Monitoring
```

**Key Components**:
- **Application Load Balancer**: Distributes HTTP traffic across multiple EC2 instances
- **Auto Scaling Group**: Maintains 1-4 instances based on CPU utilization
- **EC2 Instances**: Run Flask application via Gunicorn WSGI server
- **S3 Bucket**: Stores application versions for deployment and rollback
- **CloudWatch**: Collects metrics, logs, and triggers scaling actions
- **CloudFormation Stack**: Manages all infrastructure resources as code

For detailed architecture information, see [architecture.md](./architecture.md).

## Objectives

By completing this lab, you will:

1. ✅ Create a Flask RESTful web service with multiple API endpoints
2. ✅ Configure Python dependencies using requirements.txt
3. ✅ Initialize and configure an Elastic Beanstalk application using EB CLI
4. ✅ Deploy a Flask application to a managed EB environment
5. ✅ Understand Elastic Beanstalk's automatic infrastructure provisioning
6. ✅ Monitor application health and performance using CloudWatch
7. ✅ Test auto-scaling behavior and load balancing
8. ✅ Manage application versions and perform rollbacks
9. ✅ Configure environment properties and deployment policies
10. ✅ Implement health check endpoints for load balancer monitoring

## Key Learnings

### Platform-as-a-Service (PaaS) Benefits
- **Zero Infrastructure Management**: No need to manually configure EC2, load balancers, or auto-scaling
- **Built-in Best Practices**: HA, monitoring, and security configured automatically
- **Developer Productivity**: Focus on application code rather than infrastructure
- **Rapid Deployment**: From code to production in minutes

### Elastic Beanstalk Capabilities
- **Automatic Provisioning**: Creates EC2 instances, load balancers, security groups, and CloudWatch alarms
- **Managed Updates**: Platform and OS patches applied automatically
- **Rolling Deployments**: Zero-downtime updates with automatic rollback on failure
- **Environment Cloning**: Easily create staging/production environments
- **Multi-Language Support**: Python, Node.js, Java, .NET, PHP, Ruby, Go, Docker

### Flask RESTful API Design
- **Lightweight Framework**: Minimal boilerplate for building APIs
- **JSON Responses**: Native support for RESTful JSON APIs
- **Route Decorators**: Clean, Pythonic routing syntax
- **WSGI Compatibility**: Works with production servers like Gunicorn
- **Health Check Endpoints**: Essential for load balancer health monitoring

### Auto Scaling and High Availability
- **Horizontal Scaling**: Automatically adds/removes instances based on metrics
- **Multi-AZ Deployment**: Instances distributed across availability zones
- **Health Monitoring**: Unhealthy instances automatically replaced
- **Load Distribution**: Traffic routed only to healthy instances
- **Cost Optimization**: Scales down during low traffic periods

### CloudWatch Integration
- **Application Metrics**: CPU, memory, network, request count, latency
- **Custom Metrics**: Can publish application-specific metrics
- **Log Aggregation**: Centralized logging from all instances
- **Alarms**: Proactive notifications for anomalies
- **Dashboards**: Real-time visualization of environment health

### Deployment Best Practices
- **Version Control**: S3 stores all deployment versions for rollback
- **Environment Variables**: Configuration without code changes
- **Secrets Management**: Use AWS Secrets Manager for sensitive data
- **Blue/Green Deployments**: Swap environment URLs for instant rollback
- **Configuration Files**: `.ebextensions` for advanced customization

## Setup Instructions

### Prerequisites

- AWS account with appropriate permissions
- AWS CLI configured with credentials
- Python 3.9+ installed locally
- EB CLI installed (`pip install awsebcli`)
- Basic understanding of Python and Flask

### Step 1: Create Flask Application

Create a new directory and set up the Flask application:

```bash
# Create project directory
mkdir flask-eb-app
cd flask-eb-app

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install Flask
pip install Flask==2.3.3

# Create application.py (see application/ directory)
# Create requirements.txt (see application/ directory)
```

**Important**: Elastic Beanstalk expects the Flask application object to be named `application` (not `app`).

### Step 2: Initialize Elastic Beanstalk

Initialize the EB application in your project directory:

```bash
# Initialize EB application
eb init -p python-3.9 flask-api --region us-east-1

# This creates .elasticbeanstalk/ directory with configuration
```

**Configuration Options**:
- Platform: Python 3.9 running on 64bit Amazon Linux 2
- Application name: flask-api
- Region: us-east-1 (or your preferred region)
- SSH keypair: Optional, for debugging access

### Step 3: Create Elastic Beanstalk Environment

Create and deploy the environment:

```bash
# Create environment with t2.micro instance (Free Tier)
eb create flask-api-env --instance-type t2.micro

# This process takes 5-10 minutes and:
# - Creates CloudFormation stack
# - Provisions EC2 instances
# - Configures load balancer
# - Sets up auto-scaling
# - Deploys application
# - Runs health checks
```

### Step 4: Deploy Application

Deploy code changes to the environment:

```bash
# Deploy current code
eb deploy

# Open application in browser
eb open

# Check environment status
eb status

# View recent logs
eb logs
```

### Step 5: Test API Endpoints

Test the deployed Flask API:

```bash
# Get environment URL
eb status | grep CNAME

# Test endpoints
curl http://[your-env-url].elasticbeanstalk.com/
curl http://[your-env-url].elasticbeanstalk.com/health
curl http://[your-env-url].elasticbeanstalk.com/api/info
```

**Expected Responses**:
- `/` - Welcome message JSON
- `/health` - Health status JSON
- `/api/info` - API metadata JSON

### Step 6: Monitor Environment

Monitor the application using AWS Console:

1. Navigate to Elastic Beanstalk console
2. Select your environment
3. View **Dashboard** for health overview
4. Check **Monitoring** tab for CloudWatch metrics
5. Review **Logs** for application and server logs
6. Inspect **Configuration** for environment settings

**Key Metrics to Monitor**:
- Environment Health (Green/Yellow/Red)
- CPU Utilization
- Request Count
- Latency (p50, p90, p99)
- HTTP 4xx/5xx errors

### Step 7: Configure Auto Scaling (Optional)

Adjust auto-scaling settings:

```bash
# Edit configuration
eb config

# Or use console:
# Configuration → Capacity → Auto Scaling Group
# Set min instances: 1, max instances: 4
# Scaling triggers: CPU > 70% for 5 minutes
```

### Step 8: Test Scaling Behavior (Optional)

Simulate load to trigger auto-scaling:

```bash
# Install Apache Bench
sudo apt-get install apache2-utils  # Ubuntu/Debian
brew install httpd  # macOS

# Generate load (1000 requests, 10 concurrent)
ab -n 1000 -c 10 http://[your-env-url].elasticbeanstalk.com/

# Monitor scaling in CloudWatch or EB console
# New instances launch when CPU > 70%
```

### Step 9: Manage Application Versions

View and manage deployment versions:

```bash
# List application versions
eb appversion

# Deploy specific version
eb deploy --version [version-label]

# Delete old versions
eb appversion delete [version-label]
```

### Step 10: Clean Up Resources

Terminate the environment to avoid charges:

```bash
# Terminate environment (deletes all resources)
eb terminate flask-api-env

# Confirm termination when prompted
```

**Resources Deleted**:
- EC2 instances
- Load balancer
- Auto Scaling group
- Security groups
- CloudWatch alarms
- CloudFormation stack

**Resources Retained**:
- S3 bucket with application versions (manual cleanup required)
- EB application definition (can be deleted via console)

## Application Code Explanation

### application.py

The Flask application provides three RESTful endpoints:

```python
from flask import Flask, jsonify

# Elastic Beanstalk requires 'application' object name
application = Flask(__name__)

@application.route('/')
def hello_world():
    """Root endpoint - welcome message"""
    return jsonify({
        'message': 'Hello World from Flask on Elastic Beanstalk!',
        'status': 'success'
    })

@application.route('/health')
def health_check():
    """Health check for load balancer monitoring"""
    return jsonify({
        'status': 'healthy',
        'service': 'flask-api'
    })

@application.route('/api/info')
def api_info():
    """API metadata and available endpoints"""
    return jsonify({
        'api_name': 'Flask RESTful Service',
        'version': '1.0.0',
        'endpoints': [...]
    })
```

**Key Design Decisions**:
- **Object Name**: `application` (not `app`) - EB convention
- **JSON Responses**: All endpoints return JSON via `jsonify()`
- **Health Endpoint**: `/health` used by load balancer for health checks
- **Stateless**: No session management, enables horizontal scaling
- **Error Handling**: Flask's default error handlers (can be customized)

### requirements.txt

Python dependencies installed during deployment:

```
Flask==2.3.3          # Web framework
Werkzeug==2.3.7       # WSGI utility library
click==8.1.7          # CLI creation kit
Jinja2==3.1.2         # Templating engine
MarkupSafe==2.1.3     # String handling
itsdangerous==2.1.2   # Data signing
```

**Dependency Management**:
- Pinned versions ensure reproducible deployments
- EB automatically runs `pip install -r requirements.txt`
- Virtual environment created automatically on each instance

### .ebignore

Excludes files from deployment bundle:

```
venv/                 # Virtual environment (recreated on instance)
__pycache__/          # Python cache files
.env                  # Environment variables (use EB config instead)
.git/                 # Git repository
README.md             # Documentation
```

**Benefits**:
- Smaller deployment bundles (faster uploads)
- Excludes sensitive files (.env, .pem)
- Reduces deployment time

## Scripts and Configurations

### configs/eb.config

Contains EB CLI commands and configuration examples:

- Environment initialization commands
- Deployment commands
- Monitoring and logging commands
- Auto-scaling configuration
- Load balancer settings
- Security configuration

See [configs/eb.config](./configs/eb.config) for complete reference.

## Troubleshooting

### Common Issues

**Issue**: Environment creation fails  
**Solution**: Check IAM permissions, ensure service roles exist, verify region availability

**Issue**: Application shows 502 Bad Gateway  
**Solution**: Check application logs (`eb logs`), verify `application` object name, check Python version compatibility

**Issue**: Health check failing  
**Solution**: Ensure `/health` endpoint returns 200 status, check security group rules, verify instance connectivity

**Issue**: Deployment takes too long  
**Solution**: Reduce deployment bundle size with `.ebignore`, use smaller instance types for testing

**Issue**: Auto-scaling not working  
**Solution**: Verify CloudWatch alarms exist, check scaling policies, ensure sufficient capacity limits

### Debugging Commands

```bash
# View detailed logs
eb logs --all

# SSH into instance (requires keypair)
eb ssh

# Check environment health
eb health --refresh

# View recent events
eb events

# Validate configuration
eb config --display
```

### Log Locations on EC2 Instance

```
/var/log/eb-engine.log              # EB deployment logs
/var/log/nginx/access.log           # Web server access logs
/var/log/nginx/error.log            # Web server error logs
/var/app/current/                   # Application directory
/opt/python/log/                    # Python application logs
```

## Cost Considerations

**Free Tier Eligible**:
- t2.micro instance: 750 hours/month
- Application Load Balancer: 750 hours/month (first year)
- CloudWatch: 10 metrics, 10 alarms, 5GB logs

**Ongoing Costs** (after Free Tier):
- EC2 instances: ~$0.0116/hour per t2.micro
- Load Balancer: ~$0.0225/hour + $0.008/LCU
- Data transfer: $0.09/GB outbound
- S3 storage: $0.023/GB/month

**Cost Optimization Tips**:
- Use t2.micro for development/testing
- Set appropriate auto-scaling limits
- Delete old application versions from S3
- Terminate environments when not in use
- Use Reserved Instances for production workloads

## Next Steps

### Enhancements

1. **Add Database**: Integrate RDS PostgreSQL or DynamoDB
2. **Implement Authentication**: Add JWT or OAuth2
3. **Enable HTTPS**: Configure SSL certificate via ACM
4. **Custom Domain**: Map Route 53 domain to EB environment
5. **CI/CD Pipeline**: Automate deployments with CodePipeline
6. **Monitoring**: Add AWS X-Ray for distributed tracing
7. **Caching**: Integrate ElastiCache for Redis
8. **API Gateway**: Add rate limiting and API keys

### Related Labs

- **WordPress on EC2**: Manual EC2 instance configuration
- **Lambda Functions**: Serverless alternative to EB
- **ECS/Fargate**: Container-based deployment
- **API Gateway + Lambda**: Fully serverless REST API

## Certification Alignment

This lab aligns with the following AWS certification topics:

**AWS Certified Solutions Architect - Associate**:
- Domain 1: Design Resilient Architectures (Auto Scaling, Load Balancing)
- Domain 2: Design High-Performing Architectures (Elastic Beanstalk, CloudWatch)
- Domain 3: Design Secure Applications (Security Groups, IAM Roles)

**AWS Certified Developer - Associate**:
- Domain 1: Deployment (Elastic Beanstalk, EB CLI)
- Domain 2: Security (IAM, Security Groups)
- Domain 3: Development with AWS Services (CloudWatch, S3)
- Domain 4: Refactoring (PaaS migration strategies)

## Resources

- [AWS Elastic Beanstalk Documentation](https://docs.aws.amazon.com/elasticbeanstalk/)
- [EB CLI Command Reference](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3.html)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Python on Elastic Beanstalk](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create-deploy-python-apps.html)
- [Auto Scaling Best Practices](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-best-practices.html)

## Tags

`AWS` `Elastic-Beanstalk` `PaaS` `Python` `Flask` `RESTful-API` `Auto-Scaling` `Load-Balancing` `CloudWatch` `EC2` `S3` `CloudFormation` `DevOps` `Deployment` `High-Availability` `Monitoring`

---

**Lab Completed**: AWS Cloud Fundamentals  
**Domain**: Compute  
**Complexity**: Intermediate  
**Last Updated**: 2024
