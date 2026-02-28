#!/bin/bash

# Test Lambda Function
# This script invokes the Lambda function and displays results

set -e

# Read function name
if [ ! -f lambda-function-name.txt ]; then
  echo "Error: lambda-function-name.txt not found. Run deploy-lambda.sh first."
  exit 1
fi

FUNCTION_NAME=$(cat lambda-function-name.txt)

echo "Testing Lambda function: $FUNCTION_NAME"
echo ""

# Test 1: Cold start invocation
echo "Test 1: Cold start invocation (cache miss)"
echo "Invoking function..."

aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  response1.json

echo "Response:"
cat response1.json | jq '.'
echo ""

# Get execution logs
echo "Execution logs:"
aws logs tail /aws/lambda/"$FUNCTION_NAME" --since 1m --format short
echo ""

# Test 2: Warm invocation (cache hit)
echo "Test 2: Warm invocation (cache hit)"
echo "Invoking function again..."
sleep 2

aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  response2.json

echo "Response:"
cat response2.json | jq '.'
echo ""

# Test 3: Multiple rapid invocations
echo "Test 3: Multiple rapid invocations (testing cache)"
for i in {1..5}; do
  echo "Invocation $i..."
  aws lambda invoke \
    --function-name "$FUNCTION_NAME" \
    --payload '{}' \
    --cli-binary-format raw-in-base64-out \
    response_$i.json > /dev/null
done

echo "✓ All invocations completed"
echo ""

# Clean up response files
rm -f response*.json

echo "Performance Comparison:"
echo "  - Cold start: ~1000-1500ms (includes secret retrieval)"
echo "  - Warm start: ~50-100ms (uses cached secret)"
echo "  - Cache hit rate: Check CloudWatch Logs"
echo ""
echo "View detailed logs:"
echo "  aws logs tail /aws/lambda/$FUNCTION_NAME --follow"
