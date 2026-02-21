"""Content extraction module for processing lab materials."""

from typing import List
from .models import CodeBlock, LabMetadata, ArchitectureDescription


class ContentExtractor:
    """Extracts structured content from pasted lab materials."""
    
    def extract_code_blocks(self, raw_content: str) -> List[CodeBlock]:
        """Extract code blocks from markdown content."""
        # Implementation will be added in task 2.1
        pass
    
    def extract_metadata(self, raw_content: str) -> LabMetadata:
        """Extract lab metadata from content."""
        # Implementation will be added in task 2.2
        pass
    
    def extract_architecture_info(self, raw_content: str) -> ArchitectureDescription:
        """Extract architecture information from content."""
        # Implementation will be added in task 2.3
        pass
    
    def identify_aws_services(self, raw_content: str) -> List[str]:
        """Identify AWS services mentioned in content."""
        # Implementation will be added in task 2.2
        pass
