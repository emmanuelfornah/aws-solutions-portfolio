#!/bin/bash
# AWS CLI Commands for Route 53 DNS Configuration
# This file contains reference commands for managing Route 53 private hosted zones

# Note: Replace placeholder values with your actual AWS resource IDs
# VPC_ID: Your VPC ID (e.g., vpc-0123456789abcdef0)
# HOSTED_ZONE_ID: Your hosted zone ID (e.g., Z1234567890ABC)
# ELASTIC_IP: Instance A's Elastic IP address
# REGION: Your AWS region (e.g., us-east-1)

# ============================================
# 1. VPC DNS Configuration
# ============================================

# Check if VPC has DNS support enabled
aws ec2 describe-vpc-attribute \
  --vpc-id <VPC_ID> \
  --attribute enableDnsSupport \
  --region <REGION>

# Check if VPC has DNS hostnames enabled
aws ec2 describe-vpc-attribute \
  --vpc-id <VPC_ID> \
  --attribute enableDnsHostnames \
  --region <REGION>

# Enable DNS support (required for Route 53 private hosted zones)
aws ec2 modify-vpc-attribute \
  --vpc-id <VPC_ID> \
  --enable-dns-support \
  --region <REGION>

# Enable DNS hostnames (recommended)
aws ec2 modify-vpc-attribute \
  --vpc-id <VPC_ID> \
  --enable-dns-hostnames \
  --region <REGION>

# ============================================
# 2. Create Private Hosted Zone
# ============================================

# Create private hosted zone for anycompany.corp
aws route53 create-hosted-zone \
  --name anycompany.corp \
  --vpc VPCRegion=<REGION>,VPCId=<VPC_ID> \
  --caller-reference "anycompany-$(date +%s)" \
  --hosted-zone-config Comment="Private DNS for AnyCompany VPC",PrivateZone=true

# Alternative: Create using JSON config file
aws route53 create-hosted-zone \
  --cli-input-json file://configs/hosted-zone-config.json

# ============================================
# 3. List Hosted Zones
# ============================================

# List all hosted zones
aws route53 list-hosted-zones

# List hosted zones by VPC
aws route53 list-hosted-zones-by-vpc \
  --vpc-id <VPC_ID> \
  --vpc-region <REGION>

# Get specific hosted zone details
aws route53 get-hosted-zone \
  --id <HOSTED_ZONE_ID>

# ============================================
# 4. Create A Record
# ============================================

# Create A record for www.anycompany.corp
aws route53 change-resource-record-sets \
  --hosted-zone-id <HOSTED_ZONE_ID> \
  --change-batch '{
    "Comment": "Create A record for www.anycompany.corp",
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "www.anycompany.corp",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [
            {
              "Value": "<ELASTIC_IP>"
            }
          ]
        }
      }
    ]
  }'

# Alternative: Create using JSON config file
# (Update the Elastic IP in configs/a-record-config.json first)
aws route53 change-resource-record-sets \
  --hosted-zone-id <HOSTED_ZONE_ID> \
  --change-batch file://configs/a-record-config.json

# ============================================
# 5. List and Manage Records
# ============================================

# List all records in hosted zone
aws route53 list-resource-record-sets \
  --hosted-zone-id <HOSTED_ZONE_ID>

# List specific record type
aws route53 list-resource-record-sets \
  --hosted-zone-id <HOSTED_ZONE_ID> \
  --query "ResourceRecordSets[?Type=='A']"

# Get specific record
aws route53 list-resource-record-sets \
  --hosted-zone-id <HOSTED_ZONE_ID> \
  --query "ResourceRecordSets[?Name=='www.anycompany.corp.']"

# ============================================
# 6. Update A Record
# ============================================

# Update A record with new IP address
aws route53 change-resource-record-sets \
  --hosted-zone-id <HOSTED_ZONE_ID> \
  --change-batch '{
    "Comment": "Update A record IP address",
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "www.anycompany.corp",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [
            {
              "Value": "<NEW_ELASTIC_IP>"
            }
          ]
        }
      }
    ]
  }'

# ============================================
# 7. Delete A Record
# ============================================

# Delete A record (must match existing record exactly)
aws route53 change-resource-record-sets \
  --hosted-zone-id <HOSTED_ZONE_ID> \
  --change-batch '{
    "Comment": "Delete A record",
    "Changes": [
      {
        "Action": "DELETE",
        "ResourceRecordSet": {
          "Name": "www.anycompany.corp",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [
            {
              "Value": "<ELASTIC_IP>"
            }
          ]
        }
      }
    ]
  }'

# ============================================
# 8. Associate Additional VPCs
# ============================================

# Associate hosted zone with another VPC
aws route53 associate-vpc-with-hosted-zone \
  --hosted-zone-id <HOSTED_ZONE_ID> \
  --vpc VPCRegion=<REGION>,VPCId=<ANOTHER_VPC_ID>

# Disassociate VPC from hosted zone
aws route53 disassociate-vpc-from-hosted-zone \
  --hosted-zone-id <HOSTED_ZONE_ID> \
  --vpc VPCRegion=<REGION>,VPCId=<VPC_ID>

