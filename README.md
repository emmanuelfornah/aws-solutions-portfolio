# Portfolio Reorganizer

AWS Well-Architected Portfolio Reorganization Tool

## Overview

This tool reorganizes an AWS Cloud Institute portfolio from a service-domain structure (compute, storage, databases, etc.) into an AWS Well-Architected Framework structure organized by the six pillars:

- Operational Excellence
- Security
- Reliability
- Performance Efficiency
- Cost Optimization
- Sustainability

## Installation

```bash
pip install -e .
```

For development:
```bash
pip install -e ".[dev]"
```

## Usage

```python
from portfolio_reorganizer import discover_labs

# Discover labs in your portfolio
labs = discover_labs(repo_root, service_domains)
```

## Development

Run tests:
```bash
pytest
```

Run tests with coverage:
```bash
pytest --cov=portfolio_reorganizer --cov-report=html
```

Format code:
```bash
black portfolio_reorganizer tests
```

## Project Structure

```
portfolio_reorganizer/
├── __init__.py
├── models.py              # Data models
├── discovery.py           # Lab discovery
├── pillar_assignment.py   # Pillar assignment logic
├── business_problem.py    # Business problem generation
├── migration.py           # Lab migration with git history
├── documentation.py       # README generation
└── validation.py          # Portfolio validation
```

## License

MIT License
