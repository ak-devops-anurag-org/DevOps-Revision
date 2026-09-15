# Troubleshooting & Real-World Scenarios

> **Interview Takeaways**: Demonstrate senior-level debugging skills. For each scenario, explain: Problem → Possible Causes → How to Investigate → Fix. This section separates mid-level from senior candidates.

---

## General Debugging Tools & Commands

Before diving into scenarios, know these core debugging techniques:

### Jenkins System Log

```
Jenkins UI → Manage Jenkins → System Log
URL: JENKINS_URL/log/all
```

### Thread Dump (Stuck Builds)

```
JENKINS_URL/threadDump
```

### Script Console (Groovy)

```
JENKINS_URL/script
```

Useful Groovy scripts:

```groovy
// List all running builds
Jenkins.instance.getAllItems(Job).each { job ->
    job.builds.each { build ->
        if (build.isBuilding()) {
            println "${job.fullName} #${build.number} - ${build.executor?.displayName}"
        }
    }
}

// Kill a stuck build
def job = Jenkins.instance.getItemByFullName('job-name')
job.builds.find { it.isBuilding() }?.doStop()

// List all credentials
com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
    com.cloudbees.plugins.credentials.common.StandardCredentials,
    Jenkins.instance, null, null
).each { println "${it.id} - ${it.description}" }

// Check disk space on all agents
Jenkins.instance.computers.each { c ->
    println "${c.name}: ${c.getMonitorData()}"
}

// List offline agents
Jenkins.instance.computers.findAll { it.offline }.each {
    println "${it.name}: ${it.offlineCauseReason}"
}
```

### Pipeline Replay

- Go to build page → **Replay** → modify and re-run Jenkinsfile without committing
- Useful for quick debugging iterations

### Blue Ocean

- Visual pipeline execution — see which stage failed and why
- Parallel stage visualisation
- Log output per stage

### Environment Variables

```groovy
// Print all env vars in a pipeline
steps {
    sh 'env | sort'
    // or
    sh 'printenv'
}
```

---

## Scenario 1: Jenkins Build Is Stuck / Hanging

**Problem**: A build has been running for hours and appears frozen.

**Possible Causes**:
- Waiting for user `input` that nobody approved
- Waiting for an agent/executor to become available
- Shell command hanging (infinite loop, waiting for network, interactive prompt)
- Deadlock in Groovy/shared library code
- Resource exhaustion on agent (CPU/memory)
- Docker command waiting for resource (port conflict, volume lock)

**How to Investigate**:
1. Check build console output — see where it stopped
2. Check `JENKINS_URL/threadDump` for stuck threads
3. Check if build is waiting for `input` (look for "Paused for Input" in UI)
4. Check executor status: `JENKINS_URL/computer/` — is the agent busy?
5. SSH to agent and check process: `ps aux | grep java`, `top`, `df -h`

**Fix**:
- If waiting for input → approve or abort
- If shell command is hanging → abort build, add `timeout` to the step
- If agent is overloaded → kill the process, add resource limits
- If deadlock → abort, fix the Groovy code
- **Prevention**: Always add `timeout` to pipeline and individual stages

```groovy
options { timeout(time: 30, unit: 'MINUTES') }
stage('Build') {
    options { timeout(time: 10, unit: 'MINUTES') }
    steps { sh 'mvn package' }
}
```

---

## Scenario 2: Agent Is Offline / Not Connecting

**Problem**: Agent shows as offline in Jenkins; builds queue indefinitely.

**Possible Causes**:
- Agent machine is down or unreachable
- SSH key changed / expired
- JNLP port (50000) blocked by firewall
- Java version mismatch (agent requires compatible JRE)
- Agent process crashed (OOM, disk full)
- Network/DNS change
- Agent certificate expired (HTTPS)

**How to Investigate**:
1. Check agent status page: `JENKINS_URL/computer/agent-name/`
2. Read the offline reason message
3. Try SSH from controller to agent: `ssh jenkins@agent-host`
4. Check agent logs: `JENKINS_URL/computer/agent-name/log`
5. On the agent: `systemctl status jenkins-agent`, `journalctl -u jenkins-agent`
6. Check network: `telnet controller-host 50000` (JNLP), `curl controller-host:8080` (HTTP)
7. Check disk space: `df -h` on agent

**Fix**:

