#!/bin/bash

# Test WAF Rules
# This script simulates various attacks to verify WAF protection

set -e

# Read ALB endpoint
if [ ! -f alb-endpoint.txt ]; then
  echo "Error: alb-endpoint.txt not found."
  echo "Please create this file with your ALB DNS name."
  exit 1
fi

ALB_ENDPOINT=$(cat alb-endpoint.txt)

echo "Testing WAF rules against: $ALB_ENDPOINT"
echo ""

# Test 1: Normal request (should succeed)
echo "Test 1: Normal request (should succeed)"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "http://$ALB_ENDPOINT/")
HTTP_STATUS=$(echo "$RESPONSE" | grep HTTP_STATUS | cut -d: -f2)
echo "Status: $HTTP_STATUS"
if [ "$HTTP_STATUS" = "200" ]; then
  echo "✓ Normal request allowed"
else
  echo "✗ Unexpected status: $HTTP_STATUS"
fi
echo ""

# Test 2: SQL Injection attempt (should be blocked)
echo "Test 2: SQL Injection attempt (should be blocked)"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "http://$ALB_ENDPOINT/?id=1' OR '1'='1")
HTTP_STATUS=$(echo "$RESPONSE" | grep HTTP_STATUS | cut -d: -f2)
echo "Status: $HTTP_STATUS"
if [ "$HTTP_STATUS" = "403" ]; then
  echo "✓ SQL injection blocked"
else
  echo "✗ Expected 403, got: $HTTP_STATUS"
fi
echo ""

# Test 3: XSS attempt (should be blocked)
echo "Test 3: XSS attempt (should be blocked)"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "http://$ALB_ENDPOINT/?search=<script>alert('xss')</script>")
HTTP_STATUS=$(echo "$RESPONSE" | grep HTTP_STATUS | cut -d: -f2)
echo "Status: $HTTP_STATUS"
if [ "$HTTP_STATUS" = "403" ]; then
  echo "✓ XSS attempt blocked"
else
  echo "✗ Expected 403, got: $HTTP_STATUS"
fi
echo ""

# Test 4: Path traversal attempt (should be blocked)
echo "Test 4: Path traversal attempt (should be blocked)"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "http://$ALB_ENDPOINT/../../etc/passwd")
HTTP_STATUS=$(echo "$RESPONSE" | grep HTTP_STATUS | cut -d: -f2)
echo "Status: $HTTP_STATUS"
if [ "$HTTP_STATUS" = "403" ]; then
  echo "✓ Path traversal blocked"
else
  echo "✗ Expected 403, got: $HTTP_STATUS"
fi
echo ""

# Test 5: Rate limiting (should block after threshold)
echo "Test 5: Rate limiting test (sending 100 rapid requests)"
BLOCKED_COUNT=0
for i in {1..100}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$ALB_ENDPOINT/")
  if [ "$STATUS" = "403" ] || [ "$STATUS" = "429" ]; then
    ((BLOCKED_COUNT++))
  fi
done
echo "Blocked requests: $BLOCKED_COUNT/100"
if [ $BLOCKED_COUNT -gt 0 ]; then
  echo "✓ Rate limiting working (some requests blocked)"
else
  echo "Note: Rate limit not triggered (threshold: 2000 req/5min)"
fi
echo ""

echo "WAF testing completed!"
echo ""
echo "Check CloudWatch Logs for detailed blocking information:"
echo "  aws logs tail /aws/wafv2/WebAppProtectionACL --follow"
