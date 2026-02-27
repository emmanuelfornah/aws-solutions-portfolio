"""
Documentation generation functionality.

This module generates standardized READMEs for mini-projects and pillars.
"""

from pathlib import Path
from typing import List
import logging
from datetime import datetime

from .models import Lab, LabMapping, BusinessProblem

logger = logging.getLogger(__name__)


def generate_project_readme(
    lab: Lab,
    mapping: LabMapping,
    business_problem: BusinessProblem
) -> str:
    """
    Generate a standardized README for a mini-project.
    
    Args:
        lab: Lab object
        mapping: LabMapping with pillar assignment
        business_problem: BusinessProblem statement
        
    Returns:
        Generated README content as string
    """
    # Load template
    template_path = Path(__file__).parent / "templates" / "mini_project_readme.md"
    with open(template_path, 'r', encoding='utf-8') as f:
        template = f.read()
    
    # Read existing README for content extraction
    existing_content = ""
    try:
        with open(lab.readme_path, 'r', encoding='utf-8') as f:
            existing_content = f.read()
    except Exception as e:
        logger.warning(f"Could not read existing README: {e}")
    
    # Extract sections from existing README
    implementation_details = _extract_section(existing_content, ["implementation", "details", "overview"])
    prerequisites = _extract_section(existing_content, ["prerequisites", "requirements"])
    deployment_steps = _extract_section(existing_content, ["deployment", "setup", "installation"])
    configuration_notes = _extract_section(existing_content, ["configuration", "config"])
    
    # Generate AWS services list
    aws_services_list = ""
    if mapping.aws_services:
        for service in mapping.aws_services:
            aws_services_list += f"- **{service}**: Used for {_get_service_purpose(service, mapping.primary_pillar)}\n"
    else:
        aws_services_list = "- AWS services used in this project\n"
    
    # Architecture diagram section
    architecture_diagram_section = ""
    if lab.architecture_path:
        architecture_diagram_section = f"\n### Architecture Diagram\n\nSee [architecture.md](architecture.md) for detailed architecture diagrams.\n"
    
    # Secondary pillars section
    secondary_pillars_section = ""
    if mapping.secondary_pillars:
        secondary_pillars_section = f"\n**Secondary Pillars**: {', '.join(mapping.secondary_pillars)}"
    
    # Pillar principles
    pillar_principles = _get_pillar_principles(mapping.primary_pillar)
    
    # Fill template
    readme = template.format(
        project_title=_generate_professional_title(lab, mapping),
        primary_pillar=mapping.primary_pillar.replace('-', ' ').title(),
        business_problem=business_problem.statement,
        solution_summary=business_problem.solution_summary,
        architecture_diagram_section=architecture_diagram_section,
        aws_services_list=aws_services_list.strip(),
        results=business_problem.business_value,
        implementation_details=implementation_details or "Refer to the configuration files and scripts in this directory for implementation details.",
        prerequisites=prerequisites or "- AWS Account with appropriate permissions\n- AWS CLI configured\n- Basic understanding of the AWS services used",
        deployment_steps=deployment_steps or "1. Review the architecture diagram\n2. Configure AWS credentials\n3. Deploy using the provided scripts\n4. Validate the deployment",
        configuration_notes=configuration_notes or "Configuration files are located in the `configs/` directory. Scripts for deployment are in the `scripts/` directory.",
        key_learnings=_generate_key_learnings(mapping.primary_pillar, mapping.aws_services),
        implementation_date=datetime.now().strftime("%Y-%m"),
        services_tags=", ".join(mapping.aws_services) if mapping.aws_services else "AWS"
    )
    
    return readme


def _generate_professional_title(lab: Lab, mapping: LabMapping) -> str:
    """Generate a professional project title based on services and pillar."""
    from .business_problem import TITLE_TEMPLATES
    
    pillar = mapping.primary_pillar
    title_templates = TITLE_TEMPLATES.get(pillar, {})
    
    # Try to find specific title based on primary service
    for service in mapping.aws_services:
        if service in title_templates:
            return title_templates[service]
    
    # Fall back to default or lab name
    default_title = title_templates.get("default", lab.name.replace('-', ' ').title())
    return default_title


def _extract_section(content: str, keywords: List[str]) -> str:
    """Extract a section from existing README based on keywords."""
    lines = content.split('\n')
    section_lines = []
    in_section = False
    
    for i, line in enumerate(lines):
        # Check if this is a section header
        if line.startswith('#'):
            # Check if any keyword matches
            line_lower = line.lower()
            if any(keyword in line_lower for keyword in keywords):
                in_section = True
                continue
            elif in_section:
                # Hit next section, stop
                break
        
        if in_section:
            section_lines.append(line)
    
    return '\n'.join(section_lines).strip()


def _get_service_purpose(service: str, pillar: str) -> str:
    """Get a brief purpose description for a service in context of a pillar."""
    purposes = {
        "Lambda": "serverless compute and event-driven processing",
        "S3": "scalable object storage",
        "DynamoDB": "high-performance NoSQL database",
        "EC2": "compute capacity",
        "RDS": "managed relational database",
        "CloudFormation": "infrastructure as code",
        "CloudWatch": "monitoring and observability",
        "IAM": "identity and access management",
        "VPC": "network isolation and security",
        "ECS": "container orchestration",
        "EKS": "Kubernetes orchestration",
    }
    return purposes.get(service, f"{pillar.replace('-', ' ')} implementation")


