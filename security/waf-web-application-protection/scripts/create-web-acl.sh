#!/bin/bash

# Create AWS WAF Web ACL
# This script creates a Web ACL for protecting web applications

set -e

echo "Creating AWS WAF Web ACL..."

# Create Web ACL
WEB_ACL_ARN=$(aws wafv2 create-web-acl \
  --name WebAppProtectionACL \
  --scope REGIONAL \
  --default-action Allow={} \
  --description "Web ACL for protecting web application" \
  --rules '[]' \
  --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=WebAppProtectionACL \
  --region us-east-1 \
  --query 'Summary.ARN' \
  --output text)

echo "Web ACL created: $WEB_ACL_ARN"

# Extract Web ACL ID
WEB_ACL_ID=$(echo "$WEB_ACL_ARN" | awk -F'/' '{print $NF}')
echo "$WEB_ACL_ID" > web-acl-id.txt
echo "$WEB_ACL_ARN" > web-acl-arn.txt

echo "✓ Web ACL created successfully"
echo ""
echo "Web ACL Configuration:"
echo "  - Name: WebAppProtectionACL"
echo "  - ID: $WEB_ACL_ID"
echo "  - ARN: $WEB_ACL_ARN"
echo "  - Default Action: Allow"
echo "  - Scope: REGIONAL"
