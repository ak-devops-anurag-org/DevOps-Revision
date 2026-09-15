# Jenkins Interview Questions

> **50+ questions** from Basic → Intermediate → Advanced → Scenario-Based → Quick-Fire Comparisons. Each answer is concise and interview-ready.

---

## 1. Basic Questions

### Q1. What is Jenkins?

Jenkins is an **open-source automation server** written in Java that automates CI/CD pipelines — building, testing, and deploying software. It has 2000+ plugins and supports Pipeline-as-Code via Jenkinsfile.

### Q2. What is CI/CD?

- **CI (Continuous Integration)**: Developers merge code frequently; each merge triggers automated build + test.
- **CD (Continuous Delivery)**: CI + automated deployment to staging; manual approval for production.
- **CD (Continuous Deployment)**: Fully automated deployment to production — no manual gate.

### Q3. Explain Jenkins architecture.

Jenkins follows a **Controller-Agent** (master-slave) architecture:
- **Controller**: Manages UI, scheduling, config, credentials, and plugin management. Does NOT run builds in production.
- **Agents**: Execute build workloads. Connected via SSH, JNLP/TCP, or WebSocket.
- Controller distributes jobs to agents based on **labels** and **executor availability**.

### Q4. What is the difference between Controller and Agent?

| Controller | Agent |
|-----------|-------|
| Orchestrates and schedules | Executes builds |
| Stores configuration and credentials | Stateless (ideally) |
| Single instance | Scales horizontally |
| Should NOT run builds | Runs all builds |
| Holds admin access | Limited, sandboxed access |

### Q5. What is a Jenkins Job?

A job (or project) is a **runnable task** — it defines what to build, test, or deploy. Types: Freestyle, Pipeline, Multibranch Pipeline, Multi-configuration, Organization Folder.

### Q6. What is a Build Executor?

An executor is a **computational slot** on a node (controller or agent) that runs one build at a time. An agent with 4 executors can run 4 concurrent builds.

### Q7. What is a Workspace?

The **workspace** is a directory on the agent where Jenkins checks out source code and runs build steps. Each job gets its own workspace. It can be cleaned with `cleanWs()`.

### Q8. What is the Jenkins Home Directory?

`JENKINS_HOME` (default `/var/jenkins_home` or `/var/lib/jenkins`) stores all Jenkins state — job configs, plugins, credentials, secrets, build history. It must be **backed up**.

### Q9. How do you install Jenkins?

Three common methods:
- **Package manager**: `apt install jenkins` (Linux)
- **Docker**: `docker run -p 8080:8080 jenkins/jenkins:lts-jdk17`
- **WAR file**: `java -jar jenkins.war --httpPort=8080`

Initial password: `cat /var/jenkins_home/secrets/initialAdminPassword`

### Q10. What are Jenkins Plugins? Name important ones.

Plugins extend Jenkins functionality. Key plugins:
- **Pipeline** — Pipeline-as-Code
- **Git** — SCM integration
- **Docker Pipeline** — Docker in pipelines
- **Kubernetes** — Dynamic K8s agents
- **Credentials Binding** — Inject secrets
- **Role Strategy** — RBAC
- **Blue Ocean** — Modern UI
- **SonarQube Scanner** — Code quality

### Q11. What is the difference between Freestyle and Pipeline?

| Freestyle | Pipeline |
|-----------|---------|
| GUI-configured | Code-based (Jenkinsfile) |
| Not version-controlled | Stored in Git |
| Simple, linear | Complex, multi-stage, parallel |
| No code review | PR-reviewable |
| **For**: Quick POCs | **For**: All production workloads |

### Q12. What is Blue Ocean?

Blue Ocean is a **modern Jenkins UI** that provides a visual pipeline editor, per-stage log viewing, and a more intuitive experience for creating and monitoring pipelines.

---

## 2. Intermediate Questions

### Q13. What is a Jenkinsfile?

A Jenkinsfile is a **text file** that defines the pipeline as code. It's stored in the project's Git repository, version-controlled, and reviewed via PRs. It uses Groovy-based DSL.

### Q14. Declarative vs Scripted Pipeline?

