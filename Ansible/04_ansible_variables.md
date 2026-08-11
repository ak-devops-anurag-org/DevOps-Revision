# Variables in Ansible

The four concepts are connected:

```text
Variables
   │
   ├── Registering variables
   │
   ├── Variable scope
   │
   ├── Variable precedence
   │
   ├── Magic variables
   │
   └── Facts
```

---

# 1. Variables in Ansible

Think of an Ansible variable exactly like a variable in programming.

Instead of hardcoding:

```yaml
port: 8080
```

you define:

```yaml
app_port: 8080
```

and use:

```yaml
port: "{{ app_port }}"
```

### Example

```yaml
---
- name: Deploy application
  hosts: app_servers

  vars:
    app_name: myapp
    app_port: 8080

  tasks:
    - name: Show application details
      ansible.builtin.debug:
        msg: "Deploying {{ app_name }} on port {{ app_port }}"
```

Output:

```text
Deploying myapp on port 8080
```

### Why variables matter in production

Suppose:

```text
DEV     → port 8080
UAT     → port 8081
PROD    → port 80
```

You don't want three different playbooks.

You want:

```text
Same Playbook
      +
Different Variables
      =
Different Environments
```

That's one of the most important Ansible patterns.

---

# 2. Where can variables come from?

This is where Ansible becomes interesting.

Variables can come from:

```text
Inventory
Playbook
group_vars
host_vars
Command line
Registered variables
Facts
Role defaults
Role vars
Extra vars
etc.
```

Example inventory:

```ini
[web]
web01 ansible_host=10.0.1.10
web02 ansible_host=10.0.1.11

[db]
db01 ansible_host=10.0.2.10
```

You can define:

```yaml
# group_vars/web.yml

app_port: 8080
app_name: myapp
```

Now every server in the `web` group gets:

```yaml
app_port: 8080
app_name: myapp
```

---

# 3. Registering Variables

This is extremely important in real Ansible automation.

**`register` stores the result of a task into a variable.**

Example:

```yaml
- name: Check disk usage
  ansible.builtin.shell: df -h /
  register: disk_output
```

Now `disk_output` contains the result.

You can inspect it:

```yaml
- name: Display disk information
  ansible.builtin.debug:
    var: disk_output
```

You'll get something similar to:

```text
disk_output:
  stdout: "/dev/sda1  50G  32G  18G  65% /"
  stderr: ""
  rc: 0
  changed: true
```

---

## Production example

Suppose you're checking whether an application is running.

```yaml
- name: Check application
  ansible.builtin.shell: systemctl is-active myapp
  register: app_status
  changed_when: false
```

Then:

```yaml
- name: Restart application if stopped
  ansible.builtin.systemd:
    name: myapp
    state: restarted
  when: app_status.stdout != "active"
```

So the flow becomes:

```text
Run command
    ↓
Register result
    ↓
Analyze result
    ↓
Take action
```

This pattern is used **a lot** in production automation.

---

# 4. Important parts of a registered variable

A registered variable commonly contains:

```yaml
app_status.stdout
app_status.stderr
app_status.rc
app_status.changed
app_status.failed
```

For example:

```yaml
when: app_status.rc != 0
```

means:

> If the command returned a non-zero exit code.

And:

```yaml
when: app_status.stdout == "active"
```

means:

> If the command output is `active`.

---

# 5. Variable Scoping

This is basically:

> **Where is this variable available?**

Think of three levels:

```text
Global-ish
   ↓
Play
   ↓
Task
```

But in real Ansible, scope also depends on things such as inventory groups, hosts, roles, etc.

### Example

```yaml
- hosts: web

  vars:
    app_name: myapp

  tasks:

    - name: Task 1
      debug:
        var: app_name

    - name: Task 2
      debug:
        var: app_name
```

`app_name` is available to both tasks because it is defined at **play scope**.

---

## Host-specific variables

Suppose:

```text
web01
web02
web03
```

You want:

```text
web01 → port 8080
web02 → port 8081
web03 → port 8082
```

You can use:

```text
host_vars/
├── web01.yml
├── web02.yml
└── web03.yml
```

Example:

```yaml
# host_vars/web01.yml

app_port: 8080
```

```yaml
# host_vars/web02.yml

app_port: 8081
```

Now the same playbook behaves differently depending on the host.

---

# 6. Variable Precedence

This is one of the areas that **confuses people in real projects**.

Imagine:

```yaml
app_port: 8080
```

is defined somewhere.

Then somewhere else:

```yaml
app_port: 9090
```

Which one wins?

**Variable precedence.**

The simplified mental model is:

```text
LOW precedence
      ↓
Role defaults
      ↓
Inventory variables
      ↓
group_vars
      ↓
host_vars
      ↓
Play vars
      ↓
Task vars
      ↓
Extra vars (-e)
      ↓
HIGH precedence
```

The higher-precedence value overrides the lower one.

---

## Example

`group_vars/web.yml`:

```yaml
app_port: 8080
```

Playbook:

```yaml
- hosts: web

  vars:
    app_port: 9090
```

The result is:

```text
app_port = 9090
```

because the play variable has higher precedence.

Now run:

```bash
ansible-playbook deploy.yml -e "app_port=7070"
```

Result:

```text
app_port = 7070
```

because **extra vars have very high precedence**.

---

# 7. Why is `-e` important in production?

Imagine your deployment pipeline:

```text
Jenkins
   |
   | deploy ENV=prod
   ↓
Ansible
```

Pipeline can execute:

```bash
ansible-playbook deploy.yml \
  -i inventories/prod \
  -e "image_tag=1.5.2"
```

Your playbook:

