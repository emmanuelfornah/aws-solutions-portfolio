# Using Network Troubleshooting Commands

## Overview

This lab provides hands-on experience with essential network troubleshooting commands used to identify and diagnose network issues on EC2 instances. You'll learn to use industry-standard tools like traceroute, ifconfig, telnet, netstat, curl, dig, and tcpdump to analyze network connectivity, DNS resolution, and packet flows.

**Lab Type**: Hands-on troubleshooting and analysis  
**Difficulty**: Intermediate  
**Estimated Time**: 60 minutes

## AWS Services Used

- **Amazon EC2** - Virtual servers for running troubleshooting commands
- **Amazon VPC** - Isolated virtual network for testing connectivity

## Key Technologies

- **traceroute** - Path analysis and latency measurement
- **ifconfig** - Network interface configuration and statistics
- **telnet** - TCP port connectivity testing
- **netstat** - Connection and port monitoring
- **curl** - HTTP/HTTPS testing and debugging
- **dig** - DNS lookup and troubleshooting
- **tcpdump** - Packet capture and analysis
- **httpd (Apache)** - Web server for testing connectivity

## Architecture Overview

The lab uses a VPC with two EC2 instances for network troubleshooting:

```
VPC (Network Troubleshooting Lab)
├── Instance A (Test Client)
│   ├── Private IP: 10.0.x.x
│   └── Troubleshooting tools installed
│
├── Instance B (Target Server)
│   ├── Private IP: 10.0.x.x
│   └── httpd web server running
│
└── Security Groups
    ├── Instance A: Outbound traffic allowed
    └── Instance B: HTTP (80) inbound allowed
```

**Key Components**:
- **Instance A**: Test client for running troubleshooting commands
- **Instance B**: Target server running httpd web server
- **Security Groups**: Control traffic between instances
- **Private IPs**: Internal VPC addressing for communication

**Network Flow**:
1. Instance A initiates connections to Instance B
2. Security groups filter traffic based on rules
3. Troubleshooting commands analyze connectivity
4. Packet capture reveals detailed network behavior

## Objectives

By completing this lab, you will:

1. ✅ Install and use traceroute to track network paths
2. ✅ Use ifconfig to view network interface configuration
3. ✅ Test TCP connectivity with telnet
4. ✅ Monitor network connections with netstat
5. ✅ Test HTTP/HTTPS connectivity with curl
6. ✅ Perform DNS lookups with dig
7. ✅ Capture and analyze network packets with tcpdump
8. ✅ Understand TCP three-way handshake
9. ✅ Diagnose network connectivity issues
10. ✅ Analyze network interface statistics

## Key Learnings

### traceroute - Path Analysis

**Purpose**: Tracks the path packets take from source to destination, showing each hop and latency.

**Key Concepts**:
- **Hop-by-hop routing**: Shows each router/gateway in the path
- **Latency measurement**: RTT (Round Trip Time) for each hop
- **Packet loss detection**: Identifies where packets are dropped
- **TTL (Time To Live)**: Incremental TTL values to discover hops
- **ICMP/UDP**: Uses ICMP or UDP packets for probing

**Common Use Cases**:
- Identify network bottlenecks
- Detect routing loops
- Measure network latency
- Troubleshoot connectivity issues
- Verify network path changes

**Example Output**:
```
traceroute to example.com (93.184.216.34), 30 hops max
 1  10.0.0.1 (10.0.0.1)  1.234 ms  1.123 ms  1.089 ms
 2  172.16.0.1 (172.16.0.1)  5.678 ms  5.432 ms  5.321 ms
 3  * * *  (timeout)
 4  93.184.216.34 (93.184.216.34)  15.234 ms  15.123 ms  15.089 ms
```

### ifconfig - Interface Configuration

**Purpose**: Displays network interface configuration, IP addresses, and statistics.

**Key Information Displayed**:
- **IP Address**: IPv4 and IPv6 addresses assigned
- **Netmask**: Subnet mask for the network
- **Broadcast**: Broadcast address for the subnet
- **MAC Address**: Hardware address of the interface
- **MTU**: Maximum Transmission Unit size
- **RX/TX Packets**: Received and transmitted packet counts
- **Errors**: Packet errors, drops, and collisions

**Common Use Cases**:
- Verify IP address configuration
- Check interface status (up/down)
- Monitor packet statistics
- Identify network errors
- Troubleshoot connectivity issues

