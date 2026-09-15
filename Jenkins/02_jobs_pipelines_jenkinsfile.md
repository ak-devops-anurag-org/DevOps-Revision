# Jobs, Pipelines & Jenkinsfile

> **Interview Takeaways**: Know Declarative vs Scripted syntax by heart, understand all pipeline directives, be able to write a Jenkinsfile from scratch, and explain credentials usage in pipelines.

---

## 1. CI/CD Concepts Recap

| Concept | Definition |
|---------|-----------|
| **Continuous Integration (CI)** | Developers merge code frequently → automated build + test on every commit |
| **Continuous Delivery (CD)** | CI + automated deployment to staging, manual approval for production |
| **Continuous Deployment** | CI + fully automated deployment to production (no manual gate) |

**Jenkins's role**: Orchestrates the entire CI/CD pipeline — triggered by code changes, executes build/test/scan/deploy stages.

---

## 2. Pipeline Fundamentals

### What Is a Jenkins Pipeline?

A **Pipeline** is a suite of automated steps defined as code (Jenkinsfile) that implements the entire build-test-deploy workflow.

### Pipeline as Code

- Jenkinsfile stored **in the Git repository** alongside application code
- Version-controlled, reviewable via PRs, auditable
- Survives Jenkins controller failure (code is in Git)

### Benefits Over Freestyle

- Multi-stage, parallel execution
- Conditional logic, loops, error handling
- Shared libraries for reuse
- Can be resumed from failed stage
- Supports manual approval gates

---

## 3. Declarative vs Scripted Pipeline ⭐

This is one of the **most frequently asked** Jenkins interview questions.

### Side-by-Side Comparison

| Feature | Declarative | Scripted |
|---------|------------|----------|
| **Syntax** | Structured, opinionated | Full Groovy scripting |
| **Wrapper** | `pipeline { }` | `node { }` |
| **Learning curve** | Lower | Higher |
| **Flexibility** | Less flexible | Maximum flexibility |
| **Error handling** | `post { }` block | `try-catch-finally` |
| **Stages** | Required `stages { stage { } }` | Optional `stage()` |
| **Validation** | Pre-validated before execution | Runtime errors only |
| **Restart** | Can restart from failed stage | Cannot restart from stage |
| **Recommended** | ✅ For most use cases | Complex/dynamic workflows |

### Declarative Pipeline Example

```groovy
pipeline {
    agent any
    
    environment {
        APP_NAME = 'my-app'
        DOCKER_REGISTRY = 'myregistry.azurecr.io'
    }
    
    stages {
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
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                sh './deploy.sh'
            }
        }
    }
    
    post {
        success { echo 'Pipeline succeeded!' }
        failure { echo 'Pipeline failed!' }
    }
}
```

### Scripted Pipeline Example

```groovy
node {
    try {
        stage('Build') {
            checkout scm
            sh 'mvn clean package -DskipTests'
        }
        stage('Test') {
            sh 'mvn test'
        }
        if (env.BRANCH_NAME == 'main') {
            stage('Deploy') {
                sh './deploy.sh'
            }
        }
    } catch (Exception e) {
        currentBuild.result = 'FAILURE'
        throw e
    } finally {
        junit 'target/surefire-reports/*.xml'
    }
}
```

### When to Use Which

- **Declarative** → 90% of use cases. Structured, validated, easier to maintain.
- **Scripted** → When you need complex Groovy logic, dynamic stage generation, or unconventional workflows.

---

## 4. Jenkinsfile Deep Dive

### Pipeline Structure

```groovy
pipeline {
    agent { ... }         // Where to run
    options { ... }       // Pipeline-level settings
    environment { ... }   // Environment variables
    parameters { ... }    // User inputs
    triggers { ... }      // Automatic triggers
    tools { ... }         // Tool installations
    stages {              // The work
        stage('Name') {
            agent { ... }     // Stage-level agent override
            when { ... }      // Conditional execution
            environment { ... }
            steps { ... }     // Actual commands
            post { ... }      // Stage-level post actions
        }
    }
    post { ... }          // Pipeline-level post actions
}
```

