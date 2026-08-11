Yes. Before the DEV/UAT/PROD project, let's finish **Conditionals + Loops** properly. These two are used constantly in production playbooks.

---

# 1. Conditionals — `when`

The basic idea is:

> **Run this task only if a condition is true.**

Example:

```yaml
- name: Install nginx
  ansible.builtin.apt:
    name: nginx
    state: present
  when: ansible_facts['distribution'] == "Ubuntu"
```

Meaning:

```text
Is OS Ubuntu?
     │
   YES ──→ Install nginx
     │
    NO ──→ Skip task
```

---

# 2. Conditional based on Facts

We already saw Facts:

```yaml
ansible_facts['distribution']
ansible_facts['os_family']
ansible_facts['architecture']
ansible_facts['memtotal_mb']
```

These can directly be used in `when`.

### Example: Ubuntu vs RedHat

```yaml
---
- name: Configure Linux servers
  hosts: all
  become: true

  tasks:

    - name: Install nginx on Ubuntu
      ansible.builtin.apt:
        name: nginx
        state: present
      when: ansible_facts['os_family'] == "Debian"

    - name: Install nginx on RedHat
      ansible.builtin.dnf:
        name: nginx
        state: present
      when: ansible_facts['os_family'] == "RedHat"
```

Notice something important:

We don't need:

```text
Ubuntu server → Ubuntu playbook
RHEL server   → RHEL playbook
```

We can have:

```text
             Same Playbook
                  │
          ┌───────┴───────┐
          ↓               ↓
      Debian           RedHat
          ↓               ↓
         apt             dnf
```

That's a major benefit of Ansible.

---

# 3. Conditional based on Variables

Suppose:

```yaml
vars:
  install_nginx: true
```

Then:

```yaml
- name: Install nginx
  ansible.builtin.apt:
    name: nginx
    state: present
  when: install_nginx
```

If:

```yaml
install_nginx: true
```

→ task runs.

If:

```yaml
install_nginx: false
```

→ task is skipped.

---

# 4. Variable comparison

You can also compare values.

```yaml
vars:
  environment: prod

tasks:

  - name: Restart application
    ansible.builtin.service:
      name: myapp
      state: restarted
    when: environment == "prod"
```

So:

```text
environment = prod
       ↓
Restart app
```

But:

```text
environment = dev
       ↓
Skip
```

---

# 5. Multiple conditions

You can use `and`:

```yaml
when:
  - environment == "prod"
  - ansible_facts['os_family'] == "Debian"
```

Both conditions must be true.

Equivalent:

```yaml
when: environment == "prod" and ansible_facts['os_family'] == "Debian"
```

I prefer the list format in production because it is easier to read:

```yaml
when:
  - environment == "prod"
  - ansible_facts['os_family'] == "Debian"
```

---

# 6. `or`

```yaml
when:
  - ansible_facts['distribution'] == "Ubuntu"
    or ansible_facts['distribution'] == "Debian"
```

Meaning:

```text
Ubuntu OR Debian
```

---

# 7. `not`

```yaml
when: not maintenance_mode
```

Meaning:

> Run when maintenance mode is NOT enabled.

---

# 8. `is defined`

Very useful when working with variables.

```yaml
when: app_version is defined
```

Meaning:

> Run only if `app_version` exists.

Example:

```yaml
- name: Deploy application
  ansible.builtin.debug:
    msg: "Deploying {{ app_version }}"
  when: app_version is defined
```

You can also use:

```yaml
when: app_version is not defined
```

---

# 9. `failed` / `success` with registered variables

This connects directly with what we learned earlier about `register`.

```yaml
- name: Check application
  ansible.builtin.command: systemctl is-active myapp
  register: app_status
  changed_when: false
  failed_when: false
```

Then:

```yaml
- name: Restart application
  ansible.builtin.service:
    name: myapp
    state: restarted
  when: app_status.rc != 0
```

Flow:

```text
Check application
       ↓
register result
       ↓
rc == 0?
 ┌─────┴─────┐
YES         NO
 │           │
Running    Restart
```

This pattern is extremely common.

---

# 10. Conditional based on command output

Example:

```yaml
- name: Check application version
  ansible.builtin.command: /opt/myapp/bin/version
  register: version_output
  changed_when: false
```

Suppose output is:

```text
1.5.2
```

You could do:

```yaml
- name: Upgrade application
  ansible.builtin.debug:
    msg: "Upgrade required"
  when: version_output.stdout != "1.5.3"
```

---

# 11. Re-using conditionals

Ansible allows you to reuse logic with constructs such as `include_tasks`, `import_tasks`, roles, and variables.

A simple example:

```yaml
vars:
  is_production: "{{ environment == 'prod' }}"
```

Then:

```yaml
- name: Restart production service
  ansible.builtin.service:
    name: myapp
    state: restarted
  when: is_production
```

Instead of repeatedly writing:

```yaml
when: environment == "prod"
```

This becomes especially useful as playbooks grow.

---

# Coding Exercise 1 — Conditionals

Don't just read this one. Try to solve it.

### Inventory

```ini
[servers]
server01
server02
server03
```

Create a playbook:

```yaml
conditional.yml
```

Requirements:

### Task 1

Print:

```text
Running on <hostname>
```

using the Ansible fact.

