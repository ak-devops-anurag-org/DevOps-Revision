Yes — this is a much better approach.

Rather than learning Ansible topic-by-topic and then doing an artificial project, we'll **learn the missing concepts when the project requires them**.

And the client requirement gives us a very good target: we can build one serious local project that exercises **Ansible + Python + REST API + YAML/JSON + Git + CI/CD + Linux + testing + logging + exception handling + reusable automation**.

One important distinction: this project will give you **hands-on project experience you can accurately describe as a personal/lab project**; don't present it as client production experience unless you actually used it for a client.

---

# Project: Automation Operations Platform

We'll build a small **production-style automation platform** that manages a simulated enterprise application environment.

Think of it as:

```text
                    Git Repository
                         │
                         ▼
                  CI/CD Pipeline
                         │
                         ▼
                 Ansible Controller
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
       WEB Nodes       APP Nodes      DB Node
       Container       Container      Container
          │              │              │
          └──────────────┼──────────────┘
                         │
                    REST API / App
```

Everything initially runs **on your laptop using Docker containers**.

We can create/destroy 5, 10, 20 worker containers whenever required.

---

# What we're going to build

Let's give the project a realistic name:

## `automation-ops-platform`

The platform will eventually be able to:

```text
Provision/configure servers
        ↓
Install required software
        ↓
Configure applications
        ↓
Deploy application
        ↓
Manage services
        ↓
Call REST APIs
        ↓
Collect results
        ↓
Validate deployment
        ↓
Generate logs/reports
```

And we'll deliberately build it using the technologies from the requirement.

---

# Mapping the client requirement to our project

This is important.

| Client requirement  | Our project                                  |
| ------------------- | -------------------------------------------- |
| Python              | Automation utilities + custom Ansible module |
| Ansible             | Core automation engine                       |
| Playbooks           | Server/application automation                |
| Roles               | `nginx`, `app`, `database`, etc.             |
| Templates           | Dynamic configuration                        |
| Variables           | DEV/UAT/PROD configuration                   |
| Handlers            | Service restart/reload                       |
| Custom Modules      | Python-based Ansible module                  |
| Automation runbooks | Operational playbooks                        |
| REST APIs           | Application/API integration                  |
| JSON                | API request/response processing              |
| YAML                | Ansible/configuration                        |
| Git                 | Project version control                      |
| CI/CD               | Automated lint/test/Ansible execution        |
| Debugging           | Ansible + Python troubleshooting             |
| Exception handling  | Python automation                            |
| Logging             | Python + Ansible logs                        |
| Testing             | Molecule/pytest/Ansible validation           |
| Linux/Unix          | Docker Linux worker nodes                    |
| Reusable automation | Roles/modules/runbooks                       |
| Scalable automation | Inventory/group architecture                 |

So we're not building a random Ansible demo.

We're building something that **maps directly to the job requirement**.

---

# Three-Phase Learning Plan

I would structure this into **three phases**.

```text
PHASE 1
Foundation + Working Automation
        ↓
PHASE 2
Production-Ready Ansible
        ↓
PHASE 3
Automation Engineering + CI/CD
```

---

# PHASE 1 — Ansible Foundation + Working Project

### Goal

By the end of Phase 1, you should be comfortable looking at an Ansible repository and understanding how it works.

We'll cover the things we've already learned and immediately apply them.

---

## 1. Local Ansible environment

We'll create:

```text
Laptop
│
├── Ansible Controller
│
├── web01
├── web02
├── app01
├── app02
└── db01
```

All worker nodes will be Docker containers.

Something like:

```text
                Your Laptop
                     │
              Ansible Controller
                     │
       ┌─────────────┼─────────────┐
       │             │             │
     web01         app01         db01
     web02         app02
```

The containers will have SSH enabled so we're practicing **real Ansible remote execution**, not just localhost commands.

---

# 2. Inventory

We'll build:

```text
inventories/
├── dev/
│   └── inventory.yml
├── uat/
│   └── inventory.yml
└── prod/
    └── inventory.yml
```

And learn:

```text
Inventory
Inventory formats
Groups
Parent/child groups
Host variables
Group variables
```

This directly covers what we just learned.

---

# 3. Basic playbooks

We'll create actual operational playbooks:

```text
playbooks/
├── bootstrap.yml
├── configure_web.yml
├── configure_app.yml
├── configure_db.yml
└── site.yml
```

We'll practice:

```text
hosts
tasks
modules
become
variables
register
facts
magic variables
conditionals
loops
```

---

# 4. First real automation

We'll make Ansible perform things like:

```text
Create users
Install packages
Create directories
Configure permissions
Configure services
Deploy configuration
Start services
Verify services
```

For example:

```text
web01
 ├── nginx
 ├── /opt/app
 └── deploy user

app01
 ├── Python
 ├── application
 └── systemd service

db01
 ├── PostgreSQL
 ├── database
 └── database user
```

---

# 5. DEV / UAT / PROD

This will be one of the most important parts.

Same playbook:

```text
site.yml
```

Different environments:

```text
DEV
UAT
PROD
```

We'll use:

```text
group_vars
host_vars
inventory variables
variable precedence
```

For example:

```yaml
# dev

app_environment: dev
app_log_level: DEBUG
app_replicas: 1
```

versus:

```yaml
# prod

app_environment: prod
app_log_level: WARN
app_replicas: 2
```

**Same automation. Different configuration.**

---

# 6. Phase 1 concepts we'll add while building

Some things we haven't covered yet:

### Handlers

```text
Configuration changed
       ↓
Notify handler
       ↓
Restart/reload service
```

### Templates

We'll use Jinja2:

```text
app.conf.j2
     ↓
Ansible template module
     ↓
app.conf
```

### Tags

For example:

```bash
ansible-playbook site.yml --tags web
```

or:

```bash
ansible-playbook site.yml --tags config
```

### Blocks

For structured error handling:

```yaml
block:
  ...
rescue:
  ...
always:
  ...
```

These are all important production concepts.

---

# PHASE 1 RESULT

At the end of Phase 1, you'll have:

```text
Docker infrastructure
        +
Inventory
        +
Playbooks
        +
Variables
        +
Facts
        +
Conditionals
        +
Loops
        +
Handlers
        +
Templates
        +
DEV/UAT/PROD
```

That's already a meaningful Ansible project.

---

# PHASE 2 — Production-Ready Ansible

Now we'll stop writing "learning playbooks" and start making the repository look like something an automation team could maintain.

---

## 1. Roles

We'll refactor:

```text
playbooks/
```

into reusable roles:

```text
roles/
├── common/
├── nginx/
├── application/
├── database/
└── monitoring/
```

Example:

```text
roles/nginx/
│
├── defaults/
│   └── main.yml
├── handlers/
│   └── main.yml
├── tasks/
│   └── main.yml
├── templates/
│   └── nginx.conf.j2
├── files/
└── vars/
    └── main.yml
```

Now we're working with the **real Ansible structure** expected in professional environments.

---

# 2. Ansible Vault

We'll introduce secrets.

For example:

```text
DB username
DB password
API token
SSH-related secrets
```

We will **not** put these directly into Git.

We'll learn:

```bash
ansible-vault encrypt
ansible-vault decrypt
ansible-vault edit
```

and use encrypted variables.

---

# 3. Production variable architecture

We'll establish a proper structure:

```text
inventories/
│
├── dev/
│   ├── inventory.yml
│   ├── group_vars/
│   │   ├── all.yml
│   │   └── app.yml
│   └── host_vars/
│
├── uat/
│   ├── inventory.yml
│   ├── group_vars/
│   └── host_vars/
│
└── prod/
    ├── inventory.yml
    ├── group_vars/
    └── host_vars/
```

And we'll intentionally create situations where:

```text
role default
     ↓
group variable
     ↓
host variable
     ↓
play variable
     ↓
extra variable
```

compete with each other.

You'll actually **debug variable precedence**, rather than memorizing a precedence chart.

---

# 4. Automation Runbooks

This directly maps to the client requirement:

> creating automation runbooks from scratch based on business/operational requirements.

We'll create runbooks such as:

```text
runbooks/
├── deploy_application.yml
├── restart_application.yml
├── server_health_check.yml
├── patch_server.yml
├── backup_database.yml
├── restore_database.yml
└── rollback_application.yml
```

For example:

```bash
ansible-playbook runbooks/restart_application.yml
```

That is much closer to real operations.

---

# 5. Health checks

