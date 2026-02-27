# Design Document: AWS Well-Architected Portfolio Reorganization

## Overview

This design document specifies the architecture and implementation approach for reorganizing an AWS Cloud Institute portfolio from a service-domain structure into an AWS Well-Architected Framework structure. The reorganization transforms 150+ individual labs across 9 service domains into business-problem-focused mini-projects organized by the six Well-Architected pillars: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, and Sustainability.

### Goals

1. **Reframe Technical Work as Business Solutions**: Transform learning-focused lab documentation into professional mini-projects that demonstrate business value
2. **Align with Industry Standards**: Organize portfolio using AWS Well-Architected Framework principles recognized by hiring managers
3. **Preserve Existing Work**: Maintain all lab files, configurations, scripts, and documentation with full git history
4. **Enable Future Growth**: Design flexible structure to accommodate additional labs and projects
5. **Professional Presentation**: Create consistent, scannable documentation optimized for technical recruiters and hiring managers

### Target Audience

- **Primary**: Technical hiring managers and recruiters for Cloud Operations, SRE, DevOps, Developer, and Architect roles
- **Secondary**: Portfolio owner (for ongoing maintenance and additions)

### Success Criteria

- All 150+ labs mapped to Well-Architected pillars with documented rationale
- Each lab repositioned as a mini-project with business problem context
- Portfolio navigable and understandable within 5-10 minutes
- All existing work preserved with git history intact
- Zero broken links or missing documentation
- Structure accommodates future lab additions

## Architecture

### High-Level Architecture

The portfolio reorganization follows a three-phase transformation pipeline:

```
Phase 1: Analysis & Mapping
├── Lab Discovery (scan all service domains)
├── Pillar Assignment (map to Well-Architected Framework)
└── Business Problem Identification

Phase 2: Structural Transformation
├── Directory Structure Creation (6 pillar directories)
├── Lab Migration (preserve git history)
└── Documentation Generation (standardized READMEs)

Phase 3: Validation & Quality Assurance
├── Completeness Verification
├── Link Validation
└── Quality Report Generation
```

### Well-Architected Framework Mapping Strategy

The mapping strategy uses a decision tree based on AWS service characteristics and lab focus:

**Primary Pillar Assignment Logic**:
1. **Security**: Labs focused on IAM, encryption, authentication, authorization, compliance, vulnerability scanning
2. **Reliability**: Labs focused on high availability, disaster recovery, backup/restore, fault tolerance, auto-scaling
3. **Performance Efficiency**: Labs focused on compute optimization, caching, CDN, database performance, right-sizing
4. **Cost Optimization**: Labs focused on resource optimization, reserved instances, spot instances, cost monitoring
5. **Operational Excellence**: Labs focused on automation, CI/CD, monitoring, logging, incident response, IaC
6. **Sustainability**: Labs focused on resource efficiency, carbon footprint reduction, sustainable architecture patterns

**Conflict Resolution**: When a lab demonstrates multiple pillars, assign to the pillar that represents the lab's primary learning objective or most prominent AWS service usage.

### Directory Structure Design

```
portfolio-root/
├── operational-excellence/
│   ├── README.md (pillar overview + mini-project index)
│   ├── cicd-pipeline-automation/
│   │   ├── README.md (mini-project documentation)
│   │   ├── architecture.md
│   │   ├── configs/
│   │   └── scripts/
│   └── [additional mini-projects...]
├── security/
│   ├── README.md
│   ├── api-gateway-cognito-authorizer/
│   └── [additional mini-projects...]
├── reliability/
│   ├── README.md
│   └── [mini-projects...]
├── performance-efficiency/
│   ├── README.md
│   └── [mini-projects...]
├── cost-optimization/
│   ├── README.md
│   └── [mini-projects...]
├── sustainability/
│   ├── README.md
│   └── [mini-projects...]
├── README.md (main portfolio entry point)
├── SKILLS_MATRIX.md
├── LEARNING_JOURNEY.md
└── .migration/
    ├── lab-mapping.json (complete mapping data)
    ├── migration-log.md (file move history)
    └── validation-report.md
```

