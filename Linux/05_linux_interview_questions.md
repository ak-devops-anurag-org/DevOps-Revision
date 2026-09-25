# Linux Interview Questions for Cloud & DevOps Engineers

This guide covers essential Linux concepts, commands, and troubleshooting scenarios tailored for Cloud & DevOps engineering interviews. 

## Linux Basics

**What is Linux? How is it different from Unix?**
Linux is an open-source kernel created by Linus Torvalds. Unix is a proprietary OS. Modern "Linux" is technically a distribution (like Ubuntu or RHEL) that packages the Linux kernel with GNU utilities and a package manager.

**Explain Linux architecture (Kernel, Shell, Hardware, Applications)**
- **Hardware:** Physical CPU, RAM, and Disks.
- **Kernel:** The core that directly manages hardware, CPU scheduling, and memory.
- **Shell:** The CLI interface (Bash, Zsh) that takes user input and sends it to the Kernel.
- **Applications:** User-level programs running on top of the OS.

**What happens when you type a command in the terminal and press Enter?**
The shell reads the input, parses arguments, and checks for built-ins. It searches the `$PATH` for the executable, forks a child process, uses `exec()` to replace the process with the command, and waits for its exit code.

**What is the difference between a shell and a terminal?**
A **terminal** is an emulator (wrapper) that handles graphical input/output. A **shell** is the program running *inside* the terminal that executes your commands (e.g., bash).

**What is the Linux boot process?**
BIOS/UEFI -> MBR/GPT (Boot Sector) -> GRUB (Bootloader) -> Kernel -> systemd (PID 1) -> Default Target (Runlevel).

**Login shell vs Non-login shell?**
- **Login shell:** Executed upon initial login (SSH or physical). Sources `/etc/profile` and `~/.bash_profile`.
- **Non-login shell:** Opened via a GUI terminal or when running scripts. Sources `~/.bashrc`.

**What are runlevels? What replaced them?**
Runlevels define the system state (e.g., 3 = CLI multi-user, 5 = GUI). Modern Linux uses **systemd targets** instead (e.g., `multi-user.target`, `graphical.target`). Check current: `systemctl get-default`.

**What is the difference between `/bin`, `/sbin`, `/usr/bin`, `/usr/local/bin`?**
- `/bin`: Essential user binaries (e.g., `ls`, `cat`).
- `/sbin`: Essential system administrator binaries (e.g., `fdisk`, `iptables`).
- `/usr/bin`: Non-essential user binaries installed by the package manager.
- `/usr/local/bin`: Custom compiled software not managed by the OS package manager.

**What is the role of `/etc/environment` vs `~/.bashrc`?**
`/etc/environment` sets system-wide environment variables for all users and processes. `~/.bashrc` sets variables and aliases only for a specific user's interactive shell.

**What are environment variables? How do you set them permanently?**
Key-value pairs used to configure the OS and applications. Set temporarily: `export DB_HOST=localhost`. Set permanently: Append `export DB_HOST=localhost` to `~/.bashrc` or `~/.profile`.

---

## Filesystem

**What is an inode? What information does it store?**
An inode is a data structure storing file metadata: permissions, ownership, timestamps, size, and pointers to the physical data blocks. **It does not store the filename.** Check inodes with `ls -i`.

**What happens when inodes are exhausted? How do you fix it?**
You get a "No space left on device" error even if disk space is free (`df -i` shows 100%). This is caused by millions of tiny files. Fix it by finding and deleting them:
```bash
find / -xdev -type f | cut -d "/" -f 2 | sort | uniq -c | sort -n
```

**Hard link vs Soft link — differences, when to use each?**
- **Hard Link:** Points directly to the inode. Cannot cross filesystems or link directories. File is deleted only when all hard links are removed. `ln file hard_link`
- **Soft Link (Symlink):** Points to the original filename. Can cross filesystems. Broken if original file is deleted. `ln -s file soft_link`

