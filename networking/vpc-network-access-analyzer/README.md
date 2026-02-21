# Working with Amazon VPC Network Access Analyzer

## Lab Overview

This lab provides hands-on experience with Amazon VPC Network Access Analyzer, a feature that helps you understand, verify, and improve your network security posture. You'll learn to analyze network paths, validate configurations, and demonstrate compliance requirements using automated reasoning algorithms.

**Duration:** 60 minutes  
**Complexity:** Intermediate

## Learning Objectives

By the end of this lab, you will be able to:
- Understand, verify, and improve network security posture using Network Access Analyzer
- Analyze network paths between resources in your VPC
- Validate that network configurations meet compliance requirements
- Create custom Network Access Scopes for specific analysis scenarios
- Identify potential security risks in VPC architectures

## What is Network Access Analyzer?

Network Access Analyzer is a feature of Amazon VPC that uses automated reasoning to analyze your network configuration and identify potential network paths. It helps you:

- **Verify security posture** - Ensure your network meets security requirements
- **Validate compliance** - Demonstrate that configurations meet compliance standards
- **Identify unintended access** - Find network paths that shouldn't exist
- **Analyze changes** - Understand the impact of configuration changes

### Key Concepts

**Network Access Scope:**
- Defines the criteria for network path analysis
- Specifies source and destination resources
- Can include or exclude specific paths
- Uses automated reasoning to find all possible paths

**Findings:**
- Potential network paths that match the scope criteria
- Show source, destination, and path details
- Help identify security risks or compliance violations

**MatchPaths vs ExcludePaths:**
- **MatchPaths** - Paths you want to find and analyze
- **ExcludePaths** - Paths you want to exclude from findings (e.g., expected/compliant paths)

## Architecture

The lab environment consists of three VPCs with different network designs:

**VPC 1: Isolated Private Network**
- Private subnet with EC2 instance
- No Internet Gateway (completely isolated)
- S3 Gateway Endpoint (added during lab)

**VPC 2: Public and Private with NAT**
- Public subnet with NAT Gateway
- Private subnet with EC2 instance
- Internet Gateway for NAT Gateway
- Private instances use NAT for outbound internet access

**VPC 3: Public Network**
- Public subnet with EC2 instance
- Internet Gateway
- Direct internet access for instances

See [architecture.md](./architecture.md) for detailed architecture diagrams and explanations.

## Prerequisites

- AWS Account with appropriate permissions
- Understanding of VPC concepts (subnets, route tables, gateways)
- Familiarity with EC2 and security groups
- Basic knowledge of network security principles

## Tasks

### Task 1: Understand the Architectures

**Objective:** Explore the three VPC architectures and understand their network designs.

#### Explore VPC 1 (Isolated)

1. Navigate to **VPC Console** → **Your VPCs**
2. Select **VPC 1** and review:
   - CIDR block
   - No Internet Gateway attached
3. Navigate to **Subnets** and review:
   - Private subnet configuration
   - Route table (no route to internet)
4. Navigate to **Instances** and note:
   - EC2 instance in private subnet
   - Private IP only (no public IP)

#### Explore VPC 2 (NAT Gateway)

1. Select **VPC 2** and review:
   - CIDR block
   - Internet Gateway attached
2. Navigate to **Subnets** and review:
   - Public subnet (with NAT Gateway)
   - Private subnet (with EC2 instance)
3. Navigate to **NAT Gateways** and note:
   - NAT Gateway in public subnet
   - Elastic IP attached
4. Review **Route Tables**:
   - Public subnet: 0.0.0.0/0 → Internet Gateway
   - Private subnet: 0.0.0.0/0 → NAT Gateway

#### Explore VPC 3 (Public)

1. Select **VPC 3** and review:
   - CIDR block
   - Internet Gateway attached
2. Navigate to **Subnets** and review:
   - Public subnet with EC2 instance
3. Review **Route Table**:
   - 0.0.0.0/0 → Internet Gateway

**Key Differences:**
- VPC 1: No internet access
- VPC 2: Outbound internet via NAT Gateway
- VPC 3: Direct bidirectional internet access

### Task 2: Use Network Access Scope Template

**Objective:** Use a pre-built template to analyze inbound traffic from Internet Gateways.

