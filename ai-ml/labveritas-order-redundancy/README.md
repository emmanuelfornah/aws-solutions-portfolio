# LabVeritas: Order Redundancy Detection Module

Part of the [AWS Solutions Portfolio](../../README.md) — AI/ML domain.

## Overview

LabVeritas is a healthcare-focused cloud automation concept within this portfolio that explores how secure, responsible AI can support laboratory workflow decisions. This module focuses on **analyte-level lab order redundancy detection** using AWS serverless services and Amazon Bedrock.

The project builds on guardrail patterns established in [`bedrock-guardrails-security`](../bedrock-guardrails-security/), reusing the responsible AI foundation—input/output filtering, prompt injection defense, PII masking, and contextual grounding—while applying those controls to a practical laboratory operations use case.

In many electronic health record and order-entry systems, duplicate checks are strongest when the exact same order code is submitted twice. They are weaker when two different orders overlap at the **analyte composition** level. This module addresses that gap by comparing incoming orders against recent order and result history, identifying redundant analytes, and routing cases for review when overlap or inefficient upgrade patterns are detected.

## Why this project matters

This project reflects both my technical development in cloud computing and my domain background in laboratory science. As a medical lab chemistry scientist transitioning into cloud application development, I wanted to build a solution that is technically credible, operationally relevant, and aligned with responsible AI practices.

## Business problem

Clinical laboratories can receive order combinations that appear different at the order-code level but are redundant at the analyte level.

Two common patterns motivate this module:

### Pattern 1 — Same-encounter component overlap
A provider orders a Basic Metabolic Panel (BMP) and, during the same encounter, also orders one or more individual analytes already included in that panel. Because the panel and standalone analyte orders have different codes, conventional duplicate checking may not flag the overlap.

### Pattern 2 — Inefficient panel upgrade
A provider orders a BMP, then later decides that liver-related analytes are also needed. Instead of ordering only the completing panel, a full Comprehensive Metabolic Panel (CMP) may be ordered, causing redundant reruns of analytes already resulted. The workflow should be able to recognize that a smaller completing panel may satisfy the need more efficiently.

## Solution approach

This module uses a **two-tier design**:

### Tier 1 — Deterministic overlap detection
A Python-based rules layer compares the analyte set of a new order against recent order and result history using a static panel composition reference.

This tier handles:
- no-overlap cases (`proceed`)
- clear overlap cases (`flag_for_review`)

### Tier 2 — AI-assisted upgrade reasoning
If Tier 1 detects overlap and the pattern resembles a potential panel-upgrade scenario, the workflow calls Amazon Bedrock through the Converse API to reason over the structured, de-identified order context.

This tier handles:
- upgrade interpretation
- minimal completing panel suggestions
- short rationale generation
- `suggest_alternative` routing decisions

AI is therefore used only where it adds value, while the majority of cases remain deterministic and auditable.

## Success criteria

- Detect analyte-level overlap with high agreement against expert-reviewed synthetic test scenarios
- Correctly distinguish between `proceed`, `flag_for_review`, and `suggest_alternative`
- Suggest a lower-cost completing panel where appropriate
- Keep prompts de-identified and guardrail-protected
- Produce concise rationales grounded in actual analyte overlap

## Architecture summary

```text
New lab order event
        |
        v
Order Intake Lambda
        |
        v
DynamoDB recent order/result history
        |
        v
Tier 1 Deterministic Overlap Check
   |                 |
   | no overlap      | overlap found
   v                 v
proceed        possible upgrade pattern?
                     |          |
                    no         yes
                     |          |
                     v          v
            flag_for_review   Tier 2 Bedrock reasoning
                                   |
                                   v
                          suggest_alternative
                                   |
                                   v
                        SNS supervisor review routing
```

## AWS services used

- **AWS Lambda** — order intake, overlap detection, AI invocation
- **Amazon DynamoDB** — recent order and result history
- **Amazon Bedrock** — AI reasoning for upgrade scenarios
- **Amazon Bedrock Guardrails** — safety, grounding, and prompt protection
- **Amazon SNS** — supervisor review routing and notifications
- **Amazon CloudWatch** — logs and observability

## Repository structure

```text
labveritas-order-redundancy/
  README.md
  architecture.md
  configs/
    panel_composition.json
    guardrail_config.json
  lambda/
    order_intake_handler.py
    tier1_overlap_check.py
    tier2_bedrock_classifier.py
    prompt_template.py
  test/
    test_scenarios.json
    test_results.md
  report/
    unit6-report-outline.md
```

## Relationship to other portfolio work

This project is intentionally connected to other work in this repository:

- Reuses responsible AI patterns from [`bedrock-guardrails-security`](../bedrock-guardrails-security/)
- Extends serverless workflow design concepts developed in prior UMGC coursework
- Contributes to a broader healthcare/lab automation portfolio direction

## Scope and disclaimer

This is a **prototype educational project** designed for synthetic data only.

- No real patient data is used
- No production EHR integration is implemented
- No PHI is intentionally sent to the model
- The module supports workflow review and routing, not diagnosis or independent clinical decision-making