### `agent` Directive

```groovy
// Run on any available agent
agent any

// Don't allocate an agent at pipeline level (set per stage)
agent none

// Run on agent with specific label
agent { label 'linux && docker' }

// Run inside a Docker container
agent {
    docker {
        image 'maven:3.9-eclipse-temurin-17'
        args '-v $HOME/.m2:/root/.m2'
    }
}

// Run inside a Kubernetes pod
agent {
    kubernetes {
        yaml '''
        apiVersion: v1
        kind: Pod
        spec:
          containers:
          - name: maven
            image: maven:3.9
            command: ['sleep', 'infinity']
        '''
        defaultContainer 'maven'
    }
}
```

### `environment` Block

```groovy
pipeline {
    agent any
    environment {
        // Static values
        APP_NAME = 'my-app'
        
        // From credentials (auto-masked in logs)
        DOCKER_CREDS = credentials('docker-hub-creds')  // Sets DOCKER_CREDS_USR and DOCKER_CREDS_PSW
        API_KEY = credentials('api-key-secret-text')
        
        // From shell command
        GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
    }
    stages {
        stage('Example') {
            environment {
                // Stage-level env var
                STAGE_VAR = 'only-in-this-stage'
            }
            steps {
                sh 'echo $APP_NAME'
                sh 'echo $DOCKER_CREDS_USR'
            }
        }
    }
}
```

### `parameters` Block

```groovy
pipeline {
    agent any
    parameters {
        string(name: 'BRANCH', defaultValue: 'main', description: 'Branch to build')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
        booleanParam(name: 'RUN_TESTS', defaultValue: true, description: 'Run test suite?')
        password(name: 'DEPLOY_TOKEN', description: 'Deployment token')
    }
    stages {
        stage('Deploy') {
            when {
                expression { params.ENVIRONMENT == 'prod' }
            }
            steps {
                sh "deploy.sh --env ${params.ENVIRONMENT} --branch ${params.BRANCH}"
            }
        }
    }
}
```

### `when` Directive — Conditional Execution

```groovy
stage('Deploy to Prod') {
    when {
        branch 'main'                               // Only on main branch
    }
    steps { sh './deploy-prod.sh' }
}

stage('Deploy to Dev') {
    when {
        branch 'develop'
    }
    steps { sh './deploy-dev.sh' }
}

stage('Run Integration Tests') {
    when {
        expression { params.RUN_TESTS == true }      // Based on parameter
    }
    steps { sh 'mvn verify' }
}

stage('Nightly Build') {
    when {
        triggeredBy 'TimerTrigger'                   // Only when triggered by cron
    }
    steps { sh 'mvn clean package' }
}

stage('PR Validation') {
    when {
        changeRequest()                              // Only on pull requests
    }
    steps { sh 'mvn test' }
}

// Multiple conditions
stage('Prod Deploy') {
    when {
        allOf {
            branch 'main'
            environment name: 'DEPLOY_ENABLED', value: 'true'
        }
    }
    steps { sh './deploy.sh' }
}
```

### `input` — Manual Approval Gate

```groovy
stage('Approval') {
    steps {
        input message: 'Deploy to production?',
              ok: 'Deploy',
              submitter: 'admin,devops-lead',
              parameters: [
                  choice(name: 'CONFIRM', choices: ['yes', 'no'], description: 'Confirm deployment')
              ]
    }
}

// Better pattern — don't hold the agent during approval
stage('Approval') {
    agent none
    steps {
        input message: 'Deploy to production?', ok: 'Approve'
    }
}
stage('Deploy') {
    agent { label 'deploy' }
    steps {
        sh './deploy.sh'
    }
}
```

### `post` Block

