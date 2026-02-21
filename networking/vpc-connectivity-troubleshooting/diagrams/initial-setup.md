# Initial Setup Diagram

## VPC Architecture - Non-Compliant Configuration

This diagram shows the initial lab setup with the non-compliant security group configuration that allows SSH from anywhere (0.0.0.0/0).

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                  Internet                                    │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │   Internet Gateway      │
                    └────────────┬────────────┘
                                 │
┌────────────────────────────────┼────────────────────────────────────────────┐
│                          VPC A (10.0.0.0/16)                                 │
│                                │                                             │
│  ┌─────────────────────────────┼──────────────────────────────────────────┐ │
│  │         Public Subnet (10.0.10.0/24)                                    │ │
│  │                             │                                           │ │
│  │  ┌──────────────────────────┴───────────────────────────┐              │ │
│  │  │                                                       │              │ │
│  │  │  ┌─────────────────────┐      ┌─────────────────────┴─────────┐    │ │
│  │  │  │   Bastion Host      │      │   Public Server               │    │ │
│  │  │  │  10.0.10.50         │      │   10.0.11.50                  │    │ │
│  │  │  │  [Public IP]        │      │   [Public IP]                 │    │ │
│  │  │  │                     │      │                               │    │ │
│  │  │  │  Security Groups:   │      │  Security Groups:             │    │ │
│  │  │  │  - BastionHostSG    │      │  - PublicServerSG             │    │ │
│  │  │  └─────────────────────┘      └───────────────────────────────┘    │ │
│  │  │                                                                     │ │
│  │  │  ┌──────────────────────────────────────────────────────────────┐  │ │
│  │  │  │   Apache Server                                              │  │ │
│  │  │  │   10.0.10.100                                                │  │ │
│  │  │  │   [Public IP]                                                │  │ │
│  │  │  │                                                              │  │ │
│  │  │  │   Security Groups:                                           │  │ │
│  │  │  │   - ApacheServerSG (⚠️ Missing HTTP rule)                    │  │ │
│  │  │  └──────────────────────────────────────────────────────────────┘  │ │
│  │  │                                                                     │ │
│  └──┼─────────────────────────────────────────────────────────────────────┘ │
│     │                                                                        │
│     │                                                                        │
│  ┌──┼────────────────────────────────────────────────────────────────────┐  │
│  │  │        Private Subnet (10.0.20.0/24)                               │  │
│  │  │                                                                     │  │
│  │  │  ┌──────────────────────────────────────────────────────────────┐  │  │
│  │  │  │   App Server                                                 │  │  │
│  │  │  │   10.0.20.10                                                 │  │  │
│  │  │  │   [No Public IP]                                             │  │  │
│  │  │  │                                                              │  │  │
│  │  │  │   Security Groups:                                           │  │  │
│  │  │  │   - AppServerSG                                              │  │  │
│  │  │  └──────────────────────────────────────────────────────────────┘  │  │
│  │  │                                                                     │  │
│  └──┼─────────────────────────────────────────────────────────────────────┘  │
│     │                                                                        │
│     │  ┌──────────────────┐                                                 │
│     └──┤   NAT Gateway    │                                                 │
│        └──────────────────┘                                                 │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Security Group Details

### AppServerSG (⚠️ Non-Compliant)

**Inbound Rules:**
```
┌──────────┬──────────┬──────┬─────────────┬──────────────────────────────┐
│ Type     │ Protocol │ Port │ Source      │ Description                  │
├──────────┼──────────┼──────┼─────────────┼──────────────────────────────┤
│ SSH      │ TCP      │ 22   │ 0.0.0.0/0   │ ⚠️ SSH from anywhere (BAD!)  │
└──────────┴──────────┴──────┴─────────────┴──────────────────────────────┘
```

**Outbound Rules:**
```
┌──────────┬──────────┬──────┬─────────────┬──────────────────────────────┐
│ Type     │ Protocol │ Port │ Destination │ Description                  │
├──────────┼──────────┼──────┼─────────────┼──────────────────────────────┤
│ All      │ All      │ All  │ 0.0.0.0/0   │ Allow all outbound           │
└──────────┴──────────┴──────┴─────────────┴──────────────────────────────┘
```

### BastionHostSG

**Inbound Rules:**
```
┌──────────┬──────────┬──────┬─────────────┬──────────────────────────────┐
│ Type     │ Protocol │ Port │ Source      │ Description                  │
├──────────┼──────────┼──────┼─────────────┼──────────────────────────────┤
│ SSH      │ TCP      │ 22   │ 0.0.0.0/0   │ SSH from internet (Session   │
│          │          │      │             │ Manager doesn't need this)   │
└──────────┴──────────┴──────┴─────────────┴──────────────────────────────┘
```

