# Docker, Kubernetes & Cloud Integration

> **Interview Takeaways**: Know how to build/push Docker images in Jenkins, run K8s agents, deploy with Helm, integrate Terraform, and connect to cloud platforms (AWS, Azure, GCP).

---

## 1. Jenkins + Docker

### Running Jenkins Itself in Docker

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts-jdk17
```

### Using Docker as Build Agent

```groovy
pipeline {
    agent {
        docker {
            image 'maven:3.9-eclipse-temurin-17'
            args '-v $HOME/.m2:/root/.m2'   // Cache dependencies
        }
    }
    stages {
        stage('Build') { steps { sh 'mvn clean package' } }
    }
}
```

### Docker-in-Docker vs Docker Socket Mount

| Aspect | Socket Mount (`/var/run/docker.sock`) | DinD (`docker:dind`) |
|--------|--------------------------------------|---------------------|
| **Setup** | Mount host's Docker socket | Run separate Docker daemon |
| **Security** | ⚠️ Container accesses host Docker | ⚠️ Requires `--privileged` |
| **Isolation** | ❌ Shares host images/containers | ✅ Fully isolated |
| **Performance** | ✅ Fast (native daemon) | ❌ Overhead from nested daemon |
| **Image cache** | ✅ Shares host cache | ❌ Cold cache each time |
| **Use case** | ✅ Most CI/CD setups | Air-gapped, strict isolation |

### Building & Pushing Docker Images

```groovy
pipeline {
    agent any
    environment {
        REGISTRY = 'myregistry.azurecr.io'
        IMAGE = "${REGISTRY}/myapp:${BUILD_NUMBER}"
    }
    stages {
        stage('Docker Build') {
            steps {
                sh "docker build -t ${IMAGE} ."
            }
        }
        stage('Docker Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'acr-creds',
                    usernameVariable: 'REG_USER',
                    passwordVariable: 'REG_PASS'
                )]) {
                    sh "echo $REG_PASS | docker login ${REGISTRY} -u $REG_USER --password-stdin"
                    sh "docker push ${IMAGE}"
                }
            }
        }
    }
}
```

### Image Scanning Before Push

```groovy
stage('Scan Image') {
    steps {
        // Fail pipeline if HIGH or CRITICAL vulnerabilities found
        sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${IMAGE}"
    }
}
```

### Docker Compose in Pipelines

```groovy
stage('Integration Tests') {
    steps {
        sh 'docker-compose -f docker-compose.test.yml up -d'
        sh 'sleep 10'   // Wait for services
        sh 'mvn verify -Pintegration'
    }
    post {
        always {
            sh 'docker-compose -f docker-compose.test.yml down -v'
        }
    }
}
```

### Pushing to Different Registries

```groovy
// Docker Hub
sh 'docker login -u $DOCKERHUB_USER -p $DOCKERHUB_PASS'
sh 'docker push myorg/myapp:latest'

// AWS ECR
sh 'aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com'
sh 'docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest'

// Azure ACR
sh 'az acr login --name myregistry'
sh 'docker push myregistry.azurecr.io/myapp:latest'

// Google GCR
sh 'gcloud auth configure-docker'
sh 'docker push gcr.io/myproject/myapp:latest'
```

---

## 2. Jenkins + Kubernetes

### Jenkins on Kubernetes (Helm Deployment)

```bash
# Add Jenkins Helm repo
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Install Jenkins
helm install jenkins jenkins/jenkins \
  --namespace jenkins --create-namespace \
  --set controller.serviceType=LoadBalancer \
  --set controller.resources.requests.cpu=500m \
  --set controller.resources.requests.memory=1Gi \
  --set persistence.enabled=true \
  --set persistence.size=20Gi

# Get admin password
kubectl get secret jenkins -n jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 -d
```

### Kubernetes Plugin for Dynamic Agents

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
              serviceAccountName: jenkins-agent
              containers:
              - name: maven
                image: maven:3.9-eclipse-temurin-17
                command: ['sleep', 'infinity']
                resources:
                  requests:
                    cpu: 500m
                    memory: 512Mi
                  limits:
                    cpu: '1'
                    memory: 1Gi
                volumeMounts:
                - name: maven-cache
                  mountPath: /root/.m2
              - name: docker
                image: docker:24-cli
                command: ['sleep', 'infinity']
                volumeMounts:
                - name: docker-sock
                  mountPath: /var/run/docker.sock
              - name: kubectl
                image: bitnami/kubectl:latest
                command: ['sleep', 'infinity']
              volumes:
              - name: docker-sock
                hostPath:
                  path: /var/run/docker.sock
              - name: maven-cache
                emptyDir: {}
            '''
            defaultContainer 'maven'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        stage('Docker Build & Push') {
            steps {
                container('docker') {
                    sh 'docker build -t myapp:${BUILD_NUMBER} .'
                    sh 'docker push myapp:${BUILD_NUMBER}'
                }
            }
        }
        stage('Deploy') {
            steps {
                container('kubectl') {
                    sh 'kubectl set image deployment/myapp myapp=myapp:${BUILD_NUMBER} -n production'
                }
            }
        }
    }
}
```

