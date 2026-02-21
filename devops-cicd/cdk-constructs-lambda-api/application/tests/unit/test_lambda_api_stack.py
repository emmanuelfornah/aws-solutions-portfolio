"""
Unit Tests for Lambda API Stack

These tests validate the infrastructure properties defined in the CDK stack
using the aws_cdk.assertions module. Tests run against the synthesized
CloudFormation template without deploying resources.
"""

import aws_cdk as cdk
from aws_cdk.assertions import Template, Match
from lambda_api.lambda_api_stack import LambdaApiStack
import pytest


@pytest.fixture
def template():
    """
    Fixture that creates a CloudFormation template from the stack.
    
    This fixture is reused across multiple tests to avoid redundant
    stack synthesis.
    """
    app = cdk.App()
    stack = LambdaApiStack(app, "TestStack")
    return Template.from_stack(stack)


def test_api_gateway_created(template):
    """
    Test that API Gateway RestApi resource exists with correct properties.
    
    Validates:
    - RestApi resource is created
    - Description matches expected value
    """
    template.has_resource_properties(
        "AWS::ApiGateway::RestApi",
        {
            "Description": "Lambda-backed API endpoint"
        }
    )


def test_api_gateway_deployment_count(template):
    """
    Test that exactly one API Gateway Deployment exists.
    
    Multiple deployments could indicate configuration issues.
    """
    template.resource_count_is("AWS::ApiGateway::Deployment", 1)


def test_api_gateway_stage_exists(template):
    """
    Test that API Gateway Stage is created with prod stage name.
    """
    template.has_resource_properties(
        "AWS::ApiGateway::Stage",
        {
            "StageName": "prod"
        }
    )


def test_lambda_function_properties(template):
    """
    Test Lambda function configuration.
    
    Validates:
    - Handler points to correct function
    - Runtime is Python 3.13
    - Function name is set correctly
    """
    template.has_resource_properties(
        "AWS::Lambda::Function",
        {
            "Handler": "hello.handler",
            "Runtime": "python3.13",
            "FunctionName": "HelloFunction"
        }
    )


def test_lambda_function_count(template):
    """
    Test that exactly one Lambda function is created.
    """
    template.resource_count_is("AWS::Lambda::Function", 1)


def test_lambda_permission_for_api_gateway(template):
    """
    Test that Lambda permission allows API Gateway to invoke the function.
    
    This permission is automatically created by the LambdaRestApi construct.
    """
    template.has_resource_properties(
        "AWS::Lambda::Permission",
        {
            "Action": "lambda:InvokeFunction",
            "Principal": "apigateway.amazonaws.com"
        }
    )


def test_stack_outputs_exist(template):
    """
    Test that required stack outputs are defined.
    
    Validates:
    - ApiUrl output exists
    - FunctionName output exists
    - FunctionArn output exists
    """
    outputs = template.find_outputs("*")
    
    # Check that outputs dictionary is not empty
    assert len(outputs) >= 3, "Stack should have at least 3 outputs"
    
    # Verify specific outputs exist
    output_keys = [key for key in outputs.keys()]
    assert any("ApiUrl" in key for key in output_keys), "ApiUrl output should exist"
    assert any("FunctionName" in key for key in output_keys), "FunctionName output should exist"
    assert any("FunctionArn" in key for key in output_keys), "FunctionArn output should exist"


def test_api_gateway_throttling_configured(template):
    """
    Test that API Gateway stage has throttling configured.
    
    Validates rate limiting is set to prevent abuse.
    """
    template.has_resource_properties(
        "AWS::ApiGateway::Stage",
        {
            "MethodSettings": Match.array_with([
                Match.object_like({
                    "ThrottlingRateLimit": 100,
                    "ThrottlingBurstLimit": 200
                })
            ])
        }
    )


def test_lambda_role_referenced(template):
    """
    Test that Lambda function references an IAM role.
    
    The role should be referenced (not created inline) since we use
    from_role_arn in the stack.
    """
    template.has_resource_properties(
        "AWS::Lambda::Function",
        {
            "Role": Match.any_value()  # Role should be present
        }
    )