| Declarative | Scripted |
|------------|---------|
| `pipeline { }` wrapper | `node { }` wrapper |
| Structured, opinionated | Full Groovy flexibility |
| Pre-validated before execution | Runtime errors only |
| `post { }` for error handling | `try-catch-finally` |
| Can restart from failed stage | Cannot restart from stage |
| **Use for**: 90% of cases | **Use for**: Complex/dynamic logic |

### Q15. What are Stages, Steps, and Agents?

- **Stage**: Logical grouping (Build, Test, Deploy) — visible in UI
- **Step**: Individual task within a stage (`sh`, `git`, `docker.build`)
- **Agent**: Where the pipeline or stage runs (`any`, `label`, `docker`, `kubernetes`)

### Q16. How do you manage credentials in Jenkins?

- Store in Jenkins Credential Store (Manage Jenkins → Credentials)
- Types: Username/Password, Secret Text, SSH Key, Secret File, Certificate
- Use `withCredentials` block or `credentials()` helper in `environment`
- Values are **automatically masked** in console output
- Use **folder-scope** credentials for team isolation

### Q17. What is a Multibranch Pipeline?

Multibranch Pipeline **auto-discovers** branches and PRs in a Git repo, creates a pipeline for each branch containing a Jenkinsfile. Branches without a Jenkinsfile are ignored. Ideal for branch-based CI/CD.

### Q18. How does a webhook trigger a Jenkins build?

1. Configure webhook in GitHub/GitLab with Jenkins URL: `JENKINS_URL/github-webhook/`
2. On push/PR, Git platform sends HTTP POST to Jenkins
3. Jenkins matches the payload to a job and triggers the build
4. Instant — no polling delay

### Q19. What is Poll SCM? How does it differ from webhooks?

Poll SCM makes Jenkins **periodically check** Git for changes (e.g., every 5 minutes). Unlike webhooks (push-based, instant), polling is **pull-based, delayed, and wastes resources**. Use webhooks whenever possible; Poll SCM as fallback.

### Q20. How do you use parameters in a pipeline?

```groovy
parameters {
    string(name: 'BRANCH', defaultValue: 'main')
    choice(name: 'ENV', choices: ['dev', 'staging', 'prod'])
    booleanParam(name: 'SKIP_TESTS', defaultValue: false)
}
// Access: params.BRANCH, params.ENV, params.SKIP_TESTS
```

### Q21. What are `post` actions?

`post` blocks run **after stages or pipeline complete**, based on build result:
- `always` — runs regardless
- `success` — only on success
- `failure` — only on failure
- `unstable` — test failures
- `cleanup` — runs last, after all other post conditions

### Q22. What is the `when` directive?

`when` enables **conditional execution** of a stage:
```groovy
when { branch 'main' }                    // Branch match
when { expression { params.ENV == 'prod' } }  // Expression
when { changeRequest() }                   // PR only
when { changeset 'src/**' }               // File changes
```

### Q23. How do you run parallel stages?

```groovy
stage('Tests') {
    parallel {
        stage('Unit') { steps { sh 'mvn test' } }
        stage('Integration') { steps { sh 'mvn verify' } }
    }
}
```
Use `failFast true` to abort all if one fails.

### Q24. How do you handle artifacts?

- **Archive**: `archiveArtifacts artifacts: 'target/*.jar'` — persist in Jenkins
- **Stash/Unstash**: Pass files between stages across agents
- **Publish tests**: `junit 'target/surefire-reports/*.xml'`

---

## 3. Advanced Questions

### Q25. How do you integrate Jenkins with Docker?

- Use `agent { docker { image 'maven:3.9' } }` to run builds in containers
- Mount Docker socket for building images: `-v /var/run/docker.sock:/var/run/docker.sock`
- Build/push images: `docker build -t myapp:latest . && docker push myapp:latest`
- Use `withCredentials` for registry authentication

### Q26. How do you run Jenkins agents on Kubernetes?

