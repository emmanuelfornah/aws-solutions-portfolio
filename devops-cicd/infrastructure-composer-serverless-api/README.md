# Building a Serverless API with AWS Infrastructure Composer

## Overview

This lab teaches how to use AWS Infrastructure Composer to visually design and build a serverless product catalog management system. You'll create a complete REST API with CRUD operations on DynamoDB, exposed through API Gateway and Lambda functions. Infrastructure Composer provides a visual canvas for designing CloudFormation templates, making it easier to understand resource relationships and build serverless architectures.

**Duration:** 90 minutes  
**Complexity:** Intermediate  
**Category:** DevOps & CI/CD

## Business Context

AnyCompany e-commerce needs a serverless product catalog management system that can:
- Create new product items
- Retrieve all items in the catalog
- Retrieve specific items by ID
- Update existing items
- Scale automatically with demand
- Minimize operational overhead

## Objectives

By completing this lab, you will:

- Familiarize with Infrastructure Composer interface (Canvas, Template, Arrange views)
- Create REST API using AWS::ApiGateway::RestApi
- Design DynamoDB table with proper key schema
- Build Lambda functions for CRUD operations (CREATE, READ, UPDATE)
- Configure API Gateway methods and integrations
- Set up Lambda permissions for API Gateway invocation
- Test all CRUD operations via API Gateway console
- Manage CloudFormation stack lifecycle (create, update, delete)
- Understand serverless architecture patterns
- Work with Boto3 for DynamoDB operations

## AWS Services Used

- **AWS Infrastructure Composer** - Visual IaC design tool
- **AWS CloudFormation** - Infrastructure as Code deployment
- **Amazon API Gateway** - REST API management
- **AWS Lambda** - Serverless compute for business logic
- **Amazon DynamoDB** - NoSQL database for product catalog
- **AWS IAM** - Permissions and roles
- **Amazon S3** - CloudFormation artifact storage

## Architecture

The lab implements a serverless REST API with the following components:

### API Structure

**Base Resource:** `/items`
- **POST /items** - Create new item
- **GET /items** - Retrieve all items

**Item Resource:** `/items/{id}`
- **GET /items/{id}** - Retrieve item by ID
- **PUT /items/{id}** - Update existing item
- **DELETE /items/{id}** - Delete item (optional)

### Lambda Functions

1. **CreateItemFunction** - Handles POST /items
   - Validates request body
   - Writes item to DynamoDB using put_item
   - Returns 200 with created item

2. **ReadItemsFunction** - Handles GET /items
   - Scans DynamoDB table
   - Returns all items with pagination support
   - Returns 200 with items array

3. **ReadItemByIdFunction** - Handles GET /items/{id}
   - Extracts ID from path parameters
   - Retrieves item using get_item
   - Returns 200 with item or 404 if not found

4. **UpdateItemFunction** - Handles PUT /items/{id}
   - Extracts ID from path parameters
   - Updates item using update_item
   - Returns 200 with updated item

### DynamoDB Table

**Table Name:** Items  
**Partition Key:** id (String, HASH)  
**Capacity:** 5 RCU, 5 WCU (provisioned)

### IAM Configuration

**RestApiLambdaRoleARN** - Imported role with permissions:
- DynamoDB read/write operations
- CloudWatch Logs for Lambda execution
- Basic Lambda execution permissions

## Prerequisites

- AWS account with appropriate permissions
- Access to AWS Infrastructure Composer
- Basic understanding of REST APIs
- Familiarity with Python and Boto3
- Understanding of DynamoDB concepts

## Setup Instructions

### Step 1: Access Infrastructure Composer

1. Navigate to AWS CloudFormation console
2. Click "Infrastructure Composer" in the left navigation
3. Choose "Create template" to open the visual designer
4. Familiarize yourself with three views:
   - **Canvas** - Visual drag-and-drop interface
   - **Template** - YAML/JSON CloudFormation code
   - **Arrange** - Auto-layout for better visualization

### Step 2: Create REST API

1. In Canvas view, search for "API Gateway REST API"
2. Drag `AWS::ApiGateway::RestApi` to canvas
3. Configure properties:
   - Name: `Items`
   - Description: `Product catalog REST API`

### Step 3: Create DynamoDB Table

1. Search for "DynamoDB Table"
2. Drag `AWS::DynamoDB::Table` to canvas
3. Configure properties:
   - TableName: `Items`
   - AttributeDefinitions:
     - AttributeName: `id`, AttributeType: `S`
   - KeySchema:
     - AttributeName: `id`, KeyType: `HASH`
   - ProvisionedThroughput:
     - ReadCapacityUnits: `5`
     - WriteCapacityUnits: `5`

### Step 4: Add CREATE Functionality

**Create Lambda Function:**
1. Drag `AWS::Lambda::Function` to canvas
2. Name: `CreateItemFunction`
3. Runtime: `python3.12`
4. Handler: `index.lambda_handler`
5. Role: Import `RestApiLambdaRoleARN`
6. Code: See [scripts/create_item.py](./scripts/create_item.py)

**Create API Resource:**
1. Drag `AWS::ApiGateway::Resource` to canvas
2. PathPart: `items`
3. Connect to REST API

