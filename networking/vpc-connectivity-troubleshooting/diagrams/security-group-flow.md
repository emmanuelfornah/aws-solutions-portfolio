# Security Group Flow Diagrams

## Initial Configuration (Noncompliant)

### SSH Access Flow - Before Remediation

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet                                │
│                      (0.0.0.0/0)                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ SSH (Port 22)
                         │ ✓ ALLOWED (Noncompliant)
                         ↓
              ┌──────────────────────┐
              │   AppServerSG        │
              │  Inbound Rules:      │
              │  SSH from 0.0.0.0/0  │
              └──────────┬───────────┘
                         │
                         ↓
              ┌──────────────────────┐
              │    App Server        │
              │  (Private Subnet)    │
              │  10.0.2.20           │
              └──────────────────────┘

Issue: Any IP address can SSH to App Server
Risk: Unauthorized access, brute force attacks
```

### Multiple Access Paths

```
┌──────────────────┐
│  Bastion Host    │
│  10.0.1.10       │──┐
│  BastionHostSG   │  │
└──────────────────┘  │
                      │ SSH (Port 22)
┌──────────────────┐  │ ✓ ALLOWED
│  Public Server   │  │
│  10.0.1.20       │──┤
│  PublicServerSG  │  │
└──────────────────┘  │
                      │
┌──────────────────┐  │
│  Any Internet    │  │
│  Host            │──┘
│  0.0.0.0/0       │
└──────────────────┘
                      │
                      ↓
           ┌──────────────────────┐
           │   AppServerSG        │
           │  Inbound Rules:      │
           │  SSH from 0.0.0.0/0  │
           └──────────┬───────────┘
                      │
                      ↓
           ┌──────────────────────┐
           │    App Server        │
           │  (Private Subnet)    │
           │  10.0.2.20           │
           └──────────────────────┘

Problem: Three different sources can access App Server
Expected: Only Bastion Host should have access
```

## After Task 3: IP-Based Restriction

### SSH Access Flow - IP Restricted

```
┌──────────────────┐
│  Bastion Host    │
│  10.0.1.10       │
│  BastionHostSG   │
└────────┬─────────┘
         │
         │ SSH (Port 22)
         │ Source: 10.0.1.10
         │ ✓ ALLOWED (Compliant)
         ↓
┌──────────────────────┐
│   AppServerSG        │
│  Inbound Rules:      │
│  SSH from            │
│  10.0.1.10/32        │
└──────────┬───────────┘
           │
           ↓
┌──────────────────────┐
│    App Server        │
│  (Private Subnet)    │
│  10.0.2.20           │
└──────────────────────┘


┌──────────────────┐
│  Public Server   │
│  10.0.1.20       │
│  PublicServerSG  │
└────────┬─────────┘
         │
         │ SSH (Port 22)
         │ Source: 10.0.1.20
         │ ✗ DENIED (Compliant)
         ↓
┌──────────────────────┐
│   AppServerSG        │
│  Inbound Rules:      │
│  SSH from            │
│  10.0.1.10/32        │
│  (No match)          │
└──────────────────────┘

Improvement: Only Bastion Host IP can access
Limitation: Must update rule if Bastion IP changes
```

## After Task 4: Security Group Referencing

### SSH Access Flow - Security Group Based

```
┌──────────────────┐
│  Bastion Host    │
│  10.0.1.10       │
│  BastionHostSG   │◄─────┐
└────────┬─────────┘      │
         │                │
         │ SSH (Port 22)  │
         │ Has: BastionHostSG
         │ ✓ ALLOWED      │
         ↓                │
┌──────────────────────┐  │
│   AppServerSG        │  │
│  Inbound Rules:      │  │
│  SSH from            │  │
│  sg-xxxxx ───────────┼──┘
│  (BastionHostSG)     │
└──────────┬───────────┘
           │
           ↓
┌──────────────────────┐
│    App Server        │
│  (Private Subnet)    │
│  10.0.2.20           │
└──────────────────────┘


┌──────────────────┐
│  Public Server   │
│  10.0.1.20       │
│  PublicServerSG  │
└────────┬─────────┘
         │
         │ SSH (Port 22)
         │ Has: PublicServerSG only
         │ ✗ DENIED
         ↓
