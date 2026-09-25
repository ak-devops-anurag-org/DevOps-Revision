# Linux Storage, Permissions & Security

## File Permissions & Ownership

### The Permission Triplet
Permissions are divided into three triplets: **User** (Owner), **Group**, and **Others**.
- `r` = Read (4)
- `w` = Write (2)
- `x` = Execute (1)

### Reading `ls -l` Output
```text
-rwxr-xr-- 1 user group 4096 Jan  1 12:00 file.txt
| |  |  |  | |    |     |    |            |
| |  |  |  | |    |     |    |            +-- File name
| |  |  |  | |    |     |    +-- Date/Time
| |  |  |  | |    |     +-- Size (bytes)
| |  |  |  | |    +-- Group owner
| |  |  |  | +-- User owner
| |  |  |  +-- Link count
| |  |  +-- Others perms (r--)
| |  +-- Group perms (r-x)
| +-- User perms (rwx)
+-- File type (- = file, d = dir, l = symlink)
```

### Numeric (Octal) Permissions Table

| Permission | Binary | Octal | Meaning |
| :--- | :--- | :--- | :--- |
| `rwx` | `111` | `7` | Read, Write, Execute |
| `rw-` | `110` | `6` | Read, Write |
| `r-x` | `101` | `5` | Read, Execute |
| `r--` | `100` | `4` | Read only |
| `-wx` | `011` | `3` | Write, Execute |
| `-w-` | `010` | `2` | Write only |
| `--x` | `001` | `1` | Execute only |
| `---` | `000` | `0` | No permissions |

### Common Permission Sets
- `755`: User can do all; group/others can read & execute (Common for scripts/directories)
- `644`: User can read/write; group/others can read (Common for config/text files)
- `700`: Only user can do all (Common for `.ssh/` dirs)
- `600`: Only user can read/write (Common for private keys, e.g., `id_rsa`)
- `777`: Everyone can do everything (Insecure)
- `400`: Only user can read (Very strict, good for private keys)

### `chmod` & `chown`

**chmod** - Change mode/permissions
```bash
# Symbolic Mode
chmod u+x file.sh       # Add execute to user
chmod go-w file.txt     # Remove write from group & others
chmod a=r file.txt      # Set all to read-only

# Numeric Mode
chmod 755 script.sh
chmod -R 644 dir/       # Recursive (files and dirs)
```

**chown** & **chgrp** - Change ownership
```bash
chown user file.txt            # Change user owner
chown user:group file.txt      # Change user and group
chown -R user:group dir/       # Recursive
chgrp groupname file.txt       # Change group owner
```

### Special Permissions

- **SUID (4xxx)**: File executes with the permissions of the file owner, not the user running it.
  - Set: `chmod u+s file` or `chmod 4755 file`
  - Identify: `s` in user execute bit (`-rwsr-xr-x`)
  - Example: `/usr/bin/passwd`
  - Risk: SUID root binaries can lead to privilege escalation.
- **SGID (2xxx)**: File executes as the group owner. Directories: new files inherit the directory's group.
  - Set: `chmod g+s dir` or `chmod 2755 dir`
  - Identify: `s` in group execute bit (`-rwxr-sr-x`)
  - Use: Shared collaborative directories.
- **Sticky Bit (1xxx)**: In shared directories, only the file owner (or root) can delete/rename a file.
  - Set: `chmod +t dir` or `chmod 1777 dir`
  - Identify: `t` in others execute bit (`drwxrwxrwt`)
  - Example: `/tmp`

### umask
- **Concept**: The default permission mask subtracted from base permissions when creating new files/dirs.
- **Base permissions**: Files = `666`, Directories = `777`
- **Calculation**: Base - umask = Actual Permissions
- **Default (022)**:
  - Files: `666` - `022` = `644` (`rw-r--r--`)
  - Dirs: `777` - `022` = `755` (`rwxr-xr-x`)
- **Where it's set**: `~/.bashrc`, `/etc/profile`, `/etc/login.defs`

---

## Users & Groups

### Key Configuration Files

- **/etc/passwd**: Local user account info. (World-readable)
  - Format: `root:x:0:0:root:/root:/bin/bash` (`user:password_placeholder:UID:GID:comment:home_dir:shell`)
- **/etc/shadow**: Secure password hashes and aging info. (Readable only by root)
  - Format: `root:$6$...:18000:0:99999:7:::` (`user:hash:last_changed:min:max:warn:inactive:expire`)
- **/etc/group**: Group information.
  - Format: `wheel:x:10:root,anurag` (`group_name:password_placeholder:GID:member_list`)

### User & Group Management Commands

| Command | Description | Example |
| :--- | :--- | :--- |
| `useradd` | Create new user | `useradd -m -s /bin/bash devuser` |
| `usermod` | Modify user | `usermod -aG docker devuser` (Append to group) |
| `userdel` | Delete user | `userdel -r devuser` (Remove home dir) |
| `groupadd` | Create new group | `groupadd devops` |
| `groupmod` | Modify group | `groupmod -n newname oldname` |
| `groupdel` | Delete group | `groupdel devops` |
| `passwd` | Set password | `passwd devuser` |
| `id` | Show UID/GID | `id devuser` |
| `whoami` | Print effective user | `whoami` |
| `w` / `who` | Show logged in users | `w` |
| `last` | Show login history | `last -n 10` |
| `su` | Substitute user | `su - devuser` (Login shell) |
| `sudo` | Run as root | `sudo systemctl restart nginx` |

