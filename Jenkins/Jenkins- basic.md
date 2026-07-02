# Jenkins Quick Revision Guide

## What is Jenkins?
- **Open-source automation server** written in Java for CI/CD
- Automates build, test, and deployment processes
- Web-based interface with 1,800+ plugins

## Jenkins Requirements
- **Java**: JDK 17+ (Jenkins 2.463+)
- **RAM**: Minimum 256MB, Recommended 4GB+
- **CPU**: 2+ cores
- **Disk**: 1GB minimum, 50GB+ recommended

## Installation Options
1. **Linux/Windows VM** (Most common in production)
2. **Docker Container**
3. **Kubernetes**
4. **WAR File**

## Production Setup - Linux VM
**Why Linux VM?**
- Better stability and security
- Lower resource overhead
- No licensing costs
- Better DevOps tool integration

**Setup:**
```bash
# Install Java
sudo apt install openjdk-17-jdk -y

# Install Jenkins
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update && sudo apt install jenkins -y

# Start service
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

## Initial Setup
**Default Password Path:**
```bash
# Linux
/var/lib/jenkins/secrets/initialAdminPassword
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Docker
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

**Setup Process:**
1. Access `http://<ip>:8080`
2. Enter initial admin password
3. **Install suggested plugins** (recommended)
4. Create admin user

## Plugins
**What are Plugins?**
- Add-on components that extend Jenkins functionality
- Integration with external tools

**Common Plugins:**
- Git Plugin, Pipeline Plugin, Blue Ocean
- Maven Integration, JUnit, Docker Plugin
- SonarQube Scanner, Slack Notification

## Pipeline (General Concept)
**Definition:** Automated sequence of processes from code to production
- Source → Build → Test → Deploy → Monitor
- **Benefits:** Automation, consistency, speed, visibility

## Jenkins Job Types

### 1. Freestyle Project
- GUI-based configuration
- Point-and-click setup
- Simple tasks, limited scripting
- Configuration stored in Jenkins

### 2. Pipeline
- **Pipeline as Code** using Jenkinsfile
- Complex workflows with parallel execution
- Version controlled, reusable
- Two types: **Declarative** (recommended) and **Scripted**

**Declarative Pipeline Example:**
```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean compile'
            }
        }
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
        stage('Deploy') {
            steps {
                sh 'mvn deploy'
            }
        }
    }
}
```

## Build Output Location
**Freestyle Project Path:**
```
/var/lib/jenkins/workspace/<JOB_NAME>/
```

**Directory Structure:**
```
/var/lib/jenkins/
├── workspace/     # Active workspaces
├── jobs/         # Job configs and build history
├── plugins/      # Installed plugins
└── secrets/      # Initial password
```

## Master-Slave Architecture
**What is it?**
- **Master (Controller):** Manages UI, scheduling, configuration
- **Slave (Agent):** Executes build jobs

**Benefits:**
- Scalability, performance distribution
- Multiple environments (Linux/Windows/macOS)
- Build isolation and high availability

## Jenkins Agents
**What are Agents?**
- Separate machines that execute builds assigned by Master

**Agent Requirements:**
- **Java** (same version as Master - JDK 17+)
- **Network connectivity** to Master
- **No Jenkins installation needed**
- Dedicated workspace directory

**Setup Methods:**
1. **SSH Agent** - Master connects via SSH
2. **JNLP Agent** - Agent connects to Master

**Quick SSH Setup:**
```bash
# On Agent
sudo useradd -m jenkins
sudo apt install openjdk-17-jdk -y

# Jenkins UI: Manage Jenkins → Nodes → New Node
# Configure: SSH launch method, credentials, labels
```

## Key Commands
```bash
# Start/Stop Jenkins
sudo systemctl start/stop jenkins

# View logs
sudo journalctl -u jenkins

# Jenkins workspace
ls /var/lib/jenkins/workspace/

# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## Quick Pipeline Script
```groovy
pipeline {
    agent { label 'linux' }
    stages {
        stage('Checkout') { steps { checkout scm } }
        stage('Build') { steps { sh 'mvn clean package' } }
        stage('Test') { steps { sh 'mvn test' } }
    }
    post {
        always { cleanWs() }
        success { echo 'Build successful!' }
    }
}
```

## Important Paths
- **Jenkins Home:** `/var/lib/jenkins/`
- **Workspace:** `/var/lib/jenkins/workspace/<JOB_NAME>/`
- **Initial Password:** `/var/lib/jenkins/secrets/initialAdminPassword`
- **Job Configs:** `/var/lib/jenkins/jobs/`