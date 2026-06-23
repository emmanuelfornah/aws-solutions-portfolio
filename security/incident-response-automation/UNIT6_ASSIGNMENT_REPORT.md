# Unit 6 Assignment Report: Automated Incident Classification with AI

**Course:** CLCS 660 9040 AI-Based Cloud Automation and Scripting  
**Assignment:** Unit 6 Assignment - Choose-Your-Own AI Enhancement Project  
**Institution:** University of Maryland Global Campus  
**Instructor:** Dr Alan Castillo  
**Student:** Emmanuel Fornah  
**Submission Date:** 06/23/2026

## 1. Problem Statement and Business Case

### Scenario Selected
**Automated Incident Classification**.

### Business Problem
The baseline incident response workflow already detects high-risk events (GuardDuty, CloudTrail, Security Hub) and triggers automation. However, responders still spend time manually reading findings, deciding severity, selecting an owning team, and determining first actions. This creates inconsistent triage quality and increases mean time to triage (MTTT), especially during alert bursts.

### Objective
Add AI-driven decisioning to classify incidents and route them automatically so responders receive a structured triage package instead of raw alerts.

### Success Criteria
1. Classification quality: >=85% accuracy on a labeled validation set.
2. Operational speed: triage decision emitted in <=5 seconds P95 in Lambda runtime.
3. Response consistency: every high/critical incident includes team routing and recommended actions.
4. Traceability: classification output stored in structured JSON for audit and post-incident review.

## 2. Solution Architecture

### Cloud and AI Components
1. **Amazon EventBridge** receives relevant security events.
2. **AWS Step Functions** orchestrates the triage workflow.
3. **Lambda: `ClassifyIncidentWithBedrock`** calls Amazon Bedrock to classify incidents.
4. **Amazon Bedrock (Nova Lite)** performs natural language understanding and returns strict JSON output.
5. **Lambda: `RouteIncidentActions`** maps category/severity to team ownership and downstream actions.
6. **EventBridge IncidentRouted events** can trigger notifications, ticket creation, or additional runbooks.

### Architecture Diagram (textual)
````javascript
GuardDuty/CloudTrail/SecurityHub
            |
            v
      EventBridge Rule
            |
            v
Step Functions: IncidentAITriageWorkflow
  -> Lambda: ClassifyIncidentWithBedrock
       -> Bedrock model inference
  -> Lambda: RouteIncidentActions
       -> emits IncidentRouted event
  -> Choice: High/Critical escalation path
```

## 3. AI Model and Implementation

### Model Choice
Amazon Bedrock model: `amazon.nova-lite-v1:0`.

### Why This Model
- Fast inference for real-time triage
- Strong structured output performance with low-temperature prompt constraints
- Native AWS integration through `bedrock-runtime:converse`

### Prompting and Guardrails
The classifier prompt enforces:
- fixed category taxonomy
- fixed severity values
- fixed routing teams
- confidence score (0.0-1.0)
- recommended actions
- short reasoning field

The Lambda implementation validates all required fields and allowed values before accepting model output. Invalid output fails explicitly to avoid silent misclassification.

### Key Code Components
- `application/incident_classifier.py`
    - Normalizes event detail into a concise incident summary
    - Calls Bedrock `converse`
    - Extracts JSON payload from model response
    - Validates schema and enumerations
    - Returns classification object with metadata (`incident_id`, timestamp, model_id)
- `application/route_incident.py`
    - Converts routed team + severity to concrete action list
    - Emits `IncidentRouted` event for downstream automation

## 4. Deployment Instructions

### Prerequisites
- AWS account with permissions for Lambda, Step Functions, EventBridge, IAM, and Bedrock invocation
- Existing baseline deployment from this project (`deploy-ir-infrastructure.sh`)
- Bedrock model access enabled for `amazon.nova-lite-v1:0`

### Deployment Steps
1. Deploy baseline incident response resources:
   ```bash
   ./scripts/deploy-ir-infrastructure.sh
   ```
2. Deploy AI classification components:
   ```bash
   ./scripts/deploy-ai-incident-classifier.sh
   ```
3. Configure event detection rules:
   ```bash
   ./scripts/configure-eventbridge-rules.sh
   ```
4. Run sample invocation test:
   ```bash
   ./scripts/test-ai-incident-classifier.sh
   ```

### Configuration Artifacts
- `configs/eventbridge-rule-ai-incident-triage.json`
- `configs/incident-routing-map.json`
- `configs/lambda-environment-variables.json`
- `state-machine/incident-ai-triage.json`

## 5. Evaluation Methodology and Results

### Method
A labeled validation dataset (`validation/fixtures/incidents.json`) was used with corresponding model predictions (`validation/fixtures/predictions.json`). The evaluation script computes:
- accuracy
- macro precision
- macro recall
- macro F1
- confusion matrix
- misclassified examples

Run:
```bash
python validation/evaluate_classifier.py
```

### Results
From the included sample predictions:
- Accuracy: **0.9167** (11/12 correct)
- Misclassifications: **1**
- Macro-F1: generated in `validation/validation-results.json`

These results exceed the target threshold (>=0.85 accuracy) for assignment acceptance while still exposing realistic error cases for improvement work.

## 6. Challenges and Mitigations

### Challenge 1: Model output variability
LLM responses can include extra prose or non-JSON formatting.
- **Mitigation**: strict JSON extraction and explicit schema validation in Lambda.

### Challenge 2: Ambiguous incidents
Some events overlap categories (e.g., credential abuse vs unauthorized access).
- **Mitigation**: controlled taxonomy, routing guidance in prompt, and confidence-aware fallback to `SOC_L1`.

### Challenge 3: Operational safety
Automated routing can create false urgency or wrong owner assignments.
- **Mitigation**: severity gate in Step Functions, explicit recommended actions, and auditable output contracts.

## 7. Future Improvements

1. Add feedback loop from analyst corrections to build supervised fine-tuning data.
2. Track online metrics (precision@team route, escalation correctness, MTTT trend by week).
3. Add confidence thresholds that trigger human-in-the-loop review when <0.7.
4. Extend event normalization with entity extraction (resource IDs, principal IDs, geolocation).
5. Introduce Bedrock Guardrails policies for prompt and response safety controls.

## 8. Submission Checklist Mapping

- **Comprehensive report**: this document (export to PDF for submission)
- **Architecture diagram**: included (textual diagram in sections 2 and `architecture.md`)
- **Code samples**: `application/incident_classifier.py`, `application/route_incident.py`
- **Deployment instructions**: section 4 + scripts folder
- **Evaluation methodology/results**: section 5 + tests artifacts
- **Implementation artifacts**: source, configs, scripts, tests all included in this project path

## References

1. AWS Security Incident Response Guide  
2. Amazon Bedrock User Guide  
3. NIST SP 800-61r2: Computer Security Incident Handling Guide
````