**Example Output**:
```
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9001
        inet 10.0.1.100  netmask 255.255.255.0  broadcast 10.0.1.255
        ether 02:ab:cd:ef:12:34  txqueuelen 1000  (Ethernet)
        RX packets 12345  bytes 1234567 (1.2 MB)
        TX packets 6789  bytes 789012 (789.0 KB)
```

### telnet - TCP Connectivity Testing

**Purpose**: Tests TCP connectivity to specific ports on remote hosts.

**Key Concepts**:
- **Port testing**: Verifies if a port is open and accepting connections
- **Service availability**: Confirms services are listening
- **TCP handshake**: Establishes TCP connection to test reachability
- **Interactive protocol testing**: Can manually interact with protocols (HTTP, SMTP)

**Common Use Cases**:
- Test if a port is open
- Verify firewall rules
- Check service availability
- Debug application connectivity
- Test load balancer health

**Example Usage**:
```bash
# Test HTTP port
telnet example.com 80

# Test HTTPS port
telnet example.com 443

# Test SSH port
telnet 10.0.1.100 22
```

**Success Indicators**:
- Connection established message
- Blank screen (waiting for input)
- Service banner displayed

**Failure Indicators**:
- Connection refused (port closed)
- Connection timeout (firewall blocking)
- No route to host (routing issue)

### netstat - Network Statistics

**Purpose**: Displays active network connections, listening ports, and network statistics.

**Key Information**:
- **Active connections**: Current TCP/UDP connections
- **Listening ports**: Services waiting for connections
- **Routing table**: Network routing information
- **Interface statistics**: Per-interface packet counts
- **Protocol statistics**: TCP/UDP/ICMP statistics

**Common Options**:
- `netstat -tuln`: Show listening TCP/UDP ports (numeric)
- `netstat -an`: Show all connections and listening ports
- `netstat -r`: Display routing table
- `netstat -s`: Show protocol statistics
- `netstat -i`: Display interface statistics

**Common Use Cases**:
- Identify listening services
- Find established connections
- Detect unauthorized connections
- Troubleshoot port conflicts
- Monitor network activity

**Example Output**:
```
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN
tcp        0      0 10.0.1.100:22           10.0.1.50:54321         ESTABLISHED
```

### curl - HTTP/HTTPS Testing

**Purpose**: Tests HTTP/HTTPS connectivity and analyzes responses.

**Key Features**:
- **HTTP methods**: GET, POST, PUT, DELETE, etc.
- **Headers**: View and set HTTP headers
- **Response codes**: Analyze HTTP status codes
- **Verbose mode**: Detailed connection information
- **Follow redirects**: Automatically follow 3xx redirects
- **Authentication**: Support for various auth methods

**Common Options**:
- `curl -v`: Verbose output with connection details
- `curl -I`: Fetch headers only (HEAD request)
- `curl -L`: Follow redirects
- `curl -o file`: Save output to file
- `curl -H "Header: value"`: Set custom headers

**Common Use Cases**:
- Test web server connectivity
- Debug HTTP issues
- Verify SSL/TLS certificates
- Test API endpoints
- Troubleshoot load balancers

**Example Usage**:
```bash
# Basic GET request
curl http://example.com

# Verbose output
curl -v http://example.com

# Headers only
curl -I http://example.com

# Test HTTPS with certificate details
curl -v https://example.com
```

### dig - DNS Troubleshooting

**Purpose**: Performs DNS lookups and troubleshoots DNS resolution issues.

**Key Features**:
- **DNS queries**: A, AAAA, MX, TXT, NS, SOA records
- **Query details**: Shows query, answer, authority, additional sections
- **Nameserver selection**: Query specific DNS servers
- **Trace mode**: Follow DNS delegation path
- **Reverse lookups**: IP to hostname resolution

**Common Options**:
- `dig example.com`: Basic A record lookup
- `dig example.com MX`: Query MX records
- `dig @8.8.8.8 example.com`: Query specific nameserver
- `dig +short example.com`: Brief output (IP only)
- `dig +trace example.com`: Trace DNS delegation
- `dig -x 1.2.3.4`: Reverse DNS lookup

**Common Use Cases**:
- Verify DNS records
- Troubleshoot DNS resolution
- Check DNS propagation
- Verify Route 53 records
- Debug DNS issues

