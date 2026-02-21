# WordPress on EC2 Architecture

## Architecture Overview

This WordPress deployment uses a single-tier architecture with an EC2 instance hosting both the web server and database, fronted by a Network Load Balancer for traffic distribution and high availability preparation.

## Components

### 1. Virtual Private Cloud (VPC)

The VPC provides network isolation and segmentation for the WordPress infrastructure.

**Configuration:**
- Custom VPC with CIDR block (e.g., 10.0.0.0/16)
- Public subnets for internet-facing resources
- Private subnets for internal resources (optional for future expansion)
- Internet Gateway for public internet access
- Route tables configured for public subnet internet routing

### 2. Network Load Balancer (NLB)

The Network Load Balancer distributes incoming traffic to the EC2 instance and provides a stable endpoint for the application.

**Configuration:**
- Internet-facing scheme
- Listeners on ports 80 (HTTP) and 443 (HTTPS)
- Target group pointing to EC2 instance
- Health checks on HTTP port 80
- Cross-zone load balancing enabled

**Benefits:**
- Single DNS endpoint for the application
- Preparation for horizontal scaling with multiple instances
- Health monitoring and automatic failover capability
- High availability and fault tolerance

### 3. EC2 Instance

The EC2 instance runs the complete LAMP stack and hosts both the WordPress application and MariaDB database.

**Specifications:**
- Amazon Linux 2023 AMI
- Instance type: t2.micro or t3.micro (suitable for testing/development)
- Public subnet placement for direct internet access
- Elastic IP or public IP for SSH access
- EBS volume for storage

**Installed Software:**
- Apache HTTP Server (httpd) - Web server
- MariaDB Server - Database management system
- PHP 8.2 with extensions (mysqlnd, pdo, gd, mbstring)
- mod_ssl - Apache SSL/TLS module
- WordPress - Content management system

### 4. Security Groups

Security groups act as virtual firewalls controlling inbound and outbound traffic.

#### Load Balancer Security Group

**Inbound Rules:**
- Port 80 (HTTP) from 0.0.0.0/0 - Allow public HTTP access
- Port 443 (HTTPS) from 0.0.0.0/0 - Allow public HTTPS access

**Outbound Rules:**
- All traffic to EC2 instance security group - Forward traffic to backend

#### EC2 Instance Security Group

**Inbound Rules:**
- Port 22 (SSH) from your IP - Administrative access
- Port 80 (HTTP) from Load Balancer security group - Web traffic from NLB
- Port 443 (HTTPS) from Load Balancer security group - Secure web traffic from NLB

**Outbound Rules:**
- Port 80 (HTTP) to 0.0.0.0/0 - Allow WordPress to download updates
- Port 443 (HTTPS) to 0.0.0.0/0 - Allow secure outbound connections
- Port 3306 (MySQL) to 127.0.0.1/32 - Database access (localhost only)

## Traffic Flow

### User Request Flow

1. **User Request**: User enters the NLB DNS name in their browser
2. **DNS Resolution**: DNS resolves to the Network Load Balancer's IP address
3. **Load Balancer**: NLB receives the request on port 80 or 443
4. **Target Selection**: NLB forwards the request to the healthy EC2 instance
5. **Security Group Check**: EC2 security group validates the request is from NLB
6. **Apache Processing**: Apache HTTP Server receives and processes the request
7. **PHP Execution**: PHP processes WordPress code
8. **Database Query**: WordPress queries MariaDB on localhost (127.0.0.1:3306)
9. **Response Generation**: WordPress generates HTML response
10. **Response Return**: Apache sends response back through NLB to user

### SSL/TLS Flow

1. **HTTPS Request**: User connects to NLB on port 443
2. **SSL Termination**: Currently handled at EC2 instance level
3. **Certificate Validation**: Browser validates the self-signed certificate (warning expected)
4. **Encrypted Communication**: Traffic encrypted between browser and EC2 instance

**Note**: For production, SSL termination should occur at the NLB level using AWS Certificate Manager (ACM) certificates.

## Network Diagram

```
Internet
    |
    | HTTP/HTTPS (80/443)
    |
    v
[Network Load Balancer]
    |
    | HTTP/HTTPS (80/443)
    |
    v
[Security Group - EC2]
    |
    v
[EC2 Instance - Amazon Linux 2023]
    |
    +-- Apache HTTP Server (Port 80/443)
    |       |
    |       +-- WordPress (PHP 8.2)
    |               |
    |               v
    +-- MariaDB Server (Port 3306 - localhost only)
```

