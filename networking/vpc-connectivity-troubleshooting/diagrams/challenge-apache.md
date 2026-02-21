# Challenge Diagram - Apache Server Troubleshooting

## Challenge Overview

An Apache web server is running in the public subnet, but you cannot access it via `http://<PublicIPaddress>`. Your task is to diagnose and fix the connectivity issue.

## Initial State - Apache Server Not Accessible

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                  Internet                                    │
│                                                                              │
│                          ┌──────────────────┐                               │
│                          │  Web Browser     │                               │
│                          │  User's Computer │                               │
│                          └────────┬─────────┘                               │
│                                   │                                          │
│                                   │ HTTP (port 80)                           │
│                                   │ ❌ Connection Timeout                    │
└───────────────────────────────────┼──────────────────────────────────────────┘
                                    │
                       ┌────────────┴────────────┐
                       │   Internet Gateway      │
                       └────────────┬────────────┘
                                    │
┌───────────────────────────────────┼──────────────────────────────────────────┐
│                             VPC A (10.0.0.0/16)                              │
│                                   │                                          │
│  ┌────────────────────────────────┼───────────────────────────────────────┐ │
│  │         Public Subnet (10.0.10.0/24)                                    │ │
│  │                                │                                        │ │
│  │                                ▼                                        │ │
│  │  ┌──────────────────────────────────────────────────────────────────┐  │ │
│  │  │   Apache Server                                                  │  │ │
│  │  │   10.0.10.100                                                    │  │ │
│  │  │   Public IP: 54.123.45.67                                        │  │ │
│  │  │                                                                  │  │ │
│  │  │   Apache Status: ✅ Running                                      │  │ │
│  │  │   Port 80: ✅ Listening                                          │  │ │
│  │  │                                                                  │  │ │
│  │  │   Security Groups:                                               │  │ │
│  │  │   - ApacheServerSG ❌ MISSING HTTP RULE!                         │  │ │
│  │  │                                                                  │  │ │
│  │  │   ┌────────────────────────────────────────────────────────┐    │  │ │
│  │  │   │ ApacheServerSG Inbound Rules:                          │    │  │ │
│  │  │   │                                                        │    │  │ │
│  │  │   │ • SSH (22) from 0.0.0.0/0 ✅                           │    │  │ │
│  │  │   │ • HTTP (80) from 0.0.0.0/0 ❌ MISSING!                 │    │  │ │
│  │  │   │                                                        │    │  │ │
│  │  │   │ Result: HTTP traffic blocked by security group        │    │  │ │
│  │  │   └────────────────────────────────────────────────────────┘    │  │ │
│  │  └──────────────────────────────────────────────────────────────────┘  │ │
│  │                                                                        │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Troubleshooting Process

### Step 1: Identify the Problem

**Symptom:**
```
Browser: http://54.123.45.67
Result: Connection timed out or "This site can't be reached"
```

**Initial Observations:**
- Apache Server has a public IP address ✅
- Server is in a public subnet ✅
- Internet Gateway is attached ✅
- But HTTP traffic is not reaching the server ❌

### Step 2: Check Apache Service

Connect via Session Manager and verify Apache is running:

```bash
# Connect to Apache Server via Session Manager
# (Session Manager doesn't require SSH security group rules)

# Check Apache status
sudo systemctl status httpd

# Expected output:
● httpd.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled)
   Active: active (running) since ...
   
# Test locally
curl localhost

# Expected output:
<html>
  <head><title>Apache Test Page</title></head>
  <body>It works!</body>
</html>
```

**Conclusion:** Apache is running correctly ✅

### Step 3: Check Security Group Rules

Navigate to EC2 Console → Security Groups → ApacheServerSG

**Current Inbound Rules:**
```
┌──────────┬──────────┬──────┬─────────────┬──────────────────────────────┐
│ Type     │ Protocol │ Port │ Source      │ Description                  │
├──────────┼──────────┼──────┼─────────────┼──────────────────────────────┤
│ SSH      │ TCP      │ 22   │ 0.0.0.0/0   │ SSH from internet            │
└──────────┴──────────┴──────┴─────────────┴──────────────────────────────┘

❌ NO HTTP RULE FOUND!
```

**Root Cause Identified:** Security group is blocking HTTP traffic on port 80!

### Step 4: Add HTTP Rule

**Solution:** Add an inbound rule to allow HTTP traffic from the internet.

```
Required Rule:
  Type: HTTP
  Protocol: TCP
  Port: 80
  Source: 0.0.0.0/0
  Description: Allow HTTP from internet
```

## After Fix - Apache Server Accessible

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                  Internet                                    │
│                                                                              │
│                          ┌──────────────────┐                               │
│                          │  Web Browser     │                               │
│                          │  User's Computer │                               │
│                          └────────┬─────────┘                               │
│                                   │                                          │
│                                   │ HTTP (port 80)                           │
│                                   │ ✅ Connection Success!                   │
└───────────────────────────────────┼──────────────────────────────────────────┘
                                    │
                       ┌────────────┴────────────┐
                       │   Internet Gateway      │
                       └────────────┬────────────┘
                                    │
