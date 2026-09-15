# Production Jenkins Best Practices

> **Interview Takeaways**: Know Jenkins security (RBAC, LDAP, HTTPS), backup strategy, scaling with K8s agents, pipeline optimisation, and the production readiness checklist.

---

## 1. Jenkins Security

### Authentication

| Method | Use Case | Setup |
|--------|----------|-------|
| **LDAP / Active Directory** | Enterprise SSO | LDAP plugin → configure server URL, base DN, bind credentials |
| **SAML / SSO** | Okta, Azure AD, Google Workspace | SAML plugin → configure metadata URL, entity ID |
| **OAuth** | GitHub/Google login | OAuth plugin → client ID/secret |
| **Jenkins internal database** | Small teams, dev/test | Default — manage users in Jenkins UI |

**Best practice**: Use **LDAP/SAML** in production — centralised user management and deprovisioning.

### Authorization

| Strategy | Description | When to Use |
|----------|-------------|-------------|
| **Matrix-based** | Global permissions per user/group | Small teams |
| **Project-based Matrix** | Per-project permissions | Medium teams |
| **Role-Based (Role Strategy plugin)** | Global, project, and agent roles | ✅ **Enterprise recommended** |
| **Folder-based** | Permissions scoped to folders | Multi-team isolation |

### CSRF Protection

- Enabled by default — **never disable** in production
- Issues a **crumb** token for all form submissions
- API calls need crumb or API token authentication

### Agent-to-Controller Security

- Enable **Agent → Controller Access Control** (Manage Jenkins → Security)
- Agents should NOT be able to:
  - Access controller file system
  - Execute commands on controller
  - Read credentials directly

### Securing the Jenkins UI

```nginx
# Reverse proxy with HTTPS (Nginx example)
server {
    listen 443 ssl;
    server_name jenkins.example.com;
    
    ssl_certificate     /etc/ssl/certs/jenkins.crt;
    ssl_certificate_key /etc/ssl/private/jenkins.key;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

### Disable Script Console in Production

The Groovy Script Console (`/script`) can execute **arbitrary code** on the controller.

- Restrict access to admins only
- Consider disabling entirely via RBAC
- Monitor for unauthorized access in audit logs

---

## 2. RBAC — Role-Based Access Control ⭐

### Role Strategy Plugin Setup

#### Global Roles

| Role | Permissions |
|------|------------|
| `admin` | Full access |
| `developer` | Read, build, cancel builds |
| `viewer` | Read only |

#### Project Roles (Pattern-based)

| Role | Pattern | Permissions |
|------|---------|------------|
| `team-a-dev` | `team-a-.*` | Build, read, configure |
| `team-b-dev` | `team-b-.*` | Build, read, configure |
| `deploy-prod` | `.*-prod-deploy` | Build (deploy jobs only) |

#### Agent Roles

| Role | Pattern | Permissions |
|------|---------|------------|
| `agent-manager` | `*` | Connect, disconnect, configure agents |

### Configuration

1. Install **Role-based Authorization Strategy** plugin
2. Manage Jenkins → Security → Authorization → Role-Based Strategy
3. Define roles in Manage Jenkins → Manage and Assign Roles

### Principle of Least Privilege

- Developers: **Build + Read** only on their projects
- Leads: **Build + Read + Configure** on team projects
- DevOps: **Admin** on CI/CD jobs, **Read** on others
- Auditors: **Read** only, globally

---

## 3. Credentials & Secrets in Production

### Credential Scopes

| Scope | Visibility | Best Practice |
|-------|-----------|---------------|
| **Global** | All jobs | Shared resources (Docker registry, Git) |
| **System** | Jenkins internals only | Agent connections, email config |
| **Folder** | Jobs in that folder only | ✅ **Team-specific credentials** |

### Folder-Level Credential Isolation

```
Jenkins/
├── team-alpha/           ← Team Alpha's credentials here
│   ├── alpha-frontend/
│   └── alpha-backend/
├── team-beta/            ← Team Beta's credentials here
│   ├── beta-api/
│   └── beta-worker/
```

Each folder has its own credential store — Team Alpha cannot access Team Beta's secrets.

### External Secret Managers (Recommended)

| Tool | Benefit |
|------|---------|
| **HashiCorp Vault** | Dynamic secrets, automatic rotation, audit logging |
| **AWS Secrets Manager** | Native AWS integration, auto-rotation, IAM-based access |
| **Azure Key Vault** | Azure-native, RBAC, certificate management |

### Credential Rotation

- Set calendar reminders for rotation (90 days recommended)
- Use Vault's **dynamic secrets** — credentials auto-expire
- Automate rotation with scripts + Jenkins jobs
- Test rotation in staging before production

---

## 4. Agent Management at Scale

### Permanent vs Ephemeral Agents

| Aspect | Permanent | Ephemeral (Docker/K8s) |
|--------|-----------|----------------------|
| **State** | Accumulates | Clean every build |
| **Cost** | Always on | Scale to zero |
| **Maintenance** | Patching, updates | Image updates only |
| **Consistency** | Can drift | ✅ Guaranteed |
| **For** | Legacy, hardware-specific | ✅ All standard builds |

### Agent Labels Strategy

```
Labels:
  linux          → All Linux agents
  docker         → Agents with Docker installed
  java17         → Agents with JDK 17
  gpu            → GPU-enabled agents
  deploy-prod    → Authorized for production deployments
