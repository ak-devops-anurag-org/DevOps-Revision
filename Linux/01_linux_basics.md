# 01 - Linux Basics & Fundamentals

## Linux Architecture & Fundamentals

**Linux Architecture**
```text
[ Hardware ] ←→ [ Kernel ] ←→ [ Shell / System Libraries ] ←→ [ Applications / User ]
```

*   **Kernel:** Core of the OS. Manages CPU, memory, devices, and acts as a bridge between hardware and software.
*   **Shell:** Command-line interpreter. Takes user input, translates it for the kernel, and returns output.
*   **Bootloader:** First program loaded on startup. Loads the kernel into memory (e.g., GRUB).

**Linux Boot Process**
`BIOS/UEFI` (Hardware Init) → `GRUB` (Bootloader) → `Kernel` (Hardware setup, rootfs mount) → `init/systemd` (First process, PID 1, starts services).

**Kernel vs. User Space**
*   **Kernel Space:** Privileged area where the kernel executes and provides its services. Direct hardware access.
*   **User Space:** Restricted area where standard user programs run. Must use system calls to request kernel services.

**Monolithic vs. Microkernel**
*   *Monolithic (Linux):* All core OS services (drivers, filesystem) run in kernel space for speed.
*   *Microkernel:* Only minimal core runs in kernel space; other services run in user space.

**Virtual Filesystems (`/proc`, `/sys`, `/dev`)**
*   `/dev`: Device nodes (interfaces to physical/virtual hardware).
    *   *Key files:* `/dev/null`, `/dev/sda` (disk), `/dev/tty` (terminal).
*   `/proc`: In-memory pseudo-filesystem exposing kernel/process data.
    *   `/proc/cpuinfo`: CPU architecture and details.
    *   `/proc/meminfo`: RAM usage and swap info.
    *   `/proc/loadavg`: 1, 5, 15-minute load averages.
    *   `/proc/partitions`: Disk partition info.
    *   `/proc/<pid>/`: Details about a specific running process.
*   `/sys`: Sysfs. Exposes structured hardware and kernel module details (more organized than `/proc`).

**Kernel Parameters**
*   `sysctl`: Command to read/write kernel parameters at runtime (e.g., `sysctl -a`, `sysctl net.ipv4.ip_forward=1`).
*   `/etc/sysctl.conf`: File to make kernel parameter changes permanent across reboots.

---

## Shell Basics

*   **Shell:** User interface for access to an OS's services (e.g., bash, sh, zsh, ksh).

**Shell Types**
*   **Login vs. Non-Login:** Login shell requires authentication (e.g., SSH, initial terminal). Non-login runs from an existing session (e.g., opening a new terminal window in a GUI).
*   **Interactive vs. Non-Interactive:** Interactive waits for user input. Non-interactive runs scripts and exits.

**Shell Configuration Files (Bash)**
*   *Login:* `/etc/profile` → `~/.bash_profile` (or `~/.profile`)
*   *Non-Login:* `~/.bashrc`
*   *System-wide env:* `/etc/environment`

**Common Shortcuts**
| Shortcut | Action |
| :--- | :--- |
| `Ctrl+C` | Send SIGINT (kill foreground process) |
| `Ctrl+Z` | Send SIGTSTP (suspend foreground process) |
| `Ctrl+D` | Send EOF (exit shell) |
| `Ctrl+R` | Reverse search history |
| `Ctrl+L` | Clear screen (`clear`) |
| `Ctrl+A` / `E`| Move cursor to start / end of line |

**Command Execution Flow**
1. Read input → 2. Expand aliases/variables → 3. Search PATH for executable → 4. Fork/Exec process → 5. Return exit code.

**Locating Commands**
*   `type`: Identifies if a command is a built-in, alias, or file (e.g., `type ls`).
*   `which`: Locates the executable path in `$PATH`.
*   `whereis`: Locates binary, source, and manual page files.
*   `alias`: Create a shortcut (e.g., `alias ll='ls -al'`).