┌───────────────────────────────────┼──────────────────────────────────────────┐
│                             VPC A (10.0.0.0/16)                              │
│                                   │                                          │
│  ┌────────────────────────────────┼───────────────────────────────────────┐ │
│  │         Public Subnet (10.0.10.0/24)                                    │ │
│  │                                │                                        │ │
│  │                                ▼                                        │ │
│  │  ┌──────────────────────────────────────────────────────────────────┐  │ │
│  │  │   Apache Server                                                  │  │ │
│  │  │   10.0.10.100                                                    │  │ │
│  │  │   Public IP: 54.123.45.67                                        │  │ │
│  │  │                                                                  │  │ │
│  │  │   Apache Status: ✅ Running                                      │  │ │
│  │  │   Port 80: ✅ Listening                                          │  │ │
│  │  │                                                                  │  │ │
│  │  │   Security Groups:                                               │  │ │
│  │  │   - ApacheServerSG ✅ HTTP RULE ADDED!                           │  │ │
│  │  │                                                                  │  │ │
│  │  │   ┌────────────────────────────────────────────────────────┐    │  │ │
│  │  │   │ ApacheServerSG Inbound Rules (UPDATED):                │    │  │ │
│  │  │   │                                                        │    │  │ │
│  │  │   │ • SSH (22) from 0.0.0.0/0 ✅                           │    │  │ │
│  │  │   │ • HTTP (80) from 0.0.0.0/0 ✅ ADDED!                   │    │  │ │
│  │  │   │                                                        │    │  │ │
│  │  │   │ Result: HTTP traffic now allowed!                     │    │  │ │
│  │  │   └────────────────────────────────────────────────────────┘    │  │ │
│  │  └──────────────────────────────────────────────────────────────────┘  │ │
│  │                                                                        │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Traffic Flow - After Fix

```
Internet Browser (203.0.113.50)
         │
         │ HTTP Request
         │ GET / HTTP/1.1
         │ Destination: 54.123.45.67:80
         │
         ▼
Internet Gateway
         │
         │ Routes to Apache Server
         │
         ▼
Apache Server (10.0.10.100 / 54.123.45.67)
         │
         └─ ApacheServerSG checks:
            Rule 1: SSH from 0.0.0.0/0 (port 22) - No match
            Rule 2: HTTP from 0.0.0.0/0 (port 80) - ✅ MATCH!
         └─ Connection ALLOWED ✅
         │
         ▼
Apache HTTP Server (httpd)
         │
         │ Processes request
         │ Returns Apache Test Page
         │
         ▼
Response sent back to browser
         │
         ▼
Browser displays: "It works!"
```

## Security Group Configuration

### ApacheServerSG - Before Fix

```
┌──────────┬──────────┬──────┬─────────────┬──────────────────────────────┐
│ Type     │ Protocol │ Port │ Source      │ Description                  │
├──────────┼──────────┼──────┼─────────────┼──────────────────────────────┤
│ SSH      │ TCP      │ 22   │ 0.0.0.0/0   │ SSH from internet            │
└──────────┴──────────┴──────┴─────────────┴──────────────────────────────┘
```

### ApacheServerSG - After Fix

```
┌──────────┬──────────┬──────┬─────────────┬──────────────────────────────┐
│ Type     │ Protocol │ Port │ Source      │ Description                  │
├──────────┼──────────┼──────┼─────────────┼──────────────────────────────┤
│ SSH      │ TCP      │ 22   │ 0.0.0.0/0   │ SSH from internet            │
├──────────┼──────────┼──────┼─────────────┼──────────────────────────────┤
│ HTTP     │ TCP      │ 80   │ 0.0.0.0/0   │ ✅ Allow HTTP from internet  │
└──────────┴──────────┴──────┴─────────────┴──────────────────────────────┘
```

## AWS CLI Commands

### Diagnose the Issue

```bash
# Get Apache Server details
APACHE_INSTANCE=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=Apache Server" \
  --query "Reservations[0].Instances[0].[InstanceId,PublicIpAddress,SecurityGroups[0].GroupId]" \
  --output text)

echo "Instance ID: $(echo $APACHE_INSTANCE | awk '{print $1}')"
echo "Public IP: $(echo $APACHE_INSTANCE | awk '{print $2}')"
echo "Security Group: $(echo $APACHE_INSTANCE | awk '{print $3}')"

# Get security group rules
APACHE_SG=$(echo $APACHE_INSTANCE | awk '{print $3}')

aws ec2 describe-security-groups \
  --group-ids $APACHE_SG \
  --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp]" \
  --output table

# Look for HTTP (port 80) rule - if missing, that's the problem!
```

### Apply the Fix

