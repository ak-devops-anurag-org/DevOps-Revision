# Linux Filesystem & Commands

## Filesystem Hierarchy Standard (FHS)

| Directory | Purpose |
|---|---|
| `/` | Root directory; top of the hierarchy. |
| `/bin` | Essential user command binaries (e.g., `ls`, `cp`). |
| `/sbin` | System administration binaries (e.g., `fdisk`, `iptables`). |
| `/etc` | **[DevOps]** Host-specific system configuration files. |
| `/home` | User home directories. |
| `/root` | Home directory for the root user. |
| `/var` | **[DevOps]** Variable data files (logs, databases, spools). |
| `/var/log` | **[DevOps]** System and application log files. |
| `/var/tmp` | Temporary files preserved between reboots. |
| `/tmp` | Temporary files (often cleared on reboot). |
| `/usr` | Secondary hierarchy for read-only user data. |
| `/usr/bin` | Non-essential command binaries. |
| `/usr/sbin` | Non-essential system binaries. |
| `/usr/local` | Locally installed software. |
| `/opt` | **[DevOps]** Add-on application software packages. |
| `/lib` | Essential shared libraries and kernel modules. |
| `/lib64` | 64-bit shared libraries. |
| `/boot` | Static files of the boot loader (kernel, initramfs). |
| `/dev` | Device files (e.g., `/dev/sda`, `/dev/null`). |
| `/proc` | **[DevOps]** Virtual filesystem providing process and kernel info. |
| `/sys` | **[DevOps]** Virtual filesystem for device and driver information. |
| `/mnt` | Temporary mount point for filesystems. |
| `/media` | Mount points for removable media. |
| `/srv` | Data for services provided by the system. |
| `/run` | Run-time variable data (PIDs, sockets). |

> [!TIP]
> **DevOps Highlights:** `/etc` (config), `/var/log` (troubleshooting), `/proc` & `/sys` (performance tuning/monitoring), `/opt` (third-party apps).

---

## Inodes & Links

- **Inode (Index Node):** A data structure storing metadata about a file or directory (everything except the filename and actual data).
- **Stores:** File size, owner, group, permissions, timestamps (atime, mtime, ctime), and pointers to data blocks.
- **Check Inodes:** `ls -i <file>` (view inode number), `df -i` (view filesystem inode usage).

### Hard Links vs. Soft (Symbolic) Links

| Feature | Hard Link (`ln`) | Soft Link (`ln -s`) |
|---|---|---|
| **What it is** | Another name pointing to the *same inode*. | A special file pointing to the *path* of another file. |
| **Cross-Filesystem** | No (must be on the same partition). | Yes. |
| **Link to Directory** | No. | Yes. |
| **If Original Deleted** | Data remains until *all* hard links are removed. | Link breaks (becomes an "orphan" or "dangling" link). |
| **Command** | `ln target link_name` | `ln -s target link_name` |

> [!IMPORTANT]
> **DevOps Scenario: "Disk Full" but `df -h` shows space?**
> This indicates **Inode Exhaustion**. Too many small files have consumed all available inodes. Check with `df -i`. Find culprits using: `find / -xdev -type d -size +100k` or `du -sh * | sort -rh`.

---

## File & Directory Operations

| Command | Purpose | Command | Purpose |
|---|---|---|---|
| `ls` | List directory contents | `cat` | Concatenate and print files |
| `cd` | Change directory | `head` | Output first 10 lines |
| `pwd` | Print working directory | `tail` | Output last 10 lines |
| `mkdir` | Make directories | `less` | View file with pagination (forward/backward) |
| `rmdir` | Remove empty directories | `more` | View file with pagination (forward only) |
| `rm` | Remove files/directories | `wc` | Word, line, character count |
| `cp` | Copy files/directories | `file` | Determine file type |
| `mv` | Move/rename files | `stat` | Display file/file system status (inode info) |
| `touch` | Change timestamps / Create empty file | `tree` | List contents in a tree-like format |

### Key Flags & Usages
- **`ls` flags:** `-la` (all, long format), `-lh` (human-readable sizes), `-lt` (sort by time), `-lS` (sort by size), `-R` (recursive), `-i` (show inodes).
- **Log Monitoring:**
  - `tail -f file.log`: Output appended data as the file grows.
  - `tail -F file.log`: Same as `-f`, but handles file rotation (reopens if file is recreated).
- **Directory Creation:** `mkdir -p /path/to/nested/dir` (creates parent directories if needed).
- **Deletion:** `rm -rf /dir` (recursive, force — **Caution!**)

---

## Text Processing Power Tools

### `grep`
- **Purpose:** Search text using patterns.
- **Flags:** `-i` (ignore case), `-r` (recursive), `-v` (invert match), `-n` (line numbers), `-c` (count), `-l` (filenames only), `-E` (extended regex = `egrep`), `-A 3` (after), `-B 3` (before), `-C 3` (context).
- **Practical:**
  ```bash
  grep -i "error" /var/log/syslog              # Find errors
  grep -v "^#" /etc/ssh/sshd_config | grep -v "^$" # View config without comments/empty lines
  grep -rnw '/var/www/' -e "database_password" # Search recursively for string
  ```