## Data Flow

### WordPress Content Delivery

1. Static content (images, CSS, JS) served directly by Apache
2. Dynamic content processed by PHP and WordPress
3. Database queries executed against local MariaDB instance
4. Generated HTML returned to client through NLB

### WordPress Administration

1. Admin accesses wp-admin through NLB DNS name
2. Authentication handled by WordPress
3. Content updates stored in MariaDB database
4. Media uploads stored in EC2 instance file system (/var/www/html/wp-content/uploads)

## Scalability Considerations

### Current Architecture Limitations

- Single EC2 instance creates a single point of failure
- Database and web server on same instance limits scalability
- Local file storage prevents horizontal scaling
- No session persistence for multiple instances

### Future Enhancements for Production

1. **Database Separation**:
   - Migrate to Amazon RDS for MariaDB/MySQL
   - Enable automated backups and multi-AZ deployment
   - Improve database performance and availability

2. **Horizontal Scaling**:
   - Add multiple EC2 instances behind NLB
   - Implement Auto Scaling based on CPU/memory metrics
   - Use Amazon EFS for shared WordPress file storage

3. **Content Delivery**:
   - Add CloudFront CDN for static content
   - Implement S3 for media storage with WordPress plugins
   - Enable caching at multiple layers

4. **High Availability**:
   - Deploy instances across multiple Availability Zones
   - Use RDS Multi-AZ for database failover
   - Implement health checks and automatic recovery

5. **Security Enhancements**:
   - Use AWS Certificate Manager for SSL certificates
   - Implement AWS WAF for application-level protection
   - Enable VPC Flow Logs for network monitoring
   - Use AWS Secrets Manager for credential management

## Security Architecture

### Defense in Depth

1. **Network Layer**: VPC isolation, security groups, NACLs
2. **Instance Layer**: OS hardening, minimal software installation
3. **Application Layer**: WordPress security plugins, file permissions
4. **Database Layer**: Localhost-only access, strong passwords
5. **Transport Layer**: SSL/TLS encryption

### Access Control

- SSH access restricted to specific IP addresses
- Database access restricted to localhost only
- WordPress admin access through HTTPS only
- Security group rules follow principle of least privilege

### Data Protection

- EBS volumes encrypted at rest (recommended)
- SSL/TLS for data in transit
- Regular backups of database and WordPress files
- Secure storage of database credentials in wp-config.php

## Monitoring and Logging

### CloudWatch Metrics

- EC2 instance metrics (CPU, memory, disk, network)
- NLB metrics (active connections, healthy targets)
- Custom metrics for WordPress performance

### Log Files

- Apache access logs: `/var/log/httpd/access_log`
- Apache error logs: `/var/log/httpd/error_log`
- MariaDB logs: `/var/log/mariadb/mariadb.log`
- WordPress debug logs: `/var/www/html/wp-content/debug.log` (if enabled)

### Health Checks

- NLB health checks on HTTP port 80
- WordPress site availability monitoring
- Database connection monitoring

## Cost Optimization

### Current Architecture Costs

- EC2 instance (t2.micro/t3.micro): ~$8-10/month
- Network Load Balancer: ~$16/month + data processing
- EBS storage: ~$0.10/GB/month
- Data transfer: Variable based on traffic

### Optimization Strategies

- Use Reserved Instances or Savings Plans for predictable workloads
- Right-size instance based on actual usage metrics
- Implement CloudFront to reduce data transfer costs
- Use S3 for media storage instead of EBS
- Schedule instance stop/start for non-production environments

## Disaster Recovery

### Backup Strategy

- EBS snapshots for instance volumes
- MariaDB database dumps (mysqldump)
- WordPress file backups (wp-content directory)
- Configuration backups (Apache, PHP, WordPress configs)

### Recovery Procedures

1. Launch new EC2 instance from AMI or snapshot
2. Restore database from backup
3. Restore WordPress files from backup
4. Update NLB target group with new instance
5. Verify site functionality

### Recovery Time Objective (RTO)

- Current architecture: 30-60 minutes
- With automation: 10-15 minutes
- With Multi-AZ RDS: Near-zero for database

### Recovery Point Objective (RPO)

- Depends on backup frequency
- Recommended: Hourly snapshots for production
- Database replication for near-zero RPO