| Cause | Fix |
|-------|-----|
| Machine down | Restart VM/container |
| SSH key issue | Regenerate and update in Jenkins credentials |
| JNLP port blocked | Open port 50000 in firewall/security group |
| Java version | Install compatible JRE on agent |
| Process crashed | Restart agent service, increase memory |
| Disk full | Clean workspace, old builds, Docker images |

---

## Scenario 3: Pipeline Cannot Access Git Repository

**Problem**: Pipeline fails at checkout with authentication or connectivity errors.

**Possible Causes**:
- Credentials misconfigured (wrong ID, expired token)
- SSH key not added to Git platform (GitHub, GitLab)
- HTTPS certificate issue (self-signed, expired)
- Firewall blocking Git platform
- Branch name incorrect
- Git not installed on agent

**How to Investigate**:
1. Read the error message carefully — "Permission denied", "Could not resolve host", "SSL certificate problem"
2. Test from agent: `git clone <url>` manually via SSH
3. Verify credential ID matches what's in the Jenkinsfile
4. Check credential scope (must be Global, not System)
5. Test SSH connectivity: `ssh -T git@github.com` from agent

**Fix**:

| Error | Fix |
|-------|-----|
| `Permission denied (publickey)` | Add SSH public key to GitHub; check credential ID in Jenkins |
| `Could not resolve host` | DNS issue — check `/etc/resolv.conf`, network connectivity |
| `SSL certificate problem` | Add CA cert to Java truststore; or use `git config http.sslVerify false` (NOT recommended) |
| `Repository not found` | Check URL, verify credential has repo access |
| `Branch not found` | Verify branch name, check `*/main` vs `*/master` |

---

## Scenario 4: Credentials Are Not Working

**Problem**: Pipeline uses `withCredentials` but gets authentication errors.

