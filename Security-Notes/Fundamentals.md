# In-Depth: OSI Model & Hardware Firewall Operations (Layers 3, 4, 7)

## OSI Model Quick Overview

```
Layer 7: Application    ← What you see (HTTP, DNS, FTP)
Layer 6: Presentation   ← Data formatting (encryption, encoding)
Layer 5: Session        ← Connection management
Layer 4: Transport      ← TCP/UDP, Ports
Layer 3: Network        ← IP addresses, Routing
Layer 2: Data Link      ← MAC addresses, Switches
Layer 1: Physical       ← Cables, Signals
```
![image not loaded](./images/Fund-pic.png)
---

## **Layer 3 - Network Layer (IP Layer)**

### What It Does
Routes packets between networks based on **IP addresses**. Think of it as the postal system - it knows the source and destination addresses.

### Hardware Firewall at Layer 3

**Inspects:**
- **Source IP**: `192.168.1.50` (your office computer)
- **Destination IP**: `34.120.45.67` (your GCP server)
- **Protocol**: IPv4 or IPv6
- **Packet fragmentation**: Is someone trying to bypass filters with fragmented packets?

### Real Example
```
Rule: Block all traffic from Russia (IP range: 5.0.0.0/8)
Firewall sees: Packet from 5.45.23.100 → BLOCKED
Firewall sees: Packet from 203.0.113.50 (Singapore) → Check next layer
```

### Layer 3 Attacks Firewalls Prevent
- **IP Spoofing**: Attacker pretends to be from trusted IP `192.168.1.10`
- **Ping of Death**: Oversized ICMP packets crash systems
- **Smurf Attack**: Amplified ICMP flood from spoofed source

### Limitations
❌ Can't see if it's HTTP, SSH, or malware  
❌ Can't detect if port 443 traffic is legitimate HTTPS or C2 communication  
❌ Can't read encrypted content

---

## **Layer 4 - Transport Layer (TCP/UDP Layer)**

### What It Does
Manages **end-to-end connections** and ensures data integrity. Breaks data into segments and reassembles them.

### Hardware Firewall at Layer 4

**Inspects:**
- **Protocols**: TCP (reliable) vs UDP (fast, unreliable)
- **Port Numbers**: 
  - Source Port: `54321` (random ephemeral port)
  - Destination Port: `443` (HTTPS), `22` (SSH), `3306` (MySQL)
- **TCP Flags**: SYN, ACK, FIN, RST (handshake status)
- **Connection State**: Is this an established connection or new?

### Real Example
```
Rule 1: Allow TCP port 443 from Office IP (203.0.113.50) to GCP Server (34.120.45.67)
Rule 2: Block TCP port 22 (SSH) from all external IPs
Rule 3: Block UDP port 53 (DNS) except to authorized DNS servers

Packet arrives: 
- From: 203.0.113.50:54321
- To: 34.120.45.67:443
- Protocol: TCP
→ ALLOWED (matches Rule 1)

Packet arrives:
- From: 203.0.113.50:12345
- To: 34.120.45.67:22
- Protocol: TCP
→ BLOCKED (matches Rule 2)
```

### Stateful vs Stateless Firewall (Layer 4)

**Stateless Firewall:**
- Examines each packet independently
- Doesn't remember previous packets
- Faster but less secure

**Stateful Firewall (Modern Hardware Firewalls):**
- Tracks connection state (NEW, ESTABLISHED, RELATED)
- Remembers the TCP 3-way handshake

```
TCP 3-Way Handshake:
1. Client → Server: SYN (I want to connect)
2. Server → Client: SYN-ACK (OK, let's connect)
3. Client → Server: ACK (Connected!)

Stateful firewall allows step 2 & 3 ONLY if step 1 was legitimate.
```

### Layer 4 Attacks Firewalls Prevent
- **SYN Flood**: Attacker sends millions of SYN packets, never completes handshake
- **Port Scanning**: Attacker probes ports 1-65535 to find open services
- **Session Hijacking**: Attacker injects packets into established TCP session

### Limitations
❌ Can't see what's INSIDE the packet (the actual data)  
❌ Can't tell if port 443 traffic is Google Docs or malware C2  
❌ Can't detect SQL injection in HTTP POST data

---

## **Layer 7 - Application Layer (Deep Packet Inspection)**

