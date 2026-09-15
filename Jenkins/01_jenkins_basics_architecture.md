# Jenkins Basics & Architecture

> **Interview Takeaways**: Know the controller-agent architecture, why builds shouldn't run on the controller, difference between Freestyle and Pipeline, and JENKINS_HOME structure.

---

## 1. What Is Jenkins and Why It Is Used

- **Open-source automation server** written in Java
- Automates **build, test, and deployment** workflows (CI/CD)
- **2000+ plugins** — integrates with virtually any tool (Git, Docker, K8s, AWS, etc.)
- **Platform-agnostic** — runs on Linux, Windows, macOS, Docker, Kubernetes

### Why Jenkins Over Other Tools?

| Factor | Jenkins | GitLab CI | GitHub Actions |
|--------|---------|-----------|----------------|
| Self-hosted | ✅ Full control | ✅ | ❌ (runners yes, platform no) |
| Plugin ecosystem | 2000+ | Limited | Marketplace (newer) |
| Maturity | 15+ years | ~10 years | ~5 years |
| Pipeline as Code | ✅ Jenkinsfile | ✅ `.gitlab-ci.yml` | ✅ YAML workflows |
| Enterprise adoption | Very high | Growing | Growing |
| Complexity | Higher (flexibility cost) | Medium | Lower |

---

## 2. Jenkins Architecture

```
┌─────────────────────────────────────────────┐
│              Jenkins Controller             │
│  ┌─────────┐ ┌──────────┐ ┌──────────────┐  │
│  │ Web UI  │ │ Scheduler│ │ Config/State │  │
│  └─────────┘ └──────────┘ └──────────────┘  │
│                    │                        │
│            Distributes builds               │
└──────────┬─────────┼─────────┬──────────────┘
           │         │         │
     ┌─────▼──┐ ┌────▼───┐ ┌─-─▼──────┐
     │ Agent 1│ │ Agent 2│ │ Agent 3  │
     │ Linux  │ │ Docker │ │ K8s Pod  │
     │ (SSH)  │ │(JNLP)  │ │(dynamic) │
     └────────┘ └────────┘ └──────────┘
```

### How It Works

1. **Controller** manages the UI, scheduling, configuration, and plugin management
2. **Agents** execute the actual build workloads
3. Controller dispatches jobs to agents based on **labels** and **availability**
4. Communication via **SSH**, **JNLP/TCP**, or **WebSocket**

---

## 3. Controller vs Agent

| Aspect | Controller (Master) | Agent (Slave) |
|--------|-------------------|---------------|
| **Role** | Orchestrates, schedules, manages UI | Executes builds |
| **State** | Stores config, job definitions, credentials | Stateless (ideally) |
| **Scaling** | Single instance (HA optional) | Scale horizontally |
| **Builds** | Should NOT run builds in production | Runs all builds |
| **Security** | Holds secrets, admin access | Limited access, sandboxed |

### ⚠️ Why NOT Run Builds on the Controller?

- **Security risk** — builds may access controller's secrets, config files
- **Stability risk** — a rogue build can crash the controller
- **Resource contention** — builds compete with controller's scheduling duties
- **Best practice** — Set controller executors to **0** in production

### Agent Types

| Type | Description | Use Case |
|------|-------------|----------|
| **Permanent/Static** | Always-on VMs, connected via SSH/JNLP | Stable, predictable workloads |
| **Docker agents** | Spin up container per build | Clean, reproducible environments |
| **Kubernetes agents** | Pod per build, auto-scaled | Cloud-native, elastic scaling |
| **Cloud agents** | EC2, Azure VM provisioned on demand | Burst capacity |

---

## 4. Core Terminology

| Term | Definition |
|------|-----------|
| **Job / Project** | A runnable task configured in Jenkins (build, test, deploy) |
| **Build** | A single execution of a job, identified by a build number |
| **Build Number** | Auto-incrementing integer identifying each build run |
| **Executor** | A slot on a node that can run one build at a time |
| **Workspace** | Directory on the agent where source code is checked out and builds run |
| **Node** | Any machine (controller or agent) that Jenkins can run builds on |
| **Queue** | Holding area for jobs waiting for an available executor |
| **Pipeline** | A suite of automated stages defined as code (Jenkinsfile) |
| **Stage** | A logical grouping of steps in a pipeline (Build, Test, Deploy) |
| **Step** | A single task within a stage (`sh`, `git`, `docker.build`) |

---

## 5. Freestyle vs Pipeline

| Feature | Freestyle Job | Pipeline |
|---------|--------------|----------|
| Configuration | GUI-based (click-and-configure) | Code-based (Jenkinsfile) |
| Version control | ❌ Not easily versioned | ✅ Stored in Git |
| Complexity | Simple, linear | Complex, multi-stage, parallel |
| Reusability | ❌ Copy-paste | ✅ Shared libraries, modules |
| Code review | ❌ No PR review | ✅ Jenkinsfile reviewed in PRs |
| Restart | From beginning only | From failed stage (declarative) |
| Visibility | Basic | Blue Ocean / stage view |
| Recommended | Quick one-off jobs, POCs | **All production workloads** |

