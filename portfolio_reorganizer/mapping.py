"""
Lab mapping generation and export functionality.
"""

from pathlib import Path
from typing import List
import json
import logging

from .models import Lab, LabMapping, BusinessProblem
from .pillar_assignment import assign_pillar, load_service_mappings
from .business_problem import identify_business_problem

logger = logging.getLogger(__name__)


def generate_lab_mapping(
    labs: List[Lab],
    service_mappings_file: Path
) -> List[LabMapping]:
    """
    Generate complete lab mappings with pillar assignments and business problems.
    
    Args:
        labs: List of discovered labs
        service_mappings_file: Path to service mappings JSON file
        
    Returns:
        List of LabMapping objects
    """
    logger.info(f"Generating mappings for {len(labs)} labs")
    
    # Load service mappings
    service_mappings = load_service_mappings(service_mappings_file)
    
    mappings = []
    for lab in labs:
        # Assign pillar
        mapping = assign_pillar(lab, service_mappings)
        
        # Generate business problem
        business_problem = identify_business_problem(lab, mapping.primary_pillar)
        mapping.business_problem = business_problem.statement
        
        mappings.append(mapping)
    
    logger.info(f"Generated {len(mappings)} lab mappings")
    return mappings


def export_mapping_json(mappings: List[LabMapping], output_file: Path) -> None:
    """
    Export lab mappings to JSON file.
    
    Args:
        mappings: List of LabMapping objects
        output_file: Path to output JSON file
    """
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    mappings_data = []
    for mapping in mappings:
        mappings_data.append({
            "lab_name": mapping.lab_name,
            "original_path": mapping.original_path,
            "new_path": mapping.new_path,
            "primary_pillar": mapping.primary_pillar,
            "secondary_pillars": mapping.secondary_pillars,
            "business_problem": mapping.business_problem,
            "aws_services": mapping.aws_services,
            "assignment_rationale": mapping.assignment_rationale,
            "confidence_score": mapping.confidence_score
        })
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(mappings_data, f, indent=2)
    
    logger.info(f"Exported mappings to {output_file}")


def export_mapping_markdown(mappings: List[LabMapping], output_file: Path) -> None:
    """
    Export lab mappings to human-readable Markdown file.
    
    Args:
        mappings: List of LabMapping objects
        output_file: Path to output Markdown file
    """
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    # Group by pillar
    by_pillar = {}
    for mapping in mappings:
        pillar = mapping.primary_pillar
        if pillar not in by_pillar:
            by_pillar[pillar] = []
        by_pillar[pillar].append(mapping)
    
    # Generate markdown
    lines = [
        "# Lab Mapping Report",
        "",
        f"Total Labs: {len(mappings)}",
        "",
        "## Distribution by Pillar",
        ""
    ]
    
    for pillar in sorted(by_pillar.keys()):
        count = len(by_pillar[pillar])
        lines.append(f"- **{pillar}**: {count} labs")
    
    lines.extend(["", "---", ""])
    
    # Detail each pillar
    for pillar in sorted(by_pillar.keys()):
        lines.extend([
            f"## {pillar.replace('-', ' ').title()}",
            ""
        ])
        
        for mapping in sorted(by_pillar[pillar], key=lambda m: m.lab_name):
            lines.extend([
                f"### {mapping.lab_name}",
                "",
                f"**Original Path**: `{mapping.original_path}`",
                f"**New Path**: `{mapping.new_path}`",
                f"**Confidence**: {mapping.confidence_score:.2f}",
                "",
                f"**Business Problem**: {mapping.business_problem}",
                "",
                f"**AWS Services**: {', '.join(mapping.aws_services) if mapping.aws_services else 'None detected'}",
                "",
                f"**Rationale**: {mapping.assignment_rationale}",
                ""
            ])
            
            if mapping.secondary_pillars:
                lines.append(f"**Also relevant to**: {', '.join(mapping.secondary_pillars)}")
                lines.append("")
            
            lines.append("---")
            lines.append("")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    
    logger.info(f"Exported markdown report to {output_file}")
