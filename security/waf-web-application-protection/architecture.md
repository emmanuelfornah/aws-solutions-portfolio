# Architecture: AWS WAF Web Application Protection

## Architecture Diagram

                          Internet Traffic
                                 │
                                 │ HTTP/HTTPS Requests
                                 ▼
                    ┌────────────────────────────┐
                    │       AWS WAF              │
                    │     (Web ACL)              │
                    │                            │
                    │  ┌──────────────────────┐ │
                    │  │  Rule Evaluation     │ │
                    │  │  (Priority Order)    │ │
                    │  └──────────────────────┘ │
                    │            │               │
                    │            ▼               │
                    │  ┌──────────────────────┐ │
                    │  │ 1. Rate-Based Rules  │ │
                    │  │    - 2000 req/5min   │ │
                    │  │    - Per IP tracking │ │
                    │  └──────────────────────┘ │
                    │            │               │
                    │            ▼               │
                    │  ┌──────────────────────┐ │
                    │  │ 2. Geo-Blocking      │ │
                    │  │    - Country filter  │ │
                    │  │    - Allow/Deny list │ │
                    │  └──────────────────────┘ │
                    │            │               │
                    │            ▼               │
                    │  ┌──────────────────────┐ │
                    │  │ 3. AWS Managed Rules │ │
                    │  │    - Core Rule Set   │ │
                    │  │    - Known Bad Inputs│ │
                    │  │    - SQL Injection   │ │
                    │  │    - XSS Protection  │ │
                    │  └──────────────────────┘ │
                    │            │               │
                    │            ▼               │
                    │  ┌──────────────────────┐ │
                    │  │ 4. Custom Rules      │ │
                    │  │    - IP Allow List   │ │
                    │  │    - URI Filtering   │ │
                    │  │    - Header Checks   │ │
                    │  └──────────────────────┘ │
                    │            │               │
                    │            ▼               │
                    │  ┌──────────────────────┐ │
                    │  │  Action Decision     │ │
                    │  │  - Allow             │ │
                    │  │  - Block             │ │
                    │  │  - Count (Monitor)   │ │
                    │  └──────────────────────┘ │
                    └────────────┬───────────────┘
                                 │
                    ┌────────────┼───────────────┐
                    │            │               │
                    │  Allowed   │   Blocked     │
                    │  Traffic   │   Traffic     │
                    ▼            │               ▼
       ┌──────────────────────┐ │  ┌──────────────────────┐
       │ Application Load     │ │  │  403 Forbidden       │
       │ Balancer             │ │  │  Response            │
       │                      │ │  └──────────────────────┘
       │  ┌────────────────┐ │ │               │
       │  │ Target Group   │ │ │               │
       │  │ - EC2 Instances│ │ │               ▼
       │  │ - Containers   │ │ │  ┌──────────────────────┐
       │  │ - Lambda       │ │ │  │  CloudWatch Logs     │
       │  └────────────────┘ │ │  │  - Blocked requests  │
       └──────────┬───────────┘ │  │  - Rule matches      │
                  │             │  │  - Client IPs        │
                  ▼             │  │  - Timestamps        │
       ┌──────────────────────┐ │  └──────────────────────┘
       │  Web Application     │ │               │
       │  - EC2 Instances     │ │               │
       │  - ECS/Fargate       │ │               ▼
       │  - Lambda Functions  │ │  ┌──────────────────────┐
       └──────────────────────┘ │  │  Amazon S3           │
                  │             │  │  - WAF logs archive  │
                  ▼             │  │  - Long-term storage │
       ┌──────────────────────┐ │  │  - Compliance        │
       │  CloudWatch Logs     │ │  └──────────────────────┘
       │  - Application logs  │ │
       │  - Access logs       │ │
       └──────────────────────┘ │
                                 │
                                 ▼
                    ┌──────────────────────────┐
                    │  CloudWatch Metrics      │
                    │  - AllowedRequests       │
                    │  - BlockedRequests       │
                    │  - CountedRequests       │
                    │  - Rule matches          │
                    └──────────────────────────┘

## WAF Rule Evaluation Flow

