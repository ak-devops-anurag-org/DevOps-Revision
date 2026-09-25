# Linux Processes, Networking, & Services

## Processes

**What is a process?**
A running instance of a program.
*   **PID:** Process ID.
*   **PPID:** Parent Process ID.
*   **UID:** User ID of the user who started the process.

**Process States**
*   **R (Running):** Currently executing on CPU or in the run queue.
*   **S (Sleeping):** Waiting for an event or resource (interruptible).
*   **D (Defunct/Uninterruptible Sleep):** Waiting for I/O (cannot be interrupted).
*   **T (Stopped):** Suspended by a signal (e.g., Ctrl+Z).
*   **Z (Zombie):** Terminated but not reaped by its parent.

**Foreground vs Background Processes**
*   `&`: Append to a command to run it in the background (`sleep 100 &`).
*   `jobs`: List jobs in the current shell.
*   `bg <job_id>`: Resume a stopped job in the background.
*   `fg <job_id>`: Bring a background job to the foreground.

**Process vs Thread**
| Feature | Process | Thread |
| :--- | :--- | :--- |
| **Definition** | Independent execution unit | Subset of a process |
| **Resource Sharing** | Isolated (own memory space) | Shares memory/resources with peers |
| **Context Switching** | Expensive / Slower | Cheaper / Faster |
| **Failure** | Crash does not affect others | Crash can bring down the whole process |

**Special Process Types**
*   **Zombie Process:** A child process that has completed execution but still has an entry in the process table because the parent hasn't read its exit status. Identify via `top` (zombie count) or `ps aux | awk '$8=="Z" {print $0}'`. Fix: Kill the parent process, so `init` (PID 1) inherits and reaps it.
*   **Orphan Process:** A child whose parent has terminated. Automatically adopted by `init` (PID 1) or `systemd`, which will reap it.
*   **Daemon Process:** Background process not attached to any terminal (e.g., `sshd`, `nginx`).

### Process Commands Table

| Command | Purpose | Key Flags |
| :--- | :--- | :--- |
| `ps` | Snapshot of current processes | `ps aux` (all users, BSD format), `ps -ef` (standard format) |
| `top` | Dynamic real-time process view | `Shift + P` (sort by CPU), `Shift + M` (sort by Mem) |
| `htop` | Interactive process viewer | Use arrows, `F9` to kill, `F10` to quit (needs install) |
| `kill` | Send signal to a PID | `kill -9 <PID>` (force), `kill -15 <PID>` (graceful) |
| `pkill` | Kill processes by name | `pkill nginx`, `pkill -u user` |
| `killall` | Kill all processes with a name | `killall -9 python` |
| `pgrep` | Find PID by name | `pgrep -u root sshd` |
| `nice` | Start a program with modified priority | `nice -n 10 ./script.sh` (-20 highest, 19 lowest) |
| `renice` | Change priority of running PID | `renice -n 5 -p 1234` |
| `nohup` | Run command immune to hangups | `nohup script.sh &` (Output to `nohup.out`) |

**Signals Table**
| Signal | Value | Description |
| :--- | :--- | :--- |
| **SIGHUP** | 1 | Hangup (often used to reload config). |
| **SIGKILL** | 9 | Force kill (cannot be caught or ignored). |
| **SIGTERM** | 15 | Graceful termination (default `kill` signal). |
| **SIGSTOP** | 17/19 | Stop process (cannot be caught or ignored). |
| **SIGCONT** | 18/25 | Continue a stopped process. |

*   **`kill` vs `kill -9` vs `pkill`:** `kill` defaults to `SIGTERM` (allows cleanup). `kill -9` forces termination immediately (no cleanup). `pkill` uses process names instead of PIDs.

**Load Average**
Represents CPU demand (running + waiting tasks).
*   Format: `[1-min] [5-min] [15-min]`
*   Interpretation: On a 4-core CPU, a load of `4.0` means 100% utilization. `>4.0` means processes are queued. If 1-min > 15-min, load is increasing.