**Exit Codes (`$?`)**
*   `0` = Success.
*   `1-255` = Failure (e.g., 1 = General error, 127 = Command not found).

**Variables**
*   **Shell Variables:** Local to the current shell. Not passed to child processes.
*   **Environment Variables:** Exported to child processes.
*   `export VAR="value"`: Make variable available to child processes.
*   `env` / `printenv`: List environment variables.
*   `set`: List all shell variables and functions.
*   `unset VAR`: Delete a variable.

---

## Environment Variables

**Key Variables**
| Variable | Description |
| :--- | :--- |
| `PATH` | Colon-separated list of directories searched for executables. |
| `HOME` | Current user's home directory (`~`). |
| `USER` | Current logged-in username. |
| `SHELL` | Path to the current shell. |
| `HOSTNAME` | System's hostname. |
| `LANG` | System locale and language settings. |
| `PS1` | Primary prompt string (customizes terminal prompt appearance). |

**How PATH Works**
The shell checks directories in `$PATH` from left to right. First match is executed.
Add to PATH: `export PATH=$PATH:/new/dir`

**Setting Variables**
*   *Temporary:* `export MY_VAR="test"` (lost on logout).
*   *Permanent (User):* Add to `~/.bashrc` or `~/.profile`.
*   *Permanent (System):* Add to `/etc/environment` or `/etc/profile.d/`.

---

## Pipes, Redirection & I/O

**Standard Streams**
*   `stdin` (0): Standard Input (keyboard).
*   `stdout` (1): Standard Output (screen).
*   `stderr` (2): Standard Error (screen).

**Redirection**
*   `>`: Overwrite stdout to file (`echo "hi" > file.txt`).
*   `>>`: Append stdout to file (`echo "hi" >> file.txt`).
*   `2>`: Redirect stderr (`ls /bad 2> errors.txt`).
*   `2>>`: Append stderr.
*   `&>` or `> file 2>&1`: Redirect both stdout and stderr to the same file.
*   `/dev/null`: The "black hole". Discards written data (`command &> /dev/null`).

**Pipes (`|`)**
Passes `stdout` of one command as `stdin` to the next.
*Example:* `ls -l | grep "txt" | wc -l`

**`tee` Command**
Reads stdin and writes to both stdout AND a file simultaneously.
*Example:* `echo "Hello" | tee output.log`

**Here Documents (`<<`) & Here Strings (`<<<`)**
*   **Here Doc:** Multi-line input block.
    ```bash
    cat << EOF > file.txt
    Line 1
    Line 2
    EOF
    ```
*   **Here String:** Single-line string to stdin. `grep "root" <<< "$VAR"`

**DevOps Examples**
*   Parse logs: `cat /var/log/syslog | grep "error" | awk '{print $5}' | sort | uniq -c`
*   Silent script execution: `./deploy.sh > /var/log/deploy.log 2>&1`

---

## Package Management

| Action | Debian / Ubuntu (`apt` / `dpkg`) | RHEL / CentOS (`yum` / `dnf` / `rpm`) |
| :--- | :--- | :--- |
| **Install** | `apt install <pkg>` | `dnf install <pkg>` |
| **Remove** | `apt remove <pkg>` | `dnf remove <pkg>` |
| **Update metadata** | `apt update` | `dnf check-update` |
| **Upgrade all** | `apt upgrade` | `dnf upgrade` |
| **Search** | `apt search <pkg>` | `dnf search <pkg>` |
| **List installed** | `dpkg -l` or `apt list --installed` | `rpm -qa` or `dnf list installed` |
| **Show info** | `apt show <pkg>` | `dnf info <pkg>` |
| **Local install**| `dpkg -i file.deb` | `rpm -ivh file.rpm` |

*   **`apt update` vs `apt upgrade`:** `update` refreshes the list of available packages from repositories. `upgrade` actually downloads and installs the newer versions.
*   **Repositories:** Configured in `/etc/apt/sources.list` (Debian) or `/etc/yum.repos.d/` (RHEL).

---

## Cron Jobs & Scheduling