## Components and Interfaces

### Component 1: Lab Discovery Engine

**Purpose**: Scan the portfolio repository to identify all existing labs across service domains.

**Inputs**:
- Repository root path
- List of service domain directories (compute, storage, databases, networking, security, devops-cicd, monitoring, ai-ml-applications, modern-applications)

**Outputs**:
- Structured list of all labs with metadata:
  - Lab name
  - Current path
  - Service domain
  - Existing documentation files (README.md, architecture.md)
  - AWS services used (extracted from documentation)

**Algorithm**:
```python
def discover_labs(repo_root: Path, service_domains: List[str]) -> List[Lab]:
    labs = []
    for domain in service_domains:
        domain_path = repo_root / domain
        if not domain_path.exists():
            continue
        
        # Find all subdirectories with README.md (indicates a lab)
        for lab_dir in domain_path.iterdir():
            if lab_dir.is_dir() and (lab_dir / "README.md").exists():
                lab = Lab(
                    name=lab_dir.name,
                    path=lab_dir,
                    domain=domain,
                    readme_path=lab_dir / "README.md",
                    architecture_path=lab_dir / "architecture.md" if (lab_dir / "architecture.md").exists() else None
                )
                labs.append(lab)
    
    return labs
```

### Component 2: Pillar Assignment Engine

**Purpose**: Analyze each lab and assign it to the most appropriate Well-Architected pillar.

**Inputs**:
- Lab metadata (from Lab Discovery Engine)
- Lab documentation content (README.md, architecture.md)
- AWS service catalog with pillar associations

**Outputs**:
- Lab mapping with:
  - Primary pillar assignment
  - Secondary pillars (if applicable)
  - Assignment rationale
  - Confidence score

**Decision Logic**:

The engine uses a weighted scoring system based on:
1. **AWS Services Used** (40% weight): Each AWS service has predefined pillar associations
2. **Documentation Keywords** (30% weight): Scan for pillar-specific terms (e.g., "encryption", "high availability", "cost optimization")
3. **Architecture Patterns** (30% weight): Identify patterns like "CI/CD pipeline", "zero-trust", "auto-scaling"

**AWS Service to Pillar Mapping** (examples):
```json
{
  "IAM": ["security"],
  "KMS": ["security"],
  "WAF": ["security"],
  "Cognito": ["security"],
  "CloudFormation": ["operational-excellence"],
  "CodePipeline": ["operational-excellence"],
  "Auto Scaling": ["reliability", "cost-optimization"],
  "RDS Multi-AZ": ["reliability"],
  "CloudFront": ["performance-efficiency"],
  "ElastiCache": ["performance-efficiency"],
  "Cost Explorer": ["cost-optimization"],
  "Trusted Advisor": ["cost-optimization", "sustainability"]
}
```

### Component 3: Business Problem Identifier

**Purpose**: Transform learning-focused lab descriptions into business problem statements.

**Inputs**:
- Lab documentation
- Lab title and description
- AWS services used
- Assigned pillar

**Outputs**:
- Business problem statement
- Solution summary
- Business value proposition

**Transformation Strategy**:

Convert learning objectives to business problems using templates:

| Learning Focus | Business Problem Template |
|----------------|---------------------------|
| "Deploy Lambda function" | "Reduce operational costs and improve scalability by implementing serverless architecture" |
| "Configure WAF rules" | "Protect web applications from common security threats and ensure compliance" |
| "Set up CI/CD pipeline" | "Accelerate software delivery and reduce deployment errors through automation" |
| "Implement auto-scaling" | "Ensure application availability during traffic spikes while optimizing costs" |
| "Configure RDS Multi-AZ" | "Achieve high availability and disaster recovery for critical databases" |

