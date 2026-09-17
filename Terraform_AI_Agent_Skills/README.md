# Terraform AI Agent Skills + MCP Server — Setup Guide

> How to give your AI coding agent **Terraform IaC superpowers**: a custom skill
> (contextual guidelines) + a live connection to the HashiCorp Terraform Registry
> via the MCP server.

---

## Table of Contents

- [What's in this setup?](#whats-in-this-setup)
- [Prerequisites](#prerequisites)
- [1. Google Antigravity CLI (agy)](#1-google-antigravity-cli-agy)
- [2. Claude Code (Anthropic)](#2-claude-code-anthropic)
- [3. Cursor](#3-cursor)
- [4. Windsurf (Codeium)](#4-windsurf-codeium)
- [5. GitHub Copilot (VS Code Agent Mode)](#5-github-copilot-vs-code-agent-mode)
- [6. Any MCP-Compatible Agent](#6-any-mcp-compatible-agent)
- [Terraform MCP Server — Available Tools](#terraform-mcp-server--available-tools)
- [How We Used It (Real-World Example)](#how-we-used-it-real-world-example)
- [Skill File Reference](#skill-file-reference)
- [Troubleshooting](#troubleshooting)

---

## What's in this setup?

This project uses **two complementary components** that work together:

| Component | What it does | How the agent uses it |
|---|---|---|
| **Terraform Agent Skill** (`SKILL.md`) | Injects Terraform IaC conventions, workflow rules, project structure guidelines, naming conventions, tagging standards, and security scanning practices into the agent's context | Agent reads it as instructions — _"always run `plan` before `apply`"_, _"tag every resource with `environment`, `owner`, `managed-by`"_, etc. |
| **Terraform MCP Server** (`mcp_config.json`) | Connects the agent to the **live HashiCorp Terraform Registry** via Docker, providing real-time access to provider docs, module search, and version lookups | Agent _calls tools_ — e.g., `search_providers` to find `azurerm_cosmosdb_account`, then `get_provider_details` to read the official docs before generating code |

**Together**, the skill teaches the agent _how_ to write Terraform, and the MCP server gives it _what_ to write (verified, up-to-date provider documentation).

### Directory structure

```text
your-project/
└── .agents/                          # AI agent configuration (commit to VCS)
    ├── mcp_config.json               # Terraform MCP server definition
    └── skills/
        └── Terraform_AI_Agent_Skills/
            ├── SKILL.md              # Main skill — conventions & workflow
            ├── assets/
            │   ├── module-template/  # Skeleton for new Terraform modules
            │   └── pre-commit-config.yaml
            └── references/
                ├── aws.md            # AWS-specific patterns
                ├── azure.md          # Azure-specific patterns
                └── gcp.md            # GCP-specific patterns
```

---

## Prerequisites

- **Docker** — required to run the HashiCorp Terraform MCP server container
  ```bash
  docker pull hashicorp/terraform-mcp-server:latest
  ```
- **Terraform CLI** (optional, for running `plan`/`apply` locally)
- **Azure CLI / AWS CLI / gcloud** (depending on your cloud provider)

---

## 1. Google Antigravity CLI (agy)

> This is **exactly how we used it** in this project.

### How it works

Antigravity (agy) automatically discovers the `.agents/` directory at your
project root and loads both the skill and MCP server:

1. **Skill Discovery**: agy walks up from your CWD to the repo root, finds
   `.agents/skills/Terraform_AI_Agent_Skills/SKILL.md`, reads the YAML
   frontmatter (`name`, `description`), and registers it. The skill's
   `description` field controls _when_ the agent activates it (e.g., when
   you mention `.tf` files, Terraform commands, or cloud provisioning).

2. **MCP Server Discovery**: agy reads `.agents/mcp_config.json` and
   launches the Docker container in the background. The MCP tools become
   available to the agent automatically.

### Setup

**Step 1 — Create `.agents/mcp_config.json`** at your project root:

```json
{
  "mcpServers": {
    "terraform": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "hashicorp/terraform-mcp-server:latest"
      ]
    }
  }
}
```

**Step 2 — Create the skill** at `.agents/skills/Terraform_AI_Agent_Skills/SKILL.md`:

The `SKILL.md` must have YAML frontmatter with `name` and `description`:

```yaml
---
name: terraform
description: >-
  Write, review, scaffold, and troubleshoot Terraform infrastructure-as-code...
  Use this whenever the user is working with .tf files, running terraform
  init/plan/apply, or provisioning cloud infra via IaC.
---

# Your Terraform conventions and guidelines here
...
```

> See the full [SKILL.md](SkiLL.md) in this
> repository for the complete skill content.

**Step 3 — Start agy in your project directory:**

```bash
cd your-project/
agy
```

That's it. No additional configuration needed. agy auto-discovers everything
in `.agents/`.

### How agy activates the skill

agy uses **progressive disclosure** — it doesn't load the full skill into
context immediately. Instead:

1. Only the skill's `name` and `description` are injected at startup
2. When you ask a Terraform-related question, agy reads the full `SKILL.md`
3. The agent also has access to the `references/` and `assets/` subdirectories

### How agy uses the MCP server

When the agent needs to verify provider documentation, it calls the MCP tools
directly. Example sequence from our actual session:

```
1. get_latest_provider_version(namespace="hashicorp", name="azurerm")
   → returned "5.5.0"

2. search_providers(provider_name="azurerm", provider_namespace="hashicorp",
                    service_slug="cosmosdb_account",
                    provider_document_type="resources")
   → returned provider_doc_id: "13599774"

3. get_provider_details(provider_doc_id="13599774")
   → returned full official documentation for azurerm_cosmosdb_account
```

The agent used this to verify every argument, attribute, and capability
before generating the Terraform code.

### Verification commands

```bash
# Confirm the skill is loaded (look for "terraform" in the skills list)
# In an agy session, the agent will tell you the skill is available

# Confirm MCP server is connected (the agent can list available MCP tools)
# Ask: "Can you access the Terraform MCP server?"
```

### Configuration locations (agy)

| Scope | Path | Use case |
|---|---|---|
| **Project** (recommended) | `<repo>/.agents/` | Shared with team via VCS |
| **Global** | `~/.gemini/config/` | Personal defaults across all projects |

---

## 2. Claude Code (Anthropic)

### MCP Server

**Option A — CLI (recommended):**

```bash
claude mcp add terraform -- docker run -i --rm hashicorp/terraform-mcp-server:latest
```

**Option B — Manual `.mcp.json`** at your project root:

```json
{
  "mcpServers": {
    "terraform": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "hashicorp/terraform-mcp-server:latest"]
    }
  }
}
```

Verify with:
```bash
claude mcp list
# Should show: terraform  ✓ Connected
```

### Custom Instructions (Skill equivalent)

Claude Code uses **CLAUDE.md** (equivalent to agy's skills/rules):

```bash
# Copy the skill content into Claude's instruction file
cp Terraform_AI_Agent_Skills/SKILL.md CLAUDE.md
```

Or create `CLAUDE.md` at your project root and paste the skill content
(without the YAML frontmatter).

### Scopes

| Scope | File | Committed to VCS? |
|---|---|---|
| Project | `.mcp.json` + `CLAUDE.md` in repo root | Yes |
| User | `~/.claude.json` | No |

---

## 3. Cursor

### MCP Server

**Option A — UI:**

1. Open **Cursor Settings** → **Features** → **MCP**
2. Click **"+ Add new MCP server"**
3. Enter:
   - **Name:** `terraform`
   - **Type:** `command`
   - **Command:** `docker`
   - **Args:** `run`, `-i`, `--rm`, `hashicorp/terraform-mcp-server:latest`

**Option B — `.cursor/mcp.json`** in your project root:

```json
{
  "mcpServers": {
    "terraform": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "hashicorp/terraform-mcp-server:latest"]
    }
  }
}
```

> Restart Cursor after adding the server. Look for a green indicator in MCP
> settings to confirm the connection.

### Custom Instructions (Skill equivalent)

Cursor uses **`.cursorrules`** or **`.cursor/rules/*.md`**:

```bash
# Option 1: Single rules file
cp Terraform_AI_Agent_Skills/SKILL.md .cursorrules

# Option 2: Rules directory (preferred for multiple rule sets)
mkdir -p .cursor/rules
cp Terraform_AI_Agent_Skills/SKILL.md .cursor/rules/terraform.md
```

---

## 4. Windsurf (Codeium)

### MCP Server

Edit the Windsurf MCP config file:

- **macOS/Linux:** `~/.codeium/windsurf/mcp_config.json`
- **Windows:** `%USERPROFILE%\.codeium\windsurf\mcp_config.json`

```json
{
  "mcpServers": {
    "terraform": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "hashicorp/terraform-mcp-server:latest"]
    }
  }
}
```

After saving, go to **Settings → Cascade → MCP Servers** and click
**Refresh** to activate.

### Custom Instructions (Skill equivalent)

Create **`.windsurfrules`** at your project root:

```bash
cp Terraform_AI_Agent_Skills/SKILL.md .windsurfrules
```

Or use the `.windsurf/rules/` directory for multiple rule files:

```bash
mkdir -p .windsurf/rules
cp Terraform_AI_Agent_Skills/SKILL.md .windsurf/rules/terraform.md
```

---

## 5. GitHub Copilot (VS Code Agent Mode)

### MCP Server

Create **`.vscode/mcp.json`** in your workspace:

```json
{
  "servers": {
    "terraform": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "hashicorp/terraform-mcp-server:latest"]
    }
  }
}
```

Or add to your global config at `~/.copilot/mcp-config.json`.

Then in VS Code:
1. Open the **Copilot Chat** panel
2. Switch to **Agent** mode (dropdown at top)
3. Click **Configure tools** to verify the terraform MCP tools are available

### Custom Instructions (Skill equivalent)

Copilot uses **`.github/copilot-instructions.md`**:

```bash
mkdir -p .github
cp Terraform_AI_Agent_Skills/SKILL.md .github/copilot-instructions.md
```

---

## 6. Any MCP-Compatible Agent

The MCP server follows the standard **Model Context Protocol** (stdio
transport). Any agent that supports MCP can connect using:

```json
{
  "command": "docker",
  "args": ["run", "-i", "--rm", "hashicorp/terraform-mcp-server:latest"]
}
```

For the skill/instructions, copy `SKILL.md` content into whatever custom
instruction mechanism your agent supports.

---

## Terraform MCP Server — Available Tools

The HashiCorp Terraform MCP Server exposes **9 tools** that give the agent
live access to the Terraform Registry:

| Tool | Purpose | Example Usage |
|---|---|---|
| `search_providers` | Search provider resources/data-sources by name | Find `azurerm_cosmosdb_account` docs |
| `get_provider_details` | Fetch full docs for a specific resource | Get all arguments, attributes, examples |
| `get_provider_capabilities` | List all resources/data-sources a provider offers | See everything AzureRM can provision |
| `get_latest_provider_version` | Check the latest stable provider version | Verify AzureRM 5.5.0 is latest |
| `search_modules` | Search the Terraform module registry | Find a VPC or AKS module |
| `get_module_details` | Fetch module documentation and inputs/outputs | Read module README and variables |
| `get_latest_module_version` | Check latest version of a module | Pin to latest stable |
| `search_policies` | Search Sentinel policy library | Find compliance policies |
| `get_policy_details` | Fetch policy documentation | Read policy enforcement rules |

### Tool call sequence (how agents typically use them)

```text
Step 1: get_latest_provider_version
        → Know what version to pin in versions.tf

Step 2: search_providers (with service_slug + provider_document_type)
        → Get the provider_doc_id for the resource you need

Step 3: get_provider_details (with provider_doc_id)
        → Read the full official documentation before generating code
```

---

## How We Used It (Real-World Example)

In this project, we provisioned **Azure Cosmos DB for NoSQL** using
Terraform. Here's the exact workflow the agent followed:

### 1. Agent read the Terraform skill

The agent read `.agents/skills/Terraform_AI_Agent_Skills/SKILL.md` to
understand the project's conventions:
- Tag every resource with `environment`, `owner`, `managed-by`
- Every variable needs `description` + `type` + `validation`
- Mark sensitive outputs with `sensitive = true`
- Pin provider versions — never leave `required_providers` unconstrained
- Follow `terraform fmt` → `validate` → `plan` → `apply` workflow

### 2. Agent queried the MCP server

```
# Get latest AzureRM version
get_latest_provider_version(namespace="hashicorp", name="azurerm")
→ "5.5.0"

# Find Cosmos DB account resource docs
search_providers(
  provider_name="azurerm",
  provider_namespace="hashicorp",
  service_slug="cosmosdb_account",
  provider_document_type="resources"
)
→ provider_doc_id: "13599774"

# Read official documentation
get_provider_details(provider_doc_id="13599774")
→ Full docs: arguments, attributes, examples, capabilities list

# Repeat for SQL database (doc_id: 13599791) and SQL container (doc_id: 13599790)
```

### 3. Agent generated verified Terraform code

Using the skill conventions + MCP-verified documentation, the agent produced:

```text
terraform/
├── versions.tf                 # AzureRM ~> 5.5 (verified via MCP)
├── providers.tf                # No hardcoded subscription
├── variables.tf                # 8 vars with validation blocks
├── main.tf                     # Resource group + common tags
├── cosmosdb.tf                 # Account + DB + Container (verified args)
├── outputs.tf                  # Endpoint + key (sensitive) + names
├── terraform.tfvars.example    # Safe-to-commit example
└── README.md                   # Full documentation
```

Every resource argument was verified against the official AzureRM 5.5
documentation before being written — not generated from training data.

---

## Skill File Reference

### SKILL.md Frontmatter

The YAML frontmatter controls when the agent activates the skill:

```yaml
---
name: terraform              # Unique skill identifier
description: >-              # When to activate (natural language trigger)
  Write, review, scaffold, and troubleshoot Terraform infrastructure-as-code...
---
```

### Key conventions from the skill

| Convention | Details |
|---|---|
| **Workflow** | `fmt` → `validate` → `plan -out=tfplan` → review → `apply tfplan` |
| **Structure** | Directory-per-environment, not workspaces |
| **Variables** | Always `description` + `type` + `validation` |
| **Outputs** | Only what consumers need; `sensitive = true` for secrets |
| **Naming** | `<project>-<env>-<component>-<resource-type>` |
| **Tagging** | `environment`, `owner`, `managed-by = terraform` |
| **State** | Remote backend with locking; never local for real infra |
| **Security** | Run tfsec/checkov before any `apply` on networking/IAM/public endpoints |

### Reference files

| File | Content |
|---|---|
| `references/aws.md` | AWS provider patterns (VPCs, S3, IAM, EC2) |
| `references/azure.md` | Azure provider patterns (AKS, VNets, Key Vault) |
| `references/gcp.md` | GCP provider patterns (GKE, VPCs, IAM) |

---

## Troubleshooting

| Problem | Solution |
|---|---|
| MCP server not connecting | Ensure Docker is running: `docker ps` |
| MCP tools not available | Pull the latest image: `docker pull hashicorp/terraform-mcp-server:latest` |
| Skill not loading (agy) | Check `.agents/skills/*/SKILL.md` has valid YAML frontmatter |
| Skill not loading (other agents) | Copy `SKILL.md` content to the agent's instruction file (see agent-specific sections) |
| `search_providers` returns no results | Use a single-word `service_slug` (e.g., `cosmosdb_account`, not `cosmos db account`) |
| `get_provider_details` fails | You must call `search_providers` first to get the `provider_doc_id` |
| Docker container exits immediately | Add `-i` flag (interactive/stdin) — the MCP server uses stdio transport |

---

## Quick Reference — Configuration Files by Agent

| Agent | MCP Config | Custom Instructions / Skill |
|---|---|---|
| **agy (Antigravity)** | `.agents/mcp_config.json` | `.agents/skills/<name>/SKILL.md` |
| **Claude Code** | `.mcp.json` | `CLAUDE.md` |
| **Cursor** | `.cursor/mcp.json` | `.cursorrules` or `.cursor/rules/*.md` |
| **Windsurf** | `~/.codeium/windsurf/mcp_config.json` | `.windsurfrules` or `.windsurf/rules/*.md` |
| **GitHub Copilot** | `.vscode/mcp.json` | `.github/copilot-instructions.md` |
