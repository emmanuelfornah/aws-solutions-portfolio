#!/bin/bash

# Invoke AI classifier Lambda with sample GuardDuty event

set -euo pipefail

REGION="${REGION:-us-east-1}"

cat > sample-guardduty-event.json <<EOF
{
  "version": "0",
  "id": "test-inc-001",
  "detail-type": "GuardDuty Finding",
  "source": "aws.guardduty",
  "detail": {
    "severity": 8,
    "type": "Backdoor:EC2/C&CActivity.B",
    "title": "Backdoor behavior detected",
    "description": "EC2 instance is communicating with known command-and-control infrastructure.",
    "service": {
      "serviceName": "guardduty"
    }
  }
}
EOF

aws lambda invoke \
  --function-name ClassifyIncidentWithBedrock \
  --payload file://sample-guardduty-event.json \
  --cli-binary-format raw-in-base64-out \
  --region "$REGION" \
  classifier-output.json >/dev/null

echo "Classifier output saved to classifier-output.json"
cat classifier-output.json