```

```groovy
// Match specific agent capabilities
agent { label 'linux && docker && java17' }
```

### Agent Security

- **Network isolation** — agents in separate VPC/subnet
- **Minimal permissions** — agents only access what they need
- **No SSH to controller** — agents don't have controller access
- **Ephemeral credentials** — use OIDC or short-lived tokens
- **Image scanning** — scan agent Docker images for CVEs

---

## 5. Distributed Builds & Scaling

### Horizontal Scaling (Add Agents)

```
Controller ──→ Agent 1 (2 executors)
           ──→ Agent 2 (4 executors)
           ──→ Agent 3 (2 executors)
           ──→ K8s Pods (auto-scale 0-50)
```

### Vertical Scaling (Controller Resources)

| Load | Recommended Controller Resources |
|------|--------------------------------|
| < 50 jobs | 2 CPU, 4 GB RAM |
| 50-200 jobs | 4 CPU, 8 GB RAM |
| 200-500 jobs | 8 CPU, 16 GB RAM |
| 500+ jobs | 16 CPU, 32 GB RAM + consider multiple controllers |

### Kubernetes-Based Auto-Scaling

- **Scale to zero** when idle — no cost
- **Scale up** when builds are queued
- Pod templates define resource limits
- Use **PodDisruptionBudgets** for stability

### Queue Management

- Monitor queue length — long queues indicate insufficient agents
- Use `Throttle Concurrent Builds` plugin to limit per-job concurrency
- Label-based routing prevents bottlenecks on specialised agents

---

## 6. Jenkins Controller High Availability

### Strategies

| Strategy | Complexity | Recovery Time |
|----------|-----------|---------------|
| **Regular backups + restore** | Low | Hours |
| **Shared storage (NFS/EFS) + standby** | Medium | Minutes |
| **Jenkins on K8s with PVC** | Medium | Auto-recovery (minutes) |
| **CloudBees HA** (commercial) | High | Seconds (active-active) |

### Jenkins on Kubernetes (Self-Healing)

```yaml
# Jenkins controller as a StatefulSet with PVC
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: jenkins
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: jenkins
        image: jenkins/jenkins:lts-jdk17
        resources:
          requests:
            cpu: '2'
            memory: 4Gi
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
  volumeClaimTemplates:
  - metadata:
      name: jenkins-home
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 50Gi
```

If the pod crashes, Kubernetes **restarts it** with the same persistent volume — all data preserved.

---

## 7. Backup & Restore ⭐

### What to Back Up

| Item | Location | Critical? |
|------|----------|-----------|
| `config.xml` | `JENKINS_HOME/` | ✅ Global config |
| `credentials.xml` | `JENKINS_HOME/` | ✅ All credentials |
| `secrets/` | `JENKINS_HOME/secrets/` | ✅ Encryption keys |
| `jobs/*/config.xml` | `JENKINS_HOME/jobs/` | ✅ Job configs |
| `nodes/` | `JENKINS_HOME/nodes/` | ✅ Agent configs |
| `users/` | `JENKINS_HOME/users/` | ✅ User data |
| `plugins/` | `JENKINS_HOME/plugins/` | ⚠️ Re-installable |
| `workspace/` | `JENKINS_HOME/workspace/` | ❌ Regenerated |
| `builds/` (logs) | `JENKINS_HOME/jobs/*/builds/` | ⚠️ Optional |

### Backup Methods

```bash
# Method 1: ThinBackup plugin (recommended)
# Install → Manage Jenkins → ThinBackup → Configure backup directory and schedule

