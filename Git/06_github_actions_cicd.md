# GitHub Actions & CI/CD - Interview Revision

## 1. What is GitHub Actions?
⭐ **MUST KNOW**

GitHub Actions is a CI/CD platform native to GitHub that automates build, test, and deployment pipelines.

### Core Concepts

- **Workflow**: Automated process defined by a YAML file in `.github/workflows/`.
- **Job**: A set of steps that execute on the same runner. Jobs run in parallel by default.
- **Step**: An individual task that can either run a shell command or an action.
- **Action**: A reusable extension or standalone command (e.g., `actions/checkout`).
- **Runner**: The server that executes the workflow.

```text
Workflow (.yml)
  └── Job 1 (runs-on: ubuntu-latest)
  │     ├── Step 1: uses: actions/checkout@v4
  │     ├── Step 2: run: npm install
  │     └── Step 3: run: npm test
  └── Job 2 (runs in parallel by default)
        └── ...
```

## 2. Workflow YAML Structure
⭐ **MUST KNOW**

```yaml
name: CI Pipeline                    # Workflow name

on:                                  # Trigger events
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:                                # Define jobs
  build-and-test:
    runs-on: ubuntu-latest           # Runner environment

    steps:                           # Sequential tasks
      - name: Checkout code
        uses: actions/checkout@v4    # Use a predefined action

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci                  # Run a shell command

      - name: Run Linting
        run: npm run lint

      - name: Run Tests
        run: npm test
```

### Key Elements

| Element | Purpose |
|---------|---------|
| `on` | Defines trigger event(s) |
| `jobs` | Defines the jobs to run |
| `runs-on` | Specifies the runner OS |
| `steps` | Sequential tasks within a job |
| `uses` | Invokes a predefined action |
| `run` | Executes a shell command |
| `with` | Passes parameters to an action |
| `needs` | Defines job dependencies (ordering) |

## 3. Triggers — how to start workflows
⭐ **MUST KNOW**

```yaml
on:
  push:                              # On code push
    branches: [ "main", "develop" ]
    paths: [ "src/**" ]              # Only when specific paths change

  pull_request:                      # On PR events
    branches: [ "main" ]
    types: [ opened, synchronize ]

  schedule:                          # Cron schedule
    - cron: '0 2 * * 1'              # Every Monday at 2 AM UTC

  workflow_dispatch:                 # Manual trigger via UI
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'staging'

  repository_dispatch:               # External webhook trigger
    types: [ deploy ]
```

## 4. Runners — GitHub-hosted vs self-hosted
🟠 **IMPORTANT**

| Aspect | GitHub-Hosted | Self-Hosted |
|--------|--------------|-------------|
| Management | Managed by GitHub | Managed by you |
| Environment | Clean ephemeral VM for each job | Persistent machine |
| Cost | Included minutes (limited) | Your own infrastructure |
| Use case | Standard builds | Private networks, custom hardware, cost control |
| Maintenance | Zero | You handle updates, security, scaling |

```yaml
# GitHub-hosted
runs-on: ubuntu-latest    # Also: windows-latest, macos-latest

# Self-hosted
runs-on: self-hosted
# Or with labels
runs-on: [self-hosted, linux, x64]
```

## 5. Secrets and Environment Variables
🟠 **IMPORTANT**

### Secrets (Sensitive Data)

```yaml
steps:
  - name: Deploy
    run: ./deploy.sh
    env:
      API_KEY: ${{ secrets.API_KEY }}
      DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
```

### Scopes

| Scope | Access |
|-------|--------|
| **Repository** | Available to all workflows in that repo |
| **Organization** | Shared across repos (can be restricted to specific repos) |
| **Environment** | Only available when deploying to that specific environment |

> [!WARNING]
> Never print secrets using `echo` or pass them directly in CLI arguments. GitHub redacts them in logs, but they can still be exposed in command history or third-party actions.

### Variables (Non-Sensitive Config)

```yaml
env:
  NODE_ENV: ${{ vars.NODE_ENV }}
```

## 6. Environments — protection rules and approvals
🟠 **IMPORTANT**

Environments are deployment targets (e.g., Dev, Staging, Prod) that enforce protection rules.

### Key Features

