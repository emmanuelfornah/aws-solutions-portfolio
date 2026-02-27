# Implementation Plan: AWS Well-Architected Portfolio Reorganization

## Overview

This implementation plan transforms the AWS Cloud Institute portfolio from a service-domain structure (compute, storage, databases, etc.) into an AWS Well-Architected Framework structure organized by six pillars. The plan follows a three-phase approach: Analysis & Mapping, Structural Transformation, and Validation & Quality Assurance.

The implementation uses Python and follows the design document's architecture with components for lab discovery, pillar assignment, business problem identification, directory management, documentation generation, and validation.

## Tasks

### Phase 1: Analysis & Mapping

- [x] 1. Set up project infrastructure and data models
  - [x] 1.1 Create Python project structure with core modules
    - Create `portfolio_reorganizer/` package with modules: `discovery.py`, `pillar_assignment.py`, `business_problem.py`, `migration.py`, `documentation.py`, `validation.py`
    - Create `portfolio_reorganizer/models.py` with Lab, LabMapping, MigrationLog, ValidationReport dataclasses
    - Set up `pyproject.toml` with dependencies: `hypothesis` for property testing, `pytest` for unit testing, `gitpython` for git operations, `pydantic` for data validation
    - _Requirements: 1.1, 1.3, 3.1_
  
  - [ ]* 1.2 Write unit tests for data models
    - Test Lab model instantiation and validation
    - Test LabMapping model with edge cases (empty lists, None values)
    - Test MigrationLog and ValidationReport models
    - _Requirements: 1.3_

- [x] 2. Implement Lab Discovery Engine
  - [x] 2.1 Create lab discovery functionality
    - Implement `discover_labs(repo_root: Path, service_domains: List[str]) -> List[Lab]` function
    - Scan all service domain directories (compute, storage, databases, networking, security, devops-cicd, monitoring, ai-ml-applications, modern-applications)
    - Identify labs by presence of README.md in subdirectories
    - Extract metadata: lab name, path, domain, AWS services from README content
    - Handle missing directories gracefully with logging
    - _Requirements: 1.1_
  
  - [ ]* 2.2 Write property test for lab discovery
    - **Property 1: Complete Lab Discovery and Assignment**
    - **Validates: Requirements 1.1, 1.3, 1.5**
    - Generate repositories with random labs across domains
    - Verify all labs with README.md are discovered
    - Verify no false positives (directories without README.md)
  
  - [ ]* 2.3 Write unit tests for lab discovery edge cases
    - Test empty repository (no service domains)
    - Test service domain with no labs
    - Test malformed README files
    - Test labs with missing architecture.md
    - _Requirements: 1.1_

