# Requirements Document

## Introduction

This document specifies requirements for reorganizing an AWS Cloud Institute portfolio from a service-domain structure (compute, storage, databases, etc.) into an AWS Well-Architected Framework structure organized by the six pillars: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, and Sustainability. The reorganization transforms individual labs into business-problem-focused mini-projects that demonstrate professional cloud architecture skills for Cloud Operations, SRE, DevOps, Developer, and Architect roles.

## Glossary

- **Portfolio_System**: The complete AWS Cloud Institute portfolio repository containing 150+ labs
- **Lab**: An individual AWS Cloud Institute hands-on exercise demonstrating specific AWS services or patterns
- **Mini_Project**: A lab repositioned with business problem context, solution architecture, and outcomes
- **Well_Architected_Pillar**: One of the six AWS Well-Architected Framework pillars (Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, Sustainability)
- **Service_Domain**: The current organizational structure (compute, storage, databases, networking, security, devops-cicd, monitoring, ai-ml-applications, modern-applications)
- **Business_Problem**: The real-world challenge or need that a lab/mini-project addresses
- **Lab_Mapping**: The association between a lab and its primary Well-Architected pillar
- **Project_README**: A standardized documentation file for each mini-project showing business problem, solution, and outcomes
- **Main_README**: The root README.md file that serves as the portfolio entry point
- **Hiring_Manager**: The target audience for the portfolio (recruiters and technical hiring managers for Cloud Ops, SRE, DevOps, Developer, and Architect roles)

## Requirements

### Requirement 1: Analyze and Map Existing Labs

**User Story:** As a portfolio owner, I want all existing labs analyzed and mapped to Well-Architected Framework pillars, so that I can understand how my work aligns with industry-standard architecture principles.

#### Acceptance Criteria

1. THE Portfolio_System SHALL identify all labs across all nine Service_Domains (compute, storage, databases, networking, security, devops-cicd, monitoring, ai-ml-applications, modern-applications)
2. WHEN a lab is analyzed, THE Portfolio_System SHALL determine its primary Well_Architected_Pillar based on the lab's core focus and AWS services used
3. THE Portfolio_System SHALL create a Lab_Mapping document that associates each lab with exactly one primary Well_Architected_Pillar
4. WHERE a lab demonstrates multiple pillars, THE Portfolio_System SHALL assign it to the most prominent pillar and note secondary pillars in the mapping
5. THE Lab_Mapping SHALL include all documented labs and accommodate future undocumented labs
6. FOR ALL labs in the mapping, the pillar assignment SHALL be justified with a brief rationale

### Requirement 2: Identify Business Problems

**User Story:** As a portfolio owner, I want each lab repositioned as a solution to a business problem, so that hiring managers understand the practical value of my work beyond technical skills.

#### Acceptance Criteria

1. WHEN a lab is analyzed, THE Portfolio_System SHALL identify the Business_Problem that the lab solves
2. THE Business_Problem SHALL focus on business value rather than learning objectives (e.g., "automated deployment to reduce manual errors" not "learned Lambda")
3. THE Business_Problem SHALL be relevant to enterprise cloud operations, development, or architecture scenarios
4. THE Portfolio_System SHALL document the Business_Problem for each lab in the Lab_Mapping
5. WHERE multiple business problems apply, THE Portfolio_System SHALL select the most impactful problem for the target roles (Cloud Ops, SRE, DevOps, Developer, Architect)

### Requirement 3: Create Well-Architected Directory Structure

**User Story:** As a portfolio owner, I want my repository reorganized into Well-Architected Framework pillars, so that hiring managers can quickly navigate my work by architecture principles.

#### Acceptance Criteria

1. THE Portfolio_System SHALL create six top-level directories named: operational-excellence, security, reliability, performance-efficiency, cost-optimization, and sustainability
2. WHEN labs are reorganized, THE Portfolio_System SHALL move each lab to its assigned Well_Architected_Pillar directory
3. THE Portfolio_System SHALL preserve all existing lab files, configurations, scripts, and documentation during reorganization
4. THE Portfolio_System SHALL maintain git history for all moved files
5. WHERE a lab has dependencies on other labs, THE Portfolio_System SHALL preserve those relationships through documentation or relative path updates
6. THE Portfolio_System SHALL remove or archive the old Service_Domain directories after successful reorganization

