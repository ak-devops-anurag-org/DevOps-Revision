# 🚀 Helm in Kubernetes

### **What is Helm?**

* Helm = **Package Manager for Kubernetes** (like `apt` for Ubuntu or `yum` for CentOS).
* Instead of writing multiple YAML files for Deployment, Service, Ingress, ConfigMaps, etc., Helm bundles them into **one reusable package** called a **Chart**.

### **Why Helm? (Problems it solves)**

Without Helm:

* You manually write and apply multiple YAMLs for each app (messy, repetitive).
* Hard to manage **different environments** (dev, QA, prod) with slightly different configs.
* Updating apps = manually editing YAMLs.
* Sharing applications is hard (you zip YAMLs and send).

With Helm:

* **Charts** package all K8s resources in one unit.
* Use **Values.yaml** to override configs per environment.
* Easy **versioning, rollback, upgrade**.
* Huge ecosystem of **public charts** (NGINX, MySQL, Prometheus, etc.).

### **Helm Components**

Helm has two main pieces:

1. **Helm Client (CLI)**

   * Runs on your machine.
   * Commands: `helm install`, `helm upgrade`, `helm rollback`, etc.

2. **Charts**

   * A Helm **Chart** = a package of YAML templates + values.
   * Structure:

     ```
     mychart/
     ├── Chart.yaml        # Metadata (name, version, etc.)
     ├── values.yaml       # Default config values
     ├── templates/        # Actual K8s manifests (with Go templating)
     │   ├── deployment.yaml
     │   ├── service.yaml
     │   └── ingress.yaml
     └── charts/           # Dependencies (other charts)
     ```
3. **Release**

    * Every time you install a chart, a release is created.
    * Release = specific instance of a chart running in a namespace.
    * Example: You can deploy the same chart (nginx) twice as nginx-dev and nginx-prod.

### **Helm Workflow**

1. Create a chart:

   ```bash
   helm create myapp
   ```
2. Customize `values.yaml` (app name, image, replicas).
3. Install into cluster:

   ```bash
   helm install myapp ./myapp
   ```
4. Upgrade when configs change:

   ```bash
   helm upgrade myapp ./myapp
   ```
5. Rollback if something breaks:

   ```bash
   helm rollback myapp 1
   ```

### **Helm Charts Example**

Let’s say you want to deploy NGINX.

* **values.yaml**

  ```yaml
  replicaCount: 2
  image:
    repository: nginx
    tag: "1.21.1"
  service:
    type: ClusterIP
    port: 80
  ```

* **templates/deployment.yaml**

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: {{ .Release.Name }}-nginx
  spec:
    replicas: {{ .Values.replicaCount }}
    selector:
      matchLabels:
        app: nginx
    template:
      metadata:
        labels:
          app: nginx
      spec:
        containers:
        - name: nginx
          image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
          ports:
          - containerPort: 80
  ```

When you run:

```bash
helm install webserver ./mychart
```

It substitutes values → generates Deployment + Service YAML → applies to cluster.

### **Helm Repositories**

* Charts are stored in repos (like Docker Hub for images).
* Popular repo: [Bitnami Helm Charts](https://bitnami.com/stacks/helm).

Example:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install mydb bitnami/mysql
```


**Summary**:
Helm = Kubernetes package manager.

* Chart = app package.
* Values.yaml = config.
* Commands: `install`, `upgrade`, `rollback`.
* Solves: complexity, duplication, environment differences.

