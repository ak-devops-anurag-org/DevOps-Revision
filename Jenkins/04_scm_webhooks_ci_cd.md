# SCM Integration, Webhooks & CI/CD

> **Interview Takeaways**: Understand webhook vs Poll SCM, Multibranch Pipeline setup, branch-based CI/CD strategy, and the end-to-end CI/CD flow from Git push to Kubernetes deployment.

---

## 1. Git/GitHub Integration

### Required Plugins

| Plugin | Purpose |
|--------|---------|
| **Git** | Core Git operations (clone, fetch, checkout) |
| **GitHub** | GitHub webhook support, PR status updates |
| **GitHub Branch Source** | Multibranch Pipeline discovery from GitHub |
| **GitLab** | GitLab webhook and integration |
| **Bitbucket** | Bitbucket Cloud/Server integration |

### SSH vs HTTPS for Git Cloning

| Method | When to Use | Credential Type |
|--------|------------|----------------|
| **HTTPS** | Simple setup, token-based auth | Username + Personal Access Token |
| **SSH** | More secure, no token expiry issues | SSH private key |

```groovy
// HTTPS checkout
steps {
    git url: 'https://github.com/org/repo.git',
        branch: 'main',
        credentialsId: 'github-pat'
}

// SSH checkout
steps {
    git url: 'git@github.com:org/repo.git',
        branch: 'main',
        credentialsId: 'github-ssh-key'
}

// Default checkout (from Multibranch or Pipeline SCM config)
steps {
    checkout scm
}
```

### Credentials for Private Repos

```groovy
// Method 1: Using checkout step
checkout([
    $class: 'GitSCM',
    branches: [[name: '*/main']],
    userRemoteConfigs: [[
        url: 'https://github.com/org/private-repo.git',
        credentialsId: 'github-pat'
    ]]
])

// Method 2: Using environment + credentials helper
environment {
    GIT_CREDS = credentials('github-pat')
}
```

---

## 2. Webhooks ⭐

### What Is a Webhook?

A webhook is a **push notification** — when an event occurs in Git (push, PR), the Git platform sends an HTTP POST to Jenkins to trigger a build.

### GitHub Webhook Setup

1. **In GitHub**: Repository → Settings → Webhooks → Add webhook
2. **Payload URL**: `https://jenkins.example.com/github-webhook/`
3. **Content type**: `application/json`
4. **Events**: Push events, Pull request events
5. **Secret**: Set a shared secret for payload verification

### Webhook Endpoints by Platform

| Platform | Jenkins Webhook URL |
|----------|-------------------|
| **GitHub** | `JENKINS_URL/github-webhook/` |
| **GitLab** | `JENKINS_URL/project/JOB_NAME` |
| **Bitbucket** | `JENKINS_URL/bitbucket-hook/` |
| **Generic** | `JENKINS_URL/generic-webhook-trigger/invoke?token=TOKEN` |

### Webhook Flow

```
Developer pushes code
        ↓
GitHub/GitLab detects push event
        ↓
Sends HTTP POST to Jenkins webhook URL
  (includes branch, commit, author info)
        ↓
Jenkins receives payload
        ↓
Matches to configured job/Multibranch Pipeline
        ↓
Triggers build on the relevant branch
```

### Generic Webhook Trigger Plugin

For custom integrations or platforms without native Jenkins plugins:

```groovy
pipeline {
    agent any
    triggers {
        GenericTrigger(
            genericVariables: [
                [key: 'BRANCH', value: '$.ref'],
                [key: 'COMMIT', value: '$.after']
            ],
            token: 'my-build-token',
            causeString: 'Triggered by webhook',
            printContributedVariables: true
        )
    }
    stages {
        stage('Build') {
            steps {
                echo "Building branch: ${BRANCH}, commit: ${COMMIT}"
            }
        }
    }
}
```

### Webhook Security

- **Shared secret** — validate payload signature (GitHub: `X-Hub-Signature-256` header)
- **IP whitelisting** — restrict webhook sources to Git platform IPs
- **HTTPS only** — encrypt webhook payloads in transit
- **Token authentication** — use build trigger tokens
- **CSRF protection** — configure crumb issuer in Jenkins

---

## 3. Poll SCM vs Webhook

| Feature | Poll SCM | Webhook |
|---------|----------|---------|
| **How it works** | Jenkins periodically checks Git for changes | Git pushes notification to Jenkins |
| **Latency** | Delayed (polling interval) | Instant (within seconds) |
| **Resource usage** | ❌ Constant Git API calls | ✅ Only on actual events |
| **Network** | Jenkins needs outbound access to Git | Git needs access to Jenkins |
| **Reliability** | Always works if Git is reachable | Can miss events if Jenkins is down |
| **Setup** | Simpler (no external config needed) | Requires Git platform configuration |
| **Recommended** | Fallback only | ✅ **Always preferred** |