- [x] 3. Implement Pillar Assignment Engine
  - [x] 3.1 Create AWS service to pillar mapping configuration
    - Create `aws_service_mappings.json` with service-to-pillar associations
    - Map 50+ common AWS services to primary and secondary pillars
    - Include services: IAM, KMS, WAF, Cognito (Security); CloudFormation, CodePipeline (Operational Excellence); Auto Scaling, RDS Multi-AZ (Reliability); CloudFront, ElastiCache (Performance Efficiency); Cost Explorer, Trusted Advisor (Cost Optimization)
    - _Requirements: 1.2_
  
  - [x] 3.2 Implement pillar scoring algorithm
    - Create `calculate_pillar_scores(lab: Lab, service_mappings: dict) -> Dict[str, float]` function
    - Implement weighted scoring: AWS services (40%), documentation keywords (30%), architecture patterns (30%)
    - Extract AWS services from lab README content using regex patterns
    - Scan for pillar-specific keywords (encryption, high availability, cost optimization, etc.)
    - Identify architecture patterns (CI/CD, zero-trust, auto-scaling, etc.)
    - _Requirements: 1.2_
  
  - [x] 3.3 Implement pillar assignment with conflict resolution
    - Create `assign_pillar(lab: Lab) -> LabMapping` function
    - Select primary pillar as highest scoring pillar
    - Identify secondary pillars (scores above threshold, e.g., 0.3)
    - Generate assignment rationale explaining the decision
    - Handle edge case: no clear pillar match (default to operational-excellence)
    - Calculate confidence score (0.0 to 1.0)
    - _Requirements: 1.2, 1.4, 1.6_
  
  - [ ]* 3.4 Write property test for consistent pillar assignment
    - **Property 2: Consistent Pillar Assignment**
    - **Validates: Requirements 1.2**
    - Generate labs with fixed AWS services and content
    - Run pillar assignment multiple times
    - Verify deterministic results (same primary pillar every time)
  
  - [ ]* 3.5 Write property test for multi-pillar handling
    - **Property 4: Multi-Pillar Handling**
    - **Validates: Requirements 1.4**
    - Generate labs that score high on multiple pillars
    - Verify exactly one primary pillar assigned
    - Verify secondary pillars listed correctly
  
  - [ ]* 3.6 Write unit tests for pillar assignment edge cases
    - Test lab with no AWS services mentioned
    - Test lab with only generic services (EC2, S3)
    - Test lab with conflicting pillar signals
    - Test confidence score calculation
    - _Requirements: 1.2, 1.4_

- [x] 4. Implement Business Problem Identifier
  - [x] 4.1 Create business problem generation logic
    - Create `identify_business_problem(lab: Lab, pillar: str) -> BusinessProblem` function
    - Define problem templates for each pillar and common service combinations
    - Extract key services and architecture patterns from lab documentation
    - Transform learning objectives to business value statements
    - Generate solution summary and business value proposition
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  
  - [ ]* 4.2 Write property test for business problem quality
    - **Property 6: Business Problem Quality**
    - **Validates: Requirements 2.1, 2.2, 2.3**
    - Generate random labs with various content
    - Verify business problems don't contain learning keywords (learn, understand, practice)
    - Verify business problems contain business value keywords (reduce, improve, ensure, achieve)
  
  - [ ]* 4.3 Write unit tests for business problem generation
    - Test problem generation for each pillar
    - Test with known lab examples (Lambda → serverless cost optimization)
    - Test edge case: lab with minimal documentation
    - Verify solution summary quality
    - _Requirements: 2.1, 2.2, 2.3, 2.5_

- [x] 5. Generate complete lab mapping document
  - [x] 5.1 Create mapping generation and export functionality
    - Implement `generate_lab_mapping(labs: List[Lab]) -> List[LabMapping]` function
    - Run discovery, pillar assignment, and business problem identification for all labs
    - Export mapping to `.migration/lab-mapping.json` with all metadata
    - Create human-readable `.migration/lab-mapping.md` with rationale for each assignment
    - _Requirements: 1.3, 1.6, 2.4_
  
  - [ ]* 5.2 Write property test for mapping completeness
    - **Property 5: Mapping Completeness**
    - **Validates: Requirements 1.6, 2.4**
    - Generate random labs and create mappings
    - Verify all mapping entries have non-empty: lab_name, primary_pillar, business_problem, aws_services, assignment_rationale
  
  - [ ]* 5.3 Write unit tests for mapping export
    - Test JSON export format and schema
    - Test markdown export readability
    - Test handling of special characters in lab names
    - _Requirements: 1.3_

- [ ] 6. Checkpoint - Review Phase 1 outputs
  - Review `.migration/lab-mapping.json` and `.migration/lab-mapping.md`
  - Verify all 150+ labs are mapped with rationale
  - Ensure all tests pass, ask the user if questions arise

### Phase 2: Structural Transformation