┌──────────────────────┐
│   AppServerSG        │
│  Inbound Rules:      │
│  SSH from            │
│  sg-xxxxx            │
│  (BastionHostSG)     │
│  (No match)          │
└──────────────────────┘

Benefit: Access based on security group membership
Dynamic: Add/remove instances without IP updates
```

### After Adding Public Server to BastionHostSG

```
┌──────────────────┐
│  Public Server   │
│  10.0.1.20       │
│  PublicServerSG  │
│  BastionHostSG   │◄─────┐
└────────┬─────────┘      │
         │                │
         │ SSH (Port 22)  │
         │ Has: BastionHostSG
         │ ✓ ALLOWED      │
         ↓                │
┌──────────────────────┐  │
│   AppServerSG        │  │
│  Inbound Rules:      │  │
│  SSH from            │  │
│  sg-xxxxx ───────────┼──┘
│  (BastionHostSG)     │
└──────────┬───────────┘
           │
           ↓
┌──────────────────────┐
│    App Server        │
│  (Private Subnet)    │
│  10.0.2.20           │
└──────────────────────┘

Key Insight: Public Server now has access because it has BastionHostSG
No rule changes needed - dynamic membership
```

## Apache Server Challenge

### Initial State (Broken)

```
┌─────────────────────────────────────────┐
│            Internet                     │
│         (Web Browser)                   │
└────────────────┬────────────────────────┘
                 │
                 │ HTTP (Port 80)
                 │ ✗ DENIED
                 ↓
      ┌──────────────────────┐
      │  ApacheServerSG      │
      │  Inbound Rules:      │
      │  SSH (22) only       │
      │  NO HTTP RULE!       │
      └──────────┬───────────┘
                 │
                 ✗ Blocked
                 │
      ┌──────────────────────┐
      │   Apache Server      │
      │  (Public Subnet)     │
      │  Apache running ✓    │
      │  Public IP: x.x.x.x  │
      └──────────────────────┘

Problem: Security group missing HTTP inbound rule
Symptom: Connection timeout or refused
```

### After Fix (Working)

```
┌─────────────────────────────────────────┐
│            Internet                     │
│         (Web Browser)                   │
└────────────────┬────────────────────────┘
                 │
                 │ HTTP (Port 80)
                 │ ✓ ALLOWED
                 ↓
      ┌──────────────────────┐
      │  ApacheServerSG      │
      │  Inbound Rules:      │
      │  SSH (22)            │
      │  HTTP (80) ✓         │
      └──────────┬───────────┘
                 │
                 ✓ Allowed
                 ↓
      ┌──────────────────────┐
      │   Apache Server      │
      │  (Public Subnet)     │
      │  Apache running ✓    │
      │  Public IP: x.x.x.x  │
      └──────────────────────┘
                 │
                 ↓
      ┌──────────────────────┐
      │   HTTP Response      │
      │   Apache Test Page   │
      └──────────────────────┘

Solution: Added HTTP inbound rule to security group
Result: Web traffic now allowed
```

## Stateful Nature of Security Groups

### Outbound Connection (Stateful Behavior)

```
Request Flow:
┌──────────────────┐
│  App Server      │
│  10.0.2.20       │
└────────┬─────────┘
         │
         │ 1. Outbound HTTP Request
         │    Source: 10.0.2.20:random_port
         │    Dest: 203.0.113.5:80
         ↓
┌──────────────────────┐
│   AppServerSG        │
│  Outbound Rules:     │
│  All traffic         │
│  ✓ ALLOWED           │
└──────────┬───────────┘
           │
           ↓
┌──────────────────────┐
│   Internet           │
│   203.0.113.5:80     │
└──────────┬───────────┘
           │
           │ 2. Return HTTP Response
           │    Source: 203.0.113.5:80
           │    Dest: 10.0.2.20:random_port
           ↓
┌──────────────────────┐
│   AppServerSG        │
│  Inbound Rules:      │
│  SSH only            │
│  ✓ ALLOWED           │
│  (Stateful - return  │
│   traffic auto-      │
│   allowed)           │
└──────────┬───────────┘
           │
           ↓
