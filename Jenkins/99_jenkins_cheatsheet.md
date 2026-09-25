# Jenkins Cheat Sheet — Last-Minute Interview Revision

> **30 minutes before your interview?** Read this file.

---

## 1. Architecture

- **Controller** → orchestrates, schedules, UI, config, credentials. Never runs builds in production.
- **Agent** → executes builds. Types: SSH (permanent), Docker (ephemeral), Kubernetes (auto-scale).
- **Communication**: SSH (controller→agent), JNLP/TCP port 50000 (agent→controller), WebSocket.
- **Controller executors = 0** in production. Always.
- `JENKINS_HOME` = config.xml + credentials.xml + secrets/ + jobs/ + plugins/ + nodes/

### Key Terminology

| Term | Meaning |
|------|---------|
| Job | Runnable task (build/test/deploy) |
| Build | Single execution of a job |
| Executor | Slot that runs one build |
| Workspace | Directory where build runs |
| Node | Machine (controller or agent) |
| Queue | Waiting area for pending builds |

---

## 2. Pipeline Syntax Quick Reference

```groovy
pipeline {
    agent any                          // Where to run
    options {                          // Pipeline settings
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        disableConcurrentBuilds()
    }
    environment {                      // Env vars
        APP = 'myapp'
        CREDS = credentials('cred-id')
    }
    parameters {                       // User inputs
        string(name: 'BRANCH', defaultValue: 'main')
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'])
        booleanParam(name: 'SKIP_TESTS', defaultValue: false)
    }
    triggers {                         // Automatic triggers
        pollSCM('H/5 * * * *')
        cron('H 2 * * *')
    }
    tools { maven 'Maven-3.9' }       // Tool installations

    stages {
        stage('Build') {
            agent { label 'linux' }    // Stage-level agent
            when { branch 'main' }     // Conditional
            steps {
                sh 'mvn package'
            }
        }
        stage('Approval') {
            agent none
            steps {
                input message: 'Deploy?', ok: 'Yes', submitter: 'admin'
            }
        }
    }
    post {
        always  { cleanWs() }
        success { echo 'Passed' }
        failure { echo 'Failed' }
        unstable { echo 'Unstable' }
    }
}
```

---

## 3. Common Jenkinsfile Snippets

### Docker Agent
```groovy
agent { docker { image 'maven:3.9'; args '-v $HOME/.m2:/root/.m2' } }
```

### Kubernetes Agent
```groovy
agent {
    kubernetes {
        yaml '''
        spec:
          containers:
          - name: maven
            image: maven:3.9
            command: ['sleep','infinity']
        '''
        defaultContainer 'maven'
    }
}
```

### Parallel Stages
```groovy
stage('Tests') {
    failFast true
    parallel {
        stage('Unit') { steps { sh 'mvn test' } }
        stage('Lint') { steps { sh 'mvn checkstyle:check' } }
    }
}
```

### Credentials
```groovy
// Method 1: environment
environment { TOKEN = credentials('api-token') }

// Method 2: withCredentials
withCredentials([usernamePassword(credentialsId: 'docker', usernameVariable: 'U', passwordVariable: 'P')]) {
    sh 'echo $P | docker login -u $U --password-stdin'
}
withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
    sh 'kubectl get pods'
}
```

### Conditional Execution
```groovy
when { branch 'main' }
when { expression { params.ENV == 'prod' } }
when { changeRequest() }                       // PR only
when { changeset 'terraform/**' }              // File change
when { allOf { branch 'main'; environment name: 'DEPLOY', value: 'true' } }
```

### Approval Gate
```groovy
stage('Approve') {
    agent none   // Don't hold executor
    steps { input message: 'Deploy to prod?', ok: 'Deploy', submitter: 'devops' }
}
```

### Shared Library
```groovy
@Library('my-shared-lib') _
pipeline { stages { stage('Build') { steps { buildApp() } } } }
```

### Error Handling
```groovy
// Soft fail (mark UNSTABLE, continue)
catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
    sh 'trivy image --exit-code 1 myapp:latest'
}

// Retry + timeout
retry(3) { timeout(time: 5, unit: 'MINUTES') { sh './deploy.sh' } }
```

---

## 4. Declarative vs Scripted