**Create POST Method:**
1. Drag `AWS::ApiGateway::Method` to canvas
2. HttpMethod: `POST`
3. Integration:
   - Type: `AWS_PROXY`
   - IntegrationHttpMethod: `POST`
   - Uri: Lambda function ARN

**Add Lambda Permission:**
1. Drag `AWS::Lambda::Permission` to canvas
2. Action: `lambda:InvokeFunction`
3. Principal: `apigateway.amazonaws.com`
4. SourceArn: API Gateway execution ARN

### Step 5: Add READ ALL Functionality

**Create Lambda Function:**
1. Drag `AWS::Lambda::Function` to canvas
2. Name: `ReadItemsFunction`
3. Runtime: `python3.12`
4. Code: See [scripts/read_items.py](./scripts/read_items.py)

**Create GET Method:**
1. Drag `AWS::ApiGateway::Method` to canvas
2. HttpMethod: `GET`
3. Connect to `/items` resource
4. Integration: AWS_PROXY with Lambda

**Add Lambda Permission:**
1. Configure permission for API Gateway invocation

### Step 6: Add READ BY ID Functionality

**Create Item Resource:**
1. Drag `AWS::ApiGateway::Resource` to canvas
2. PathPart: `{id}`
3. Parent: `/items` resource

**Create Lambda Function:**
1. Name: `ReadItemByIdFunction`
2. Runtime: `python3.12`
3. Code: See [scripts/read_item_by_id.py](./scripts/read_item_by_id.py)

**Create GET Method:**
1. HttpMethod: `GET`
2. Connect to `/items/{id}` resource
3. Integration: AWS_PROXY with Lambda

**Add Lambda Permission:**
1. Configure permission for API Gateway invocation

### Step 7: Add UPDATE Functionality

**Create Lambda Function:**
1. Name: `UpdateItemFunction`
2. Runtime: `python3.12`
3. Code: See [scripts/update_item.py](./scripts/update_item.py)

**Create PUT Method:**
1. HttpMethod: `PUT`
2. Connect to `/items/{id}` resource
3. Integration: AWS_PROXY with Lambda

**Add Lambda Permission:**
1. Configure permission for API Gateway invocation

### Step 8: Deploy API

1. Create `AWS::ApiGateway::Deployment`
2. StageName: `prod`
3. Connect to REST API
4. This creates the deployment endpoint

### Step 9: Deploy CloudFormation Stack

1. Click "Create stack" in Infrastructure Composer
2. Stack name: `serverless-api-stack`
3. Review resources in template view
4. Deploy stack
5. Wait for CREATE_COMPLETE status

See [configs/serverless-api-template.yml](./configs/serverless-api-template.yml) for the complete template.

### Step 10: Test CRUD Operations

**Test CREATE (POST /items):**
```bash
curl -X POST https://API_ID.execute-api.REGION.amazonaws.com/prod/items \
  -H "Content-Type: application/json" \
  -d '{
    "id": "item-001",
    "name": "Laptop",
    "price": 999.99,
    "category": "Electronics"
  }'
```

**Test READ ALL (GET /items):**
```bash
curl https://API_ID.execute-api.REGION.amazonaws.com/prod/items
```

**Test READ BY ID (GET /items/{id}):**
```bash
curl https://API_ID.execute-api.REGION.amazonaws.com/prod/items/item-001
```

**Test UPDATE (PUT /items/{id}):**
```bash
curl -X PUT https://API_ID.execute-api.REGION.amazonaws.com/prod/items/item-001 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Gaming Laptop",
    "price": 1299.99
  }'
```

Or use the provided test script:
```bash
./scripts/test-api.sh
```

## Key Learnings

### Infrastructure Composer Benefits

**Visual Design:**
- Drag-and-drop interface for AWS resources
- Automatic relationship detection
- Real-time CloudFormation template generation
- Visual validation of resource connections

**Faster Development:**
- No need to memorize CloudFormation syntax
- Auto-complete for resource properties
- Built-in validation and error checking
- Quick iteration on architecture designs

**Learning Tool:**
- Understand resource relationships visually
- See how services connect together
- Learn CloudFormation by example
- Export templates for version control

### Serverless Architecture Patterns

**API Gateway + Lambda:**
- API Gateway handles HTTP routing and authentication
- Lambda executes business logic on-demand
- No server management required
- Automatic scaling with traffic

**AWS_PROXY Integration:**
- Lambda receives full HTTP request context
- Lambda returns HTTP response format
- Simplifies integration code
- Supports all HTTP methods and headers

**DynamoDB Access Patterns:**
- Partition key for direct item access (get_item)
- Scan for retrieving all items (with pagination)
- Update expressions for partial updates
- Conditional writes for consistency

### Python Boto3 DynamoDB Operations

**put_item (Create):**
```python
table.put_item(Item={
    'id': 'item-001',
    'name': 'Laptop',
    'price': Decimal('999.99')
})
```

**scan (Read All):**
```python
response = table.scan()
items = response['Items']
```

**get_item (Read By ID):**
```python
response = table.get_item(Key={'id': 'item-001'})
item = response.get('Item')
```

