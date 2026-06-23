#!/bin/bash

# Create Forensic Isolation Security Group
# This security group blocks all inbound and outbound traffic

set -e

VPC_ID="${1:-vpc-12345}"  # Pass VPC ID as argument
REGION="us-east-1"

echo "Creating forensic isolation security group..."
echo "VPC: $VPC_ID"

# Create security group
SG_ID=$(aws ec2 create-security-group \
  --group-name forensic-isolation-sg \
  --description "Forensic isolation - blocks all traffic" \
  --vpc-id "$VPC_ID" \
  --region "$REGION" \
  --query 'GroupId' \
  --output text)

echo "Security group created: $SG_ID"

# Remove default egress rule (allows all outbound)
aws ec2 revoke-security-group-egress \
  --group-id "$SG_ID" \
  --ip-permissions '[{"IpProtocol": "-1", "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]' \
  --region "$REGION"

echo "Default egress rule removed"

# Tag security group
aws ec2 create-tags \
  --resources "$SG_ID" \
  --tags \
    Key=Name,Value=forensic-isolation-sg \
    Key=Purpose,Value=IncidentResponse \
    Key=Description,Value="Blocks all traffic for forensic isolation" \
  --region "$REGION"

echo ""
echo "Forensic isolation security group created successfully!"
echo "Security Group ID: $SG_ID"
echo ""
echo "Rules:"
echo "  Inbound: NONE (all traffic blocked)"
echo "  Outbound: NONE (all traffic blocked)"
echo ""
echo "Save this security group ID for Lambda configuration:"
echo "$SG_ID" > isolation-sg-id.txt
echo "Saved to isolation-sg-id.txt"