```yaml
- name: Deploy application
  hosts: app

  tasks:
    - name: Deploy version
      debug:
        msg: "Deploying {{ image_tag }}"
```

Result:

```text
Deploying 1.5.2
```

This is a very common CI/CD pattern.

---

# 8. Magic Variables

Now we get into an important Ansible concept.

**Magic variables are variables automatically created by Ansible.**

You don't define them yourself.

They give Ansible information about:

* current host
* groups
* inventory
* play
* other hosts
* execution context

---

## Most important magic variables

### `inventory_hostname`

Current host's inventory name.

```yaml
- debug:
    msg: "{{ inventory_hostname }}"
```

Output:

```text
web01
```

---

### `groups`

Contains inventory groups.

Suppose:

```ini
[web]
web01
web02

[db]
db01
db02
```

You can do:

```yaml
- debug:
    msg: "{{ groups['web'] }}"
```

Result:

```text
["web01", "web02"]
```

---

### `hostvars`

This is extremely useful.

It lets you access variables of **another host**.

For example:

```yaml
{{ hostvars['db01']['ansible_host'] }}
```

Meaning:

> Give me the `ansible_host` variable of `db01`.

Production use case:

```text
Application server
       |
       | needs DB IP
       ↓
Database server
```

You can reference the DB host's information without hardcoding its IP.

---

# 9. Ansible Facts

Now the fourth concept.

**Facts are information Ansible automatically gathers about the target server.**

When you run a playbook:

```yaml
- hosts: all
```

Ansible normally performs:

```text
Gathering Facts
      ↓
CPU
Memory
OS
IP addresses
Hostname
Disk
Kernel
Architecture
etc.
```

You can inspect them:

```yaml
- hosts: all

  tasks:

    - name: Show OS
      debug:
        var: ansible_facts
```

That's a huge object, so normally you access specific facts.

---

## Example

```yaml
- name: Show OS
  debug:
    msg: "{{ ansible_facts['distribution'] }}"
```

Output:

```text
Ubuntu
```

Version:

```yaml
{{ ansible_facts['distribution_version'] }}
```

Hostname:

```yaml
{{ ansible_facts['hostname'] }}
```

Architecture:

```yaml
{{ ansible_facts['architecture'] }}
```

Memory:

```yaml
{{ ansible_facts['memtotal_mb'] }}
```

---

# 10. Production example using Facts

Suppose your application requires Ubuntu.

You can do:

```yaml
- name: Install Docker
  hosts: all

  tasks:

    - name: Install Docker on Ubuntu
      ansible.builtin.apt:
        name: docker.io
        state: present
      when: ansible_facts['distribution'] == "Ubuntu"
```

For RedHat:

```yaml
- name: Install Docker on RedHat
  ansible.builtin.yum:
    name: docker
    state: present
  when: ansible_facts['os_family'] == "RedHat"
```

Now the **same playbook** can work against different Linux distributions.

---

# 11. Facts vs Variables vs Magic Variables

This distinction is important.

| Type                | Example                         | Who creates it?       |
| ------------------- | ------------------------------- | --------------------- |
| Normal variable     | `app_port`                      | You                   |
| Registered variable | `app_status`                    | You, using `register` |
| Fact                | `ansible_facts['distribution']` | Ansible               |
| Magic variable      | `inventory_hostname`            | Ansible               |

Think:

```text
NORMAL VARIABLE
"Something I want Ansible to know"

REGISTER
"Result from something Ansible just did"

FACT
"Information Ansible discovered about the server"

MAGIC VARIABLE
"Information Ansible knows about the execution/inventory"
```

---

# 12. Putting everything together — Production-style example

Imagine:

```text
Production
│
├── web01
├── web02
└── web03
```

Inventory:

```ini
[web]
web01
web02
web03
```

`group_vars/web.yml`:

```yaml
app_name: payment-service
app_port: 8080
```

Playbook:

```yaml
---
- name: Configure application servers
  hosts: web

  tasks:

    - name: Show server information
      ansible.builtin.debug:
        msg: >
          Server={{ inventory_hostname }}
          OS={{ ansible_facts['distribution'] }}
          App={{ app_name }}
          Port={{ app_port }}

    - name: Check application
      ansible.builtin.shell: systemctl is-active {{ app_name }}
      register: app_status
      changed_when: false
      failed_when: false

    - name: Start application if stopped
      ansible.builtin.systemd:
        name: "{{ app_name }}"
        state: started
      when: app_status.stdout != "active"
```

Now we have all four concepts:

```text
app_name / app_port
       ↓
Normal Variables

app_status
       ↓
Registered Variable

inventory_hostname
       ↓
Magic Variable

ansible_facts
       ↓
Facts
```

And the execution flow is:

```text
             Ansible
                |
        Gather server facts
                |
                ↓
       Identify current host
                |
                ↓
       Read application vars
                |
                ↓
       Check application
                |
                ↓
        register result
                |
                ↓
       Evaluate condition
                |
          ┌─────┴─────┐
          ↓           ↓
       Running      Stopped
          ↓           ↓
       Nothing      Start app
```

---

# The production mental model

If you're working with Ansible professionally, remember these five questions:

```text
1. WHERE is the variable defined?
       ↓
2. WHAT is its scope?
       ↓
3. WHICH variable wins?
       ↓
4. Is it a normal variable, fact, or magic variable?
       ↓
5. Is it the RESULT of a previous task?
       ↓
      register
```

The next thing I'd recommend learning is **`group_vars` + `host_vars` + inventory variables + variable precedence through an actual DEV/UAT/PROD project**, because that's where these concepts stop being theoretical and start making sense.