### Request Processing Pipeline

Incoming Request
│
├─ Step 1: Extract Request Components
│  ├─ Source IP: 203.0.113.45
│  ├─ URI: /api/users?id=1
│  ├─ Headers: User-Agent, Cookie, etc.
│  ├─ Body: POST data
│  └─ Geo Location: Country code
│
├─ Step 2: Evaluate Rules (Priority Order)
│  │
│  ├─ Priority 1: Rate-Based Rule
│  │  ├─ Check: Requests from IP in last 5 minutes
│  │  ├─ Threshold: 2000 requests
│  │  ├─ Current: 150 requests
│  │  └─ Result: PASS (Continue)
│  │
│  ├─ Priority 2: Geo-Blocking Rule
│  │  ├─ Check: Country code
│  │  ├─ Blocked Countries: [CN, RU, KP]
│  │  ├─ Request Country: US
│  │  └─ Result: PASS (Continue)
│  │
│  ├─ Priority 3: AWS Managed Rules - Core Rule Set
│  │  ├─ Check: SQL Injection patterns
│  │  ├─ Pattern: ' OR '1'='1
│  │  ├─ Found in: Query parameter 'id'
│  │  └─ Result: BLOCK (Stop evaluation)
│  │
│  └─ Priority 4: Custom Rules (Not evaluated - blocked)
│
└─ Step 3: Action Execution
   ├─ Action: BLOCK
   ├─ Response: 403 Forbidden
   ├─ Log: CloudWatch Logs
   └─ Metric: BlockedRequests +1

## Protection Layers

### Layer 1: Rate-Based Protection

**Purpose**: Prevent DDoS attacks and brute-force attempts

**Configuration**:
```json
{
  "Name": "RateLimitRule",
  "Priority": 1,
  "Statement": {
    "RateBasedStatement": {
      "Limit": 2000,
      "AggregateKeyType": "IP"
    }
  },
  "Action": {
    "Block": {}
  }
}

**Protection Against**:
- Distributed Denial of Service (DDoS)
- Brute-force login attempts
- API abuse
- Credential stuffing
- Web scraping

**Behavior**:
- Tracks requests per IP address
- 5-minute rolling window
- Automatic blocking when threshold exceeded
- Automatic unblocking after rate decreases

### Layer 2: Geographic Restrictions

**Purpose**: Block traffic from high-risk countries

**Configuration**:
```json
{
  "Name": "GeoBlockingRule",
  "Priority": 2,
  "Statement": {
    "GeoMatchStatement": {
      "CountryCodes": ["CN", "RU", "KP", "IR"]
    }
  },
  "Action": {
    "Block": {}
  }
}

**Use Cases**:
- Compliance requirements (GDPR, data residency)
- Reduce attack surface from high-risk regions
- Licensing restrictions
- Regional service availability

### Layer 3: AWS Managed Rules

**Purpose**: Protection against OWASP Top 10 and common exploits

#### Core Rule Set (CRS)

**Protections**:
- SQL Injection (SQLi)
- Cross-Site Scripting (XSS)
- Local File Inclusion (LFI)
- Remote File Inclusion (RFI)
- Path Traversal
- Command Injection
- Session Fixation

**Example Rules**:
SQL Injection Detection:
- Pattern: ' OR '1'='1
- Pattern: UNION SELECT
- Pattern: DROP TABLE
- Pattern: ; DELETE FROM

XSS Detection:
- Pattern: <script>
- Pattern: javascript:
- Pattern: onerror=
- Pattern: onload=

#### Known Bad Inputs

**Protections**:
- Known malicious user agents
- Known bad bot signatures
- Exploit attempt patterns
- Vulnerability scanners

#### Amazon IP Reputation List

**Protections**:
- Known malicious IP addresses
- Botnet sources
- Tor exit nodes
- Anonymous proxies

### Layer 4: Custom Rules

**Purpose**: Application-specific protection

#### IP Allow List

