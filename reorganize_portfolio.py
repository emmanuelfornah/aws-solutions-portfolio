#!/usr/bin/env python3
"""
Main orchestration script for AWS Well-Architected Portfolio Reorganization.

This script coordinates the entire reorganization process:
1. Discovery - Find all labs in the portfolio
2. Mapping - Assign labs to Well-Architected pillars
3. Export - Generate mapping reports

Usage:
    python reorganize_portfolio.py [--repo-path PATH] [--phase PHASE]
"""

import argparse
import logging
from pathlib import Path
import sys

from portfolio_reorganizer.discovery import discover_labs
from portfolio_reorganizer.mapping import (
    generate_lab_mapping,
    export_mapping_json,
    export_mapping_markdown
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Service domains to scan
SERVICE_DOMAINS = [
    "compute",
    "storage",
    "databases",
    "networking",
    "security",
    "devops-cicd",
    "monitoring",
    "ai-ml-applications",
    "modern-applications"
]


def phase1_analysis(repo_path: Path) -> None:
    """
    Phase 1: Analysis & Mapping
    
    - Discover all labs
    - Assign pillars
    - Generate business problems
    - Export mappings
    """
    logger.info("=" * 60)
    logger.info("PHASE 1: Analysis & Mapping")
    logger.info("=" * 60)
    
    # Discover labs
    logger.info("Step 1: Discovering labs...")
    labs = discover_labs(repo_path, SERVICE_DOMAINS)
    
    if not labs:
        logger.error("No labs found! Check your repository structure.")
        sys.exit(1)
    
    logger.info(f"Found {len(labs)} labs")
    
    # Generate mappings
    logger.info("Step 2: Generating lab mappings...")
    service_mappings_file = Path(__file__).parent / "portfolio_reorganizer" / "aws_service_mappings.json"
    mappings = generate_lab_mapping(labs, service_mappings_file)
    
    # Export mappings
    logger.info("Step 3: Exporting mappings...")
    migration_dir = repo_path / ".migration"
    migration_dir.mkdir(exist_ok=True)
    
    export_mapping_json(mappings, migration_dir / "lab-mapping.json")
    export_mapping_markdown(mappings, migration_dir / "lab-mapping.md")
    
    # Summary
    logger.info("=" * 60)
    logger.info("PHASE 1 COMPLETE")
    logger.info("=" * 60)
    logger.info(f"Total labs mapped: {len(mappings)}")
    
    # Count by pillar
    pillar_counts = {}
    for mapping in mappings:
        pillar = mapping.primary_pillar
        pillar_counts[pillar] = pillar_counts.get(pillar, 0) + 1
    
    logger.info("\nDistribution by pillar:")
    for pillar in sorted(pillar_counts.keys()):
        logger.info(f"  {pillar}: {pillar_counts[pillar]} labs")
    
    logger.info(f"\nMapping files created:")
    logger.info(f"  - {migration_dir / 'lab-mapping.json'}")
    logger.info(f"  - {migration_dir / 'lab-mapping.md'}")
    logger.info("\nReview the mapping files before proceeding to Phase 2 (migration).")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="AWS Well-Architected Portfolio Reorganization Tool"
    )
    parser.add_argument(
        "--repo-path",
        type=Path,
        default=Path.cwd(),
        help="Path to the portfolio repository (default: current directory)"
    )
    parser.add_argument(
        "--phase",
        choices=["analyze", "migrate", "document", "validate", "full"],
        default="analyze",
        help="Phase to execute (default: analyze)"
    )
    
    args = parser.parse_args()
    
    # Validate repository path
    if not args.repo_path.exists():
        logger.error(f"Repository path does not exist: {args.repo_path}")
        sys.exit(1)
    
    logger.info(f"Repository path: {args.repo_path}")
    logger.info(f"Phase: {args.phase}")
    
    # Execute requested phase
    if args.phase == "analyze":
        phase1_analysis(args.repo_path)
    elif args.phase == "migrate":
        logger.error("Phase 2 (migrate) not yet implemented")
        sys.exit(1)
    elif args.phase == "document":
        logger.error("Phase 3 (document) not yet implemented")
        sys.exit(1)
    elif args.phase == "validate":
        logger.error("Phase 4 (validate) not yet implemented")
        sys.exit(1)
    elif args.phase == "full":
        logger.error("Full workflow not yet implemented")
        sys.exit(1)


if __name__ == "__main__":
    main()
