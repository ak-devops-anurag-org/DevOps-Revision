# How to Create a GitHub Repository from the Terminal

This guide provides two methods for creating a new GitHub repository directly from your terminal and pushing your local code to it.

**Example Scenario:**
* Username: `githubak2002`
* Repository Name: `ideahub`
* Visibility: Public

---

## Option 1: Using `curl` and GitHub REST API

This method uses standard tools available on almost all Unix-based systems. It requires a GitHub Personal Access Token (PAT).

### Prerequisites
1. Go to **GitHub.com > Settings > Developer settings > Personal access tokens > Tokens (classic)**.
2. Generate a new token and check the `repo` scope.
3. Copy the token (it usually starts with `ghp_`).

### Step 1: Create the Remote Repository
Run the following `curl` command as a **single continuous line** to avoid invisible formatting characters breaking the command. Replace `<YOUR_TOKEN>` with your actual PAT.

```bash
curl -H "Authorization: token <YOUR_TOKEN>" https://api.github.com/user/repos -d '{"name":"ideahub", "private":false}'
```
*Note: Upon success, you will see a large JSON output detailing the new repository.*

### Step 2: Link Local Repo and Push
Once the remote repository is created, link your local directory to it and push your code:

```bash
# Initialize and commit (if not already done)
git init
git add .
git commit -m "init setup"

# Link the remote repository
git remote add origin https://github.com/githubak2002/ideahub.git

# Set the main branch and push
git branch -M main
git push -u origin main
```

---

## Option 2: Using GitHub CLI (`gh`)

The GitHub CLI is the officially supported tool and provides a much cleaner, error-free workflow for daily operations.

### Prerequisites
1. Install the GitHub CLI (e.g., `brew install gh` on macOS, or download from [cli.github.com](https://cli.github.com/)).
2. Authenticate your account by running:
   ```bash
   gh auth login
   ```
   *(Follow the interactive prompts to log in via your browser.)*

### Step 1: Create and Push the Repository
Assuming you are already in your local project directory and have committed your code (`git init`, `git add .`, `git commit -m "init setup"`), run this single command:

```bash
gh repo create ideahub --public --source=. --remote=origin --push
```

**What this command does:**
* `ideahub`: The name of the repository to create.
* `--public`: Makes the repository public.
* `--source=.`: Uses the current directory as the source for the repository.
* `--remote=origin`: Adds the GitHub repository as a remote named `origin`.
* `--push`: Pushes your local commits to GitHub automatically.
