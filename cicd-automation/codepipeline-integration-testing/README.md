# Using AWS CodePipeline for Integration Testing

## Overview

This project focuses on integrating automated integration testing into a CI/CD pipeline using AWS CodePipeline. It configures a pipeline with an integration testing stage that validates application functionality before deployment. This project demonstrates how integration tests differ from unit tests by verifying that multiple components work together correctly, including the Flask application's interaction with external dependencies.

**Duration:** 60 minutes  
**Complexity:** Intermediate  
**Category:** DevOps & CI/CD

## Objectives

By completing this project, you will:

- Review an existing CI/CD pipeline and Python Flask application in CodeCommit
- Create a CodeBuild project specifically for integration testing
- Add an integration test stage to an existing CodePipeline
- Configure the integration test stage with the CodeBuild project
- Clone the repository and create integration_buildspec.yml configuration
- Explore integration test scripts with intentional errors
- Review integration test failures and fix assertion errors
- Push updated code and verify successful test execution
- View the deployed application on EC2 to confirm functionality

## AWS Services Used

- **AWS CodePipeline** - Orchestrates the CI/CD workflow with multiple test stages
- **AWS CodeBuild** - Executes integration tests in isolated build environments
- **AWS CodeCommit** - Git-based source control repository
- **AWS CodeDeploy** - Automated application deployment to EC2
- **Amazon EC2** - Hosts the Flask web application
- **AWS IAM** - Manages service roles and permissions

## Architecture

This project implements a multi-stage CI/CD pipeline with separate unit and integration testing:

1. **Developer** - Makes code changes and pushes to CodeCommit
2. **CodeCommit** - Stores source code in Git repository
3. **CodePipeline** - Orchestrates the pipeline with multiple stages:
   - **Source Stage** - Retrieves code from CodeCommit
   - **Unit Test Stage** - Runs fast unit tests (existing)
   - **Integration Test Stage** - Runs integration tests (new)
   - **Deploy Stage** - Deploys to EC2 if all tests pass
4. **CodeBuild** - Executes pytest integration tests in containerized environment
5. **EC2 Instance** - Serves the Flask application
6. **CodeDeploy** - Manages deployment lifecycle

The integration test stage validates that the Flask application routes, templates, and business logic work together correctly.

## Prerequisites

- AWS account with appropriate permissions
- AWS Cloud9 or Code Editor IDE environment
- CodeCommit repository with Flask application code
- Existing CodePipeline with Source, Unit Test, and Deploy stages
- EC2 instance with CodeDeploy agent installed
- Understanding of CI/CD concepts, Git, YAML, and Python testing

## Setup Instructions

### Step 1: Review CI/CD Pipeline and Application

1. Navigate to AWS CodePipeline console
2. Review the existing pipeline structure (Source → Unit Test → Deploy)
3. Navigate to CodeCommit and review the Flask application code
4. Note the application structure and existing unit tests

### Step 2: Create CodeBuild Project for Integration Testing

1. Navigate to AWS CodeBuild console
2. Click "Create build project"
3. Configure the project:
   - **Project name:** IntegrationProject
   - **Source provider:** AWS CodeCommit
   - **Repository:** Select your Flask application repository
   - **Environment image:** Managed image
   - **Operating system:** Amazon Linux 2
   - **Runtime:** Standard
   - **Image:** Latest available
   - **Service role:** Create new or use existing
   - **Buildspec:** Use buildspec file named `integration_buildspec.yml`
4. Click "Create build project"

### Step 3: Add Integration Test Stage to Pipeline

1. Navigate to AWS CodePipeline console
2. Select your pipeline and click "Edit"
3. After the Unit Test stage, click "Add stage"
4. Name the stage "IntegrationTest"
5. Click "Add action group"
6. Configure the action:
   - **Action name:** IntegrationTestAction
   - **Action provider:** AWS CodeBuild
   - **Input artifacts:** SourceArtifact
   - **Project name:** IntegrationProject
7. Click "Done" and "Save" the pipeline

### Step 4: Clone Repository and Create Integration Buildspec

Clone the repository to your development environment:
```bash
cd ~/environment
git clone <your-codecommit-repo-url>
cd <repo-name>
```

Or use the provided script:
```bash
./scripts/clone-repo.sh
```

Create the integration buildspec configuration file (see configs/integration_buildspec.yml for reference).