### What It Does
This is where the **actual application data** lives - your HTTP requests, SQL queries, email content, API calls.

### Hardware Firewall at Layer 7 (Next-Gen Firewalls)

**Inspects:**
- **HTTP/HTTPS**: URLs, headers, cookies, POST data
- **DNS**: Domain names being queried
- **FTP**: File names, commands
- **SMTP/POP3**: Email content, attachments
- **SQL**: Database queries
- **SSL/TLS**: Even encrypted traffic (via SSL inspection)

### Deep Packet Inspection (DPI) - How It Works

```
Without DPI (Layer 4):
Firewall sees: TCP packet to port 443
Firewall thinks: "It's HTTPS, probably safe"
Actual content: Malware downloading executable via HTTPS

With DPI (Layer 7):
Firewall sees: TCP packet to port 443
Firewall decrypts/inspects: 
  - URL: https://malicious-site.ru/payload.exe
  - File signature: PE executable (Windows program)
  - Threat intelligence: Known malware hash
Firewall action: BLOCK + Alert
```

### Real-World Examples

#### Example 1: SQL Injection Detection
```http
POST /login HTTP/1.1
Host: yourapp.com
Content-Type: application/x-www-form-urlencoded

username=admin' OR '1'='1&password=anything
```

**Layer 4 firewall**: ✅ Allows (it's just TCP port 443)  
**Layer 7 firewall**: ❌ Blocks (detects SQL injection pattern)

#### Example 2: Malicious File Upload
```http
POST /upload HTTP/1.1
Host: yourapp.com
Content-Type: multipart/form-data

[File: resume.pdf.exe - Size: 2MB]
```

**Layer 4**: ✅ Allows (just HTTPS traffic)  
**Layer 7**: ❌ Blocks (detects double extension + executable signature)

#### Example 3: Data Exfiltration via DNS Tunneling
```
Normal DNS: myapp.com → 34.120.45.67
Malicious DNS: a2F3YXNha2k.steal-data.evil.com
```

**Layer 4**: ✅ Allows (UDP port 53 is DNS, looks normal)  
**Layer 7**: ❌ Blocks (detects abnormal subdomain length + frequency)

### SSL/TLS Inspection (HTTPS Decryption)

**The Problem**: Most traffic is encrypted (HTTPS), firewall can't see inside.

**The Solution**: SSL Interception (Man-in-the-Middle)

```
Normal HTTPS Flow:
Your Browser ←[Encrypted]→ Google Server

With SSL Inspection:
Your Browser ←[Encrypted]→ Firewall ←[Encrypted]→ Google Server
                             ↓
                    [Decrypts, Inspects, Re-encrypts]
```

**How it works:**
1. Firewall presents its own SSL certificate to your browser
2. Browser trusts firewall (corporate CA certificate installed)
3. Firewall decrypts traffic, inspects content
4. Firewall re-encrypts to destination server
5. **You see:** Valid HTTPS connection
6. **Firewall sees:** Plain text HTTP data

### Application-Level Filtering

```python
# Layer 7 Firewall Rules Example

# Block social media during work hours
if url.contains("facebook.com", "instagram.com", "tiktok.com"):
    if time.now() between 9am and 5pm:
        BLOCK

# Allow only approved cloud storage
if protocol == "WebDAV" or protocol == "FTP":
    if destination not in ["drive.google.com", "onedrive.com"]:
        BLOCK

# Prevent sensitive data upload
if http.method == "POST":
    if body.contains(regex="\\d{3}-\\d{2}-\\d{4}"):  # SSN pattern
        BLOCK + ALERT("Potential SSN exfiltration")
```

### Layer 7 Attacks Firewalls Prevent
- **SQL Injection**: `admin' OR '1'='1`
- **Cross-Site Scripting (XSS)**: `<script>alert('hacked')</script>`
- **Command Injection**: `; rm -rf /`
- **Malware Downloads**: Executable files disguised as PDFs
- **Data Exfiltration**: Sensitive files being uploaded to Pastebin
- **Zero-Day Exploits**: Behavioral analysis detects unusual patterns

---

## **How All 3 Layers Work Together**

### Example Attack Scenario: Hacker tries to access your database

```
Attack Packet Structure:

Layer 7: SQL command: "SELECT * FROM users WHERE id=1 OR 1=1--"
Layer 4: TCP Destination Port: 3306 (MySQL)
Layer 3: Destination IP: 10.0.1.50 (your database server)

Firewall Inspection Process:

Step 1 - Layer 3 Check:
✓ Source IP: 203.0.113.100 (external IP from China)
✗ Rule: Database server 10.0.1.50 should only accept from internal IPs
→ BLOCKED at Layer 3 (never reaches Layer 4 or 7)

If IP was allowed:
Step 2 - Layer 4 Check:
✓ Destination Port: 3306
✗ Rule: Port 3306 should only be accessible from application servers (10.0.1.10-10.0.1.20)
→ BLOCKED at Layer 4 (never reaches Layer 7)

If port was allowed:
Step 3 - Layer 7 Check:
✓ Protocol: MySQL
✗ SQL Query contains: "OR 1=1--" (SQL injection pattern)
→ BLOCKED at Layer 7 + ALERT sent to SOC team
```

---

## **Hardware Firewall in Your Office Setup**

### Your Architecture with Layers Mapped

```
Employee Computer (Layer 7 app: Chrome browser)
        ↓
Office Switch (Layer 2)
        ↓
HARDWARE FIREWALL ← This is where the magic happens
│
├─ Layer 3: Checks if destination IP is allowed (GCP: 34.120.45.67)
├─ Layer 4: Checks if port 443 (HTTPS) is permitted
├─ Layer 7: DPI checks if it's legitimate API call or malware C2
│
        ↓
Internet Router
        ↓
GCP Cloud Armor (WAF) - Another Layer 7 firewall
        ↓
Load Balancer (Layer 4)
        ↓
Application in Private Subnet (Layer 7)
```

### Practical Firewall Rules for Your Setup

```
# Office Hardware Firewall Rules

# LAYER 3 RULES
1. Allow outbound to GCP IP range: 34.120.0.0/16
2. Block outbound to known malicious IPs (threat feed)
3. Block inbound from all external IPs (office network shouldn't accept incoming)

# LAYER 4 RULES
4. Allow TCP port 443 (HTTPS) to GCP servers
5. Allow TCP port 22 (SSH) only for DevOps team IPs
6. Block all UDP except DNS (port 53) to company DNS
7. Block high-risk ports: 3389 (RDP), 23 (Telnet), 21 (FTP)

# LAYER 7 RULES (DPI)
8. Block exe, dll, vbs file downloads (malware prevention)
9. Allow only HTTPS to *.yourcompany.com and approved SaaS
10. Detect & block SQL injection patterns in HTTP POST
11. SSL inspection for all HTTPS traffic (except banking/health sites)
12. Block access to cryptocurrency mining pools
13. Data Loss Prevention: Block upload of files containing "CONFIDENTIAL"
```

---

## **Why Layers Matter for Security**

| Layer | Speed | Visibility | Use Case |
|-------|-------|------------|----------|
| **Layer 3** | ⚡ Fastest | 👁️ IP only | Geo-blocking, DDoS mitigation |
| **Layer 4** | ⚡ Fast | 👁️👁️ IP + Port | Port filtering, connection limits |
| **Layer 7** | 🐌 Slower | 👁️👁️👁️ Full content | Malware, data exfiltration, app attacks |

**Defense in Depth Strategy:**
- Layer 3: Stop 80% of junk traffic (wrong country, known bad IPs)
- Layer 4: Stop 15% more (wrong ports, SYN floods)
- Layer 7: Stop the remaining 5% (sophisticated attacks)

---

## **Network Architecture Corrections for Your Setup**

### Inbound Traffic (Internet → Application)
```
Internet 
  → CDN (Content Delivery Network)
  → Cloud Armor / WAF (Web Application Firewall)
  → Internet Gateway (GCP)
  → Load Balancer (in public subnet)
  → Application (in private subnet)
```

### Outbound Traffic (Application → Internet)
```
Application (private subnet)
  → NAT Gateway (in public subnet)
  → Internet Gateway
  → Internet
```

**Key Correction**: NAT Gateway is for **OUTBOUND** traffic only, not inbound.

---

## **Office to Cloud Architecture**

### Option 1: IP Whitelisting (Basic)
```
Office Systems 
  → Hardware Firewall (your office public IP: 203.0.113.50)
  → Internet
  → GCP Cloud Armor (whitelist: 203.0.113.50 only)
  → Load Balancer
  → Application
```

**GCP Firewall Configuration:**
```yaml
# GCP Firewall Rule
name: allow-office-only
sourceRanges: ["203.0.113.50/32"]
allowed:
  - IPProtocol: tcp
    ports: ["443", "22"]
direction: INGRESS
priority: 1000
```

### Option 2: VPN Tunnel (Recommended)
```
Office Systems
  → Hardware Firewall
  → VPN Gateway (on-premises)
  → Encrypted Tunnel (IPsec/IKEv2)
  → Cloud VPN Gateway (GCP)
  → Private connection to VPCs
  → Application (no public exposure)
```

**Benefits:**
- ✅ Traffic never touches public internet
- ✅ End-to-end encryption
- ✅ Access private subnets directly
- ✅ No need to expose applications publicly

---

## **Deep Dive: How Hardware Firewall Protects Office → Cloud**

### Step-by-Step Traffic Flow with Security Checks

```
Step 1: Employee opens browser, types: https://yourapp.gcp.com/api/data

Step 2: DNS Resolution
Layer 7 Firewall Check:
  ✓ Domain "yourapp.gcp.com" in approved list
  ✗ If domain was "malicious-phishing.com" → BLOCKED

Step 3: Connection Initiation
Layer 3 Firewall Check:
  ✓ Destination IP: 34.120.45.67 (your GCP server)
  ✓ Source IP: 192.168.1.50 (employee computer)
  ✗ If destination was 5.45.23.100 (Russia) → BLOCKED

Step 4: TCP Handshake
Layer 4 Firewall Check:
  ✓ Destination Port: 443 (HTTPS)
  ✓ Protocol: TCP
  ✓ Connection state: NEW (SYN packet)
  ✗ If port was 3389 (RDP) → BLOCKED

Step 5: HTTPS Request
Layer 7 Firewall Check (SSL Inspection):
  → Decrypt HTTPS traffic
  → Inspect HTTP headers
  → Inspect POST body
  ✓ GET /api/data (legitimate API endpoint)
  ✓ No SQL injection patterns
  ✓ No malware signatures
  ✗ If URL was /api/../../etc/passwd (path traversal) → BLOCKED

Step 6: Allow traffic to exit office network
  → NAT translation (192.168.1.50 → 203.0.113.50)
  → Exit to internet with office public IP

Step 7: Traffic reaches GCP Cloud Armor
GCP Layer 7 Firewall Check:
  ✓ Source IP: 203.0.113.50 (your office firewall)
  ✓ Rate limit: 100 requests/minute (OK)
  ✓ No OWASP Top 10 attack patterns
  → ALLOWED to Load Balancer

Step 8: Load Balancer routes to Application
  → Application processes request
  → Returns data

Step 9: Response travels back through same path
  ← Each firewall logs the response
  ← Employee sees data in browser
```

---

## **Common Hardware Firewall Features**

### 1. Intrusion Prevention System (IPS)
- Detects and blocks known attack signatures
- Updates from threat intelligence feeds
- Blocks zero-day exploits using behavioral analysis

### 2. Application Control
- Identify applications regardless of port (e.g., Skype on port 443)
- Block/allow specific apps (BitTorrent, WhatsApp, etc.)

### 3. URL Filtering
- Category-based blocking (adult content, gambling, malware)
- Custom whitelist/blacklist

### 4. Data Loss Prevention (DLP)
- Scan outbound traffic for sensitive data
- Block upload of credit cards, SSNs, confidential docs

### 5. Advanced Threat Protection (ATP)
- Sandbox suspicious files in isolated environment
- Detonate executables to observe behavior
- Block if malicious activity detected

### 6. Traffic Shaping / QoS
- Prioritize business-critical traffic
- Throttle bandwidth-heavy apps (YouTube, Netflix)

### 7. VPN Concentrator
- IPsec VPN for site-to-site (Office → GCP)
- SSL VPN for remote employees
- Multi-factor authentication

---

## **Deployment Topology**

### Single Firewall (Small Office)
```
Internet ←→ [Hardware Firewall] ←→ Internal Network
             (All traffic passes through)
```

### DMZ Configuration (Medium/Large Office)
```
                [Hardware Firewall]
                       │
        ┌──────────────┼──────────────┐
        ↓              ↓              ↓
   Internet      DMZ Subnet    Internal Network
   (Public)    (Semi-trusted)   (Fully trusted)
                     │
              Web Servers,
              Email Gateway
```

### High Availability (Enterprise)
```
             [Primary Firewall] ←→ [Secondary Firewall]
                    ↓                      ↓
             (Active/Standby or Active/Active)
                    ↓
              Internal Network
```

---

## **Performance Considerations**

### Throughput Impact by Layer

| Security Feature | Throughput Impact | Latency Added |
|-----------------|-------------------|---------------|
| Layer 3 IP filtering | < 5% | < 1 ms |
| Layer 4 stateful inspection | 10-15% | 1-2 ms |
| Layer 7 DPI (no SSL) | 30-40% | 5-10 ms |
| Layer 7 DPI + SSL inspection | 50-70% | 10-20 ms |
| IPS + ATP | 60-80% | 15-30 ms |

**Sizing Example:**
- 1 Gbps internet connection
- With full Layer 7 inspection + SSL: Expect 300-500 Mbps usable throughput
- Need hardware firewall rated for **2-3x your bandwidth** for headroom

---

## **Logging & Monitoring**

### What to Log

**Layer 3:**
```
[2025-02-12 10:15:23] BLOCKED | SRC: 5.45.23.100 | DST: 34.120.45.67 | PROTO: ICMP | RULE: GeoBlock-Russia
```

**Layer 4:**
```
[2025-02-12 10:16:45] ALLOWED | SRC: 192.168.1.50:54321 | DST: 34.120.45.67:443 | PROTO: TCP | STATE: NEW | RULE: Allow-HTTPS
```

**Layer 7:**
```
[2025-02-12 10:17:01] BLOCKED | SRC: 192.168.1.75 | URL: yourapp.com/login | THREAT: SQL-Injection | PATTERN: 'OR 1=1-- | ACTION: Drop+Alert
```

### Integration with SIEM
- Forward logs to Splunk, ELK, or Google Chronicle
- Correlation with GCP Cloud Armor logs
- Automated alerting for critical events

---

## Key Takeaways 

1. **Layer 3 = Where** (IP addresses, routing)
2. **Layer 4 = How** (TCP/UDP, ports, connection state)
3. **Layer 7 = What** (actual application data, URLs, files)

4. **Modern hardware firewalls** = All 3 layers combined (Next-Gen Firewalls)

5. **Your office firewall** should:
   - Whitelist only your GCP IPs (Layer 3)
   - Open only necessary ports like 443, 22 (Layer 4)
   - Inspect HTTPS traffic for malware/data leaks (Layer 7)

6. **GCP side** should only accept traffic from your office firewall's public IP (creating a trusted tunnel)

7. **Defense in Depth**: Multiple layers of security (office firewall + GCP Cloud Armor + VPC firewall rules)

8. **NAT Gateway clarification**: Used for outbound traffic from private subnets, NOT for inbound traffic routing

---

## **Best Practices**

1. **Choose firewall hardware**: Fortinet FortiGate, Palo Alto Networks, Cisco ASA, pfSense
2. **Design firewall rules**: Start with deny-all, explicitly allow only necessary traffic
3. **Enable SSL inspection**: Deploy corporate CA certificate to all employee devices
4. **Configure GCP side**: 
   - Create VPC firewall rules to allow only office IP
   - Configure Cloud Armor security policies
   - Set up VPN gateway for secure connectivity
5. **Implement logging**: Forward logs to centralized SIEM
6. **Test thoroughly**: Simulate attacks to validate rules work
7. **Document everything**: Network diagrams, firewall rules, emergency procedures

---

## **Additional Resources**

- **OSI Model Deep Dive**: RFC 1122, RFC 791 (IP), RFC 793 (TCP)
- **Firewall Best Practices**: NIST SP 800-41 Rev 1
- **GCP Network Security**: https://cloud.google.com/security/products/firewall
- **VPN Setup**: IPsec/IKEv2 configuration guides
- **Threat Intelligence**: Alienvault OTX, MISP, Threat Fox

---
**Last Updated**: February 12, 2026  
**Author**: Research Notes - IT Security Internship

