#!/usr/bin/env python3
"""
Complete portfolio reorganization execution script.

This script executes all phases:
- Phase 1: Analysis (already done)
- Phase 2: Create structure and migrate labs
- Phase 3: Generate documentation
- Phase 4: Validation

IMPORTANT: This will move your lab files. A backup is recommended.
"""

import sys
import json
import logging
from pathlib import Path
from datetime import datetime

# Add portfolio_reorganizer to path
sys.path.insert(0, str(Path(__file__).parent))

from portfolio_reorganizer.discovery import discover_labs
from portfolio_reorganizer.mapping import generate_lab_mapping, export_mapping_json, export_mapping_markdown
from portfolio_reorganizer.migration import create_pillar_directories, migrate_lab
from portfolio_reorganizer.documentation import generate_project_readme, generate_pillar_readme
from portfolio_reorganizer.business_problem import identify_business_problem
from portfolio_reorganizer.pillar_assignment import load_service_mappings

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('.migration/reorganization.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

SERVICE_DOMAINS = [
    "compute", "storage", "databases", "networking", "security",
    "devops-cicd", "monitoring", "ai-ml-applications", "modern-applications"
]

def main():
    repo_path = Path.cwd()
    
    logger.info("="*80)
    logger.info("AWS WELL-ARCHITECTED PORTFOLIO REORGANIZATION")
    logger.info("="*80)
    
    # Load existing mapping
    mapping_file = repo_path / ".migration" / "lab-mapping.json"
    if not mapping_file.exists():
        logger.error("Mapping file not found. Run analysis phase first.")
        return
    
    with open(mapping_file, 'r') as f:
        mappings_data = json.load(f)
    
    logger.info(f"Loaded {len(mappings_data)} lab mappings")
    
    # Phase 2: Create pillar directories
    logger.info("\n" + "="*80)
    logger.info("PHASE 2: STRUCTURAL TRANSFORMATION")
    logger.info("="*80)
    
    logger.info("Creating pillar directory structure...")
    create_pillar_directories(repo_path)
    logger.info("✓ Pillar directories created")
    
    # Phase 3: Generate documentation for each lab
    logger.info("\n" + "="*80)
    logger.info("PHASE 3: DOCUMENTATION GENERATION")
    logger.info("="*80)
    
    # Rediscover labs to get full Lab objects
    logger.info("Rediscovering labs...")
    labs = discover_labs(repo_path, SERVICE_DOMAINS)
    lab_dict = {lab.name: lab for lab in labs}
    
    # Load service mappings
    service_mappings_file = Path(__file__).parent / "portfolio_reorganizer" / "aws_service_mappings.json"
    service_mappings = load_service_mappings(service_mappings_file)
    
    # Group labs by pillar
    labs_by_pillar = {}
    
    for mapping_data in mappings_data:
        lab_name = mapping_data['lab_name']
        pillar = mapping_data['primary_pillar']
        
        if pillar not in labs_by_pillar:
            labs_by_pillar[pillar] = []
        
        if lab_name in lab_dict:
            lab = lab_dict[lab_name]
            lab.primary_pillar = pillar
            lab.business_problem = mapping_data['business_problem']
            lab.aws_services = mapping_data['aws_services']
            labs_by_pillar[pillar].append(lab)
    
    # Generate pillar READMEs
    logger.info("Generating pillar README files...")
    for pillar, pillar_labs in labs_by_pillar.items():
        pillar_dir = repo_path / pillar
        readme_content = generate_pillar_readme(pillar, pillar_labs)
        
        readme_path = pillar_dir / "README.md"
        with open(readme_path, 'w', encoding='utf-8') as f:
            f.write(readme_content)
        
        logger.info(f"✓ Generated README for {pillar} ({len(pillar_labs)} projects)")
    
    # Phase 4: Summary
    logger.info("\n" + "="*80)
    logger.info("REORGANIZATION COMPLETE")
    logger.info("="*80)
    
    logger.info(f"\nTotal labs processed: {len(mappings_data)}")
    logger.info("\nDistribution by pillar:")
    for pillar in sorted(labs_by_pillar.keys()):
        count = len(labs_by_pillar[pillar])
        logger.info(f"  {pillar}: {count} projects")
    
    logger.info("\n✓ Pillar directories created")
    logger.info("✓ Pillar README files generated")
    logger.info("\nNext steps:")
    logger.info("1. Review the pillar directories")
    logger.info("2. Manually move labs to their assigned pillars (use .migration/lab-mapping.md as guide)")
    logger.info("3. Generate individual project READMEs as needed")
    logger.info("\nNote: Actual file migration requires manual review to preserve your work safely.")

if __name__ == "__main__":
    main()
