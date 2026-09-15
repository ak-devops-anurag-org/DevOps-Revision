# Agents, Nodes, Plugins & Credentials

> **Interview Takeaways**: Understand static vs dynamic agents, Docker/K8s agent setup, credential types and scopes, `withCredentials` usage, and secret handling best practices.

---

## 1. Jenkins Agents Overview

### What Are Agents?

Agents are **worker machines** that execute Jenkins builds. The controller delegates work to agents.

### Why Agents?

- **Isolation** — builds don't affect the controller
- **Scalability** — add agents to handle more concurrent builds
- **Diversity** — different OS/tools per agent (Linux, Windows, specific SDKs)
- **Security** — builds run in restricted environments

### Communication Protocols

| Protocol | How It Works | Direction | Use Case |
|----------|-------------|-----------|----------|
| **SSH** | Controller SSHes into agent | Controller → Agent | Linux agents, most common |
| **JNLP/TCP** | Agent connects to controller on port 50000 | Agent → Controller | Agents behind NAT/firewall |
| **WebSocket** | Agent connects via HTTP upgrade | Agent → Controller | Modern, firewall-friendly |

---

## 2. Static vs Dynamic Agents

| Feature | Static (Permanent) | Dynamic (Ephemeral) |
|---------|-------------------|-------------------|
| **Lifecycle** | Always running, always connected | Created per build, destroyed after |
| **Setup** | Manual VM/server provisioning | Automated (Docker, K8s, cloud) |
| **State** | Accumulates state (cache, artifacts) | Clean environment every time |
| **Cost** | Constant (running 24/7) | Pay per use |
| **Maintenance** | OS patches, tool updates needed | Image updates only |
| **Consistency** | Can drift over time | Identical every run |
| **Best for** | Legacy, specialised hardware | ✅ Modern CI/CD (recommended) |

---

## 3. SSH Agents

### How They Work

1. Controller stores SSH credentials (private key or username/password)
2. Controller SSHes into agent machine
3. Launches `remoting.jar` on the agent
4. Builds execute in agent's workspace

### Configuration Steps

1. **On the agent machine**:
   ```bash
   # Create Jenkins user
   sudo useradd -m -s /bin/bash jenkins
   # Install Java (required)
   sudo apt install openjdk-17-jre
   # Create workspace directory
   sudo mkdir -p /home/jenkins/workspace
   sudo chown jenkins:jenkins /home/jenkins/workspace
   ```

2. **On the controller**:
   - Manage Jenkins → Nodes → New Node
   - Set **Remote root directory**: `/home/jenkins`
   - Set **Launch method**: Launch agents via SSH
   - Add **Host** and **Credentials** (SSH key)
   - Set **Labels** (e.g., `linux`, `docker`, `build`)

### SSH Key Setup

```bash
# Generate key pair (on controller or locally)
ssh-keygen -t ed25519 -f jenkins_agent_key -C "jenkins-agent"

# Copy public key to agent
ssh-copy-id -i jenkins_agent_key.pub jenkins@agent-host

# Add private key as Jenkins credential (SSH Username with private key)
```

---

## 4. Docker Agents

### Running Builds Inside Docker Containers

Builds run in a fresh container — clean, reproducible, isolated.

```groovy
// Simple Docker agent
pipeline {
    agent {
        docker {
            image 'maven:3.9-eclipse-temurin-17'
            args '-v $HOME/.m2:/root/.m2'  // Mount cache
        }
    }
    stages {
        stage('Build') {
            steps { sh 'mvn clean package' }
        }
    }
}

// Per-stage Docker agent
pipeline {
    agent none
    stages {
        stage('Build') {
            agent { docker { image 'maven:3.9' } }
            steps { sh 'mvn package' }
        }
        stage('Test Frontend') {
            agent { docker { image 'node:20' } }
            steps { sh 'npm test' }
        }
    }
}
```

### Docker-in-Docker (DinD) vs Docker Socket Mount

| Aspect | Docker Socket Mount | Docker-in-Docker (DinD) |
|--------|-------------------|----------------------|
| **How** | Mount `/var/run/docker.sock` into container | Run separate Docker daemon inside container |
| **Setup** | `args '-v /var/run/docker.sock:/var/run/docker.sock'` | Use `docker:dind` image, privileged mode |
| **Isolation** | ❌ Shares host Docker daemon | ✅ Isolated Docker daemon |
| **Security** | ⚠️ Container can access host Docker | ⚠️ Requires `--privileged` flag |
| **Performance** | ✅ Better (no nested overhead) | ❌ Slower |
| **Recommended** | ✅ Most CI/CD setups | Use when isolation is critical |