### `awk`
- **Purpose:** Text processing and data extraction.
- **Syntax:** `awk -F'delimiter' '/pattern/ {action}' file`
- **Built-ins:** `NR` (Record/Line number), `NF` (Number of fields), `$0` (Whole line), `$1` (Field 1).
- **Practical:**
  ```bash
  awk '{print $1, $3}' file.txt                # Print 1st and 3rd columns (space delimited)
  awk -F: '{print $1}' /etc/passwd             # Extract all usernames
  awk '{sum+=$1} END {print sum}' numbers.txt  # Sum values in the first column
  df -h | awk '$5 > 90 {print $0}'             # Alert if disk usage > 90%
  ```

### `sed`
- **Purpose:** Stream editor for filtering and transforming text.
- **Practical:**
  ```bash
  sed 's/old/new/g' file.txt                   # Replace all occurrences in stream
  sed -i 's/AllowOverride None/AllowOverride All/g' httpd.conf # In-place edit
  sed '/^#/d' config.ini                       # Delete commented lines
  sed -n '5,10p' file.txt                      # Print only lines 5 through 10
  ```

### `cut`
- **Purpose:** Remove sections from each line of files.
- **Practical:**
  ```bash
  cut -d: -f1 /etc/passwd                      # Extract usernames (delimiter :, field 1)
  cut -d, -f1,3 data.csv                       # Extract 1st and 3rd columns from CSV
  ```

### `sort` & `uniq`
- **Purpose:** Sort lines and report/omit repeated lines.
- **Flags:** `sort` `-n` (numeric), `-r` (reverse), `-k` (key/column), `-t` (delimiter). `uniq` `-c` (count), `-d` (duplicate).
- **Practical:**
  ```bash
  cat access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head -10 # Top 10 IP addresses
  ```

### `find`
- **Purpose:** Search for files in a directory hierarchy.
- **Flags:** `-name` (pattern), `-iname` (case-insensitive), `-type f\|d`, `-size +100M`, `-mtime +30` (modified >30 days), `-exec` (execute command), `-delete` (delete found items).
- **Practical:**
  ```bash
  find /var/log -name "*.log" -mtime +7 -delete       # Delete logs older than 7 days
  find / -type f -size +1G                            # Find files larger than 1GB
  find . -type f -name "*.bak" -exec rm {} \;         # Find and remove .bak files
  ```

### `xargs`
- **Purpose:** Build and execute command lines from standard input.
- **Practical:**
  ```bash
  find . -name "*.tmp" | xargs rm                     # Delete tmp files (handles many files better than -exec)
  cat urls.txt | xargs -I {} wget {}                  # Download all URLs from a file
  ```

### Other Useful Tools
- **`tr`**: Translate or delete characters (e.g., `cat file \| tr 'a-z' 'A-Z'`).
- **`diff`**: Compare files line by line (e.g., `diff config.old config.new`).
- **`comm`**: Compare two sorted files line by line.
- **`paste`**: Merge lines of files.
- **`tee`**: Read from stdin and write to stdout and files (e.g., `echo "data" \| tee -a file.txt`).

---

## Archiving & Compression

| Format/Tool | Compress / Create | Extract / Uncompress | View Contents |
|---|---|---|---|
| **tar (archive)** | `tar -cvf archive.tar dir/` | `tar -xvf archive.tar` | `tar -tvf archive.tar` |
| **tar.gz** | `tar -czvf archive.tar.gz dir/` | `tar -xzvf archive.tar.gz` | `tar -tzvf archive.tar.gz` |
| **gzip** | `gzip file.txt` (.gz) | `gunzip file.txt.gz` | `zcat file.txt.gz` |
| **bzip2** | `bzip2 file.txt` (.bz2) | `bunzip2 file.txt.bz2` | `bzcat file.txt.bz2` |
| **zip** | `zip -r arch.zip dir/` | `unzip arch.zip` | `unzip -l arch.zip` |

---

## Quick Reference — Commands to Remember

| Task | Command |
|---|---|
| Check free disk / inodes | `df -h` / `df -i` |
| Top 10 largest files/dirs | `du -sh * \| sort -rh \| head -10` |
| Live log monitoring | `tail -f /var/log/syslog` |
| Find files > 500MB | `find / -type f -size +500M` |
| Search config without comments | `grep -vE "^#\|^\$" /etc/config` |
| Extract IPs from log | `awk '{print $1}' access.log \| sort \| uniq -c \| sort -nr` |
| In-place replace in config | `sed -i 's/old/new/g' config.txt` |
| Extract archive | `tar -xzvf file.tar.gz` |
