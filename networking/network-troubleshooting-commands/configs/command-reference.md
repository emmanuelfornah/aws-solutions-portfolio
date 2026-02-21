# Network Troubleshooting Commands - Quick Reference

## Command Overview

| Command | Purpose | Layer | Common Use |
|---------|---------|-------|------------|
| `traceroute` | Path analysis | Network | Find routing issues |
| `ifconfig` | Interface config | Data Link | Check IP/MAC address |
| `telnet` | Port testing | Transport | Test TCP connectivity |
| `netstat` | Connection stats | Transport | View active connections |
| `curl` | HTTP testing | Application | Test web services |
| `dig` | DNS lookup | Application | Troubleshoot DNS |
| `tcpdump` | Packet capture | All layers | Deep packet analysis |

## Quick Command Reference

### traceroute

```bash
# Basic usage
traceroute <host>

# Limit hops
traceroute -m 10 <host>

# Use ICMP instead of UDP
sudo traceroute -I <host>

# Use TCP
sudo traceroute -T -p 80 <host>
```

### ifconfig / ip

```bash
# Show all interfaces
ifconfig
ip addr show

# Show specific interface
ifconfig eth0
ip addr show eth0

# Show brief info
ifconfig -s
ip -br addr

# Show statistics
netstat -i
ip -s link
```

### telnet

```bash
# Test port connectivity
telnet <host> <port>

# Common examples
telnet example.com 80    # HTTP
telnet example.com 443   # HTTPS
telnet example.com 22    # SSH
telnet example.com 3306  # MySQL

# Exit telnet
Ctrl+]
quit
```

### netstat / ss

```bash
# Show listening ports
sudo netstat -tulnp
sudo ss -tulnp

# Show all connections
netstat -an
ss -an

# Show established connections
netstat -an | grep ESTABLISHED
ss -an | grep ESTAB

# Show routing table
netstat -r
ip route show

# Show interface statistics
netstat -i
ip -s link
```

### curl

```bash
# Basic GET request
curl http://example.com

# Verbose output
curl -v http://example.com

# Headers only
curl -I http://example.com

# Follow redirects
curl -L http://example.com

# Set timeout
curl --connect-timeout 5 http://example.com

# Save to file
curl -o output.html http://example.com

# Show timing
curl -w "\nTime: %{time_total}s\n" http://example.com

# Custom headers
curl -H "Authorization: Bearer token" http://example.com

# POST request
curl -X POST -d "data=value" http://example.com
```

### dig

```bash
# Basic lookup
dig example.com

# Short output (IP only)
dig +short example.com

# Specific record types
dig example.com A      # IPv4
dig example.com AAAA   # IPv6
dig example.com MX     # Mail
dig example.com NS     # Nameservers
dig example.com TXT    # Text records

# Query specific nameserver
dig @8.8.8.8 example.com

# Reverse lookup
dig -x 8.8.8.8

# Trace delegation
dig +trace example.com

# Show query time
dig example.com | grep "Query time"
```

### tcpdump

```bash
# Capture on interface
sudo tcpdump -i eth0

# Capture specific port
sudo tcpdump -i eth0 port 80

# Capture specific host
sudo tcpdump -i eth0 host 10.0.1.100

# Capture TCP only
sudo tcpdump -i eth0 tcp

# Verbose output
sudo tcpdump -i eth0 -v

# Show packet contents (hex)
sudo tcpdump -i eth0 -X

# Limit packet count
sudo tcpdump -i eth0 -c 10

# Save to file
sudo tcpdump -i eth0 -w capture.pcap

# Read from file
sudo tcpdump -r capture.pcap

# Complex filters
sudo tcpdump -i eth0 'tcp port 80 and host 10.0.1.100'
sudo tcpdump -i eth0 'tcp[tcpflags] & tcp-syn != 0'
```

## Common Troubleshooting Workflows

### Test Web Server Connectivity

