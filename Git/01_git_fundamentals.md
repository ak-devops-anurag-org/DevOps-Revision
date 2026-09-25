# Git Fundamentals - Interview Revision

## 1. What is Version Control System (VCS)? What are the types?
⭐ **MUST KNOW**

VCS tracks changes to files over time, allowing multiple developers to collaborate, trace history, and revert to previous states. 
*   **Centralized (CVCS)**: Single central server holds history (e.g., SVN, Perforce). A network is required for most actions.
*   **Distributed (DVCS)**: Every client fully clones the entire repository and its history (e.g., Git, Mercurial). Allows full offline work.

## 2. What is Git and why choose it over other VCS?
⭐ **MUST KNOW**

Git is a fast, distributed version control system. It is preferred because it offers full offline operation (local commits/history), has extremely fast and lightweight branching/merging capabilities, and guarantees data integrity via cryptographic hashing (SHA-1) to prevent corruption.

## 3. Explain Git's architecture and workflow.
⭐ **MUST KNOW**

Git operates across four main logical areas. Files move through these areas as you track, commit, and share changes.

```text
Working Dir    Staging (Index)    Local Repo      Remote Repo
     |               |                 |               |
     |--- git add -->|                 |               |
     |               |-- git commit -->|               |
     |               |                 |-- git push -->|
     |               |                 |<-- git fetch -|
     |<------- git checkout / merge / pull ------------|
```

## 4. How does Git store data internally (Objects & Hashing)?
🟠 **IMPORTANT**

Git is a key-value data store. It hashes file contents and metadata using SHA-1 (a 40-character string) and stores them as objects.
*   **Blob**: Stores raw file data (contents only, no filenames).
*   **Tree**: Represents directory structures; contains pointers to blobs and other trees.
*   **Commit**: Stores metadata (author, message, date) and a pointer to the root tree.
*   **Tag**: An annotated pointer to a specific commit.

## 5. What is inside the `.git` directory?
🟠 **IMPORTANT**

The `.git` folder contains the entire repository history and configuration. 
*   `objects/`: The database storing all blobs, trees, commits, and tags.
*   `refs/`: Pointers to commit hashes (e.g., branches in `refs/heads/`, tags in `refs/tags/`).
*   `HEAD`: A file containing a pointer to the currently checked-out branch.
*   `config`: Repository-specific configuration settings.
*   `index`: A binary file representing the staging area.

## 6. What are the primary states a file can reside in?
⭐ **MUST KNOW**

Files in Git exist in three main states:
1.  **Modified**: You have changed the file but have not yet staged it.
2.  **Staged**: You have marked a modified file in its current version to go into the next commit snapshot.
3.  **Committed**: The data is safely stored in your local Git database.

## 7. What is the difference between `git init` and `git clone`?

*   `git init`: Creates a brand new, empty Git repository locally by generating the `.git` subdirectory in the current folder.
*   `git clone`: Copies an existing remote repository to your local machine, downloading all history and automatically setting up remote tracking branches.

**Commands:**
*   `git init` - Initialize a new local repo.
*   `git clone <url>` - Copy a remote repo locally.

## 8. What is HEAD? What does "Detached HEAD" mean?
🟠 **IMPORTANT**

`HEAD` is a reference pointer to the current branch you are on. A **Detached HEAD** occurs when you check out a specific commit hash or remote branch directly, causing `HEAD` to point to a commit rather than a local branch.

⚠️ **INTERVIEW TRAP**: Commits made in a detached HEAD state are temporary and "unreachable." They will be permanently lost during garbage collection unless you create a branch to save them.

**Commands:**
*   `git checkout <hash>` - View an old commit (enters detached HEAD state).
*   `git switch -c <new-branch>` - Save detached commits to a new branch.

## 9. What is `.gitignore` and what are best practices?
⭐ **MUST KNOW**

A `.gitignore` file specifies intentionally untracked files that Git should ignore (e.g., compiled code, logs, dependencies like `node_modules`, or `.env` files with secrets).

> [!WARNING] 
> If a file is already tracked by Git, adding it to `.gitignore` will not magically remove it from the repository. You must untrack it first.

**Commands:**
*   `git rm --cached <file>` - Stop tracking a file without deleting it from the local system, allowing `.gitignore` to take over.

## 10. What are the Git configuration levels?

Git applies configurations in three tiers, overriding from broadest to most specific:
1.  **System** (`--system`): Applies to all users on the machine (stored in `/etc/gitconfig`).
2.  **Global** (`--global`): Applies to your specific user account (stored in `~/.gitconfig`).
3.  **Local** (`--local`): Applies only to the specific repository (stored in `.git/config`).

**Commands:**
*   `git config --global user.name "Your Name"` - Set name for all your repos.
*   `git config --list --show-origin` - View all resolved configs and where they are defined.