- [x] 7. Implement Directory Structure Manager
  - [x] 7.1 Create pillar directory structure
    - Implement `create_pillar_directories(repo_root: Path)` function
    - Create six top-level directories: operational-excellence, security, reliability, performance-efficiency, cost-optimization, sustainability
    - Create `.migration/` directory for logs and reports
    - Create pillar-level README.md templates for each directory
    - _Requirements: 3.1_
  
  - [ ]* 7.2 Write unit tests for directory creation
    - Test directory creation in empty repository
    - Test handling of existing directories (no overwrite)
    - Test permission errors
    - _Requirements: 3.1_

- [ ] 8. Implement Git-aware lab migration
  - [x] 8.1 Create lab migration functionality with git history preservation
    - Implement `migrate_lab(lab: Lab, mapping: LabMapping, repo: GitRepo) -> MigrationLog` function
    - Use `git mv` command to preserve commit history
    - Move lab directory from service domain to assigned pillar directory
    - Handle duplicate lab names (append suffix, log conflict)
    - Create migration log entry for each operation
    - _Requirements: 3.2, 3.3, 3.4, 6.1, 6.2_
  
  - [ ]* 8.2 Write property test for file preservation during migration
    - **Property 3: File Preservation During Migration**
    - **Validates: Requirements 3.3, 6.1**
    - Generate labs with random files (scripts, configs, docs)
    - Migrate labs to pillar directories
    - Verify all files exist in new location with identical content
  
  - [ ]* 8.3 Write property test for git history preservation
    - **Property 10: Git History Preservation**
    - **Validates: Requirements 3.4**
    - Create labs with commit history
    - Migrate labs using git mv
    - Verify `git log --follow` shows complete history
  
  - [ ]* 8.4 Write property test for correct pillar migration
    - **Property 9: Lab Migration to Correct Pillar**
    - **Validates: Requirements 3.2**
    - Generate labs with pillar assignments
    - Migrate all labs
    - Verify each lab exists in its assigned pillar directory
  
  - [ ]* 8.5 Write unit tests for migration edge cases
    - Test duplicate lab names across domains
    - Test migration with file permission errors
    - Test migration rollback on failure
    - Test migration log generation
    - _Requirements: 3.2, 3.3, 3.4, 6.2, 6.6_

- [ ] 9. Implement internal reference updater
  - [x] 9.1 Create link and reference update functionality
    - Implement `update_internal_references(lab_dir: Path, old_path: str, new_path: str)` function
    - Find all markdown files in migrated lab directory
    - Extract relative path links using regex
    - Update links to reflect new directory structure
    - Handle both relative (`../compute/other-lab`) and absolute paths
    - Log all link updates
    - _Requirements: 3.5_
  
  - [ ]* 9.2 Write property test for internal link updates
    - **Property 11: Internal Link Updates**
    - **Validates: Requirements 3.5**
    - Generate repository with cross-references between labs
    - Reorganize portfolio
    - Verify all internal links resolve to existing files
  
  - [ ]* 9.3 Write unit tests for reference updates
    - Test relative path link updates
    - Test links to files within same lab (should not change)
    - Test links to external resources (should not change)
    - Test markdown image links
    - _Requirements: 3.5_

- [ ] 10. Checkpoint - Verify migration integrity
  - Run migration on test repository copy
  - Verify git history preserved for sample labs
  - Verify no files lost during migration
  - Ensure all tests pass, ask the user if questions arise

### Phase 3: Documentation Generation

- [ ] 11. Implement Documentation Generator
  - [x] 11.1 Create mini-project README template
    - Create `templates/mini_project_readme.md` template file
    - Include sections: Business Problem, Solution Architecture, AWS Services Used, Implementation Details, Results/Outcomes, Key Learnings, Well-Architected Alignment, Related Projects
    - Add placeholders for dynamic content (business problem, services, pillar)
    - _Requirements: 4.1_
  
  - [ ]* 11.2 Write unit tests for template structure
    - Test template has all required sections
    - Test template placeholder syntax
    - _Requirements: 4.1_