**What is the Filesystem Hierarchy Standard?**
It defines the directory structure: `/etc` for configurations, `/var` for variable data (logs), `/home` for user profiles, `/tmp` for temporary files, and `/opt` for optional add-on software.

**What is `/proc`? Name some important files inside it.**
A virtual pseudo-filesystem existing in RAM, exposing kernel and process data.
- `/proc/cpuinfo`: CPU specs
- `/proc/meminfo`: Memory usage
- `/proc/<PID>`: Data for a specific process

**What is `/dev/null`?**
The "black hole" pseudo-device. Any data written to it is instantly discarded. Often used to suppress unwanted output: `command > /dev/null 2>&1`.

**Explain the output of `ls -la`**
Shows hidden files (`-a`) in long format (`-l`). Output columns:
Permissions (`-rw-r--r--`), Link count (`1`), Owner (`root`), Group (`root`), Size (`4096`), Modification Date (`Oct 1`), Filename (`file.txt`).

**What are the important directories under `/var`?**
- `/var/log`: System and application logs.
- `/var/lib`: Database states and application data.
- `/var/run`: PIDs and sockets for running processes.

---

## Commands & Text Processing

**How do you find all files larger than 100MB?**
```bash
find / -type f -size +100M
```

**How do you find the top 10 largest files on the system?**
```bash
find / -type f -exec du -Sh {} + | sort -rh | head -n 10
```

**How do you search for a pattern recursively in files? (grep)**
```bash
grep -rn "ERROR" /var/log/
```
*(r = recursive, n = show line numbers)*

**Explain the difference between `grep`, `awk`, and `sed`**
- `grep`: Filters and searches text by pattern.
- `awk`: Advanced column/field extraction and math logic (`awk '{print $1}'`).
- `sed`: Stream editor primarily used for find and replace (`sed 's/old/new/g' file`).

**How do you find the top 10 IP addresses in an access log?**
Assuming IP is the first column:
```bash
awk '{print $1}' access.log | sort | uniq -c | sort -nr | head -n 10
```

**What is the difference between `>` and `>>`?**
`>` Overwrites the file contents. `>>` Appends to the end of the file.

**What does `2>&1` mean?**
Redirects standard error (`2`) to the same destination as standard output (`1`). It merges both streams so errors and regular output go to the same file/pipe.

**How do you count lines, words, and characters in a file?**
```bash
wc -l file.txt  # Lines
wc -w file.txt  # Words
wc -c file.txt  # Characters
```

**How do you sort output and remove duplicates?**
You must sort first, as `uniq` only removes *adjacent* duplicates.
```bash
sort file.txt | uniq
```

**What is `xargs` and when do you use it?**
It converts standard input into command-line arguments. Used when piping to commands that don't natively read standard input.
```bash
find . -name "*.tmp" | xargs rm -f
```

---

## Permissions & Users

**What are file permissions? How does `chmod 755` work?**
Permissions are Read (4), Write (2), Execute (1). `755` means:
- Owner gets 7 (4+2+1 = Read/Write/Execute)
- Group gets 5 (4+1 = Read/Execute)
- Others get 5 (4+1 = Read/Execute)

**What is umask? What is the default umask?**
`umask` subtracts from default permissions (Dirs: 777, Files: 666) to set secure defaults. A default umask of `022` results in directories being `755` and files being `644`.

**What are SUID, SGID, and Sticky Bit? Give examples.**
- **SUID (`4000`):** File executes with the privileges of its owner (e.g., `/usr/bin/passwd`).
- **SGID (`2000`):** File executes with group privileges; new files in a directory inherit the directory's group.
- **Sticky Bit (`1000`):** Users can only delete files they own within a shared directory (e.g., `/tmp`).

**What is the difference between `su` and `sudo`?**
`su` switches your session entirely to another user and requires *their* password. `sudo` executes a single command as root/another user, requiring *your* password (and authorization in `/etc/sudoers`).

