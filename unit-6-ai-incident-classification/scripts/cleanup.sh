#!/bin/bash

# Cleanup Incident Response Infrastructure
# Removes all created resources

set -e

REGION="us-east-1"

echo "Cleaning up incident response infrastructure..."

# Load configuration if exists
if [ -f ir-config.txt ]; then
  source ir-config.txt
fi

# Delete EventBridge rules
echo "Deleting EventBridge rules..."
for RULE in CompromisedInstanceDetection UnauthorizedAccessDetection RootAccountUsageDetection AIIncidentTriageRule; do
  # Remove targets
  aws events remove-targets \
    --rule "$RULE" \
    --ids 1 \
    --region "$REGION" 2>/dev/null || true
  
  # Delete rule
  aws events delete-rule \
    --name "$RULE" \
    --region "$REGION" 2>/dev/null || true
done

# Delete Lambda function
echo "Deleting Lambda function..."
aws lambda delete-function \
  --function-name IsolateCompromisedInstance \
  --region "$REGION" 2>/dev/null || true

aws lambda delete-function \
  --function-name ClassifyIncidentWithBedrock \
  --region "$REGION" 2>/dev/null || true

aws lambda delete-function \
  --function-name RouteIncidentActions \
  --region "$REGION" 2>/dev/null || true

# Delete IAM role
echo "Deleting IAM role..."
aws iam delete-role-policy \
  --role-name IncidentResponseLambdaRole \
  --policy-name IncidentResponsePolicy 2>/dev/null || true

aws iam detach-role-policy \
  --role-name IncidentResponseLambdaRole \
  --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" 2>/dev/null || true

aws iam delete-role \
  --role-name IncidentResponseLambdaRole 2>/dev/null || true

# Delete SNS topic
if [ -n "$SNS_TOPIC_ARN" ]; then
  echo "Deleting SNS topic..."
  aws sns delete-topic \
    --topic-arn "$SNS_TOPIC_ARN" \
    --region "$REGION" 2>/dev/null || true
fi

# Delete isolation security group
if [ -f isolation-sg-id.txt ]; then
  SG_ID=$(cat isolation-sg-id.txt)
  echo "Deleting isolation security group..."
  aws ec2 delete-security-group \
    --group-id "$SG_ID" \
    --region "$REGION" 2>/dev/null || true
fi

# Note: Not deleting S3 bucket as it may contain evidence
if [ -n "$EVIDENCE_BUCKET" ]; then
  echo ""
  echo "Note: Evidence bucket not deleted: s3://$EVIDENCE_BUCKET"
  echo "Delete manually if no longer needed:"
  echo "  aws s3 rb s3://$EVIDENCE_BUCKET --force"
fi

# Remove temporary files
echo "Removing temporary files..."
rm -f ir-config.txt isolation-sg-id.txt
rm -f lambda-trust-policy.json ir-lambda-policy.json
rm -f guardduty-pattern.json unauthorized-access-pattern.json root-usage-pattern.json
rm -f isolate-instance.zip
rm -f incident-classifier.zip route-incident.zip sample-guardduty-event.json classifier-output.json
rm -rf lambda-package
rm -rf lambda-package-classifier lambda-package-router

echo ""
echo "Cleanup completed successfully!"