| | Declarative | Scripted |
|-|------------|---------|
| **Wrapper** | `pipeline { }` | `node { }` |
| **Syntax** | Structured DSL | Full Groovy |
| **Validation** | Pre-run | Runtime only |
| **Error handling** | `post { }` | `try-catch` |
| **Restart** | From failed stage | From beginning |
| **Use case** | ✅ 90% of pipelines | Complex logic |

---

## 5. Agents Quick Reference

```groovy
agent any                                      // Any available agent
agent none                                     // No agent (set per stage)
agent { label 'linux && docker' }              // Label matching
agent { docker { image 'node:20' } }           // Docker container
agent { kubernetes { yaml '...' } }            // K8s pod
```

- **Static**: Always-on VMs, SSH connected, accumulate state
- **Dynamic**: Docker/K8s, per-build, clean, auto-scale → ✅ preferred
- **Labels**: Tag agents by capability (`linux`, `docker`, `gpu`, `deploy-prod`)
- **Executors**: Slots per agent; controller = 0 in production

---

## 6. Credentials Quick Reference

| Type | withCredentials Syntax |
|------|----------------------|
| **Secret text** | `string(credentialsId: 'id', variable: 'VAR')` |
| **Username/password** | `usernamePassword(credentialsId: 'id', usernameVariable: 'U', passwordVariable: 'P')` |
| **SSH key** | `sshUserPrivateKey(credentialsId: 'id', keyFileVariable: 'KEY')` |
| **Secret file** | `file(credentialsId: 'id', variable: 'FILE_PATH')` |

- **Scopes**: Global (all jobs), System (internals only), Folder (team isolation)
- **Masking**: Auto-masked in console output with `withCredentials`/`credentials()`
- **Never**: `echo` secrets, hardcode in Jenkinsfile, pass as build params

---

## 7. Git & Webhooks

```groovy
// Git checkout
checkout scm                                   // Default (Multibranch)
git url: 'https://github.com/org/repo.git', branch: 'main', credentialsId: 'github-pat'
```

- **Webhook URL**: `JENKINS_URL/github-webhook/` (GitHub), `/project/JOB_NAME` (GitLab)
- **Webhook > Poll SCM**: Instant, efficient vs delayed, wasteful

| | Webhook | Poll SCM |
|-|---------|----------|
| **Trigger** | Push-based (instant) | Pull-based (delayed) |
| **Efficiency** | ✅ One call per event | ❌ Constant polling |
| **Setup** | Git platform config needed | Jenkins-only config |

- **Multibranch Pipeline**: Auto-discovers branches with Jenkinsfile, creates pipeline per branch, supports PRs
- **`BRANCH_NAME`**: Built-in env var for current branch in Multibranch

---

## 8. Docker & Kubernetes Integration

### Docker Build/Push
```groovy
sh 'docker build -t myapp:${BUILD_NUMBER} .'
withCredentials([usernamePassword(credentialsId: 'reg', usernameVariable: 'U', passwordVariable: 'P')]) {
    sh 'echo $P | docker login registry.example.com -u $U --password-stdin'
    sh 'docker push myapp:${BUILD_NUMBER}'
}
```

### DinD vs Socket Mount
- **Socket mount** (`-v /var/run/docker.sock:...`) → shares host Docker, fast, ✅ most CI/CD
- **DinD** (`docker:dind`) → isolated daemon, needs `--privileged`, slower

### K8s Pod Template — see Section 3 above

### Helm Deployment
```groovy
sh """
    helm upgrade --install myapp ./helm/myapp \\
        --namespace prod \\
        --set image.tag=${BUILD_NUMBER} \\
        --values helm/myapp/values-prod.yaml \\
        --wait --atomic
"""
```
`--atomic` = auto-rollback on failure

---

## 9. DevSecOps Quick Reference

### Pipeline Flow
```
Checkout → Build → SAST → SCA → Test → Docker Build → Image Scan → IaC Scan → Push → DAST → Deploy
```

### Tools Table

| Scan Type | Tool | What It Scans |
|-----------|------|--------------|
| **SAST** | SonarQube, Checkmarx | Source code |
| **SCA** | OWASP Dep-Check, Snyk | Dependencies |
| **Image Scan** | Trivy, Grype | Docker images |
| **IaC Scan** | Checkov, tfsec | Terraform/K8s manifests |
| **DAST** | OWASP ZAP | Running application |

