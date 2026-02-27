#!/usr/bin/env python3
"""
Lab migration script - moves labs to their assigned pillar directories.

This script uses git mv to preserve commit history.
"""

import sys
import json
import logging
import subprocess
from pathlib import Path
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('.migration/migration.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def git_mv(source: Path, destination: Path) -> bool:
    """Move a directory using git mv to preserve history."""
    try:
        # Ensure destination parent exists
        destination.parent.mkdir(parents=True, exist_ok=True)
        
        # Use git mv
        result = subprocess.run(
            ['git', 'mv', str(source), str(destination)],
            capture_output=True,
            text=True,
            check=True
        )
        logger.info(f"✓ Moved {source.name} → {destination.parent.name}/")
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"✗ Failed to move {source.name}: {e.stderr}")
        return False
    except Exception as e:
        logger.error(f"✗ Error moving {source.name}: {str(e)}")
        return False

def main():
    repo_path = Path.cwd()
    
    logger.info("="*80)
    logger.info("LAB MIGRATION TO PILLAR DIRECTORIES")
    logger.info("="*80)
    logger.info("")
    
    # Load mapping
    mapping_file = repo_path / ".migration" / "lab-mapping.json"
    if not mapping_file.exists():
        logger.error("Mapping file not found. Run analysis first.")
        return
    
    with open(mapping_file, 'r') as f:
        mappings = json.load(f)
    
    logger.info(f"Loaded {len(mappings)} lab mappings")
    logger.info("")
    
    # Track statistics
    successful = 0
    failed = 0
    skipped = 0
    
    # Migrate each lab
    for mapping in mappings:
        lab_name = mapping['lab_name']
        original_path = mapping['original_path']
        pillar = mapping['primary_pillar']
        
        # Convert Windows path to Path object
        source_path = repo_path / original_path.replace('\\', '/')
        destination_path = repo_path / pillar / lab_name
        
        # Check if source exists
        if not source_path.exists():
            logger.warning(f"⊘ Source not found: {source_path}")
            skipped += 1
            continue
        
        # Check if destination already exists
        if destination_path.exists():
            logger.warning(f"⊘ Destination exists: {destination_path}")
            skipped += 1
            continue
        
        # Perform migration
        if git_mv(source_path, destination_path):
            successful += 1
        else:
            failed += 1
    
    # Summary
    logger.info("")
    logger.info("="*80)
    logger.info("MIGRATION COMPLETE")
    logger.info("="*80)
    logger.info(f"Successful: {successful}")
    logger.info(f"Failed: {failed}")
    logger.info(f"Skipped: {skipped}")
    logger.info(f"Total: {len(mappings)}")
    logger.info("")
    
    if successful > 0:
        logger.info("Next steps:")
        logger.info("1. Review the changes: git status")
        logger.info("2. Commit the reorganization: git commit -m 'Reorganize portfolio by AWS Well-Architected pillars'")
        logger.info("3. Check the pillar directories to verify everything looks good")

if __name__ == "__main__":
    main()
