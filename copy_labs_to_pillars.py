#!/usr/bin/env python3
"""
Copy labs to pillar directories (OneDrive-safe approach)
After copying, you can manually delete the old directories and git will detect the move.
"""

import json
import shutil
from pathlib import Path

def main():
    repo_path = Path.cwd()
    
    # Load mapping
    mapping_file = repo_path / ".migration" / "lab-mapping.json"
    with open(mapping_file, 'r') as f:
        mappings = json.load(f)
    
    print("Copying labs to pillar directories...")
    print("=" * 60)
    
    for mapping in mappings:
        lab_name = mapping['lab_name']
        original_path = mapping['original_path'].replace('\\', '/')
        pillar = mapping['primary_pillar']
        
        source = repo_path / original_path
        destination = repo_path / pillar / lab_name
        
        if not source.exists():
            print(f"⊘ Skip: {lab_name} (source not found)")
            continue
        
        if destination.exists():
            print(f"⊘ Skip: {lab_name} (already exists in {pillar})")
            continue
        
        try:
            shutil.copytree(source, destination)
            print(f"✓ Copied: {lab_name} → {pillar}/")
        except Exception as e:
            print(f"✗ Failed: {lab_name} - {str(e)}")
    
    print("\n" + "=" * 60)
    print("COPY COMPLETE")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Verify the copied labs in pillar directories")
    print("2. Delete the old service domain directories (compute/, databases/, etc.)")
    print("3. Run: git add -A")
    print("4. Run: git status (git will detect the moves)")
    print("5. Run: git commit -m 'Reorganize portfolio by AWS Well-Architected pillars'")

if __name__ == "__main__":
    main()