### Task 2

Install `nginx` **only if**:

```text
OS family = Debian
```

### Task 3

Create:

```text
/opt/production
```

**only if**:

```yaml
environment == "prod"
```

### Task 4

Create:

```text
/opt/development
```

**only if**:

```yaml
environment == "dev"
```

### Task 5

Set:

```yaml
environment: prod
```

in the playbook.

Your skeleton:

```yaml
---
- name: Conditional exercise
  hosts: servers
  become: true

  vars:
    environment: prod

  tasks:

    # Task 1


    # Task 2


    # Task 3


    # Task 4
```

Try writing it yourself before looking up the solution.

---

# 12. Loops

Now the second major concept.

Suppose you need to install:

```text
nginx
curl
git
vim
```

Without a loop:

```yaml
- name: Install nginx
  ansible.builtin.apt:
    name: nginx
    state: present

- name: Install curl
  ansible.builtin.apt:
    name: curl
    state: present

- name: Install git
  ansible.builtin.apt:
    name: git
    state: present

- name: Install vim
  ansible.builtin.apt:
    name: vim
    state: present
```

That's repetitive.

With a loop:

```yaml
- name: Install required packages
  ansible.builtin.apt:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - curl
    - git
    - vim
```

Much cleaner.

---

# 13. How does `item` work?

This:

```yaml
loop:
  - nginx
  - curl
  - git
```

means Ansible executes the task three times.

Internally:

```text
item = nginx
     ↓
Install nginx

item = curl
     ↓
Install curl

item = git
     ↓
Install git
```

So:

```yaml
name: "{{ item }}"
```

changes on every iteration.

---

# 14. Loop with files

Suppose you need to create:

```text
/opt/app
/opt/app/logs
/opt/app/config
/opt/app/data
```

You could do:

```yaml
- name: Create application directories
  ansible.builtin.file:
    path: "{{ item }}"
    state: directory
    mode: '0755'
  loop:
    - /opt/app
    - /opt/app/logs
    - /opt/app/config
    - /opt/app/data
```

Very common pattern.

---

# 15. Loop with users

Suppose production requires:

```text
deploy
jenkins
monitoring
```

You can do:

```yaml
- name: Create users
  ansible.builtin.user:
    name: "{{ item }}"
    state: present
  loop:
    - deploy
    - jenkins
    - monitoring
```

---

# 16. Loop with dictionaries

This is where loops become more powerful.

Suppose we want different users with different shells:

```yaml
users:
  - name: deploy
    shell: /bin/bash

  - name: monitoring
    shell: /bin/sh
```

Then:

```yaml
- name: Create users
  ansible.builtin.user:
    name: "{{ item.name }}"
    shell: "{{ item.shell }}"
    state: present

  loop: "{{ users }}"
```

Now:

```text
item.name
item.shell
```

are available for each iteration.

---

# 17. Production-style loop

Imagine application configuration:

```yaml
services:
  - name: payment
    port: 8080

  - name: order
    port: 8081

  - name: user
    port: 8082
```

You can process all of them:

```yaml
- name: Display services
  ansible.builtin.debug:
    msg: "{{ item.name }} runs on port {{ item.port }}"
  loop: "{{ services }}"
```

Output:

```text
payment runs on port 8080
order runs on port 8081
user runs on port 8082
```

This pattern is extremely useful when managing multiple application components.

---

# 18. Loop + Conditional

This is where the two concepts combine.

```yaml
packages:
  - nginx
  - curl
  - git
```

Then:

```yaml
- name: Install packages
  ansible.builtin.apt:
    name: "{{ item }}"
    state: present
  loop: "{{ packages }}"
  when: ansible_facts['os_family'] == "Debian"
```

Flow:

```text
packages
   ↓
nginx → condition → install
curl  → condition → install
git   → condition → install
```

---

# Coding Exercise 2 — Loops

Create:

```text
loops.yml
```

### Task 1

Install these packages:

```text
nginx
curl
git
unzip
```

using **one task + loop**.

### Task 2

Create these directories:

```text
/opt/myapp
/opt/myapp/logs
/opt/myapp/config
/opt/myapp/data
```

using **one task + loop**.

### Task 3

Create these users:

```text
deploy
monitoring
backup
```

using one task + loop.

### Task 4 — slightly harder

Create users with different shells:

```yaml
users:
  - name: deploy
    shell: /bin/bash

  - name: monitoring
    shell: /bin/sh

  - name: backup
    shell: /bin/bash
```

Create them using:

```text
one task
+
loop
```

---

# 19. The two concepts together

At this point you should be able to understand something like this:

```yaml
---
- name: Configure application servers
  hosts: app
  become: true

  vars:
    environment: prod

    packages:
      - curl
      - git
      - unzip

  tasks:

    - name: Install packages
      ansible.builtin.apt:
        name: "{{ item }}"
        state: present
      loop: "{{ packages }}"
      when: ansible_facts['os_family'] == "Debian"

    - name: Create production directory
      ansible.builtin.file:
        path: /opt/myapp
        state: directory
        mode: '0755'
      when: environment == "prod"
```

Read it in plain English:

> For every package in my package list, install it if the server is Debian-based.
> Create the production application directory only when the environment is production.

That's exactly the kind of thinking you need for Ansible.