### Deploying to Kubernetes from Jenkins

```groovy
// Method 1: kubectl directly
stage('Deploy') {
    steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
            sh 'kubectl apply -f k8s/deployment.yaml -n production'
            sh 'kubectl rollout status deployment/myapp -n production --timeout=120s'
        }
    }
}

// Method 2: Using kubectl set image (rolling update)
stage('Deploy') {
    steps {
        sh "kubectl set image deployment/myapp myapp=${IMAGE}:${TAG} -n production"
    }
}

// Method 3: Helm (recommended for complex deployments)
stage('Deploy') {
    steps {
        sh """
            helm upgrade --install myapp ./helm/myapp \
                --namespace production \
                --set image.tag=${BUILD_NUMBER} \
                --wait --timeout 300s
        """
    }
}
```

### Kubeconfig & Credential Management

```groovy
// Store kubeconfig as a Secret file credential in Jenkins
withCredentials([file(credentialsId: 'kubeconfig-prod', variable: 'KUBECONFIG')]) {
    sh 'kubectl get pods -n production'
}

// Or use Kubernetes service account (when Jenkins runs in K8s)
// No credentials needed — pod's service account has RBAC permissions
```

---

## 3. Jenkins + Helm

### Helm in Jenkins Pipelines

```groovy
stage('Deploy with Helm') {
    steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
            sh """
                helm upgrade --install myapp ./helm/myapp \\
                    --namespace production \\
                    --set image.repository=${REGISTRY}/myapp \\
                    --set image.tag=${BUILD_NUMBER} \\
                    --values helm/myapp/values-prod.yaml \\
                    --wait \\
                    --timeout 300s \\
                    --atomic
            """
        }
    }
}
```

### `--atomic` Flag

- If deploy fails, Helm **automatically rolls back** to previous release
- Combines `--wait` + rollback on failure
- Essential for production deployments

### Values File Per Environment

```
helm/myapp/
├── Chart.yaml
├── values.yaml            # Defaults
├── values-dev.yaml        # Dev overrides
├── values-staging.yaml    # Staging overrides
└── values-prod.yaml       # Production overrides
```

```groovy
// Environment-specific deployment
sh """
    helm upgrade --install myapp ./helm/myapp \\
        --namespace ${params.ENVIRONMENT} \\
        --values helm/myapp/values-${params.ENVIRONMENT}.yaml \\
        --set image.tag=${BUILD_NUMBER}
"""
```

---

## 4. Jenkins + Terraform

### Terraform Pipeline Pattern

```groovy
pipeline {
    agent any
    parameters {
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
    }
    environment {
        TF_VAR_environment = "${params.ENVIRONMENT}"
        AWS_CREDS = credentials('aws-terraform')
    }
    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        stage('Terraform Init') {
            steps {
                dir("environments/${params.ENVIRONMENT}") {
                    sh 'terraform init -backend-config=backend.hcl'
                }
            }
        }
        stage('Terraform Plan') {
            steps {
                dir("environments/${params.ENVIRONMENT}") {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }
        stage('Approval') {
            when { expression { params.ACTION == 'apply' && params.ENVIRONMENT == 'prod' } }
            steps {
                input message: "Apply Terraform changes to PRODUCTION?", ok: 'Apply'
            }
        }
        stage('Terraform Apply') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                dir("environments/${params.ENVIRONMENT}") {
                    sh 'terraform apply tfplan'
                }
            }
        }
    }
    post {
        always {
            // Archive plan for audit
            archiveArtifacts artifacts: '**/tfplan', allowEmptyArchive: true
        }
    }
}
```

### Key Considerations

- **Save the plan file** and apply it — ensures reviewed changes are what get applied
- **Approval gate** for production `apply`
- **Never auto-apply** to production without review
- **State management** — use remote backend (S3, Azure Blob)
- **Credentials** — use IAM roles or short-lived tokens, not hardcoded keys

---

## 5. Jenkins + Artifact Repositories

### Nexus / Artifactory Integration

```groovy
// Push Maven artifact to Nexus
stage('Publish to Nexus') {
    steps {
        sh 'mvn deploy -DaltDeploymentRepository=nexus::default::https://nexus.example.com/repository/maven-releases/'
    }
}

// Push to Artifactory
stage('Publish to Artifactory') {
    steps {
        rtUpload(
            serverId: 'artifactory',
            spec: """{
                "files": [{
                    "pattern": "target/*.jar",
                    "target": "libs-release-local/myapp/"
                }]
            }"""
        )
    }
}

// Push Helm chart to registry
stage('Push Helm Chart') {
    steps {
        sh 'helm package ./helm/myapp'
        sh 'helm push myapp-*.tgz oci://myregistry.azurecr.io/helm'
    }
}
```

