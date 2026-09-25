# Git & GitHub Security & Best Practices - Interview Revision

## 1. Branch Protection Rules — what they are, key rules to enable
⭐ **MUST KNOW**

Branch protection rules enforce workflows on critical branches (e.g., `main`, `develop`) to prevent accidental or unauthorized changes.

### Key Rules to Enable

| Rule | Purpose |
|------|---------|
| Require pull request reviews | No direct pushes; code must be reviewed |
| Require status checks to pass | CI must be green before merge |
| Require conversation resolution | All review comments must be resolved |
| Require signed commits | Only verified commits allowed |
| Require linear history | Enforces rebase/squash (no merge commits) |
| Restrict who can push | Only specific teams/users can merge |
| Dismiss stale reviews | Invalidates approvals when new commits are pushed |
| Require up-to-date branches | Branch must be current with base before merge |

> [!IMPORTANT]
> Branch protection rules are the **#1 security measure** for your Git workflow. Always enable them on `main` and production branches.

## 2. Signed Commits — GPG/SSH signing
⭐ **MUST KNOW**

Signed commits prove that the committer is who they claim to be. Without signing, anyone can set `user.name` and `user.email` to impersonate another developer.

### Setup (GPG)

```bash
# Generate GPG key
gpg --full-generate-key

# List keys
gpg --list-secret-keys --keyid-format=long

# Configure Git to sign commits
git config --global user.signingkey <key-id>
git config --global commit.gpgsign true

# Add public key to GitHub: Settings → SSH and GPG Keys
```

### Verification

- **Verified** (green badge): Commit signed with a key associated with the GitHub account.
- **Unverified**: Commit not signed or key not recognized.

> [!TIP]
> GitHub now supports **SSH key signing** as a simpler alternative to GPG. Use `git config gpg.format ssh`.

## 3. GitHub Secret Scanning — what it does
🟠 **IMPORTANT**

Automatically scans repositories for known secret patterns (API keys, tokens, passwords, connection strings) and alerts repository admins.

### Key Points

- Scans all commits (including history).
- Works with 100+ partner patterns (AWS keys, Slack tokens, etc.).
- **Push protection**: Can block pushes that contain secrets before they enter the repo.
- Available for public repos (free) and private repos (GitHub Advanced Security license).

## 4. Dependabot — dependency updates and security alerts
🟠 **IMPORTANT**

GitHub's automated dependency management bot.

### Features

- **Security Alerts**: Notifies when dependencies have known vulnerabilities (CVEs).
- **Automated PRs**: Opens PRs to update vulnerable or outdated dependencies.
- **Version Updates**: Can be configured to keep dependencies current.

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "daily"
```

## 5. `.gitignore` best practices — what to NEVER commit
⭐ **MUST KNOW**

### Never Commit

- `.env` files (secrets, API keys, database credentials)
- `node_modules/`, `vendor/`, `__pycache__/` (dependencies — use lockfiles)
- `*.pem`, `*.key`, `*.p12` (private keys and certificates)
- `.terraform/`, `*.tfstate` (Terraform state contains secrets)
- IDE settings (`.idea/`, `.vscode/` — personal preferences)
- Build artifacts (`dist/`, `build/`, `*.exe`)
- OS files (`.DS_Store`, `Thumbs.db`)

```gitignore
# Secrets
.env
.env.*
*.pem
*.key

# Dependencies
node_modules/
vendor/

# Build
dist/
build/

# Terraform
.terraform/
*.tfstate
*.tfstate.backup

# IDE
.idea/
.vscode/
```

> [!WARNING]
> Use a **global `.gitignore`** (`~/.gitignore_global`) for personal IDE/OS files. Keep project `.gitignore` for project-specific patterns.

## 6. CODEOWNERS — enforcing ownership and review
⭐ **MUST KNOW**

> For details on CODEOWNERS syntax, see `05_github_collaboration.md`.

CODEOWNERS automatically assigns reviewers based on file paths. Combined with branch protection rules requiring CODEOWNER approval, it enforces that the right people review the right code.

### Security Value

- Ensures infrastructure changes are reviewed by the DevOps team.
- Security-sensitive code requires security team approval.
- Prevents unauthorized changes to critical paths.

## 7. GitHub Advanced Security (GHAS)
🟠 **IMPORTANT**

Enterprise-grade security features for GitHub repositories.

| Feature | What it Does |
|---------|-------------|
| **Code Scanning (CodeQL)** | SAST — finds vulnerabilities in source code |
| **Secret Scanning** | Detects leaked secrets in repos |
| **Dependency Review** | Reviews dependency changes in PRs for vulnerabilities |
| **Push Protection** | Blocks pushes containing detected secrets |

```text
Developer → Push → Secret Scan → Code Scan → Dependency Review → Merge
                    (Block if             (Block if          (Alert on
                     secrets found)        critical CVE)      vuln deps)