1. Navigate to **VPC Console** → **Network Access Analyzer**
2. Click **Create network access scope**
3. Select **Use a template**
4. Choose **Identify access from Internet Gateways**
5. Configure:
   - **Name:** `inbound-from-igw`
   - **Description:** `Analyze inbound paths from Internet Gateways`
6. Click **Create network access scope**

#### Analyze the Scope

1. Select the `inbound-from-igw` scope
2. Click **Analyze**
3. Wait for analysis to complete (may take 1-2 minutes)

#### Review Findings

**Expected Findings:**

**VPC 3 Finding:**
- **Source:** Internet Gateway
- **Destination:** EC2 instance in public subnet
- **Path:** IGW → Public Subnet → EC2 Instance
- **Interpretation:** Direct inbound access from internet (potential risk)

**VPC 2 - No Finding for Private Subnet:**
- Private subnet instance has no direct inbound path from IGW
- NAT Gateway only allows outbound traffic
- This is compliant with security best practices

**Key Insight:** Network Access Analyzer identifies that VPC 3 has direct inbound internet access, which may be a security concern depending on requirements.

### Task 3: Create and Analyze VPC Endpoint Path

**Objective:** Create an S3 gateway endpoint and verify the network path.

#### Create S3 Gateway Endpoint

1. Navigate to **VPC Console** → **Endpoints**
2. Click **Create endpoint**
3. Configure:
   - **Name:** `vpc1-s3-endpoint`
   - **Service category:** AWS services
   - **Service name:** `com.amazonaws.<region>.s3` (Gateway type)
   - **VPC:** VPC 1
   - **Route tables:** Select VPC 1 private subnet route table
4. Click **Create endpoint**

**Automation:** Use the provided script:
```bash
./scripts/create-s3-endpoint.sh VPC1_ID ROUTE_TABLE_ID
```

#### Create Custom Network Access Scope

1. Navigate to **Network Access Analyzer**
2. Click **Create network access scope**
3. Select **Build from scratch**
4. Configure:
   - **Name:** `validate-s3-endpoint-access`
   - **Description:** `Verify access from VPC 1 instance to S3 endpoint`
5. Configure **Match paths**:
   - **Source type:** Instances
   - **Source:** Select VPC 1 EC2 instance
   - **Destination type:** VPC endpoints
   - **Destination:** Select `vpc1-s3-endpoint`
6. Click **Create network access scope**

#### Analyze and Review

1. Select the scope and click **Analyze**
2. Review findings:
   - **Expected:** Path from EC2 instance to S3 endpoint
   - **Path details:** Instance → Subnet → Route Table → S3 Endpoint

**Key Insight:** VPC 1 instance can access S3 without internet access via the gateway endpoint.

### Task 4: Analyze Private Subnet Isolation

**Objective:** Verify that private subnets don't have direct internet access.

#### Create Custom Scope

1. Navigate to **Network Access Analyzer**
2. Click **Create network access scope**
3. Configure:
   - **Name:** `verify-private-subnet-isolation`
   - **Description:** `Ensure private subnets have no direct internet access`
4. Configure **Match paths**:
   - **Source type:** Internet Gateways
   - **Source:** All Internet Gateways
   - **Destination type:** Subnets
   - **Destination:** Select all private subnets (VPC 1 and VPC 2 private)
5. Click **Create network access scope**

#### Analyze and Review

1. Select the scope and click **Analyze**
2. Review findings:
   - **Expected:** No findings
   - **Interpretation:** No direct paths from IGW to private subnets (compliant)

**Key Insight:** Private subnets are properly isolated from direct internet access.

### Task 5: Analyze VPC Segmentation with Peering

**Objective:** Create VPC peering and verify connectivity between VPCs.

#### Initial Analysis (No Peering)

1. Create Network Access Scope:
   - **Name:** `verify-vpc-segmentation`
   - **Description:** `Analyze VPC peering connections`
2. Configure **Match paths**:
   - **Source type:** Instances
   - **Source:** VPC 1 EC2 instance
   - **Destination type:** Instances
   - **Destination:** VPC 3 EC2 instance
3. Analyze:
   - **Expected:** No findings (no peering exists)