**Algorithm**:
```python
def identify_business_problem(lab: Lab, pillar: str) -> BusinessProblem:
    # Extract key services and patterns
    services = extract_aws_services(lab.readme_content)
    patterns = identify_architecture_patterns(lab.readme_content)
    
    # Generate business problem based on pillar and services
    problem_template = get_problem_template(pillar, services, patterns)
    
    return BusinessProblem(
        statement=problem_template.format(services=services),
        solution_summary=generate_solution_summary(lab),
        business_value=calculate_business_value(pillar, services)
    )
```

### Component 4: Directory Structure Manager

**Purpose**: Create the new Well-Architected directory structure and manage lab migration.

**Inputs**:
- Lab mapping (from Pillar Assignment Engine)
- Repository root path

**Outputs**:
- New directory structure
- Migration log (file moves with git history)
- Conflict report (if any)

**Operations**:
1. **Create Pillar Directories**: Create six top-level directories with pillar READMEs
2. **Migrate Labs**: Use `git mv` to preserve history
3. **Update References**: Update relative paths in documentation
4. **Archive Old Structure**: Move old service domain directories to `.migration/archive/`

**Git History Preservation**:
```bash
# Use git mv to preserve history
git mv compute/lambda-url-checker operational-excellence/serverless-cost-optimization

# Update internal references
find operational-excellence/serverless-cost-optimization -type f -name "*.md" \
  -exec sed -i 's|../compute/|../operational-excellence/|g' {} \;
```

### Component 5: Documentation Generator

**Purpose**: Generate standardized mini-project READMEs using a consistent template.

**Inputs**:
- Lab metadata
- Business problem statement
- Existing lab documentation

**Outputs**:
- Standardized README.md for each mini-project
- Pillar-level README.md files
- Updated main README.md

**Mini-Project README Template**:
```markdown
# [Mini-Project Title]

## Business Problem

[Clear statement of the business challenge this project addresses]

## Solution Architecture

[High-level description of the solution approach]

### Architecture Diagram

[Include or reference existing architecture diagram]

## AWS Services Used

- **[Service 1]**: [Purpose in this solution]
- **[Service 2]**: [Purpose in this solution]
- [Additional services...]

## Implementation Details

### Prerequisites
[Required AWS resources, permissions, tools]

### Deployment Steps
[High-level deployment process]

### Configuration
[Key configuration decisions and files]

## Results and Outcomes

- [Measurable outcome 1, e.g., "Reduced deployment time by 80%"]
- [Measurable outcome 2, e.g., "Achieved 99.9% uptime"]
- [Business impact statement]

## Key Learnings

- [Technical insight 1]
- [Best practice 1]
- [Challenge overcome]

## Well-Architected Alignment

**Primary Pillar**: [Pillar Name]
**Secondary Pillars**: [If applicable]

This project demonstrates [pillar name] principles through:
- [Specific principle 1]
- [Specific principle 2]

## Related Projects

- [Link to related mini-project 1]
- [Link to related mini-project 2]

---

**Original Lab**: [Link to AWS Cloud Institute course/lab if applicable]
**Implementation Date**: [Date]
**AWS Services**: [Comma-separated list for searchability]
```

### Component 6: Validation Engine

**Purpose**: Verify the reorganized portfolio meets quality standards.

**Inputs**:
- Reorganized repository structure
- Lab mapping data
- Expected completeness criteria

**Outputs**:
- Validation report with:
  - Completeness metrics (% labs with READMEs, architecture diagrams)
  - Broken link report
  - Missing documentation list
  - Quality score (0-100)

**Validation Checks**:
1. **Completeness**: All labs have standardized READMEs
2. **Link Integrity**: All internal links resolve correctly
3. **Pillar Balance**: No pillar is empty or disproportionately large
4. **Documentation Quality**: READMEs follow template structure
5. **Git History**: All files have preserved commit history
6. **Navigation**: Main README accurately reflects structure

## Data Models

### Lab Model
```python
@dataclass
class Lab:
    name: str
    path: Path
    domain: str  # Original service domain
    readme_path: Path
    architecture_path: Optional[Path]
    aws_services: List[str]
    primary_pillar: Optional[str] = None
    secondary_pillars: List[str] = field(default_factory=list)
    business_problem: Optional[str] = None
    assignment_rationale: Optional[str] = None
```

