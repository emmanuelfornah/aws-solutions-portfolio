# Flask Web Application on AWS Elastic Beanstalk

## 🎯 Lab Overview

Deployed a Python Flask web application using AWS Elastic Beanstalk, demonstrating platform-as-a-service (PaaS) deployment with automated infrastructure management, load balancing, and auto-scaling capabilities.

## 🏗️ Architecture

```
Internet
    ↓
Elastic Load Balancer (ELB)
    ↓
Auto Scaling Group
    ├── EC2 Instance 1 (Flask App)
    ├── EC2 Instance 2 (Flask App)
    └── EC2 Instance N (Flask App)
    ↓
CloudWatch (Monitoring & Logs)
    ↓
S3 (Application Versions)
```

**AWS Services Used:**
- AWS Elastic Beanstalk
- Amazon EC2 (managed by EB)
- Elastic Load Balancer (Application Load Balancer)
- Auto Scaling
- Amazon S3 (application version storage)
- Amazon CloudWatch (monitoring and logs)

## 💡 What I Built

A production-ready Flask web application with:
- Automated deployment using EB CLI
- Load balancing across multiple instances
- Auto-scaling based on traffic
- Environment configuration management
- Application version control
- Integrated monitoring and logging

## 🎓 Key Learnings

### Platform-as-a-Service (PaaS)
- Understood when to use managed services vs. manual EC2 deployment
- Leveraged Elastic Beanstalk for automated infrastructure management
- Compared PaaS benefits: faster deployment, reduced operational overhead
- Learned trade-offs between control and convenience

### Python Application Deployment
- Created a Flask web application with proper structure
- Configured virtual environments and dependency management
- Used requirements.txt for reproducible deployments
- Named entry point as `application.py` per EB requirements

### EB CLI & Configuration
- Installed and configured AWS EB CLI
- Initialized Elastic Beanstalk applications and environments
- Deployed applications using `eb create` and `eb deploy`
- Managed environment variables and configuration files

### Infrastructure Automation
- Used `.ebextensions` for custom configuration
- Configured `.ebignore` to exclude unnecessary files
- Implemented environment-specific settings
- Automated scaling policies and health checks

### Monitoring & Troubleshooting
- Accessed application logs using `eb logs`
- Monitored application health in EB console
- Used CloudWatch for metrics and alarms
- Debugged deployment issues with EB events

## 📋 Setup Instructions

### Prerequisites
```bash
# Install Python 3 and pip
python3 --version

# Install virtualenv
pip install virtualenv

# Install EB CLI
pip install awsebcli
```

### 1. Create Virtual Environment
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Test Locally
```bash
python application.py
# Visit http://localhost:5000
```

### 4. Initialize Elastic Beanstalk
```bash
eb init -p python-3.11 flask-app --region us-east-1
```

### 5. Create Environment and Deploy
```bash
eb create flask-env
```

### 6. Open Application
```bash
eb open
```

### 7. View Logs
```bash
eb logs
```

### 8. Deploy Updates
```bash
eb deploy
```

### 9. Terminate Environment (when done)
```bash
eb terminate flask-env
```

## 📁 Project Structure

```
02-flask-elastic-beanstalk/
├── application.py          # Flask application entry point
├── requirements.txt        # Python dependencies
├── .ebignore              # Files to exclude from deployment
└── .ebextensions/         # EB configuration
    └── eb.config          # Custom environment settings
```

## 🔧 Configuration Files

- **application.py**: Flask web application with routes and logic
- **requirements.txt**: Python package dependencies (Flask, etc.)
- **.ebignore**: Excludes virtual environment and cache files from deployment
- **.ebextensions/eb.config**: Custom EB environment configuration

## 🚀 Skills Demonstrated for Hiring

- **Python Development**: Flask framework, web application structure
- **AWS PaaS**: Elastic Beanstalk deployment and management
- **DevOps Practices**: CLI automation, version control, deployment pipelines
- **Infrastructure as Code**: Configuration files, automated provisioning
- **Scalability**: Auto-scaling groups, load balancing
- **Monitoring**: CloudWatch integration, log analysis
- **Troubleshooting**: Debugging deployment issues, reading logs
- **Cost Optimization**: Understanding when to use managed services

## 🔍 Real-World Applications

This lab demonstrates skills directly applicable to:
- Deploying Python web applications in production
- Using AWS managed services for faster time-to-market
- Implementing auto-scaling for variable traffic
- Managing application versions and rollbacks
- Setting up CI/CD pipelines with EB
- Monitoring application health and performance
- Reducing operational overhead with PaaS

## 📝 Key Differences: EC2 vs. Elastic Beanstalk

| Aspect | EC2 (WordPress Lab) | Elastic Beanstalk (Flask Lab) |
|--------|---------------------|-------------------------------|
| **Control** | Full control over OS and configuration | Managed platform, less control |
| **Setup Time** | Manual installation and configuration | Automated with EB CLI |
| **Scaling** | Manual or custom Auto Scaling setup | Built-in auto-scaling |
| **Monitoring** | Manual CloudWatch setup | Integrated monitoring |
| **Updates** | Manual patching and updates | Managed platform updates |
| **Use Case** | Custom requirements, full control needed | Standard web apps, faster deployment |

## 💡 When to Use Elastic Beanstalk

Choose Elastic Beanstalk when:
- You want to focus on application code, not infrastructure
- Your application fits standard platform patterns
- You need quick deployment and scaling
- You want integrated monitoring and logging
- You prefer managed platform updates

Choose EC2 when:
- You need full control over the environment
- You have custom OS or software requirements
- You're running non-standard applications
- You need specific security configurations

## 📈 Production Considerations

For production deployments, consider:
- **Environment Types**: Use load-balanced environments for production
- **Database**: Integrate with RDS for persistent data storage
- **HTTPS**: Configure SSL/TLS certificates via EB console
- **Custom Domain**: Use Route 53 for DNS management
- **CI/CD**: Integrate with CodePipeline for automated deployments
- **Monitoring**: Set up CloudWatch alarms for critical metrics
- **Backups**: Configure automated snapshots and version retention
