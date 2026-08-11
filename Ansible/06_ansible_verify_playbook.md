
# `check mode` — very useful in production

Before making changes, you can often run:

```bash
ansible-playbook -i inventory playbook.yml --check
```

This is basically:

> **Show me what Ansible would change without actually changing the server.**

- This is extremely useful before production changes.
- NOT all the modules support check mode.
- So, if a task/module do not support the check mode - this will be skipped.
---

# `--diff`

For configuration changes:

```bash
ansible-playbook playbook.yml --check --diff
```

This can show you what configuration differences Ansible expects to make.

Production workflow can therefore be:

```text
Developer changes playbook
        ↓
Git PR
        ↓
Review
        ↓
Ansible --check
        ↓
Approval
        ↓
Actual execution
```


# `--syntax-check`

For checking the syntax:

```bash
ansible-playbook playbook.yml --syntax-check
```
---

# Playbook structure 

A production playbook commonly looks like:

```yaml
---
- name: Configure application servers
  hosts: app
  become: true

  vars:
    app_name: payment-service
    app_port: 8080

  tasks:

    - name: Install required packages
      ansible.builtin.apt:
        name:
          - nginx
          - curl
        state: present

    - name: Create application directory
      ansible.builtin.file:
        path: /opt/{{ app_name }}
        state: directory
        mode: '0755'

    - name: Start nginx
      ansible.builtin.service:
        name: nginx
        state: started
```

Notice how everything fits together:

```text
Play
 │
 ├── hosts
 │
 ├── become
 │
 ├── vars
 │
 └── tasks
      │
      ├── Task 1
      ├── Task 2
      └── Task 3
```

---

# `become: true`

You'll see this constantly in production.

```yaml
become: true
```

It means:

> Execute tasks with elevated privileges.

Usually equivalent to using:

```bash
sudo
```

For example, installing packages normally requires root.

So:

```yaml
- name: Configure server
  hosts: web
  become: true
```

allows tasks such as:

```yaml
apt:
  name: nginx
```

to execute with elevated privileges.

---

# Multiple plays in one playbook

A playbook can contain multiple plays.

Example:

```yaml
---
- name: Configure web servers
  hosts: web
  become: true

  tasks:

    - name: Install nginx
      ansible.builtin.apt:
        name: nginx
        state: present


- name: Configure database servers
  hosts: db
  become: true

  tasks:

    - name: Install PostgreSQL
      ansible.builtin.apt:
        name: postgresql
        state: present
```

Now:

```text
playbook.yml
     │
     ├── Play 1
     │     └── Web servers
     │           └── Install nginx
     │
     └── Play 2
           └── DB servers
                 └── Install PostgreSQL
```

---

# Real production example

Imagine an application architecture:

```text
                 Load Balancer
                      │
          ┌───────────┴───────────┐
          │                       │
        web01                   web02
          │                       │
          └───────────┬───────────┘
                      │
                    db01
```

Inventory:

```ini
[web]
web01
web02

[db]
db01
```

Playbook:

```yaml
---
- name: Configure web servers
  hosts: web
  become: true

  tasks:

    - name: Install nginx
      ansible.builtin.apt:
        name: nginx
        state: present

    - name: Ensure nginx is running
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true


- name: Configure database server
  hosts: db
  become: true

  tasks:

    - name: Install PostgreSQL
      ansible.builtin.apt:
        name: postgresql
        state: present

    - name: Ensure PostgreSQL is running
      ansible.builtin.service:
        name: postgresql
        state: started
        enabled: true
```

Run:

```bash
ansible-playbook -i inventory playbook.yml
```

Ansible understands:

```text
[web]
   ↓
web01
web02

[db]
   ↓
db01
```

and executes the appropriate play against each group.

---

# What happens when you run a playbook?

This is the actual flow you should remember:

```text
ansible-playbook
       │
       ▼
Read ansible.cfg
       │
       ▼
Read inventory
       │
       ▼
Identify target hosts
       │
       ▼
Load variables
       │
       ▼
Gather facts
       │
       ▼
Execute tasks
       │
       ▼
Check desired state
       │
       ▼
Make required changes
       │
       ▼
Return result
```

And you'll typically see:

```text
TASK [Install nginx]
changed: [web01]
changed: [web02]

TASK [Ensure nginx is running]
ok: [web01]
ok: [web02]
```

---

# `ok`, `changed`, `failed`, `skipped`

These statuses are worth understanding early.

### `ok`

Ansible checked the server and **nothing needed to change**.

```text
ok: [web01]
```

### `changed`

Ansible actually modified something.

```text
changed: [web01]
```

### `failed`

Something went wrong.

```text
failed: [web01]
```

### `skipped`

A condition prevented the task from running.

```text
skipping: [web01]
```

---


# Playbook vs Shell Script

This distinction is worth remembering.

### Shell script

```bash
apt install nginx
systemctl start nginx
mkdir /opt/myapp
```

You're describing **commands to execute**.

### Ansible

```yaml
apt:
  name: nginx
  state: present

service:
  name: nginx
  state: started

file:
  path: /opt/myapp
  state: directory
```

You're describing the **desired state**.

That's why Ansible becomes powerful when managing hundreds of servers.

---

# One thing I want you to notice

Earlier we discussed variables.

Now you can see where they actually fit:

```yaml
---
- name: Deploy application
  hosts: web

  vars:
    app_name: payment-service
    app_port: 8080

  tasks:

    - name: Create application directory
      ansible.builtin.file:
        path: "/opt/{{ app_name }}"
        state: directory

    - name: Show application port
      ansible.builtin.debug:
        msg: "Application runs on {{ app_port }}"
```

So the playbook is the **execution layer**, while variables provide the **configuration data**.

Later we'll move those variables outside the playbook into:

```text
group_vars/
host_vars/
inventory
```

which is much closer to how you structure a production project.

---

# Where we're going next

I suggest we follow this exact order:

```text
1. ✅ Ansible Playbook
       ↓
2. Tasks & Modules
       ↓
3. Handlers
       ↓
4. Conditions (when)
       ↓
5. Loops
       ↓
6. Templates (Jinja2)
       ↓
7. Variables
       ↓
8. group_vars
       ↓
9. host_vars
       ↓
10. Inventory variables
       ↓
11. Variable precedence
       ↓
12. Roles
       ↓
13. Vault / Secrets
       ↓
14. DEV / UAT / PROD project
       ↓
15. Jenkins/GitHub Actions + Ansible
```

