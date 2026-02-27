"""
Lab discovery functionality.

This module scans the portfolio repository to identify all existing labs
across service domains.
"""

from pathlib import Path
from typing import List
import logging
import re

from .models import Lab

logger = logging.getLogger(__name__)


def extract_aws_services(readme_content: str) -> List[str]:
    """
    Extract AWS service names from README content.
    
    Args:
        readme_content: Content of the README file
        
    Returns:
        List of AWS service names found in the content
    """
    # Common AWS service patterns
    aws_services = set()
    
    # Service name patterns (e.g., "Amazon S3", "AWS Lambda", "EC2")
    service_patterns = [
        r'\b(Amazon\s+\w+(?:\s+\w+)?)\b',
        r'\b(AWS\s+\w+(?:\s+\w+)?)\b',
        r'\b(EC2|S3|RDS|VPC|IAM|ECS|EKS|Lambda|DynamoDB|CloudFormation|CloudWatch)\b',
        r'\b(Elastic\s+\w+(?:\s+\w+)?)\b',
    ]
    
    for pattern in service_patterns:
        matches = re.finditer(pattern, readme_content, re.IGNORECASE)
        for match in matches:
            service = match.group(1).strip()
            # Normalize service names
            service = service.replace('Amazon ', '').replace('AWS ', '').replace('Elastic ', '')
            aws_services.add(service)
    
    return sorted(list(aws_services))


def discover_labs(repo_root: Path, service_domains: List[str]) -> List[Lab]:
    """
    Discover all labs in the repository.
    
    Args:
        repo_root: Path to the repository root
        service_domains: List of service domain directory names
        
    Returns:
        List of discovered Lab objects
    """
    labs = []
    
    for domain in service_domains:
        domain_path = repo_root / domain
        
        if not domain_path.exists():
            logger.warning(f"Service domain directory not found: {domain}")
            continue
            
        if not domain_path.is_dir():
            logger.warning(f"Service domain path is not a directory: {domain}")
            continue
        
        # Find all subdirectories with README.md (indicates a lab)
        try:
            for lab_dir in domain_path.iterdir():
                if not lab_dir.is_dir():
                    continue
                    
                readme_path = lab_dir / "README.md"
                if not readme_path.exists():
                    continue
                
                # Found a lab
                architecture_path = lab_dir / "architecture.md"
                
                # Extract AWS services from README
                aws_services = []
                try:
                    with open(readme_path, 'r', encoding='utf-8') as f:
                        readme_content = f.read()
                        aws_services = extract_aws_services(readme_content)
                except Exception as e:
                    logger.warning(f"Could not read README for {lab_dir.name}: {e}")
                
                lab = Lab(
                    name=lab_dir.name,
                    path=lab_dir,
                    domain=domain,
                    readme_path=readme_path,
                    architecture_path=architecture_path if architecture_path.exists() else None,
                    aws_services=aws_services
                )
                
                labs.append(lab)
                logger.info(f"Discovered lab: {domain}/{lab_dir.name} (services: {', '.join(aws_services[:3])}{'...' if len(aws_services) > 3 else ''})")
                
        except PermissionError as e:
            logger.error(f"Permission denied accessing {domain_path}: {e}")
            continue
        except Exception as e:
            logger.error(f"Error scanning {domain_path}: {e}")
            continue
    
    logger.info(f"Discovered {len(labs)} labs across {len(service_domains)} domains")
    return labs