**update_item (Update):**
```python
table.update_item(
    Key={'id': 'item-001'},
    UpdateExpression='SET #name = :name, price = :price',
    ExpressionAttributeNames={'#name': 'name'},
    ExpressionAttributeValues={
        ':name': 'Gaming Laptop',
        ':price': Decimal('1299.99')
    }
)
```

### Lambda Response Format

**Success Response:**
```python
return {
    'statusCode': 200,
    'headers': {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
    },
    'body': json.dumps({'item': item})
}
```

**Error Response:**
```python
return {
    'statusCode': 404,
    'headers': {'Content-Type': 'application/json'},
    'body': json.dumps({'error': 'Item not found'})
}
```

### CloudFormation Stack Management

**Create Stack:**
- Deploy infrastructure from template
- CloudFormation creates resources in dependency order
- Rollback on failure

**Update Stack:**
- Modify template in Infrastructure Composer
- CloudFormation calculates change set
- Updates only changed resources

**Delete Stack:**
- Removes all resources in reverse order
- Cleans up S3 artifacts
- Deletes DynamoDB table (data loss!)

## Interview Talking Points

### Serverless API Development

**"I built a complete serverless REST API using AWS Infrastructure Composer, API Gateway, Lambda, and DynamoDB. The API supported full CRUD operations for a product catalog with four Lambda functions handling create, read, update, and delete operations. I used AWS_PROXY integration for seamless Lambda-API Gateway communication and implemented proper error handling with appropriate HTTP status codes."**

### Infrastructure as Code with Visual Tools

**"I used AWS Infrastructure Composer to visually design the serverless architecture, which automatically generated CloudFormation templates. This visual approach helped me understand resource relationships and dependencies. The tool provided real-time validation and made it easy to iterate on the design. I could switch between Canvas view for visual design and Template view to see the generated CloudFormation YAML."**

### DynamoDB Access Patterns

**"I implemented multiple DynamoDB access patterns using Boto3. For creating items, I used put_item with the full item object. For retrieving all items, I used scan with pagination support. For reading specific items, I used get_item with the partition key. For updates, I used update_item with UpdateExpression to modify only specific attributes without replacing the entire item."**

### API Gateway Integration

**"I configured API Gateway with multiple resources and methods: POST /items for creation, GET /items for listing, GET /items/{id} for retrieval, and PUT /items/{id} for updates. Each method used AWS_PROXY integration with Lambda, which passes the full HTTP request context to Lambda and expects a properly formatted HTTP response. I also configured Lambda permissions to allow API Gateway to invoke the functions."**

## Project Structure

```
devops-cicd/infrastructure-composer-serverless-api/
├── README.md                          # This file
├── scripts/
│   ├── create_item.py                 # Lambda: Create item
│   ├── read_items.py                  # Lambda: Read all items
│   ├── read_item_by_id.py             # Lambda: Read item by ID
│   ├── update_item.py                 # Lambda: Update item
│   ├── delete_item.py                 # Lambda: Delete item (optional)
│   └── test-api.sh                    # API testing script
└── configs/
    └── serverless-api-template.yml    # Complete CloudFormation template
```

## Additional Resources

- [AWS Infrastructure Composer Documentation](https://docs.aws.amazon.com/infrastructure-composer/)
- [Amazon API Gateway Developer Guide](https://docs.aws.amazon.com/apigateway/)
- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/)
- [Amazon DynamoDB Developer Guide](https://docs.aws.amazon.com/dynamodb/)
- [Boto3 DynamoDB Documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/dynamodb.html)
- [Serverless Architecture Patterns](https://aws.amazon.com/serverless/)

## Troubleshooting

### Lambda Function Fails

- Check CloudWatch Logs for error messages
- Verify IAM role has DynamoDB permissions
- Ensure table name matches in code and template
- Check Python syntax and imports

### API Gateway Returns 403 Forbidden

- Verify Lambda permission allows API Gateway invocation
- Check API Gateway deployment is current
- Ensure correct stage name in URL
- Verify IAM role for Lambda execution

### DynamoDB Operation Fails

- Check table exists and is ACTIVE
- Verify partition key name matches ('id')
- Ensure attribute types are correct (String)
- Check provisioned capacity is sufficient

### Item Not Found (404)

- Verify item ID exists in DynamoDB
- Check path parameter extraction in Lambda
- Ensure correct key schema in get_item call
- Test with DynamoDB console first

### Infrastructure Composer Issues

- Refresh browser if canvas doesn't load
- Check resource connections are properly linked
- Validate template before deploying
- Use Arrange view to organize complex diagrams

## Next Steps

- Add DELETE functionality for complete CRUD
- Implement pagination for large result sets
- Add input validation and error handling
- Configure API Gateway authentication (Cognito, API Keys)
- Add CloudWatch alarms for Lambda errors
- Implement DynamoDB Global Secondary Indexes
- Add API Gateway request/response validation
- Configure CORS for web application access
- Implement caching with API Gateway
- Add X-Ray tracing for distributed debugging

## License

This lab is for educational purposes as part of an AWS training portfolio.