### Step 5: Explore Integration Test Script

Review the integration test file `test_integration.py`:

```python
import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_page(client):
    """Test that home page loads successfully"""
    response = client.get('/')
    assert response.status_code == 200
    assert b'Welcome' in response.data

def test_api_endpoint(client):
    """Test API endpoint returns correct data"""
    response = client.get('/api/data')
    assert response.status_code == 200
    # Intentional error: expects wrong value
    assert response.json['status'] == 'error'  # Should be 'success'
```

Note the intentional assertion error in the API endpoint test.

### Step 6: Review Integration Test Failure

1. Push the integration_buildspec.yml to the repository:
```bash
git add integration_buildspec.yml
git commit -m "Add integration test buildspec"
git push origin main
```

2. Navigate to CodePipeline and watch the pipeline execute
3. Observe that the IntegrationTest stage fails
4. Click on "Details" to view the CodeBuild logs
5. Identify the assertion error in test_api_endpoint

### Step 7: Fix Assertion Error

Update `test_integration.py` to fix the assertion:

```python
def test_api_endpoint(client):
    """Test API endpoint returns correct data"""
    response = client.get('/api/data')
    assert response.status_code == 200
    # Fixed: expects correct value
    assert response.json['status'] == 'success'
```

Or use the provided fixed version in `scripts/test_integration_fixed.py`.

### Step 8: Push Updated Code and Verify

Push the corrected test:
```bash
git add test_integration.py
git commit -m "Fix integration test assertion"
git push origin main
```

Or use the workflow script:
```bash
./scripts/git-workflow.sh
```

Monitor the pipeline:
1. Navigate to CodePipeline console
2. Watch the pipeline automatically trigger
3. Verify all stages complete successfully (Source → Unit Test → IntegrationTest → Deploy)

### Step 9: View Deployed Application

1. Navigate to EC2 console
2. Find the instance running your Flask application
3. Copy the public IP or DNS
4. Open in browser: `http://<instance-ip>`
5. Verify the application is working correctly
6. Test the API endpoint: `http://<instance-ip>/api/data`

## Technical Highlights

### Integration Testing vs Unit Testing

**Unit Tests:**
- Test individual functions or methods in isolation
- Fast execution (milliseconds)
- Mock external dependencies
- Run frequently during development
- Example: Testing a single function's return value

**Integration Tests:**
- Test multiple components working together
- Slower execution (seconds to minutes)
- Use real or test instances of dependencies
- Run before deployment
- Example: Testing HTTP routes, database queries, API responses

### CI/CD Pipeline Stages

**Multi-Stage Testing Strategy:**
1. **Unit Tests** - Fast feedback on code correctness
2. **Integration Tests** - Verify component interactions
3. **Deployment** - Only if all tests pass

This approach provides:
- **Fast Feedback** - Unit tests fail quickly
- **Comprehensive Coverage** - Integration tests catch interaction bugs
- **Quality Gates** - Multiple checkpoints before production
- **Confidence** - Thorough validation before deployment

### CodeBuild for Testing

**Benefits:**
- **Isolated Environments** - Each test run gets a clean container
- **Scalability** - Parallel test execution
- **Flexibility** - Custom build environments and dependencies
- **Integration** - Seamless CodePipeline integration
- **Cost-Effective** - Pay only for build time used

**Buildspec Configuration:**
```yaml
version: 0.2
phases:
  install:
    runtime-versions:
      python: 3.9
    commands:
      - pip install -r requirements.txt
  build:
    commands:
      - pytest test_integration.py -v
```

### Flask Testing Best Practices

**Test Client Pattern:**
```python
@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client
```

This pattern:
- Enables testing mode (disables error catching)
- Provides a test client for making requests
- Automatically handles setup and teardown
- Allows testing without running a server

### Debugging Failed Tests in CI/CD

**Steps to Debug:**
1. Review CodeBuild logs in pipeline details
2. Identify the failing test and assertion
3. Reproduce locally if possible
4. Fix the code or test
5. Push changes and verify in pipeline

**Common Issues:**
- Environment differences (local vs CI)
- Missing dependencies
- Incorrect test assertions
- Configuration errors

## Interview Talking Points

### Multi-Stage Testing Strategy