```groovy
pipeline {
    agent any
    stages {
        stage('Build') { steps { sh 'mvn package' } }
    }
    post {
        always {
            // Runs regardless of result
            junit 'target/surefire-reports/*.xml'
            cleanWs()
        }
        success {
            slackSend color: 'good', message: "Build #${BUILD_NUMBER} succeeded"
        }
        failure {
            slackSend color: 'danger', message: "Build #${BUILD_NUMBER} FAILED"
        }
        unstable {
            echo 'Build is unstable (test failures)'
        }
        cleanup {
            // Runs after all other post conditions
            echo 'Final cleanup'
        }
    }
}
```

### `options` Block

```groovy
pipeline {
    agent any
    options {
        timeout(time: 30, unit: 'MINUTES')           // Pipeline timeout
        retry(2)                                       // Retry entire pipeline
        timestamps()                                   // Add timestamps to console
        buildDiscarder(logRotator(numToKeepStr: '10')) // Keep last 10 builds
        disableConcurrentBuilds()                      // Prevent parallel runs
        skipDefaultCheckout()                          // Don't auto-checkout
    }
    stages { ... }
}
```

### `triggers` Block

```groovy
pipeline {
    agent any
    triggers {
        // Cron schedule (build every night at 2 AM)
        cron('H 2 * * *')
        
        // Poll SCM every 5 minutes
        pollSCM('H/5 * * * *')
        
        // Trigger when upstream job completes
        upstream(upstreamProjects: 'build-library', threshold: hudson.model.Result.SUCCESS)
    }
    stages { ... }
}
```

### `tools` Block

```groovy
pipeline {
    agent any
    tools {
        maven 'Maven-3.9'        // Name configured in Global Tool Configuration
        jdk 'JDK-17'
        gradle 'Gradle-8.0'
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn --version'
            }
        }
    }
}
```

---

## 5. Credentials in Pipelines ⭐

### Using `credentials()` Helper (Declarative)

```groovy
environment {
    // Secret text → single variable
    API_KEY = credentials('api-key-id')
    
    // Username/password → creates _USR and _PSW variables
    DOCKER_CREDS = credentials('dockerhub-creds')
    // Access: ${DOCKER_CREDS_USR} and ${DOCKER_CREDS_PSW}
    
    // SSH key → writes key to temp file, variable holds the path
    SSH_KEY = credentials('ssh-deploy-key')
}
```

### Using `withCredentials` Block

```groovy
// Secret text
steps {
    withCredentials([string(credentialsId: 'api-token', variable: 'TOKEN')]) {
        sh 'curl -H "Authorization: Bearer $TOKEN" https://api.example.com'
    }
}

// Username and password
steps {
    withCredentials([usernamePassword(
        credentialsId: 'docker-creds',
        usernameVariable: 'DOCKER_USER',
        passwordVariable: 'DOCKER_PASS'
    )]) {
        sh 'docker login -u $DOCKER_USER -p $DOCKER_PASS'
    }
}

// SSH key
steps {
    withCredentials([sshUserPrivateKey(
        credentialsId: 'ssh-key',
        keyFileVariable: 'SSH_KEY_FILE',
        usernameVariable: 'SSH_USER'
    )]) {
        sh 'ssh -i $SSH_KEY_FILE $SSH_USER@server.example.com "deploy.sh"'
    }
}

// File credential
steps {
    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
        sh 'kubectl get pods'
    }
}
```

### Masking Secrets in Logs

- `credentials()` and `withCredentials` automatically mask values in console output
- **Never** use `echo` or `println` with credentials
- Use `set +x` before shell commands to avoid command echoing:
  ```groovy
  sh '''
      set +x
      curl -H "Authorization: Bearer $TOKEN" https://api.example.com
  '''
  ```

---

## 6. Built-in Environment Variables