### Why Pipelines Are Preferred in Production

1. **Pipeline as Code** — auditable, version-controlled, reviewable
2. **Reproducible** — same Jenkinsfile = same pipeline everywhere
3. **Complex workflows** — parallel stages, conditionals, approvals
4. **Disaster recovery** — Jenkinsfile in Git survives controller failure

---

## 6. Jenkins Installation & Configuration

### Installation Methods

```bash
# Method 1: Package manager (Ubuntu/Debian)
sudo apt update
sudo apt install fontconfig openjdk-17-jre
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update && sudo apt install jenkins

# Method 2: Docker (recommended for quick setup)
docker run -d \
  --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts-jdk17

# Method 3: WAR file
java -jar jenkins.war --httpPort=8080
```

### Initial Setup

1. Access `http://<server>:8080`
2. Retrieve initial admin password:
   ```bash
   cat /var/jenkins_home/secrets/initialAdminPassword
   ```
3. Install suggested plugins or select specific ones
4. Create admin user
5. Configure Jenkins URL

### Key Ports

| Port | Purpose |
|------|---------|
| `8080` | Web UI (HTTP) |
| `50000` | JNLP agent communication |
| `443` | HTTPS (via reverse proxy) |

---

## 7. Jenkins Home Directory (`JENKINS_HOME`)

Default: `/var/jenkins_home` (Docker) or `/var/lib/jenkins` (package install)

```
JENKINS_HOME/
├── config.xml              # Global Jenkins configuration
├── credentials.xml         # Encrypted credentials store
├── secrets/                # Encryption keys, initial admin password
│   ├── master.key
│   ├── hudson.util.Secret
│   └── initialAdminPassword
├── jobs/                   # Job configurations and build history
│   └── my-job/
│       ├── config.xml      # Job configuration
│       └── builds/         # Build logs and artifacts
├── plugins/                # Installed plugins (.jpi/.hpi files)
├── nodes/                  # Agent configurations
├── users/                  # User configurations
├── workspace/              # Build workspaces (can be cleaned)
├── logs/                   # Jenkins logs
└── updates/                # Plugin update metadata
```

### What to Back Up

| Must Back Up | Can Skip |
|-------------|----------|
| `config.xml` | `workspace/` (regenerated) |
| `credentials.xml` | `updates/` (re-downloaded) |
| `secrets/` | `war/` (re-installed) |
| `jobs/` (configs) | Build logs (optional) |
| `plugins/` | Cache directories |
| `nodes/` | |
| `users/` | |

---

## 8. Plugins & Plugin Management

### What Plugins Do

Plugins extend Jenkins functionality — from SCM integration to cloud provider support. Jenkins is intentionally minimal without plugins.

### Essential Plugins for DevOps

| Plugin | Purpose |
|--------|---------|
| **Pipeline** | Pipeline-as-Code support |
| **Git** | Git SCM integration |
| **GitHub / GitLab** | Webhook, PR integration |
| **Docker Pipeline** | Docker build/push in pipelines |
| **Kubernetes** | Dynamic K8s agents |
| **Credentials Binding** | Inject credentials into builds |
| **Blue Ocean** | Modern pipeline visualisation |
| **Role-based Authorization** | RBAC for Jenkins |
| **SSH Agent** | SSH credential forwarding |
| **Timestamper** | Timestamps in console output |
| **Build Discarder** | Automatic build log cleanup |
| **Pipeline Utility Steps** | File operations, JSON/YAML parsing |

### Plugin Management

```bash
# Via Jenkins CLI
java -jar jenkins-cli.jar -s http://localhost:8080/ install-plugin git docker-workflow

# Via plugins.txt (Docker-based Jenkins)
# Create plugins.txt:
pipeline-model-definition:latest
git:latest
docker-workflow:latest
kubernetes:latest
credentials-binding:latest

# In Dockerfile:
FROM jenkins/jenkins:lts-jdk17
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
```

### Plugin Best Practices

- **Pin versions** — don't use `latest` in production
- **Test updates in staging** before applying to production
- **Minimise plugin count** — each plugin is an attack surface
- **Monitor compatibility** — check Plugin Compatibility Matrix before upgrades
- **Back up before updating** — plugins can break existing pipelines
- **Use `jenkins-plugin-cli`** for reproducible Docker-based installs

---

## Key Interview Questions from This Section

1. **What is Jenkins?** → Open-source automation server for CI/CD with a plugin-based architecture.
2. **Explain the architecture** → Controller orchestrates; agents execute builds; communication via SSH/JNLP.
3. **Why not run builds on the controller?** → Security risk, stability risk, resource contention.
4. **Freestyle vs Pipeline?** → Freestyle is GUI-based and simple; Pipeline is code-based, version-controlled, and production-ready.
5. **What's in JENKINS_HOME?** → Jobs, plugins, credentials, secrets, node configs — the entire Jenkins state.
6. **How do you manage plugins?** → `plugins.txt` for Docker, pin versions, test in staging, minimise count.