#### Create VPC Peering Connection

1. Navigate to **VPC Console** → **Peering Connections**
2. Click **Create peering connection**
3. Configure:
   - **Name:** `vpc1-to-vpc3-peering`
   - **VPC (Requester):** VPC 1
   - **VPC (Accepter):** VPC 3
4. Click **Create peering connection**
5. Select the peering connection and click **Actions** → **Accept request**

**Automation:** Use the provided script:
```bash
./scripts/create-vpc-peering.sh VPC1_ID VPC3_ID
```

#### Update Route Tables

**VPC 1 Route Table:**
1. Navigate to **Route Tables**
2. Select VPC 1 private subnet route table
3. Click **Edit routes** → **Add route**:
   - **Destination:** VPC 3 CIDR block
   - **Target:** Peering connection `vpc1-to-vpc3-peering`
4. Click **Save changes**

**VPC 3 Route Table:**
1. Select VPC 3 public subnet route table
2. Click **Edit routes** → **Add route**:
   - **Destination:** VPC 1 CIDR block
   - **Target:** Peering connection `vpc1-to-vpc3-peering`
3. Click **Save changes**

#### Re-analyze

1. Return to Network Access Analyzer
2. Select `verify-vpc-segmentation` scope
3. Click **Analyze** again
4. Review findings:
   - **Expected:** Path found from VPC 1 to VPC 3
   - **Path details:** VPC 1 Instance → Peering Connection → VPC 3 Instance

**Key Insight:** Network Access Analyzer detects the new peering connection and validates connectivity.

### Task 6: Verify NAT Gateway Usage

**Objective:** Validate that VPC 2 private subnet uses NAT Gateway for internet access.

#### Create Network Access Scope

1. Create new scope:
   - **Name:** `verify-nat-usage`
   - **Description:** `Validate private instances use NAT for internet access`
2. Configure **Match paths**:
   - **Source type:** Instances
   - **Source:** All instances in private subnets
   - **Destination type:** Internet Gateways
   - **Destination:** All Internet Gateways
3. Click **Create network access scope**

#### Analyze and Review

1. Select the scope and click **Analyze**
2. Review findings:

**Expected Findings:**

**VPC 2 Private Instance:**
- **Path:** Instance → NAT Gateway → Internet Gateway
- **Interpretation:** Uses NAT Gateway (compliant)

**VPC 3 Public Instance:**
- **Path:** Instance → Internet Gateway
- **Interpretation:** Direct access (may or may not be compliant)

**VPC 1 Instance:**
- **No finding:** No internet access at all

**Key Insight:** Network Access Analyzer shows different internet access patterns across VPCs.

### Task 7: Exclude NAT Gateway Paths

**Objective:** Duplicate and modify a scope to exclude expected NAT Gateway paths.

#### Duplicate Scope

1. Navigate to **Network Access Analyzer**
2. Select `verify-nat-usage` scope
3. Click **Actions** → **Duplicate**
4. Rename to: `verify-nat-usage-exclude-nat`

#### Add Exclusion

1. Edit the duplicated scope
2. Add **Exclude paths**:
   - **Through resource type:** NAT Gateways
   - **Through resource:** All NAT Gateways
3. Click **Save changes**

#### Analyze and Review

1. Select the modified scope and click **Analyze**
2. Review findings:
   - **VPC 2:** No finding (NAT path excluded)
   - **VPC 3:** Finding still present (direct IGW access)
   - **VPC 1:** No finding (no internet access)

**Key Insight:** ExcludePaths allows you to filter out expected/compliant paths and focus on potential issues.

### Task 8: Validate Compliance Requirement

**Objective:** Validate that a specific instance can access a particular IP address and port.

#### Scenario

**Compliance Requirement:**
- VPC 2 private instance must be able to access AWS service endpoint
- Specific IP: 205.251.242.103 (example AWS service IP)
- Port: 443 (HTTPS)

#### Create Network Access Scope

1. Create new scope:
   - **Name:** `validate-compliance-requirement`
   - **Description:** `Verify VPC 2 instance can access specific IP:port`
2. Configure **Match paths**:
   - **Source type:** Instances
   - **Source:** VPC 2 private instance
   - **Destination type:** IP addresses
   - **Destination:** 205.251.242.103/32
   - **Destination port:** 443
   - **Protocol:** TCP
