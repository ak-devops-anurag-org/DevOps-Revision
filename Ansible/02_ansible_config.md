## 1. What is Ansible?

**Ansible is an agentless automation/configuration-management tool** used to configure servers, deploy applications, install packages, manage users, and perform operational tasks.

In simple terms: **instead of SSH-ing into 50 servers and doing the same thing manually, you write the task once and Ansible does it across all 50 servers.**

---

## 2. Why use Ansible?

Typical production problem:

> You have **100 Linux VMs** and need to install Docker + configure users + deploy an application on all of them.

Without Ansible:

```text
SSH → Server 1 → commands
SSH → Server 2 → commands
SSH → Server 3 → commands
...
SSH → Server 100
```

With Ansible:

```text
Ansible Controller
       |
       +---- Server 1
       +---- Server 2
       +---- Server 3
       ...
       +---- Server 100
```

You define the desired configuration once, and Ansible executes it consistently.

---

# 3. How is Ansible used in production?

A common production setup looks like:

```text
                 Git
                  |
                  | Playbooks / Roles
                  v
          CI/CD Pipeline
          (Jenkins/GitHub)
                  |
                  v
        Ansible Control Node
                  |
        -----------------------
        |          |          |
        v          v          v
      VM-01      VM-02      VM-03
      Prod       Prod       Prod
```

For example, your deployment pipeline might do:

```text
Developer
   ↓
Git Push
   ↓
Jenkins
   ↓
Build Docker image
   ↓
Terraform → Infrastructure
   ↓
Ansible → Configure VM
   ↓
Deploy application
```

Ansible is particularly useful when you have **VM-based infrastructure**.

For Kubernetes-based environments, Ansible is still useful for things around the cluster, but you generally use **Kubernetes manifests/Helm/GitOps** for application deployment rather than Ansible.

---

# 4. What is `ansible.cfg`?

`ansible.cfg` is the **configuration file for Ansible**.

It controls things like:

```ini
[defaults]
inventory = ./inventory
remote_user = ubuntu
host_key_checking = False
timeout = 30
```

For example:

```text
ansible-project/
│
├── ansible.cfg
├── inventory
├── playbook.yml
└── roles/
```

Then:

```bash
ansible-playbook playbook.yml
```

Ansible reads `ansible.cfg` to determine how it should behave.

---

# 5. Ansible configuration priority

This is important in real projects.

Ansible can get configuration from **multiple locations**.

The priority is:

```text
1. ANSIBLE_CONFIG environment variable
             ↓
2. ./ansible.cfg
   (current directory)
             ↓
3. ~/.ansible.cfg
   (user home)
             ↓
4. /etc/ansible/ansible.cfg
   (system-wide)
```

So the **highest priority wins**.

### Example

Suppose you have:

```text
/etc/ansible/ansible.cfg
```

with:

```ini
[defaults]
inventory = /etc/ansible/hosts
```

But your project contains:

```text
my-project/
└── ansible.cfg
```

with:

```ini
[defaults]
inventory = ./inventory/prod
```

When you run:

```bash
cd my-project
ansible-playbook site.yml
```

Ansible uses:

```text
./ansible.cfg
```

instead of:

```text
/etc/ansible/ansible.cfg
```

---

## 6. How to check which config Ansible is actually using?

Very useful production troubleshooting command:

```bash
ansible --version
```

Example:

```text
ansible [core 2.x.x]

config file = /home/ubuntu/project/ansible.cfg
```

You can immediately see:

```text
config file = ...
```

That's the config Ansible is currently using.

You can also check:

```bash
ansible-config view
```

and:

```bash
ansible-config dump
```

---

## 7. One production recommendation

For a real project, I would normally keep the configuration **inside the Git repository**:

```text
ansible-project/
│
├── ansible.cfg
├── inventories/
│   ├── dev/
│   │   └── hosts.yml
│   ├── staging/
│   │   └── hosts.yml
│   └── prod/
│       └── hosts.yml
│
├── playbooks/
│   ├── site.yml
│   └── deploy.yml
│
├── roles/
│   ├── nginx/
│   ├── docker/
│   └── application/
│
└── group_vars/
    ├── all.yml
    └── prod.yml
```

Then your deployment becomes explicit:

```bash
ansible-playbook \
  -i inventories/prod/hosts.yml \
  playbooks/deploy.yml
```

This is much safer than having random Ansible configuration scattered across servers.

### Mental model to remember

```text
ansible.cfg
     ↓
How Ansible behaves

inventory
     ↓
Which servers Ansible manages

playbook
     ↓
What Ansible should do

role
     ↓
Reusable production automation

variables
     ↓
Environment-specific values
```

That distinction is the foundation. Once this is clear, **Inventory → Ad-hoc commands → Playbooks → Variables → Roles → Vault → Production CI/CD** is the natural learning path.