**How do you add a user to a group without removing existing groups?**
The `-a` (append) is critical; without it, they are removed from all other secondary groups.
```bash
usermod -aG docker devuser
```

**What is `/etc/passwd`? Explain each field.**
Stores user account definitions. Format: `user:x:1000:1000:Comment:/home/user:/bin/bash`
*(Username : Password Placeholder : UID : GID : Info : Home Directory : Default Shell)*

**What is `/etc/shadow`?**
Stores the securely hashed user passwords and password expiration policies. Only readable by root.

**How do you configure passwordless sudo for a user?**
Run `visudo` and add the following line:
```text
devuser ALL=(ALL) NOPASSWD: ALL
```

---

## Processes

**What is a process? What is PID and PPID?**
A process is an executing instance of a program. PID is the unique Process ID. PPID is the Parent Process ID (the process that spawned it).

**What is a zombie process? How do you identify and fix it?**
A process that has completed execution but remains in the process table because its parent hasn't read its exit status.
Find them: `top` (look at 'Z' column) or `ps aux | awk '{print $8}' | grep Z`.
Fix: You cannot kill a zombie. You must kill its parent process, or wait for PID 1 to reap it.

**What is a defunct process? Is it the same as a zombie?**
Yes, "defunct" is just another term for a zombie process.

**Difference between process and thread?**
A process has its own isolated memory space. Threads exist *within* a process, are lighter weight, and share the process's memory and resources.

**What is the difference between `kill`, `kill -9`, and `pkill`?**
- `kill <PID>`: Sends `SIGTERM` (15), allowing the process to clean up and exit gracefully.
- `kill -9 <PID>`: Sends `SIGKILL` (9), forcing the kernel to terminate it immediately (can cause data corruption).
- `pkill <name>`: Kills processes by name rather than PID (`pkill nginx`).

**What is load average? How do you interpret it?**
Shows system CPU demand over 1, 5, and 15 minutes (via `uptime` or `top`). A load of `1.0` on a 1-core system means 100% utilization. A load of `4.0` on a 4-core system is 100%.

**How do you run a process in the background? How do you bring it to foreground?**
Append `&` to run it in the background: `sleep 100 &`. Use `fg` to bring it to the foreground.

**What is `nohup`? When do you use it?**
"No hang up". It prevents a process from receiving a `SIGHUP` signal when the terminal closes, allowing it to keep running after you disconnect.
```bash
nohup ./long_script.sh &
```

**What are the different process states in Linux?**
Running (`R`), Sleeping (`S`), Uninterruptible Sleep waiting for I/O (`D`), Stopped (`T`), and Zombie (`Z`).

**What is an orphan process?**
A running process whose parent has terminated. It is immediately adopted by `systemd` (PID 1).

**How do you find which process is using the most CPU?**
Run `top` or `htop`. Alternatively:
```bash
ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%cpu | head -n 10
```

**What is OOM Killer?**
Out of Memory Killer. A kernel protection mechanism that abruptly kills user-space processes consuming too much memory to prevent the entire OS from crashing.

---

## Systemd & Services

**What is systemd? How is it different from SysVinit?**
systemd is the modern initialization system and service manager. It starts services in parallel, resolves dependencies automatically, and uses standard `.service` files. SysVinit used sequential bash scripts which were slower and harder to manage.

**What is a systemd unit file? Explain its sections.**
A configuration file for a service (e.g., `nginx.service`).
- `[Unit]`: Metadata and dependencies (Before, After).
- `[Service]`: Execution instructions (`ExecStart`, `Restart` policies).
- `[Install]`: Defines when it should be enabled (`WantedBy=multi-user.target`).

**How do you create a custom systemd service?**
1. Create `/etc/systemd/system/myapp.service`.
2. Define the `[Unit]` and `[Service]` blocks.
3. Run `systemctl daemon-reload`.
4. Run `systemctl start myapp` and `systemctl enable myapp`.

