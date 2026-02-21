# AWS Console Deployment Guide - Lambda URL Checker

This guide walks through deploying the URL Checker Lambda function using the AWS Management Console.

## Prerequisites

- AWS account with Lambda and IAM permissions
- Deployment package created (run `./package-lambda.sh`)
- `lambda-deployment-package.zip` file ready

## Step 1: Create IAM Execution Role

Lambda functions require an IAM role to execute and access AWS services.

1. Navigate to **IAM Console** → **Roles** → **Create role**

2. **Select trusted entity:**
   - Trusted entity type: **AWS service**
   - Use case: **Lambda**
   - Click **Next**

3. **Add permissions:**
   - Search for and select: **AWSLambdaBasicExecutionRole**
   - This policy grants CloudWatch Logs permissions
   - Click **Next**

4. **Name and create:**
   - Role name: `LambdaURLCheckerRole`
   - Description: `Execution role for URL Checker Lambda function`
   - Click **Create role**

5. **Note the Role ARN** (you'll need this later):
   - Format: `arn:aws:iam::123456789012:role/LambdaURLCheckerRole`

## Step 2: Create Lambda Function

1. Navigate to **Lambda Console** → **Functions** → **Create function**

2. **Basic information:**
   - Option: **Author from scratch**
   - Function name: `URLChecker`
   - Runtime: **Python 3.13**
   - Architecture: **x86_64** (default)

3. **Permissions:**
   - Execution role: **Use an existing role**
   - Existing role: Select `LambdaURLCheckerRole` (created in Step 1)

4. Click **Create function**

## Step 3: Upload Deployment Package

1. In the function configuration page, scroll to **Code source** section

2. Click **Upload from** → **.zip file**

3. Click **Upload** and select `lambda-deployment-package.zip`

4. Click **Save**

5. Wait for upload to complete (you'll see a success message)

## Step 4: Configure Function Settings

1. Navigate to **Configuration** tab → **General configuration** → **Edit**

2. Update settings:
   - **Timeout:** 10 seconds (default 3 seconds is too short for network requests)
   - **Memory:** 128 MB (sufficient for this function)
   - **Description:** URL health checker function

3. Click **Save**

## Step 5: Test the Function

### Test 1: Valid URL

1. Navigate to **Test** tab

2. Click **Create new test event**

3. Configure test event:
   - Event name: `TestValidURL`
   - Event JSON:
   ```json
   {
     "url": "https://aws.amazon.com"
   }
   ```

4. Click **Save**

5. Click **Test** button

6. **Expected result:**
   - Execution result: **succeeded**
   - Response:
   ```json
   {
     "statusCode": 200,
     "body": {
       "url": "https://aws.amazon.com",
       "status": "success",
       "http_status": 200,
       "message": "URL is reachable"
     }
   }
   ```

### Test 2: Invalid URL

1. Create another test event:
   - Event name: `TestInvalidURL`
   - Event JSON:
   ```json
   {
     "url": "https://invalid-domain-that-does-not-exist-12345.com"
   }
   ```

2. Click **Test**

3. **Expected result:**
   - Execution result: **succeeded** (function handled error gracefully)
   - Response:
   ```json
   {
     "statusCode": 500,
     "body": {
       "url": "https://invalid-domain-that-does-not-exist-12345.com",
       "status": "error",
       "message": "Connection error: [error details]"
     }
   }
   ```

### Test 3: Missing URL Parameter

1. Create test event:
   - Event name: `TestMissingURL`
   - Event JSON:
   ```json
   {}
   ```

2. Click **Test**

3. **Expected result:**
   - Response:
   ```json
   {
     "statusCode": 400,
     "body": "{\"status\": \"error\", \"message\": \"Missing required parameter: url\"}"
   }
   ```

## Step 6: View CloudWatch Logs

1. Navigate to **Monitor** tab in Lambda function

2. Click **View CloudWatch logs**

3. Click on the most recent **log stream**

4. **Observe log entries:**
   - Function start and end
   - Custom print statements from code
   - Execution duration and memory usage
   - Billing information

**Example log output:**
```
START RequestId: abc123-def456-ghi789 Version: $LATEST
Checking URL: https://aws.amazon.com
Success: https://aws.amazon.com returned status 200
END RequestId: abc123-def456-ghi789
REPORT RequestId: abc123-def456-ghi789
Duration: 245.67 ms
Billed Duration: 246 ms
Memory Size: 128 MB
Max Memory Used: 45 MB
```

## Step 7: Invoke Function via AWS CLI (Optional)

If you have AWS CLI configured:

```bash
# Invoke function
aws lambda invoke \
  --function-name URLChecker \
  --payload '{"url":"https://aws.amazon.com"}' \
  response.json

# View response
cat response.json
```

## Verification Checklist

- [ ] IAM execution role created with CloudWatch Logs permissions
- [ ] Lambda function created with Python 3.13 runtime
- [ ] Deployment package uploaded successfully
- [ ] Function timeout set to 10 seconds
- [ ] Test with valid URL returns status 200
- [ ] Test with invalid URL returns error response
- [ ] Test with missing URL parameter returns 400 error
- [ ] CloudWatch logs show execution details

## Troubleshooting

### Issue: "Unable to import module 'app'"

**Cause:** Deployment package structure is incorrect

**Solution:**
- Ensure `app.py` is at the root of the ZIP file
- Recreate package using `package-lambda.sh` script
- Verify ZIP contents: `unzip -l lambda-deployment-package.zip`

### Issue: "No module named 'requests'"

**Cause:** Dependencies not included in deployment package

**Solution:**
- Run `package-lambda.sh` to bundle dependencies
- Verify `requests` library is in ZIP: `unzip -l lambda-deployment-package.zip | grep requests`

### Issue: Function times out after 3 seconds

**Cause:** Default timeout is too short

**Solution:**
- Go to Configuration → General configuration → Edit
- Increase timeout to 10 seconds
- Save changes

### Issue: "Access Denied" when creating function

**Cause:** IAM user lacks Lambda permissions

**Solution:**
- Attach `AWSLambdaFullAccess` policy to your IAM user
- Or request permissions from AWS administrator

### Issue: CloudWatch logs not appearing

**Cause:** Execution role lacks CloudWatch permissions

**Solution:**
- Verify `AWSLambdaBasicExecutionRole` is attached to execution role
- Check IAM role trust policy allows Lambda service

## Next Steps

- Add scheduled execution using Amazon EventBridge
- Store results in DynamoDB for historical tracking
- Send SNS notifications for failed URL checks
- Create API Gateway endpoint for HTTP invocation
- Implement retry logic with exponential backoff

## Cost Considerations

**Lambda Pricing (as of 2024):**
- **Requests:** $0.20 per 1 million requests
- **Duration:** $0.0000166667 per GB-second

**Example calculation for this function:**
- Memory: 128 MB (0.125 GB)
- Duration: ~250 ms (0.25 seconds)
- Cost per invocation: 0.125 GB × 0.25 s × $0.0000166667 = $0.00000052

**Monthly cost for 10,000 invocations:**
- Requests: 10,000 × $0.20 / 1,000,000 = $0.002
- Duration: 10,000 × $0.00000052 = $0.0052
- **Total: ~$0.0072 per month**

**Free Tier:**
- 1 million requests per month
- 400,000 GB-seconds of compute time per month
- This function easily fits within free tier limits!

## Security Best Practices

1. **Least Privilege:** Only grant necessary permissions to execution role
2. **Environment Variables:** Store sensitive data (API keys) in encrypted environment variables
3. **VPC Configuration:** If checking internal URLs, deploy Lambda in VPC
4. **Resource Policies:** Restrict who can invoke the function
5. **Monitoring:** Set up CloudWatch alarms for errors and throttling

## Deployment Complete!

You've successfully deployed a serverless URL checker using AWS Lambda. The function demonstrates key serverless concepts including event-driven execution, automatic scaling, and pay-per-use pricing.