### `sudo` vs `su`
- **`su` (Substitute User)**: Requires knowing the *target user's password* (usually root). Switches your session.
- **`sudo` (Superuser DO)**: Requires knowing *your own password*. Grants temporary privileges based on `/etc/sudoers`. Auditable.

### `/etc/sudoers` & `visudo`
- Always edit `/etc/sudoers` using the `visudo` command (checks syntax before saving to prevent lockouts).
- **Syntax Example**:
  ```text
  # User/Group  Host=(RunAs)       Commands
  devuser       ALL=(ALL)          ALL                  # devuser can run anything
  %devops       ALL=(root)         /bin/systemctl       # devops group can run systemctl as root
  anurag        ALL=(ALL) NOPASSWD: ALL                 # No password prompt required
  ```

---

## Disk & Storage

Linux treats everything as a file, including storage devices (block devices).
- **Block Devices**: `/dev/sda`, `/dev/nvme0n1`
- **Partitions**: `/dev/sda1`, `/dev/sda2`
- **Common Filesystems**:
  - `ext4`: Standard, reliable Linux filesystem.
  - `xfs`: High performance, great for large files, default on RHEL/CentOS.
  - `btrfs`: Advanced features like snapshots, pooling.
  - `tmpfs`: RAM-based filesystem (lost on reboot).
  - `swap`: Virtual memory on disk.

### Storage Commands

| Command | Purpose | Example |
| :--- | :--- | :--- |
| `df -h` | Disk free space (human-readable) | `df -h /` |
| `df -i` | Inode usage | `df -i` |
| `du -sh` | Disk usage for a specific file/dir | `du -sh /var/log` |
| `lsblk` | List block devices | `lsblk` |
| `blkid` | Show block device attributes (UUIDs) | `blkid /dev/sda1` |
| `fdisk` | Partition table manipulator | `fdisk /dev/sda` |
| `parted` | Partition manipulator (supports >2TB) | `parted /dev/sda` |
| `mkfs` | Make filesystem (format) | `mkfs.ext4 /dev/sdb1` |
| `mount` | Mount a filesystem | `mount /dev/sdb1 /mnt/data` |
| `umount` | Unmount a filesystem | `umount /mnt/data` |
| `findmnt` | Find mounted filesystems | `findmnt /` |

### Persistent Mounts: `/etc/fstab`
Used to mount filesystems automatically on boot.
- Format (6 fields): `<Device/UUID> <MountPoint> <FileSystemType> <Options> <Dump> <Pass>`
- Example: `UUID=1234-5678 /data ext4 defaults 0 2`
- Tip: Always use UUIDs instead of `/dev/sdX` which can change across reboots.

### Swap Management
- `mkswap /dev/sdb2`: Format partition as swap
- `swapon /dev/sdb2`: Enable swap
- `swapoff /dev/sdb2`: Disable swap
- `free -h`: Check swap usage

### LVM (Logical Volume Manager) Basics
Abstraction layer over physical disks allowing resizing.
1. **PV (Physical Volume)**: `pvcreate /dev/sdb`
2. **VG (Volume Group)**: `vgcreate data_vg /dev/sdb`
3. **LV (Logical Volume)**: `lvcreate -L 10G -n app_lv data_vg`
- **Extending**:
  ```bash
  lvextend -L +5G /dev/data_vg/app_lv
  resize2fs /dev/data_vg/app_lv  # for ext4
  # or xfs_growfs /mnt/data      # for xfs
  ```

### RAID Levels Overview

| Level | Name | Features | Fault Tolerance |
| :--- | :--- | :--- | :--- |
| **RAID 0** | Striping | High Perf, Max Space | None (1 drive dies = total data loss) |
| **RAID 1** | Mirroring | Data duplicated | Yes (1 drive failure) |
| **RAID 5** | Striping + Parity | Good Perf, Efficient Space | Yes (1 drive failure) |
| **RAID 6** | Striping + Double Parity | Good Perf, Less Space | Yes (2 drives failure) |
| **RAID 10**| Striping + Mirroring | Excellent Perf & Reliability | Yes (Up to 1 per mirror pair) |

### Disk Troubleshooting

- **Disk 100% full**:
  - `df -h`: Verify which partition is full.
  - `du -sh /* 2>/dev/null | sort -rh | head`: Find largest dirs.
  - **Deleted but open files holding space**: `lsof | grep deleted` (Fix by restarting the service holding the file).
- **Inode exhaustion** (`No space left on device` but `df -h` shows space):
  - `df -i`: Check inode usage.
  - Usually caused by millions of tiny files (e.g., session files, cron emails).
- **Read-only filesystem**:
  - Remount read-write: `mount -o remount,rw /`
  - Check `dmesg -T` for hardware/disk errors that caused the OS to remount as read-only for protection.

