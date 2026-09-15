# DevSecOps Pipeline with Jenkins

> **Interview Takeaways**: Know the shift-left concept, integrate SonarQube/Trivy/OWASP in pipelines, understand quality gates (fail vs warn), and implement a complete DevSecOps Jenkinsfile.

---

## 1. What Is DevSecOps

- **Shift-left security** — integrate security early in the development lifecycle, not at the end
- Security becomes part of every developer's workflow, not just the security team's
- Automated scans run in CI/CD — every commit is security-tested
- **Jenkins's role**: Orchestrate security scans as pipeline stages, enforce quality gates

### Key Principle

```
Traditional:  Dev → Ops → Security (find issues late, expensive to fix)
DevSecOps:    Dev+Sec+Ops (find issues early, cheap to fix)
```

---

## 2. Security Scanning Stages in a Pipeline

```
┌──────────┐   ┌───────┐   ┌──────┐   ┌──────┐   ┌────────┐   ┌────────────┐
│ Checkout │ → │ Build │ → │ SAST │ → │ SCA  │ → │  Test  │ → │Docker Build│
└──────────┘   └───────┘   └──────┘   └──────┘   └────────┘   └─────┬──────┘
                                                                      ↓
┌──────────┐   ┌────────┐   ┌──────────┐   ┌──────┐   ┌────────────────────┐
│  Deploy  │ ← │  Push  │ ← │ IaC Scan │ ← │ DAST │ ← │ Container/Image    │
│          │   │        │   │          │   │(post)│   │ Scan (Trivy)       │
└──────────┘   └────────┘   └──────────┘   └──────┘   └────────────────────┘
```

| Stage | What It Does | Tools |
|-------|-------------|-------|
| **SAST** | Analyse source code for vulnerabilities | SonarQube, Checkmarx, Semgrep |
| **SCA** | Scan dependencies for known CVEs | OWASP Dependency-Check, Snyk, Dependabot |
| **Image Scan** | Scan Docker images for OS/package CVEs | Trivy, Grype, Snyk Container |
| **IaC Scan** | Check Terraform/K8s manifests for misconfigs | Checkov, tfsec, Terrascan |
| **DAST** | Test running application for vulnerabilities | OWASP ZAP, Burp Suite |

---

## 3. SAST — Static Application Security Testing

### SonarQube Integration

**SonarQube** scans source code for bugs, vulnerabilities, code smells, and security hotspots.

#### Setup

1. Install **SonarQube Scanner** plugin in Jenkins
2. Configure SonarQube server: Manage Jenkins → System → SonarQube servers
3. Add SonarQube token as Jenkins credential

#### Pipeline Stage

```groovy
stage('SonarQube Analysis') {
    steps {
        withSonarQubeEnv('SonarQube-Server') {
            sh '''
                mvn sonar:sonar \
                    -Dsonar.projectKey=myapp \
                    -Dsonar.projectName="My Application"
            '''
        }
    }
}

// Wait for Quality Gate result
stage('Quality Gate') {
    steps {
        timeout(time: 5, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
        }
    }
}
```

#### How Quality Gate Works

1. SonarQube analyses the code
2. Evaluates against **Quality Gate** rules (coverage > 80%, no critical bugs, etc.)
3. Sends webhook back to Jenkins with pass/fail
4. `waitForQualityGate abortPipeline: true` → **fails the pipeline** if gate fails

### Other SAST Tools

```groovy
// Semgrep (open-source SAST)
stage('SAST - Semgrep') {
    steps {
        sh 'semgrep --config=auto --json --output=semgrep-results.json .'
    }
}

// Checkmarx (enterprise SAST)
stage('SAST - Checkmarx') {
    steps {
        step([$class: 'CxScanBuilder',
              projectName: 'myapp',
              serverUrl: 'https://checkmarx.example.com',
              vulnerabilityThresholdEnabled: true,
              highThreshold: 0])
    }
}
```

---

## 4. SCA — Software Composition Analysis

### OWASP Dependency-Check

Scans project dependencies for known vulnerabilities (CVEs).

