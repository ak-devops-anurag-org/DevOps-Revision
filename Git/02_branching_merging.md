# Git Branching and Merging - Interview Revision

## 1. What is a branch in Git? How does it work internally?
⭐ **MUST KNOW**

A branch in Git is simply a lightweight, movable pointer to a specific commit. Unlike other VCS tools that copy directories, Git creates a 41-byte file containing the SHA-1 checksum of the commit it points to.

### Key Points

- The default branch is `main` (or `master`).
- The special `HEAD` pointer indicates your current active branch.

> [!TIP]
> Interview tip: Emphasize that branches are extremely cheap and fast in Git because they are just pointers, not duplicated files.

## 2. Branch Management Commands
⭐ **MUST KNOW**

```bash
git branch                 # List all local branches
git branch <name>          # Create a new branch (doesn't switch to it)
git switch <name>          # Switch to an existing branch (modern alternative to checkout)
git checkout -b <name>     # Create a new branch AND switch to it
git branch -d <name>       # Delete a branch (fails if unmerged changes exist)
git branch -D <name>       # Force delete a branch (ignores unmerged changes)
git branch -a              # List all branches including remote-tracking
git branch -r              # List only remote-tracking branches
```

## 3. What is merging? Fast-forward vs 3-way merge
⭐ **MUST KNOW**

Merging integrates changes from one branch into another.

- **Fast-forward merge:** Occurs when there are no new commits on the target branch. Git simply moves the target branch pointer forward to the source branch's commit.
- **3-way merge:** Occurs when both branches have diverged. Git creates a new "merge commit" that ties the two histories together, using a common ancestor (the 3rd commit) to resolve the delta.

```text
Fast-Forward Merge:
A---B (main)
     \---C---D (feature)
Result: A---B---C---D (main, feature)

3-Way Merge:
A---B---C (main)
     \---D---E (feature)
Result: A---B---C---M (main)
             \       /
              D---E (feature)
```

## 4. `git merge --no-ff` vs default merge behavior
⭐ **MUST KNOW**

By default, Git performs a fast-forward merge if possible. `git merge --no-ff` forces Git to create a merge commit even if a fast-forward is possible.

### Key Points

- Useful for preserving feature branch history.
- Explicitly shows that a group of commits were part of a specific feature.
- Makes rollbacks easier since you can revert a single merge commit.

## 5. What is a merge conflict? How to resolve it?
⭐ **MUST KNOW**

A conflict happens during a merge or rebase when Git cannot automatically resolve differences (e.g., the same line in a file was edited differently in both branches).

### Resolution Steps

1. Git pauses the merge and marks conflicted files.
2. Open files and look for `<<<<<<<`, `=======`, `>>>>>>>` markers.
3. Manually edit the file to keep the desired code.
4. Run `git add <file>` to mark it as resolved.
5. Run `git commit` to finalize the merge.

```bash
# Check which files have conflicts
git status

# After manual resolution
git add <resolved-file>
git commit
```

## 6. What is `git rebase`? Rebase vs Merge — when to use which?
⭐ **MUST KNOW**

Rebase integrates changes by moving the entire feature branch to begin on the tip of the target branch, effectively rewriting project history.

| Aspect | Merge | Rebase |
|--------|-------|--------|
| History | Preserves exact history, creates merge commit | Creates linear history, rewrites commits |
| Use when | Merging to shared branches (main, develop) | Updating feature branch with latest main |
| Graph | Can be messy/cluttered | Clean, easy to read |
| Safety | Safe for public branches | **Never rebase public branches** |

```bash
# Rebase feature branch onto latest main
git checkout feature
git rebase main
```

## 7. Why should you never rebase public/shared branches?
⚠️ **INTERVIEW TRAP**

**"The Golden Rule of Rebasing"** — Never rebase a branch that has been pushed and is being used by other developers (like `main`).

**Why?** Rebasing rewrites history and generates new commit hashes. If you force-push this rewritten history, it will diverge from your colleagues' local repositories, causing massive conflicts and confusing duplicate commits when they try to pull or merge.

> [!WARNING]
> Only rebase **your own local feature branches** that haven't been shared. Once pushed, prefer merge.

## 8. Interactive rebase (`git rebase -i`)
🟠 **IMPORTANT**

Allows you to modify commits as they are moved to the new base. It opens an editor where you can pick, drop, reword, edit, or squash commits.

### Key Uses

- **Squashing:** Combines multiple small, messy commits (e.g., "wip", "fix typo") into a single, clean, meaningful commit before merging into `main`.
- **Rewording:** Change commit messages.
- **Reordering:** Change the order of commits.

```bash
# Open the last 3 commits for interactive modification
git rebase -i HEAD~3
```

> [!TIP]
> Squash commits before opening a PR to present a clean, reviewable history.

## 9. `git merge --squash` — what it does and when to use it
🟠 **IMPORTANT**

Takes all the commits from the feature branch, squashes them into one single set of changes, and stages them on the target branch without creating a merge commit immediately.

**When to use:** When you want a single, clean commit on the `main` branch representing a whole feature, but prefer the workflow of merging over rebasing.

```bash
git checkout main
git merge --squash feature
git commit -m "Add user authentication feature"
```

> [!NOTE]
> Unlike standard squash via rebase, `--squash` does not record the feature branch's original commits in the target branch's history.

## 10. Resolving conflicts — practical scenario
🎯 **SCENARIO**: Two developers made conflicting changes to the same file — how do you resolve?

### What would you check?

1. Fetch the latest remote changes (`git fetch`).
2. Attempt to pull/merge the target branch into your local branch.
3. Git will flag the conflicting file.
4. Open the file, communicate with the other developer if the business logic overlaps.
5. Decide whether to keep your changes, theirs, or combine them.
6. Remove the conflict markers, save the file, stage it (`git add`), and complete the merge commit.

### Interview Answer

> [!TIP]
> Always resolve conflicts locally on your feature branch *before* pushing to the remote repository or opening a Pull Request. Mention using VS Code's built-in merge editor or `git mergetool` for complex conflicts.
