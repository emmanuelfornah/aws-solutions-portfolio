# AWS Solutions Portfolio

45+ hands-on AWS projects spanning compute, databases, security, serverless, CI/CD, and AI/ML, built during AWS Cloud Institute coursework — every project here was actually deployed and verified, not just followed along with in a video. This repo is the breadth layer of my AWS work; see **Flagship Projects** below for independently-designed, production-style systems built after this coursework, where the architecture decisions are mine.

## Flagship Projects (start here)

| Project | What it demonstrates |
|---|---|
| [salon-booking-app](https://github.com/emmanuelfornah/AWS-EKS-CICD-CAPSTONE) | EKS→EC2 migration, Terraform, blue/green CodeDeploy, RDS IAM auth, documented cost/architecture tradeoffs |
| [healthlab-portal](https://github.com/emmanuelfornah/healthlab-portal) | Serverless HIPAA-aligned patterns — Cognito, Step Functions, WAF/GuardDuty/Security Hub, X-Ray |
| [pedalworks-serverless-microservices](https://github.com/emmanuelfornah/pedalworks-serverless-microservices) | Monolith-to-microservices decomposition, React frontend, SAM, GitHub OIDC CI/CD |

## Certifications

**Exam-based:**
- AWS Certified Solutions Architect – Associate (exp. Aug 2029)
- AWS Certified Developer – Associate (exp. Sep 2029)
- AWS Certified AI Practitioner (exp. Sep 2028)
- AWS Certified Cloud Practitioner (exp. Sep 2029)
- HashiCorp Certified: Terraform Associate (003) (exp. Dec 2027)

**Program completion:**
- AWS Cloud Institute — Cloud Application Developer Graduate

**Additional training (The Linux Foundation):** Linux fundamentals (LFS101), Linux
system administration (LFS207), Kubernetes (LFS158), containers (LFS253), DevOps/SRE
fundamentals and continuous delivery (LFS162, LFS261), cloud technician essentials
(LFS203)

Verification: [Credly profile](https://www.credly.com/users/emmanuel-fornah)

## Projects by Domain

### Compute (7 projects)
| Project | Services | Description |
|---------|----------|-------------|
| [ec2-url-checker](compute/ec2-url-checker/) | EC2, SSM | Python URL checker on EC2 with Session Manager access |
| [wordpress-on-ec2](compute/wordpress-on-ec2/) | EC2, NLB, SSL | Production WordPress with LAMP stack and TLS encryption |
| [lambda-url-checker](compute/lambda-url-checker/) | Lambda | Serverless URL checker with Lambda deployment packages |
| [docker-ecr-url-checker](compute/docker-ecr-url-checker/) | Docker, ECR | Containerized app with ECR private registry |
| [flask-elastic-beanstalk](compute/flask-elastic-beanstalk/) | Elastic Beanstalk | Flask API with rolling deployments |
| [fargate-ecs-deployment](compute/fargate-ecs-deployment/) | ECS, Fargate | Serverless container orchestration with awsvpc networking |
| [eks-url-checker](compute/eks-url-checker/) | EKS, kubectl | Kubernetes deployment with imperative and declarative patterns |

### Databases (3 projects)
| Project | Services | Description |
|---------|----------|-------------|
| [dynamodb-tables-indexes](databases/dynamodb-tables-indexes/) | DynamoDB | Partition/sort key design and GSI query optimization |
| [dynamodb-streams-lambda](databases/dynamodb-streams-lambda/) | DynamoDB Streams, Lambda | Change data capture with event-driven processing |
| [dynamodb-capacity-scaling](databases/dynamodb-capacity-scaling/) | DynamoDB Auto Scaling | Provisioned vs on-demand capacity with auto scaling policies |

### Security (8 projects)
| Project | Services | Description |
|---------|----------|-------------|
| [api-gateway-cognito-authorizer](security/api-gateway-cognito-authorizer/) | API Gateway, Cognito | JWT authentication with Cognito User Pools |
| [oidc-identity-provider](security/oidc-identity-provider/) | IAM, STS | Federated auth with OIDC and AssumeRoleWithWebIdentity |
| [kms-secrets-manager-encryption](security/kms-secrets-manager-encryption/) | KMS, Secrets Manager | Customer-managed keys with envelope encryption |
| [lambda-secrets-manager-integration](security/lambda-secrets-manager-integration/) | Lambda, Secrets Manager | Secure data access with secret caching (99% latency reduction) |
| [waf-web-application-protection](security/waf-web-application-protection/) | WAF, ALB | OWASP Top 10 protection with rate-based DDoS mitigation |
| [inspector-vulnerability-scanning](security/inspector-vulnerability-scanning/) | Inspector, Lambda, EC2 | Automated CVE detection with hybrid scanning |
| [zero-trust-service-architecture](security/zero-trust-service-architecture/) | IAM, VPC Endpoints, API Gateway | SigV4 signing with multi-layer authorization |
| [incident-response-automation](security/incident-response-automation/) | EventBridge, Lambda | Automated detection, isolation, and forensic snapshots (<10s response) |

### CI/CD & Automation (11 projects)
| Project | Services | Description |
|---------|----------|-------------|
| [codepipeline-unit-testing](cicd-automation/codepipeline-unit-testing/) | CodePipeline, CodeDeploy | Automated unit testing with pytest and TDD |
| [codepipeline-integration-testing](cicd-automation/codepipeline-integration-testing/) | CodeBuild, CodePipeline | Multi-stage integration testing with Flask test client |
| [codedeploy-blue-green](cicd-automation/codedeploy-blue-green/) | CodeDeploy, ALB | Zero-downtime blue/green deployments |
| [cloudformation-codepipeline-iac](cicd-automation/cloudformation-codepipeline-iac/) | CloudFormation, CodePipeline | Automated infrastructure updates with cfn-lint validation |
| [cloudformation-intrinsic-functions](cicd-automation/cloudformation-intrinsic-functions/) | CloudFormation | Advanced template design with intrinsic functions |
| [cdk-constructs-lambda-api](cicd-automation/cdk-constructs-lambda-api/) | CDK, Lambda, API Gateway | Programmatic IaC with Python L2 constructs |
| [codeguru-code-reviews](cicd-automation/codeguru-code-reviews/) | CodeGuru | Automated code quality reviews |
| [distributor-package-creation](cicd-automation/distributor-package-creation/) | Systems Manager Distributor | Custom software package distribution at scale |
| [systems-manager-automation-resize](cicd-automation/systems-manager-automation-resize/) | Systems Manager Automation | Automated EC2 instance management with rate control |
| [monitoring-applications-infrastructure](cicd-automation/monitoring-applications-infrastructure/) | CloudWatch, Lambda Canary | Custom metrics, dashboards, and synthetic monitoring |
| [security-monitoring-cloudwatch-alarms](cicd-automation/security-monitoring-cloudwatch-alarms/) | CloudWatch, SNS | CPU alarms with SNS notification workflows |

### Serverless & Event-Driven (7 projects)
| Project | Services | Description |
|---------|----------|-------------|
| [lambda-dynamodb-crud](serverless/lambda-dynamodb-crud/) | Lambda, DynamoDB, S3 | Serverless CRUD API with Boto3 |
| [api-gateway-lambda-integration](serverless/api-gateway-lambda-integration/) | API Gateway, Lambda | HTTP API with Lambda proxy integration and CORS |
| [sam-infrastructure-as-code](serverless/sam-infrastructure-as-code/) | SAM, CloudFormation | SAM CLI workflow — build, deploy, local testing |
| [step-functions-workflow-orchestration](serverless/step-functions-workflow-orchestration/) | Step Functions, Lambda | State machine design with choice states and error handling |
| [sns-sqs-fanout-pattern](serverless/sns-sqs-fanout-pattern/) | SNS, SQS, Lambda | Pub/sub fan-out with dead letter queues |
| [eventbridge-decoupled-architecture](serverless/eventbridge-decoupled-architecture/) | EventBridge, WebSocket API | Event-driven microservices with real-time updates |
| [kinesis-streaming-pipeline](serverless/kinesis-streaming-pipeline/) | Kinesis, DynamoDB Streams, OpenSearch | Real-time stream processing and analytics |

### AI/ML (9 projects)
| Project | Services | Description |
|---------|----------|-------------|
| [bedrock-console-introduction](ai-ml/bedrock-console-introduction/) | Bedrock | Foundation model exploration and parameter tuning |
| [prompt-engineering-methods](ai-ml/prompt-engineering-methods/) | Bedrock, Nova, Llama 3 | Zero-shot, few-shot, and chain-of-thought techniques |
| [bedrock-python-sdk](ai-ml/bedrock-python-sdk/) | Bedrock, S3, Rekognition | Programmatic model invocation with multi-service integration |
| [bedrock-flashcard-application](ai-ml/bedrock-flashcard-application/) | Bedrock, Lambda, API Gateway | End-to-end serverless AI app with structured JSON output |
| [bedrock-rag-knowledge-bases](ai-ml/bedrock-rag-knowledge-bases/) | Bedrock, Knowledge Bases | RAG with vector embeddings and source attribution |
| [langchain-ai-development](ai-ml/langchain-ai-development/) | Bedrock, LangChain | Prompt templates, output parsers, document loaders |
| [langchain-chatbots](ai-ml/langchain-chatbots/) | Bedrock, LangChain, DynamoDB | Conversational AI with memory and Streamlit GUI |
| [bedrock-guardrails-security](ai-ml/bedrock-guardrails-security/) | Bedrock Guardrails | Content filtering, PII detection, prompt injection mitigation |
| [labveritas-order-redundancy](ai-ml/labveritas-order-redundancy/) | Bedrock, Bedrock Guardrails, Lambda, DynamoDB, SNS | Healthcare-focused analyte-level lab order redundancy detection with responsible AI controls |

## Tech Stack

- **Languages**: Python, Bash, YAML/JSON
- **IaC**: CloudFormation, SAM, CDK
- **Containers**: Docker, ECS Fargate, EKS
- **CI/CD**: CodePipeline, CodeBuild, CodeDeploy
- **AI/ML**: Amazon Bedrock, LangChain
- **40+ AWS services** across 6 domains

## License

MIT
