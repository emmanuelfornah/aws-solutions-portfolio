#!/bin/bash
# Script to create Amazon Bedrock Knowledge Base

# Configuration
KB_NAME="CompanyKnowledgeBase"
KB_DESCRIPTION="Company policies and documentation"
BUCKET_NAME="[BUCKET-NAME]"
COLLECTION_NAME="bedrock-kb-collection"
INDEX_NAME="bedrock-knowledge-base-index"
ROLE_NAME="BedrockKnowledgeBaseRole"

echo "Creating Amazon Bedrock Knowledge Base..."

# Step 1: Create IAM role for Knowledge Base
echo "Step 1: Creating IAM role..."
aws iam create-role \
  --role-name $ROLE_NAME \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "bedrock.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach policies
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/AmazonBedrockFullAccess

# Step 2: Create OpenSearch Serverless collection
echo "Step 2: Creating OpenSearch Serverless collection..."
aws opensearchserverless create-collection \
  --name $COLLECTION_NAME \
  --type VECTORSEARCH \
  --description "Vector store for Bedrock Knowledge Base"

# Wait for collection to be active
echo "Waiting for collection to be active..."
sleep 60

# Step 3: Create Knowledge Base
echo "Step 3: Creating Knowledge Base..."
KB_ID=$(aws bedrock-agent create-knowledge-base \
  --name $KB_NAME \
  --description "$KB_DESCRIPTION" \
  --role-arn "arn:aws:iam::[ACCOUNT-ID]:role/$ROLE_NAME" \
  --knowledge-base-configuration '{
    "type": "VECTOR",
    "vectorKnowledgeBaseConfiguration": {
      "embeddingModelArn": "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
    }
  }' \
  --storage-configuration '{
    "type": "OPENSEARCH_SERVERLESS",
    "opensearchServerlessConfiguration": {
      "collectionArn": "arn:aws:aoss:us-east-1:[ACCOUNT-ID]:collection/[COLLECTION-ID]",
      "vectorIndexName": "'$INDEX_NAME'",
      "fieldMapping": {
        "vectorField": "vector",
        "textField": "text",
        "metadataField": "metadata"
      }
    }
  }' \
  --query 'knowledgeBase.knowledgeBaseId' \
  --output text)

echo "Knowledge Base created with ID: $KB_ID"

# Step 4: Create data source
echo "Step 4: Creating S3 data source..."
DS_ID=$(aws bedrock-agent create-data-source \
  --knowledge-base-id $KB_ID \
  --name "CompanyDocuments" \
  --data-source-configuration '{
    "type": "S3",
    "s3Configuration": {
      "bucketArn": "arn:aws:s3:::'$BUCKET_NAME'",
      "inclusionPrefixes": ["documents/"]
    }
  }' \
  --query 'dataSource.dataSourceId' \
  --output text)

echo "Data source created with ID: $DS_ID"

# Step 5: Start ingestion
echo "Step 5: Starting ingestion job..."
aws bedrock-agent start-ingestion-job \
  --knowledge-base-id $KB_ID \
  --data-source-id $DS_ID

echo "Ingestion job started. Monitor progress in AWS console."
echo ""
echo "Knowledge Base ID: $KB_ID"
echo "Data Source ID: $DS_ID"
echo ""
echo "Use these IDs in your application code."