**Example Output**:
```
; <<>> DiG 9.16.1 <<>> example.com
;; QUESTION SECTION:
;example.com.                   IN      A

;; ANSWER SECTION:
example.com.            300     IN      A       93.184.216.34

;; Query time: 15 msec
;; SERVER: 10.0.0.2#53(10.0.0.2)
;; WHEN: Mon Jan 01 12:00:00 UTC 2024
;; MSG SIZE  rcvd: 56
```

### tcpdump - Packet Capture

**Purpose**: Captures and analyzes network packets for deep troubleshooting.

**Key Features**:
- **Packet capture**: Capture all network traffic
- **Filtering**: Capture specific protocols, ports, hosts
- **Protocol analysis**: Decode TCP, UDP, ICMP, etc.
- **Hex dump**: View raw packet data
- **Save to file**: Capture to pcap for Wireshark analysis

**Common Options**:
- `tcpdump -i eth0`: Capture on specific interface
- `tcpdump port 80`: Capture HTTP traffic
- `tcpdump host 10.0.1.100`: Capture traffic to/from host
- `tcpdump -n`: Don't resolve hostnames
- `tcpdump -w file.pcap`: Save to file
- `tcpdump -c 10`: Capture 10 packets only

**Common Use Cases**:
- Analyze TCP handshake
- Debug connection issues
- Verify packet delivery
- Troubleshoot firewall rules
- Capture malicious traffic

**TCP Three-Way Handshake**:
```
1. SYN: Client → Server (Synchronize)
2. SYN-ACK: Server → Client (Synchronize-Acknowledge)
3. ACK: Client → Server (Acknowledge)
```

**Example Output**:
```
12:00:00.123456 IP 10.0.1.100.54321 > 10.0.1.200.80: Flags [S], seq 1234567890
12:00:00.123789 IP 10.0.1.200.80 > 10.0.1.100.54321: Flags [S.], seq 9876543210, ack 1234567891
12:00:00.123890 IP 10.0.1.100.54321 > 10.0.1.200.80: Flags [.], ack 1
```

### Network Troubleshooting Methodology

**Step 1: Verify Physical/Link Layer**
- Check interface status with `ifconfig`
- Verify interface is UP
- Check for errors, drops, collisions

**Step 2: Verify Network Layer**
- Test connectivity with `ping`
- Check routing with `traceroute`
- Verify IP configuration

**Step 3: Verify Transport Layer**
- Test port connectivity with `telnet`
- Check listening ports with `netstat`
- Analyze TCP handshake with `tcpdump`

**Step 4: Verify Application Layer**
- Test HTTP with `curl`
- Verify DNS with `dig`
- Check application logs

**Step 5: Analyze Traffic**
- Capture packets with `tcpdump`
- Analyze protocol behavior
- Identify anomalies

## Setup Instructions

### Prerequisites

- AWS account with appropriate permissions
- Access to AWS Management Console
- Basic understanding of VPC networking
- Familiarity with EC2 instance management
- Understanding of TCP/IP networking

### Step 1: Launch EC2 Instances

Launch two EC2 instances in the same VPC:

1. Navigate to **EC2 Console** → **Instances** → **Launch Instance**
2. Configure **Instance A** (Test Client):
   - **Name**: Instance A
   - **AMI**: Amazon Linux 2023
   - **Instance Type**: t2.micro
   - **VPC**: Select your VPC
   - **Subnet**: Any subnet
   - **Security Group**: Allow SSH (22) inbound
3. Configure **Instance B** (Target Server):
   - **Name**: Instance B
   - **AMI**: Amazon Linux 2023
   - **Instance Type**: t2.micro
   - **VPC**: Same VPC as Instance A
   - **Subnet**: Any subnet
   - **Security Group**: Allow SSH (22) and HTTP (80) inbound
4. Launch both instances

### Step 2: Install httpd on Instance B

Connect to Instance B and install Apache web server:

```bash
# Connect to Instance B
ssh -i your-key.pem ec2-user@[INSTANCE-B-IP]

# Update system packages
sudo yum update -y

# Install Apache httpd
sudo yum install httpd -y

# Start httpd service
sudo systemctl start httpd
sudo systemctl enable httpd

# Create test page
echo "<h1>Hello from Instance B</h1>" | sudo tee /var/www/html/index.html

# Verify httpd is running
sudo systemctl status httpd
curl localhost
```