**Interpreting `top` Output**
*   **PID:** Process ID.
*   **USER:** Owner of the process.
*   **PR / NI:** Priority and Nice value.
*   **VIRT:** Virtual memory used (total mapped).
*   **RES:** Resident Set Size (actual physical memory used).
*   **SHR:** Shared memory.
*   **S:** State (R, S, D, T, Z).
*   **%CPU / %MEM:** CPU and Memory percentage used.

**`/proc/<pid>/` Files**
*   `cmdline`: Command that started the process.
*   `status`: Human-readable status (State, memory, threads).
*   `fd/`: Directory of open file descriptors.
*   `environ`: Environment variables for the process.

---

## Systemd & Services

**What is systemd?**
The modern Linux init system and service manager. It has PID 1 and initializes the system, manages services, and tracks dependencies.

**systemd vs SysVinit**
| Feature | systemd | SysVinit |
| :--- | :--- | :--- |
| **Startup** | Parallel (faster boot) | Sequential (slower boot) |
| **Management** | `systemctl` | `service`, `/etc/init.d/` scripts |
| **Dependency Tracking** | Advanced (waits for sockets/targets) | Manual via scripts |
| **Logging** | Native (`journalctl`) | Relies on `syslog` |

**`systemctl` Commands Table**
| Command | Action |
| :--- | :--- |
| `systemctl start/stop <service>` | Start or stop a service immediately. |
| `systemctl restart <service>` | Stop then start the service. |
| `systemctl reload <service>` | Reload config without dropping connections (if supported). |
| `systemctl enable/disable <service>` | Enable/disable service at boot time. |
| `systemctl status <service>` | Check current status, uptime, and recent logs. |
| `systemctl is-active <service>` | Returns `active` or `inactive`. |
| `systemctl is-enabled <service>` | Returns `enabled` or `disabled`. |
| `systemctl list-units --type=service` | List active services. |
| `systemctl list-unit-files` | List all available units and their boot state. |
| `systemctl daemon-reload` | Reload systemd manager configuration (run after editing unit files). |
| `systemctl mask/unmask <service>` | Completely prevent a service from starting (symlinks to `/dev/null`). |

**Unit Files**
*   **Locations:** `/etc/systemd/system/` (Local config, highest priority), `/usr/lib/systemd/system/` (Package defaults).
*   **Anatomy:**
    *   `[Unit]`: Metadata and dependencies (`Description`, `After`, `Wants`).
    *   `[Service]`: Execution details (`ExecStart`, `ExecReload`, `Restart`, `User`).
    *   `[Install]`: Behavior when enabled (`WantedBy`).

**Custom Systemd Service Example** (`/etc/systemd/system/myapp.service`)
```ini
[Unit]
Description=My Custom Node App
After=network.target

[Service]
User=appuser
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/node index.js
Restart=always

[Install]
WantedBy=multi-user.target
```

**Targets (Runlevel Equivalents)**
*   `multi-user.target`: CLI mode, network active (SysVinit Runlevel 3).
*   `graphical.target`: GUI mode (SysVinit Runlevel 5).

**Investigating a Failed Service**
```bash
systemctl status <service>
journalctl -u <service>
journalctl -u <service> --since "1 hour ago"
```

---

## Logs & journalctl

**Important Log Files**
| Log File | Contents / Purpose | OS Family |
| :--- | :--- | :--- |
| `/var/log/syslog` | Global system logs | Debian/Ubuntu |
| `/var/log/messages` | Global system logs | RHEL/CentOS |
| `/var/log/auth.log` | Authentication logs (SSH, sudo, logins) | Debian/Ubuntu |
| `/var/log/secure` | Authentication logs | RHEL/CentOS |
| `/var/log/kern.log` | Kernel logs | Both |
| `/var/log/dmesg` | Boot/hardware messages (ring buffer) | Both |
| `/var/log/boot.log` | Bootup process logs | Both |
| `/var/log/cron` | Cron job logs | Both |

