#!/bin/bash

# Deploy API Gateway with IAM Authorization
# Creates REST API with IAM authorization for Zero Trust architecture

set -e

API_NAME="ZeroTrustServiceAPI"
REGION="us-east-1"

echo "Creating API Gateway with IAM authorization..."

# Create REST API
API_ID=$(aws apigateway create-rest-api \
  --name "$API_NAME" \
  --description "Zero Trust API with IAM authorization" \
  --endpoint-configuration types=REGIONAL \
  --region "$REGION" \
  --query 'id' \
  --output text)

echo "API created: $API_ID"

# Get root resource
ROOT_ID=$(aws apigateway get-resources \
  --rest-api-id "$API_ID" \
  --region "$REGION" \
  --query 'items[0].id' \
  --output text)

# Create /users resource
USERS_ID=$(aws apigateway create-resource \
  --rest-api-id "$API_ID" \
  --parent-id "$ROOT_ID" \
  --path-part "users" \
  --region "$REGION" \
  --query 'id' \
  --output text)

# Create GET method with IAM authorization
aws apigateway put-method \
  --rest-api-id "$API_ID" \
  --resource-id "$USERS_ID" \
  --http-method GET \
  --authorization-type AWS_IAM \
  --region "$REGION"

# Create mock integration for testing
aws apigateway put-integration \
  --rest-api-id "$API_ID" \
  --resource-id "$USERS_ID" \
  --http-method GET \
  --type MOCK \
  --request-templates '{"application/json": "{\"statusCode\": 200}"}' \
  --region "$REGION"

# Create method response
aws apigateway put-method-response \
  --rest-api-id "$API_ID" \
  --resource-id "$USERS_ID" \
  --http-method GET \
  --status-code 200 \
  --region "$REGION"

# Create integration response
aws apigateway put-integration-response \
  --rest-api-id "$API_ID" \
  --resource-id "$USERS_ID" \
  --http-method GET \
  --status-code 200 \
  --response-templates '{"application/json": "{\"message\": \"Success\", \"users\": []}"}' \
  --region "$REGION"

# Deploy API
DEPLOYMENT_ID=$(aws apigateway create-deployment \
  --rest-api-id "$API_ID" \
  --stage-name prod \
  --stage-description "Production stage" \
  --description "Initial deployment" \
  --region "$REGION" \
  --query 'id' \
  --output text)

echo ""
echo "API Gateway deployed successfully!"
echo "API ID: $API_ID"
echo "Deployment ID: $DEPLOYMENT_ID"
echo "Invoke URL: https://$API_ID.execute-api.$REGION.amazonaws.com/prod"

# Save API ID
echo "$API_ID" > api-id.txt

echo ""
echo "Next step: Configure resource policy using configure-resource-policy.sh"