### Poll SCM Configuration

```groovy
pipeline {
    agent any
    triggers {
        pollSCM('H/5 * * * *')   // Check every 5 minutes
    }
    stages {
        stage('Build') {
            steps { sh 'mvn package' }
        }
    }
}
```

> **`H` notation**: Jenkins hash-based distribution — `H/5 * * * *` means "every 5 minutes, but spread across different minutes to avoid thundering herd".

### When to Use Poll SCM

- Jenkins behind firewall (Git can't reach it)
- Air-gapped environments
- As a **backup** alongside webhooks (belt and suspenders)

---

## 4. Multibranch Pipelines ⭐

### What Is a Multibranch Pipeline?

A Multibranch Pipeline **automatically discovers branches** (and PRs) in a Git repository and creates a sub-job for each branch that contains a `Jenkinsfile`.

### How Branch Discovery Works

```
Repository: github.com/org/myapp
├── main          → Jenkinsfile exists → Jenkins creates "main" job
├── develop       → Jenkinsfile exists → Jenkins creates "develop" job
├── feature/login → Jenkinsfile exists → Jenkins creates "feature%2Flogin" job
├── hotfix/bug123 → No Jenkinsfile     → Ignored
└── PR #42        → Jenkinsfile exists → Jenkins creates "PR-42" job
```

1. Jenkins scans the repository periodically or via webhook
2. Discovers branches/PRs with a `Jenkinsfile`
3. Creates/removes pipeline jobs automatically
4. Each branch runs its own Jenkinsfile

### Configuration

1. New Item → Multibranch Pipeline
2. **Branch Sources**: Add GitHub / Git
3. **Credentials**: For private repos
4. **Behaviours**:
   - Discover branches (all, only with PRs, exclude patterns)
   - Discover PRs (merge with target, head only)
   - Filter by name: `main develop release/*`
5. **Build Configuration**: `Jenkinsfile` path (default: root)
6. **Scan triggers**: Periodically, or via webhook

### Branch Filtering

```
# Include only specific branches
Include: main develop release/*

# Exclude patterns
Exclude: WIP/* experimental/*
```

### Organization Folders

For organizations with many repos — automatically discovers all repos with Jenkinsfiles:

1. New Item → Organization Folder
2. Set GitHub Organization or GitLab Group
3. Jenkins discovers all repos → creates Multibranch Pipelines for each

---

## 5. Branch-Based CI/CD

### Strategy: Feature Branch Workflow

```
feature/xyz → PR → develop → release/1.0 → main
     ↓          ↓       ↓           ↓          ↓
   Build     Build   Build+      Build+     Build+
   +Test     +Test   Deploy      Deploy     Deploy
                     to Dev      to Staging  to Prod
```

### Using `BRANCH_NAME` for Conditional Deployment

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps { sh 'mvn clean package' }
        }
        stage('Test') {
            steps { sh 'mvn test' }
        }
        stage('Deploy to Dev') {
            when { branch 'develop' }
            steps { sh 'kubectl apply -f k8s/ -n dev' }
        }
        stage('Deploy to Staging') {
            when { branch pattern: 'release/*', comparator: 'GLOB' }
            steps { sh 'kubectl apply -f k8s/ -n staging' }
        }
        stage('Deploy to Production') {
            when { branch 'main' }
            steps {
                input message: 'Deploy to Production?', ok: 'Deploy'
                sh 'kubectl apply -f k8s/ -n production'
            }
        }
    }
}
```

### PR-Based CI

```groovy
stage('PR Validation') {
    when { changeRequest() }
    steps {
        sh 'mvn test'
        sh 'mvn sonar:sonar'
        // Post status check back to GitHub
    }
}

stage('PR Cleanup') {
    when {
        changeRequest()
        expression { return env.CHANGE_TARGET == 'main' }
    }
    steps {
        echo "PR #${env.CHANGE_ID} targeting ${env.CHANGE_TARGET}"
    }
}
```

---

## 6. Complete CI/CD Flow

### End-to-End Pipeline

```
Developer
   ↓
Git Push (feature branch)
   ↓
Webhook triggers Jenkins
   ↓