### LabMapping Model
```python
@dataclass
class LabMapping:
    lab_name: str
    original_path: str
    new_path: str
    primary_pillar: str
    secondary_pillars: List[str]
    business_problem: str
    aws_services: List[str]
    assignment_rationale: str
    confidence_score: float  # 0.0 to 1.0
```

### MigrationLog Model
```python
@dataclass
class MigrationLog:
    timestamp: datetime
    operation: str  # "move", "create", "update"
    source_path: Optional[str]
    destination_path: str
    git_commit: str
    status: str  # "success", "conflict", "error"
    notes: Optional[str]
```

### ValidationReport Model
```python
@dataclass
class ValidationReport:
    timestamp: datetime
    total_labs: int
    labs_with_readme: int
    labs_with_architecture: int
    broken_links: List[str]
    missing_documentation: List[str]
    pillar_distribution: Dict[str, int]
    quality_score: float  # 0-100
    recommendations: List[str]
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property Reflection

After analyzing all acceptance criteria, several properties were identified as redundant or overlapping:

- **3.3 and 6.1** both test file preservation during migration - consolidated into Property 3
- **1.5 and 7.1** both test completeness of lab assignment - consolidated into Property 1
- **4.3, 4.4, and 4.7** all test README content population - consolidated into Property 7
- **7.2 and 4.2** both test README generation with template - consolidated into Property 7

The following properties represent the unique, non-redundant correctness guarantees for this system:

### Property 1: Complete Lab Discovery and Assignment

*For any* repository with labs in service domain directories, the discovery process should identify all labs (directories containing README.md files), and after pillar assignment, every discovered lab should appear in exactly one pillar directory with a primary pillar assignment in the mapping.

**Validates: Requirements 1.1, 1.3, 1.5, 7.1**

### Property 2: Consistent Pillar Assignment

*For any* lab with the same AWS services and documentation content, running the pillar assignment multiple times should produce the same primary pillar assignment.

**Validates: Requirements 1.2**

### Property 3: File Preservation During Migration

*For any* lab before reorganization, after migration to a pillar directory, all original files (scripts, configs, documentation) should exist in the new location with the same content and git history preserved.

**Validates: Requirements 3.3, 6.1**

### Property 4: Multi-Pillar Handling

*For any* lab that scores above threshold on multiple pillars, the mapping should assign exactly one primary pillar (the highest scoring) and list all other above-threshold pillars as secondary pillars.

**Validates: Requirements 1.4**

### Property 5: Mapping Completeness

*For any* lab in the mapping, the mapping entry should contain non-empty values for: lab_name, primary_pillar, business_problem, aws_services list, and assignment_rationale.

**Validates: Requirements 1.6, 2.4**

### Property 6: Business Problem Quality

*For any* generated business problem statement, the statement should not contain learning-focused keywords (e.g., "learn", "understand", "practice", "demonstrate") and should contain at least one business-value keyword (e.g., "reduce", "improve", "ensure", "achieve", "optimize", "automate", "protect").

**Validates: Requirements 2.1, 2.2, 2.3**

### Property 7: README Generation and Population

*For any* lab converted to a mini-project, the generated README.md should: (1) exist in the project directory, (2) contain all required template sections (Business Problem, Solution Architecture, AWS Services Used, Implementation Details, Results/Outcomes, Key Learnings), (3) have the Business Problem section populated with the mapping's business_problem value, and (4) list all AWS services from the mapping.

**Validates: Requirements 4.2, 4.3, 4.4, 4.7, 7.2**

### Property 8: Architecture Diagram References

*For any* lab that has an architecture.md or architecture diagram file, the generated README should contain a reference or link to that diagram file.

**Validates: Requirements 4.5**

### Property 9: Lab Migration to Correct Pillar

*For any* lab with an assigned primary pillar in the mapping, after reorganization, the lab directory should exist within the corresponding pillar directory (e.g., if primary_pillar is "security", the lab should be in the security/ directory).

**Validates: Requirements 3.2**

### Property 10: Git History Preservation

*For any* file that existed before reorganization, after migration, running `git log --follow <new_path>` should show the complete commit history from before the migration.

**Validates: Requirements 3.4**

### Property 11: Internal Link Updates

*For any* documentation file containing relative path links to other labs or files, after reorganization, all internal links should resolve to existing files (no broken links).

**Validates: Requirements 3.5, 7.3**

### Property 12: Main README Pillar Counts

*For any* completed reorganization, the mini-project counts per pillar listed in the main README should match the actual number of lab directories in each pillar directory.

**Validates: Requirements 5.7, 7.4**

### Property 13: Content Preservation from Original README

*For any* lab with an existing README containing technical content (architecture descriptions, implementation details, configuration notes), the new generated README should incorporate that content in the appropriate template sections.

**Validates: Requirements 6.3**

### Property 14: Conflict Documentation

*For any* reorganization operation that encounters a conflict (e.g., duplicate lab names, file collisions), the system should create a conflict log entry and preserve both versions of the conflicting items.

**Validates: Requirements 6.6**

### Property 15: Validation Completeness

*For any* completed reorganization, the validation report should verify: (1) all labs have READMEs with required sections, (2) all internal links resolve, (3) pillar counts are accurate, and (4) list any issues found in each category.

**Validates: Requirements 7.2, 7.3, 7.4, 7.5**

## Error Handling

### Error Categories

1. **Discovery Errors**
   - Missing service domain directories
   - Inaccessible lab directories
   - Malformed README files
   - **Handling**: Log warning, skip directory, continue discovery

2. **Pillar Assignment Errors**
   - Unable to extract AWS services from documentation
   - No clear pillar match (all scores below threshold)
   - **Handling**: Assign to "operational-excellence" as default, flag for manual review, log rationale

3. **Migration Errors**
   - Git history preservation failure
   - File permission issues
   - Duplicate lab names across pillars
   - **Handling**: Document in conflict log, preserve original, halt migration for manual resolution

4. **Documentation Generation Errors**
   - Template file missing
   - Unable to parse existing README
   - Missing required metadata
   - **Handling**: Generate README with available data, mark sections as "[To be completed]", log warning

5. **Validation Errors**
   - Broken internal links
   - Missing required sections in README
   - Pillar count mismatch
   - **Handling**: Document in validation report, do not halt process, provide recommendations

### Error Recovery Strategy

**Transactional Migration**: The reorganization process should be implemented as a series of atomic operations with rollback capability:

```python
def reorganize_portfolio(repo_path: Path) -> Result:
    try:
        # Phase 1: Discovery (read-only, no rollback needed)
        labs = discover_labs(repo_path)
        
        # Phase 2: Analysis (read-only, no rollback needed)
        mappings = assign_pillars(labs)
        business_problems = identify_business_problems(labs, mappings)
        
        # Phase 3: Migration (requires rollback capability)
        with GitTransaction(repo_path) as transaction:
            create_pillar_directories(repo_path)
            migration_log = migrate_labs(labs, mappings, transaction)
            generate_documentation(labs, mappings, business_problems)
            update_main_readme(repo_path, mappings)
            
            # Validate before committing
            validation = validate_reorganization(repo_path, mappings)
            if validation.has_critical_errors():
                transaction.rollback()
                return Result.error(validation.critical_errors)
            
            transaction.commit()
        
        return Result.success(validation)
    
    except Exception as e:
        log_error(e)
        return Result.error(str(e))