**Possible Causes**:
- Wrong credential ID
- Credential scope mismatch (System scope can't be used in pipelines)
- Credential expired or rotated externally
- Wrong credential type (using secret text ID for SSH key)
- Folder-scoped credential not accessible from another folder

**How to Investigate**:
1. Verify credential ID: Manage Jenkins → Credentials → search by ID
2. Check scope: must be **Global** or in the same **Folder** as the job
3. Test credential: create a simple test job that echoes masked value
4. Check for typos in `credentialsId` parameter

**Fix**:
- Correct the credential ID in Jenkinsfile
- Change scope from System to Global
- Update expired credentials
- Move folder-scoped credentials or use Global scope
- Use `credentials()` helper for simple cases

---

## Scenario 5: Docker Command Fails Inside Jenkins

**Problem**: `docker build` or `docker push` fails with "permission denied" or "command not found".

**Possible Causes**:
- Docker not installed on agent
- Jenkins user not in `docker` group
- Docker socket not mounted (Docker agent)
- Docker daemon not running
- Docker-in-Docker not configured correctly
- Docker socket permissions (`/var/run/docker.sock`)

**How to Investigate**:
1. Check if Docker is installed: `docker --version`
2. Check Docker daemon: `systemctl status docker`
3. Check permissions: `ls -la /var/run/docker.sock`
4. Check user groups: `groups jenkins`
5. Check Docker socket mount in agent config

**Fix**:

```bash
# Add Jenkins user to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# Or fix Docker socket permissions
sudo chmod 666 /var/run/docker.sock   # Quick fix (not for production)

# For Docker-based agents, mount the socket:
agent {
    docker {
        image 'docker:24'
        args '-v /var/run/docker.sock:/var/run/docker.sock'
    }
}
```

---

## Scenario 6: Kubernetes Deployment Fails from Jenkins

**Problem**: `kubectl apply` or `helm upgrade` fails during deployment stage.

**Possible Causes**:
- Kubeconfig not mounted or incorrect
- RBAC insufficient (ServiceAccount can't create resources)
- Image pull error (registry auth, image doesn't exist)
- Resource limits exceeded (quota, CPU, memory)
- Namespace doesn't exist
- Kubernetes API server unreachable

**How to Investigate**:
1. Read the error message: `forbidden`, `ImagePullBackOff`, `QuotaExceeded`
2. Test kubectl from agent: `kubectl cluster-info`
3. Check RBAC: `kubectl auth can-i create deployment -n production`
4. Check events: `kubectl get events -n production --sort-by=.lastTimestamp`
5. Check pod status: `kubectl describe pod <pod-name> -n production`

**Fix**:

| Error | Fix |
|-------|-----|
| `forbidden` | Update RBAC — add required verbs to ServiceAccount's Role |
| `ImagePullBackOff` | Check registry credentials, verify image tag exists |
| `QuotaExceeded` | Request quota increase or optimise resource requests |
| `connection refused` | Check kubeconfig, cluster URL, network connectivity |
| `namespace not found` | Create namespace: `kubectl create ns production` |

---

## Scenario 7: Jenkins Workspace Issues

**Problem**: Build fails with file permission errors, stale files, or "disk full".

**Possible Causes**:
- Disk full on agent
- Permission errors (different user ran previous build)
- Stale workspace from previous build (lock files, partial state)
- Long path names (Windows agents)
- Concurrent builds sharing workspace

**How to Investigate**:
1. Check disk space: `df -h` on agent
2. Check workspace permissions: `ls -la $WORKSPACE`
3. Check for lock files: `find $WORKSPACE -name "*.lock"`
4. Check concurrent build settings

**Fix**:
- **Disk full**: Clean old workspaces, Docker images, build logs
  ```bash
  # Clean Docker
  docker system prune -af
  # Clean old workspaces (Groovy script console)
  Jenkins.instance.nodes.each { node ->
      node.workspaceRoot?.deleteRecursive()
  }
  ```
- **Permission errors**: `chown -R jenkins:jenkins $WORKSPACE`
- **Stale files**: Add `cleanWs()` to pipeline `post { always { } }`
- **Concurrent builds**: Use `options { disableConcurrentBuilds() }`

---

## Scenario 8: Pipeline Works Manually But Fails via Webhook

**Problem**: Clicking "Build Now" works fine, but webhook-triggered builds fail.

**Possible Causes**:
- Webhook URL incorrect (typo, wrong endpoint)
- Jenkins not reachable from Git platform (firewall, NAT)
- CSRF crumb issue (webhook rejected)
- Webhook payload format mismatch
- Different branch/ref in webhook vs manual build
- Missing Jenkins authentication for webhook

**How to Investigate**:
1. Check webhook delivery logs in GitHub/GitLab (status codes)
2. Check Jenkins logs for incoming webhook requests
3. Test connectivity: `curl -X POST https://jenkins.example.com/github-webhook/` from outside
4. Check if CSRF is blocking: look for `403` responses
5. Compare `BRANCH_NAME` between manual and webhook runs

**Fix**:

| Issue | Fix |
|-------|-----|
| Jenkins not reachable | Open firewall, use public URL or tunnel (ngrok for testing) |
| 403 Forbidden | Configure crumb exclusion for webhook URL, or use API token |
| Wrong endpoint | GitHub: `/github-webhook/`, GitLab: `/project/JOB_NAME` |
| Payload mismatch | Check content type (`application/json`) |
| Branch mismatch | Ensure webhook sends correct branch ref |

---

## Scenario 9: Pipeline Is Very Slow

**Problem**: Builds that should take 5 minutes take 30+ minutes.

**Possible Causes**:
- Sequential stages that could be parallel
- No dependency caching (downloading everything each build)
- Full Git clone on large repos
- Heavy Docker image pulls every build
- Insufficient executors (builds waiting in queue)
- Agent resource constraints (slow CPU, low memory, slow disk)
- Unnecessary steps or scans

**How to Investigate**:
1. Check **Stage View** or **Blue Ocean** — which stages are slow?
2. Check queue time vs build time
3. Check agent performance: `top`, `iostat`, `free -m`
4. Check if Docker images are being pulled each time
5. Review pipeline for unnecessary steps

**Fix**:

```groovy
// 1. Parallel stages
stage('Tests') {
    parallel {
        stage('Unit') { steps { sh 'mvn test' } }
        stage('Lint') { steps { sh 'mvn checkstyle:check' } }
    }
}

// 2. Cache dependencies
agent {
    docker {
        image 'maven:3.9'
        args '-v /tmp/maven-cache:/root/.m2'   // Persist cache
    }
}

// 3. Shallow clone
checkout([$class: 'GitSCM',
    extensions: [[$class: 'CloneOption', depth: 1, shallow: true]]
])

// 4. Use Docker image cache (don't pull every time)
docker.image('maven:3.9').inside {
    sh 'mvn package'
}
```

---

## Scenario 10: Out-of-Memory (OOM) Issues

**Problem**: Jenkins controller or agent crashes with `OutOfMemoryError`.

**Possible Causes**:
- JVM heap too small for workload
- Too many concurrent builds
- Memory leak in plugins
- Large workspaces loaded into memory
- Build logs too large (console output)

**How to Investigate**:
1. Check Jenkins logs for `OutOfMemoryError`
2. Monitor JVM: `JENKINS_URL/monitoring` (Monitoring plugin)
3. Check heap usage: `JENKINS_URL/systemInfo`
4. Identify heavy plugins via Jenkins support bundle
5. Check concurrent build count

**Fix**:

```bash
# Increase JVM heap for controller
JAVA_OPTS="-Xms2g -Xmx4g -XX:+UseG1GC"
# In Docker: docker run -e JAVA_OPTS="-Xmx4g" jenkins/jenkins:lts

# For agents
JAVA_OPTS="-Xmx2g"
```

- Reduce concurrent builds with `disableConcurrentBuilds()` or throttle plugin
- Limit console log size with `options { buildDiscarder(logRotator(...)) }`
- Remove unused/heavy plugins
- Add more agents to distribute load

---

## Scenario 11: Plugin Compatibility Issues

**Problem**: After updating plugins, pipelines start failing with `NoSuchMethodError`, `ClassNotFoundException`, or unexpected behaviour.

**Possible Causes**:
- Plugin API changed (breaking change)
- Incompatible plugin versions (dependency conflict)
- Plugin requires newer Jenkins version
- Deprecated features removed

**How to Investigate**:
1. Check Jenkins → Manage Jenkins → Plugin Manager → Installed → look for warnings
2. Check Jenkins system log for `ClassNotFoundException` or `NoSuchMethodError`
3. Review plugin changelog for breaking changes
4. Check Plugin Compatibility Matrix

**Fix**:

```bash
# Rollback a plugin
1. Go to JENKINS_HOME/plugins/
2. Find the .jpi file for the problematic plugin
3. Replace with the older version from backup
4. Restart Jenkins

# Or via CLI
java -jar jenkins-cli.jar -s http://localhost:8080/ install-plugin git:5.2.0 -restart

# Prevention
- Always test plugin updates in staging
- Keep backups before updates
- Pin plugin versions in plugins.txt
```

---

## Scenario 12: Jenkins Cannot Connect to External Service

**Problem**: Pipeline can't reach APIs, registries, or services.

**Possible Causes**:
- DNS resolution failure
- Proxy configuration missing
- Firewall rules blocking outbound traffic
- SSL/TLS certificate not trusted
- Timeout too short
- Service is actually down

**How to Investigate**:
1. From agent: `nslookup service.example.com`, `curl -v https://service.example.com`
2. Check proxy settings: Manage Jenkins → Plugins → Advanced (proxy config)
3. Check Jenkins proxy env vars: `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`
4. Test SSL: `openssl s_client -connect service.example.com:443`
5. Check firewall: `telnet service.example.com 443`

**Fix**:

| Issue | Fix |
|-------|-----|
| DNS failure | Check `/etc/resolv.conf`, add DNS server |
| Proxy needed | Set `HTTP_PROXY`/`HTTPS_PROXY` in Jenkins and agent env |
| SSL cert untrusted | Add CA cert to Java truststore: `keytool -importcert` |
| Firewall blocking | Open egress rules for the service |
| Timeout | Increase connection timeout in pipeline step |

```bash
# Add CA cert to Java truststore
keytool -importcert -alias mycert -file /path/to/ca.crt \
    -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -noprompt
```

---

## Scenario 13: Failed Deployment and Rollback

**Problem**: Deployment to production failed; application is down or broken.

**Possible Causes**:
- New version has a bug (runtime error, crash loop)
- Configuration mismatch (wrong env vars, secrets)
- Resource limits too low (OOM kill)
- Health check failing (wrong endpoint, slow startup)
- Database migration failed

**How to Investigate**:
1. Check deployment status: `kubectl rollout status deployment/myapp`
2. Check pod events: `kubectl describe pod <pod> -n production`
3. Check pod logs: `kubectl logs <pod> -n production --previous`
4. Check rollout history: `kubectl rollout history deployment/myapp`

**Fix — Immediate Rollback**:

```bash
# Kubernetes rollback
kubectl rollout undo deployment/myapp -n production

# Helm rollback
helm rollback myapp 1 -n production    # Roll back to revision 1
```

### Implementing Rollback in Jenkinsfile

```groovy
stage('Deploy') {
    steps {
        sh """
            helm upgrade --install myapp ./helm/myapp \\
                --namespace production \\
                --set image.tag=${BUILD_NUMBER} \\
                --wait --timeout 300s \\
                --atomic    # Auto-rollback on failure
        """
    }
}

stage('Smoke Test') {
    steps {
        script {
            def response = sh(
                script: 'curl -sf https://myapp.example.com/health',
                returnStatus: true
            )
            if (response != 0) {
                echo 'Smoke test failed! Rolling back...'
                sh 'helm rollback myapp 0 -n production'
                error('Deployment failed smoke test — rolled back')
            }
        }
    }
}
```

---

## Scenario 14: Build Artifacts Missing or Not Published

**Problem**: Build completes but artifacts are not available in Jenkins.

**Possible Causes**:
- `archiveArtifacts` path pattern doesn't match any files
- Workspace cleaned before archiving
- Build ran on different agent than expected
- `stash`/`unstash` used incorrectly
- Agent disconnected during archive step

**How to Investigate**:
1. Check console output for `archiveArtifacts` step — any warnings?
2. Verify file path: `sh 'ls -la target/*.jar'` before archive step
3. Check if `cleanWs()` runs before `archiveArtifacts`

**Fix**:
```groovy
// Archive BEFORE cleanup
post {
    success {
        archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
    }
    always {
        cleanWs()   // Clean AFTER archiving
    }
}
```

---

## Scenario 15: Jenkins After Restart Loses Running Builds

**Problem**: After Jenkins restart, in-progress builds are lost or show as failed.

**Possible Causes**:
- Pipeline durability set to `PERFORMANCE_OPTIMIZED`
- Ungraceful shutdown (kill -9, crash)
- Non-durable steps in progress during restart

**How to Investigate**:
1. Check pipeline durability setting
2. Check Jenkins system log for resume errors after restart
3. Check if builds were using `@NonCPS` functions

**Fix**:
```groovy
// Use default or max durability for critical pipelines
pipeline {
    options {
        durabilityHint('MAX_SURVIVABILITY')
    }
}
```

- **Graceful shutdown**: `JENKINS_URL/safeRestart` (waits for builds to finish)
- **Avoid** `kill -9` — use `JENKINS_URL/safeRestart` or `kill -15`

---

## Troubleshooting Quick Reference

| Symptom | First Check | Quick Fix |
|---------|------------|-----------|
| Build stuck | Thread dump + console output | Abort + add timeout |
| Agent offline | Agent log + SSH connectivity | Restart agent + check keys |
| Git auth failure | Credential ID + scope | Fix credential + test manually |
| Docker permission denied | Docker group + socket | `usermod -aG docker jenkins` |
| K8s deploy fails | `kubectl describe pod` + events | Fix RBAC/image/resources |
| Webhook not triggering | GitHub delivery log + Jenkins log | Fix URL + firewall + CSRF |
| Pipeline slow | Stage View timing | Parallel + cache + shallow clone |
| OOM crash | JVM settings + concurrent builds | Increase `-Xmx` + limit concurrency |
| Plugin broke builds | Jenkins log + plugin changelog | Rollback .jpi from backup |
| Disk full | `df -h` on agent | `docker prune` + `cleanWs()` + log rotation |

---

## Key Interview Questions from This Section

1. **How do you troubleshoot a stuck build?** → Check console output, thread dump, look for `input` waits, check agent resources, abort and add `timeout`.
2. **Agent is offline — what do you check?** → Agent page for reason, SSH connectivity, JNLP port, Java version, disk space, agent logs.
3. **Docker commands fail in Jenkins — why?** → Jenkins user not in docker group, or socket not mounted. Fix: `usermod -aG docker jenkins`.
4. **How do you handle a failed production deploy?** → Immediate `kubectl rollout undo` or `helm rollback`; use `--atomic` in Helm for auto-rollback.
5. **Pipeline works manually but not via webhook?** → Check webhook delivery logs, Jenkins reachability, CSRF settings, webhook URL format.