**Crontab Syntax**
```text
* * * * * command to be executed
- - - - -
| | | | |
| | | | +----- Day of week (0 - 7) (Sunday=0 or 7)
| | | +------- Month (1 - 12)
| | +--------- Day of month (1 - 31)
| +----------- Hour (0 - 23)
+------------- Minute (0 - 59)
```

**Commands**
*   `crontab -e`: Edit user's crontab.
*   `crontab -l`: List user's crontab.
*   `crontab -r`: Remove user's crontab.

**System Cron**
*   `/etc/crontab`: System-wide cron file (includes a user field).
*   `/etc/cron.d/`: Drop-in directory for cron fragments.
*   `/etc/cron.hourly/`, `cron.daily/`, `cron.weekly/`, `cron.monthly/`: Drop executable scripts here to run at those intervals.

**Cron Examples**
| Schedule | Syntax |
| :--- | :--- |
| Every minute | `* * * * *` |
| Every 5 minutes | `*/5 * * * *` |
| Every day at midnight | `0 0 * * *` |
| Every Monday at 2 AM | `0 2 * * 1` |

**Notes & Use Cases**
*   **`at` command:** Schedule a one-time task (e.g., `echo "systemctl restart nginx" | at 2:00 AM`).
*   **Logs:** Usually found in `/var/log/syslog` (Ubuntu) or `/var/log/cron` (RHEL).
*   **DevOps Use Cases:** Database dumps, log rotation (usually handled by `logrotate` via cron), temp file cleanup, health check scripts.

---

## SSH (Secure Shell)

**How SSH Works**
Provides a secure, encrypted channel over an unsecured network (default Port 22). Uses asymmetric cryptography for authentication and symmetric cryptography for the session.

**Key-Based Authentication Flow**
1. Client generates Key Pair (Public/Private).
2. Client's Public Key is copied to Server's `~/.ssh/authorized_keys`.
3. Client attempts connection; Server issues a challenge encrypted with the Public Key.
4. Client decrypts challenge with Private Key and sends it back. Access granted.

**Commands**
*   `ssh-keygen -t rsa -b 4096`: Generate an SSH key pair.
*   `ssh-copy-id user@host`: Copy public key to remote server.
*   `ssh-agent`: Program that holds private keys in memory.
*   `ssh-add ~/.ssh/id_rsa`: Add key to agent (avoids typing passphrase repeatedly).

**SSH Configuration (`~/.ssh/config`)**
Simplifies connections:
```text
Host myserver
    HostName 192.168.1.10
    User admin
    Port 2222
    IdentityFile ~/.ssh/myserver_key
```
Connect using: `ssh myserver`

**SSH Tunneling (Port Forwarding)**
*   **Local Forwarding (`-L`):** Forward a local port to a remote destination via SSH server.
    `ssh -L 8080:internal-db:3306 user@bastion` (Access internal-db:3306 via localhost:8080).
*   **Remote Forwarding (`-R`):** Expose a local port to the remote SSH server.

**File Transfer**
*   `scp`: Secure copy. `scp file.txt user@host:/tmp/`
*   `rsync`: Sync files/directories (delta transfers, resumable). `rsync -avz local_dir/ user@host:/remote_dir/`

**SSH Hardening (`/etc/ssh/sshd_config`)**
*   `PermitRootLogin no` (Disable direct root login)
*   `PasswordAuthentication no` (Force key-based auth)
*   `Port 2222` (Change default port to avoid automated scanners)

---

## Quick Reference — Commands to Remember

| Command | Action |
| :--- | :--- |
| `sysctl -a` | List all kernel parameters |
| `type cmd` | Check command type/alias |
| `echo $?` | View exit code of last command |
| `export VAR=val`| Set environment variable |
| `env` / `printenv`| List environment variables |
| `cmd &> file` | Redirect stdout and stderr to file |
| `cmd | tee file`| Print to stdout AND save to file |
| `crontab -e` | Edit cron jobs |
| `ssh-copy-id` | Install public key on remote host |
| `rsync -avz` | Sync directories efficiently |
