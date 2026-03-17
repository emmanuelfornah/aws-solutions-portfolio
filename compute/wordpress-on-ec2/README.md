# Production WordPress on EC2

## Overview

Deploys a production-ready WordPress site on EC2 with a LAMP stack (Linux, Apache, MySQL, PHP), fronted by a Network Load Balancer with TLS termination for encrypted client connections.

## AWS Services Used

- **Amazon EC2** - LAMP stack hosting WordPress
- **Elastic Load Balancing (NLB)** - Layer 4 load balancing with TLS
- **AWS Certificate Manager** - SSL/TLS certificate provisioning
- **Amazon VPC** - Public/private subnet architecture
- **Amazon EBS** - Persistent storage for WordPress files

## Architecture

```
┌──────────┐     HTTPS     ┌─────────┐     HTTP     ┌──────────────────┐
│  Client  │ ────────────> │   NLB   │ ───────────> │   EC2 Instance   │
│          │   (TLS :443)  │         │   (:80)      │                  │
└──────────┘               └─────────┘              │  Apache + PHP    │
                                                    │  MySQL           │
                                                    │  WordPress       │
                                                    └──────────────────┘
```

## Technical Highlights

- LAMP stack installed and configured via user data script
- NLB handles TLS termination with ACM-managed certificate
- WordPress database runs on local MySQL (single-instance deployment)
- Security group restricts HTTP ingress to NLB only
- EBS volume provides persistent storage across instance restarts