- **Required Reviewers**: Manual approval before deployment proceeds.
- **Wait Timers**: Introduce a delay before deployment.
- **Environment Secrets**: Restrict secrets to specific environments.
- **Deployment Branches**: Limit which branches can deploy to an environment.

```yaml
jobs:
  deploy-staging:
    environment: staging
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying to staging"

  deploy-prod:
    needs: deploy-staging
    environment: prod        # Will pause for manual approval
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying to production"
```

## 7. Matrix Builds — testing across versions/OS
🟠 **IMPORTANT**

Matrix strategy automatically generates multiple job runs based on an array of variables.

```yaml
strategy:
  matrix:
    node-version: [16, 18, 20]
    os: [ubuntu-latest, windows-latest]
  fail-fast: true            # Stop all jobs if any fails
```

This creates 6 parallel jobs testing all combinations of OS and Node versions.

## 8. Artifacts — uploading and downloading build outputs

```yaml
steps:
  - name: Build
    run: npm run build

  - name: Upload artifact
    uses: actions/upload-artifact@v4
    with:
      name: build-output
      path: dist/

# In another job:
  - name: Download artifact
    uses: actions/download-artifact@v4
    with:
      name: build-output
```

Artifacts persist data between jobs and can be downloaded from the GitHub UI after the workflow completes.

## 9. Caching — faster dependency installation

```yaml
- name: Cache node modules
  uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

> [!TIP]
> Caching uses a key (usually a hash of the lockfile). If the lockfile changes, a cache miss occurs and fresh dependencies are downloaded.

## 10. Reusable Workflows — DRY principle
⭐ **MUST KNOW**

Define a workflow once and call it from multiple repositories or workflows.

### Reusable workflow (called)

```yaml
# .github/workflows/reusable-deploy.yml
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
    secrets:
      deploy-key:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - run: echo "Deploying to ${{ inputs.environment }}"
```

### Caller workflow

```yaml
jobs:
  call-deploy:
    uses: my-org/shared-workflows/.github/workflows/reusable-deploy.yml@main
    with:
      environment: production
    secrets:
      deploy-key: ${{ secrets.DEPLOY_KEY }}
```

## 11. Composite Actions — creating custom actions

Bundles multiple workflow steps into a single reusable action (defined in `action.yml`).

```yaml
# .github/actions/setup-and-test/action.yml
name: Setup and Test
runs:
  using: composite
  steps:
    - run: npm ci
      shell: bash
    - run: npm test
      shell: bash
```

**Key difference:** Reusable workflows define entire **jobs**. Composite actions define reusable **steps** within a job.

## 12. Your GitHub Actions pipeline is slow — how do you optimize it?
🎯 **SCENARIO**

### What would you check?

1. **Caching**: Cache dependencies (`actions/cache`) and Docker layers.
2. **Parallelism**: Split sequential tasks into parallel jobs.
3. **Fail Fast**: Set `fail-fast: true` in matrix builds.
4. **Path Filtering**: Use `paths:` in triggers to run only when relevant files change.
5. **Larger Runners**: Upgrade to larger GitHub runners or use powerful self-hosted runners.
6. **Shallow Clone**: Use `fetch-depth: 1` in `actions/checkout` to skip history.
7. **Skip unnecessary steps**: Use `if:` conditionals to skip irrelevant jobs.

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 1          # Shallow clone for faster checkout
```

## 13. Multi-environment deployment with approvals
🎯 **SCENARIO**

### Interview Answer

1. Define three GitHub Environments (`dev`, `staging`, `prod`).
2. Add **Environment Protection Rules** on `prod` requiring specific reviewers.
3. Set environment-specific secrets (different API keys per env).
4. Use `needs:` to enforce sequential deployment order.
5. Optionally add wait timers on staging for soak testing.

## 14. Runners start with an empty workspace
⚠️ **INTERVIEW TRAP**

> [!CAUTION]
> **Trap:** "If I specify `runs-on: ubuntu-latest`, my repository code is automatically available in the runner, right?"
>
> **Answer:** **No.** Runners start with an empty workspace. You MUST include `uses: actions/checkout@v4` as the first step in your job to clone your repository code into the runner. Without it, your code files don't exist on the runner.