**`journalctl` Key Usage**
*   `-u <unit>`: Logs for a specific service (`journalctl -u nginx`).
*   `-f`: Follow logs in real-time.
*   `-b`: Logs from the current boot.
*   `--since "1 hour ago"` / `--until "2023-10-01 12:00:00"`: Time filtering.
*   `-p err`: Filter by priority (err, warning, info).
*   `-n 50`: Show last 50 lines.
*   `--no-pager`: Output directly to stdout without pausing.
*   `-xe`: Jump to the end and show extra explanations (useful for immediate failures).

**Log Rotation**
*   Managed by `logrotate` via cron.
*   Config: `/etc/logrotate.conf` (global), `/etc/logrotate.d/` (app-specific).
*   Prevents logs from consuming all disk space.

---

## Networking

**OSI Model (Focus on DevOps relevance)**
| Layer | Name | Concept | Relevance |
| :--- | :--- | :--- | :--- |
| 7 | Application | High-level protocols (HTTP, HTTPS, SSH, SMTP) | L7 Load Balancers, Ingress, APIs |
| 6 | Presentation | Data formatting, Encryption | SSL/TLS termination |
| 5 | Session | Session management | Persistent connections |
| 4 | Transport | TCP/UDP, Port numbers | L4 Load Balancers, Firewalls (iptables) |
| 3 | Network | IP Addresses, Routing (ICMP) | Subnets, VPCs, Routers, Ping |
| 2 | Data Link | MAC Addresses, Switching | ARP, VLANs, Switches |
| 1 | Physical | Cables, Signals | Physical hardware |

**TCP vs UDP**
| Feature | TCP | UDP |
| :--- | :--- | :--- |
| **Connection** | Connection-oriented (Handshake) | Connectionless |
| **Reliability** | Reliable (Retransmission, ordering) | Unreliable (Best effort) |
| **Speed** | Slower (overhead) | Faster |
| **Use Case** | HTTP, SSH, Databases | DNS, Video Streaming, VoIP |

**TCP 3-Way Handshake**
1.  **SYN:** Client requests connection.
2.  **SYN-ACK:** Server acknowledges request and responds.
3.  **ACK:** Client acknowledges server's response. Connection established.

**Ports**
*   **Well-known:** 0-1023 (Requires root).
*   **Registered:** 1024-49151.
*   **Dynamic/Ephemeral:** 49152-65535 (Used temporarily by clients).

**Common Ports Table**
| Port | Protocol | Port | Protocol | Port | Protocol |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 22 | SSH | 3306 | MySQL | 2379-2380 | etcd (K8s) |
| 80 | HTTP | 5432 | PostgreSQL | 6443 | K8s API |
| 443 | HTTPS | 6379 | Redis | 10250 | Kubelet |
| 53 | DNS | 8080/8443 | Alt HTTP/HTTPS | 25 | SMTP |

### Networking Commands Table

| Command | Purpose | Common Flags / Examples |
| :--- | :--- | :--- |
| `ip addr` / `ip a` | Show IP addresses (replaces ifconfig) | `ip a show eth0` |
| `ip route` | Show routing table | `ip route get 8.8.8.8` |
| `ip link` | Show network interfaces | `ip link set eth0 up` |
| `ss` | Socket statistics (replaces netstat) | `ss -tulnp` (TCP/UDP, Listening, Numeric, PIDs) |
| `ping` | Test ICMP reachability | `ping -c 4 8.8.8.8` |
| `traceroute` / `mtr` | Trace path packets take to dest | `mtr 8.8.8.8` (Dynamic updating traceroute) |
| `curl` | Transfer data from/to server | `curl -I <url>` (Headers), `curl -v` (Verbose) |
| `wget` | Download files | `wget -O output.txt <url>` |
| `dig` | DNS lookup | `dig +short A example.com` |
| `nslookup` / `host` | DNS lookup (older alternatives) | `nslookup example.com` |
| `nc` (netcat) | Read/write TCP/UDP, test ports | `nc -vz <ip> <port>` (Check if port is open) |
| `tcpdump` | Packet sniffer | `tcpdump -i eth0 port 80` |
| `iptables` | Configure firewall rules | `iptables -L -n -v` (List rules) |