| Variable | Description |
|----------|-------------|
| `BUILD_NUMBER` | Current build number |
| `BUILD_ID` | Current build ID (same as BUILD_NUMBER) |
| `BUILD_URL` | URL of the current build |
| `JOB_NAME` | Name of the job |
| `JOB_URL` | URL of the job |
| `WORKSPACE` | Absolute path of the workspace |
| `BRANCH_NAME` | Branch name (Multibranch Pipeline only) |
| `CHANGE_ID` | PR/MR number (Multibranch Pipeline) |
| `GIT_COMMIT` | Git commit SHA |
| `GIT_BRANCH` | Git branch |
| `NODE_NAME` | Name of the agent node |
| `EXECUTOR_NUMBER` | Executor number on the node |
| `JENKINS_URL` | URL of the Jenkins instance |
| `BUILD_TAG` | Unique identifier: `jenkins-{JOB_NAME}-{BUILD_NUMBER}` |

Access in pipeline:
```groovy
sh "echo Build: ${env.BUILD_NUMBER} on branch: ${env.BRANCH_NAME}"
```

---

## 7. Build Triggers

| Trigger | How | Use Case |
|---------|-----|----------|
| **Webhook** | GitHub/GitLab sends POST to Jenkins | ✅ Recommended — instant, efficient |
| **Poll SCM** | Jenkins periodically checks for changes | Fallback when webhook isn't possible |
| **Cron** | Time-based schedule | Nightly builds, scheduled tasks |
| **Upstream** | Triggered when another job completes | Dependency chains |
| **Manual** | User clicks "Build Now" | Ad-hoc, on-demand |
| **Remote API** | HTTP POST to Jenkins API | External system integration |

---

## 8. Error Handling

### Declarative: `post` Blocks

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps { sh 'mvn package' }
        }
    }
    post {
        failure {
            slackSend message: "Build failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
    }
}
```

### Scripted: `try-catch`

```groovy
node {
    try {
        stage('Build') { sh 'mvn package' }
        stage('Deploy') { sh './deploy.sh' }
    } catch (Exception e) {
        currentBuild.result = 'FAILURE'
        slackSend message: "Failed: ${e.getMessage()}"
        throw e
    } finally {
        cleanWs()
    }
}
```

### `catchError` — Continue Pipeline on Stage Failure

```groovy
stage('Security Scan') {
    steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
            sh 'trivy image myapp:latest --exit-code 1'
        }
    }
}
// Pipeline continues, but build is marked UNSTABLE
```

### `retry` and `timeout`

```groovy
stage('Deploy') {
    steps {
        retry(3) {
            timeout(time: 5, unit: 'MINUTES') {
                sh './deploy.sh'
            }
        }
    }
}
```

---

## 9. Parallel Stages

```groovy
stage('Tests') {
    parallel {
        stage('Unit Tests') {
            agent { label 'linux' }
            steps { sh 'mvn test' }
        }
        stage('Integration Tests') {
            agent { label 'linux' }
            steps { sh 'mvn verify -Pintegration' }
        }
        stage('Security Scan') {
            agent { label 'linux' }
            steps { sh 'trivy fs .' }
        }
    }
}

