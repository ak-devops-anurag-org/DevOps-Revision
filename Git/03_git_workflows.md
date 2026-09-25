# Git Workflows & Branching Strategies - Interview Revision

## 1. What is GitFlow? What branches are involved?
⭐ **MUST KNOW**

GitFlow is a strict branching model utilizing multiple long-lived branches for parallel development and scheduled releases.

### Key Branches

- `main` (or `master`): Always reflects production-ready state.
- `develop`: The integration branch for next release features.
- `feature/*`: Branches off `develop` for new work, merges back to `develop`.
- `release/*`: Branches off `develop` for pre-production testing; merges to `main` and `develop`.
- `hotfix/*`: Branches off `main` for critical prod bugs; merges back to `main` and `develop`.

```text
main     --o------------------------------------o--------o-->
            \                                  /        /
hotfix       \--- (urgent fix) ---------------/        /
              \                                       /
release        \--------------- (v1.0 prep) ---------/
                \              /                    /
develop  --------o------------o--------------------o-------->
                  \          /
feature            \-(work)-/
```

## 2. What is Trunk-Based Development? How does it differ from GitFlow?
⭐ **MUST KNOW**

Developers merge small, frequent updates directly into a central `main` branch (trunk) multiple times a day.

### Key Points

- Eliminates long-lived feature and release branches (avoids "merge hell").
- Relies heavily on **Feature Flags** to hide incomplete code in production.
- Requires extremely reliable and fast automated testing (CI).

> [!TIP]
> **Interview Tip:** Emphasize that Trunk-Based is the enabler for true CI/CD. GitFlow is for scheduled, boxed releases; Trunk-based is for SaaS/continuous deployment.

## 3. How does the Feature Branch Workflow operate?
🟠 **IMPORTANT**

All feature development happens in dedicated short-lived branches rather than directly on `main`. Once the feature is complete, it is integrated via a Pull Request.

### Key Points

- Keeps the main codebase clean, buildable.
- Ensures all code is reviewed before integration.
- Branches should be short-lived (1-3 days ideally).

## 4. When and why to use the Forking Workflow?
🟠 **IMPORTANT**

Used primarily in Open Source projects or large enterprises across decoupled teams.

### Key Points

- Contributors fork (copy) the entire repository to their own workspace.
- They push changes to their fork and open a Pull Request to the *upstream* (original) repository.
- **Why:** Security and access control. Maintainers don't need to grant write access to every contributor.

```bash
# Add upstream remote after forking
git remote add upstream <original-repo-url>

# Sync fork with upstream
git fetch upstream
git merge upstream/main
```

## 5. Which branching strategy to choose and when?
⭐ **MUST KNOW**

| Strategy | Best For | Key Characteristic |
|----------|----------|-------------------|
| **Trunk-Based** | Microservices, SaaS, mature CI/CD | Continuous deployment, feature flags |
| **GitFlow** | Versioned releases, mobile apps, on-premise | Strict release cycles, multiple versions |
| **Feature Branch** | Small-medium teams, any project | PR-based review, short-lived branches |
| **Forking** | Open Source, untrusted contributors | No write access needed |

> [!WARNING]
> ⚠️ **INTERVIEW TRAP:** Don't say "Trunk-based is always better." Acknowledge that Trunk-Based can break production easily if the team lacks solid automated testing and deployment maturity.

## 6. Walk through a Pull Request (PR) workflow
⭐ **MUST KNOW**

1. Developer creates a feature branch and pushes to the remote repo.
2. Developer opens a PR against the target branch (e.g., `main` or `develop`).
3. **CI/CD triggers**: Automated linting, unit tests, and security scans run.
4. **Code Review**: Peers review code, leave comments, request changes, and approve.
5. **Merge**: Code is integrated (often via `Squash and merge` to keep history clean).
6. Feature branch is deleted after merge.

### Best Practices

- Small, focused PRs (< 400 lines of code).
- Descriptive PR titles and descriptions.
- Link PRs to issues/tickets.
- Require at least 1-2 approvals before merge.

## 7. How do you handle Release Management and Versioning?
🟠 **IMPORTANT**

Releases are managed using Git tags and Semantic Versioning (SemVer: `MAJOR.MINOR.PATCH`).

| Version Part | When to Increment |
|-------------|-------------------|
| **MAJOR** (1.x.x) | Breaking / incompatible API changes |
| **MINOR** (x.1.x) | New features, backward compatible |
| **PATCH** (x.x.1) | Bug fixes, backward compatible |

```bash
# Create an annotated tag
git tag -a v1.2.0 -m "Release version 1.2.0"

# Push tags to remote
git push origin --tags
```

## 8. Your team is doing a hotfix while a release is in progress
🎯 **SCENARIO**

### What would you check?

1. Branch the `hotfix` off `main`.
2. Fix the bug, test, and merge the `hotfix` into `main` and `develop`.
3. **Critical Step:** You MUST also merge the `hotfix` into the active `release` branch (or cherry-pick the fix). Otherwise, when the `release` branch eventually merges to `main`, it will overwrite and erase your hotfix!

### Interview Answer

Hotfixes always branch from `main`, get merged back to both `main` and `develop`, and must also be applied to any active release branch. This is where GitFlow's complexity shows — the team must coordinate carefully.

## 9. Your company wants to move from GitFlow to trunk-based
🎯 **SCENARIO**

### What would you recommend?

1. **Phase 1:** Reduce the lifespan of feature branches (merge within 1-2 days).
2. **Phase 2:** Implement **Feature Flags** (Toggles) so incomplete code can safely live in `main`.
3. **Phase 3:** Strengthen CI pipelines — automated tests must be fast and comprehensive.
4. **Phase 4:** Phase out the `develop` branch and merge directly to `main`.
5. **Phase 5:** Move to continuous deployment with automated rollback capability.

> [!IMPORTANT]
> The shift is not just a Git change — it requires cultural and process changes: smaller PRs, more automated testing, and better deployment infrastructure.

## 10. Cherry-picking across branches — when and how
🟠 **IMPORTANT**

Cherry-picking applies a specific commit from one branch onto another without merging the entire branch.

### When to Use

- Backporting a crucial bug fix to an older supported release branch.
- Grabbing a specific helpful commit from an abandoned feature branch.
- Applying a fix to `main` that was first developed on a feature branch.

```bash
# Apply a specific commit to your current branch
git cherry-pick <commit-hash>

# Cherry-pick without committing (stage changes only)
git cherry-pick --no-commit <commit-hash>
```

> [!TIP]
> After cherry-picking, the new commit has a different SHA. If you later merge the original branch, Git is smart enough to handle duplicates in most cases.
