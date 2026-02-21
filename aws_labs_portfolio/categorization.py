"""Domain categorization module for organizing labs."""

from .models import LabMetadata


class DomainCategorizer:
    """Categorizes labs into domain categories based on AWS services."""
    
    def categorize_lab(self, metadata: LabMetadata) -> str:
        """Determine the domain category for a lab."""
        # Implementation will be added in task 5.1
        pass
    
    def get_primary_service(self, services: list[str]) -> str:
        """Identify the primary AWS service from a list."""
        # Implementation will be added in task 5.1
        pass