**How do you investigate why a service failed to start?**
```bash
systemctl status <service_name>
journalctl -u <service_name> --no-pager | tail -n 50
```

**What is the difference between `systemctl enable` and `systemctl start`?**
`start` starts the service immediately for the current session. `enable` creates a symlink ensuring the service automatically starts upon system boot.

**What is `daemon-reload` and when do you use it?**
It instructs systemd to parse and reload all unit files. You must run it anytime you create or modify a `.service` file.

**What is the difference between `restart` and `reload`?**
`restart` forcefully stops and starts the process (causes downtime). `reload` sends a `SIGHUP` signal, asking the service (like Nginx) to elegantly re-read its config without dropping active connections.

**What is masking a service?**
`systemctl mask <service>`. It links the unit file to `/dev/null`, making it completely impossible to start the service manually or automatically. Stronger than `disable`.

---

## Networking

**How does DNS resolution work in Linux?**
The system checks `/etc/hosts` first for local overrides, then checks `/etc/resolv.conf` for configured upstream DNS servers to query.

**What is the difference between TCP and UDP?**
- **TCP:** Connection-oriented, reliable, guarantees delivery and order (HTTP, SSH).
- **UDP:** Connectionless, fast, no guaranteed delivery (DNS, Video Streaming).

**Explain the TCP 3-way handshake.**
Client sends **SYN** -> Server replies with **SYN-ACK** -> Client replies with **ACK**. A reliable connection is now established.

**How do you find which process is listening on a specific port?**
```bash
ss -tulpn | grep :8080
# or
lsof -i :8080
```

**How do you check if a remote port is open? (multiple methods)**
```bash
nc -zv 10.0.0.5 443
telnet 10.0.0.5 443
curl -v telnet://10.0.0.5:443
```

**What is the difference between `ss` and `netstat`?**
`ss` is the modern, much faster replacement for `netstat`. `ss` pulls data directly from kernel space, whereas `netstat` is deprecated and reads slower `/proc` files.

**What files control DNS resolution in Linux?**
- `/etc/hosts`: Local static mappings.
- `/etc/resolv.conf`: Configured nameservers.
- `/etc/nsswitch.conf`: Determines the lookup order (files vs dns).

**How do you troubleshoot "connection refused" vs "connection timed out"?**
- **Refused:** The network packet reached the server, but no service is listening on that port (or a local firewall rejected it). Check the service status.
- **Timed out:** The packet was dropped on the network, likely by a Cloud Security Group or an external firewall. Check routing and firewall rules.

**What is a socket?**
An endpoint for communication, combining an IP address and a Port number (e.g., `192.168.1.10:443`).

**How do you capture network traffic on a specific port?**
```bash
tcpdump -i eth0 port 80 -n
```

**What is the difference between `curl` and `wget`?**
`curl` is designed to interact with APIs and prints to standard output by default. `wget` is designed to recursively download files and saves them to disk.

**What is SSH tunneling / port forwarding? Explain local and remote forwarding.**
Securely forwarding network traffic through an SSH connection.
- **Local (`-L`):** Forwards a port on your local machine to the remote server.
- **Remote (`-R`):** Exposes a port on your local machine to the remote server.

**How does SSH key-based authentication work?**
The client generates a public/private keypair. The public key is added to the server's `~/.ssh/authorized_keys`. Upon login, the server challenges the client to cryptographically sign a message proving ownership of the private key.

---

## Storage & Disk

**What is the difference between `df` and `du`?**
`df -h` reports free and used space at the entire filesystem/mount level. `du -sh *` calculates the actual sizes of specific directories and files.

**What happens when disk becomes 100% full? How do you troubleshoot?**
Databases stop accepting writes and the OS may crash.
1. Confirm: `df -h`
2. Find culprits: `du -ahx / | sort -rh | head -10`
3. Check for deleted files held open by processes: `lsof +L1`
4. Truncate logs instead of deleting: `> /var/log/huge.log`

