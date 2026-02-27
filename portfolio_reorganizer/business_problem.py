"""
Business problem identification functionality.

This module transforms learning-focused lab descriptions into business problem statements.
"""

from typing import Dict, List
import logging
import re

from .models import Lab, BusinessProblem

logger = logging.getLogger(__name__)

# Business problem templates by pillar and service combinations
PROBLEM_TEMPLATES = {
    "security": {
        "default": "Over-permissive access and lack of security controls expose {resources} to threats",
        "IAM": "Over-permissive access policies create security vulnerabilities and compliance risks",
        "WAF": "Web applications lack protection against common security threats and OWASP Top 10 vulnerabilities",
        "Cognito": "Insecure authentication mechanisms and lack of centralized identity management",
        "KMS": "Sensitive data stored without encryption creates compliance and security risks",
        "VPC": "Public exposure of internal services and lack of network segmentation",
        "Security Hub": "Fragmented security monitoring across multiple AWS accounts and services",
        "GuardDuty": "Lack of continuous threat detection and automated security response"
    },
    "reliability": {
        "default": "Single points of failure and lack of redundancy cause service disruptions",
        "Auto Scaling": "Application crashes during traffic spikes due to fixed capacity",
        "RDS": "Database failures cause extended downtime and potential data loss",
        "Load Balancer": "Uneven traffic distribution and lack of health checks cause service degradation",
        "Backup": "Data loss risk due to inadequate backup and recovery strategies",
        "Route 53": "DNS failures and lack of failover capabilities impact availability",
        "Multi-AZ": "Regional failures cause complete service outages"
    },
    "performance-efficiency": {
        "default": "Poor resource utilization and high latency impact user experience",
        "CloudFront": "High latency for global users due to lack of edge caching",
        "ElastiCache": "High database response times and repeated expensive queries",
        "DynamoDB": "Database bottlenecks limit application scalability",
        "Lambda": "Over-provisioned compute resources waste capacity and increase costs",
        "EC2": "Improperly sized instances lead to poor performance or wasted resources"
    },
    "cost-optimization": {
        "default": "Inefficient resource usage and lack of cost visibility drive up cloud spending",
        "Lambda": "Always-on infrastructure creates unnecessary costs for variable workloads",
        "S3": "Storing all data in standard storage tiers increases storage costs unnecessarily",
        "Fargate": "Managing EC2 infrastructure adds operational overhead and costs",
        "Cost Explorer": "Lack of cost visibility prevents optimization opportunities",
        "Compute Optimizer": "Running improperly sized resources wastes budget",
        "EC2": "Idle and underutilized instances drive up compute costs"
    },
    "operational-excellence": {
        "default": "Manual processes and lack of automation increase errors and deployment time",
        "CodePipeline": "Manual deployments create downtime and human error",
        "CloudFormation": "Configuration drift and inconsistent environments across stages",
        "CloudWatch": "Lack of visibility into system health prevents proactive issue resolution",
        "Systems Manager": "Manual operational tasks are time-consuming and error-prone",
        "EKS": "Complex container orchestration requires automated management",
        "EventBridge": "Manual recovery from failures delays service restoration",
        "Step Functions": "Complex workflows lack orchestration and error handling"
    },
    "sustainability": {
        "default": "Inefficient resource usage increases carbon footprint and energy costs",
        "Lambda": "Always-on compute resources waste energy during idle periods",
        "Auto Scaling": "Fixed capacity provisioning wastes resources during low demand",
        "Graviton": "x86 instances consume more energy than ARM-based alternatives",
        "S3": "Storing infrequently accessed data in hot storage tiers wastes resources"
    }
}

# Professional project title templates
TITLE_TEMPLATES = {
    "security": {
        "IAM": "Least Privilege IAM Policy Architecture",
        "WAF": "Layered Web Application Security with WAF and Shield",
        "Cognito": "Secure User Authentication and Authorization System",
        "KMS": "End-to-End Encryption Strategy Using KMS",
        "VPC": "Zero-Trust Network Design for Cloud Applications",
        "default": "Enterprise Security Architecture Implementation"
    },
    "reliability": {
        "Auto Scaling": "Highly Available Web Tier with Auto Scaling and ALB",
        "RDS": "Multi-AZ Database Architecture with Automated Failover",
        "Backup": "Disaster Recovery Strategy with Automated Snapshot Testing",
        "Load Balancer": "Fault-Tolerant Load Balancing Architecture",
        "default": "High Availability and Fault Tolerance Implementation"
    },
    "performance-efficiency": {
        "CloudFront": "Global Content Distribution with Edge Caching",
        "ElastiCache": "Low-Latency Application Performance with Caching Layer",
        "DynamoDB": "High-Performance NoSQL Database Architecture",
        "Lambda": "Right-Sizing Serverless Compute for Optimal Performance",
        "default": "Performance-Optimized Cloud Architecture"
    },
    "cost-optimization": {
        "Lambda": "Cost-Efficient Event-Driven Serverless Architecture",
        "S3": "Intelligent Storage Tiering Lifecycle Implementation",
        "Compute Optimizer": "Compute Rightsizing with AWS Optimizer",
        "Cost Explorer": "Real-Time Cost Monitoring and Alerting System",
        "default": "Cloud Cost Optimization Strategy"
    },
    "operational-excellence": {
        "CodePipeline": "Automated Multi-Stage CI/CD Pipeline with Rollback Strategy",
        "CloudFormation": "Immutable Infrastructure Deployment with IaC",
        "CloudWatch": "Centralized Observability Architecture with Automated Alerting",
        "Systems Manager": "Automated Operational Task Management at Scale",
        "EKS": "Production-Grade Kubernetes Orchestration Platform",
        "EventBridge": "Event-Driven Self-Healing Infrastructure",
        "default": "Automated Operations and Deployment Pipeline"
    },
    "sustainability": {
        "Lambda": "Serverless-First Sustainable Architecture",
        "Graviton": "ARM-Based Compute Migration for Energy Efficiency",
        "S3": "Automated Storage Lifecycle Optimization",
        "default": "Resource-Efficient Cloud Architecture"
    }
}