### Step 3: Install Troubleshooting Tools on Instance A

Connect to Instance A and install required tools:

```bash
# Connect to Instance A
ssh -i your-key.pem ec2-user@[INSTANCE-A-IP]

# Update system packages
sudo yum update -y

# Install traceroute
sudo yum install traceroute -y

# Install telnet
sudo yum install telnet -y

# Install bind-utils (includes dig)
sudo yum install bind-utils -y

# Install tcpdump
sudo yum install tcpdump -y

# Verify installations
traceroute --version
telnet --version
dig -v
tcpdump --version
```

**Note**: `ifconfig`, `netstat`, and `curl` are typically pre-installed on Amazon Linux.

### Step 4: Running traceroute

Track the network path to Instance B:

```bash
# From Instance A, run traceroute to Instance B
traceroute [INSTANCE-B-PRIVATE-IP]

# Expected output: Shows hops from Instance A to Instance B
# Within same VPC, typically 1-2 hops

# Traceroute to external destination
traceroute google.com

# Traceroute with ICMP instead of UDP
sudo traceroute -I [INSTANCE-B-PRIVATE-IP]

# Limit maximum hops
traceroute -m 10 [INSTANCE-B-PRIVATE-IP]
```

**Analysis**:
- **Hop count**: Number of routers between source and destination
- **Latency**: RTT for each hop (3 measurements per hop)
- **Timeouts**: Asterisks (*) indicate packet loss or filtered ICMP
- **Within VPC**: Typically very low latency (<1ms)

### Step 5: Running ifconfig

View network interface configuration:

```bash
# Display all interfaces
ifconfig

# Display specific interface
ifconfig eth0

# Display brief information
ifconfig -s

# Expected output includes:
# - IP address (inet)
# - Netmask
# - MAC address (ether)
# - MTU size
# - RX/TX packet counts
# - Errors and drops
```

**Key Metrics to Check**:
- **RX errors**: Received packet errors (should be 0 or very low)
- **TX errors**: Transmitted packet errors (should be 0 or very low)
- **RX dropped**: Dropped received packets (indicates buffer issues)
- **TX dropped**: Dropped transmitted packets (indicates congestion)
- **Collisions**: Ethernet collisions (should be 0 in switched networks)

### Step 6: Running telnet

Test TCP connectivity to Instance B:

```bash
# Test HTTP port (80) on Instance B
telnet [INSTANCE-B-PRIVATE-IP] 80

# If successful, you'll see:
# Trying [IP]...
# Connected to [IP].
# Escape character is '^]'.

# Type HTTP request manually:
GET / HTTP/1.1
Host: [INSTANCE-B-PRIVATE-IP]
[Press Enter twice]

# You should see HTTP response with HTML content

# Exit telnet: Ctrl+] then type 'quit'

# Test closed port (should fail)
telnet [INSTANCE-B-PRIVATE-IP] 8080

# Test SSH port
telnet [INSTANCE-B-PRIVATE-IP] 22
```

**Interpreting Results**:
- **Connected**: Port is open and accepting connections
- **Connection refused**: Port is closed (no service listening)
- **Connection timeout**: Firewall blocking or host unreachable

### Step 7: Running netstat

Monitor network connections and listening ports:

```bash
# Show all listening TCP and UDP ports (numeric)
sudo netstat -tuln

# Show all connections (listening and established)
sudo netstat -an

# Show listening ports with process information
sudo netstat -tulnp

# Show established connections
netstat -an | grep ESTABLISHED

# Show routing table
netstat -r

# Show interface statistics
netstat -i

# Show protocol statistics
netstat -s
```

**Common States**:
- **LISTEN**: Service waiting for connections
- **ESTABLISHED**: Active connection
- **TIME_WAIT**: Connection closed, waiting for final packets
- **CLOSE_WAIT**: Remote end closed connection
- **SYN_SENT**: Attempting to establish connection

**Example Analysis**:
```bash
# Find what's listening on port 80
sudo netstat -tulnp | grep :80

# Expected output:
# tcp  0  0  0.0.0.0:80  0.0.0.0:*  LISTEN  1234/httpd

# Count established connections
netstat -an | grep ESTABLISHED | wc -l
```

### Step 8: Running curl

Test HTTP connectivity to Instance B:

```bash
# Basic HTTP request
curl http://[INSTANCE-B-PRIVATE-IP]

# Expected output: <h1>Hello from Instance B</h1>

# Verbose output (shows connection details)
curl -v http://[INSTANCE-B-PRIVATE-IP]

# Headers only
curl -I http://[INSTANCE-B-PRIVATE-IP]

# Show response time
curl -w "\nTime: %{time_total}s\n" http://[INSTANCE-B-PRIVATE-IP]

# Test with timeout
curl --connect-timeout 5 http://[INSTANCE-B-PRIVATE-IP]

# Follow redirects
curl -L http://[INSTANCE-B-PRIVATE-IP]

# Save output to file
curl -o output.html http://[INSTANCE-B-PRIVATE-IP]
```

**Verbose Output Analysis**:
```
* Trying [IP]...
* Connected to [IP] ([IP]) port 80 (#0)
> GET / HTTP/1.1
> Host: [IP]
> User-Agent: curl/7.88.1
> Accept: */*
> 
< HTTP/1.1 200 OK
< Date: Mon, 01 Jan 2024 12:00:00 GMT
< Server: Apache/2.4.57 (Amazon Linux)
< Content-Length: 32
< Content-Type: text/html
< 
<h1>Hello from Instance B</h1>
```

**HTTP Status Codes**:
- **200 OK**: Successful request
- **301/302**: Redirect
- **403 Forbidden**: Access denied
- **404 Not Found**: Resource doesn't exist
- **500 Internal Server Error**: Server-side error
- **503 Service Unavailable**: Server overloaded or down

### Step 9: Running dig

Perform DNS lookups:

```bash
# Basic DNS lookup
dig google.com

# Short output (IP only)
dig +short google.com

# Query specific record type
dig google.com MX
dig google.com NS
dig google.com TXT

# Query specific nameserver
dig @8.8.8.8 google.com

# Reverse DNS lookup
dig -x 8.8.8.8

# Trace DNS delegation path
dig +trace google.com

# Query all record types
dig google.com ANY

# Check DNS response time
dig google.com | grep "Query time"
```

**Output Sections**:
- **QUESTION**: Query being asked
- **ANSWER**: DNS response records
- **AUTHORITY**: Authoritative nameservers
- **ADDITIONAL**: Additional information
- **Query time**: DNS resolution time
- **SERVER**: DNS server used

**Troubleshooting DNS Issues**:
```bash
# Check if DNS is working
dig google.com

# If fails, try different nameserver
dig @8.8.8.8 google.com

# Check local DNS configuration
cat /etc/resolv.conf

# Test Route 53 private hosted zone
dig www.example.internal
```

### Step 10: Running tcpdump

Capture and analyze network packets:

```bash
# Capture packets on eth0 interface
sudo tcpdump -i eth0

# Capture HTTP traffic (port 80)
sudo tcpdump -i eth0 port 80

# Capture traffic to/from Instance B
sudo tcpdump -i eth0 host [INSTANCE-B-PRIVATE-IP]

# Capture TCP traffic only
sudo tcpdump -i eth0 tcp

# Capture with detailed output
sudo tcpdump -i eth0 -v port 80

# Capture and show packet contents
sudo tcpdump -i eth0 -X port 80

# Capture limited number of packets
sudo tcpdump -i eth0 -c 10 port 80

# Save capture to file
sudo tcpdump -i eth0 -w capture.pcap port 80

# Read from capture file
sudo tcpdump -r capture.pcap
```

**Analyzing TCP Three-Way Handshake**:

```bash
# In one terminal on Instance A, start tcpdump
sudo tcpdump -i eth0 -n host [INSTANCE-B-PRIVATE-IP] and port 80

# In another terminal on Instance A, make HTTP request
curl http://[INSTANCE-B-PRIVATE-IP]

# Observe tcpdump output:
# 1. SYN: Instance A → Instance B (Flags [S])
# 2. SYN-ACK: Instance B → Instance A (Flags [S.])
# 3. ACK: Instance A → Instance B (Flags [.])
# 4. HTTP request: Instance A → Instance B (Flags [P.])
# 5. HTTP response: Instance B → Instance A (Flags [P.])
# 6. FIN: Connection termination (Flags [F.])
```