```json
{
  "Name": "IPAllowListRule",
  "Priority": 10,
  "Statement": {
    "IPSetReferenceStatement": {
      "Arn": "arn:aws:wafv2:us-east-1:XXXXXXXXXXXX:regional/ipset/admin-ips/..."
    }
  },
  "Action": {
    "Allow": {}
  }
}

**Use Cases**:
- Admin panel access
- API management endpoints
- Internal tools
- Partner integrations

#### URI Path Filtering

```json
{
  "Name": "BlockAdminPaths",
  "Priority": 11,
  "Statement": {
    "ByteMatchStatement": {
      "SearchString": "/admin",
      "FieldToMatch": {
        "UriPath": {}
      },
      "TextTransformations": [
        {
          "Priority": 0,
          "Type": "LOWERCASE"
        }
      ],
      "PositionalConstraint": "STARTS_WITH"
    }
  },
  "Action": {
    "Block": {}
  }
}

#### Header Validation

```json
{
  "Name": "RequireAPIKey",
  "Priority": 12,
  "Statement": {
    "NotStatement": {
      "Statement": {
        "ByteMatchStatement": {
          "SearchString": "valid-api-key-value",
          "FieldToMatch": {
            "SingleHeader": {
              "Name": "x-api-key"
            }
          }
        }
      }
    }
  },
  "Action": {
    "Block": {}
  }
}

## Rule Actions

### Block Action

**Behavior**:
- Returns 403 Forbidden
- Stops rule evaluation
- Logs to CloudWatch
- Increments BlockedRequests metric

**Custom Response**:
```json
{
  "Action": {
    "Block": {
      "CustomResponse": {
        "ResponseCode": 403,
        "CustomResponseBodyKey": "blocked-message"
      }
    }
  }
}

### Allow Action

**Behavior**:
- Passes request to ALB
- Stops rule evaluation
- Logs to CloudWatch
- Increments AllowedRequests metric

### Count Action

**Behavior**:
- Continues rule evaluation
- Logs to CloudWatch
- Increments CountedRequests metric
- Used for testing rules before enforcement

## Logging and Monitoring

### CloudWatch Logs