### SonarQube Stage
```groovy
withSonarQubeEnv('SonarQube') { sh 'mvn sonar:sonar' }
timeout(time: 5, unit: 'MINUTES') { waitForQualityGate abortPipeline: true }
```

### Trivy Scan
```groovy
sh 'trivy image --exit-code 1 --severity HIGH,CRITICAL myapp:latest'
```

### Quality Gate Pattern
- **CRITICAL** → Hard fail (`--exit-code 1`)
- **HIGH** → Soft fail (`catchError → UNSTABLE`)
- **MEDIUM/LOW** → Report only

---

## 10. Production & Security

- **Auth**: LDAP / SAML (SSO) / OAuth — centralised user management
- **RBAC**: Role Strategy plugin → global + project + agent roles → least privilege
- **Backup**: JENKINS_HOME (config, credentials, secrets, jobs, plugins) → ThinBackup daily → test restores
- **Scaling**: Docker/K8s agents → auto-scale → parallel stages → dependency caching
- **Pipeline optimisation**: parallel, shallow clone (`depth: 1`), cache `.m2`/`node_modules`, `cleanWs()`

### Production Checklist
- [ ] HTTPS (reverse proxy)
- [ ] LDAP/SAML auth
- [ ] RBAC with Role Strategy
- [ ] Controller executors = 0
- [ ] Agent-to-controller security
- [ ] CSRF enabled
- [ ] Daily backups tested
- [ ] Build log rotation
- [ ] `cleanWs()` in all pipelines
- [ ] Pinned plugin versions

---

## 11. Troubleshooting Commands & Concepts

| Issue | Check | Fix |
|-------|-------|-----|
| Build stuck | Console output + thread dump | Abort + add `timeout` |
| Agent offline | Agent page + SSH test | Restart + check keys/ports |
| Git auth fail | Credential ID + scope | Fix cred + test manually |
| Docker permission | Docker group membership | `usermod -aG docker jenkins` |
| K8s deploy fail | `kubectl describe pod` | Fix RBAC/image/resources |
| Webhook not firing | GitHub delivery log | Fix URL + firewall + CSRF |
| Slow pipeline | Stage View timings | Parallel + cache + shallow clone |
| OOM | JVM `-Xmx` setting | Increase heap + limit concurrency |
| Plugin broke things | Jenkins log + changelog | Rollback `.jpi` from backup |
| Disk full | `df -h` | `docker prune` + log rotation + `cleanWs()` |

### Useful Groovy (Script Console)
```groovy
// List running builds
Jenkins.instance.getAllItems(Job).each { j -> j.builds.findAll { it.isBuilding() }.each { println "${j.name} #${it.number}" } }

// List offline agents
Jenkins.instance.computers.findAll { it.offline }.each { println "${it.name}: ${it.offlineCauseReason}" }

// Kill stuck build
Jenkins.instance.getItemByFullName('job-name').builds.find { it.isBuilding() }?.doStop()
```

### Key Debug URLs
- System Log: `JENKINS_URL/log/all`
- Thread Dump: `JENKINS_URL/threadDump`
- Script Console: `JENKINS_URL/script`
- System Info: `JENKINS_URL/systemInfo`

---

## 12. Key Comparisons Table

| Comparison | Option A | Option B |
|-----------|----------|----------|
| **Freestyle vs Pipeline** | GUI, simple, no Git | Code, complex, ✅ production |
| **Declarative vs Scripted** | Structured, validated, ✅ 90% | Full Groovy, flexible |
| **Poll SCM vs Webhook** | Pull, delayed, fallback | Push, instant, ✅ preferred |
| **Static vs Dynamic agents** | Always-on, drift | Ephemeral, clean, ✅ preferred |
| **DinD vs Socket mount** | Isolated, `--privileged` | Shared, fast, ✅ most CI/CD |
| **stash vs archiveArtifacts** | Temp, inter-stage | Permanent, downloadable |
| **Jenkins vs GitLab CI** | 2000+ plugins, complex | Built-in, simpler |
| **Jenkins vs GitHub Actions** | Self-hosted, mature | SaaS, YAML, newer |
| **`when` vs `input`** | Auto conditional | Manual approval |

