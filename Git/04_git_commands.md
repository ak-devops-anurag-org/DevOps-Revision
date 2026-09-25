# Essential Git Commands - Interview Revision

## 1. Daily Workflow Commands
⭐ **MUST KNOW**

```bash
git status                          # Show working tree status (modified, staged, untracked files)
git add <file>                      # Stage a specific file
git add .                           # Stage all changes in current directory
git commit -m "message"             # Commit staged changes with a message
git push origin <branch>            # Push local commits to remote repository
git pull origin <branch>            # Fetch + merge remote changes into local branch
git fetch origin                    # Download remote changes WITHOUT merging
git diff                            # Show unstaged changes
git diff --staged                   # Show staged changes (ready to commit)
git log --oneline                   # Show compact commit history
```

## 2. `git pull` vs `git fetch` — what's the difference?
⭐ **MUST KNOW**

| Command | What it does |
|---------|-------------|
| `git fetch` | Downloads new data from remote but does NOT merge into your working branch. Safe operation. |
| `git pull` | Runs `git fetch` + `git merge` in one step. Can cause merge conflicts. |

> [!TIP]
> **Interview Tip:** Always mention that `git fetch` is the safer option. You can review changes before merging. Use `git pull --rebase` to rebase instead of merge.

⚠️ **INTERVIEW TRAP**: `git pull` = `git fetch` + `git merge` (NOT rebase) by default. You can change this with `git config pull.rebase true`.

## 3. `git reset` — soft, mixed, hard
⭐ **MUST KNOW**

`git reset` moves the branch pointer (HEAD) backward to a previous commit.

| Mode | HEAD | Staging Area | Working Directory |
|------|------|-------------|-------------------|
| `--soft` | ✅ Moved | ❌ Preserved | ❌ Preserved |
| `--mixed` (default) | ✅ Moved | ✅ Cleared | ❌ Preserved |
| `--hard` | ✅ Moved | ✅ Cleared | ✅ Cleared |

```bash
git reset --soft HEAD~1             # Undo last commit, keep changes staged
git reset --mixed HEAD~1            # Undo last commit, unstage changes (default)
git reset --hard HEAD~1             # Undo last commit, DESTROY all changes
```

> [!WARNING]
> `git reset --hard` is destructive. Uncommitted working directory changes are gone forever. Only recoverable via `git reflog` for committed work.

## 4. `git revert` vs `git reset` — when to use which?
⭐ **MUST KNOW**

| Aspect | `git reset` | `git revert` |
|--------|------------|-------------|
| Action | Moves branch pointer backward | Creates a NEW commit that undoes changes |
| History | Rewrites history (removes commits) | Preserves history (adds inverse commit) |
| Use for | Local/unpushed commits only | Public/pushed commits (safe for shared branches) |
| Safety | Dangerous on shared branches | Safe for production |

```bash
# Undo locally (unpushed)
git reset --soft HEAD~1

# Undo a pushed commit safely
git revert <commit-hash>
```

> [!IMPORTANT]
> **Rule of thumb:** Use `reset` for local cleanup, `revert` for anything already pushed.

## 5. `git stash` — save work temporarily
🟠 **IMPORTANT**

Stash temporarily shelves modified tracked files so you can switch branches without committing incomplete work.

```bash
git stash                           # Stash current changes
git stash save "description"        # Stash with a descriptive message
git stash list                      # List all stashes
git stash pop                       # Apply most recent stash and remove it from list
git stash apply                     # Apply most recent stash but keep it in list
git stash apply stash@{2}           # Apply a specific stash
git stash drop stash@{0}            # Delete a specific stash
git stash clear                     # Delete all stashes
git stash -u                        # Stash including untracked files
```

## 6. `git cherry-pick` — apply specific commits
🟠 **IMPORTANT**

Applies changes from a specific commit onto the current branch without merging the entire source branch.

```bash
git cherry-pick <commit-hash>       # Apply a specific commit
git cherry-pick --no-commit <hash>  # Apply changes without auto-committing
git cherry-pick A..B                # Cherry-pick a range of commits
```

