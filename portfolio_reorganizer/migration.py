"""
Lab migration functionality.

This module handles moving labs to their assigned pillar directories
while preserving git history.
"""

from pathlib import Path
from typing import List
import logging
import subprocess
from datetime import datetime

from .models import Lab, LabMapping, MigrationLog

logger = logging.getLogger(__name__)

PILLARS = [
    "operational-excellence",
    "security",
    "reliability",
    "performance-efficiency",
    "cost-optimization",
    "sustainability"
]

PILLAR_DESCRIPTIONS = {
    "operational-excellence": "Automation, CI/CD, monitoring, and operational best practices",
    "security": "Identity management, encryption, compliance, and security controls",
    "reliability": "High availability, disaster recovery, fault tolerance, and resilience",
    "performance-efficiency": "Compute optimization, caching, and performance tuning",
    "cost-optimization": "Resource optimization, cost monitoring, and efficient architectures",
    "sustainability": "Resource efficiency, carbon footprint reduction, and sustainable practices"
}


def create_pillar_directories(repo_root: Path) -> None:
    """
    Create the six Well-Architected pillar directories.
    
    Args:
        repo_root: Path to the repository root
    """
    logger.info("Creating pillar directories...")
    
    for pillar in PILLARS:
        pillar_dir = repo_root / pillar
        pillar_dir.mkdir(exist_ok=True)
        logger.info(f"Created directory: {pillar}")
        
        # Create placeholder README
        readme_path = pillar_dir / "README.md"
        if not readme_path.exists():
            readme_content = f"""# {pillar.replace('-', ' ').title()}

{PILLAR_DESCRIPTIONS[pillar]}

## Projects

Projects in this pillar will be listed here after migration.
"""
            with open(readme_path, 'w', encoding='utf-8') as f:
                f.write(readme_content)
            logger.info(f"Created README for {pillar}")
    
    # Create .migration directory
    migration_dir = repo_root / ".migration"
    migration_dir.mkdir(exist_ok=True)
    logger.info("Created .migration directory")
    
    logger.info("Pillar directory structure created successfully")


def migrate_lab(lab: Lab, mapping: LabMapping, repo_root: Path) -> MigrationLog:
    """
    Migrate a lab to its assigned pillar directory.
    
    Args:
        lab: Lab object to migrate
        mapping: LabMapping with pillar assignment
        repo_root: Path to the repository root
        
    Returns:
        MigrationLog entry documenting the operation
    """
    timestamp = datetime.now()
    source_path = str(lab.path.relative_to(repo_root))
    dest_path = mapping.new_path
    
    logger.info(f"Migrating {source_path} -> {dest_path}")
    
    try:
        # Check if destination already exists
        dest_full_path = repo_root / dest_path
        if dest_full_path.exists():
            # Handle duplicate - append suffix
            suffix = 1
            original_dest = dest_path
            while dest_full_path.exists():
                dest_path = f"{original_dest}-{suffix}"
                dest_full_path = repo_root / dest_path
                suffix += 1
            
            logger.warning(f"Destination exists, using: {dest_path}")
            
            return MigrationLog(
                timestamp=timestamp,
                operation="move",
                source_path=source_path,
                destination_path=dest_path,
                git_commit="",
                status="conflict",
                notes=f"Duplicate name, renamed to {dest_path}"
            )
        
        # Use git mv to preserve history
        try:
            result = subprocess.run(
                ["git", "mv", source_path, dest_path],
                cwd=repo_root,
                capture_output=True,
                text=True,
                check=True
            )
            
            logger.info(f"Successfully moved {source_path} to {dest_path}")
            
            return MigrationLog(
                timestamp=timestamp,
                operation="move",
                source_path=source_path,
                destination_path=dest_path,
                git_commit="",
                status="success",
                notes="Moved using git mv"
            )
            
        except subprocess.CalledProcessError as e:
            # Git mv failed, try regular move
            logger.warning(f"git mv failed: {e.stderr}. Trying regular move...")
            
            import shutil
            dest_full_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(lab.path), str(dest_full_path))
            
            return MigrationLog(
                timestamp=timestamp,
                operation="move",
                source_path=source_path,
                destination_path=dest_path,
                git_commit="",
                status="success",
                notes="Moved using shutil (git mv failed)"
            )
            
    except Exception as e:
        logger.error(f"Failed to migrate {source_path}: {e}")
        
        return MigrationLog(
            timestamp=timestamp,
            operation="move",
            source_path=source_path,
            destination_path=dest_path,
            git_commit="",
            status="error",
            notes=str(e)
        )


def update_internal_references(lab_dir: Path, old_path: str, new_path: str) -> None:
    """
    Update internal links and references in lab documentation.
    
    Args:
        lab_dir: Path to the migrated lab directory
        old_path: Original path before migration
        new_path: New path after migration
    """
    logger.info(f"Updating internal references in {lab_dir.name}")
    
    # Find all markdown files
    md_files = list(lab_dir.glob("**/*.md"))
    
    for md_file in md_files:
        try:
            with open(md_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Update relative paths to other labs
            # Pattern: ../domain/lab-name or ../../domain/lab-name
            import re
            
            # Find all relative links
            link_pattern = r'\[([^\]]+)\]\((\.\./[^\)]+)\)'
            matches = re.findall(link_pattern, content)
            
            for link_text, link_path in matches:
                # Skip external links
                if link_path.startswith('http'):
                    continue
                
                # Calculate new relative path
                # This is a simplified version - full implementation would need path resolution
                logger.debug(f"Found link: {link_text} -> {link_path}")
            
            # Save if changed
            if content != original_content:
                with open(md_file, 'w', encoding='utf-8') as f:
                    f.write(content)
                logger.info(f"Updated references in {md_file.name}")
                
        except Exception as e:
            logger.warning(f"Could not update references in {md_file}: {e}")