```bash
# 1. Check interface
ifconfig eth0

# 2. Test network path
traceroute <server-ip>

# 3. Test port
telnet <server-ip> 80

# 4. Test HTTP
curl -v http://<server-ip>

# 5. Capture traffic
sudo tcpdump -i eth0 host <server-ip> and port 80
```

### Troubleshoot DNS Issues

```bash
# 1. Check DNS config
cat /etc/resolv.conf

# 2. Test resolution
dig example.com

# 3. Try different nameserver
dig @8.8.8.8 example.com

# 4. Check DNS timing
dig example.com | grep "Query time"

# 5. Trace delegation
dig +trace example.com
```

### Diagnose Connection Problems

```bash
# 1. Check listening ports
sudo netstat -tulnp

# 2. Check active connections
netstat -an | grep ESTABLISHED

# 3. Test connectivity
telnet <host> <port>

# 4. Capture handshake
sudo tcpdump -i eth0 host <host> and port <port>

# 5. Check for errors
ifconfig | grep errors
```

### Analyze Network Performance

```bash
# 1. Check interface stats
netstat -i

# 2. Trace route with timing
traceroute <host>

# 3. Test HTTP timing
curl -w "@curl-format.txt" http://<host>

# 4. Capture and analyze
sudo tcpdump -i eth0 -w capture.pcap
sudo tcpdump -r capture.pcap -v
```

## TCP Flags Reference

| Flag | Symbol | Meaning |
|------|--------|---------|
| SYN | S | Synchronize (start connection) |
| ACK | . | Acknowledge |
| PSH | P | Push data |
| FIN | F | Finish (close connection) |
| RST | R | Reset (abort connection) |
| URG | U | Urgent |

### Common Flag Combinations

- `[S]` - SYN (connection request)
- `[S.]` - SYN-ACK (connection accepted)
- `[.]` - ACK (acknowledgment)
- `[P.]` - PSH-ACK (data transfer)
- `[F.]` - FIN-ACK (graceful close)
- `[R]` - RST (connection reset)

## HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | OK | Success |
| 301 | Moved Permanently | Follow redirect |
| 302 | Found (Temporary) | Follow redirect |
| 400 | Bad Request | Check request syntax |
| 401 | Unauthorized | Check authentication |
| 403 | Forbidden | Check permissions |
| 404 | Not Found | Check URL |
| 500 | Internal Server Error | Check server logs |
| 502 | Bad Gateway | Check upstream server |
| 503 | Service Unavailable | Server overloaded |
| 504 | Gateway Timeout | Upstream timeout |

## Common Ports

| Port | Service | Protocol |
|------|---------|----------|
| 20/21 | FTP | TCP |
| 22 | SSH | TCP |
| 23 | Telnet | TCP |
| 25 | SMTP | TCP |
| 53 | DNS | TCP/UDP |
| 80 | HTTP | TCP |
| 110 | POP3 | TCP |
| 143 | IMAP | TCP |
| 443 | HTTPS | TCP |
| 3306 | MySQL | TCP |
| 5432 | PostgreSQL | TCP |
| 6379 | Redis | TCP |
| 8080 | HTTP Alt | TCP |
| 27017 | MongoDB | TCP |

## Troubleshooting Decision Tree

```
Connection Issue?
├─ Can't resolve hostname?
│  └─ Use dig to troubleshoot DNS
├─ Can't reach host?
│  └─ Use traceroute to find routing issue
├─ Can reach host but not port?
│  └─ Use telnet to test port
├─ Port open but service not responding?
│  └─ Use curl to test application
└─ Need detailed analysis?
   └─ Use tcpdump to capture packets
```

## Performance Benchmarks

### Expected Latency (AWS Same Region)

- Same AZ: < 1ms
- Different AZ: 1-2ms
- Same Region: 2-5ms
- Cross Region: 50-200ms (varies by distance)

### DNS Resolution Time

- Cached: < 1ms
- Route 53: 10-50ms
- Public DNS: 20-100ms

### HTTP Response Time

- Static content: 10-50ms
- Dynamic content: 50-200ms
- API calls: 100-500ms
