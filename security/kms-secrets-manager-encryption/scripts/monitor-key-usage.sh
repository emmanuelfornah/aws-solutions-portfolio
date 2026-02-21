#!/bin/bash

# Monitor KMS Key Usage
# This script queries CloudTrail for KMS key usage events

set -e

# Read KMS key ID
if [ ! -f kms-key-id.txt ]; then
  echo "Error: kms-key-id.txt not found. Run create-kms-key.sh first."
  exit 1
fi

KMS_KEY_ID=$(cat kms-key-id.txt)

echo "Monitoring KMS key usage: $KMS_KEY_ID"
echo ""

# Query CloudTrail for KMS events (last 24 hours)
echo "Recent KMS API calls (last 24 hours):"
echo ""

aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue="$KMS_KEY_ID" \
  --max-results 50 \
  --query 'Events[*].[EventTime,EventName,Username]' \
  --output table

echo ""
echo "Key Usage Statistics:"
echo ""

# Get CloudWatch metrics for the key
aws cloudwatch get-metric-statistics \
  --namespace AWS/KMS \
  --metric-name NumberOfDecryptCalls \
  --dimensions Name=KeyId,Value="$KMS_KEY_ID" \
  --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum \
  --query 'Datapoints[*].[Timestamp,Sum]' \
  --output table

echo ""
echo "To view detailed logs:"
echo "  aws logs tail /aws/cloudtrail/logs --follow --filter-pattern \"$KMS_KEY_ID\""
echo ""
echo "To create CloudWatch alarm for unusual activity:"
echo "  aws cloudwatch put-metric-alarm \\"
echo "    --alarm-name high-kms-decrypt-rate \\"
echo "    --alarm-description 'Alert on high KMS decrypt rate' \\"
echo "    --metric-name NumberOfDecryptCalls \\"
echo "    --namespace AWS/KMS \\"
echo "    --statistic Sum \\"
echo "    --period 300 \\"
echo "    --threshold 1000 \\"
echo "    --comparison-operator GreaterThanThreshold"