# Method 2: Scripted backup
#!/bin/bash
BACKUP_DIR="/backups/jenkins/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR
rsync -a --exclude='workspace/' --exclude='builds/' \
    /var/jenkins_home/ $BACKUP_DIR/
# Upload to S3
aws s3 sync $BACKUP_DIR s3://jenkins-backups/$BACKUP_DIR/

# Method 3: K8s volume snapshot
kubectl get pvc jenkins-home -n jenkins
# Create VolumeSnapshot
```

### Backup Schedule

| Frequency | What |
|-----------|------|
| **Daily** | Full JENKINS_HOME (minus workspace) |
| **Before upgrades** | Full backup before any Jenkins or plugin upgrade |
| **Weekly** | Off-site backup (S3, Azure Blob) |

### Disaster Recovery Plan

1. **Document** the full Jenkins setup: plugins, config, agents, credentials
2. **Automate** backup + verification
3. **Test restore** regularly (quarterly at minimum)
4. **Infrastructure as Code** — Jenkins setup via Helm/Docker/Ansible
5. **Jenkinsfile in Git** — pipelines survive controller loss

---

## 8. Plugin Management in Production

### Best Practices

- **Pin exact versions** — `git:5.2.1` not `git:latest`
- **Test in staging** — update plugins in staging, run key pipelines, then promote
- **Minimise count** — every plugin is a potential security risk and compatibility issue
- **Review changelogs** — check for breaking changes before updating
- **Batch updates** — update related plugins together, test, then update others

### Docker-Based Plugin Management

```dockerfile
FROM jenkins/jenkins:lts-jdk17

# Install specific plugin versions
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
```

```text
# plugins.txt — pinned versions
pipeline-model-definition:2.2198.v1a_5a_c20d1c1f
git:5.2.1
docker-workflow:572.v950f58993843
kubernetes:4029.v5712230ccb_f8
credentials-binding:677.vdc9c38cb_15e0
role-strategy:689.v731678c3e0eb_
```

### Plugin Rollback

```bash
# Plugins are stored as .jpi files in JENKINS_HOME/plugins/
# To rollback:
1. Stop Jenkins
2. Replace the .jpi file with the older version (from backup)
3. Delete the corresponding .jpi.pinned file if it exists
4. Start Jenkins
```

---

## 9. Pipeline Optimisation

### Parallel Stages

```groovy
stage('Tests') {
    failFast true
    parallel {
        stage('Unit') { steps { sh 'mvn test' } }
        stage('Integration') { steps { sh 'mvn verify -Pintegration' } }
        stage('Lint') { steps { sh 'mvn checkstyle:check' } }
    }
}
```

### Dependency Caching

```groovy
// Maven cache
agent {
    docker {
        image 'maven:3.9'
        args '-v /tmp/maven-cache:/root/.m2'
    }
}

// npm cache
agent {
    docker {
        image 'node:20'
        args '-v /tmp/npm-cache:/root/.npm'
    }
}
```

### Lightweight Checkout

```groovy
options {
    skipDefaultCheckout()     // Don't clone entire repo
}
stages {
    stage('Checkout') {
        steps {
            checkout([$class: 'GitSCM',
                branches: [[name: '*/main']],
                extensions: [[$class: 'CloneOption', depth: 1, shallow: true]],
                userRemoteConfigs: [[url: 'https://github.com/org/repo.git']]
            ])
        }
    }
}
```

### Pipeline Durability

```groovy
// In Jenkinsfile — trade durability for speed
pipeline {
    options {
        durabilityHint('PERFORMANCE_OPTIMIZED')  // Faster, but may not survive crash
    }
}
```

| Setting | Behaviour |
|---------|----------|
| `MAX_SURVIVABILITY` | Full persistence — survives any restart (slowest) |
| `SURVIVABLE_NONATOMIC` | Default — good balance |
| `PERFORMANCE_OPTIMIZED` | Minimal I/O — fastest, may lose state on crash |

### Reducing Log Size

```groovy
// Truncate logs
options {
    buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '5'))
}