- [ ] 12. Implement README generation and content merging
  - [x] 12.1 Create README generation functionality
    - Implement `generate_project_readme(lab: Lab, mapping: LabMapping, business_problem: BusinessProblem) -> str` function
    - Load mini-project README template
    - Populate Business Problem section with business_problem.statement
    - Populate AWS Services Used section with mapping.aws_services
    - Extract and preserve valuable content from existing lab README
    - Merge existing technical content into appropriate template sections
    - Add architecture diagram references if architecture.md exists
    - Generate Well-Architected Alignment section with pillar explanation
    - _Requirements: 4.2, 4.3, 4.4, 4.5, 4.7, 6.3_
  
  - [ ]* 12.2 Write property test for README generation and population
    - **Property 7: README Generation and Population**
    - **Validates: Requirements 4.2, 4.3, 4.4, 4.7**
    - Generate random labs with mappings
    - Generate READMEs for all labs
    - Verify README exists in project directory
    - Verify all required sections present
    - Verify Business Problem section populated correctly
    - Verify AWS services listed
  
  - [ ]* 12.3 Write property test for architecture diagram references
    - **Property 8: Architecture Diagram References**
    - **Validates: Requirements 4.5**
    - Generate labs with architecture files
    - Generate READMEs
    - Verify READMEs contain references to architecture files
  
  - [ ]* 12.4 Write property test for content preservation
    - **Property 13: Content Preservation from Original README**
    - **Validates: Requirements 6.3**
    - Generate labs with rich existing README content
    - Generate new READMEs
    - Verify technical content incorporated into new README
  
  - [ ]* 12.5 Write unit tests for README generation
    - Test README generation with minimal lab data
    - Test README generation with complete lab data
    - Test content merging from existing README
    - Test architecture diagram link generation
    - Test handling of missing business problem
    - _Requirements: 4.2, 4.3, 4.4, 4.5, 4.7, 6.3_

- [x] 13. Generate pillar-level README files
  - [x] 13.1 Create pillar README generation functionality
    - Implement `generate_pillar_readme(pillar: str, labs: List[Lab]) -> str` function
    - Create pillar overview explaining the Well-Architected pillar
    - List all mini-projects in the pillar with brief descriptions
    - Add navigation links to each mini-project
    - Include pillar-specific best practices and principles
    - _Requirements: 5.2_
  
  - [ ]* 13.2 Write unit tests for pillar README generation
    - Test README generation for each pillar
    - Test with varying numbers of labs (0, 1, 10, 50)
    - Test navigation link generation
    - _Requirements: 5.2_

- [ ] 14. Update main portfolio README
  - [ ] 14.1 Create main README update functionality
    - Implement `update_main_readme(repo_root: Path, mappings: List[LabMapping])` function
    - Preserve existing sections (education, certifications, contact)
    - Add Well-Architected Framework overview section with pillar descriptions
    - Create navigation section with links to each pillar directory
    - Add mini-project count summary per pillar
    - Highlight skills for Cloud Ops, SRE, DevOps, Developer, Architect roles
    - Ensure scannable format (5-10 minute read time)
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_
  
  - [ ]* 14.2 Write property test for main README pillar counts
    - **Property 12: Main README Pillar Counts**
    - **Validates: Requirements 5.7**
    - Generate repository with random lab distribution
    - Update main README
    - Verify pillar counts in README match actual directory counts
  
  - [ ]* 14.3 Write unit tests for main README update
    - Test preservation of existing content
    - Test pillar count calculation
    - Test navigation link generation
    - Test Well-Architected section formatting
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

- [ ] 15. Checkpoint - Review generated documentation
  - Review sample mini-project READMEs for quality and completeness
  - Review pillar-level READMEs for accuracy
  - Review main README for professional presentation
  - Ensure all tests pass, ask the user if questions arise

### Phase 4: Validation & Quality Assurance

