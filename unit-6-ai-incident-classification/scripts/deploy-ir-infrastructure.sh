#!/bin/bash

# Deploy Incident Response Infrastructure
# Creates Lambda functions, EventBridge rules, and supporting resources

set -e

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

echo "Deploying incident response infrastructure..."

# Create S3 bucket for evidence storage
EVIDENCE_BUCKET="incident-response-evidence-$ACCOUNT_ID"
aws s3 mb "s3://$EVIDENCE_BUCKET" --region "$REGION" 2>/dev/null || echo "Bucket already exists"

# Enable versioning and encryption
aws s3api put-bucket-versioning \
  --bucket "$EVIDENCE_BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "$EVIDENCE_BUCKET" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

echo "Evidence bucket created: $EVIDENCE_BUCKET"

# Create SNS topic for notifications
SNS_TOPIC_ARN=$(aws sns create-topic \
  --name SecurityIncidentAlerts \
  --region "$REGION" \
  --query 'TopicArn' \
  --output text)

echo "SNS topic created: $SNS_TOPIC_ARN"

# Subscribe email to SNS topic
read -p "Enter email address for incident notifications: " EMAIL
aws sns subscribe \
  --topic-arn "$SNS_TOPIC_ARN" \
  --protocol email \
  --notification-endpoint "$EMAIL" \
  --region "$REGION"

echo "Email subscription created. Check your email to confirm."

# Create IAM role for Lambda
cat > lambda-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "lambda.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
EOF

LAMBDA_ROLE_ARN=$(aws iam create-role \
  --role-name IncidentResponseLambdaRole \
  --assume-role-policy-document file://lambda-trust-policy.json \
  --query 'Role.Arn' \
  --output text 2>/dev/null || \
  aws iam get-role --role-name IncidentResponseLambdaRole --query 'Role.Arn' --output text)

# Attach policies to Lambda role
aws iam attach-role-policy \
  --role-name IncidentResponseLambdaRole \
  --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

# Create custom policy for incident response actions
cat > ir-lambda-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeVolumes",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:ModifyInstanceAttribute",
        "ec2:DescribeSecurityGroups"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::$EVIDENCE_BUCKET/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": "$SNS_TOPIC_ARN"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:StartQuery",
        "logs:GetQueryResults"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "events:PutEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name IncidentResponseLambdaRole \
  --policy-name IncidentResponsePolicy \
  --policy-document file://ir-lambda-policy.json

echo "Lambda IAM role created: $LAMBDA_ROLE_ARN"

# Package and deploy Lambda function
echo "Creating Lambda deployment package..."
mkdir -p lambda-package
cp ../lambda/isolate_instance.py lambda-package/
cd lambda-package
zip -r ../isolate-instance.zip .
cd ..

# Create Lambda function
LAMBDA_ARN=$(aws lambda create-function \
  --function-name IsolateCompromisedInstance \
  --runtime python3.11 \
  --role "$LAMBDA_ROLE_ARN" \
  --handler isolate_instance.lambda_handler \
  --zip-file fileb://isolate-instance.zip \
  --timeout 300 \
  --memory-size 512 \
  --environment "Variables={
    EVIDENCE_BUCKET=$EVIDENCE_BUCKET,
    SNS_TOPIC_ARN=$SNS_TOPIC_ARN,
    ISOLATION_SECURITY_GROUP=sg-isolation
  }" \
  --region "$REGION" \
  --query 'FunctionArn' \
  --output text 2>/dev/null || \
  aws lambda get-function --function-name IsolateCompromisedInstance --query 'Configuration.FunctionArn' --output text)

echo "Lambda function created: $LAMBDA_ARN"

# Save configuration
cat > ir-config.txt <<EOF
EVIDENCE_BUCKET=$EVIDENCE_BUCKET
SNS_TOPIC_ARN=$SNS_TOPIC_ARN
LAMBDA_ROLE_ARN=$LAMBDA_ROLE_ARN
LAMBDA_ARN=$LAMBDA_ARN
REGION=$REGION
EOF

echo ""
echo "Incident response infrastructure deployed successfully!"
echo "Configuration saved to ir-config.txt"
echo ""
echo "Next steps:"
echo "1. Confirm SNS email subscription"
echo "2. Run create-isolation-security-group.sh"
echo "3. Run configure-eventbridge-rules.sh"