Install the **Kubernetes plugin**, configure cloud in Jenkins settings, and define pod templates:
```groovy
agent {
    kubernetes {
        yaml '''..pod spec...'''
        defaultContainer 'maven'
    }
}
```
Pods are **created per build** and destroyed after — auto-scaling, clean, cost-efficient.

### Q27. How do you integrate security scanning?

- **SonarQube**: `withSonarQubeEnv` + `waitForQualityGate abortPipeline: true`
- **Trivy**: `trivy image --exit-code 1 --severity HIGH,CRITICAL myimage`
- **OWASP Dependency-Check**: Scan dependencies for known CVEs
- Use `catchError(buildResult: 'UNSTABLE')` for soft fails on non-critical findings

### Q28. How do you prevent secrets from appearing in build logs?

1. Use `withCredentials` or `credentials()` — values auto-masked as `****`
2. Use `set +x` in shell steps to suppress command echoing
3. Never use `echo` or `println` with credentials
4. Don't pass secrets as build parameters (visible in history)
5. Use external secret managers (Vault) for sensitive environments

### Q29. What is a Jenkins Shared Library?

A **reusable Groovy library** stored in Git, loaded via `@Library('my-lib') _`. Contains:
- `vars/` — global pipeline functions (e.g., `buildApp.groovy`)
- `src/` — Groovy classes
- `resources/` — non-Groovy files

Benefits: Standardise pipelines across teams, enforce security stages, reduce duplication.

### Q30. How do you scale Jenkins?

1. **Add agents** — Docker/Kubernetes for auto-scaling
2. **Parallel stages** — run independent stages concurrently
3. **Cache dependencies** — Maven `.m2`, npm `node_modules`
4. **Shallow clone** — `depth: 1` for large repos
5. **Throttle builds** — limit concurrent builds on heavy jobs
6. **Multiple controllers** — for very large orgs (CloudBees)

### Q31. How do you implement RBAC?

Install **Role-based Authorization Strategy** plugin:
1. Define **Global roles** (admin, developer, viewer)
2. Define **Project roles** with patterns (e.g., `team-a-.*`)
3. Assign users/groups to roles
4. Principle of least privilege — developers get Build+Read, not Admin

### Q32. How do you back up and restore Jenkins?