```

## 8. SSH vs HTTPS for Git authentication
🟠 **IMPORTANT**

| Aspect | SSH | HTTPS |
|--------|-----|-------|
| Authentication | SSH key pair | Username/PAT or credential manager |
| Setup | Generate key, add to GitHub | Simpler initial setup |
| Firewall | Port 22 (may be blocked) | Port 443 (rarely blocked) |
| Security | Very secure (key-based) | Depends on token management |
| Best for | Developers, daily use | CI/CD, scripts, firewalled environments |

```bash
# Test SSH connection
ssh -T git@github.com

# Switch remote URL from HTTPS to SSH
git remote set-url origin git@github.com:user/repo.git
```

## 9. PAT vs SSH Keys vs GitHub Apps — when to use each

| Method | Use Case |
|--------|----------|
| **Personal Access Token (PAT)** | Script automation, temporary access, HTTPS auth |
| **SSH Keys** | Developer daily workflow, personal authentication |
| **GitHub Apps** | Organization-wide automation, CI/CD, fine-grained permissions |
| **Deploy Keys** | Read-only access for servers/CI to a single repo |

> [!TIP]
> **Interview Tip:** GitHub Apps are the recommended approach for automation because they have fine-grained permissions, rate limits per installation, and don't tie to a personal account.

## 10. Git Hooks — security use cases
🟠 **IMPORTANT**

Scripts that run automatically at specific Git events.

### Client-Side Hooks

| Hook | When it Runs | Security Use |
|------|-------------|-------------|
| `pre-commit` | Before commit is created | Scan for secrets, run linters |
| `commit-msg` | After commit message is entered | Enforce commit message format |
| `pre-push` | Before push to remote | Run tests, check for secrets |

### Server-Side Hooks

| Hook | When it Runs | Security Use |
|------|-------------|-------------|
| `pre-receive` | Before accepting a push | Reject commits with secrets, enforce policies |
| `post-receive` | After push is accepted | Trigger deployments, notifications |

## 11. `git-secrets` / `pre-commit` framework — preventing secrets
🟠 **IMPORTANT**

```bash
# Install pre-commit framework
pip install pre-commit

# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks

# Install hooks
pre-commit install
```

Also consider: `git-secrets` (by AWS), `detect-secrets` (by Yelp), `trufflehog`.

## 12. Removing a file from tracking doesn't remove it from Git history
⚠️ **INTERVIEW TRAP**

Adding a file to `.gitignore` or deleting it only affects future commits. The file (and its contents) remain in Git history and can be recovered by anyone with repo access.

```bash
# This does NOT remove from history
git rm --cached secrets.env
echo "secrets.env" >> .gitignore
git commit -m "Stop tracking secrets"
# SECRETS ARE STILL IN OLDER COMMITS!
```

> [!CAUTION]
> If secrets were committed, they must be considered **compromised**. Rotate them immediately, then clean history.

## 13. Secrets were committed to Git history — how to remove them?
🎯 **SCENARIO**

### Steps

1. **Immediately rotate/revoke** the exposed credentials.
2. Clean history using one of these tools:

```bash
# Option 1: BFG Repo-Cleaner (simpler, recommended)
bfg --delete-files secrets.env
bfg --replace-text passwords.txt

# Option 2: git filter-repo (official, more powerful)
git filter-repo --path secrets.env --invert-paths
```

3. Force push the cleaned history: `git push --force --all`
4. All team members must re-clone the repository.
5. Enable secret scanning and pre-commit hooks to prevent recurrence.

> [!WARNING]
> If the repo was public, assume the secret was already harvested by bots. Rotation is mandatory.

## 14. Setting up a secure Git workflow for a new team
🎯 **SCENARIO**

### What would you implement?

1. **Branch Protection Rules** on `main` — require PRs, reviews, status checks.
2. **CODEOWNERS** file — enforce ownership-based reviews.
3. **Signed Commits** — verify author identity.
4. **Secret Scanning** + **Push Protection** — prevent secrets in code.
5. **Dependabot** — automated dependency vulnerability alerts and updates.
6. **Pre-commit hooks** — local secret scanning, linting.
7. **CI/CD pipeline** — automated tests, security scans (SAST, SCA).
8. **`.gitignore`** — comprehensive exclusion of secrets, dependencies, build artifacts.
9. **Least privilege access** — appropriate team permissions.
10. **SSH key authentication** — for all developers.

## 15. Least privilege access — GitHub permissions model

| Role | Capabilities |
|------|-------------|
| **Read** | View code, issues, PRs |
| **Triage** | Manage issues/PRs (no code write) |
| **Write** | Push to non-protected branches, merge PRs |
| **Maintain** | Manage repo settings (no destructive actions) |
| **Admin** | Full control (delete repo, manage access) |

> [!IMPORTANT]
> Most developers need **Write** access only. Reserve **Admin** for team leads. Use **Teams** for scalable permission management.
