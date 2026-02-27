# Using AWS CodePipeline for Unit Testing

## Overview

This lab demonstrates how to implement automated unit testing in a CI/CD pipeline using AWS CodePipeline. You'll work with a Flask-based Presidents application that has a bug in its age calculation logic, fix the bug using test-driven development practices, and watch as CodePipeline automatically tests and deploys your changes.

**Duration:** 60 minutes  
**Complexity:** Intermediate  
**Category:** DevOps & CI/CD

## The Bug

The Presidents application calculates ages incorrectly. For example, President John Adams' age is shown as 91 years when it should be 90 years. The bug stems from using simple year subtraction instead of accounting for actual dates.

**Current (Buggy) Logic:**
```python
age = president["Died"].year - president["Born"].year
```

**Fixed Logic:**
```python
from dateutil.relativedelta import relativedelta
age = relativedelta(president["Died"], president["Born"]).years
```

## Objectives

By completing this lab, you will:

- Verify and understand a bug in production code
- Install and configure development dependencies in AWS Cloud9/Code Editor
- Run unit tests locally to identify code flaws
- Fix application logic using Python's `relativedelta` for accurate date calculations
- Update unit tests to reflect correct expected values
- Push changes to AWS CodeCommit repository
- Observe automated CI/CD pipeline execution
- Verify successful deployment and bug resolution

## AWS Services Used

- **AWS CodePipeline** - Orchestrates the CI/CD workflow
- **AWS CodeCommit** - Git-based source control repository
- **AWS CodeDeploy** - Automated application deployment
- **AWS Cloud9/Code Editor** - Cloud-based IDE for development
- **Amazon EC2** - Hosts the web application
- **Amazon DynamoDB** - Stores Presidents data

## Architecture

The lab implements a complete CI/CD pipeline:

1. **Developer** - Makes code changes in AWS Cloud9/Code Editor
2. **CodeCommit** - Stores source code in Git repository
3. **CodePipeline** - Detects changes and orchestrates pipeline stages
4. **Test Stage** - Runs pytest unit tests automatically
5. **Deploy Stage** - Uses CodeDeploy to deploy to EC2 if tests pass
6. **EC2 Instance** - Serves the Flask application
7. **DynamoDB** - Provides Presidents data to the application

See [architecture.md](./architecture.md) for detailed pipeline workflow.

## Prerequisites

- AWS account with appropriate permissions
- AWS Cloud9 or Code Editor IDE environment
- CodeCommit repository with Presidents application code
- CodePipeline configured with Source, Test, and Deploy stages
- EC2 instance with CodeDeploy agent installed

## Setup Instructions

### Step 1: Verify the Bug

1. Navigate to the application URL in your browser
2. Find President John Adams in the list
3. Note that his age shows as 91 years (incorrect - should be 90)

### Step 2: Install Dependencies

Install application dependencies:
```bash
cd ~/environment/presidents-app
pip install -r app/requirements.txt
```

Install testing dependencies:
```bash
pip install -r tests/requirements.txt
```

Or use the provided script:
```bash
./scripts/install-dependencies.sh
```

### Step 3: Run Unit Tests Locally

Execute the test suite to see the failing test:
```bash
./run_tests.sh
```

You should see a test failure indicating the age calculation is incorrect.

### Step 4: Fix the Application Logic

Update `app/presidents.py` to use `relativedelta`:

```python
from dateutil.relativedelta import relativedelta

# Replace the buggy calculation
age = relativedelta(president["Died"], president["Born"]).years
```

### Step 5: Update Unit Tests

Modify `tests/test_handler.py` to expect the correct age (90 instead of 91).

### Step 6: Verify Fix Locally

Run tests again to confirm they pass:
```bash
./run_tests.sh
```

### Step 7: Push Changes to CodeCommit

```bash
git add .
git commit -m "Fix age calculation using relativedelta"
git push origin main
```

Or use the provided script:
```bash
./scripts/git-workflow.sh
```

### Step 8: Monitor CodePipeline

1. Navigate to AWS CodePipeline console
2. Watch your pipeline automatically trigger
3. Observe the Source, Test, and Deploy stages execute
4. Verify all stages complete successfully

### Step 9: Verify the Fix

1. Return to the application URL
2. Refresh the page
3. Confirm President John Adams now shows age 90 (correct)

## Key Learnings

### CI/CD Pipeline Automation

- **Automated Testing** - Unit tests run automatically on every code push
- **Fast Feedback** - Developers know immediately if changes break tests
- **Deployment Automation** - Successful tests trigger automatic deployment
- **Quality Gates** - Failed tests prevent buggy code from reaching production