```groovy
// Socket mount approach
agent {
    docker {
        image 'docker:24'
        args '-v /var/run/docker.sock:/var/run/docker.sock'
    }
}
```

---

## 5. Kubernetes Agents

### How It Works

1. Jenkins Kubernetes plugin manages agent pods
2. Each build gets a **fresh pod** with defined containers
3. Pod is destroyed after build completes
4. Auto-scales based on queue

### Pipeline Syntax

```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
            apiVersion: v1
            kind: Pod
            metadata:
              labels:
                jenkins: agent
            spec:
              containers:
              - name: maven
                image: maven:3.9-eclipse-temurin-17
                command: ['sleep', 'infinity']
                resources:
                  requests:
                    cpu: '500m'
                    memory: '512Mi'
                  limits:
                    cpu: '1'
                    memory: '1Gi'
              - name: docker
                image: docker:24
                command: ['sleep', 'infinity']
                volumeMounts:
                - name: docker-sock
                  mountPath: /var/run/docker.sock
              volumes:
              - name: docker-sock
                hostPath:
                  path: /var/run/docker.sock
            '''
            defaultContainer 'maven'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('Docker Build') {
            steps {
                container('docker') {
                    sh 'docker build -t myapp:latest .'
                }
            }
        }
    }
}
```

### Pod Template Configuration (UI)

- Manage Jenkins → Cloud → Kubernetes
- Configure Kubernetes URL, namespace, credentials
- Define Pod Templates with:
  - Labels (for agent matching)
  - Container templates (image, command, resources)
  - Volumes (secrets, configmaps, host paths)

### Benefits of K8s Agents

- **Auto-scaling** — pods scale with demand, scale to zero when idle
- **Resource efficiency** — no idle VMs
- **Isolation** — each build in its own pod
- **Consistency** — container images define the environment

---

## 6. Labels and Executors

### Labels

Labels are **tags** assigned to agents to classify their capabilities.

```groovy
// Match agents by label
agent { label 'linux' }
agent { label 'linux && docker' }       // Agent with BOTH labels
agent { label 'linux || windows' }      // Agent with EITHER label
agent { label 'deploy && production' }
```

**Best practices**:
- Use descriptive labels: `linux`, `docker`, `gpu`, `deploy-prod`
- Combine labels for specific requirements
- Don't over-label — keep it manageable

### Executors

- An **executor** is a slot on a node that can run one build
- **2 executors** on an agent = 2 concurrent builds
- Controller executors should be set to **0** in production

**Tuning**: Set executor count based on agent resources:
- CPU-bound builds: executors ≈ CPU cores
- I/O-bound builds: executors can exceed CPU cores
- Docker/K8s agents: typically 1 executor per container

---

## 7. Credentials Management ⭐

### Credential Types

| Type | Use Case | Example |
|------|----------|---------|
| **Username with password** | Docker registry, Git HTTPS, APIs | DockerHub login |
| **Secret text** | API tokens, passwords | Slack token, SonarQube key |
| **SSH Username with private key** | Git SSH, server access | GitHub deploy key |
| **Secret file** | Kubeconfig, certificates, JSON keys | GCP service account key |
| **Certificate** | Client TLS authentication | mTLS connections |

### Credential Scopes

| Scope | Visibility | Use Case |
|-------|-----------|----------|
| **Global** | Available to all jobs | Common credentials (Docker, Git) |
| **System** | Only for Jenkins system (not jobs) | Agent connections, admin APIs |
| **Folder** | Jobs within a specific folder only | Team-specific credentials |

**Best practice**: Use **folder-level** credentials to isolate teams.

### Using `withCredentials` Block