- [ ] 16. Implement Validation Engine
  - [ ] 16.1 Create completeness validation
    - Implement `validate_completeness(repo_root: Path, mappings: List[LabMapping]) -> ValidationReport` function
    - Verify all labs have README.md in their pillar directories
    - Verify all READMEs contain required sections
    - Check for missing architecture diagrams where expected
    - Calculate completeness percentage
    - _Requirements: 7.1, 7.2_
  
  - [ ] 16.2 Create link validation functionality
    - Implement `validate_links(repo_root: Path) -> List[str]` function
    - Extract all internal links from markdown files
    - Resolve relative paths and verify target files exist
    - Identify broken links and generate report
    - _Requirements: 7.3_
  
  - [ ] 16.3 Create pillar distribution analysis
    - Implement `analyze_pillar_distribution(mappings: List[LabMapping]) -> Dict[str, int]` function
    - Count labs per pillar
    - Identify empty pillars
    - Flag disproportionate distributions (e.g., 80% in one pillar)
    - _Requirements: 7.4_
  
  - [ ] 16.4 Generate comprehensive validation report
    - Implement `generate_validation_report(repo_root: Path, mappings: List[LabMapping]) -> ValidationReport` function
    - Run all validation checks (completeness, links, distribution)
    - Calculate overall quality score (0-100)
    - Generate recommendations for improvements
    - Export report to `.migration/validation-report.md`
    - _Requirements: 7.5_
  
  - [ ]* 16.5 Write property test for validation completeness
    - **Property 15: Validation Completeness**
    - **Validates: Requirements 7.2, 7.3, 7.4, 7.5**
    - Generate reorganized repositories with various issues
    - Run validation
    - Verify validation report covers all required checks
    - Verify issues are correctly identified
  
  - [ ]* 16.6 Write unit tests for validation engine
    - Test completeness validation with missing READMEs
    - Test link validation with broken links
    - Test pillar distribution analysis
    - Test quality score calculation
    - Test validation report generation
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 17. Implement conflict detection and documentation
  - [ ] 17.1 Create conflict detection functionality
    - Implement `detect_conflicts(migration_logs: List[MigrationLog]) -> List[Conflict]` function
    - Identify duplicate lab names across pillars
    - Identify file collisions during migration
    - Identify labs that couldn't be assigned to pillars
    - _Requirements: 6.6_
  
  - [ ] 17.2 Create conflict resolution documentation
    - Implement `document_conflicts(conflicts: List[Conflict])` function
    - Create `.migration/conflicts.md` with detailed conflict descriptions
    - Preserve both versions of conflicting items
    - Provide resolution recommendations
    - _Requirements: 6.6_
  
  - [ ]* 17.3 Write property test for conflict documentation
    - **Property 14: Conflict Documentation**
    - **Validates: Requirements 6.6**
    - Generate scenarios with conflicts (duplicate names, file collisions)
    - Run reorganization
    - Verify conflicts are logged
    - Verify both versions preserved
  
  - [ ]* 17.4 Write unit tests for conflict detection
    - Test duplicate lab name detection
    - Test file collision detection
    - Test conflict report generation
    - _Requirements: 6.6_

- [ ] 18. Create migration guidelines for future labs
  - [ ] 18.1 Generate guidelines document
    - Create `.migration/adding-new-labs.md` with instructions
    - Document how to determine pillar for new labs
    - Provide mini-project README template usage guide
    - Include examples of pillar assignment for common scenarios
    - _Requirements: 6.4, 6.5_
  
  - [ ]* 18.2 Write unit tests for guidelines generation
    - Test guidelines document creation
    - Verify all required sections present
    - _Requirements: 6.4, 6.5_

- [ ] 19. Final checkpoint - Complete validation
  - Run full validation on reorganized portfolio
  - Review validation report and address any critical issues
  - Verify portfolio is navigable within 5-10 minutes
  - Ensure all tests pass, ask the user if questions arise