```groovy
stage('Dependency Check') {
    steps {
        sh '''
            dependency-check.sh \
                --project myapp \
                --scan . \
                --format JSON \
                --format HTML \
                --out dependency-check-report
        '''
    }
    post {
        always {
            dependencyCheckPublisher pattern: 'dependency-check-report/dependency-check-report.json'
            archiveArtifacts artifacts: 'dependency-check-report/*', allowEmptyArchive: true
        }
    }
}
```

### Snyk

```groovy
stage('SCA - Snyk') {
    steps {
        withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
            sh 'snyk auth $SNYK_TOKEN'
            sh 'snyk test --severity-threshold=high'    // Fail on high+ vulns
            sh 'snyk monitor'                            // Upload to dashboard
        }
    }
}
```

---

## 5. Container/Image Scanning

### Trivy Integration ⭐

Trivy is the **most commonly asked** image scanning tool in interviews.

```groovy
stage('Image Scan - Trivy') {
    steps {
        // Hard fail on CRITICAL and HIGH vulnerabilities
        sh '''
            trivy image \
                --exit-code 1 \
                --severity HIGH,CRITICAL \
                --format table \
                ${IMAGE}:${BUILD_NUMBER}
        '''
    }
}

// Generate HTML report
stage('Image Scan - Trivy') {
    steps {
        sh '''
            trivy image \
                --exit-code 1 \
                --severity HIGH,CRITICAL \
                --format template \
                --template "@/contrib/html.tpl" \
                --output trivy-report.html \
                ${IMAGE}:${BUILD_NUMBER}
        '''
    }
    post {
        always {
            archiveArtifacts artifacts: 'trivy-report.html', allowEmptyArchive: true
        }
    }
}
```

### Soft Fail — Mark Unstable Instead of Failing

```groovy
stage('Image Scan') {
    steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
            sh 'trivy image --exit-code 1 --severity CRITICAL ${IMAGE}'
        }
    }
}
```

### Trivy File System Scan

```groovy
// Scan source code and dependencies (before Docker build)
stage('FS Scan') {
    steps {
        sh 'trivy fs --exit-code 1 --severity HIGH,CRITICAL .'
    }
}
```

### Alternatives

| Tool | Type | Notes |
|------|------|-------|
| **Grype** | Image scanner | Anchore's scanner, fast |
| **Snyk Container** | Image scanner | Commercial, good UI |
| **Docker Scout** | Image scanner | Docker's native scanner |
| **Clair** | Image scanner | CoreOS, open-source |

---

## 6. IaC Scanning

### Checkov

```groovy
stage('IaC Scan - Checkov') {
    steps {
        sh '''
            checkov \
                --directory terraform/ \
                --output json \
                --output-file checkov-results.json \
                --soft-fail-on LOW
        '''
    }
}
```

### tfsec

```groovy
stage('IaC Scan - tfsec') {
    steps {
        sh 'tfsec terraform/ --format json --out tfsec-results.json'
    }
}
```

### Scanning Kubernetes Manifests

```groovy
stage('K8s Scan') {
    steps {
        sh 'checkov --directory k8s/ --framework kubernetes'
        // Or: sh 'kubesec scan k8s/deployment.yaml'
    }
}
```

---

## 7. DAST — Dynamic Application Security Testing

DAST tests the **running application** for vulnerabilities (SQL injection, XSS, etc.).

### OWASP ZAP

```groovy
stage('DAST - ZAP') {
    // Run AFTER deployment to staging
    steps {
        sh '''
            docker run --rm \
                -v $(pwd)/zap-report:/zap/wrk:rw \
                ghcr.io/zaproxy/zaproxy:stable \
                zap-baseline.py \
                -t https://staging.myapp.com \
                -r zap-report.html \
                -I    # Non-failing mode (info only)
        '''
    }
    post {
        always {
            archiveArtifacts artifacts: 'zap-report/*.html', allowEmptyArchive: true
        }
    }
}
```

**When to run DAST**: After deploying to staging, not in the build phase.

---

## 8. Quality Gates & Fail vs Warn Behaviour ⭐

### Hard Fail — Pipeline Stops

```groovy
// Pipeline fails immediately on findings
sh 'trivy image --exit-code 1 --severity CRITICAL ${IMAGE}'
```

### Soft Fail — Pipeline Continues, Build Marked UNSTABLE