// Suppress verbose output
sh(script: 'noisy-command', returnStdout: true)  // Capture stdout instead of printing
```

---

## 10. Resource Management

### Workspace Cleanup

```groovy
// At the end of pipeline
post {
    always {
        cleanWs()   // Clean workspace after build
    }
}

// Delete workspace before build (nuclear option)
options {
    skipDefaultCheckout()
}
stage('Clean') {
    steps {
        deleteDir()
        checkout scm
    }
}
```

### Build Log Rotation

```groovy
options {
    buildDiscarder(logRotator(
        numToKeepStr: '20',          // Keep last 20 builds
        daysToKeepStr: '30',         // Keep builds from last 30 days
        artifactNumToKeepStr: '5'    // Keep artifacts from last 5 builds
    ))
}
```

### Disk Space Monitoring

```groovy
// Groovy script for Jenkins Script Console
import hudson.model.*

Jenkins.instance.nodes.each { node ->
    def computer = node.toComputer()
    if (computer != null) {
        def channel = computer.getChannel()
        if (channel != null) {
            def space = channel.call(new DiskSpaceCheck())
            println "${node.name}: ${space / 1024 / 1024 / 1024} GB free"
        }
    }
}
```

### Agent Resource Limits (Kubernetes)

```yaml
containers:
- name: build
  image: maven:3.9
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: '2'
      memory: 2Gi
```

---

## 11. Production Readiness Checklist

### Security

- [ ] HTTPS via reverse proxy (Nginx/HAProxy)
- [ ] LDAP/SAML authentication configured
- [ ] RBAC with Role Strategy plugin
- [ ] Controller executors set to 0
- [ ] Agent-to-Controller access control enabled
- [ ] CSRF protection enabled
- [ ] Script Console access restricted
- [ ] Credentials stored in folder scope or external vault
- [ ] Audit trail plugin enabled

### Reliability

- [ ] Automated daily backups (ThinBackup or scripted)
- [ ] Backup tested with restore drill
- [ ] Jenkins on K8s or with HA setup
- [ ] Monitoring: CPU, memory, disk, queue length, build times
- [ ] Alerting on failures and resource thresholds
- [ ] Disaster recovery runbook documented

### Operations

- [ ] Plugins pinned to specific versions
- [ ] Plugin updates tested in staging first
- [ ] Build log rotation configured
- [ ] Workspace cleanup in every pipeline (`cleanWs()`)
- [ ] Pipeline durability set appropriately
- [ ] Job naming convention enforced
- [ ] Shared libraries for standardised pipelines

### Scaling

- [ ] Ephemeral agents (Docker/Kubernetes)
- [ ] Agent auto-scaling configured
- [ ] Dependency caching (Maven, npm, Docker layers)
- [ ] Parallel stages where possible
- [ ] Shallow Git clones for large repos
- [ ] Concurrent build limits on heavy jobs

---

## Key Interview Questions from This Section

1. **How do you secure Jenkins in production?** → HTTPS + LDAP/SAML auth + RBAC + agent-to-controller security + zero controller executors + audit trail.
2. **How do you implement RBAC?** → Role Strategy plugin → define global/project/agent roles → assign users/groups → least privilege.
3. **How do you back up Jenkins?** → ThinBackup plugin or scripted rsync of JENKINS_HOME (minus workspace/builds) → daily + before upgrades → test restores.
4. **How do you scale Jenkins?** → Ephemeral Docker/K8s agents + auto-scaling + parallel stages + caching + shallow checkouts.
5. **What's your production checklist?** → HTTPS, RBAC, 0 controller executors, backups, monitoring, pinned plugins, cleanWs, shared libraries.
