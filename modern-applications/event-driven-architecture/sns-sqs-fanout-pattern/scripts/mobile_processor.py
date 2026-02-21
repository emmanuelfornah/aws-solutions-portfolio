"""
Mobile Image Processor Lambda Function
Resizes images to 800px width for mobile devices
"""

import json
import boto3
import os
from PIL import Image
from io import BytesIO

# Initialize AWS clients
s3 = boto3.client('s3')

# Environment variables
DESTINATION_BUCKET = os.environ.get('DESTINATION_BUCKET', 'image-processing-mobile-ACCOUNT_ID')
MAX_WIDTH = 800

def lambda_handler(event, context):
    """
    Process SQS messages containing S3 image upload notifications
    Resize images for mobile display and save to destination bucket
    
    Args:
        event: SQS event with SNS message containing S3 notification
        context: Lambda context object
        
    Returns:
        Processing results
    """
    
    processed_count = 0
    failed_count = 0
    
    # Process each SQS record
    for record in event['Records']:
        try:
            # Parse SNS message from SQS
            sns_message = json.loads(record['body'])
            s3_event = json.loads(sns_message['Message'])
            
            # Extract S3 bucket and key from event
            for s3_record in s3_event['Records']:
                source_bucket = s3_record['s3']['bucket']['name']
                source_key = s3_record['s3']['object']['key']
                
                print(f"Processing mobile image for: s3://{source_bucket}/{source_key}")
                
                # Download image from S3
                response = s3.get_object(Bucket=source_bucket, Key=source_key)
                image_data = response['Body'].read()
                
                # Open image with Pillow
                image = Image.open(BytesIO(image_data))
                
                # Convert RGBA to RGB if necessary
                if image.mode in ('RGBA', 'LA', 'P'):
                    background = Image.new('RGB', image.size, (255, 255, 255))
                    if image.mode == 'P':
                        image = image.convert('RGBA')
                    background.paste(image, mask=image.split()[-1] if image.mode == 'RGBA' else None)
                    image = background
                
                # Resize if width exceeds MAX_WIDTH
                if image.width > MAX_WIDTH:
                    ratio = MAX_WIDTH / image.width
                    new_height = int(image.height * ratio)
                    image = image.resize((MAX_WIDTH, new_height), Image.Resampling.LANCZOS)
                    print(f"Resized to: {MAX_WIDTH}x{new_height}")
                else:
                    print(f"Image already optimal: {image.width}x{image.height}")
                
                # Save to BytesIO buffer with higher compression for mobile
                buffer = BytesIO()
                image.save(buffer, format='JPEG', quality=80, optimize=True)
                buffer.seek(0)
                
                # Generate destination key
                filename = os.path.basename(source_key)
                name, ext = os.path.splitext(filename)
                destination_key = f"mobile/{name}_mobile.jpg"
                
                # Upload mobile image to destination bucket
                s3.put_object(
                    Bucket=DESTINATION_BUCKET,
                    Key=destination_key,
                    Body=buffer,
                    ContentType='image/jpeg',
                    Metadata={
                        'source-bucket': source_bucket,
                        'source-key': source_key,
                        'processor': 'mobile',
                        'max-width': str(MAX_WIDTH)
                    }
                )
                
                print(f"Mobile image saved: s3://{DESTINATION_BUCKET}/{destination_key}")
                processed_count += 1
                
        except Exception as e:
            print(f"Error processing record: {str(e)}")
            failed_count += 1
            # Re-raise exception to trigger SQS retry
            raise
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'processed': processed_count,
            'failed': failed_count
        })
    }