```

### Logging Strategy

All operations should log to `.migration/reorganization.log` with structured entries:

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "INFO|WARN|ERROR",
  "component": "LabDiscovery|PillarAssignment|Migration|Validation",
  "operation": "discover_lab|assign_pillar|move_file|validate_link",
  "details": {
    "lab_name": "lambda-url-checker",
    "from_path": "compute/lambda-url-checker",
    "to_path": "operational-excellence/lambda-url-checker",
    "status": "success|warning|error",
    "message": "Detailed message"
  }
}
```

## Testing Strategy

### Dual Testing Approach

This project requires both unit tests and property-based tests to ensure comprehensive coverage:

- **Unit Tests**: Verify specific examples, edge cases, and integration points
- **Property Tests**: Verify universal properties across all inputs using randomized test data

### Unit Testing Focus

Unit tests should cover:

1. **Specific Examples**:
   - Test pillar assignment for known labs (e.g., "api-gateway-cognito-authorizer" → "security")
   - Test business problem generation for sample labs
   - Test README template rendering with sample data

2. **Edge Cases**:
   - Empty repository (no labs found)
   - Lab with no AWS services mentioned in documentation
   - Lab with malformed README
   - Duplicate lab names across domains
   - Labs with circular dependencies

3. **Integration Points**:
   - Git operations (mv, log, commit)
   - File system operations (create directories, read/write files)
   - Markdown parsing and link extraction