```groovy
// Build continues but is marked UNSTABLE
stage('Security Scan') {
    steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
            sh 'trivy image --exit-code 1 --severity HIGH,CRITICAL ${IMAGE}'
        }
    }
}
```

### Per-Severity Strategy

```groovy
// CRITICAL → Hard fail (pipeline stops)
stage('Critical CVE Check') {
    steps {
        sh 'trivy image --exit-code 1 --severity CRITICAL ${IMAGE}'
    }
}

// HIGH → Soft fail (mark UNSTABLE, continue)
stage('High CVE Check') {
    steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
            sh 'trivy image --exit-code 1 --severity HIGH ${IMAGE}'
        }
    }
}

// MEDIUM/LOW → Report only (no failure)
stage('Full Scan Report') {
    steps {
        sh 'trivy image --exit-code 0 --severity MEDIUM,LOW ${IMAGE} > trivy-info.txt'
        archiveArtifacts 'trivy-info.txt'
    }
}
```

### Recommended Quality Gate Strategy

| Severity | Action | Rationale |
|----------|--------|-----------|
| **CRITICAL** | ❌ Hard fail | Active exploits, must fix immediately |
| **HIGH** | ⚠️ Soft fail (UNSTABLE) | Serious risk, fix soon |
| **MEDIUM** | 📊 Report only | Track and prioritise |
| **LOW** | 📊 Report only | Address during regular maintenance |

---

## 9. Secrets Management in DevSecOps

### Jenkins Credentials Store

- Built-in, encrypted at rest with `master.key`
- Suitable for basic usage
- Limited rotation and audit capabilities

### HashiCorp Vault Integration

```groovy
// Using HashiCorp Vault plugin
def secrets = [
    [path: 'secret/data/myapp/prod', secretValues: [
        [envVar: 'DB_PASSWORD', vaultKey: 'db_password'],
        [envVar: 'API_KEY', vaultKey: 'api_key']
    ]]
]

stage('Deploy') {
    steps {
        withVault(configuration: [vaultUrl: 'https://vault.internal:8200'], vaultSecrets: secrets) {
            sh 'deploy.sh'
        }
    }
}
```

### Best Practices

- **Never** hardcode secrets in Jenkinsfile or source code
- Use `withCredentials` for automatic masking
- Use `set +x` in shell steps to prevent command echoing
- Prefer **external secret managers** (Vault, AWS SM) for rotation
- Scan repos for leaked secrets using **gitleaks** or **trufflehog**
- Rotate Jenkins `master.key` if compromised

---

## 10. Secure Jenkins Pipeline Practices

### Shared Libraries

```groovy
// Use @Library for trusted, audited pipeline code
@Library('my-shared-lib') _

pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                buildApp()  // From shared library
            }
        }
        stage('Security Scan') {
            steps {
                securityScan(image: "${IMAGE}")  // Standardised scanning
            }
        }
    }
}
```

### Pipeline Security Checklist

- ✅ Use **Shared Libraries** for standardised security stages
- ✅ Enable **Groovy sandbox** — limits what pipeline scripts can do
- ✅ Require **Script Approval** for non-sandboxed scripts
- ✅ Pin plugin and tool versions
- ✅ Restrict who can modify the Jenkinsfile (CODEOWNERS)
- ✅ Enable **audit trail** plugin for all pipeline actions
- ✅ Scan Jenkinsfiles for hardcoded secrets in PR checks
- ✅ Use `timeout` to prevent builds from running indefinitely

---

## 11. Complete DevSecOps Jenkinsfile