// With failFast — abort all parallel stages if one fails
stage('Tests') {
    failFast true
    parallel {
        stage('Unit') { steps { sh 'mvn test' } }
        stage('Lint') { steps { sh 'mvn checkstyle:check' } }
    }
}
```

---

## 10. Artifacts

### Archive Artifacts

```groovy
stage('Build') {
    steps {
        sh 'mvn package'
    }
    post {
        success {
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
        }
    }
}
```

### Stash/Unstash — Pass Files Between Stages (Across Agents)

```groovy
stage('Build') {
    agent { label 'build' }
    steps {
        sh 'mvn package'
        stash name: 'build-artifacts', includes: 'target/*.jar'
    }
}
stage('Deploy') {
    agent { label 'deploy' }
    steps {
        unstash 'build-artifacts'
        sh 'deploy.sh target/app.jar'
    }
}
```

### Publish Test Results

```groovy
post {
    always {
        junit testResults: 'target/surefire-reports/*.xml', allowEmptyResults: true
    }
}
```

---

## 11. Practical Jenkinsfile Examples

### Example 1: Basic Build → Test → Deploy

```groovy
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        stage('Build') {
            steps { sh 'mvn clean package -DskipTests' }
        }
        stage('Test') {
            steps { sh 'mvn test' }
            post { always { junit 'target/surefire-reports/*.xml' } }
        }
        stage('Deploy') {
            when { branch 'main' }
            steps { sh './scripts/deploy.sh' }
        }
    }
    post {
        failure { slackSend message: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}" }
    }
}
```

### Example 2: Pipeline with Docker Agent

```groovy
pipeline {
    agent {
        docker {
            image 'node:20-alpine'
            args '-v $HOME/.npm:/root/.npm'  // Cache npm packages
        }
    }
    stages {
        stage('Install') {
            steps { sh 'npm ci' }
        }
        stage('Test') {
            steps { sh 'npm test' }
        }
        stage('Build') {
            steps { sh 'npm run build' }
        }
    }
}
```

### Example 3: Pipeline with Parameters & Approval

```groovy
pipeline {
    agent any
    parameters {
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: 'Deploy target')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false)
    }
    stages {
        stage('Build') {
            steps { sh 'mvn package' }
        }
        stage('Test') {
            when { expression { !params.SKIP_TESTS } }
            steps { sh 'mvn test' }
        }
        stage('Approval') {
            when { expression { params.ENV == 'prod' } }
            agent none
            steps {
                input message: "Deploy to PRODUCTION?", ok: 'Deploy', submitter: 'devops-team'
            }
        }
        stage('Deploy') {
            steps { sh "ansible-playbook deploy.yml -e env=${params.ENV}" }
        }
    }
}
```

### Example 4: Parallel Stages with Matrix

```groovy
pipeline {
    agent none
    stages {
        stage('Test Matrix') {
            parallel {
                stage('JDK 17') {
                    agent { docker { image 'maven:3.9-eclipse-temurin-17' } }
                    steps { sh 'mvn test' }
                }
                stage('JDK 21') {
                    agent { docker { image 'maven:3.9-eclipse-temurin-21' } }
                    steps { sh 'mvn test' }
                }
            }
        }
    }
}
```

### Example 5: Multi-Environment Deployment

```groovy
pipeline {
    agent any
    environment {
        IMAGE = "myregistry.azurecr.io/myapp:${BUILD_NUMBER}"
    }
    stages {
        stage('Build & Push Image') {
            steps {
                sh "docker build -t ${IMAGE} ."
                withCredentials([usernamePassword(credentialsId: 'acr-creds', usernameVariable: 'ACR_USER', passwordVariable: 'ACR_PASS')]) {
                    sh "docker login myregistry.azurecr.io -u $ACR_USER -p $ACR_PASS"
                    sh "docker push ${IMAGE}"
                }
            }
        }
        stage('Deploy to Dev') {
            when { branch 'develop' }
            steps { sh "kubectl set image deployment/myapp myapp=${IMAGE} -n dev" }
        }
        stage('Deploy to Staging') {
            when { branch 'main' }
            steps { sh "kubectl set image deployment/myapp myapp=${IMAGE} -n staging" }
        }
        stage('Deploy to Prod') {
            when {
                allOf {
                    branch 'main'
                    expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
                }
            }
            steps {
                input message: 'Deploy to Production?', ok: 'Deploy'
                sh "kubectl set image deployment/myapp myapp=${IMAGE} -n production"
            }
        }
    }
}
```

---

## Key Interview Questions from This Section

1. **What is a Jenkinsfile?** → A text file defining the pipeline, stored in the project's Git repo.
2. **Declarative vs Scripted?** → Declarative is structured (`pipeline {}`); Scripted is full Groovy (`node {}`). Use Declarative for 90% of cases.
3. **How do you handle credentials?** → `withCredentials` block or `credentials()` helper; values auto-masked in logs.
4. **What is `when`?** → Conditional execution based on branch, expression, environment, or trigger.
5. **How do you handle errors?** → `post { failure {} }` in declarative; `try-catch` in scripted; `catchError` for soft failures.
6. **What are parallel stages?** → Run multiple stages concurrently; use `failFast` to abort on first failure.
