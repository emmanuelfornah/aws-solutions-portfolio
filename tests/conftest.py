"""Pytest configuration and fixtures."""

import pytest
from hypothesis import settings

# Configure hypothesis for property-based testing
settings.register_profile("default", max_examples=100)
settings.load_profile("default")