We'll build:

```text
Application deployment
        ↓
HTTP health check
        ↓
API response
        ↓
Validate status
        ↓
SUCCESS / FAILURE
```

For example:

```text
GET /health

200 OK
{
    "status": "healthy"
}
```

Now we're introducing:

```text
Ansible
+
REST
+
JSON
```

---

# 6. REST API integration

We'll create a small local API.

Python:

```text
FastAPI / Flask
```

and Ansible will interact with it.

Example:

```text
Ansible
   │
   │ POST /deploy
   ▼
Application API
   │
   ▼
JSON response
```

Ansible will parse the response and make decisions.

This gives you practical experience with:

```text
REST
HTTP
GET
POST
JSON
authentication
status codes
API error handling
```

---

# 7. Python Custom Ansible Module

This is a **key requirement** in the client description.

We'll actually write one.

Something like:

```text
library/
└── application_health.py
```

Python module:

```text
Ansible
   ↓
Custom module
   ↓
Python
   ↓
Application/API
   ↓
Result
   ↓
Ansible
```

The module could perform something useful like:

```text
Check application health
Validate deployment version
Compare expected vs actual version
Return structured result
```

Now you're not merely saying:

> "I know Ansible custom modules."

You'll have actually built one.

---

# 8. Python automation layer

We'll also build Python utilities around the project.

Something like:

```text
python/
├── api_client.py
├── inventory_validator.py
├── deployment_validator.py
├── config_loader.py
└── logger.py
```

We'll practice:

```text
Functions
Classes where appropriate
REST clients
JSON
YAML
Exception handling
Logging
Configuration management
CLI arguments
Exit codes
```

This maps directly to:

> production-grade automation scripts/applications.

---

# PHASE 2 RESULT

At this point:

```text
Ansible
 ├── Playbooks
 ├── Roles
 ├── Templates
 ├── Variables
 ├── Handlers
 ├── Vault
 ├── Custom Modules
 ├── Runbooks
 └── REST API integration

Python
 ├── API client
 ├── Automation utilities
 ├── Logging
 ├── Exception handling
 └── Validation
```

Now we're getting very close to the actual job description.

---

# PHASE 3 — CI/CD + Testing + Engineering Practices

This phase makes the project look like an **automation engineering project**, rather than an Ansible lab.

---

# 1. Git workflow

We'll use:

```text
main
│
├── feature/add-nginx-role
├── feature/api-health-check
├── feature/custom-module
└── feature/ci-pipeline
```

We'll practice:

```text
branch
commit
PR
review
merge
tag/release
```

---

# 2. CI pipeline

We'll create:

```text
Git Push
   ↓
CI Pipeline
   ↓
Python tests
   ↓
Lint Python
   ↓
Lint YAML
   ↓
Ansible Lint
   ↓
Syntax Check
   ↓
Deploy to DEV
   ↓
Integration Test
```

Eventually:

```text
DEV
 ↓
Approval
 ↓
UAT
 ↓
Approval
 ↓
PROD
```

Even though everything is local.

---

# 3. Testing

We'll introduce:

### Python

```text
pytest
```

Example:

```text
test_api_client.py
test_config_loader.py
test_inventory_validator.py
```

### Ansible

We'll use:

```text
ansible-lint
```

and potentially:

```text
Molecule
```

for role testing.

We'll also write integration tests.

---

# 4. Logging

Our Python automation should not just do:

```python
print("something happened")
```

We'll implement proper logging:

```text
INFO
WARNING
ERROR
DEBUG
```

Example:

```text
2026-08-11 18:30:01 INFO  Starting deployment
2026-08-11 18:30:02 INFO  Target environment: DEV
2026-08-11 18:30:04 INFO  API health check passed
2026-08-11 18:30:05 ERROR Deployment validation failed
```

---

# 5. Exception handling

We'll deliberately make APIs fail and learn to handle:

```text
ConnectionError
Timeout
HTTP 4xx
HTTP 5xx
Invalid JSON
Missing configuration
Authentication failure
```

For example:

```python
try:
    response = client.deploy()
except TimeoutError:
    logger.error("Deployment API timed out")
    raise
```

But we'll go beyond simple `try/except` and design appropriate failure behavior and exit codes.

---

# 6. Debugging

