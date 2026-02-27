@echo off
echo ========================================
echo LAB MIGRATION TO PILLAR DIRECTORIES
echo ========================================
echo.
echo This will reorganize labs by AWS Well-Architected pillars
echo Press Ctrl+C to cancel, or
pause

echo.
echo Migrating labs...
echo.

REM From compute to operational-excellence
git mv compute/docker-ecr-url-checker operational-excellence/
git mv compute/eks-url-checker operational-excellence/
git mv compute/fargate-ecs-deployment operational-excellence/
git mv compute/flask-elastic-beanstalk operational-excellence/
git mv compute/lambda-url-checker operational-excellence/

REM From compute to security
git mv compute/ec2-url-checker security/
git mv compute/wordpress-on-ec2 security/

REM From ai-ml-applications to operational-excellence
git mv ai-ml-applications/bedrock-console-introduction operational-excellence/
git mv ai-ml-applications/langchain-ai-development operational-excellence/

REM From ai-ml-applications to security
git mv ai-ml-applications/bedrock-flashcard-application security/
git mv ai-ml-applications/bedrock-guardrails-security security/
git mv ai-ml-applications/bedrock-python-sdk security/

REM From ai-ml-applications to performance-efficiency
git mv ai-ml-applications/bedrock-rag-knowledge-bases performance-efficiency/

REM From ai-ml-applications to cost-optimization
git mv ai-ml-applications/langchain-chatbots cost-optimization/
git mv ai-ml-applications/prompt-engineering-methods cost-optimization/

REM From devops-cicd to operational-excellence
git mv devops-cicd/cdk-constructs-lambda-api operational-excellence/
git mv devops-cicd/cloudformation-codepipeline-iac operational-excellence/
git mv devops-cicd/cloudformation-intrinsic-functions operational-excellence/
git mv devops-cicd/codedeploy-blue-green operational-excellence/
git mv devops-cicd/codeguru-code-reviews operational-excellence/
git mv devops-cicd/codepipeline-integration-testing operational-excellence/
git mv devops-cicd/codepipeline-unit-testing operational-excellence/
git mv devops-cicd/distributor-package-creation operational-excellence/
git mv devops-cicd/eventbridge-automation operational-excellence/
git mv devops-cicd/systems-manager-automation-resize operational-excellence/

REM From databases to operational-excellence
git mv databases/dynamodb-capacity-scaling operational-excellence/
git mv databases/dynamodb-streams-lambda operational-excellence/
git mv databases/dynamodb-tables-indexes operational-excellence/

REM From databases to security
git mv databases/dynamodb-encryption security/

REM From databases to cost-optimization
git mv databases/rds-cost-optimization cost-optimization/

REM From databases to reliability
git mv databases/rds-automated-backups reliability/
git mv databases/rds-multi-az reliability/
git mv databases/rds-read-replicas reliability/

REM From monitoring to operational-excellence
git mv monitoring/monitoring-applications-infrastructure operational-excellence/
git mv monitoring/security-monitoring-cloudwatch-alarms operational-excellence/

REM From modern-applications to operational-excellence
git mv modern-applications/event-driven-architecture operational-excellence/
git mv modern-applications/serverless-development operational-excellence/

REM From networking to security
git mv networking/network-security-groups security/
git mv networking/vpc-flow-logs security/
git mv networking/vpc-peering security/
git mv networking/vpc-private-subnets security/
git mv networking/vpc-public-subnets security/
git mv networking/vpc-security-groups security/

REM From networking to performance-efficiency  
git mv networking/cloudfront-distribution performance-efficiency/

REM From storage to security
git mv storage/s3-bucket-policies security/
git mv storage/s3-encryption security/
git mv storage/s3-versioning-lifecycle security/

REM From storage to cost-optimization
git mv storage/s3-intelligent-tiering cost-optimization/
git mv storage/s3-storage-classes cost-optimization/

REM Security labs stay in security (no move needed)
REM These are already in the correct pillar directory

echo.
echo ========================================
echo MIGRATION COMPLETE
echo ========================================
echo.
echo Next steps:
echo 1. Run: git status
echo 2. Review the changes
echo 3. Commit: git commit -m "Reorganize portfolio by AWS Well-Architected pillars"
echo.
pause