**What is `/etc/fstab`? Explain its fields.**
Configuration for mounting filesystems automatically on boot. Fields:
`Device | MountPoint | FilesystemType | Options | Dump (backup) | Fsck (check order)`

**What is LVM? Why is it useful?**
Logical Volume Manager. It abstracts physical disks into logical pools. It is crucial because it allows you to dynamically resize filesystems on the fly, span volumes across multiple disks, and create snapshots.

**What are common filesystem types in Linux? (ext4, xfs, etc.)**
- **ext4:** The standard, stable Linux filesystem.
- **xfs:** High performance, standard on RHEL/CentOS. Good for large files.
- **btrfs:** Modern filesystem supporting snapshots and subvolumes.

**What is swap? When is it used?**
Disk space used as virtual memory when physical RAM is exhausted. It prevents crashes but severely degrades performance (thrashing) because disks are slower than RAM.

**How do you add a new disk in Linux? (end to end steps)**
1. Identify: `lsblk` or `fdisk -l`
2. Partition: `fdisk /dev/sdb` (create a new partition)
3. Format: `mkfs.ext4 /dev/sdb1`
4. Mount: `mount /dev/sdb1 /mnt/data`
5. Persist: Add entry to `/etc/fstab`

**How do you extend an LVM volume?**
1. Add new space to Volume Group (if needed): `vgextend vg0 /dev/sdc`
2. Extend the Logical Volume: `lvextend -l +100%FREE /dev/vg0/lv0`
3. Resize the filesystem: `resize2fs /dev/vg0/lv0` (for ext4) or `xfs_growfs` (for xfs).

**How do you find files that are deleted but still held open by processes?**
If a process is writing to a file and you delete it, space isn't freed until the process stops.
```bash
lsof | grep deleted
```
To clear the space, restart the process or truncate the file descriptor directly: `> /proc/<PID>/fd/<FD>`

---

## Shell & Scripting

**What is the significance of `#!/bin/bash`?**
The shebang tells the operating system which interpreter should be used to parse and execute the rest of the script.

**What is the difference between `$()` and backticks?**
Both perform command substitution (running a command and capturing its output). `$()` is modern, highly readable, and allows for easy nesting (`$(echo $(date))`). Backticks are legacy.

**How do you pass arguments to a script? (`$1`, `$2`, `$@`, `$#`, `$?`)**
- `$1, $2`: The first and second positional arguments.
- `$@`: An array of all arguments passed.
- `$#`: The total count of arguments passed.
- `$?`: The exit status code of the last executed command (0 = success).

**What is the difference between single quotes and double quotes?**
- **Single quotes (`'...'`):** Literal string. NO variable expansion (`'$USER'` stays `$USER`).
- **Double quotes (`"..."`):** Allows variable expansion and command substitution (`"$USER"` becomes `root`).

**How do you check if a file exists in a bash script?**
```bash
if [ -f "/var/log/syslog" ]; then
  echo "File exists"
fi
```

**What is a heredoc?**
A method to pass multi-line string input to a command without creating a separate file.
```bash
cat <<EOF > config.txt
line 1
line 2
EOF
```

**What is the difference between `source script.sh` and `./script.sh`?**
`source` (or `.`) runs the script in the *current* shell, meaning any environment variables set will persist in your session. `./` spawns a *subshell*, so any variables set are lost once the script finishes.

---

## Troubleshooting Scenarios

**A server has high CPU — what steps do you take?**
1. Run `top` or `htop` to identify the PID causing the spike.
2. Check if the process is multi-threaded: `htop -p <PID>`.
3. Use `strace -p <PID>` to see what system calls the process is stuck on.
4. Check `journalctl` for app-level errors.

**A server has high memory usage — how do you troubleshoot?**
1. Check overall RAM/Swap with `free -m`.
2. Find top consumers in `top` (Shift+M to sort by memory).
3. Check kernel logs for OOM events: `dmesg -T | grep -i oom`.

