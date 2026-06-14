# Unit 6 Report Outline: LabVeritas Order Redundancy Detection Module

## Working title
LabVeritas: AI-Assisted Laboratory Order Redundancy Detection with Amazon Bedrock Guardrails

## 1. Introduction
- Briefly introduce the problem of redundant lab ordering
- Explain why analyte-level redundancy is harder to detect than identical order duplication
- State that the project builds on prior AWS and responsible AI work

## 2. Background and Motivation
- Connect the problem to clinical laboratory workflow efficiency
- Discuss cost, turnaround time, and utilization concerns
- Explain personal relevance from a medical lab chemistry scientist perspective

## 3. Business Problem
- Describe same-encounter component overlap
- Describe inefficient panel upgrade scenarios
- Explain the operational impact of missed redundancy

## 4. Proposed AI Enhancement
- Define the module as a focused AI enhancement within a broader cloud portfolio
- Explain the two-tier model:
  - deterministic overlap detection
  - AI-assisted upgrade reasoning
- Justify why AI is used selectively rather than universally

## 5. AWS Architecture
- AWS Lambda for intake and classification
- DynamoDB for recent order history
- Amazon Bedrock for upgrade reasoning
- Bedrock Guardrails for safe and grounded inference
- SNS for routing flagged cases
- CloudWatch for observability

## 6. Responsible AI Considerations
- De-identification before prompt construction
- Prompt injection protection
- Denied topics and output constraints
- Human review for low-confidence cases
- Synthetic data only

## 7. Evaluation Methodology
- Use synthetic order scenarios
- Compare results against expected classifications
- Evaluate overlap detection accuracy
- Evaluate suggestion quality for upgrade cases
- Measure routing decision quality

## 8. Benefits and Limitations
### Benefits
- Reduced redundant testing
- Lower cost and improved workflow efficiency
- Better use of AI in targeted scenarios
- Stronger auditability than ad hoc reasoning

### Limitations
- Prototype only
- No live EHR integration
- Depends on curated panel composition reference data
- AI reasoning may still require supervisory review

## 9. Future Enhancements
- Step Functions orchestration
- dashboards and analytics
- broader LabVeritas platform modules
- supervisor feedback loop
- additional panel families and specialties

## 10. Conclusion
- Summarize the value of combining domain expertise, serverless architecture, and responsible AI
- Reinforce that the project is a realistic portfolio piece and academic prototype
