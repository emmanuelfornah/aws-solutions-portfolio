# Architecture: Automating Code Reviews with Amazon CodeGuru

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Developer Workflow                              │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         AWS CodeCommit Repository                        │
│                         (python-app-code)                                │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  • app.py (Flask application)                                     │  │
│  │  • aws_controller.py (DynamoDB client)                            │  │
│  │  • buildspec.yml (Build configuration)                            │  │
│  │  • appspec.yml (Deploy configuration)                             │  │
│  │  • templates/ (HTML files)                                        │  │
│  │  • scripts/ (Deployment hooks)                                    │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                    │                                   │
                    │                                   │
        ┌───────────▼──────────┐           ┌───────────▼──────────────┐
        │  Amaz