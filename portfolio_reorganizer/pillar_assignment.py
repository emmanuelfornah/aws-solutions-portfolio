"""
Pillar assignment functionality.

This module analyzes labs and assigns them to Well-Architected Framework pillars.
"""

from pathlib import Path
from typing import Dict, List
import json
import logging
import re

from .models import Lab, LabMapping

logger = logging.getLogger(__name__)

# Pillar names
PILLARS = [
    "operational-excellence",
    "security",
    "reliability",
    "performance-efficiency",
    "cost-optimization",
    "sustainability"
]


def load_service_mappings(mappings_file: Path) -> Dict:
    """Load AWS service to pillar mappings from JSON file."""
    with open(mappings_file, 'r') as f:
        return json.load(f)


def calculate_pillar_scores(lab: Lab, service_mappings: Dict) -> Dict[str, float]:
    """
    Calculate pillar scores for a lab based on services, keywords, and patterns.
    
    Uses weighted scoring:
    - AWS Services: 40%
    - Documentation Keywords: 30%
    - Architecture Patterns: 30%
    
    Args:
        lab: Lab object to score
        service_mappings: AWS service to pillar mapping configuration
        
    Returns:
        Dictionary mapping pillar names to scores (0.0 to 1.0)
    """
    pillar_scores = {pillar: 0.0 for pillar in PILLARS}
    
    # Read lab documentation
    readme_content = ""
    try:
        with open(lab.readme_path, 'r', encoding='utf-8') as f:
            readme_content = f.read().lower()
    except Exception as e:
        logger.warning(f"Could not read README for {lab.name}: {e}")
    
    # Read architecture documentation if available
    if lab.architecture_path:
        try:
            with open(lab.architecture_path, 'r', encoding='utf-8') as f:
                readme_content += " " + f.read().lower()
        except Exception as e:
            logger.warning(f"Could not read architecture.md for {lab.name}: {e}")
    
    # 1. AWS Services scoring (40% weight)
    service_score = {pillar: 0.0 for pillar in PILLARS}
    service_mappings_dict = service_mappings.get("service_mappings", {})
    
    for service in lab.aws_services:
        if service in service_mappings_dict:
            mapping = service_mappings_dict[service]
            primary = mapping.get("primary_pillar")
            secondaries = mapping.get("secondary_pillars", [])
            
            if primary:
                service_score[primary] += 1.0
            for secondary in secondaries:
                service_score[secondary] += 0.5
    
    # Normalize service scores
    max_service_score = max(service_score.values()) if service_score.values() else 1.0
    if max_service_score > 0:
        for pillar in PILLARS:
            pillar_scores[pillar] += (service_score[pillar] / max_service_score) * 0.4
    
    # 2. Keyword scoring (30% weight)
    keyword_score = {pillar: 0.0 for pillar in PILLARS}
    keyword_mappings = service_mappings.get("keyword_mappings", {})
    
    for pillar, keywords in keyword_mappings.items():
        for keyword in keywords:
            # Count occurrences of keyword in documentation
            count = len(re.findall(r'\b' + re.escape(keyword.lower()) + r'\b', readme_content))
            keyword_score[pillar] += count
    
    # Normalize keyword scores
    max_keyword_score = max(keyword_score.values()) if keyword_score.values() else 1.0
    if max_keyword_score > 0:
        for pillar in PILLARS:
            pillar_scores[pillar] += (keyword_score[pillar] / max_keyword_score) * 0.3
    
    # 3. Pattern scoring (30% weight)
    pattern_score = {pillar: 0.0 for pillar in PILLARS}
    pattern_mappings = service_mappings.get("pattern_mappings", {})
    
    for pillar, patterns in pattern_mappings.items():
        for pattern in patterns:
            if pattern.lower() in readme_content:
                pattern_score[pillar] += 1.0
    
    # Normalize pattern scores
    max_pattern_score = max(pattern_score.values()) if pattern_score.values() else 1.0
    if max_pattern_score > 0:
        for pillar in PILLARS:
            pillar_scores[pillar] += (pattern_score[pillar] / max_pattern_score) * 0.3
    
    return pillar_scores


def assign_pillar(lab: Lab, service_mappings: Dict) -> LabMapping:
    """
    Assign a lab to its primary Well-Architected pillar.
    
    Args:
        lab: Lab object to assign
        service_mappings: AWS service to pillar mapping configuration
        
    Returns:
        LabMapping object with pillar assignment
    """
    # Calculate scores for all pillars
    pillar_scores = calculate_pillar_scores(lab, service_mappings)
    
    # Find primary pillar (highest score)
    if not pillar_scores or all(score == 0 for score in pillar_scores.values()):
        # No clear match - default to operational-excellence
        primary_pillar = "operational-excellence"
        confidence_score = 0.3
        rationale = "No clear pillar match found. Defaulted to operational-excellence."
        secondary_pillars = []
    else:
        # Sort pillars by score
        sorted_pillars = sorted(pillar_scores.items(), key=lambda x: x[1], reverse=True)
        primary_pillar = sorted_pillars[0][0]
        primary_score = sorted_pillars[0][1]
        
        # Find secondary pillars (score > 0.3 threshold and not primary)
        secondary_threshold = 0.3
        secondary_pillars = [
            pillar for pillar, score in sorted_pillars[1:]
            if score > secondary_threshold
        ]
        
        # Calculate confidence score (0.0 to 1.0)
        confidence_score = min(primary_score, 1.0)
        
        # Generate rationale
        rationale_parts = []
        if lab.aws_services:
            rationale_parts.append(f"Primary services: {', '.join(lab.aws_services[:3])}")
        rationale_parts.append(f"Score: {primary_score:.2f}")
        if secondary_pillars:
            rationale_parts.append(f"Also relevant to: {', '.join(secondary_pillars)}")
        rationale = ". ".join(rationale_parts)
    
    # Create new path
    new_path = f"{primary_pillar}/{lab.name}"
    
    # Create mapping
    mapping = LabMapping(
        lab_name=lab.name,
        original_path=str(lab.path.relative_to(lab.path.parent.parent)),
        new_path=new_path,
        primary_pillar=primary_pillar,
        secondary_pillars=secondary_pillars,
        business_problem="",  # Will be filled by business problem identifier
        aws_services=lab.aws_services,
        assignment_rationale=rationale,
        confidence_score=confidence_score
    )
    
    logger.info(f"Assigned {lab.name} to {primary_pillar} (confidence: {confidence_score:.2f})")
    
    return mapping