4. **Error Conditions**:
   - Permission denied during file operations
   - Git repository not initialized
   - Missing template files
   - Invalid pillar names in mapping

### Property-Based Testing Configuration

**Testing Library**: Use `hypothesis` (Python) for property-based testing

**Configuration**: Each property test should run minimum 100 iterations to ensure comprehensive input coverage

**Test Tagging**: Each property test must reference its design document property using the format:
```python
# Feature: well-architected-portfolio-reorganization, Property 1: Complete Lab Discovery and Assignment
@given(repository_with_labs())
@settings(max_examples=100)
def test_complete_lab_discovery_and_assignment(repo):
    # Test implementation
    pass
```

### Property Test Implementation Guide

**Property 1: Complete Lab Discovery and Assignment**
```python
# Feature: well-architected-portfolio-reorganization, Property 1: Complete Lab Discovery and Assignment
@given(repository_with_labs(min_labs=1, max_labs=50))
@settings(max_examples=100)
def test_complete_lab_discovery_and_assignment(repo):
    """For any repository with labs, all discovered labs should be assigned to pillars"""
    # Discover labs
    labs = discover_labs(repo.path)
    
    # Assign pillars
    mappings = assign_pillars(labs)
    
    # Migrate
    migrate_labs(labs, mappings)
    
    # Verify: every discovered lab appears in exactly one pillar directory
    assert len(labs) == len(mappings)
    for lab in labs:
        pillar_dirs = find_lab_in_pillars(repo.path, lab.name)
        assert len(pillar_dirs) == 1, f"Lab {lab.name} found in {len(pillar_dirs)} pillars"
```

**Property 2: Consistent Pillar Assignment**
```python
# Feature: well-architected-portfolio-reorganization, Property 2: Consistent Pillar Assignment
@given(lab_with_services())
@settings(max_examples=100)
def test_consistent_pillar_assignment(lab):
    """For any lab, pillar assignment should be deterministic"""
    pillar1 = assign_pillar(lab)
    pillar2 = assign_pillar(lab)
    pillar3 = assign_pillar(lab)
    
    assert pillar1 == pillar2 == pillar3
```

**Property 3: File Preservation During Migration**
```python
# Feature: well-architected-portfolio-reorganization, Property 3: File Preservation During Migration
@given(lab_with_files(min_files=1, max_files=20))
@settings(max_examples=100)
def test_file_preservation_during_migration(lab, temp_repo):
    """For any lab, all files should exist after migration with same content"""
    # Record original files and content
    original_files = get_all_files(lab.path)
    original_content = {f: read_file(f) for f in original_files}
    
    # Migrate
    mapping = LabMapping(lab.name, lab.path, f"security/{lab.name}", "security", [], "", [], "", 1.0)
    migrate_lab(lab, mapping, temp_repo)
    
    # Verify all files exist with same content
    new_path = temp_repo / "security" / lab.name
    new_files = get_all_files(new_path)
    
    assert len(original_files) == len(new_files)
    for original_file in original_files:
        relative_path = original_file.relative_to(lab.path)
        new_file = new_path / relative_path
        assert new_file.exists()
        assert read_file(new_file) == original_content[original_file]
```

