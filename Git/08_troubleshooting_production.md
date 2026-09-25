# Git Troubleshooting & Production Practices - Interview Revision

## 1. How do you undo the last commit? (Reset vs. Revert)
⭐ **MUST KNOW**

**Reset** moves the branch pointer backward, erasing history. **Revert** creates a *new* commit that undoes the changes of a previous one, preserving history.

- **Key point:** Use `reset` only for local, unpushed commits. Use `revert` for public/shared branches to avoid breaking other developers' repositories.

```bash
# Undo locally but keep changes in working directory
git reset --soft HEAD~1

# Undo and destroy local changes (dangerous)
git reset --hard HEAD~1

# Safely undo a pushed commit by creating a new inverse commit
git revert <commit-hash>
```

> [!IMPORTANT]
> Never use `git reset` on public branches like `main`. Always use `git revert` for production code.

## 2. How do you recover a deleted branch or "lost" commit?
⭐ **MUST KNOW**

Use `git reflog`. It tracks every update to the tip of branches (HEAD), even if those commits aren't visible in `git log` because they were reset or the branch was deleted.

- **Key point:** Reflog entries expire (usually after 30-90 days), so act quickly.

```bash
# View the history of HEAD movements
git reflog

# Recover by creating a branch from the reflog hash
git checkout -b <recovered-branch-name> <hash-from-reflog>
```

## 3. What is a "Detached HEAD", and how do you fix it?
🟠 **IMPORTANT**

It happens when you checkout a specific commit hash or remote branch instead of a local branch. You are no longer on a branch, so new commits will be orphaned if you switch away.

### Fix

```bash
# Save detached work to a new branch
git checkout -b <new-branch-name>

# Or simply go back to main if no commits were made
git checkout main
```

## 4. How do you resolve a merge conflict?
🟠 **IMPORTANT**

Conflicts happen when Git can't automatically merge changes (e.g., both branches edited the same line).

### Steps

1. `git status` to find conflicted files.
2. Open files and look for `<<<<<<< HEAD`, `=======`, and `>>>>>>>`.
3. Manually edit the file to the desired state.
4. `git add` the resolved file.
5. `git commit` to finalize.

> For detailed conflict resolution, see `02_branching_merging.md`.

> [!TIP]
> Mention using a visual merge tool (e.g., VS Code, `git mergetool`) for complex conflicts.

## 5. Your `git push` is rejected. What do you do?
🎯 **SCENARIO**

The remote repository has commits that you don't have locally (non-fast-forward push).

### Steps

```bash
# Fetch and merge remote changes
git pull origin <branch-name>

# Alternatively, rebase your changes on top of remote (cleaner history)
git pull --rebase origin <branch-name>

# Then push
git push origin <branch-name>
```

> [!WARNING]
> Never use `git push --force` unless you fully understand the implications and have communicated with your team. It overwrites remote history.

## 6. A bug was introduced ~10 commits ago — how to find the bad commit?
🎯 **SCENARIO**

Use `git bisect`. It uses binary search to quickly pinpoint which commit introduced a bug.

```bash
git bisect start
git bisect bad                 # Current commit is bad
git bisect good <commit-hash>  # Older commit known to work
# Test the code...
git bisect bad                 # Or 'git bisect good' based on test
# Repeat until Git identifies the first bad commit
git bisect reset               # End the session when done
```

> [!TIP]
> You can automate bisect with a test script: `git bisect run ./test.sh` — Git will automatically mark commits as good/bad based on exit codes.

## 7. Repository size is growing too large — how to handle?
🎯 **SCENARIO**

Large repos slow down cloning and CI pipelines.

### Solutions

1. **Git LFS** for binary files (images, videos, datasets).
2. **Shallow clone** (`--depth 1`) in CI pipelines.
3. **Clean up history** (BFG Repo-Cleaner or `git filter-repo`) if large files were accidentally committed.
4. **Sparse checkout** to only checkout specific directories.
5. **`.gitignore`** to prevent future large file commits.

## 8. What is `git lfs` (Large File Storage)?
🟠 **IMPORTANT**

An extension that replaces large files (audio, video, binaries, datasets) with text pointers inside Git, while storing the actual file contents on a remote server.

**Why:** Keeps the Git repository small and fast. Git is terrible at versioning binary blobs.

