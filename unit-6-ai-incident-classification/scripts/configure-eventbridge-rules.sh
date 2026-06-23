#!/bin/bash

# Configure EventBridge Rules for Incident Detection
# Creates rules to trigger automated incident response

set -e

source ir-config.txt
REGION="${REGION:-us-east-1}"

echo "Configuring EventBridge rules for incident detection..."

# Rule 1: Compromised Instance (GuardDuty)
echo "Creating rule for compromised instance detection..."

cat > guardduty-pattern.json <<EOF
{
  "source": ["aws.guardduty"],
  "detail-type": ["GuardDuty Finding"],
  "detail": {
    "severity": [7, 8, 9],
    "type": [
      {"prefix": "CryptoCurrency:EC2"},
      {"prefix": "Backdoor:EC2"},
      {"prefix": "Trojan:EC2"}
    ]
  }
}
EOF

aws events put-rule \
  --name CompromisedInstanceDetection \
  --description "Detect compromised EC2 instances from GuardDuty" \
  --event-pattern file://guardduty-pattern.json \
  --state ENABLED \
  --region "$REGION"

# Add Lambda as target
aws events put-targets \
  --rule CompromisedInstanceDetection \
  --targets "Id=1,Arn=$LAMBDA_ARN" \
  --region "$REGION"

# Grant EventBridge permission to invoke Lambda
aws lambda add-permission \
  --function-name IsolateCompromisedInstance \
  --statement-id AllowEventBridgeInvoke1 \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn "arn:aws:events:$REGION:$(aws sts get-caller-identity --query Account --output text):rule/CompromisedInstanceDetection" \
  --region "$REGION" 2>/dev/null || echo "Permission already exists"

echo "Rule created: CompromisedInstanceDetection"

# Rule 2: Unauthorized Access Attempts
echo "Creating rule for unauthorized access detection..."

cat > unauthorized-access-pattern.json <<EOF
{
  "source": ["aws.cloudtrail"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "errorCode": ["AccessDenied", "UnauthorizedOperation"]
  }
}
EOF

aws events put-rule \
  --name UnauthorizedAccessDetection \
  --description "Detect unauthorized access attempts" \
  --event-pattern file://unauthorized-access-pattern.json \
  --state ENABLED \
  --region "$REGION"

# Add SNS as target for this rule
aws events put-targets \
  --rule UnauthorizedAccessDetection \
  --targets "Id=1,Arn=$SNS_TOPIC_ARN" \
  --region "$REGION"

echo "Rule created: UnauthorizedAccessDetection"

# Rule 3: Root Account Usage
echo "Creating rule for root account usage detection..."

cat > root-usage-pattern.json <<EOF
{
  "source": ["aws.cloudtrail"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "userIdentity": {
      "type": ["Root"]
    }
  }
}
EOF

aws events put-rule \
  --name RootAccountUsageDetection \
  --description "Detect root account usage" \
  --event-pattern file://root-usage-pattern.json \
  --state ENABLED \
  --region "$REGION"

aws events put-targets \
  --rule RootAccountUsageDetection \
  --targets "Id=1,Arn=$SNS_TOPIC_ARN" \
  --region "$REGION"

echo "Rule created: RootAccountUsageDetection"

echo ""
echo "EventBridge rules configured successfully!"
echo ""
echo "Rules created:"
echo "  1. CompromisedInstanceDetection → Lambda (automated isolation)"
echo "  2. UnauthorizedAccessDetection → SNS (notification)"
echo "  3. RootAccountUsageDetection → SNS (notification)"
