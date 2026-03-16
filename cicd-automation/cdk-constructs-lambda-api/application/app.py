#!/usr/bin/env python3
"""
AWS CDK Application Entry Point

This file serves as the entry point for the CDK application.
It instantiates the CDK app and creates the Lambda API stack.
"""

import os
import aws_cdk as cdk
from lambda_api.lambda_api_stack import LambdaApiStack


# Create CDK app instance
app = cdk.App()

# Instantiate the Lambda API stack
LambdaApiStack(
    app,
    "LambdaApiStack",
    # Uncomment to specify environment (account and region)
    # env=cdk.Environment(
    #     account=os.getenv('CDK_DEFAULT_ACCOUNT'),
    #     region=os.getenv('CDK_DEFAULT_REGION')
    # ),
    description="Lambda-backed API endpoint using AWS CDK constructs"
)

# Synthesize CloudFormation template
app.synth()