3. Click **Create network access scope**

#### Initial Analysis

1. Analyze the scope
2. Review findings:
   - **Expected:** May show no findings or blocked path
   - **Reason:** Security group may not allow outbound HTTPS to specific IP

#### Update Security Group

1. Navigate to **EC2 Console** → **Security Groups**
2. Select the security group for VPC 2 private instance
3. Click **Edit outbound rules**
4. Add rule:
   - **Type:** HTTPS
   - **Protocol:** TCP
   - **Port:** 443
   - **Destination:** 205.251.242.103/32
   - **Description:** Allow HTTPS to AWS service endpoint
5. Click **Save rules**

#### Re-analyze

1. Return to Network Access Analyzer
2. Select `validate-compliance-requirement` scope
3. Click **Analyze** again
4. Review findings:
   - **Expected:** Path found
   - **Path:** Instance → NAT Gateway → IGW → 205.251.242.103:443

**Key Insight:** Network Access Analyzer validates compliance by confirming the required network path exists.

## Key Learnings

### Network Access Analyzer Benefits

1. **Automated Analysis** - Uses automated reasoning to find all possible paths
2. **Compliance Validation** - Demonstrates that configurations meet requirements
3. **Security Posture** - Identifies unintended network access
4. **Change Impact** - Analyzes the effect of configuration changes
5. **Documentation** - Provides evidence for audits and compliance reports

### Network Access Scope Design

1. **Be Specific** - Define precise source and destination criteria
2. **Use Templates** - Start with pre-built templates for common scenarios
3. **Leverage Exclusions** - Use ExcludePaths to filter expected paths
4. **Iterate** - Refine scopes based on findings
5. **Document** - Add clear descriptions for future reference

### Common Use Cases

1. **Verify Internet Isolation** - Ensure private resources have no direct internet access
2. **Validate VPC Peering** - Confirm connectivity between peered VPCs
3. **Check Endpoint Access** - Verify VPC endpoint paths
4. **Audit NAT Usage** - Ensure private instances use NAT Gateways
5. **Compliance Reporting** - Demonstrate network security posture

### Best Practices

1. **Regular Analysis** - Run analyses periodically to detect configuration drift
2. **Baseline Scopes** - Create baseline scopes for ongoing monitoring
3. **Automate** - Use AWS CLI or SDKs to automate scope creation and analysis
4. **Integrate with CI/CD** - Validate network changes before deployment
5. **Document Findings** - Track and remediate identified issues
6. **Use Tags** - Tag resources for easier scope configuration

## Cleanup

To avoid ongoing charges, delete the lab resources:

1. Delete VPC peering connections
2. Delete VPC endpoints
3. Terminate all EC2 instances
4. Delete NAT Gateways (and release Elastic IPs)
5. Delete Network Access Scopes
6. Delete VPCs (will delete associated subnets, route tables, etc.)

**Note:** Delete resources in the correct order to avoid dependency errors.

## Additional Resources

- [Network Access Analyzer Documentation](https://docs.aws.amazon.com/vpc/latest/network-access-analyzer/)
- [Network Access Analyzer User Guide](https://docs.aws.amazon.com/vpc/latest/network-access-analyzer/what-is-network-access-analyzer.html)
- [VPC Peering Documentation](https://docs.aws.amazon.com/vpc/latest/peering/)
- [VPC Endpoints Documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)

## Scripts

This lab includes automation scripts in the `scripts/` directory:

- `create-s3-endpoint.sh` - Create S3 gateway endpoint
- `create-vpc-peering.sh` - Create and configure VPC peering
- `create-network-access-scope.sh` - Create custom scope via AWS CLI
- `analyze-network-paths.sh` - Run analysis and view findings

See individual script files for usage instructions.

## Configuration Files

Sample Network Access Scope configurations are provided in the `configs/` directory:

- `network-access-scope-inbound.json` - Inbound traffic analysis
- `network-access-scope-s3-endpoint.json` - S3 endpoint path validation
- `network-access-scope-vpc-peering.json` - VPC segmentation analysis

These can be used with the AWS CLI to create scopes programmatically.
