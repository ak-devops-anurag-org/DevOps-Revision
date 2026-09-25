# Git & GitHub — Interview Questions

## Table of Contents

1. [Core Concepts & Architecture](#1-core-concepts--architecture)
2. [Branching & Merging](#2-branching--merging)
3. [Commands & Daily Operations](#3-commands--daily-operations)
4. [Git Workflows & Strategies](#4-git-workflows--strategies)
5. [GitHub & Collaboration](#5-github--collaboration)
6. [GitHub Actions & CI/CD](#6-github-actions--cicd)
7. [Security & Best Practices](#7-security--best-practices)
8. [Troubleshooting & Production](#8-troubleshooting--production)
9. [Scenario-Based Questions](#9-scenario-based-questions)
10. [Rapid-Fire Questions](#10-rapid-fire-questions)

---

## 1. Core Concepts & Architecture

### 1. What is Git?
⭐ **MUST KNOW**

Git is a distributed version control system that tracks changes to files, enables collaboration, and maintains a complete history of every change. Every developer has a full copy of the repository including its entire history.

### Key Points

- Distributed (vs centralized like SVN)
- Fast, lightweight branching
- Data integrity via SHA-1 hashing
- Full offline capability

### 2. What is the difference between centralized and distributed VCS?
⭐ **MUST KNOW**

- **Centralized (CVCS):** Single server holds all versioned files. Developers checkout files from central server. Single point of failure. (SVN, Perforce)
- **Distributed (DVCS):** Every developer clones the entire repository. Full offline work. No single point of failure. (Git, Mercurial)

### 3. Explain Git's architecture — the three areas.
⭐ **MUST KNOW**

```text
Working Directory → Staging Area (Index) → Local Repository → Remote Repository
     git add →          git commit →            git push →
                                              ← git fetch/pull
```

- **Working Directory:** Where you edit files.
- **Staging Area (Index):** Snapshot of what will go into the next commit.
- **Local Repository:** Your local `.git` database with full commit history.
- **Remote Repository:** Shared server (GitHub, GitLab).

### 4. What are Git objects?
🟠 **IMPORTANT**

Git stores everything as objects, identified by SHA-1 hashes:

- **Blob:** File contents (no filename/metadata).
- **Tree:** Directory listing — pointers to blobs and other trees.
- **Commit:** Points to a tree + metadata (author, message, parent commit).
- **Tag:** Named pointer to a specific commit (annotated tags include metadata).

### 5. What is HEAD in Git?
⭐ **MUST KNOW**

HEAD is a pointer to the current branch reference (which in turn points to the latest commit). When you checkout a branch, HEAD points to that branch.

**Detached HEAD:** When HEAD points directly to a commit (not a branch). Commits made here will be lost if you switch away without creating a branch.

### 6. What is `.gitignore`?
⭐ **MUST KNOW**

A file that specifies patterns of files Git should ignore (not track). Used for dependencies (`node_modules/`), secrets (`.env`), build artifacts (`dist/`), and IDE settings.

⚠️ **INTERVIEW TRAP**: Adding a file to `.gitignore` does NOT remove it if it's already tracked. You must run `git rm --cached <file>` first.

---

## 2. Branching & Merging

### 7. What is a branch and how does Git implement it?
⭐ **MUST KNOW**

A branch is a lightweight, movable pointer to a commit. Internally, it's just a 41-byte file containing a commit SHA. This makes branching in Git extremely fast and cheap compared to other VCS tools.

### 8. What is the difference between `git merge` and `git rebase`?
⭐ **MUST KNOW**

| Merge | Rebase |
|-------|--------|
| Creates a merge commit | Rewrites history (linear) |
| Preserves complete history | Cleaner, linear log |
| Safe for public branches | **Never rebase public branches** |
| Can create messy graph | Easier to read history |

### 9. What is a fast-forward merge?
⭐ **MUST KNOW**

Occurs when the target branch has no new commits since the feature branch was created. Git simply moves the branch pointer forward — no merge commit is created. Use `--no-ff` to force a merge commit for better history tracking.

### 10. How do you resolve a merge conflict?
⭐ **MUST KNOW**

1. Run the merge/rebase — Git pauses on conflict.
2. `git status` to identify conflicted files.
3. Open files, find `<<<<<<<`, `=======`, `>>>>>>>` markers.
4. Edit to desired state, remove markers.
5. `git add <file>` to mark as resolved.
6. `git commit` (or `git rebase --continue`).

### 11. What is interactive rebase?
🟠 **IMPORTANT**

`git rebase -i HEAD~N` opens an editor to modify the last N commits. You can:
- **Squash:** Combine multiple commits into one.
- **Reword:** Change commit messages.
- **Drop:** Remove commits.
- **Reorder:** Change commit order.

---

## 3. Commands & Daily Operations

### 12. What is the difference between `git pull` and `git fetch`?
⭐ **MUST KNOW**

- `git fetch`: Downloads remote changes but does NOT merge. Safe operation.
- `git pull`: Runs `git fetch` + `git merge`. Can cause conflicts.

⚠️ **INTERVIEW TRAP**: `git pull` = `fetch + merge` (not rebase) by default.

### 13. Explain `git reset` — soft, mixed, hard.
⭐ **MUST KNOW**

| Mode | HEAD | Staging | Working Dir |
|------|------|---------|-------------|
| `--soft` | Moved | Kept | Kept |
| `--mixed` | Moved | Cleared | Kept |
| `--hard` | Moved | Cleared | **Cleared** |

### 14. `git reset` vs `git revert` — when to use which?
⭐ **MUST KNOW**

- **Reset:** Rewrites history — use for local/unpushed commits only.
- **Revert:** Creates a new inverse commit — safe for pushed/shared branches.

### 15. What is `git stash`?
🟠 **IMPORTANT**

Temporarily shelves uncommitted changes so you can switch branches. `git stash pop` re-applies them. Use `git stash -u` to include untracked files.

### 16. What is `git cherry-pick`?
🟠 **IMPORTANT**

Applies a specific commit from one branch onto another without merging the whole branch. Used for backporting fixes or grabbing specific commits.

```bash
git cherry-pick <commit-hash>
```

### 17. What is `git reflog`?
🟠 **IMPORTANT**

Records every HEAD movement (commits, resets, rebases, checkouts). Your safety net for recovering "lost" commits after reset or branch deletion. Entries expire after 30-90 days.

### 18. What is `git bisect`?
🟠 **IMPORTANT**

Binary search to find the commit that introduced a bug. Mark current as `bad`, a known working commit as `good`, and Git narrows it down logarithmically.

---

## 4. Git Workflows & Strategies

### 19. Explain GitFlow.
⭐ **MUST KNOW**

A branching model with long-lived branches: `main` (production), `develop` (integration), and short-lived `feature/*`, `release/*`, `hotfix/*` branches. Best for products with scheduled release cycles.

### 20. What is Trunk-Based Development?
⭐ **MUST KNOW**

Developers merge small, frequent changes directly into `main`. Uses feature flags to hide incomplete code. Requires strong CI/CD and automated testing. Best for SaaS and continuous deployment.

### 21. GitFlow vs Trunk-Based — when to use which?
⭐ **MUST KNOW**

- **GitFlow:** Scheduled releases, multiple active versions, mobile apps.
- **Trunk-Based:** SaaS, microservices, mature CI/CD pipelines.
- **Feature Branch:** Small teams, any project needing code review via PRs.
- **Forking:** Open source, untrusted contributors.

### 22. What is semantic versioning?
🟠 **IMPORTANT**

`MAJOR.MINOR.PATCH` — MAJOR for breaking changes, MINOR for new features (backward compatible), PATCH for bug fixes. Example: `v2.1.3`.

---

## 5. GitHub & Collaboration

### 23. What is a Pull Request (PR)?
⭐ **MUST KNOW**

A request to merge changes from one branch into another. Enables code review, automated CI checks, and collaborative discussion before code is merged.

### 24. Fork vs Clone — what's the difference?
⭐ **MUST KNOW**

- **Fork:** Server-side copy to your GitHub account. Used for contributing to repos without write access (open source).
- **Clone:** Local copy to your machine. Used for repos you have access to.

### 25. What is CODEOWNERS?
⭐ **MUST KNOW**

A file (`.github/CODEOWNERS`) that auto-assigns reviewers based on which files are changed. Combined with branch protection, it ensures the right people review the right code.

### 26. What are GitHub Webhooks?
🟠 **IMPORTANT**

HTTP POST callbacks triggered by repository events (push, PR, etc.). Used to trigger external CI/CD, send Slack notifications, or sync with other tools.

---

## 6. GitHub Actions & CI/CD

### 27. What is GitHub Actions?
⭐ **MUST KNOW**

GitHub's native CI/CD platform. Workflows are defined in YAML (`.github/workflows/`), composed of jobs and steps, triggered by events (push, PR, schedule, manual).

### 28. What are the core components of GitHub Actions?
⭐ **MUST KNOW**

- **Workflow:** The entire automation pipeline (YAML file).
- **Job:** Group of steps running on the same runner. Parallel by default.
- **Step:** Single task — runs a command (`run:`) or uses an action (`uses:`).
- **Action:** Reusable unit (e.g., `actions/checkout@v4`).
- **Runner:** The machine that executes the job.

### 29. GitHub-hosted vs self-hosted runners?
🟠 **IMPORTANT**

- **GitHub-hosted:** Managed, ephemeral, clean VMs. Limited compute minutes.
- **Self-hosted:** Your infrastructure. Good for private networks, custom hardware, cost control.

### 30. How do you manage secrets in GitHub Actions?
🟠 **IMPORTANT**

Use GitHub Secrets at repository, organization, or environment level. Access with `${{ secrets.SECRET_NAME }}`. Never echo or log secrets.

### 31. What are reusable workflows?
⭐ **MUST KNOW**

Workflows triggered via `workflow_call` that can be called from other workflows. Implements DRY principle — define a pipeline once, use it across multiple repos.

---

## 7. Security & Best Practices

### 32. What are branch protection rules?
⭐ **MUST KNOW**

Rules enforced on branches to prevent direct pushes, require PR reviews, status checks, signed commits, and up-to-date branches before merging. Essential for securing `main`.

### 33. What are signed commits and why do they matter?
⭐ **MUST KNOW**

GPG or SSH signed commits verify the committer's identity. Without signing, anyone can impersonate a developer by setting `user.name` and `user.email`. GitHub shows a "Verified" badge.

### 34. What is GitHub Secret Scanning?
🟠 **IMPORTANT**

Automatically scans repos for known secret patterns (API keys, tokens). Push protection can block pushes containing secrets before they enter the repo.

### 35. What is Dependabot?
🟠 **IMPORTANT**

Automated dependency management — alerts on vulnerable dependencies and opens PRs to update them.

### 36. SSH vs HTTPS for Git authentication?
🟠 **IMPORTANT**

- **SSH:** Key-based, very secure, may be blocked on port 22. Best for daily developer use.
- **HTTPS:** Uses PAT/credential manager, works through firewalls (port 443). Best for CI/CD.

---

## 8. Troubleshooting & Production

### 37. How do you recover a lost commit?
⭐ **MUST KNOW**

Use `git reflog` to find the commit hash, then `git checkout -b <branch> <hash>` to recover it. Reflog entries expire in 30-90 days.

### 38. What is `git lfs`?
🟠 **IMPORTANT**

Large File Storage — replaces large binary files with text pointers, storing actual content on a separate server. Keeps the Git repo small and fast.

### 39. What is a shallow clone?
🟠 **IMPORTANT**

`git clone --depth 1` downloads only the latest commit without full history. Standard practice for CI/CD pipelines to speed up checkout.

### 40. Monorepo vs Polyrepo?
🟠 **IMPORTANT**

- **Monorepo:** Single repo for all projects. Easy dependencies, atomic changes. Needs special tooling at scale.
- **Polyrepo:** One repo per service. Independent pipelines, smaller repos. Harder cross-project coordination.

---

## 9. Scenario-Based Questions

### 🎯 Scenario: You accidentally committed secrets to a public repo. What do you do?

1. Immediately **rotate/revoke** the exposed credentials.
2. Remove from history using BFG Repo-Cleaner or `git filter-repo`.
3. Force push the cleaned history.
4. Enable secret scanning and pre-commit hooks.
5. Add patterns to `.gitignore`.

### 🎯 Scenario: A developer force-pushed and overwrote team changes on `main`.

1. Stop all work on the branch immediately.
2. Find someone with the correct local copy and have them force push to restore.
3. Use `git reflog` on the developer's machine to find the original remote tip.
4. **Prevention:** Enable branch protection to block force pushes.

### 🎯 Scenario: Production has a bug introduced somewhere in the last 20 commits.

Use `git bisect`:
1. `git bisect start` → mark current as `bad` → mark a known-good commit as `good`.
2. Git checks out middle commits; test each and mark as good/bad.
3. Git identifies the exact commit that introduced the bug.
4. Automate with `git bisect run ./test.sh`.

### 🎯 Scenario: CI/CD pipeline is failing because of merge conflicts.

1. Developer must update their branch: `git fetch origin && git merge origin/main`.
2. Resolve conflicts locally, push the fix.
3. **Prevention:** Enable "Require branches to be up to date" in branch protection.

### 🎯 Scenario: Your GitHub Actions pipeline takes 30 minutes. How do you speed it up?

1. Cache dependencies (`actions/cache`).
2. Parallelize jobs.
3. Use path filtering to skip irrelevant runs.
4. Shallow clone (`fetch-depth: 1`).
5. Use larger runners or self-hosted runners.
6. Set `fail-fast: true` in matrix builds.

### 🎯 Scenario: You committed to the wrong branch.

```bash
git log --oneline -1              # Note the commit hash
git reset --soft HEAD~1           # Undo commit, keep changes staged
git stash                         # Stash the changes
git checkout correct-branch       # Switch to correct branch
git stash pop                     # Apply changes
git commit -m "Your message"      # Commit on correct branch
```

### 🎯 Scenario: You need to deploy to Dev, Staging, and Prod with Prod requiring approval.

1. Create three GitHub Environments.
2. Add required reviewers protection rule on `prod`.
3. Define sequential jobs with `needs:` dependencies.
4. Use environment-specific secrets.

---

## 10. Rapid-Fire Questions

**Q: What is Git?**
A: A distributed version control system that tracks changes and enables collaboration.

**Q: Git vs GitHub?**
A: Git is the VCS tool. GitHub is a cloud hosting platform for Git repos with collaboration features.

**Q: What is a commit?**
A: A snapshot of staged changes saved to the local repository with a unique SHA hash.

**Q: What is a branch?**
A: A lightweight, movable pointer to a commit.

**Q: What does `git status` do?**
A: Shows the state of the working directory and staging area — modified, staged, untracked files.

**Q: What does `git log` do?**
A: Displays the commit history of the current branch.

**Q: What does `git diff` show?**
A: Differences between working directory and staging area (unstaged changes).

**Q: What is staging area?**
A: An intermediate area where changes are prepared before committing.

**Q: What does `git add .` do?**
A: Stages all changes in the current directory for the next commit.

**Q: What does `git clone` do?**
A: Creates a local copy of a remote repository including all history.

**Q: `git pull` vs `git fetch`?**
A: Fetch downloads changes without merging. Pull = fetch + merge.

**Q: `git reset --hard` vs `--soft`?**
A: Hard discards all changes. Soft undoes commit but keeps changes staged.

**Q: `git reset` vs `git revert`?**
A: Reset rewrites history (local only). Revert creates an inverse commit (safe for shared branches).

**Q: What is a merge conflict?**
A: Occurs when Git can't auto-merge because the same code was changed differently in both branches.

**Q: What is fast-forward merge?**
A: When the target branch has no new commits, Git moves the pointer forward without a merge commit.

**Q: What is `git stash`?**
A: Temporarily saves uncommitted changes so you can switch branches.

**Q: What is `git cherry-pick`?**
A: Applies a specific commit from one branch onto another.

**Q: What is `git reflog`?**
A: Logs all HEAD movements locally — safety net for recovering lost commits.

**Q: What is `git bisect`?**
A: Binary search to find the commit that introduced a bug.

**Q: What is `.gitignore`?**
A: A file listing patterns of files Git should not track.

**Q: What is a Pull Request?**
A: A request to merge code from one branch to another with code review.

**Q: Fork vs Clone?**
A: Fork is a server-side copy (no write access needed). Clone is a local copy.

**Q: What is CODEOWNERS?**
A: A file that auto-assigns reviewers based on changed file paths.

**Q: What is GitFlow?**
A: A branching model with main, develop, feature, release, and hotfix branches.

**Q: What is trunk-based development?**
A: Developers merge frequently to main using feature flags. Enables CI/CD.

**Q: What is GitHub Actions?**
A: GitHub's built-in CI/CD platform using YAML workflows.

**Q: What is a runner in GitHub Actions?**
A: A server that executes workflow jobs. Can be GitHub-hosted or self-hosted.

**Q: What is a reusable workflow?**
A: A workflow callable from other workflows using `workflow_call` trigger — DRY principle.

**Q: What are branch protection rules?**
A: Rules that enforce PR reviews, status checks, and restrictions on protected branches.

**Q: What are signed commits?**
A: Commits cryptographically signed with GPG/SSH to verify author identity.

**Q: What is Dependabot?**
A: GitHub bot that alerts on vulnerable dependencies and auto-creates update PRs.

**Q: What is `git lfs`?**
A: Large File Storage — stores large binaries outside the Git repo using pointers.

**Q: What is a shallow clone?**
A: `git clone --depth 1` — downloads only latest commit, skipping history. Used in CI/CD.

**Q: Monorepo vs Polyrepo?**
A: Monorepo = all projects in one repo. Polyrepo = separate repo per service.

**Q: What is semantic versioning?**
A: `MAJOR.MINOR.PATCH` — Major for breaking changes, Minor for features, Patch for fixes.

**Q: What are Git hooks?**
A: Scripts that run automatically at Git events (pre-commit, pre-push, etc.).

**Q: How to remove a secret from Git history?**
A: Rotate the secret immediately, then use BFG Repo-Cleaner or `git filter-repo` to rewrite history.

**Q: What does `actions/checkout@v4` do?**
A: Clones the repository into the GitHub Actions runner workspace — required because runners start empty.

**Q: What is `git tag`?**
A: Creates a named reference to a specific commit. Annotated tags include metadata.

**Q: What is the difference between `git merge --squash` and regular merge?**
A: Squash combines all feature commits into one staged change without a merge commit.

**Q: Can you undo `git reset --hard`?**
A: Committed work can be recovered via `git reflog`. Uncommitted changes are lost forever.
