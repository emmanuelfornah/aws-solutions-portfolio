"""
Data models for portfolio reorganization.
"""

from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Dict


@dataclass
class Lab:
    """Represents an AWS Cloud Institute lab."""
    name: str
    path: Path
    domain: str  # Original service domain
    readme_path: Path
    architecture_path: Optional[Path] = None
    aws_services: List[str] = field(default_factory=list)
    primary_pillar: Optional[str] = None
    secondary_pillars: List[str] = field(default_factory=list)
    business_problem: Optional[str] = None
    assignment_rationale: Optional[str] = None


@dataclass
class LabMapping:
    """Mapping of a lab to its Well-Architected pillar."""
    lab_name: str
    original_path: str
    new_path: str
    primary_pillar: str
    secondary_pillars: List[str]
    business_problem: str
    aws_services: List[str]
    assignment_rationale: str
    confidence_score: float  # 0.0 to 1.0


@dataclass
class MigrationLog:
    """Log entry for a migration operation."""
    timestamp: datetime
    operation: str  # "move", "create", "update"
    source_path: Optional[str]
    destination_path: str
    git_commit: str
    status: str  # "success", "conflict", "error"
    notes: Optional[str] = None


@dataclass
class ValidationReport:
    """Report of portfolio validation results."""
    timestamp: datetime
    total_labs: int
    labs_with_readme: int
    labs_with_architecture: int
    broken_links: List[str]
    missing_documentation: List[str]
    pillar_distribution: Dict[str, int]
    quality_score: float  # 0-100
    recommendations: List[str]


@dataclass
class BusinessProblem:
    """Business problem statement for a lab."""
    statement: str
    solution_summary: str
    business_value: str