**"In this project, I implemented a multi-stage CI/CD pipeline with separate unit and integration testing stages. Unit tests ran first for fast feedback on code correctness, followed by integration tests that verified the Flask application's routes and API endpoints worked correctly. This layered approach caught different types of bugs at different stages, improving overall code quality."**

### Integration Testing Implementation

**"I created a CodeBuild project specifically for integration testing and added it as a new stage in CodePipeline. The integration tests used Flask's test client to make actual HTTP requests to the application routes and verify responses. This caught issues that unit tests missed, like incorrect route configurations or template rendering problems."**

### Debugging CI/CD Failures

**"When the integration tests initially failed, I used CodeBuild's detailed logs to identify the exact assertion error. I then fixed the test expectation to match the actual API response. This experience taught me how to effectively debug failures in automated pipelines and the importance of clear, descriptive test assertions."**

### Quality Gates in Deployment

**"The pipeline implemented quality gates where both unit and integration tests had to pass before deployment. This meant that if either test stage failed, CodePipeline would stop and prevent deployment to EC2. This automated quality control ensured that only fully validated code reached production, reducing the risk of bugs affecting users."**

## Project Structure

```
devops-cicd/codepipeline-integration-testing/
├── README.md                          # This file
├── scripts/
│   ├── clone-repo.sh                  # Clone CodeCommit repository
│   ├── git-workflow.sh                # Git commands for pushing changes
│   └── test_integration_fixed.py      # Fixed integration test
├── configs/
│   ├── integration_buildspec.yml      # CodeBuild configuration
│   ├── buildspec.yml                  # Unit test buildspec (reference)
│   ├── appspec.yml                    # CodeDeploy configuration
│   ├── requirements.txt               # Python dependencies
│   ├── flaskapp.conf                  # Apache/Nginx configuration
│   ├── flaskapp.service               # Systemd service configuration
│   └── gunicorn_config.py             # Gunicorn WSGI server config
└── application/
    └── test_integration.py            # Sample integration test
```

## Additional Resources

- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [AWS CodeBuild User Guide](https://docs.aws.amazon.com/codebuild/)
- [AWS CodeCommit Documentation](https://docs.aws.amazon.com/codecommit/)
- [AWS CodeDeploy Documentation](https://docs.aws.amazon.com/codedeploy/)
- [Flask Testing Documentation](https://flask.palletsprojects.com/en/latest/testing/)
- [pytest Documentation](https://docs.pytest.org/)

## Troubleshooting

### Integration Test Stage Fails

- Review CodeBuild logs for specific error messages
- Verify integration_buildspec.yml is correctly formatted
- Check that all dependencies are listed in requirements.txt
- Ensure test file paths are correct in buildspec

### CodeBuild Project Not Found

- Verify the CodeBuild project name matches exactly
- Check IAM permissions for CodePipeline to invoke CodeBuild
- Ensure the project is in the same region as the pipeline

### Tests Pass Locally But Fail in Pipeline

- Check for environment-specific configurations
- Verify Python version matches between local and CodeBuild
- Review environment variables in CodeBuild project
- Check for missing dependencies in requirements.txt

### Pipeline Doesn't Trigger

- Confirm changes were pushed to CodeCommit
- Verify CodePipeline is monitoring the correct branch
- Check CloudWatch Events rule for the pipeline trigger

### Deployment Fails After Tests Pass

- Verify CodeDeploy agent is running on EC2 instance
- Check appspec.yml configuration
- Review CodeDeploy logs: `/var/log/aws/codedeploy-agent/`
- Ensure EC2 instance has correct IAM role

## Real-World Application

- **Continuous integration**: Every production CI/CD pipeline runs integration tests against real service endpoints before deployment approval
- **API contract testing**: Integration tests verify that API responses match expected schemas — catching breaking changes before they reach consumers
- **Database migration validation**: Integration tests confirm that schema migrations work correctly with application code before production deployment
- **Microservice compatibility**: Service-to-service integration tests ensure that upstream changes don't break downstream consumers

## Next Steps

- Add end-to-end tests that test the full user workflow
- Implement load testing in a separate pipeline stage
- Add security scanning (SAST/DAST) to the pipeline
- Configure parallel test execution for faster feedback
- Add code coverage reporting for integration tests
- Implement canary deployments with gradual rollout
- Add manual approval stage before production deployment
- Configure SNS notifications for test failures

## License

This project is for educational purposes as part of an AWS training portfolio.