**Property 6: Business Problem Quality**
```python
# Feature: well-architected-portfolio-reorganization, Property 6: Business Problem Quality
@given(lab_with_documentation())
@settings(max_examples=100)
def test_business_problem_quality(lab):
    """For any lab, business problem should focus on business value, not learning"""
    business_problem = identify_business_problem(lab, "operational-excellence")
    
    # Should not contain learning keywords
    learning_keywords = ["learn", "understand", "practice", "demonstrate", "explore"]
    assert not any(keyword in business_problem.statement.lower() for keyword in learning_keywords)
    
    # Should contain business value keywords
    business_keywords = ["reduce", "improve", "ensure", "achieve", "optimize", "automate", "protect", "enable"]
    assert any(keyword in business_problem.statement.lower() for keyword in business_keywords)
```

**Property 11: Internal Link Updates**
```python
# Feature: well-architected-portfolio-reorganization, Property 11: Internal Link Updates
@given(repository_with_cross_references())
@settings(max_examples=100)
def test_internal_link_updates(repo):
    """For any repository with internal links, all links should resolve after reorganization"""
    # Reorganize
    reorganize_portfolio(repo.path)
    
    # Extract all internal links from all markdown files
    all_links = extract_internal_links(repo.path)
    
    # Verify all links resolve
    for link in all_links:
        source_file = link.source_file
        target_path = resolve_relative_path(source_file, link.target)
        assert target_path.exists(), f"Broken link in {source_file}: {link.target}"
```

### Test Data Generators

Property-based tests require generators for creating random test data:

```python
from hypothesis import strategies as st

@st.composite
def repository_with_labs(draw, min_labs=1, max_labs=10):
    """Generate a repository with random labs"""
    num_labs = draw(st.integers(min_value=min_labs, max_value=max_labs))
    domains = ["compute", "storage", "databases", "security", "networking"]
    
    repo = TempRepository()
    for i in range(num_labs):
        domain = draw(st.sampled_from(domains))
        lab_name = f"lab-{i}-{draw(st.text(alphabet=st.characters(whitelist_categories=('Ll',)), min_size=5, max_size=15))}"
        create_lab(repo, domain, lab_name)
    
    return repo

@st.composite
def lab_with_services(draw):
    """Generate a lab with random AWS services"""
    services = draw(st.lists(
        st.sampled_from(["Lambda", "S3", "DynamoDB", "IAM", "CloudFormation", "EC2", "RDS"]),
        min_size=1,
        max_size=5,
        unique=True
    ))
    
    readme_content = f"# Lab\n\nThis lab uses {', '.join(services)}."
    return Lab(name="test-lab", readme_content=readme_content, aws_services=services)

@st.composite
def lab_with_files(draw, min_files=1, max_files=10):
    """Generate a lab with random files"""
    num_files = draw(st.integers(min_value=min_files, max_value=max_files))
    lab = create_temp_lab()
    
    for i in range(num_files):
        file_type = draw(st.sampled_from(["script", "config", "doc"]))
        if file_type == "script":
            create_file(lab.path / "scripts" / f"script{i}.sh", "#!/bin/bash\necho 'test'")
        elif file_type == "config":
            create_file(lab.path / "configs" / f"config{i}.json", "{}")
        else:
            create_file(lab.path / f"doc{i}.md", "# Documentation")
    
    return lab
```

### Test Coverage Goals

- **Unit Test Coverage**: Minimum 80% code coverage
- **Property Test Coverage**: All 15 correctness properties implemented as property tests
- **Integration Test Coverage**: End-to-end reorganization test with sample portfolio
- **Edge Case Coverage**: All identified edge cases have dedicated unit tests

### Continuous Integration

Tests should run automatically on:
- Every commit (unit tests + fast property tests with 10 examples)
- Pull requests (full test suite with 100 examples per property)
- Pre-release (full test suite + manual validation of sample portfolio)