We'll intentionally introduce bugs.

For example:

```text
Wrong variable
Wrong inventory
Bad Jinja template
Wrong permissions
Failed service
Invalid API response
Bad JSON
Python exception
Ansible module failure
```

Then troubleshoot them using:

```bash
-v
-vv
-vvv
-vvvv
```

plus:

```bash
ansible-inventory --graph
ansible-inventory --list
ansible-playbook --check
ansible-playbook --diff
```

This is important because **production automation is as much debugging as writing YAML.**

---

# Final Project Architecture

By the end, our repository should look roughly like:

```text
automation-ops-platform/
│
├── README.md
├── ansible.cfg
├── requirements.yml
│
├── inventories/
│   ├── dev/
│   │   ├── inventory.yml
│   │   ├── group_vars/
│   │   └── host_vars/
│   │
│   ├── uat/
│   │   ├── inventory.yml
│   │   ├── group_vars/
│   │   └── host_vars/
│   │
│   └── prod/
│       ├── inventory.yml
│       ├── group_vars/
│       └── host_vars/
│
├── playbooks/
│   ├── site.yml
│   ├── bootstrap.yml
│   └── deploy.yml
│
├── runbooks/
│   ├── health_check.yml
│   ├── restart_app.yml
│   ├── deploy_app.yml
│   ├── rollback.yml
│   └── backup.yml
│
├── roles/
│   ├── common/
│   ├── nginx/
│   ├── application/
│   ├── database/
│   └── monitoring/
│
├── library/
│   └── application_health.py
│
├── python/
│   ├── api_client.py
│   ├── config_loader.py
│   ├── deployment_validator.py
│   └── logger.py
│
├── tests/
│   ├── unit/
│   └── integration/
│
├── app/
│   └── api/
│
├── docker/
│   ├── controller/
│   ├── web/
│   ├── app/
│   └── db/
│
├── docker-compose.yml
│
└── .github/
    └── workflows/
        └── ci.yml
```

---

# The learning strategy

The key is **we don't build all of this upfront**.

We'll grow the project incrementally:

```text
START
 │
 ▼
Docker containers
 │
 ▼
Inventory
 │
 ▼
Simple Playbook
 │
 ▼
Tasks + Modules
 │
 ▼
Variables
 │
 ▼
Facts
 │
 ▼
Conditionals
 │
 ▼
Loops
 │
 ▼
Handlers
 │
 ▼
Templates
 │
 ▼
DEV/UAT/PROD
 │
 ▼
Roles
 │
 ▼
Vault
 │
 ▼
Runbooks
 │
 ▼
REST API
 │
 ▼
Python
 │
 ▼
Custom Ansible Module
 │
 ▼
Testing
 │
 ▼
Logging + Exception Handling
 │
 ▼
Git
 │
 ▼
CI/CD
 │
 ▼
FINAL PROJECT
```

And when we encounter a concept we haven't learned yet, **we stop, learn just enough of that concept, and immediately implement it in the project.**

That will make the learning much faster given your existing development/DevOps background.

---

## What you'll eventually be able to say accurately

After completing this project, a strong project description would be along the lines of:

> **Built a production-style automation platform using Python and Ansible to automate Linux server configuration, application deployment, operational runbooks, REST API integrations, health validation, and environment-specific configuration across DEV/UAT/PROD. Implemented reusable Ansible roles, Jinja2 templates, handlers, variables, Ansible Vault, custom Python modules, structured logging, exception handling, automated testing, Git-based workflows, and CI/CD validation.**

That maps **very closely** to the client's requirement without claiming experience you haven't actually obtained.

---

# Our immediate next step

We should **not start writing the Ansible project yet**.

First, we'll build the lab:

```text
Your Laptop
     │
     ▼
Docker Compose
     │
     ├── ansible-controller
     ├── dev-web01
     ├── dev-app01
     ├── dev-db01
     ├── uat-web01
     ├── uat-app01
     ├── uat-db01
     ├── prod-web01
     ├── prod-app01
     └── prod-db01
```

Then we'll verify:

```text
Docker networking
SSH
Linux users
Ansible installation
SSH connectivity
ansible ping
inventory
```

**Only after that do we write our first project playbook.**

That gives us a clean, reproducible local environment that we can destroy and rebuild whenever we want.