**Outbound Rules:**
```
┌──────────┬──────────┬──────┬─────────────┬──────────────────────────────┐
│ Type     │ Protocol │ Port │ Destination │ Description                  │
├──────────┼──────────┼──────┼─────────────┼──────────────────────────────┤
│ All      │ All      │ All  │ 0.0.0.0/0   │ Allow all outbound           │
└──────────┴──────────┴──────┴─────────────┴──────────────────────────────┘
```

### PublicServerSG

**Inbound Rules:**
```
┌──────────┬──────────┬──────┬─────────────┬──────────────────────────────┐
│ Type     │ Protocol │ Port │ Source      │ Description                  │
├──────────┼──────────┼──────┼─────────────┼──────────────────────────────┤
│ SSH      │ TCP      │ 22   │ 0.0.0.0/0   │ SSH from internet            │
└──────────┴──────────┴──────┴─────────────┴──────────────────────────────┘
```

**Outbound Rules:**
```
┌──────────┬──────────┬──────┬─────────────┬──────────────────────────────┐
│ Type     │ Protocol │ Port │ Destination │ Description                  │
├──────────┼──────────┼──────┼─────────────┼──────────────────────────────┤
│ All      │ All      │ All  │ 0.0.0.0/0   │ Allow all outbound           │
└──────────┴──────────┴──────┴─────────────┴──────────────────────────────┘
```

### ApacheServerSG (⚠️ Non-Compliant)

**Inbound Rules:**
```
┌──────────┬──────────┬──────┬─────────────┬──────────────────────────────┐
│ Type     │ Protocol │ Port │ Source      │ Description                  │
├──────────┼──────────┼──────┼─────────────┼──────────────────────────────┤
│ SSH      │ TCP      │ 22   │ 0.0.0.0/0   │ SSH from internet            │
│          │          │      │             │                              │
│ ⚠️ MISSING HTTP RULE - This is the challenge!                           │
└──────────┴──────────┴──────┴─────────────┴──────────────────────────────┘
```

**Outbound Rules:**
```
┌──────────┬──────────┬──────┬─────────────┬──────────────────────────────┐
│ Type     │ Protocol │ Port │ Destination │ Description                  │
├──────────┼──────────┼──────┼─────────────┼──────────────────────────────┤
│ All      │ All      │ All  │ 0.0.0.0/0   │ Allow all outbound           │
└──────────┴──────────┴──────┴─────────────┴──────────────────────────────┘
```

## Traffic Flow - Initial State

### SSH from Bastion Host to App Server (✅ Works)

```
Bastion Host (10.0.10.50)
         │
         │ SSH (port 22)
         │
         ▼
App Server (10.0.20.10)
         │
         └─ AppServerSG checks: Source 10.0.10.50 matches 0.0.0.0/0 ✅
         └─ Connection ALLOWED
```

### SSH from Public Server to App Server (⚠️ Works but shouldn't!)

```
Public Server (10.0.11.50)
         │
         │ SSH (port 22)
         │
         ▼
App Server (10.0.20.10)
         │
         └─ AppServerSG checks: Source 10.0.11.50 matches 0.0.0.0/0 ✅
         └─ Connection ALLOWED (⚠️ SECURITY VIOLATION!)
```

### HTTP to Apache Server (❌ Fails)

```
Internet Browser
         │
         │ HTTP (port 80)
         │
         ▼
Apache Server (10.0.10.100)
         │
         └─ ApacheServerSG checks: No HTTP rule found ❌
         └─ Connection DENIED
```

## Problems Identified

### Problem 1: AppServerSG Too Permissive
- **Issue:** SSH allowed from 0.0.0.0/0 (anywhere)
- **Risk:** Any host can SSH to App Server
- **Violation:** Security policy requires SSH only through bastion host
- **Impact:** Public Server can SSH to App Server (non-compliant)

### Problem 2: ApacheServerSG Missing HTTP Rule
- **Issue:** No HTTP (port 80) inbound rule
- **Risk:** Web server cannot serve traffic
- **Impact:** Apache Test Page inaccessible from internet

## Next Steps

1. **Task 3:** Restrict AppServerSG to specific IP (Bastion Host)
2. **Task 4:** Replace IP with security group reference
3. **Challenge:** Add HTTP rule to ApacheServerSG

See the other diagram files for the corrected configurations.