```bash
# Install and initialize LFS
git lfs install

# Track all zip files with LFS
git lfs track "*.zip"
git lfs track "*.psd"

# This creates/updates .gitattributes
git add .gitattributes
git commit -m "Track large files with LFS"
```

## 9. Explain Shallow Clone and Partial Clone
🟠 **IMPORTANT**

| Type | Command | What it Does |
|------|---------|-------------|
| **Shallow Clone** | `git clone --depth 1` | Downloads only the latest commit(s), skipping history |
| **Partial Clone** | `git clone --filter=blob:none` | Downloads commit history but defers blob downloads until needed |

```bash
# Shallow clone (CI/CD standard — fastest)
git clone --depth 1 <url>

# Partial clone (good for massive monorepos)
git clone --filter=blob:none <url>
```

> [!TIP]
> Use shallow clone in CI/CD pipelines where you don't need history. In GitHub Actions: `actions/checkout@v4` with `fetch-depth: 1`.

## 10. Submodules vs. Subtrees

Both include one repo inside another.

| Aspect | Submodules | Subtrees |
|--------|-----------|----------|
| How | Links to a specific commit of another repo | Copies files and history into parent repo |
| Independence | Repos stay separate | Merged into parent |
| Setup | Harder (`git submodule init/update`) | Easier (acts like normal files) |
| Repo size | Keeps parent smaller | Makes parent larger |
| Use case | Shared libraries, independent versioning | Simpler integration, infrequent updates |

```bash
# Add a submodule
git submodule add <url> path/to/submodule

# Clone repo with submodules
git clone --recurse-submodules <url>

# Update submodules
git submodule update --remote
```

## 11. A developer force-pushed and overwrote team changes
🎯 **SCENARIO**

### Recovery Steps

1. Have everyone **STOP** working and pushing.
2. If someone has a recent local copy of the overwritten branch, they can push it back:
   ```bash
   git push --force origin <branch>
   ```
3. If not, check the Git server's audit logs or PR history to find the original commit hash.
4. Use `git reflog` locally (on the developer's machine who force-pushed) to find the original remote tip.
5. **Prevention:** Enable branch protection rules to disable force pushes on shared branches.

> [!WARNING]
> Always prevent force-pushes on `main` and shared branches via branch protection rules. This scenario should never happen in a well-configured repo.

## 12. CI/CD pipeline failing due to merge conflicts on auto-merge
🎯 **SCENARIO**

The target branch (`main`) moved ahead with conflicting changes while the PR was open.

### Fix

```bash
# Developer must update their branch
git fetch origin
git merge origin/main          # Or: git rebase origin/main
# Resolve conflicts, commit, and push
git add .
git commit
git push
```

**Prevention:** Enable "Require branches to be up to date" in branch protection rules.

## 13. Monorepo vs Polyrepo (DevOps Perspective)
🟠 **IMPORTANT**

| Aspect | Monorepo | Polyrepo |
|--------|----------|----------|
| Structure | Single repo for all projects | One repo per service/project |
| Examples | Google, Meta | Netflix, most microservice teams |
| CI/CD | Complex (needs path-based filtering) | Simple (independent pipelines) |
| Dependencies | Easy cross-project management | Requires package managers, versioning |
| Changes | Atomic cross-project commits | Coordinating across repos is hard |
| Repo size | Can be massive | Small, focused repos |
| Tooling | Needs special tools (Bazel, Nx, Lerna) | Standard Git workflows |

## 14. Git Performance Optimization

Commands to keep a repo healthy and fast:

```bash
# Garbage collection — clean up and optimize local repo
git gc

# Remove unreachable objects
git prune

# Background maintenance (recommended for large repos)
git maintenance start

# Sparse checkout — only checkout specific directories
git sparse-checkout init --cone
git sparse-checkout set src/ docs/
```

## 15. `git reset --hard` is destructive
⚠️ **INTERVIEW TRAP**

**Trap:** "Is there any way to undo `git reset --hard`?"

**Answer:** Partially. Using `git reflog`, you can find the orphaned commit hash and recover **committed** work, assuming the Git garbage collector hasn't cleaned it up yet. However, **uncommitted changes** in the working directory are permanently lost — there is no recovery.

> [!WARNING]
> Uncommitted working directory changes lost via `git reset --hard` are gone forever. Always commit or stash before resetting.
