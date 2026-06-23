#!/bin/bash

# Deploy AI-driven incident classification components

set -euo pipefail

REGION="${REGION:-us-east-1}"
MODEL_ID="${BEDROCK_MODEL_ID:-amazon.nova-lite-v1:0}"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

echo "Deploying AI incident classification workflow in $REGION..."

if [ -f ir-config.txt ]; then
  source ir-config.txt
fi

LAMBDA_ROLE_NAME="IncidentResponseLambdaRole"
LAMBDA_ROLE_ARN=$(aws iam get-role --role-name "$LAMBDA_ROLE_NAME" --query 'Role.Arn' --output text)

mkdir -p lambda-package-classifier
cp ../application/incident_classifier.py lambda-package-classifier/
(
  cd lambda-package-classifier
  zip -q -r ../incident-classifier.zip .
)

CLASSIFIER_ARN=$(aws lambda create-function \
  --function-name ClassifyIncidentWithBedrock \
  --runtime python3.11 \
  --role "$LAMBDA_ROLE_ARN" \
  --handler incident_classifier.lambda_handler \
  --zip-file fileb://incident-classifier.zip \
  --timeout 120 \
  --memory-size 512 \
  --environment "Variables={BEDROCK_MODEL_ID=$MODEL_ID}" \
  --region "$REGION" \
  --query 'FunctionArn' \
  --output text 2>/dev/null || \
  aws lambda update-function-code \
    --function-name ClassifyIncidentWithBedrock \
    --zip-file fileb://incident-classifier.zip \
    --region "$REGION" \
    --query 'FunctionArn' \
    --output text)

mkdir -p lambda-package-router
cp ../application/route_incident.py lambda-package-router/
(
  cd lambda-package-router
  zip -q -r ../route-incident.zip .
)

ROUTER_ARN=$(aws lambda create-function \
  --function-name RouteIncidentActions \
  --runtime python3.11 \
  --role "$LAMBDA_ROLE_ARN" \
  --handler route_incident.lambda_handler \
  --zip-file fileb://route-incident.zip \
  --timeout 60 \
  --memory-size 256 \
  --region "$REGION" \
  --query 'FunctionArn' \
  --output text 2>/dev/null || \
  aws lambda update-function-code \
    --function-name RouteIncidentActions \
    --zip-file fileb://route-incident.zip \
    --region "$REGION" \
    --query 'FunctionArn' \
    --output text)

STATE_MACHINE_DEFINITION=$(sed "s/REGION/$REGION/g; s/ACCOUNT_ID/$ACCOUNT_ID/g" ../state-machine/incident-ai-triage.json)

STATE_MACHINE_ARN=$(aws stepfunctions create-state-machine \
  --name IncidentAITriageWorkflow \
  --definition "$STATE_MACHINE_DEFINITION" \
  --role-arn "arn:aws:iam::$ACCOUNT_ID:role/service-role/StatesExecutionRole-$REGION" \
  --type STANDARD \
  --query 'stateMachineArn' \
  --output text 2>/dev/null || true)

if [ -z "$STATE_MACHINE_ARN" ]; then
  STATE_MACHINE_ARN=$(aws stepfunctions list-state-machines \
    --query "stateMachines[?name=='IncidentAITriageWorkflow'].stateMachineArn | [0]" \
    --output text)
fi

aws events put-rule \
  --name AIIncidentTriageRule \
  --description "Send security findings to AI incident triage workflow" \
  --event-pattern file://../configs/eventbridge-rule-ai-incident-triage.json \
  --state ENABLED \
  --region "$REGION" >/dev/null

aws events put-targets \
  --rule AIIncidentTriageRule \
  --targets "Id=1,Arn=$STATE_MACHINE_ARN,RoleArn=arn:aws:iam::$ACCOUNT_ID:role/service-role/Amazon_EventBridge_Invoke_StepFunctions_$REGION" \
  --region "$REGION" >/dev/null

echo "CLASSIFIER_ARN=$CLASSIFIER_ARN" >> ir-config.txt
echo "ROUTER_ARN=$ROUTER_ARN" >> ir-config.txt
echo "AI_TRIAGE_STATE_MACHINE_ARN=$STATE_MACHINE_ARN" >> ir-config.txt
echo "BEDROCK_MODEL_ID=$MODEL_ID" >> ir-config.txt

echo "Deployment complete."