**TCP Flags**:
- **[S]**: SYN (synchronize)
- **[.]**: ACK (acknowledge)
- **[S.]**: SYN-ACK
- **[P.]**: PSH-ACK (push data)
- **[F.]**: FIN (finish/close)
- **[R]**: RST (reset)

**Example tcpdump Output**:
```
12:00:00.123456 IP 10.0.1.100.54321 > 10.0.1.200.80: Flags [S], seq 1234567890, win 65535
12:00:00.123789 IP 10.0.1.200.80 > 10.0.1.100.54321: Flags [S.], seq 9876543210, ack 1234567891, win 65535
12:00:00.123890 IP 10.0.1.100.54321 > 10.0.1.200.80: Flags [.], ack 1, win 65535
```

## Scripts and Configurations

### Network Diagnostic Script

A comprehensive script to run all troubleshooting commands:

```bash
#!/bin/bash
# network-diagnostics.sh
# Comprehensive network troubleshooting script

TARGET_HOST=$1

if [ -z "$TARGET_HOST" ]; then
    echo "Usage: $0 <target-host>"
    exit 1
fi

echo "=== Network Diagnostics for $TARGET_HOST ==="
echo ""

echo "1. Interface Configuration:"
ifconfig | grep -A 7 "^eth0"
echo ""

echo "2. Traceroute:"
traceroute -m 10 $TARGET_HOST
echo ""

echo "3. DNS Lookup:"
dig +short $TARGET_HOST
echo ""

echo "4. TCP Port 80 Test:"
timeout 5 telnet $TARGET_HOST 80 2>&1 | head -n 3
echo ""

echo "5. HTTP Connectivity:"
curl -I -s --connect-timeout 5 http://$TARGET_HOST | head -n 5
echo ""

echo "6. Active Connections:"
netstat -an | grep ESTABLISHED | head -n 10
echo ""

echo "7. Listening Ports:"
sudo netstat -tulnp | grep LISTEN
echo ""

echo "=== Diagnostics Complete ==="
```

### Quick Port Scanner

Script to test common ports:

```bash
#!/bin/bash
# port-scanner.sh
# Test common ports on target host

TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <target-host>"
    exit 1
fi

PORTS=(22 80 443 3306 5432 6379 8080)

echo "Scanning common ports on $TARGET..."
echo ""

for PORT in "${PORTS[@]}"; do
    timeout 2 bash -c "echo >/dev/tcp/$TARGET/$PORT" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Port $PORT: OPEN"
    else
        echo "Port $PORT: CLOSED"
    fi
done
```

### DNS Troubleshooting Script

```bash
#!/bin/bash
# dns-check.sh
# Comprehensive DNS troubleshooting

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

echo "=== DNS Troubleshooting for $DOMAIN ==="
echo ""

echo "1. A Record:"
dig +short $DOMAIN A
echo ""

echo "2. AAAA Record (IPv6):"
dig +short $DOMAIN AAAA
echo ""

echo "3. MX Records:"
dig +short $DOMAIN MX
echo ""

echo "4. NS Records:"
dig +short $DOMAIN NS
echo ""

echo "5. TXT Records:"
dig $DOMAIN TXT
echo ""

echo "6. DNS Resolution Time:"
dig $DOMAIN | grep "Query time"
echo ""

echo "7. Nameserver Used:"
dig $DOMAIN | grep "SERVER"
echo ""

echo "=== DNS Check Complete ==="
```

### Packet Capture Script

```bash
#!/bin/bash
# capture-traffic.sh
# Capture network traffic for analysis

INTERFACE="eth0"
DURATION=60
OUTPUT="capture-$(date +%Y%m%d-%H%M%S).pcap"

echo "Capturing traffic on $INTERFACE for $DURATION seconds..."
echo "Output file: $OUTPUT"
echo ""

sudo tcpdump -i $INTERFACE -w $OUTPUT -G $DURATION -W 1

echo ""
echo "Capture complete. Analyze with:"
echo "  sudo tcpdump -r $OUTPUT"
echo "  or download and open in Wireshark"
```

## Troubleshooting

### Common Issues

**Issue**: traceroute shows all asterisks (*)  
**Solution**:
- ICMP/UDP packets may be blocked by firewall
- Try `traceroute -I` (ICMP) or `traceroute -T` (TCP)
- Check security group rules
- Some routers don't respond to traceroute probes