# Results templates with metrics
RESULTS_TEMPLATES = {
    "operational-excellence": [
        "Reduced deployment time by 70%",
        "Zero manual production releases",
        "Automated rollback within 2 minutes",
        "Deployment frequency increased from weekly to daily",
        "Mean time to recovery (MTTR) reduced by 80%"
    ],
    "security": [
        "Achieved compliance with SOC 2 and ISO 27001 standards",
        "Reduced security incidents by 90%",
        "Automated threat detection and response",
        "Zero data breaches since implementation",
        "Passed all security audits"
    ],
    "reliability": [
        "Achieved 99.99% uptime SLA",
        "Zero unplanned downtime in 6 months",
        "Automated failover in under 60 seconds",
        "Successfully tested disaster recovery procedures",
        "Reduced incident response time by 75%"
    ],
    "performance-efficiency": [
        "Reduced latency by 60% for global users",
        "Improved application response time from 2s to 200ms",
        "Increased throughput by 300%",
        "Reduced database query time by 85%",
        "Optimized resource utilization to 80%"
    ],
    "cost-optimization": [
        "Reduced monthly AWS costs by 40%",
        "Eliminated $5K/month in idle resource spending",
        "Achieved 60% cost savings through rightsizing",
        "Implemented automated cost alerting",
        "Reduced storage costs by 50% through lifecycle policies"
    ],
    "sustainability": [
        "Reduced carbon footprint by 35%",
        "Decreased energy consumption by 40%",
        "Migrated 80% of workloads to ARM-based instances",
        "Eliminated idle resource waste",
        "Optimized resource utilization to minimize environmental impact"
    ]
}


def identify_business_problem(lab: Lab, pillar: str) -> BusinessProblem:
    """
    Generate a business problem statement for a lab.
    
    Args:
        lab: Lab object
        pillar: Assigned Well-Architected pillar
        
    Returns:
        BusinessProblem object with statement, solution, and value
    """
    # Get templates for this pillar
    pillar_templates = PROBLEM_TEMPLATES.get(pillar, {})
    title_templates = TITLE_TEMPLATES.get(pillar, {})
    
    # Try to find a specific template based on services
    problem_statement = None
    project_title = None
    
    for service in lab.aws_services:
        if service in pillar_templates:
            problem_statement = pillar_templates[service]
            project_title = title_templates.get(service)
            break
    
    # Fall back to default template
    if not problem_statement:
        problem_statement = pillar_templates.get("default", 
            f"Inefficient {pillar.replace('-', ' ')} practices impact system reliability and performance")
    
    if not project_title:
        project_title = title_templates.get("default",
            lab.name.replace('-', ' ').title())
    
    # Replace placeholders
    if "{resources}" in problem_statement:
        if lab.aws_services:
            resources = " and ".join(lab.aws_services[:2])
        else:
            resources = "cloud resources"
        problem_statement = problem_statement.format(resources=resources)
    
    # Generate solution summary
    solution_summary = _generate_solution_summary(lab, pillar, project_title)
    
    # Generate business value with results
    business_value = _generate_business_value(pillar, lab.aws_services)
    
    return BusinessProblem(
        statement=problem_statement,
        solution_summary=solution_summary,
        business_value=business_value
    )


def _generate_solution_summary(lab: Lab, pillar: str, project_title: str) -> str:
    """Generate a solution summary based on lab services and pillar."""
    if not lab.aws_services:
        return f"Implemented {project_title.lower()} using AWS best practices"
    
    services_str = ", ".join(lab.aws_services[:3])
    
    solution_verbs = {
        "operational-excellence": "Automated",
        "security": "Secured",
        "reliability": "Built highly available",
        "performance-efficiency": "Optimized",
        "cost-optimization": "Cost-optimized",
        "sustainability": "Implemented sustainable"
    }
    
    verb = solution_verbs.get(pillar, "Implemented")
    
    return f"{verb} solution using {services_str} following AWS Well-Architected Framework best practices"


def _generate_business_value(pillar: str, services: List[str]) -> str:
    """Generate business value statement with results based on pillar."""
    results_list = RESULTS_TEMPLATES.get(pillar, [
        "Improved system reliability and performance",
        "Reduced operational overhead",
        "Enhanced security posture"
    ])
    
    # Select 2-3 relevant results
    selected_results = results_list[:3]
    
    return "\n".join(f"- {result}" for result in selected_results)