def _get_pillar_principles(pillar: str) -> str:
    """Get pillar-specific principles."""
    principles = {
        "operational-excellence": "- Automated deployment and operations\n- Comprehensive monitoring and logging\n- Infrastructure as code practices",
        "security": "- Defense in depth\n- Least privilege access\n- Data encryption at rest and in transit",
        "reliability": "- Fault tolerance and redundancy\n- Automated recovery\n- Regular backup and testing",
        "performance-efficiency": "- Right-sizing resources\n- Caching strategies\n- Performance monitoring and optimization",
        "cost-optimization": "- Pay-per-use pricing models\n- Resource optimization\n- Cost monitoring and allocation",
        "sustainability": "- Resource efficiency\n- Minimizing idle resources\n- Sustainable architecture patterns"
    }
    return principles.get(pillar, "- Best practices implementation")


def _generate_key_learnings(pillar: str, services: List[str]) -> str:
    """Generate key learnings based on pillar and services."""
    learnings = [
        f"- Practical application of {pillar.replace('-', ' ')} principles",
        "- Hands-on experience with AWS services in real-world scenarios"
    ]
    
    if services:
        learnings.append(f"- Integration patterns for {', '.join(services[:2])}")
    
    return '\n'.join(learnings)


def generate_pillar_readme(pillar: str, labs: List[Lab]) -> str:
    """
    Generate a README for a pillar directory.
    
    Args:
        pillar: Pillar name
        labs: List of labs in this pillar
        
    Returns:
        Generated README content as string
    """
    pillar_title = pillar.replace('-', ' ').title()
    
    pillar_descriptions = {
        "operational-excellence": {
            "description": "The Operational Excellence pillar focuses on running and monitoring systems, and continually improving processes and procedures.",
            "principles": [
                "Perform operations as code",
                "Make frequent, small, reversible changes",
                "Refine operations procedures frequently",
                "Anticipate failure",
                "Learn from all operational failures"
            ]
        },
        "security": {
            "description": "The Security pillar focuses on protecting information and systems.",
            "principles": [
                "Implement a strong identity foundation",
                "Enable traceability",
                "Apply security at all layers",
                "Automate security best practices",
                "Protect data in transit and at rest",
                "Keep people away from data",
                "Prepare for security events"
            ]
        },
        "reliability": {
            "description": "The Reliability pillar focuses on workloads performing their intended functions and how to recover quickly from failure.",
            "principles": [
                "Automatically recover from failure",
                "Test recovery procedures",
                "Scale horizontally to increase aggregate workload availability",
                "Stop guessing capacity",
                "Manage change through automation"
            ]
        },
        "performance-efficiency": {
            "description": "The Performance Efficiency pillar focuses on structured and streamlined allocation of IT and computing resources.",
            "principles": [
                "Democratize advanced technologies",
                "Go global in minutes",
                "Use serverless architectures",
                "Experiment more often",
                "Consider mechanical sympathy"
            ]
        },
        "cost-optimization": {
            "description": "The Cost Optimization pillar focuses on avoiding unnecessary costs.",
            "principles": [
                "Implement cloud financial management",
                "Adopt a consumption model",
                "Measure overall efficiency",
                "Stop spending money on undifferentiated heavy lifting",
                "Analyze and attribute expenditure"
            ]
        },
        "sustainability": {
            "description": "The Sustainability pillar focuses on minimizing the environmental impacts of running cloud workloads.",
            "principles": [
                "Understand your impact",
                "Establish sustainability goals",
                "Maximize utilization",
                "Anticipate and adopt new, more efficient hardware and software offerings",
                "Use managed services",
                "Reduce the downstream impact of your cloud workloads"
            ]
        }
    }
    
    pillar_info = pillar_descriptions.get(pillar, {
        "description": f"Projects demonstrating {pillar_title} best practices.",
        "principles": []
    })
    
    readme = f"""# {pillar_title}

{pillar_info['description']}

## Design Principles

"""
    
    for principle in pillar_info['principles']:
        readme += f"- {principle}\n"
    
    readme += f"\n## Projects ({len(labs)})\n\n"
    
    if labs:
        for lab in sorted(labs, key=lambda l: l.name):
            readme += f"### [{lab.name.replace('-', ' ').title()}]({lab.name}/)\n\n"
            
            # Add brief description if available
            if lab.business_problem:
                readme += f"{lab.business_problem}\n\n"
            
            # Add services
            if lab.aws_services:
                readme += f"**Services**: {', '.join(lab.aws_services[:5])}\n\n"
            
            readme += "---\n\n"
    else:
        readme += "No projects in this pillar yet.\n\n"
    
    readme += """## Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Well-Architected Tool](https://aws.amazon.com/well-architected-tool/)
"""
    
    return readme


def update_main_readme(repo_root: Path, mappings: List[LabMapping]) -> None:
    """
    Update the main portfolio README.
    
    Args:
        repo_root: Path to the repository root
        mappings: List of all lab mappings
    """
    # TODO: Implement main README update logic
    # This is a placeholder that will be implemented in task 14.1
    pass