### Test-Driven Development

- **Write Tests First** - Define expected behavior before implementation
- **Red-Green-Refactor** - See tests fail, make them pass, improve code
- **Regression Prevention** - Tests catch bugs before they reach users
- **Living Documentation** - Tests document how code should behave

### Python Date Calculations

**Why Year Subtraction Fails:**
```python
# Born: October 30, 1735
# Died: July 4, 1826
# Simple subtraction: 1826 - 1735 = 91 years
# But Adams died before his 91st birthday!
```

**Why relativedelta Works:**
```python
# relativedelta accounts for actual dates
# Born: October 30, 1735
# Died: July 4, 1826
# Actual age: 90 years, 8 months, 4 days
# .years property returns 90 (correct)
```

### AWS CodePipeline Benefits

- **Source Integration** - Automatically detects CodeCommit changes
- **Flexible Stages** - Build, test, deploy, and custom actions
- **Parallel Execution** - Run multiple actions simultaneously
- **Manual Approvals** - Add human gates for production deployments
- **Cross-Region** - Deploy to multiple AWS regions
- **Notifications** - SNS integration for pipeline events

## Interview Talking Points

### CI/CD Best Practices

**"In this project, I implemented a complete CI/CD pipeline using AWS CodePipeline that automated unit testing and deployment. The pipeline had three stages: Source (CodeCommit), Test (pytest), and Deploy (CodeDeploy). This ensured that every code change was automatically tested before deployment, preventing bugs from reaching production."**

### Test-Driven Development

**"I used test-driven development to fix a date calculation bug. First, I ran the existing unit tests to identify the failure. Then I updated the application logic to use Python's relativedelta instead of simple year subtraction. Finally, I updated the tests to expect the correct values and verified all tests passed before pushing to the repository."**

### Automated Quality Gates

**"The pipeline implemented quality gates where failed unit tests would prevent deployment. This meant that if my code changes broke any tests, CodePipeline would stop the pipeline and prevent the buggy code from reaching the EC2 instance. This automated quality control is crucial for maintaining application reliability."**

### Infrastructure as Code

**"While fixing the application bug, I also learned how CodePipeline integrates with other AWS services. The pipeline was defined as code, making it repeatable and version-controlled. CodeDeploy used appspec.yml to define deployment steps, and the entire infrastructure could be recreated in any AWS account."**

## Project Structure

```
devops-cicd/codepipeline-unit-testing/
├── README.md                          # This file
├── architecture.md                    # Detailed pipeline architecture
├── scripts/
│   ├── install-dependencies.sh        # Install app and test dependencies
│   ├── run-tests.sh                   # Execute unit tests
│   └── git-workflow.sh                # Git commands for pushing changes
├── configs/
│   ├── app-requirements.txt           # Application dependencies
│   └── test-requirements.txt          # Testing dependencies
└── application/
    ├── presidents.py                  # Sample application logic
    └── test_handler.py                # Sample unit test
```

## Additional Resources

- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [AWS CodeCommit User Guide](https://docs.aws.amazon.com/codecommit/)
- [AWS CodeDeploy Documentation](https://docs.aws.amazon.com/codedeploy/)
- [pytest Documentation](https://docs.pytest.org/)
- [Python dateutil Library](https://dateutil.readthedocs.io/)

## Troubleshooting

### Tests Fail Locally

- Ensure all dependencies are installed: `pip install -r tests/requirements.txt`
- Check Python version compatibility (Python 3.7+)
- Verify you're in the correct directory

### Pipeline Doesn't Trigger

- Confirm changes were pushed to CodeCommit: `git log --oneline`
- Check CodePipeline is monitoring the correct branch
- Verify IAM permissions for CodePipeline service role

### Deployment Fails

- Check CodeDeploy agent is running on EC2 instance
- Verify appspec.yml is correctly formatted
- Review CodeDeploy logs on the EC2 instance: `/var/log/aws/codedeploy-agent/`

### Application Still Shows Bug

- Clear browser cache and refresh
- Verify deployment completed successfully in CodeDeploy console
- SSH to EC2 instance and check application files were updated

## Next Steps

- Add code coverage reporting to the pipeline
- Implement integration tests in addition to unit tests
- Add a manual approval stage before production deployment
- Configure SNS notifications for pipeline failures
- Explore blue/green deployments with CodeDeploy
- Add static code analysis (linting) to the Test stage

## License

This lab is for educational purposes as part of an AWS training portfolio.
