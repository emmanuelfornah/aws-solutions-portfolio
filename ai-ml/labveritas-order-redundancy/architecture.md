# Architecture: LabVeritas Order Redundancy Detection

## High-level architecture

```text
                    New lab order event
            (panel code, analyte list, patient ref, timestamp)
                              |
                              v
                    Order Intake Lambda
                      - records incoming order
                      - reads recent history
                              |
                              v
                DynamoDB: OrderHistory / ResultHistory
                              |
                              v
        Tier 1 - Deterministic Overlap Check
          - loads panel composition reference
          - computes analyte intersections
                |                       |
          no overlap              overlap found
                |                       |
                v                       v
        Route: proceed          Potential upgrade pattern?
                                      |             |
                                     no            yes
                                      |             |
                                      v             v
                           Route: flag_for_review   Tier 2 - Bedrock reasoning
                                                     - de-identified prompt
                                                     - guardrail-protected inference
                                                     - rationale generation
                                                              |
                                                              v
                                               Route: suggest_alternative
                                                              |
                                                              v
                                             SNS supervisor review notification
```

## Design goals

This architecture is designed to:
- detect analyte-level redundancy earlier in the workflow
- minimize unnecessary AI calls
- keep the majority of logic deterministic and testable
- apply responsible AI controls where inference is used
- support future growth into broader lab workflow automation

## Workflow steps

1. A new lab order event enters the workflow.
2. The order intake function normalizes the order and looks up recent order/result history.
3. Tier 1 compares the analyte set of the new order with recent order analyte sets.
4. If no meaningful overlap exists, the order proceeds.
5. If overlap exists but does not resemble an upgrade pattern, the case is flagged for supervisor review.
6. If overlap suggests a panel-upgrade scenario, Tier 2 invokes Amazon Bedrock using a de-identified prompt.
7. Bedrock returns a structured recommendation and rationale.
8. Guardrails and validation checks are applied before routing.
9. The workflow produces one of three outcomes:
   - `proceed`
   - `flag_for_review`
   - `suggest_alternative`

## Why a two-tier approach

A deterministic overlap check is sufficient for many redundant-order cases and is preferable because it is:
- auditable
- inexpensive
- fast
- easy to unit test

AI is reserved for cases where reasoning adds value, especially when the system must infer a more efficient completing panel and provide a short explanation for supervisory review.

## Data model inputs

### Order event inputs
- order code or panel name
- analyte set
- encounter timestamp
- de-identified patient reference

### Reference data
- panel composition map (BMP, CMP, LFT, etc.)
- optional routing thresholds
- guardrail configuration

### Output decision schema

```json
{
  "decision": "suggest_alternative",
  "overlapping_analytes": ["glucose", "potassium"],
  "suggested_panel": "LFT",
  "rationale": "Recent BMP results already cover glucose and potassium; LFT completes the needed liver analytes without rerunning the full CMP.",
  "confidence": 0.89
}
```

## Responsible AI and safety controls

The design reuses and adapts guardrail concepts from the existing Bedrock Guardrails project.

### Pre-inference controls
- prompt de-identification
- denied-topic restrictions
- prompt injection defense
- word and content filtering

### Post-inference controls
- output grounding checks
- structured response validation
- optional PII masking defense in depth
- fallback to manual review on invalid or low-confidence responses

## Security considerations

- No intentional PHI is sent to the model
- Reference data is separated from patient context
- Logs should avoid storing sensitive free text
- IAM permissions should follow least privilege for Lambda, DynamoDB, Bedrock, and SNS

## Future expansion

This module could later be extended into a broader lab workflow platform with:
- specimen exception handling
- critical value escalation support
- result auto-verification support
- utilization review dashboards
- approval workflows with Step Functions
