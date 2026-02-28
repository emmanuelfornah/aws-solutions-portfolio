#!/bin/bash

# Add AWS Managed Rules to Web ACL
# This script adds managed rule groups for OWASP protection

set -e

# Read Web ACL ID
if [ ! -f web-acl-id.txt ]; then
  echo "Error: web-acl-id.txt not found. Run create-web-acl.sh first."
  exit 1
fi

WEB_ACL_ID=$(cat web-acl-id.txt)

echo "Adding AWS Managed Rules to Web ACL: $WEB_ACL_ID"

# Get current lock token
LOCK_TOKEN=$(aws wafv2 get-web-acl \
  --scope REGIONAL \
  --id "$WEB_ACL_ID" \
  --name WebAppProtectionACL \
  --region us-east-1 \
  --query 'LockToken' \
  --output text)

# Update Web ACL with managed rules
aws wafv2 update-web-acl \
  --scope REGIONAL \
  --id "$WEB_ACL_ID" \
  --name WebAppProtectionACL \
  --default-action Allow={} \
  --lock-token "$LOCK_TOKEN" \
  --rules '[
    {
      "Name": "AWSManagedRulesCommonRuleSet",
      "Priority": 10,
      "Statement": {
        "ManagedRuleGroupStatement": {
          "VendorName": "AWS",
          "Name": "AWSManagedRulesCommonRuleSet"
        }
      },
      "OverrideAction": {
        "None": {}
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "AWSManagedRulesCommonRuleSet"
      }
    },
    {
      "Name": "AWSManagedRulesKnownBadInputsRuleSet",
      "Priority": 20,
      "Statement": {
        "ManagedRuleGroupStatement": {
          "VendorName": "AWS",
          "Name": "AWSManagedRulesKnownBadInputsRuleSet"
        }
      },
      "OverrideAction": {
        "None": {}
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "AWSManagedRulesKnownBadInputsRuleSet"
      }
    },
    {
      "Name": "AWSManagedRulesAmazonIpReputationList",
      "Priority": 30,
      "Statement": {
        "ManagedRuleGroupStatement": {
          "VendorName": "AWS",
          "Name": "AWSManagedRulesAmazonIpReputationList"
        }
      },
      "OverrideAction": {
        "None": {}
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "AWSManagedRulesAmazonIpReputationList"
      }
    }
  ]' \
  --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=WebAppProtectionACL \
  --region us-east-1

echo "✓ AWS Managed Rules added successfully"
echo ""
echo "Managed Rule Groups Added:"
echo "  1. Core Rule Set (OWASP Top 10 protection)"
echo "  2. Known Bad Inputs (Exploit patterns)"
echo "  3. IP Reputation List (Known malicious IPs)"