# ============================================
# 9. Query Logging Configuration
# ============================================

# Create query logging configuration
aws route53 create-query-logging-config \
  --hosted-zone-id <HOSTED_ZONE_ID> \
  --cloud-watch-logs-log-group-arn arn:aws:logs:<REGION>:<ACCOUNT_ID>:log-group:/aws/route53/anycompany.corp

# List query logging configurations
aws route53 list-query-logging-configs \
  --hosted-zone-id <HOSTED_ZONE_ID>

# Delete query logging configuration
aws route53 delete-query-logging-config \
  --id <QUERY_LOGGING_CONFIG_ID>

# ============================================
# 10. Elastic IP Management
# ============================================

# Allocate Elastic IP
aws ec2 allocate-address \
  --domain vpc \
  --region <REGION>

# Associate Elastic IP with instance
aws ec2 associate-address \
  --instance-id <INSTANCE_ID> \
  --allocation-id <ALLOCATION_ID> \
  --region <REGION>

# Describe Elastic IPs
aws ec2 describe-addresses \
  --region <REGION>

# Disassociate Elastic IP
aws ec2 disassociate-address \
  --association-id <ASSOCIATION_ID> \
  --region <REGION>

# Release Elastic IP
aws ec2 release-address \
  --allocation-id <ALLOCATION_ID> \
  --region <REGION>

# ============================================
# 11. Health Checks (Optional)
# ============================================

# Create health check for Instance A
aws route53 create-health-check \
  --health-check-config '{
    "Type": "HTTP",
    "ResourcePath": "/",
    "FullyQualifiedDomainName": "<ELASTIC_IP>",
    "Port": 80,
    "RequestInterval": 30,
    "FailureThreshold": 3
  }' \
  --caller-reference "instance-a-health-$(date +%s)"

# List health checks
aws route53 list-health-checks

# Get health check status
aws route53 get-health-check-status \
  --health-check-id <HEALTH_CHECK_ID>

# Delete health check
aws route53 delete-health-check \
  --health-check-id <HEALTH_CHECK_ID>

# ============================================
# 12. Cleanup
# ============================================

# Delete all records except NS and SOA
# (Must delete all custom records before deleting hosted zone)
aws route53 list-resource-record-sets \
  --hosted-zone-id <HOSTED_ZONE_ID> \
  --query "ResourceRecordSets[?Type!='NS' && Type!='SOA']" \
  --output json > records-to-delete.json

# Delete hosted zone (only works if all custom records are deleted)
aws route53 delete-hosted-zone \
  --id <HOSTED_ZONE_ID>

# ============================================
# 13. Monitoring and Troubleshooting
# ============================================

# Get change status (after creating/updating records)
aws route53 get-change \
  --id <CHANGE_ID>

# List tags for hosted zone
aws route53 list-tags-for-resource \
  --resource-type hostedzone \
  --resource-id <HOSTED_ZONE_ID>

# Add tags to hosted zone
aws route53 change-tags-for-resource \
  --resource-type hostedzone \
  --resource-id <HOSTED_ZONE_ID> \
  --add-tags Key=Environment,Value=Lab Key=Project,Value=Route53DNS

# ============================================
# 14. Batch Operations
# ============================================

# Create multiple records at once
aws route53 change-resource-record-sets \
  --hosted-zone-id <HOSTED_ZONE_ID> \
  --change-batch '{
    "Comment": "Create multiple records",
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "www.anycompany.corp",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [{"Value": "<ELASTIC_IP>"}]
        }
      },
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "api.anycompany.corp",
          "Type": "CNAME",
          "TTL": 300,
          "ResourceRecords": [{"Value": "www.anycompany.corp"}]
        }
      }
    ]
  }'

# ============================================
# Notes
# ============================================

# 1. Private hosted zones only resolve within associated VPCs
# 2. DNS changes typically propagate within 60 seconds
# 3. TTL affects how long records are cached (default: 300 seconds)
# 4. Always use UPSERT instead of CREATE for idempotent operations
# 5. Hosted zone IDs start with 'Z' (e.g., Z1234567890ABC)
# 6. Record names must end with a dot in API responses (e.g., www.anycompany.corp.)
# 7. Elastic IPs are free when associated with running instances
# 8. Query logging incurs CloudWatch Logs charges
# 9. Health checks cost $0.50/month per check
# 10. Private hosted zones cost $0.50/month per zone

# ============================================
# Quick Reference
# ============================================

# Create hosted zone:
#   aws route53 create-hosted-zone --name <domain> --vpc VPCRegion=<region>,VPCId=<vpc-id> --caller-reference <unique-string>

# Create A record:
#   aws route53 change-resource-record-sets --hosted-zone-id <zone-id> --change-batch <json>

# List records:
#   aws route53 list-resource-record-sets --hosted-zone-id <zone-id>

# Delete hosted zone:
#   aws route53 delete-hosted-zone --id <zone-id>