┌─────────────────────────────────────────┐
│            Jenkins Pipeline              │
│                                          │
│  ┌──────────┐                            │
│  │ Checkout │ Clone repo                 │
│  └────┬─────┘                            │
│       ↓                                  │
│  ┌──────────┐                            │
│  │  Build   │ Compile, package           │
│  └────┬─────┘                            │
│       ↓                                  │
│  ┌──────────┐                            │
│  │  Test    │ Unit + Integration tests   │
│  └────┬─────┘                            │
│       ↓                                  │
│  ┌──────────────┐                        │
│  │ Security Scan│ SonarQube, OWASP       │
│  └────┬─────────┘                        │
│       ↓                                  │
│  ┌──────────────┐                        │
│  │ Docker Build │ Build container image  │
│  └────┬─────────┘                        │
│       ↓                                  │
│  ┌──────────────┐                        │
│  │ Image Scan  │ Trivy CVE scan          │
│  └────┬─────────┘                        │
│       ↓                                  │
│  ┌──────────────┐                        │
│  │ Push Image  │ Docker Hub / ECR / ACR  │
│  └────┬─────────┘                        │
│       ↓                                  │
│  ┌──────────────┐                        │
│  │   Deploy    │ kubectl / helm          │
│  └────┬─────────┘                        │
│       ↓                                  │
│  ┌──────────────┐                        │
│  │ Smoke Test  │ Verify deployment       │
│  └────┬─────────┘                        │
│       ↓                                  │
│  ┌──────────────┐                        │
│  │   Notify    │ Slack / Email / Teams   │
│  └──────────────┘                        │
└─────────────────────────────────────────┘
         ↓
   Kubernetes Cluster
```

### Jenkinsfile Implementing the Full Flow

```groovy
pipeline {
    agent any

    environment {
        REGISTRY     = 'myregistry.azurecr.io'
        IMAGE        = "${REGISTRY}/myapp"
        IMAGE_TAG    = "${BUILD_NUMBER}"
        SONAR_TOKEN  = credentials('sonarqube-token')
        DOCKER_CREDS = credentials('acr-creds')
        KUBECONFIG   = credentials('kubeconfig-prod')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                }
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always { junit 'target/surefire-reports/*.xml' }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh 'mvn sonar:sonar'
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t ${IMAGE}:${IMAGE_TAG} -t ${IMAGE}:latest ."
            }
        }

        stage('Image Scan') {
            steps {
                sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${IMAGE}:${IMAGE_TAG}"
            }
        }

        stage('Push Image') {
            steps {
                sh "echo ${DOCKER_CREDS_PSW} | docker login ${REGISTRY} -u ${DOCKER_CREDS_USR} --password-stdin"
                sh "docker push ${IMAGE}:${IMAGE_TAG}"
                sh "docker push ${IMAGE}:latest"
            }
        }

        stage('Deploy to Dev') {
            when { branch 'develop' }
            steps {
                sh "kubectl set image deployment/myapp myapp=${IMAGE}:${IMAGE_TAG} -n dev"
                sh "kubectl rollout status deployment/myapp -n dev --timeout=120s"
            }
        }

        stage('Deploy to Production') {
            when { branch 'main' }
            steps {
                input message: 'Deploy to Production?', ok: 'Deploy', submitter: 'devops-team'
                sh "kubectl set image deployment/myapp myapp=${IMAGE}:${IMAGE_TAG} -n production"
                sh "kubectl rollout status deployment/myapp -n production --timeout=180s"
            }
        }
    }

    post {
        success {
            slackSend color: 'good', message: "✅ ${JOB_NAME} #${BUILD_NUMBER} succeeded (${GIT_COMMIT_SHORT})"
        }
        failure {
            slackSend color: 'danger', message: "❌ ${JOB_NAME} #${BUILD_NUMBER} FAILED (${GIT_COMMIT_SHORT})"
        }
        always {
            cleanWs()
        }
    }
}
```

---

## Key Interview Questions from This Section

1. **How does a webhook trigger Jenkins?** → Git platform sends HTTP POST to Jenkins endpoint; Jenkins matches to job and triggers build.
2. **Poll SCM vs Webhook?** → Webhook is instant and efficient; Poll SCM polls on schedule (wasteful but works behind firewalls).
3. **What is a Multibranch Pipeline?** → Auto-discovers branches with Jenkinsfiles, creates pipeline per branch, supports PRs.
4. **How do you implement branch-based CI/CD?** → Use `when { branch 'main' }` for conditional stages; Multibranch Pipeline for auto-discovery.
5. **Describe a complete CI/CD flow** → Checkout → Build → Test → Security Scan → Docker Build → Image Scan → Push → Deploy → Notify.
