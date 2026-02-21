# Hosting a WordPress Blog on EC2

## Overview

This lab demonstrates deploying a production-ready WordPress blog on Amazon EC2 with a complete LAMP stack (Linux, Apache, MariaDB, PHP). The implementation includes SSL/TLS encryption, Network Load Balancer configuration, and proper security group setup within a custom VPC environment.

## AWS Services Used

- **Amazon EC2** - Web and database server hosting
- **Amazon VPC** - Network isolation and subnet configuration
- **Network Load Balancer (NLB)** - Traffic distribution and high availability
- **Security Groups** - Firewall rules for EC2 instances
- **Amazon Linux 2023** - Operating system

## Key Technologies

- **Apache HTTP Server** - Web server
- **MariaDB** - Database management system
- **PHP 8.2** - Server-side scripting
- **WordPress** - Content management system
- **SSL/TLS** - Secure communications
- **mod_ssl** - Apache SSL module

## Architecture Overview

The architecture consists of a VPC with public and private subnets, a Network Load Balancer distributing traffic to an EC2 instance running both the web server (Apache + WordPress) and database server (MariaDB). Security groups control inbound and outbound traffic, allowing HTTP/HTTPS access from the internet while restricting database access to localhost only.

See [architecture.md](./architecture.md) for detailed architecture description and traffic flow.

## Objectives

- Deploy and configure a LAMP stack on Amazon Linux 2023
- Install and configure WordPress with MariaDB backend
- Implement SSL/TLS encryption for secure communications
- Configure Apache virtual hosts and security settings
- Set up proper file permissions for WordPress
- Configure Network Load Balancer for traffic distribution
- Implement security best practices with security groups

## Key Learnings

- **LAMP Stack Configuration**: Understanding the integration between Linux, Apache, MariaDB, and PHP components
- **WordPress Deployment**: Manual installation and configuration of WordPress, including database setup and wp-config.php configuration
- **SSL/TLS Implementation**: Generating self-signed certificates and configuring Apache mod_ssl for HTTPS
- **Security Hardening**: Proper file permissions, security group configuration, and database access restrictions
- **Load Balancer Integration**: Configuring Network Load Balancer with target groups and health checks
- **VPC Networking**: Understanding public/private subnet architecture and security group rules
- **Apache Configuration**: Virtual host setup, SSL configuration, and DocumentRoot management

## Setup Instructions

### Prerequisites

- AWS account with appropriate permissions
- VPC with public subnet configured
- Network Load Balancer created and configured
- EC2 instance launched with Amazon Linux 2023
- SSH access to EC2 instance

### Step 1: Install LAMP Stack Components

Run the environment setup script to install Apache, MariaDB, and PHP:

```bash
./scripts/setup-environment.sh
```

This script installs:
- Apache HTTP Server (httpd)
- MariaDB server and client
- PHP 8.2 with required extensions (mysqlnd, pdo, gd, mbstring)
- mod_ssl for Apache

### Step 2: Configure MariaDB and Create WordPress Database

Run the database configuration script:

```bash
./scripts/configure-database.sh
```

This script:
- Starts and enables MariaDB service
- Secures the MariaDB installation
- Creates the WordPress database
- Creates a database user with appropriate privileges

### Step 3: Install and Configure WordPress

Run the WordPress configuration script:

```bash
./scripts/configure-wordpress.sh
```

This script:
- Downloads the latest WordPress package
- Extracts WordPress files to the web root
- Creates wp-config.php with database credentials
- Configures WordPress constants and security keys

### Step 4: Configure SSL/TLS

Run the SSL configuration script:

```bash
./scripts/configure-ssl.sh
```

This script:
- Generates a self-signed SSL certificate
- Configures Apache to use the certificate
- Sets up HTTPS virtual host

### Step 5: Set File Permissions

Run the permissions configuration script:

```bash
./scripts/configure-permissions.sh
```

This script:
- Sets proper ownership for WordPress files (apache:apache)
- Configures directory permissions (755)
- Configures file permissions (644)
- Ensures wp-config.php is secure (600)

### Step 6: Restart Apache

After all configuration is complete, restart Apache to apply changes:

```bash
sudo systemctl restart httpd
```

### Step 7: Complete WordPress Installation

1. Access your site via the Network Load Balancer DNS name
2. Complete the WordPress installation wizard
3. Set up your admin account and site information

## Scripts and Configurations

### Scripts

All scripts are located in the `scripts/` directory:

- **setup-environment.sh** - Installs LAMP stack components (Apache, MariaDB, PHP, mod_ssl)
- **configure-database.sh** - Sets up MariaDB and creates WordPress database with user
- **configure-wordpress.sh** - Downloads WordPress and creates wp-config.php
- **configure-ssl.sh** - Generates SSL certificate and configures Apache for HTTPS
- **configure-permissions.sh** - Sets proper file ownership and permissions for WordPress

### Configuration Files

Configuration templates are located in the `configs/` directory:

- **wp-config-sample.php** - WordPress configuration template with database settings
- **httpd.conf.snippet** - Apache configuration changes for SSL and virtual hosts
- **ssl.conf.snippet** - SSL/TLS configuration for Apache mod_ssl

## Troubleshooting

### WordPress Installation Issues

- Verify database credentials in wp-config.php
- Check MariaDB service is running: `sudo systemctl status mariadb`
- Verify database and user exist: `sudo mysql -e "SHOW DATABASES;"`

### Apache Issues

- Check Apache error logs: `sudo tail -f /var/log/httpd/error_log`
- Verify Apache is running: `sudo systemctl status httpd`
- Test Apache configuration: `sudo apachectl configtest`

### SSL Certificate Issues

- Verify certificate files exist in `/etc/pki/tls/certs/` and `/etc/pki/tls/private/`
- Check SSL configuration in `/etc/httpd/conf.d/ssl.conf`
- Verify mod_ssl is loaded: `sudo httpd -M | grep ssl`

### Permission Issues

- Verify Apache user ownership: `ls -la /var/www/html/`
- Check SELinux status if enabled: `getenforce`
- Review file permissions: directories should be 755, files should be 644

## Security Considerations

- The SSL certificate generated is self-signed and suitable for testing only
- For production, use a certificate from a trusted Certificate Authority
- Database credentials should be stored securely and rotated regularly
- Keep WordPress, PHP, and all components updated with security patches
- Implement regular backups of both database and WordPress files
- Consider using AWS Secrets Manager for credential management

## Next Steps

- Configure automated backups using AWS Backup or snapshots
- Implement CloudWatch monitoring for EC2 instance metrics
- Set up Auto Scaling for high availability
- Configure CloudFront CDN for improved performance
- Implement AWS WAF for additional security
- Use Amazon RDS instead of local MariaDB for managed database service

## Lab Metadata

- **Domain**: Compute
- **Complexity Level**: Intermediate
- **Estimated Time**: 2-3 hours
- **AWS Services**: EC2, VPC, Network Load Balancer, Security Groups
- **Technologies**: Apache, MariaDB, PHP, WordPress, SSL/TLS
- **Certification Alignment**: AWS Certified Solutions Architect - Associate (EC2, VPC, Load Balancing)
