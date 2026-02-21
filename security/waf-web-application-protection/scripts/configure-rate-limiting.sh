#!/bin/bash

# Configure Rate-Based Rules for DDoS Protection
# This script adds rate limiting to prevent abuse

set -e

# Read Web ACL ID
if [ ! -f web-acl-id.txt ]; then
  echo "Error: web-acl-id.txt not found. Run create-web-acl.sh first."
  exit 1
fi

WEB_ACL_ID=$(cat web-acl-id.txt)

echo "Configuring rate-based rules for Web ACL: $WEB_ACL_ID"

# Get current configuration
CURRENT_RULES=$(aws wafv2 get-web-acl \
  --scope REGIONAL \
  --id "$WEB_ACL_ID" \
  --name WebAppProtectionACL \
  --region us-east-1 \
  --query 'WebACL.Rules' \
  --output json)

LOCK_TOKEN=$(aws wafv2 get-web-acl \
  --scope REGIONAL \
  --id "$WEB_ACL_ID" \
  --name WebAppProtectionACL \
  --region us-east-1 \
  --query 'LockToken' \
  --output text)

# Add rate-based rule (prepend to existing rules)
RATE_RULE='{
  "Name": "RateLimitRule",
  "Priority": 1,
  "Statement": {
    "RateBasedStatement": {
      "Limit": 2000,
      "AggregateKeyType": "IP"
    }
  },
  "Action": {
    "Block": {}
  },
  "VisibilityConfig": {
    "SampledRequestsEnabled": true,
    "CloudWatchMetricsEnabled": true,
    "MetricName": "RateLimitRule"
  }
}'

# Combine rate rule with existing rules
ALL_RULES=$(echo "$CURRENT_RULES" | jq ". = [$RATE_RULE] + .")

# Update Web ACL
aws wafv2 update-web-acl \
  --scope REGIONAL \
  --id "$WEB_ACL_ID" \
  --name WebAppProtectionACL \
  --default-action Allow={} \
  --lock-token "$LOCK_TOKEN" \
  --rules "$ALL_RULES" \
  --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=WebAppProtectionACL \
  --region us-east-1

echo "✓ Rate-based rule configured successfully"
echo ""
echo "Rate Limiting Configuration:"
echo "  - Limit: 2000 requests per 5 minutes"
echo "  - Tracking: Per IP address"
echo "  - Action: Block"
echo "  - Protection: DDoS, brute-force, API abuse"