---

## 6. Jenkins + Cloud Platforms

### AWS Integration

```groovy
// Using AWS credentials
environment {
    AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
    AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    AWS_DEFAULT_REGION    = 'us-east-1'
}

// ECR login and push
stage('Push to ECR') {
    steps {
        sh '''
            aws ecr get-login-password --region $AWS_DEFAULT_REGION | \
            docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
            docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/myapp:$BUILD_NUMBER
        '''
    }
}

// Deploy to EKS
stage('Deploy to EKS') {
    steps {
        sh 'aws eks update-kubeconfig --name my-cluster --region us-east-1'
        sh 'kubectl apply -f k8s/ -n production'
    }
}
```

### Azure Integration

```groovy
// Using Azure Service Principal
withCredentials([azureServicePrincipal('azure-sp')]) {
    sh 'az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID'
    sh 'az aks get-credentials --resource-group myRG --name myAKS'
    sh 'kubectl apply -f k8s/ -n production'
}
```

### GCP Integration

```groovy
// Using GCP Service Account Key
withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
    sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS'
    sh 'gcloud container clusters get-credentials my-cluster --zone us-central1-a'
    sh 'kubectl apply -f k8s/ -n production'
}
```

---

## 7. Production-Grade CI/CD Pipeline — Complete Example

```groovy
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
                volumeMounts:
                - name: m2-cache
                  mountPath: /root/.m2
              - name: docker
                image: docker:24-cli
                command: ['sleep', 'infinity']
                volumeMounts:
                - name: docker-sock
                  mountPath: /var/run/docker.sock
              - name: helm
                image: alpine/helm:3.14
                command: ['sleep', 'infinity']
              - name: trivy
                image: aquasec/trivy:latest
                command: ['sleep', 'infinity']
              volumes:
              - name: docker-sock
                hostPath:
                  path: /var/run/docker.sock
              - name: m2-cache
                emptyDir: {}
            '''
            defaultContainer 'maven'
        }
    }

    environment {
        REGISTRY  = 'myregistry.azurecr.io'
        APP_NAME  = 'myapp'
        IMAGE     = "${REGISTRY}/${APP_NAME}:${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Build') {
            steps { sh 'mvn clean package -DskipTests' }
        }

        stage('Unit Test') {
            steps { sh 'mvn test' }
            post { always { junit 'target/surefire-reports/*.xml' } }
        }

        stage('SonarQube') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar'
                }
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
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

        stage('Image Scan') {
            steps {
                container('trivy') {
                    sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${IMAGE}"
                }
            }
        }

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

        stage('Deploy to Dev') {
            when { branch 'develop' }
            steps {
                container('helm') {
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                        sh """
                            helm upgrade --install ${APP_NAME} ./helm/${APP_NAME} \\
                                --namespace dev \\
                                --set image.tag=${BUILD_NUMBER} \\
                                --values helm/${APP_NAME}/values-dev.yaml \\
                                --wait --atomic
                        """
                    }
                }
            }
        }

        stage('Deploy to Production') {
            when { branch 'main' }
            steps {
                input message: 'Deploy to Production?', ok: 'Deploy', submitter: 'devops-leads'
                container('helm') {
                    withCredentials([file(credentialsId: 'kubeconfig-prod', variable: 'KUBECONFIG')]) {
                        sh """
                            helm upgrade --install ${APP_NAME} ./helm/${APP_NAME} \\
                                --namespace production \\
                                --set image.tag=${BUILD_NUMBER} \\
                                --values helm/${APP_NAME}/values-prod.yaml \\
                                --wait --atomic
                        """
                    }
                }
            }
        }

        stage('Smoke Test') {
            when { branch 'main' }
            steps {
                sh 'curl -sf https://myapp.example.com/health || exit 1'
            }
        }
    }

    post {
        success { slackSend color: 'good', message: "✅ ${JOB_NAME} #${BUILD_NUMBER} deployed" }
        failure { slackSend color: 'danger', message: "❌ ${JOB_NAME} #${BUILD_NUMBER} FAILED" }
        always { cleanWs() }
    }
}
```

---

## Key Interview Questions from This Section

1. **How do you build Docker images in Jenkins?** → Use `docker build` in shell step; mount Docker socket or use DinD; push to registry with credentials.
2. **How do you run Jenkins on Kubernetes?** → Helm chart deployment; Kubernetes plugin for dynamic pod agents; auto-scaling.
3. **How do you deploy to K8s from Jenkins?** → `kubectl apply`, `kubectl set image`, or `helm upgrade --install` with kubeconfig credentials.
4. **What is `--atomic` in Helm?** → Auto-rollback if deployment fails; essential for production safety.
5. **How do you integrate Terraform?** → init → plan → save plan → approval gate → apply from saved plan; never auto-apply to production.