**Back up**: JENKINS_HOME (config.xml, credentials.xml, secrets/, jobs/*/config.xml, plugins/)
- ThinBackup plugin (scheduled, automated)
- Scripted: `rsync` or `tar` JENKINS_HOME (exclude workspace/)
- Test restores quarterly

**Restore**: Stop Jenkins → restore JENKINS_HOME → start Jenkins.

### Q33. What is pipeline durability?

Controls how often pipeline state is persisted to disk:
- `MAX_SURVIVABILITY` — survives any crash (slowest)
- `SURVIVABLE_NONATOMIC` — default, good balance
- `PERFORMANCE_OPTIMIZED` — fastest, may lose state on crash

### Q34. How do you optimise pipeline performance?

- Parallel stages for independent work
- Cache dependencies (mount volumes)
- Shallow Git clone (`depth: 1`)
- `PERFORMANCE_OPTIMIZED` durability for non-critical pipelines
- `cleanWs()` to prevent disk issues
- `buildDiscarder` to limit build history

### Q35. How do you manage plugins in production?

- **Pin exact versions** in `plugins.txt`
- **Test updates in staging** before production
- **Minimise count** — each plugin is a security risk
- **Back up before updating**
- **Check compatibility** with Jenkins version

### Q36. What is the Jenkins Script Console?

`JENKINS_URL/script` — executes arbitrary **Groovy scripts** on the controller. Used for:
- Admin tasks (list builds, clean workspaces, manage credentials)
- Debugging (thread dumps, system info)
- **Security risk** — restrict access to admins only in production

---

## 4. Scenario-Based Questions

### Q37. Design a CI/CD pipeline for a microservices application.

**Approach**:
1. **Multibranch Pipeline** per microservice (each has its own Jenkinsfile)
2. **Shared Library** for common stages (build, test, scan, deploy)
3. Stages: Checkout → Build → Unit Test → SonarQube → Docker Build → Trivy Scan → Push → Deploy (Helm) → Smoke Test
4. Branch strategy: `feature/*` → test only; `develop` → deploy to dev; `main` → deploy to prod with approval
5. Kubernetes agents for clean, scalable builds
6. Notifications via Slack/Teams

### Q38. A build is stuck — how do you troubleshoot?

1. Check **console output** — where did it stop?
2. Check for **`input`** waiting for approval
3. Check **thread dump** (`JENKINS_URL/threadDump`)
4. Check agent **resources** (CPU, memory, disk)
5. **Abort** the build if necessary
6. **Fix**: Add `timeout` to pipeline and stages to prevent future stuck builds

### Q39. An agent is offline — what do you check?

1. Agent status page — read the **offline reason**
2. **Network**: SSH/JNLP connectivity from controller to agent
3. **Agent process**: Is it running? (`systemctl status jenkins-agent`)
4. **Java version**: Compatible JRE installed?
5. **Disk space**: `df -h` on agent
6. **Credentials**: SSH key still valid?

### Q40. Pipeline works locally but fails via webhook — what's wrong?

1. Check **webhook delivery logs** in GitHub (look for 4xx/5xx responses)
2. Is Jenkins **reachable** from the Git platform? (firewall, NAT)
3. Check **webhook URL** format (`/github-webhook/` for GitHub)
4. Check **CSRF/crumb** settings
5. Compare `BRANCH_NAME` — webhook may send different ref than manual

### Q41. Docker commands fail inside Jenkins — how do you fix it?

The Jenkins user is likely **not in the docker group**, or the Docker socket isn't mounted:
```bash
sudo usermod -aG docker jenkins   # Add to docker group
# Or mount socket in Docker agent:
args '-v /var/run/docker.sock:/var/run/docker.sock'
```

### Q42. How would you implement a DevSecOps pipeline?

```
Checkout → Build → SAST (SonarQube) → SCA (OWASP) → Unit Test → 
Docker Build → Image Scan (Trivy) → Push → Deploy to Staging → 
DAST (ZAP) → Approval → Deploy to Prod
```
- CRITICAL findings → hard fail (`--exit-code 1`)
- HIGH findings → soft fail (`catchError → UNSTABLE`)
- MEDIUM/LOW → report only

### Q43. How would you handle a failed production deployment?

1. **Immediate**: `kubectl rollout undo deployment/myapp` or `helm rollback myapp`
2. **Investigate**: Check pod logs, events, rollout history
3. **Prevention**: Use `helm upgrade --atomic` (auto-rollback), add smoke tests post-deploy, implement canary/blue-green

### Q44. Jenkins is running out of disk space — what do you do?

1. Clean **Docker**: `docker system prune -af`
2. Clean **workspaces**: `cleanWs()` in pipelines, or bulk clean via Script Console
3. Enable **build log rotation**: `buildDiscarder(logRotator(numToKeepStr: '10'))`
4. Clean old **build artifacts**
5. Monitor disk with **alerting** to prevent recurrence

### Q45. You need to migrate Jenkins to a new server — how?

1. **Back up** JENKINS_HOME completely (including `secrets/`)
2. Install Jenkins on new server (same version)
3. Stop both servers
4. **Copy** JENKINS_HOME to new server
5. Update URLs (Jenkins URL config, agent connections)
6. Start new server, verify all jobs and credentials
7. Update webhooks to point to new URL
8. Decommission old server

### Q46. How would you secure Jenkins in production?

- HTTPS via reverse proxy
- LDAP/SAML for authentication
- RBAC (Role Strategy plugin) with least privilege
- Controller executors set to **0**
- Agent-to-controller security enabled
- CSRF protection enabled
- Script Console restricted to admins
- Credentials in folder scope or external vault
- Audit trail plugin for logging
- Regular plugin updates and backups

### Q47. How do you handle secret rotation in Jenkins pipelines?

- Use **external secret managers** (Vault, AWS Secrets Manager) — secrets rotate independently
- For Jenkins credentials — update the credential value; all pipelines automatically use the new value (credential ID stays the same)
- Automate rotation with a Jenkins job that calls the secret manager's rotation API
- Test with staging before production rotation

### Q48. A team wants different pipeline behaviour per branch — how?

Use **Multibranch Pipeline** + `when` directives:
```groovy
when { branch 'main' }        // Production deployment
when { branch 'develop' }     // Dev deployment
when { changeRequest() }      // PR validation only
```
Each branch runs the **same Jenkinsfile** but conditional stages control what executes.

---

## 5. Quick-Fire / Comparison Questions

### Q49. Freestyle vs Pipeline

| Freestyle | Pipeline |
|-----------|---------|
| GUI-based | Code-based (Jenkinsfile) |
| No version control | Version-controlled in Git |
| Simple, linear | Complex, parallel, conditional |
| Not recommended for production | ✅ Production standard |

### Q50. Declarative vs Scripted Pipeline

| Declarative | Scripted |
|------------|---------|
| `pipeline { }` | `node { }` |
| Structured syntax | Full Groovy |
| Pre-validated | Runtime errors |
| `post { }` error handling | `try-catch` |
| ✅ Recommended | For complex logic |

### Q51. Poll SCM vs Webhook

| Poll SCM | Webhook |
|----------|---------|
| Jenkins pulls (periodic check) | Git pushes (instant notification) |
| Delayed | Real-time |
| Wastes API calls | Efficient |
| Works behind firewalls | Needs Jenkins reachable from Git |
| Fallback only | ✅ Preferred |

### Q52. Docker Socket Mount vs DinD

| Socket Mount | Docker-in-Docker |
|-------------|-----------------|
| Mounts `/var/run/docker.sock` | Runs separate Docker daemon |
| Shares host Docker | Fully isolated |
| Fast, uses host cache | Slower, cold cache |
| ⚠️ Less isolated | ⚠️ Needs `--privileged` |
| ✅ Most CI/CD setups | Strict isolation needs |

### Q53. `stash/unstash` vs `archiveArtifacts`

| stash/unstash | archiveArtifacts |
|--------------|-----------------|
| Pass files between stages/agents | Persist files in Jenkins |
| Temporary (within build) | Permanent (across builds) |
| Not visible in UI | Downloadable from build page |
| Use for: inter-stage file transfer | Use for: build outputs, reports |

### Q54. Jenkins vs GitLab CI vs GitHub Actions

| Feature | Jenkins | GitLab CI | GitHub Actions |
|---------|---------|-----------|----------------|
| Self-hosted | ✅ Full control | ✅ | Runners only |
| SaaS option | CloudBees | ✅ GitLab.com | ✅ GitHub.com |
| Config language | Groovy (Jenkinsfile) | YAML | YAML |
| Plugin ecosystem | 2000+ (largest) | Built-in features | Marketplace |
| Learning curve | Steeper | Moderate | Easiest |
| Enterprise maturity | Very high | High | Growing |
| Best for | Complex, legacy, enterprise | GitLab-native teams | GitHub-native teams |

### Q55. Static vs Dynamic Agents

| Static | Dynamic |
|--------|---------|
| Always running VMs | Created per build (Docker/K8s) |
| Accumulate state (drift) | Clean every time |
| Constant cost | Scale to zero |
| Manual maintenance | Image updates only |
| Legacy workloads | ✅ Modern CI/CD |

### Q56. `when` vs `input`

| `when` | `input` |
|--------|---------|
| **Automated** conditional check | **Manual** human approval |
| Based on branch, expression, etc. | Pauses for user interaction |
| No delay | Blocks until approved |
| Use for: branch-based logic | Use for: production deploy gates |

---

## Pro Tips for the Interview

1. **Always mention Pipeline-as-Code** — show you understand modern Jenkins, not legacy Freestyle
2. **Tie answers to production** — security, scalability, monitoring, backups
3. **Show debugging skills** — don't just say "it broke"; explain your systematic investigation approach
4. **Know the CI/CD flow** — be able to draw and explain: Git Push → Webhook → Build → Test → Scan → Deploy
5. **Mention DevSecOps** — security scanning in pipelines is increasingly expected
6. **Kubernetes agents** — shows you understand modern, scalable Jenkins architecture