**Issue**: ifconfig command not found  
**Solution**:
- Use `ip addr show` instead (modern replacement)
- Install net-tools: `sudo yum install net-tools -y`
- Amazon Linux 2023 uses `ip` command by default

**Issue**: telnet connection refused  
**Solution**:
- Verify service is running on target
- Check security group allows traffic on port
- Verify network ACLs allow traffic
- Confirm correct IP address and port

**Issue**: netstat shows no listening ports  
**Solution**:
- Run with sudo: `sudo netstat -tulnp`
- Use `ss -tulnp` (modern replacement)
- Verify services are actually running
- Check if services are bound to specific IPs

**Issue**: curl connection timeout  
**Solution**:
- Check security group rules
- Verify target instance is running
- Test with telnet first
- Check network ACLs
- Verify routing table

**Issue**: dig returns SERVFAIL  
**Solution**:
- DNS server cannot resolve domain
- Try different nameserver: `dig @8.8.8.8 domain.com`
- Check /etc/resolv.conf configuration
- Verify DNS server is reachable
- Check for DNS server issues

**Issue**: tcpdump permission denied  
**Solution**:
- Run with sudo: `sudo tcpdump`
- Add user to pcap group (not recommended for security)
- Use `-i any` to capture on all interfaces
- Check interface name with `ifconfig` or `ip link`

**Issue**: tcpdump shows no packets  
**Solution**:
- Verify correct interface: `tcpdump -D` to list interfaces
- Check filter syntax is correct
- Ensure traffic is actually flowing
- Try without filters first
- Use `-n` to avoid DNS lookups

### Debugging Commands

```bash
# Check interface status
ip link show

# Check IP configuration
ip addr show

# Check routing table
ip route show

# Test basic connectivity
ping -c 4 [TARGET-IP]

# Check DNS configuration
cat /etc/resolv.conf

# View system logs for network issues
sudo journalctl -u NetworkManager -n 50

# Check for dropped packets
netstat -i

# View iptables rules (firewall)
sudo iptables -L -n -v

# Check SELinux status (may block connections)
getenforce

# View security group rules (AWS CLI)
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Check instance metadata
curl http://169.254.169.254/latest/meta-data/local-ipv4
```

### Verification Checklist

- [ ] Both instances are running
- [ ] httpd service is running on Instance B
- [ ] Security groups allow required traffic
- [ ] Network ACLs allow traffic (default allows all)
- [ ] Instances are in same VPC
- [ ] traceroute shows path to destination
- [ ] ifconfig shows interface is UP
- [ ] telnet can connect to port 80
- [ ] netstat shows httpd listening on port 80
- [ ] curl returns HTTP response
- [ ] dig resolves DNS names
- [ ] tcpdump captures packets successfully

## Cost Considerations

**EC2 Costs**:
- t2.micro instances: Free Tier eligible (750 hours/month first year)
- After Free Tier: ~$0.0116/hour per instance
- 2 instances: ~$17/month

**Data Transfer**:
- Within same AZ: Free
- Between AZs: $0.01/GB
- To internet: $0.09/GB (first 10TB/month)

**VPC Costs**:
- VPC itself: Free
- VPC endpoints: $0.01/hour + $0.01/GB (if used)
- NAT Gateway: $0.045/hour + $0.045/GB (if used)

**Monthly Cost Estimate** (after Free Tier):
- 2 x t2.micro instances: ~$17/month
- Data transfer (minimal): <$1/month
- **Total**: ~$18/month

**Cost Optimization Tips**:
- Stop instances when not in use
- Use Free Tier for learning
- Delete resources after lab completion
- Use spot instances for non-critical testing

## Next Steps

### Enhancements

1. **Advanced tcpdump**: Capture and analyze complex traffic patterns
2. **Wireshark Analysis**: Download pcap files and analyze in Wireshark
3. **Network Performance**: Use iperf to measure bandwidth
4. **MTR (My Traceroute)**: Combine ping and traceroute functionality
5. **nmap**: Advanced port scanning and service detection
6. **ss Command**: Modern replacement for netstat with more features
7. **iftop**: Real-time bandwidth monitoring
8. **nethogs**: Per-process bandwidth monitoring

### Related Labs