---

## 13. Top 20 Interview Questions — 1-Line Answers

| # | Question | Answer |
|---|----------|--------|
| 1 | What is Jenkins? | Open-source CI/CD automation server with 2000+ plugins. |
| 2 | Jenkins architecture? | Controller (orchestrates) + Agents (execute builds) via SSH/JNLP. |
| 3 | Controller vs Agent? | Controller manages; Agent runs builds. Controller executors = 0 in prod. |
| 4 | Freestyle vs Pipeline? | Pipeline is code-based, version-controlled, and production-standard. |
| 5 | Declarative vs Scripted? | Declarative is structured (`pipeline{}`); Scripted is full Groovy (`node{}`). |
| 6 | What is a Jenkinsfile? | Pipeline definition stored as code in the Git repo. |
| 7 | How webhooks work? | Git sends HTTP POST to Jenkins on push → triggers build instantly. |
| 8 | How to manage credentials? | `withCredentials` block; values auto-masked in logs. |
| 9 | What is Multibranch? | Auto-discovers branches with Jenkinsfile, creates pipeline per branch. |
| 10 | How agents work? | Controller dispatches to agents by label; agents run builds and report back. |
| 11 | Jenkins + Docker? | `agent { docker {} }` for container builds; mount socket for docker commands. |
| 12 | Jenkins + Kubernetes? | K8s plugin → pod-per-build agents, auto-scaling, clean environments. |
| 13 | How to secure Jenkins? | HTTPS + LDAP/SAML + RBAC + 0 controller executors + audit trail. |
| 14 | How to prevent secret leaks? | `withCredentials` (auto-mask) + `set +x` + never echo + external vault. |
| 15 | How to scale Jenkins? | K8s/Docker agents + parallel stages + caching + shallow clones. |
| 16 | How to backup Jenkins? | JENKINS_HOME (minus workspace) → ThinBackup daily → test restores. |
| 17 | DevSecOps in Jenkins? | SAST → SCA → Image Scan → IaC Scan → DAST as pipeline stages. |
| 18 | Pipeline stuck — fix? | Check console + thread dump; abort + add `timeout`. |
| 19 | Failed deploy — rollback? | `kubectl rollout undo` or `helm rollback`; use `--atomic`. |
| 20 | Shared Library? | Reusable Groovy in Git (`@Library`); standardise pipelines across teams. |

---

## 14. Key Points to Remember

### What Interviewers Look For

- ✅ You understand **Pipeline-as-Code**, not just Freestyle jobs
- ✅ You can write a **Jenkinsfile from scratch**
- ✅ You know **Declarative vs Scripted** differences
- ✅ You integrate **security scanning** (SonarQube, Trivy) in pipelines
- ✅ You can explain the **full CI/CD flow** end-to-end
- ✅ You understand **Docker and Kubernetes** agent integration
- ✅ You have a **systematic troubleshooting** approach
- ✅ You know **production concerns**: security, RBAC, backups, scaling
- ✅ You mention **Shared Libraries** for standardisation
- ✅ You use `withCredentials` and know how masking works

### Common Mistakes Candidates Make

- ❌ Only knowing Freestyle jobs (outdated)
- ❌ Can't write pipeline syntax without UI
- ❌ No mention of security scanning
- ❌ Not knowing `when`, `input`, `post` directives
- ❌ Ignoring credential security (hardcoding secrets)
- ❌ No troubleshooting methodology (just "restart Jenkins")
- ❌ Not mentioning K8s agents for scaling
- ❌ Confusing `stash` with `archiveArtifacts`

### What Shows Senior-Level Knowledge

- 🔥 Mentioning Shared Libraries for pipeline standardisation
- 🔥 Explaining quality gate strategies (hard fail vs soft fail)
- 🔥 Discussing Helm `--atomic` for production safety
- 🔥 Knowing pipeline durability settings
- 🔥 Systematic troubleshooting: Problem → Investigate → Fix → Prevent
- 🔥 Discussing RBAC with folder-scoped credentials
- 🔥 Mentioning external secret managers (Vault) over Jenkins credentials
- 🔥 Knowing `catchError(buildResult: 'UNSTABLE')` pattern

---

> **Good luck with your interview!** 🚀
