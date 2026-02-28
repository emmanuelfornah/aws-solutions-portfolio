"""
Lambda API Stack Definition

This module defines the CDK stack that creates a Lambda function
with an API Gateway endpoint for HTTP access.
"""

from aws_cdk import (
    Stack,
    aws_lambda as _lambda,
    aws_iam as iam,
    aws_apigateway as apigateway,
    CfnOutput,
)
from constructs import Construct
import os


class LambdaApiStack(Stack):
    """
    CDK Stack that creates a Lambda-backed API endpoint.
    
    This stack demonstrates:
    - Referencing existing IAM roles with from_role_arn
    - Creating Lambda functions with CDK constructs
    - Adding API Gateway endpoints with LambdaRestApi
    - Exporting stack outputs for easy access
    """

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Reference pre-created IAM role for Lambda execution
        # In production, you might create the role inline or use a custom construct
        lambda_role = iam.Role.from_role_arn(
            self,
            'HelloLambdaRole',
            role_arn=f'arn:aws:iam::{self.account}:role/HelloLambdaRole'
        )

        # Create Lambda function using L2 construct
        # This provides sensible defaults and best practices
        hello_function = _lambda.Function(
            self,
            'HelloFunction',
            runtime=_lambda.Runtime.PYTHON_3_13,
            handler='hello.handler',
            code=_lambda.Code.from_asset('.'),
            role=lambda_role,
            description='Lambda function that returns greeting messages',
            function_name='HelloFunction'
        )

        # Create API Gateway REST API with Lambda proxy integration
        # LambdaRestApi is an L3 construct that creates:
        # - RestApi resource
        # - Deployment
        # - Stage (prod)
        # - Lambda permission for API Gateway invocation
        api = apigateway.LambdaRestApi(
            self,
            'HelloApi',
            handler=hello_function,
            proxy=True,
            description='Lambda-backed API endpoint',
            deploy_options=apigateway.StageOptions(
                stage_name='prod',
                throttling_rate_limit=100,
                throttling_burst_limit=200
            )
        )

        # Output the API Gateway URL for easy access
        CfnOutput(
            self,
            'ApiUrl',
            value=api.url,
            description='API Gateway endpoint URL',
            export_name=f'{self.stack_name}-ApiUrl'
        )

        # Output the Lambda function name
        CfnOutput(
            self,
            'FunctionName',
            value=hello_function.function_name,
            description='Lambda function name',
            export_name=f'{self.stack_name}-FunctionName'
        )

        # Output the Lambda function ARN
        CfnOutput(
            self,
            'FunctionArn',
            value=hello_function.function_arn,
            description='Lambda function ARN'
        )