- **VPC Connectivity Troubleshooting**: Advanced VPC networking issues
- **Network Access Analyzer**: Automated network path analysis
- **Route 53 DNS Configuration**: DNS setup and management
- **Elastic Load Balancing**: Load balancer troubleshooting
- **VPN and Direct Connect**: Hybrid connectivity troubleshooting

### Real-World Use Cases

- **Production Incidents**: Diagnose connectivity issues in live environments
- **Performance Tuning**: Identify network bottlenecks and latency
- **Security Analysis**: Detect unauthorized connections and traffic
- **Capacity Planning**: Monitor network utilization and growth
- **Compliance Auditing**: Verify network configurations and policies
- **Migration Validation**: Confirm connectivity after infrastructure changes

### Additional Tools to Explore

**Modern Alternatives**:
- `ip` command (replaces ifconfig)
- `ss` command (replaces netstat)
- `nmap` (advanced port scanning)
- `mtr` (combines ping and traceroute)
- `iperf3` (network performance testing)
- `ngrep` (network grep for packet content)
- `tcpflow` (TCP flow analysis)

**Monitoring Tools**:
- `iftop` (real-time bandwidth by connection)
- `nethogs` (bandwidth by process)
- `vnstat` (network statistics over time)
- `bmon` (bandwidth monitor)
- `iptraf-ng` (interactive network monitor)

**AWS-Specific Tools**:
- VPC Flow Logs (network traffic logging)
- VPC Reachability Analyzer (path analysis)
- Network Access Analyzer (security analysis)
- CloudWatch Network Monitoring (metrics and alarms)
- AWS X-Ray (distributed tracing)

## Certification Alignment

This lab aligns with the following AWS certification topics:

**AWS Certified Solutions Architect - Associate**:
- Domain 1: Design Resilient Architectures (Network troubleshooting)
- Domain 2: Design High-Performing Architectures (Network performance)
- Domain 3: Design Secure Applications (Security group troubleshooting)

**AWS Certified SysOps Administrator - Associate**:
- Domain 1: Monitoring, Logging, and Remediation (Network monitoring)
- Domain 2: Reliability and Business Continuity (Connectivity troubleshooting)
- Domain 3: Deployment, Provisioning, and Automation (Network configuration)
- Domain 6: Networking and Content Delivery (VPC troubleshooting)

**AWS Certified Advanced Networking - Specialty**:
- Domain 1: Network Design (Network architecture troubleshooting)
- Domain 2: Network Implementation (Tool usage and configuration)
- Domain 3: Network Management and Operation (Troubleshooting methodology)
- Domain 4: Network Security, Compliance, and Governance (Security analysis)

**AWS Certified Security - Specialty**:
- Domain 2: Logging and Monitoring (Network traffic analysis)
- Domain 3: Infrastructure Security (Network security troubleshooting)

## Resources

### AWS Documentation
- [VPC Troubleshooting](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-troubleshooting.html)
- [EC2 Network Troubleshooting](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/TroubleshootingInstancesConnecting.html)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [VPC Reachability Analyzer](https://docs.aws.amazon.com/vpc/latest/reachability/)
- [Security Group Rules](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)

### Tool Documentation
- [traceroute Man Page](https://linux.die.net/man/8/traceroute)
- [tcpdump Man Page](https://www.tcpdump.org/manpages/tcpdump.1.html)
- [dig Man Page](https://linux.die.net/man/1/dig)
- [curl Man Page](https://curl.se/docs/manpage.html)
- [netstat Man Page](https://linux.die.net/man/8/netstat)

### Learning Resources
- [TCP/IP Illustrated](https://www.amazon.com/TCP-Illustrated-Vol-Addison-Wesley-Professional/dp/0201633469)
- [Wireshark Network Analysis](https://www.wireshark.org/docs/)
- [Linux Network Administrators Guide](https://tldp.org/LDP/nag2/index.html)
- [AWS Networking Fundamentals](https://aws.amazon.com/training/course-descriptions/networking/)

## Tags

`AWS` `EC2` `VPC` `Networking` `Troubleshooting` `traceroute` `ifconfig` `telnet` `netstat` `curl` `dig` `tcpdump` `TCP-IP` `DNS` `Packet-Capture` `Network-Analysis` `Security-Groups` `Connectivity` `Network-Diagnostics` `SysOps`

---

**Lab Completed**: AWS Cloud Fundamentals  
**Domain**: Networking  
**Complexity**: Intermediate  
**Last Updated**: 2024