---

## Linux Security Basics

- **Principle of Least Privilege**: Users and applications should only have the minimum permissions necessary to function.

### Firewalls: `iptables`, `firewalld`, `ufw`

**iptables** (Underlying firewall tool)
- **Tables**: `filter` (default), `nat`, `mangle`.
- **Chains (filter)**: `INPUT`, `OUTPUT`, `FORWARD`.
- Commands:
  - `iptables -L -n -v`: List rules.
  - `iptables -A INPUT -p tcp --dport 22 -j ACCEPT`: Append rule.
  - `iptables -F`: Flush (delete all) rules.

**firewalld** (RHEL/CentOS default)
- Zone-based.
- Commands:
  - `firewall-cmd --get-active-zones`
  - `firewall-cmd --zone=public --add-service=http --permanent`
  - `firewall-cmd --reload`

**ufw** (Ubuntu default)
- Simplified interface for iptables.
- Commands:
  - `ufw status`
  - `ufw allow 22/tcp`
  - `ufw enable`

### SELinux (Security-Enhanced Linux)
- **What**: Mandatory Access Control (MAC) system. Restricts access based on contexts (labels) attached to files, processes, and users.
- **Modes**:
  - `Enforcing`: Actively blocks denied actions.
  - `Permissive`: Logs denied actions but allows them (good for troubleshooting).
  - `Disabled`: Turned off entirely (requires reboot).
- **Commands**:
  - `getenforce` / `setenforce 0` (Set to permissive temporarily).
  - Config file: `/etc/selinux/config`.
  - `ls -Z`: View SELinux contexts of files.
  - `restorecon -Rv /var/www`: Restore default contexts.
  - `getsebool -a` / `setsebool -P httpd_can_network_connect 1`: Manage booleans.
- **Troubleshooting**: Check `/var/log/audit/audit.log`. Use `audit2allow -w -a` to understand why it was blocked.

### AppArmor
- **What**: Profile-based MAC system (Default on Ubuntu).
- **Commands**: `aa-status`, `aa-enforce`, `aa-complain`, `aa-disable`.
- **Profiles Location**: `/etc/apparmor.d/`

### Other Security Concepts
- **PAM (Pluggable Authentication Modules)**: Framework that handles authentication for login, su, sudo, etc.
- **fail2ban**: Scans logs for failed logins and automatically updates firewall rules to ban the IP.
- **auditd**: Access monitoring and accounting for Linux (e.g., track who edited `/etc/passwd`).
- **Certificates**: Managed via `openssl` (e.g., `openssl x509 -in cert.pem -text -noout` to view cert details).

---

## Container-Relevant Linux Concepts

Containers are just Linux processes heavily isolated using core kernel features.

### Namespaces
Namespaces isolate system resources. A process in one namespace cannot see resources in another.
- **PID**: Process IDs (Container PID 1 is distinct from host PID).
- **NET**: Network interfaces, routing tables, IP addresses.
- **MNT**: Mount points and filesystems.
- **UTS**: Hostname and domain name.
- **IPC**: Inter-Process Communication.
- **USER**: User and Group IDs.
- **CGROUP**: Cgroup root directory isolation.
- **Commands**: `unshare` (run program with some namespaces unshared from parent) and `nsenter` (enter existing namespaces).

### Cgroups (Control Groups)
Cgroups limit and account for resource usage (CPU, memory, disk I/O).
- **v1 vs v2**: v2 provides a unified hierarchy, better memory tracking, and safer delegation.
- **Location**: Mounted at `/sys/fs/cgroup/`.
- **Docker**: Uses cgroups to enforce `--memory` or `--cpus` limits.

### Docker Core Mechanisms
- Docker uses **Namespaces** for *isolation*.
- Docker uses **Cgroups** for *resource limits*.
- **Overlay Filesystem (OverlayFS)**: Used to build container images layer-by-layer. Combines a read-only lower directory (image) and a read-write upper directory (container changes).
- **Networking**: Uses **veth (Virtual Ethernet) pairs** connected to a Linux **bridge** (`docker0`) to route traffic to the host.

### Capabilities
Fine-grained root privileges. Instead of granting full root access, containers run with dropped capabilities.
- Examples: `CAP_NET_ADMIN` (modify network config), `CAP_SYS_ADMIN` (broad admin rights - dangerous!).

### `chroot`
Changes the apparent root directory for the current running process. An early predecessor to containers, providing basic filesystem isolation.

---

## Quick Reference — Commands to Remember

| Debugging Task | Command |
| :--- | :--- |
| Find container PID | `docker inspect -f '{{.State.Pid}}' <container>` |
| View container processes | `ps auxf` (They run directly on the host kernel!) |
| Enter Network Namespace | `nsenter -t <PID> -n ip a` |
| Enter Mount Namespace | `nsenter -t <PID> -m ls /` |
| Enter all Namespaces | `nsenter -t <PID> -a /bin/bash` |
| View network namespaces | `ip netns list` |
| Check Memory Limit | `cat /sys/fs/cgroup/memory/docker/<id>/memory.limit_in_bytes` |