**Disk is 100% full — how do you troubleshoot?**
1. Confirm mount points with `df -h`.
2. Find large directories: `du -ahx / | sort -rh | head -n 10`.
3. Check for deleted open files: `lsof | grep deleted`.
4. Truncate logs instead of `rm` to safely free space immediately.

**A service is not starting — what commands do you use?**
1. Check status: `systemctl status <service>`.
2. View specific logs: `journalctl -u <service> -e`.
3. Manually test the app's configuration syntax (e.g., `nginx -t`, `sshd -t`).

**Application cannot connect to another server — how do you troubleshoot?**
1. ICMP Check: `ping host`.
2. DNS Check: `dig host`.
3. Port Check: `nc -zv host port`.
4. Network path: `mtr host`.
5. Check Security Groups/Firewalls on both ends.

**Port 8080 is not reachable — how do you debug?**
1. Verify the process is listening locally: `ss -tulpn | grep 8080`.
2. Ensure it's listening on `0.0.0.0` (all interfaces), not `127.0.0.1` (localhost only).
3. Check local OS firewall: `iptables -L` or `ufw status`.
4. Check cloud provider network firewalls (AWS SG, Azure NSG).

**Logs are filling the disk — how do you identify and fix the issue?**
Identify: `du -sh /var/log/* | sort -h`.
Fix: Truncate the file `> /var/log/app.log`. Set up and configure `/etc/logrotate.d/app` to automatically compress and rotate old logs daily.

**A process is consuming too much memory — what do you check?**
After finding the PID, inspect `/proc/<PID>/smaps` to see memory allocations. If it's a Java/Node/Go app, trigger a heap dump or use application-level profilers (like `pprof`) to find memory leaks.

**Server is slow — what is your systematic approach?**
Use the USE method (Utilization, Saturation, Errors):
- CPU: `uptime`, `top`
- RAM: `free -m`, `vmstat 1`
- Disk I/O: `iostat -xz 1` (look at `%util` and `await`)
- Network: `sar -n DEV 1` or `iftop`
- Logs: `dmesg -T`

**A Docker container is behaving unexpectedly — which Linux concepts/commands help?**
Containers are just isolated Linux processes.
- Find the host PID: `docker inspect -f '{{.State.Pid}}' container_name`
- Trace system calls: `strace -p <PID>`
- Enter namespaces directly from host: `nsenter -t <PID> -n ip a`

**How would you troubleshoot a production Linux server? (general methodology)**
1. **Define:** Understand the exact symptom (latency, error 500).
2. **Measure:** Check metrics (CPU, RAM, Disk, Net).
3. **Isolate:** Check logs to narrow down if it's application code, database, or infrastructure.
4. **Hypothesize & Test:** Make one change at a time.
5. **Mitigate/Fix & Document:** Restore service and write a post-mortem.

---

## Docker, Kubernetes & Linux

**What are Linux namespaces? Name the types.**
Namespaces provide isolation for processes, making a process believe it has its own OS.
Types: PID (Process IDs), NET (Networking interfaces), MNT (Mount points/filesystem), IPC (Interprocess comms), UTS (Hostname), USER (UID/GID).

**What are cgroups? Why are they important for containers?**
Control Groups. They limit, account for, and isolate physical resource usage (CPU, Memory, Disk I/O). Without cgroups, a single container could consume 100% of the host's RAM, crashing other containers.

**How does Docker use namespaces and cgroups?**
- **Namespaces** give the container *isolation* (its own IP, filesystem, and PID 1).
- **Cgroups** give the container *resource limits* (max 512MB RAM, 0.5 CPU).

**What is an overlay filesystem?**
A union filesystem that merges multiple directory layers into a single view. Docker uses this for images: read-only lower layers (the base image) combined with a writable upper layer (the running container).