```groovy
// Secret text
withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
    sh "sonar-scanner -Dsonar.login=$SONAR_TOKEN"
}

// Username and password
withCredentials([usernamePassword(
    credentialsId: 'docker-creds',
    usernameVariable: 'USER',
    passwordVariable: 'PASS'
)]) {
    sh 'echo $PASS | docker login -u $USER --password-stdin'
}

// SSH private key
withCredentials([sshUserPrivateKey(
    credentialsId: 'deploy-ssh',
    keyFileVariable: 'KEY_FILE',
    usernameVariable: 'SSH_USER'
)]) {
    sh 'ssh -i $KEY_FILE -o StrictHostKeyChecking=no $SSH_USER@server deploy.sh'
}

// Secret file (e.g., kubeconfig)
withCredentials([file(credentialsId: 'kubeconfig-prod', variable: 'KUBECONFIG')]) {
    sh 'kubectl get pods -n production'
}

// Multiple credentials at once
withCredentials([
    string(credentialsId: 'api-key', variable: 'API_KEY'),
    usernamePassword(credentialsId: 'db-creds', usernameVariable: 'DB_USER', passwordVariable: 'DB_PASS')
]) {
    sh 'run-migration.sh'
}
```

### Using `credentials()` Helper (Environment Block)

```groovy
environment {
    DOCKER_CREDS = credentials('dockerhub')     // Creates DOCKER_CREDS_USR and DOCKER_CREDS_PSW
    API_TOKEN = credentials('api-token')         // For secret text, single variable
    SSH_KEY = credentials('deploy-key')          // For SSH, variable holds file path
}
```

### How Jenkins Masks Secrets

- Values injected via `withCredentials` or `credentials()` are automatically **masked** in console output
- If the secret appears in a log line, it's replaced with `****`
- **Limitations**:
  - Encoded versions (base64, URL-encoded) may NOT be masked
  - `echo` in Groovy (`println`) bypasses masking — use `sh 'echo ...'` instead

---

## 8. Secret Handling Best Practices

### Do's ✅

```groovy
// Use withCredentials
withCredentials([string(credentialsId: 'token', variable: 'TOKEN')]) {
    sh 'curl -H "Authorization: Bearer $TOKEN" https://api.example.com'
}

// Use set +x to suppress command echoing
sh '''
    set +x
    curl -H "Authorization: Bearer $TOKEN" https://api.example.com
'''

// Use credentials() helper for environment
environment {
    MY_SECRET = credentials('secret-id')
}
```

### Don'ts ❌

```groovy
// NEVER hardcode secrets
sh 'curl -H "Authorization: Bearer abc123" ...'

// NEVER echo credentials
echo "Token is: ${TOKEN}"

// NEVER write secrets to files in workspace without cleanup
writeFile file: 'secret.txt', text: "${TOKEN}"

// NEVER pass secrets as build parameters (visible in build history)
```

### External Secret Managers

| Tool | Integration |
|------|-------------|
| **HashiCorp Vault** | HashiCorp Vault plugin → fetches secrets dynamically |
| **AWS Secrets Manager** | AWS plugin → read at runtime |
| **Azure Key Vault** | Azure Credentials plugin |
| **CyberArk** | CyberArk Credential Provider plugin |

```groovy
// HashiCorp Vault example
def secrets = [
    [path: 'secret/data/myapp', secretValues: [
        [envVar: 'DB_PASS', vaultKey: 'password']
    ]]
]
withVault(vaultSecrets: secrets) {
    sh 'echo "DB password is masked: $DB_PASS"'
}
```

### Credential Rotation Strategy

1. Use **short-lived credentials** where possible (OIDC, temporary tokens)
2. Rotate long-lived credentials on a schedule (90 days)
3. Use **external secret managers** for automatic rotation
4. **Audit** credential usage via Jenkins audit trail plugin
5. Remove unused credentials regularly

---

## Key Interview Questions from This Section

1. **What types of Jenkins agents are there?** → Static (permanent VMs), Docker (container per build), Kubernetes (pod per build), Cloud (EC2/Azure on demand).
2. **Static vs Dynamic agents?** → Static always run; dynamic are ephemeral, clean, and cost-efficient.
3. **What credential types does Jenkins support?** → Username/password, secret text, SSH key, secret file, certificate.
4. **How do you use credentials in a pipeline?** → `withCredentials` block or `credentials()` helper in environment block.
5. **How do you prevent secrets in logs?** → Use `withCredentials` (auto-masking), `set +x` in shell, never `echo` secrets, use external vault.
6. **Docker socket vs DinD?** → Socket mount shares host daemon (simple, less isolated); DinD runs separate daemon (isolated, needs privileged mode).