```groovy
@Library('devsecops-lib') _

pipeline {
    agent {
        kubernetes {
            yaml '''
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: maven
                image: maven:3.9-eclipse-temurin-17
                command: ['sleep', 'infinity']
              - name: docker
                image: docker:24-cli
                command: ['sleep', 'infinity']
                volumeMounts:
                - name: docker-sock
                  mountPath: /var/run/docker.sock
              - name: trivy
                image: aquasec/trivy:latest
                command: ['sleep', 'infinity']
              volumes:
              - name: docker-sock
                hostPath:
                  path: /var/run/docker.sock
            '''
            defaultContainer 'maven'
        }
    }

    environment {
        REGISTRY    = 'myregistry.azurecr.io'
        IMAGE       = "${REGISTRY}/myapp:${BUILD_NUMBER}"
        SONAR_TOKEN = credentials('sonarqube-token')
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Build') {
            steps { sh 'mvn clean package -DskipTests' }
        }

        stage('Unit Tests') {
            steps { sh 'mvn test' }
            post { always { junit 'target/surefire-reports/*.xml' } }
        }

        // === SECURITY GATES ===

        stage('SAST - SonarQube') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar'
                }
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true   // Hard fail on quality gate
                }
            }
        }

        stage('SCA - Dependency Check') {
            steps {
                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                    sh 'dependency-check.sh --project myapp --scan . --failOnCVSS 7'
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: '**/dependency-check-report.*', allowEmptyArchive: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                container('docker') {
                    sh "docker build -t ${IMAGE} ."
                }
            }
        }

        stage('Image Scan - Trivy') {
            steps {
                container('trivy') {
                    // Critical → hard fail
                    sh "trivy image --exit-code 1 --severity CRITICAL ${IMAGE}"
                }
                container('trivy') {
                    // High → soft fail (UNSTABLE)
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        sh "trivy image --exit-code 1 --severity HIGH ${IMAGE}"
                    }
                }
            }
        }

        stage('IaC Scan') {
            when { changeset 'terraform/**' }   // Only when Terraform files change
            steps {
                sh 'checkov --directory terraform/ --soft-fail-on LOW'
            }
        }

        // === DEPLOY ===

        stage('Push Image') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: 'acr-creds', usernameVariable: 'U', passwordVariable: 'P')]) {
                        sh "echo $P | docker login ${REGISTRY} -u $U --password-stdin"
                        sh "docker push ${IMAGE}"
                    }
                }
            }
        }

        stage('Deploy to Staging') {
            when { branch 'main' }
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh "kubectl set image deployment/myapp myapp=${IMAGE} -n staging"
                    sh 'kubectl rollout status deployment/myapp -n staging --timeout=120s'
                }
            }
        }

        stage('DAST - ZAP') {
            when { branch 'main' }
            steps {
                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                    sh '''
                        docker run --rm \
                            ghcr.io/zaproxy/zaproxy:stable \
                            zap-baseline.py -t https://staging.myapp.com
                    '''
                }
            }
        }

        stage('Deploy to Production') {
            when { branch 'main' }
            steps {
                input message: 'Deploy to Production?', ok: 'Deploy', submitter: 'devops-leads'
                withCredentials([file(credentialsId: 'kubeconfig-prod', variable: 'KUBECONFIG')]) {
                    sh "kubectl set image deployment/myapp myapp=${IMAGE} -n production"
                    sh 'kubectl rollout status deployment/myapp -n production --timeout=180s'
                }
            }
        }
    }

    post {
        success { slackSend color: 'good', message: "✅ ${JOB_NAME} #${BUILD_NUMBER} — all security gates passed" }
        unstable { slackSend color: 'warning', message: "⚠️ ${JOB_NAME} #${BUILD_NUMBER} — security findings (UNSTABLE)" }
        failure { slackSend color: 'danger', message: "❌ ${JOB_NAME} #${BUILD_NUMBER} — FAILED (security gate blocked)" }
        always { cleanWs() }
    }
}
```

---

## Key Interview Questions from This Section

1. **What is DevSecOps?** → Integrating security into every phase of CI/CD (shift-left), not treating it as a separate gate at the end.
2. **Name the security scanning types** → SAST (code), SCA (dependencies), Image scan (containers), IaC scan (infra config), DAST (running app).
3. **How do you integrate SonarQube?** → `withSonarQubeEnv` + `waitForQualityGate abortPipeline: true` for quality gate enforcement.
4. **How do you scan Docker images?** → Trivy: `trivy image --exit-code 1 --severity HIGH,CRITICAL myimage:tag`.
5. **Fail vs Warn?** → `catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE')` for soft fail; `--exit-code 1` for hard fail.
6. **How do you prevent secrets in logs?** → `withCredentials` (auto-masking), `set +x`, never `echo`, use external vault.