### Requirement 4: Generate Standardized Project Documentation

**User Story:** As a portfolio owner, I want each mini-project to have consistent, professional documentation, so that hiring managers can quickly understand the business value and technical implementation of each project.

#### Acceptance Criteria

1. THE Portfolio_System SHALL create a Project_README template with sections for: Business Problem, Solution Architecture, AWS Services Used, Implementation Details, Results/Outcomes, and Key Learnings
2. WHEN a lab is converted to a Mini_Project, THE Portfolio_System SHALL generate a Project_README using the template
3. THE Project_README SHALL populate the Business Problem section with the identified business problem from Requirement 2
4. THE Project_README SHALL list all AWS services used in the mini-project
5. THE Project_README SHALL include or reference architecture diagrams where they exist
6. THE Project_README SHALL articulate measurable outcomes or results where applicable (e.g., "reduced deployment time by 80%", "achieved 99.9% uptime")
7. FOR ALL Mini_Projects, the Project_README SHALL be named README.md and placed in the project's directory

### Requirement 5: Update Portfolio Entry Point

**User Story:** As a portfolio owner, I want my main README to showcase the Well-Architected Framework organization, so that hiring managers immediately see my understanding of AWS architecture principles.

#### Acceptance Criteria

1. THE Portfolio_System SHALL update the Main_README to reflect the new Well-Architected Framework structure
2. THE Main_README SHALL include a section explaining the six Well-Architected pillars with brief descriptions
3. THE Main_README SHALL provide navigation links to each Well_Architected_Pillar directory
4. THE Main_README SHALL highlight how the portfolio demonstrates skills for Cloud Ops, SRE, DevOps, Developer, and Architect roles
5. THE Main_README SHALL maintain existing sections about education, certifications, and contact information
6. THE Main_README SHALL be scannable and understandable by a Hiring_Manager within 5-10 minutes
7. THE Main_README SHALL include a summary count of mini-projects per pillar

### Requirement 6: Preserve Existing Work and Flexibility

**User Story:** As a portfolio owner, I want all my existing work preserved and the structure to accommodate future labs, so that I don't lose any documentation and can continue adding projects.

#### Acceptance Criteria

1. THE Portfolio_System SHALL preserve all existing lab files, scripts, configurations, and documentation during reorganization
2. THE Portfolio_System SHALL create a migration log documenting all file moves and structural changes
3. WHERE existing README files contain valuable content, THE Portfolio_System SHALL merge that content into the new Project_README format
4. THE Portfolio_System SHALL design the directory structure to accommodate additional labs beyond those currently documented
5. THE Portfolio_System SHALL provide guidelines for adding new mini-projects to the appropriate Well_Architected_Pillar directory
6. IF conflicts arise during reorganization, THEN THE Portfolio_System SHALL document the conflict and preserve both versions for manual resolution

### Requirement 7: Validate Portfolio Quality

**User Story:** As a portfolio owner, I want to validate that the reorganized portfolio meets professional standards, so that I can confidently share it with hiring managers.

#### Acceptance Criteria

1. WHEN the reorganization is complete, THE Portfolio_System SHALL verify that all labs have been assigned to a Well_Architected_Pillar
2. THE Portfolio_System SHALL verify that all Mini_Projects have a Project_README following the standardized template
3. THE Portfolio_System SHALL verify that all internal links in documentation are valid and point to correct locations
4. THE Portfolio_System SHALL verify that the Main_README accurately reflects the new structure
5. THE Portfolio_System SHALL generate a validation report listing any missing documentation, broken links, or incomplete mini-projects
6. THE Portfolio_System SHALL verify that the portfolio structure is navigable and understandable within 5-10 minutes through a test review