**Log Format**:
```json
{
  "timestamp": 1234567890000,
  "formatVersion": 1,
  "webaclId": "arn:aws:wafv2:us-east-1:XXXXXXXXXXXX:regional/webacl/...",
  "terminatingRuleId": "RateLimitRule",
  "terminatingRuleType": "RATE_BASED",
  "action": "BLOCK",
  "httpSourceName": "ALB",
  "httpSourceId": "app/my-alb/...",
  "ruleGroupList": [],
  "rateBasedRuleList": [
    {
      "rateBasedRuleName": "RateLimitRule",
      "limit": 2000,
      "maxRateAllowed": 2000
    }
  ],
  "httpRequest": {
    "clientIp": "203.0.113.45",
    "country": "US",
    "headers": [
      {
        "name": "Host",
        "value": "example.com"
      },
      {
        "name": "User-Agent",
        "value": "Mozilla/5.0..."
      }
    ],
    "uri": "/api/users",
    "args": "id=1",
    "httpVersion": "HTTP/1.1",
    "httpMethod": "GET",
    "requestId": "request-uuid"
  }
}

### CloudWatch Metrics

**Available Metrics**:
- `AllowedRequests`: Requests that passed all rules
- `BlockedRequests`: Requests blocked by rules
- `CountedRequests`: Requests matched by count rules
- `PassedRequests`: Requests evaluated but not matched

**Dimensions**:
- `WebACL`: Web ACL name
- `Rule`: Individual rule name
- `Region`: AWS region

### CloudWatch Alarms

**Example Alarms**:
High Block Rate:
- Metric: BlockedRequests
- Threshold: > 1000 in 5 minutes
- Action: SNS notification

Rate Limit Triggered:
- Metric: BlockedRequests (RateLimitRule)
- Threshold: > 100 in 5 minutes
- Action: SNS notification

Potential Attack:
- Metric: BlockedRequests (SQLi rules)
- Threshold: > 50 in 5 minutes
- Action: SNS notification + Lambda

## Performance Considerations

### Latency Impact

**WAF Processing Time**:
- Simple rules: 1-5ms
- Managed rule groups: 5-15ms
- Complex regex: 10-30ms
- Total typical overhead: 10-50ms

**Optimization Strategies**:
1. **Rule Ordering**: Place most common blocks first
2. **Caching**: Enable authorization caching where possible
3. **Rule Simplification**: Avoid complex regex patterns
4. **Scope Reduction**: Apply rules only where needed
5. **Count Mode Testing**: Test rules before enforcement

### Capacity Units

**WCU (Web ACL Capacity Units)**:
- Default quota: 1500 WCU per Web ACL
- Rate-based rule: 2 WCU
- Managed rule group: 50-700 WCU
- Custom rule: 1-10 WCU depending on complexity

**Example Calculation**:
Web ACL Capacity:
├─ Rate-based rule: 2 WCU
├─ Geo-blocking: 1 WCU
├─ Core Rule Set: 700 WCU
├─ Known Bad Inputs: 200 WCU
├─ IP Reputation: 25 WCU
├─ Custom rules (5): 10 WCU
└─ Total: 938 WCU (62% of quota)

## Cost Considerations

### Pricing Components

**Web ACL**:
- $5.00 per month per Web ACL
- $1.00 per million requests

**Rules**:
- $1.00 per month per rule
- Managed rule groups: $10-$50 per month

**Logging**:
- CloudWatch Logs: $0.50 per GB ingested
- S3 storage: Standard S3 pricing

**Example Monthly Cost**:
Web ACL: $5.00
Rules (10): $10.00
Managed Rules (3 groups): $30.00
Requests (100M): $100.00
Logging (50GB): $25.00
Total: ~$170.00/month

### Cost Optimization

1. **Rule Consolidation**: Combine similar rules
2. **Sampling**: Log only blocked requests
3. **S3 Lifecycle**: Archive old logs to Glacier
4. **Scope Limitation**: Apply WAF only to public endpoints
5. **Count Mode**: Test before enabling expensive rules

## Best Practices

### Security Best Practices

✅ **Defense in Depth**: Multiple protection layers
✅ **Managed Rules**: Use AWS Managed Rules for OWASP protection
✅ **Rate Limiting**: Protect against DDoS and brute-force
✅ **Logging**: Enable comprehensive logging
✅ **Monitoring**: Set up CloudWatch alarms
✅ **Regular Updates**: Keep managed rules updated
✅ **Testing**: Test rules in count mode first
✅ **Least Privilege**: Apply rules only where needed

### Operational Best Practices

✅ **Version Control**: Track Web ACL changes
✅ **Change Management**: Test in staging first
✅ **Documentation**: Document custom rules
✅ **Incident Response**: Playbooks for attacks
✅ **Regular Review**: Audit rules quarterly
✅ **False Positive Handling**: Process for exceptions
✅ **Performance Monitoring**: Track latency impact

## Real-World Use Cases

### E-Commerce Platform

- Rate limiting on checkout endpoints
- Geo-blocking for compliance
- SQL injection protection for search
- XSS protection for user reviews
- Bot protection for inventory scraping

### API Gateway

- Rate limiting per API key
- IP allow list for partners
- Header validation for authentication
- DDoS protection
- Abuse prevention

### Content Management System

- Admin panel IP restrictions
- SQL injection protection
- XSS protection for comments
- File upload validation
- Brute-force protection for login

## Troubleshooting

### Common Issues

**Legitimate Traffic Blocked**:
- Review CloudWatch logs for rule matches
- Identify false positive patterns
- Add exceptions or adjust rules
- Use count mode to test changes

**High Latency**:
- Check rule complexity
- Review managed rule group count
- Optimize rule ordering
- Consider scope reduction

**Logs Not Appearing**:
- Verify logging configuration
- Check S3 bucket permissions
- Confirm CloudWatch Logs permissions
- Validate log delivery IAM role

## Additional Resources

- [AWS WAF Documentation](https://docs.aws.amazon.com/waf/)
- [AWS Managed Rules](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [AWS WAF Security Automations](https://aws.amazon.com/solutions/implementations/aws-waf-security-automations/)