```bash
# Get the security group ID
APACHE_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=ApacheServerSG" \
  --query "SecurityGroups[0].GroupId" \
  --output text)

# Add HTTP inbound rule
aws ec2 authorize-security-group-ingress \
  --group-id $APACHE_SG \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --description "Allow HTTP from internet"

# Verify the rule was added
aws ec2 describe-security-groups \
  --group-ids $APACHE_SG \
  --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp]" \
  --output table
```

### Verify the Fix

```bash
# Get Apache Server public IP
APACHE_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=Apache Server" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

# Test HTTP connectivity
curl http://$APACHE_IP

# Expected output:
# <html>
#   <head><title>Apache Test Page</title></head>
#   <body>It works!</body>
# </html>
```

## Common Web Server Connectivity Issues

### Issue 1: Missing HTTP/HTTPS Rule

**Symptom:** Connection timeout when accessing web server  
**Cause:** Security group missing HTTP (80) or HTTPS (443) rule  
**Solution:** Add appropriate inbound rule for port 80 or 443

### Issue 2: Wrong Protocol

**Symptom:** Connection refused or SSL error  
**Cause:** Using https:// when server only supports http:// (or vice versa)  
**Solution:** Use correct protocol in browser

### Issue 3: Web Server Not Running

**Symptom:** Connection refused (not timeout)  
**Cause:** Apache/Nginx not running  
**Solution:** Start web server: `sudo systemctl start httpd`

### Issue 4: No Public IP

**Symptom:** Cannot access from internet  
**Cause:** Instance has no public IP address  
**Solution:** Assign Elastic IP or enable auto-assign public IP

### Issue 5: Wrong Subnet

**Symptom:** Cannot access from internet  
**Cause:** Instance in private subnet without load balancer  
**Solution:** Move to public subnet or add load balancer

## Troubleshooting Checklist

When web server is not accessible:

- [ ] Instance has public IP address
- [ ] Instance is in public subnet
- [ ] Subnet route table has route to Internet Gateway
- [ ] Security group has HTTP (80) or HTTPS (443) inbound rule
- [ ] Security group source is 0.0.0.0/0 (for public access)
- [ ] Web server service is running (httpd, nginx, etc.)
- [ ] Web server is listening on correct port
- [ ] Network ACLs allow traffic (if configured)
- [ ] Using correct protocol (http vs https)
- [ ] No firewall on instance blocking traffic

## Verification Steps

After adding the HTTP rule:

1. **Check Security Group:**
   ```bash
   aws ec2 describe-security-groups --group-ids $APACHE_SG
   ```
   Verify HTTP rule exists

2. **Test from Command Line:**
   ```bash
   curl http://<ApacheServerPublicIP>
   ```
   Should return HTML content

3. **Test from Browser:**
   ```
   http://<ApacheServerPublicIP>
   ```
   Should display Apache Test Page

4. **Check Apache Logs:**
   ```bash
   sudo tail -f /var/log/httpd/access_log
   ```
   Should show incoming requests

## Security Considerations

### Public Web Server Best Practices

**Good for Public Web Servers:**
```
Inbound Rules:
  • HTTP (80) from 0.0.0.0/0 ✅
  • HTTPS (443) from 0.0.0.0/0 ✅
  • SSH (22) from BastionHostSG ✅ (not 0.0.0.0/0)
```

**Avoid:**
```
Inbound Rules:
  • SSH (22) from 0.0.0.0/0 ❌ (use bastion host instead)
  • All traffic from 0.0.0.0/0 ❌ (too permissive)
  • Database ports from 0.0.0.0/0 ❌ (never expose databases)
```

### HTTPS Considerations

For production web servers:
- Always use HTTPS (port 443) instead of HTTP (port 80)
- Redirect HTTP to HTTPS
- Use valid SSL/TLS certificates (AWS Certificate Manager)
- Enable HTTP Strict Transport Security (HSTS)

**HTTPS Security Group:**
```
Inbound Rules:
  • HTTP (80) from 0.0.0.0/0 (redirect to HTTPS)
  • HTTPS (443) from 0.0.0.0/0
  • SSH (22) from BastionHostSG
```

## Challenge Complete!

**Problem:** Apache Server not accessible via HTTP  
**Root Cause:** Missing HTTP inbound rule in ApacheServerSG  
**Solution:** Added HTTP (port 80) rule from 0.0.0.0/0  
**Result:** ✅ Apache Test Page now accessible!

## Key Learnings

1. **Security groups block all inbound traffic by default**
2. **Web servers need explicit HTTP/HTTPS rules**
3. **Connection timeout usually indicates security group issue**
4. **Connection refused usually indicates service not running**
5. **Always verify security group rules when troubleshooting connectivity**
6. **Use Session Manager for troubleshooting without SSH access**
7. **Test locally first (curl localhost) to isolate network vs application issues**

## Related Challenges

Try these additional scenarios:
- Add HTTPS (port 443) support with SSL certificate
- Restrict SSH to bastion host only
- Add CloudFront distribution in front of Apache
- Configure Application Load Balancer
- Implement Web Application Firewall (WAF)

Congratulations on completing the VPC connectivity troubleshooting lab!