### Phase 5: Integration & Orchestration

- [ ] 20. Create main orchestration script
  - [ ] 20.1 Implement end-to-end reorganization orchestrator
    - Create `reorganize_portfolio.py` main script
    - Implement `reorganize_portfolio(repo_path: Path) -> Result` function with transactional migration
    - Orchestrate all phases: discovery → mapping → migration → documentation → validation
    - Implement rollback capability using git transactions
    - Add progress logging and user feedback
    - Handle errors gracefully with detailed error messages
    - _Requirements: All_
  
  - [ ]* 20.2 Write integration test for end-to-end reorganization
    - Create sample portfolio with 10-20 labs across domains
    - Run complete reorganization
    - Verify all phases complete successfully
    - Verify final structure matches expected output
    - _Requirements: All_
  
  - [ ]* 20.3 Write unit tests for orchestration
    - Test rollback on migration failure
    - Test error handling for each phase
    - Test progress logging
    - _Requirements: All_

- [ ] 21. Create CLI interface
  - [ ] 21.1 Implement command-line interface
    - Create CLI using `argparse` or `click`
    - Add commands: `analyze` (Phase 1 only), `migrate` (Phase 2 only), `document` (Phase 3 only), `validate` (Phase 4 only), `full` (all phases)
    - Add options: `--dry-run`, `--verbose`, `--output-dir`
    - Add interactive mode for reviewing mappings before migration
    - _Requirements: All_
  
  - [ ]* 21.2 Write unit tests for CLI
    - Test command parsing
    - Test dry-run mode
    - Test verbose output
    - _Requirements: All_

- [ ] 22. Archive old service domain structure
  - [ ] 22.1 Create archival functionality
    - Implement `archive_old_structure(repo_root: Path)` function
    - Move old service domain directories to `.migration/archive/`
    - Preserve directory structure in archive
    - Create archive manifest documenting what was archived
    - _Requirements: 3.6_
  
  - [ ]* 22.2 Write unit tests for archival
    - Test directory archival
    - Test manifest generation
    - Test handling of non-empty directories
    - _Requirements: 3.6_

- [ ] 23. Final integration and testing
  - [ ] 23.1 Run complete reorganization on actual portfolio
    - Create backup of current repository
    - Run `reorganize_portfolio.py --full` on actual portfolio
    - Review all generated documentation
    - Verify git history preserved
    - Review validation report
    - _Requirements: All_
  
  - [ ] 23.2 Manual quality review
    - Navigate portfolio as hiring manager would (5-10 minute test)
    - Verify professional presentation
    - Check for broken links manually
    - Review sample mini-project READMEs for quality
    - _Requirements: 7.6_
  
  - [ ] 23.3 Address validation report findings
    - Fix any broken links identified
    - Complete any missing documentation
    - Resolve any conflicts
    - Re-run validation to verify fixes
    - _Requirements: 7.5_

- [ ] 24. Final checkpoint - Portfolio ready for deployment
  - Verify all 150+ labs successfully reorganized
  - Verify all documentation generated and professional
  - Verify validation report shows high quality score
  - Commit final changes to git
  - Update main README with completion date

## Notes

- Tasks marked with `*` are optional testing tasks and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation and user feedback
- Property tests validate universal correctness properties across all inputs
- Unit tests validate specific examples, edge cases, and integration points
- The implementation uses Python with `hypothesis` for property-based testing
- Git history preservation is critical - always use `git mv` for file operations
- The orchestration script includes rollback capability for safe execution
- All phases can be run independently or as a complete workflow
- The validation phase ensures professional quality before deployment

## Testing Summary

- 15 correctness properties implemented as property-based tests
- Each property test runs minimum 100 iterations
- Unit tests cover edge cases, integration points, and error conditions
- Integration test validates end-to-end reorganization workflow
- Target: 80% code coverage for unit tests
- All property tests must pass before deployment
