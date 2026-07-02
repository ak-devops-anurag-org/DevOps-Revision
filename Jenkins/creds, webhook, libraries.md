# Jenkins Quick Revision: Credentials, Webhooks, Shared Libraries, and Pipeline Walkthrough

Main takeaway: Use Jenkins Credentials Binding to securely inject secrets, GitHub Webhooks to trigger jobs on code events, and Shared Libraries to reuse pipeline code. In the sample pipeline, ensure the agent has Docker, proper permissions, and credentials configured.

## Credentials Binding in Jenkins Pipeline

What it is:
- A secure way to inject secrets (usernames/passwords, tokens, SSH keys) into pipeline steps without hardcoding them.

Where to configure:
- Manage Jenkins → Credentials → System → Global credentials → Add Credentials
- Types: Username/Password, Secret text (PATs/API keys), SSH Username with private key, etc.

How to use in a pipeline:
- Username/Password
```groovy
withCredentials([usernamePassword(
  credentialsId: 'dockerHubCreds',
  usernameVariable: 'dockerHubUsername',
  passwordVariable: 'dockerHubPass'
)]) {
  sh 'echo "Logging in..."'
  sh 'docker login -u "${dockerHubUsername}" -p "${dockerHubPass}"'
}
```

- Secret Text (e.g., GitHub PAT)
```groovy
withCredentials([string(credentialsId: 'github-pat', variable: 'GITHUB_TOKEN')]) {
  sh 'echo "$GITHUB_TOKEN" | docker login ghcr.io -u USERNAME --password-stdin'
}
```

- SSH Key (for Git checkout via SSH)
```groovy
sshagent(credentials: ['git-ssh-key']) {
  sh 'git clone git@github.com:org/repo.git'
}
```

Best practices:
- Never echo secrets.
- Prefer `--password-stdin` for Docker login.
- Use least-privileged tokens (scopes).
- Store credentials at folder scope to limit blast radius.

## GitHub Webhooks

Purpose:
- Trigger Jenkins jobs automatically on push/PR events instead of polling.

Prerequisites:
- Jenkins reachable from GitHub (public URL with HTTPS) or via GitHub App/Proxy.
- GitHub integration plugin or generic webhook URL.

GitHub repo settings:
- Repo → Settings → Webhooks → Add webhook
  - Payload URL: http(s)://jenkins-server-ip:8080/github-webhook/ or http(s)://jenkins-url/github-webhook 
  - Content type: application/json
  - Events: “Just the push event” or “Let me select individual events” (push, pull_request)
  - Secret: set and configure in Jenkins if validating signature.

Jenkins job configuration:
- In Pipeline job: Build Triggers → “GitHub hook trigger for GITScm polling” (for Git plugin)
- Or use Generic Webhook Trigger plugin with token/conditions.
- In a multibranch pipeline: configure GitHub source and build strategies; webhooks will trigger branch/PR indexing and builds.

Testing:
- In GitHub webhook page: “Recent Deliveries” → Redeliver → inspect response status.
- In Jenkins logs, verify the job is triggered.

## Jenkins Shared Libraries (Reusable Code)

What it is:
- Centralized, versioned Groovy library to share pipeline steps/vars across repos.

Setup:
- Create a Git repo with this structure:
```
(root)
  vars/
    sayHello.groovy        
```
- sayHello.groovy:
```groovy
def call(String name = 'world') {
  echo "Hello, ${name}"
}
```
- In Jenkins: Manage Jenkins → System → Global Pipeline Libraries
  - Name: ak-lib  
  - Default version: main (or tag)
  - Retrieval: Modern SCM → Git repo URL + credentials (if private repo)

Use in Jenkinsfile:
```groovy
@Library('ak-lib') _              // lib we created in Jenkins
pipeline {
  agent any
  stages {
    stage('Greet') {
      steps {
        script{
          sayHello('Jenkins')     // func name - same as groovy file name in GitHub repo
        }
      }
    }
  }
}
```

Benefits:
- DRY pipelines, governance, auditability.
- Versioned logic, easy updates.








## Sample Pipeline with Shared Libraries

```groovy
@Library('ak-libraries') _ 

pipeline {
    agent any

    stages {
        stage('Hello') {
            steps {
                echo 'Hello World'
            }
        }

        stage('Clone Repo') {
            steps {
                script {
                    cloneRepo('https://github.com/ak-devops-anurag-org/simple-nodejs-server-with-dockerFile.git', 'dev')
                }
            }
        }

        stage('who am i') {
            steps {
                echo 'whoami'
                sh 'whoami'
                // sh 'sudo usermod -aG docker $USER && newgrp docker'
            }
        }

        stage('Build Docker Image'){
            steps {
                script {
                    dockerBuild('simple-node-img-jenkins','latest','akdevanurag')
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing image to Docker Hub'
                withCredentials([usernamePassword(
                    credentialsId: "dockerHubCreds", 
                    usernameVariable: "dockerHubUsername", 
                    passwordVariable: "dockerHubPass")]) {
                    sh """
                      echo "$dockerHubPass" | docker login -u "$dockerHubUsername" --password-stdin
                      docker push ${dockerHubUsername}/simple-node-img-jenkins:latest
                    """
                }
            }
        }

        stage('Deploy Container') {
            steps {
                echo 'Deploying Docker container'
                sh 'docker compose up -d'
            }
        }
    }
}
```

**Key Pipeline Features:**
- **Shared Library Usage:** `@Library('ak-libraries') _` imports reusable functions
- **Custom Functions:** 
  - `cloneRepo()` - handles Git repository cloning
  - `dockerBuild()` - handles Docker image building and tagging
- **Credentials Binding:** Secure Docker Hub authentication
- **Multi-line Shell Commands:** Using `sh """..."""` for complex commands

**Required Shared Library Functions:**

**vars/cloneRepo.groovy:**
```groovy
def call(String repoUrl, String branch = 'main') {
    echo "Cloning repository: ${repoUrl} on branch: ${branch}"
    git url: repoUrl, branch: branch
}
```

**vars/dockerBuild.groovy:**
```groovy
def call(String imageName, String tag = 'latest', String dockerHubUsername) {
    echo "Building Docker image: ${dockerHubUsername}/${imageName}:${tag}"
    sh "docker build -t ${imageName} ."
    sh "docker tag ${imageName} ${dockerHubUsername}/${imageName}:${tag}"
}
```

## Quick Setup Checklists

**Credentials Binding:**
- Add credentials in Manage Jenkins → Credentials
- Reference with `withCredentials` or `sshagent`
- Avoid printing secrets
- Use `--password-stdin` for Docker login

**GitHub Webhooks:**
- Public Jenkins URL reachable
- Repo → Settings → Webhooks → Add → payload URL `/github-webhook/`
- Job trigger: "GitHub hook trigger for GITScm polling"
- Test webhook delivery

**Shared Libraries:**
- Create library repo with `vars/` directory
- Register library in Global Pipeline Libraries
- Import with `@Library('name') _`
- Call custom functions in script blocks

**Agent for Docker:**
- Install Docker/Compose
- `sudo usermod -aG docker jenkins` then restart/newgrp
- Verify: `docker version` and `docker run hello-world`

**Pipeline Requirements:**
- Docker Hub credentials configured (`dockerHubCreds`)
- Shared library `ak-libraries` with `cloneRepo` and `dockerBuild` functions
- Agent has Docker permissions
- Repository has `docker-compose.yml` file

This revision covers secure credential management, automated GitHub webhooks, reusable shared libraries, and a complete CI/CD pipeline example using custom library functions.