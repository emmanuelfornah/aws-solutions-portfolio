# WordPress on EC2 with Network Load Balancer

## 🎯 Lab Overview

Deployed a production-ready WordPress website on Amazon EC2 with Apache web server, MariaDB database, and Network Load Balancer. This lab demonstrates full-stack deployment skills, from infrastructure setup to application configuration.

## 🏗️ Architecture

```
Internet
    ↓
Network Load Balancer
    ↓
VPC (Custom)
    ↓
EC2 Instance (Amazon Linux 2023)
    ├── Apache HTTP Server (httpd)
    ├── PHP 8.2
    ├── MariaDB 10.5
    └── WordPress (Latest)
```

**AWS Services Used:**
- Amazon VPC (Virtual Private Cloud)
- Amazon EC2 (Elastic Compute Cloud)
- Network Load Balancer (NLB)
- Amazon Linux 2023

## 💡 What I Built

A fully functional WordPress website with:
- Custom VPC and networking configuration
- Apache web server with PHP support
- MariaDB database with secure user configuration
- WordPress installation with proper file permissions
- SSL/TLS certificate generation capability
- Load balancer for high availability

## 🎓 Key Learnings

### Infrastructure & Networking
- Designed and deployed custom VPC architecture
- Configured Network Load Balancer for traffic distribution
- Understood EC2 instance types and sizing considerations

### Web Server Configuration
- Installed and configured Apache HTTP Server on Amazon Linux 2023
- Set up PHP 8.2 with required extensions for WordPress
- Configured virtual hosts and document root permissions
- Generated SSL certificates for HTTPS support

### Database Management
- Installed and secured MariaDB database server
- Created databases and users with proper privileges
- Configured WordPress database connection securely
- Implemented database security best practices

### Application Deployment
- Deployed WordPress from source
- Configured wp-config.php with database credentials
- Set proper file ownership and permissions (apache:apache)
- Troubleshot common WordPress installation issues

### Security Best Practices
- Configured firewall rules and security groups
- Set restrictive file permissions (755 for directories, 644 for files)
- Secured database with strong passwords
- Prepared for SSL/TLS certificate implementation

## 📋 Setup Instructions

### 1. Environment Setup
Run the environment setup script to install all required packages:
```bash
./scripts/setup-environment.sh
```

### 2. Database Configuration
Configure MariaDB and create the WordPress database:
```bash
./scripts/configure-database.sh
```

### 3. WordPress Installation
Download and configure WordPress:
```bash
./scripts/configure-wordpress.sh
```

### 4. Set Permissions
Apply proper file permissions:
```bash
./scripts/configure-permissions.sh
```

### 5. Access WordPress
Navigate to your EC2 instance's public IP or load balancer DNS to complete the WordPress installation wizard.

## 🔧 Configuration Files

- **wp-config-sample.php**: WordPress database configuration template
- **httpd.conf-snippet**: Apache virtual host configuration example

## 🚀 Skills Demonstrated for Hiring

- **Linux System Administration**: Package management, service configuration, file permissions
- **Web Server Management**: Apache installation, configuration, and troubleshooting
- **Database Administration**: MariaDB setup, user management, security
- **Application Deployment**: WordPress installation and configuration
- **AWS Infrastructure**: VPC design, EC2 management, load balancing
- **Security Mindset**: Proper permissions, secure credentials, SSL preparation
- **Documentation**: Clear scripts and configuration management

## 🔍 Real-World Applications

This lab demonstrates skills directly applicable to:
- Deploying and managing web applications on AWS
- Setting up LAMP/LEMP stacks for various applications
- Configuring load balancers for high availability
- Managing databases in cloud environments
- Implementing security best practices
- Troubleshooting production web server issues

## 📝 Notes

This deployment uses a single EC2 instance for demonstration purposes. In production, consider:
- Multi-AZ deployment for high availability
- RDS for managed database service
- Auto Scaling groups for elasticity
- CloudFront CDN for content delivery
- S3 for media storage
- Automated backups and disaster recovery