### When to use

- Backporting a bug fix to a release branch.
- Grabbing a specific commit from an abandoned branch.
- Applying a hotfix to multiple branches.

## 7. `git reflog` — lifesaver for recovering lost commits
🟠 **IMPORTANT**

Reflog records every movement of HEAD in your local repository. It tracks commits, resets, rebases, and branch switches — even for "deleted" commits.

```bash
git reflog                          # Show full HEAD movement history
git reflog show <branch>            # Show reflog for a specific branch
git checkout <hash-from-reflog>     # Recover a "lost" commit
git branch recovery <hash>          # Create a branch from a recovered commit
```

> [!TIP]
> Reflog is your safety net. Even after `git reset --hard`, you can find the old commit hash in reflog and recover it (as long as garbage collection hasn't run).

## 8. `git log` variations
🟠 **IMPORTANT**

```bash
git log --oneline                   # Compact one-line-per-commit view
git log --oneline --graph           # Visual branch/merge graph
git log --author="name"             # Filter by author
git log --since="2024-01-01"        # Commits after a date
git log --until="2024-06-01"        # Commits before a date
git log --oneline -n 10             # Show last 10 commits
git log -- <file>                   # Show commits that affected a specific file
git log --all --decorate            # Show all branches with labels
git shortlog -sn                    # Summary: commit count per author
```

## 9. `git tag` — lightweight vs annotated tags

```bash
# Lightweight tag (just a pointer, no metadata)
git tag v1.0.0

# Annotated tag (includes tagger, date, message — recommended)
git tag -a v1.0.0 -m "Release version 1.0.0"

# List tags
git tag -l

# Push tags to remote
git push origin --tags

# Delete a tag
git tag -d v1.0.0
git push origin --delete v1.0.0     # Delete remote tag
```

> [!TIP]
> Use **annotated tags** for releases (they store who tagged, when, and why). Use lightweight tags for temporary/private bookmarks.

## 10. `git clean` — removing untracked files

```bash
git clean -n                        # Dry run — show what WOULD be deleted
git clean -f                        # Force delete untracked files
git clean -fd                       # Delete untracked files AND directories
git clean -fx                       # Delete untracked AND ignored files
```

> [!WARNING]
> Always run `git clean -n` (dry run) first to preview what will be deleted!

## 11. `git blame` — finding who changed what

```bash
git blame <file>                    # Show line-by-line last modification info
git blame -L 10,20 <file>           # Blame specific line range
```

Shows the commit hash, author, and date for each line — useful for understanding why a line was written.

## 12. `git bisect` — binary search for bugs
🟠 **IMPORTANT**

Uses binary search to efficiently find the commit that introduced a bug.

```bash
git bisect start                    # Start bisect session
git bisect bad                      # Mark current commit as bad
git bisect good <commit-hash>       # Mark a known-good commit
# Git checks out a middle commit — test it, then:
git bisect good                     # or 'git bisect bad'
# Repeat until Git identifies the first bad commit
git bisect reset                    # End bisect session
```

## 13. You accidentally committed to the wrong branch
🎯 **SCENARIO**

### Steps to fix

```bash
# 1. Note the commit hash
git log --oneline -1

# 2. Undo the commit on the wrong branch (keep changes)
git reset --soft HEAD~1

# 3. Stash the changes
git stash

# 4. Switch to the correct branch
git checkout correct-branch

# 5. Apply the stash
git stash pop

# 6. Commit on the correct branch
git commit -m "Your commit message"
```

**Alternative (if already pushed):** Cherry-pick the commit to the correct branch, then revert it on the wrong branch.

## 14. You need to undo the last 3 commits but keep the changes
🎯 **SCENARIO**

```bash
# Soft reset — moves HEAD back 3 commits, keeps all changes staged
git reset --soft HEAD~3

# Now you can recommit as a single clean commit
git commit -m "Combined: feature implementation"
```

> [!TIP]
> This is a common technique for cleaning up messy commit history before pushing.
