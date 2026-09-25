# GitHub Collaboration & Features - Interview Revision

## 1. What is GitHub? Git vs GitHub
⭐ **MUST KNOW**

**Git** is a distributed version control system (CLI tool). **GitHub** is a cloud-based hosting platform for Git repositories that adds collaboration features.

| Git | GitHub |
|-----|--------|
| Version control tool | Hosting platform for Git repos |
| Runs locally | Cloud-based (github.com) |
| Tracks changes, branches, merges | Adds PRs, issues, CI/CD, code review |
| Open source, created by Linus Torvalds | Owned by Microsoft |
| Works without GitHub | Requires Git underneath |

> [!TIP]
> **Interview Tip:** "Git is the engine, GitHub is the car." Alternatives to GitHub: GitLab, Bitbucket, Azure DevOps Repos.

## 2. What is a Pull Request (PR)? PR lifecycle and best practices
⭐ **MUST KNOW**

A PR is a request to merge changes from one branch into another. It's the primary mechanism for code review and collaboration on GitHub.

### PR Lifecycle

1. Developer pushes feature branch to remote.
2. Opens a PR against target branch (e.g., `main`).
3. CI/CD runs automated checks (tests, linting, security scans).
4. Reviewers examine code, leave comments, request changes.
5. Developer addresses feedback and pushes updates.
6. Reviewer approves → PR is merged.
7. Feature branch is deleted.

### Best Practices

- Keep PRs small and focused (< 400 lines).
- Write descriptive titles and descriptions.
- Link to related issues.
- Use draft PRs for work-in-progress.
- Require at least 1-2 approvals.

## 3. Code Review process — best practices
🟠 **IMPORTANT**

### Reviewer Responsibilities

- Check for correctness, readability, maintainability.
- Look for security vulnerabilities and edge cases.
- Verify tests are included and pass.
- Provide constructive, actionable feedback.
- Approve or request changes — don't leave PRs hanging.

### Best Practices

- Review within 24 hours.
- Use "Suggest Changes" feature for small fixes.
- Focus on logic, not style (automate style with linters).
- Don't rubber-stamp — actually read the code.

## 4. Fork vs Clone — when to use which?
⭐ **MUST KNOW**

| Aspect | Fork | Clone |
|--------|------|-------|
| What | Server-side copy of entire repo to your GitHub account | Local copy of a repo to your machine |
| When | Contributing to repos you DON'T have write access to | Working on repos you DO have write access to |
| Use case | Open source contributions | Daily team development |
| Remote | Creates separate repo; push to your fork | Uses original repo as remote |

```bash
# After forking on GitHub, clone your fork
git clone <your-fork-url>

# Add upstream remote to sync with original
git remote add upstream <original-repo-url>

# Sync fork with upstream
git fetch upstream
git merge upstream/main
```

## 5. GitHub Issues — tracking and management
🟠 **IMPORTANT**

Issues are GitHub's built-in project tracking tool for bugs, features, and tasks.

### Key Features

- **Labels**: Categorize issues (bug, enhancement, priority).
- **Milestones**: Group issues into releases or sprints.
- **Assignees**: Assign responsibility.
- **Linking to PRs**: Use keywords in PR description to auto-close issues:

```text
Fixes #123
Closes #45
Resolves #67
```

## 6. GitHub Organizations — teams, permissions, repository visibility
🟠 **IMPORTANT**

Organizations provide shared ownership and team-based access management.

### Key Concepts

- **Teams**: Groups of members with specific permissions.
- **Repository Visibility**: Public, Private, or Internal (org-only).
- **Permission Levels**: Read, Triage, Write, Maintain, Admin.
- **Base Permissions**: Default permission level for all org members.

> [!IMPORTANT]
> Follow the principle of **least privilege** — give teams only the access they need.

## 7. GitHub Pages — static site hosting

Free static website hosting directly from a GitHub repository. Commonly used for project documentation, portfolios, and blogs.

- Serves from `main` branch, `gh-pages` branch, or `/docs` folder.
- Supports custom domains and HTTPS.
- Built-in Jekyll support for static site generation.

## 8. GitHub Packages — package registry
🟠 **IMPORTANT**

GitHub's built-in package hosting service supporting multiple package formats: npm, Docker, Maven, NuGet, RubyGems.

- Integrated with GitHub permissions and Actions.
- Supports public and private packages.
- Can replace Docker Hub, npm registry, etc.

## 9. Webhooks — what they are, common use cases
🟠 **IMPORTANT**

Webhooks send HTTP POST payloads to a configured URL when specific events occur in a repository.

### Common Use Cases

- Trigger CI/CD pipelines (Jenkins, external tools).
- Send notifications to Slack/Teams on push or PR events.
- Sync with external project management tools (Jira).
- Trigger deployments on merge to `main`.

## 10. GitHub API — REST vs GraphQL

| Aspect | REST API | GraphQL API |
|--------|----------|-------------|
| Style | Multiple endpoints, fixed response shape | Single endpoint, flexible queries |
| Use for | Simple operations, scripts | Complex queries, fetching nested data |
| Endpoint | `https://api.github.com/...` | `https://api.github.com/graphql` |

### Common Automation Use Cases

- Creating repos, issues, PRs programmatically.
- Automating team/permission management.
- Building custom dashboards and reporting.
- Integrating with internal tools.

## 11. CODEOWNERS file — what it is, how it works
⭐ **MUST KNOW**

A file (`.github/CODEOWNERS`) that defines which users/teams are automatically requested as reviewers when specific files are changed in a PR.

```text
# .github/CODEOWNERS

# DevOps team owns all Terraform files
*.tf @devops-team

# Backend team owns the API directory
/src/api/ @backend-team

# Security team must review any auth changes
/src/auth/ @security-team

# Default owners for everything else
* @tech-leads
```

> [!TIP]
> Combine CODEOWNERS with **branch protection rules** requiring CODEOWNER approval to enforce mandatory reviews from the right people.

## 12. GitHub Templates — issue and PR templates

Templates standardize how issues and PRs are created, ensuring contributors provide required information.

```text
.github/
├── ISSUE_TEMPLATE/
│   ├── bug_report.md
│   └── feature_request.md
└── pull_request_template.md
```

## 13. A junior developer pushed sensitive credentials to a public repo
🎯 **SCENARIO**

### What would you do?

1. **Immediately rotate/revoke** the exposed credentials (API keys, passwords, tokens).
2. Remove the sensitive data from Git history using `git filter-repo` or BFG Repo-Cleaner.
3. Force push the cleaned history.
4. Enable **GitHub Secret Scanning** to prevent future occurrences.
5. Add sensitive file patterns to `.gitignore`.
6. Set up **pre-commit hooks** to scan for secrets before committing.
7. Educate the team on secure practices.

> [!WARNING]
> Simply deleting the file in a new commit does NOT remove it from Git history. The secret remains in older commits and is still accessible.

## 14. Your team needs to enforce code review before merging
🎯 **SCENARIO**

### How do you set it up?

1. Go to **Settings → Branches → Branch Protection Rules**.
2. Enable **"Require pull request reviews before merging"**.
3. Set minimum number of approving reviews (e.g., 2).
4. Enable **"Dismiss stale reviews"** — invalidates approvals when new commits are pushed.
5. Enable **"Require review from CODEOWNERS"**.
6. Enable **"Require status checks to pass"** — CI must be green.
7. Enable **"Require branches to be up to date"** — ensures no stale merges.
8. Optionally restrict who can push directly to the protected branch.

> [!IMPORTANT]
> Branch protection rules are the backbone of a secure Git workflow. They prevent direct pushes to `main` and enforce CI + code review gates.
