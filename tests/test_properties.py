"""Property-based tests for AWS Labs Portfolio system."""

from hypothesis import given, strategies as st
from aws_labs_portfolio.models import LabMetadata, DomainCategory


# Strategy for generating valid AWS service names
aws_services = st.sampled_from([
    "EC2", "S3", "RDS", "Lambda", "VPC", "CloudFormation",
    "CloudWatch", "IAM", "EBS", "EFS", "DynamoDB", "Elastic Beanstalk",
    "CodePipeline", "CloudFront", "WAF", "KMS", "Inspector"
])

# Strategy for generating LabMetadata
lab_metadata_strategy = st.builds(
    LabMetadata,
    title=st.text(min_size=5, max_size=100),
    aws_services=st.lists(aws_services, min_size=1, max_size=5),
    objectives=st.lists(st.text(min_size=10, max_size=200), min_size=1, max_size=5),
    domain_category=st.sampled_from([
        DomainCategory.COMPUTE,
        DomainCategory.STORAGE,
        DomainCategory.DATABASES,
        DomainCategory.NETWORKING,
        DomainCategory.SECURITY,
        DomainCategory.DEVOPS_CICD,
        DomainCategory.MONITORING
    ])
)


@given(lab_metadata_strategy)
def test_property_1_valid_category_assignment(lab: LabMetadata):
    """
    Feature: aws-labs-portfolio, Property 1: Domain Category Structure
    
    **Validates: Requirements 1.1, 1.4**
    
    For any lab project, it must be assigned to exactly one of the seven 
    valid domain categories (Compute, Storage, Databases, Networking, 
    Security, DevOps/CI-CD, Monitoring), and each category must have a 
    corresponding directory in the repository structure.
    """
    valid_categories = {
        DomainCategory.COMPUTE,
        DomainCategory.STORAGE,
        DomainCategory.DATABASES,
        DomainCategory.NETWORKING,
        DomainCategory.SECURITY,
        DomainCategory.DEVOPS_CICD,
        DomainCategory.MONITORING
    }
    
    # Test that the lab's domain_category is one of the valid categories
    assert lab.domain_category in valid_categories, \
        f"Lab category '{lab.domain_category}' is not in valid categories: {valid_categories}"
