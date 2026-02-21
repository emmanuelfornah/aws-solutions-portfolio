"""Data models for AWS Labs Portfolio system."""

from dataclasses import dataclass, field
from typing import List, Optional
from datetime import datetime


@dataclass
class CodeBlock:
    """Represents an extracted code block from lab materials."""
    language: str
    content: str
    context: str  # Surrounding description


@dataclass
class LabMetadata:
    """Information about a lab project."""
    title: str
    objectives: List[str]
    aws_services: List[str]
    domain_category: str = ""


@dataclass
class ArchitectureDescription:
    """Architecture information for a lab."""
    components: List[str]
    diagram_reference: Optional[str]
    description: str


@dataclass
class ScriptFile:
    """Represents a script file in a lab project."""
    filename: str
    language: str
    content: str
    description: str


@dataclass
class ConfigFile:
    """Represents a configuration file in a lab project."""
    filename: str
    content: str
    description: str


@dataclass
class AssetFile:
    """Represents an asset file (diagram, screenshot, etc.)."""
    filename: str
    file_type: str  # "diagram", "screenshot", "other"
    description: str


@dataclass
class LabProject:
    """Complete lab project with all associated content."""
    id: str
    title: str
    domain_category: str
    aws_services: List[str]
    objectives: List[str]
    architecture: ArchitectureDescription
    scripts: List[ScriptFile] = field(default_factory=list)
    configs: List[ConfigFile] = field(default_factory=list)
    assets: List[AssetFile] = field(default_factory=list)
    completion_date: Optional[datetime] = None
    complexity_level: str = "Intermediate"  # "Basic", "Intermediate", "Advanced"
    estimated_time: str = ""
    key_learnings: List[str] = field(default_factory=list)


@dataclass
class DomainCategory:
    """Represents a domain category for organizing labs."""
    name: str
    slug: str  # URL-friendly name
    description: str
    labs: List[LabProject] = field(default_factory=list)
    
    # Predefined categories
    COMPUTE = "compute"
    STORAGE = "storage"
    DATABASES = "databases"
    NETWORKING = "networking"
    SECURITY = "security"
    DEVOPS_CICD = "devops-cicd"
    MONITORING = "monitoring"