**How do you inspect a container's process from the host?**
Containers are host processes. Find it: `docker inspect -f '{{.State.Pid}}' <container>`. Then run `ps -ef | grep <PID>` or `lsof -p <PID>` directly on the host.

**What is `nsenter`? How do you use it?**
Executes commands within an existing process's namespaces. Highly useful for debugging containers that lack shells (distroless).
```bash
nsenter -t <PID> -n -m /bin/bash
```
*(Enters the Network and Mount namespaces of the PID).*

**What Linux capabilities are relevant to containers?**
Capabilities break down full `root` privileges into granular permissions. Docker drops most by default. E.g., adding `CAP_NET_BIND_SERVICE` allows a non-root container to bind to port 80.

**What is `chroot`? How does it relate to containers?**
"Change root". It changes the apparent root directory `/` for a running process, jailing it in a specific folder. It is the primitive ancestor to modern container namespaces.

**How do you debug networking issues in a Kubernetes pod from a Linux perspective?**
1. SSH into the K8s worker node.
2. Find the container's PID via `crictl inspect`.
3. Use `nsenter -t <PID> -n tcpdump -i any` to capture packets natively within the pod's network namespace.

---

## Advanced Linux

**What is the OOM Killer? How does it decide which process to kill?**
The kernel's defense mechanism when RAM runs out. It calculates an `oom_score` for every process based on memory consumption. The process with the highest score is killed. Admins can tweak this using `oom_score_adj`.

**What is the difference between a major and minor page fault?**
- **Minor:** The requested memory page is loaded in RAM but not yet mapped to the process. Fast fix.
- **Major:** The page is NOT in RAM. The kernel must pause the process and perform a slow Disk I/O read (from swap or disk) to fetch it. High major faults indicate RAM starvation.

**What is `strace`? When do you use it?**
A system call and signal tracer. Used when an application is stuck, crashing without logs, or failing to read a file. It intercepts calls between the app and the kernel.
```bash
strace -p <PID> -e trace=open,read
```

**What is `lsof`? Give practical examples.**
"List Open Files". Since everything in Linux is a file, this is powerful.
- Find listening ports: `lsof -iTCP -sTCP:LISTEN`
- Find deleted files holding space: `lsof +L1`
- Find files opened by a specific user: `lsof -u root`

**What is `dmesg`? When do you use it?**
Prints the kernel ring buffer. Used to debug hardware failures, network interface flapping, failing disk drives, or finding out if the OOM killer terminated a process.

**What are kernel modules? How do you list/load/unload them?**
Pieces of code (usually device drivers) that can be loaded into the kernel dynamically on demand.
- List: `lsmod`
- Load: `modprobe <module_name>`
- Unload: `modprobe -r <module_name>`

**What is the difference between Enforcing, Permissive, and Disabled modes in SELinux?**
- **Enforcing:** Security policies are actively enforced; unauthorized actions are blocked and logged.
- **Permissive:** Policies are NOT enforced, but violations are logged (ideal for debugging).
- **Disabled:** SELinux is completely turned off.

**How do you persist sysctl changes?**
Kernel parameters changed via `sysctl -w net.ipv4.ip_forward=1` are lost on reboot. To persist, add them to `/etc/sysctl.conf` and run `sysctl -p`.

**What is a file descriptor? What is the default limit?**
An integer that the kernel uses to identify an open file, socket, or pipe for a process. Default limits are usually 1024 per process (`ulimit -n`). Exhausting this causes "Too many open files" errors.

**What is `epoll`? Why is it relevant for high-performance servers?**
An efficient I/O event notification facility in Linux (replacing `select`/`poll`). It allows applications like Nginx, Redis, and Node.js to handle tens of thousands of concurrent connections (C10K problem) without wasting CPU polling sockets.

**What is PAM in Linux?**
Pluggable Authentication Modules. A framework that centralizes authentication mechanisms. It allows admins to enforce password complexity, configure LDAP, or add MFA without modifying the underlying applications (like SSH). Configured in `/etc/pam.d/`.