### DNS

**DNS Resolution Steps**
1. Check local cache / `/etc/hosts`.
2. Query configured recursive resolver (`/etc/resolv.conf`).
3. Resolver queries Root server -> TLD server -> Authoritative Nameserver.
4. Returns IP to client.

**DNS Config Files**
*   `/etc/resolv.conf`: Configures DNS resolvers (nameservers).
*   `/etc/hosts`: Local DNS overrides (IP to Hostname mapping).
*   `/etc/nsswitch.conf`: Determines lookup order (e.g., `hosts: files dns`).

**DNS Record Types**
| Type | Purpose |
| :--- | :--- |
| **A** | Maps hostname to IPv4 address. |
| **AAAA**| Maps hostname to IPv6 address. |
| **CNAME**| Alias for another hostname. |
| **MX** | Mail exchange (routing emails). |
| **NS** | Authoritative nameservers for a domain. |
| **TXT** | Text data (often used for SPF, DKIM, validation). |
| **PTR** | Reverse DNS (IP to hostname). |

### Network Configuration Files
*   `/etc/hostname`: System hostname.
*   `/etc/sysconfig/network-scripts/ifcfg-<interface>`: RHEL network config.
*   `/etc/netplan/*.yaml`: Ubuntu modern network config.

---

## DevOps Troubleshooting Scenarios

**1. Server has high CPU**
*   **Check:** Which process is hogging CPU.
*   **Commands:** `top` (press Shift+P), `htop`, `ps aux --sort=-%cpu | head`, `uptime` (check load average).
*   **Look for:** A runaway process, excessive Java GC, crypto-mining malware.

**2. High memory usage**
*   **Check:** Available RAM, swap usage, memory leaks.
*   **Commands:** `free -h`, `top` (press Shift+M), `ps aux --sort=-%mem | head`, `dmesg -T | grep -i oom`.
*   **Look for:** Low `available` memory, heavy swap usage, processes killed by the OOM (Out Of Memory) killer.

**3. Service not starting**
*   **Check:** Service status, logs, configurations, dependencies.
*   **Commands:** `systemctl status <service>`, `journalctl -u <service> -xe`, `ss -tulnp` (check port conflict).
*   **Look for:** Syntax errors in config, permission denied errors, required port already bound by another process.

**4. Cannot connect to another server**
*   **Check:** Network reachability, DNS, Firewall, Routing.
*   **Commands:** `ping <target>`, `dig <domain>`, `nc -vz <target_ip> <port>`, `ip route`.
*   **Look for:** Dropped packets (firewall issue), NXDOMAIN (DNS issue), No Route to Host.

**5. Port not reachable (Connection Refused / Timeout)**
*   **Check:** Is service listening? Is firewall blocking?
*   **Commands:** `ss -tulnp | grep <port>` (on target server), `iptables -L -n` or AWS Security Groups, `curl -v telnet://<ip>:<port>`.
*   **Look for:** Service listening on `127.0.0.1` instead of `0.0.0.0` (localhost only), Security Group dropping packets (Timeout), service down (Connection Refused).

**6. Logs filling disk**
*   **Check:** Which files are largest.
*   **Commands:** `df -h` (check disk space), `du -sh /var/log/* | sort -rh`, `find /var/log -type f -size +100M`.
*   **Look for:** Runaway application logs, unconfigured `logrotate`, bloated `syslog`. Fix: Truncate logs (`> /var/log/file.log`), check logrotate config.

## Quick Reference — Commands to Remember
```bash
# Check listening ports
ss -tulnp

# Find files larger than 500MB
find / -type f -size +500M

# Check service logs from the last 10 minutes
journalctl -u nginx --since "10 minutes ago"

# Find a process by name and kill it gracefully
pkill -15 node

# Check memory and sort processes by memory usage
free -m && ps aux --sort=-%mem | head -n 5
```