┌──────────────────────┐
│  App Server          │
│  Receives response   │
└──────────────────────┘

Key Point: Return traffic automatically allowed
No inbound HTTP rule needed for responses
```

## Multi-Tier Application Pattern

### Three-Tier Architecture with Security Group Referencing

```
┌─────────────────────────────────────────┐
│            Internet                     │
└────────────────┬────────────────────────┘
                 │
                 │ HTTPS (443)
                 ↓
      ┌──────────────────────┐
      │   LoadBalancerSG     │
      │  In: HTTPS from      │
      │      0.0.0.0/0       │
      └──────────┬───────────┘
                 │
                 │ HTTP (80)
                 ↓
      ┌──────────────────────┐
      │   WebServerSG        │
      │  In: HTTP from       │
      │      LoadBalancerSG  │◄─────┐
      └──────────┬───────────┘      │
                 │                   │
                 │ App Protocol      │
                 │ (Port 8080)       │
                 ↓                   │
      ┌──────────────────────┐      │
      │   AppServerSG        │      │
      │  In: 8080 from       │      │
      │      WebServerSG     │◄──┐  │
      └──────────┬───────────┘   │  │
                 │                │  │
                 │ MySQL           │  │
                 │ (Port 3306)     │  │
                 ↓                │  │
      ┌──────────────────────┐   │  │
      │   DatabaseSG         │   │  │
      │  In: 3306 from       │   │  │
      │      AppServerSG     │◄──┘  │
      └──────────────────────┘      │
                                    │
Benefits:                           │
- Each tier only accepts from       │
  previous tier                     │
- Security group references         │
  enable dynamic scaling            │
- No IP address management          │
- Clear security boundaries         │
```

## Troubleshooting Flow Chart

```
Connection Failed?
       │
       ↓
┌─────────────────┐
│ Check: Is app   │
│ running?        │
└────┬────────────┘
     │
     ├─ No → Start application
     │
     └─ Yes
         │
         ↓
┌─────────────────┐
│ Check: Security │
│ Group Inbound   │
│ Rules           │
└────┬────────────┘
     │
     ├─ Port allowed? ──No──→ Add rule
     │                         │
     ├─ Source correct? ─No──→ Fix source
     │                         │
     └─ Yes
         │
         ↓
┌─────────────────┐
│ Check: Network  │
│ ACLs            │
└────┬────────────┘
     │
     ├─ Inbound OK? ──No──→ Fix NACL
     │                       │
     ├─ Outbound OK? ─No──→ Fix NACL
     │                       │
     └─ Yes
         │
         ↓
┌─────────────────┐
│ Check: Route    │
│ Tables          │
└────┬────────────┘
     │
     ├─ Route exists? ─No──→ Add route
     │                        │
     └─ Yes
         │
         ↓
┌─────────────────┐
│ Check: OS       │
│ Firewall        │
└────┬────────────┘
     │
     └─ iptables/Windows Firewall
```

## Key Concepts Visualization

### Security Group vs Network ACL

```
┌─────────────────────────────────────────────────────────┐
│                    VPC Subnet                           │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Network ACL (Subnet Level)               │  │
│  │  - Stateless (must allow return traffic)         │  │
│  │  - Rules processed in order                      │  │
│  │  - Allow and Deny rules                          │  │
│  │  - Applies to all instances in subnet            │  │
│  └────────────────────┬─────────────────────────────┘  │
│                       │                                 │
│                       ↓                                 │
│            ┌──────────────────────┐                    │
│            │  Security Group      │                    │
│            │  (Instance Level)    │                    │
│            │  - Stateful          │                    │
│            │  - All rules eval    │                    │
│            │  - Allow only        │                    │
│            │  - Per instance      │                    │
│            └──────────┬───────────┘                    │
│                       │                                 │
│                       ↓                                 │
│            ┌──────────────────────┐                    │
│            │    EC2 Instance      │                    │
│            └──────────────────────┘                    │
│                                                         │
└─────────────────────────────────────────────────────────┘

Defense in Depth: Both layers provide security
Most issues: Security Group misconfigurations
```
