# Helm & Production Kubernetes — Interview Revision

> Covers: Helm charts, releases, production deployment strategies, autoscaling, HA, observability, and best practices.

## Part 1: Helm

### Q1. What is Helm and why is it used? ⭐ MUST KNOW

**Answer:** Helm is the package manager for Kubernetes. It uses "charts" (packages of templated K8s manifests) to simplify and automate the deployment of complex applications.

**How it works:** It groups related K8s resources into a single logical unit. Instead of managing dozens of static YAML files, you parameterize them, making the application easily reusable across different environments.

**Interview point:** Emphasize reusability and parameterization. Mention that Helm allows treating K8s deployments like software packages (install, upgrade, rollback).

---

### Q2. What is the typical structure of a Helm chart? 🟠 IMPORTANT

**Answer:** A Helm chart is a directory with a specific structure.
```text
my-chart/
├── Chart.yaml          # Metadata (name, version, description)
├── values.yaml         # Default configuration values
├── templates/          # Templated K8s manifests (deployment.yaml, service.yaml, etc.)
│   └── _helpers.tpl    # Template helpers/functions
└── charts/             # Sub-chart dependencies
```

**How it works:** When you run `helm install`, Helm merges the templates in the `templates/` directory with the variables defined in `values.yaml` to generate valid Kubernetes manifests, which are then applied to the cluster.

**Interview point:** Interviewers want to know you've built or modified charts. Knowing `Chart.yaml` vs `values.yaml` vs `templates/` is mandatory.

---

### Q3. How does `values.yaml` work and what is the override priority? ⭐ MUST KNOW

**Answer:** `values.yaml` stores default configuration variables for the chart. These values are injected into the templates during rendering.

**How it works:** Values can be overridden at install or upgrade time. The priority from lowest to highest is:
1. Default `values.yaml` (in the chart)
2. Custom values file (`-f custom-values.yaml`)
3. Command-line flags (`--set key=value`)

**Interview point:** Explain that `--set` has the highest priority and is useful for passing dynamic secrets or one-off flags in CI/CD pipelines, while `-f` is better for environment-specific configs.

---

### Q4. How do Helm templates work? Give examples of syntax. 🟠 IMPORTANT

**Answer:** Helm uses Go template syntax to dynamically generate manifests.

**How it works:** You use double curly braces `{{ }}` to access values or use control structures.
- Value injection: `{{ .Values.replicaCount }}` or `{{ .Release.Name }}`
- Conditionals: `{{ if .Values.ingress.enabled }} ... {{ end }}`
- Loops: `{{ range .Values.hosts }} ... {{ end }}`

**Interview point:** Be able to mention Go templating and show that you understand how to make a deployment optional (using `if`) or iterate through lists (using `range`).

---

### Q5. What are the essential Helm commands for a deployment lifecycle? 🟠 IMPORTANT

**Answer:** 
- Add repo: `helm repo add bitnami https://charts.bitnami.com/bitnami`
- Install: `helm install my-release ./my-chart -f prod-values.yaml`
- Upgrade: `helm upgrade my-release ./my-chart -f prod-values.yaml` (or `upgrade --install`)
- Uninstall: `helm uninstall my-release`

**How it works:** These commands interact with the K8s cluster to create, update, or delete the resources defined by the rendered chart.

**Interview point:** Always mention `helm upgrade --install` (often used in CI/CD because it works whether it's the first deployment or an update).

---

### Q6. What is a Helm Release and how does rollback work? ⭐ MUST KNOW

**Answer:** A release is an instance of a chart deployed to a Kubernetes cluster. Every `helm upgrade` creates a new revision of that release.

**How it works:** Helm stores the history and state of each revision in K8s Secrets (by default) in the same namespace. You can rollback to any previous revision using `helm rollback my-release <revision_number>`.

**Interview point:** This is a major selling point of Helm. Mentioning that the state is stored in Secrets shows deep architectural knowledge.

---

### Q7. How does Helm differ from just using `kubectl apply`? 🟠 IMPORTANT

**Answer:** 

| Feature | Helm | `kubectl apply` |
|---------|------|-----------------|
| Approach | Templated, parameterized | Static YAML |
| Lifecycle | Release management (install, upgrade, uninstall) | No release tracking |
| Rollback | Built-in (`helm rollback`) | Manual K8s native rollbacks |
| Use Case | Complex apps, multiple environments | Simple deployments, one-off resources |

**Interview point:** `kubectl apply` is fine for simple things, but Helm is essential for CI/CD, multi-environment deployments, and distributing third-party apps (like Nginx ingress or Prometheus).

---

### Q8. 🎯 SCENARIO: A Helm upgrade failed in production. How do you rollback?

**Answer:** 
1. Check the history to find the previous stable revision: `helm history my-release -n production`
2. Rollback to that revision: `helm rollback my-release 1 -n production` (where 1 is the revision number).

**How it works:** Helm retrieves the saved K8s Secret for that specific revision, renders the manifests as they were at that time, and applies them to the cluster.

**Interview point:** Quick rollbacks are crucial for MTTR (Mean Time To Recovery). Mention doing this before digging into logs to restore service quickly.

---

### Q9. 🎯 SCENARIO: You have the same chart but need different configurations for dev, staging, and prod.

**Answer:** Maintain a single Helm chart and create separate values files for each environment (e.g., `values-dev.yaml`, `values-prod.yaml`).

**How it works:** In your CI/CD pipeline, pass the appropriate values file during deployment: 
`helm upgrade --install my-app ./my-chart -f values-prod.yaml -n prod`

**Interview point:** This is the standard pattern for DRY (Don't Repeat Yourself) infrastructure. You only maintain one set of K8s YAMLs.

---

### Q10. 🎯 SCENARIO: How do you debug Helm template rendering issues before applying?

**Answer:** Use `helm template` or `helm install --dry-run`.

**How it works:** 
- `helm template my-release ./my-chart`: Renders the templates locally and prints the output YAML without connecting to the K8s API.
- `helm install --dry-run --debug my-release ./my-chart`: Simulates an install against the K8s cluster, verifying that K8s will accept the manifests.

**Interview point:** Mention using `--dry-run` to catch K8s API validation errors, while `template` is good for quick local YAML inspection.

---

### Q11. 🎯 SCENARIO: A Helm release is stuck in a "pending-install" or "pending-upgrade" state.

**Answer:** This usually happens if a previous Helm operation was interrupted, timed out, or crashed.

**How it works:** Helm places a lock (via Secrets) during operations. If interrupted, the lock remains. Fix it by finding the secret and modifying it, or explicitly rolling back.
Command: `helm rollback <release>` or in severe cases, deleting the stuck Helm secret directly.

**Interview point:** Shows real-world troubleshooting experience. 

---

## Part 2: Production Kubernetes

### Q12. What is a RollingUpdate deployment strategy? ⭐ MUST KNOW

**Answer:** It is the default K8s deployment strategy that gradually replaces old Pods with new ones, ensuring zero downtime.

**How it works:** 
Controlled by two parameters:
- `maxSurge`: How many extra Pods can be created above the desired count.
- `maxUnavailable`: How many Pods can be unavailable below the desired count.
*Flow: Adds new Pod -> Waits for Readiness -> Terminates old Pod -> Repeats.*

**Interview point:** Essential for zero-downtime deployments. Explain that without Readiness probes, a RollingUpdate can still cause downtime!

---

### Q13. What is the Recreate deployment strategy and when do you use it? 🟠 IMPORTANT

**Answer:** It kills all existing Pods before creating new ones.

**How it works:** Downtime is guaranteed. You use it only when the old version and new version cannot run simultaneously (e.g., destructive database schema migrations or legacy apps holding strict volume locks).

**Interview point:** Contrast this with RollingUpdate. It's a trade-off between zero downtime and data/state safety.

---

### Q14. How do you rollback a native Kubernetes Deployment (without Helm)? ⭐ MUST KNOW

**Answer:** Use the `kubectl rollout undo` command.

**How it works:** 
- `kubectl rollout undo deployment/my-app` (Rolls back to the immediate previous ReplicaSet)
- `kubectl rollout history deployment/my-app` (View revisions)
- `kubectl rollout undo deployment/my-app --to-revision=2` (Specific revision)

**Interview point:** K8s Deployments manage multiple ReplicaSets. A rollback simply scales up an old ReplicaSet and scales down the current one.

---

### Q15. Briefly explain Blue/Green and Canary deployments. 🟠 IMPORTANT

**Answer:** These are advanced, zero-downtime deployment strategies, typically requiring extra tools (Service Mesh, Ingress controllers, or Argo Rollouts).

**How it works:** 
- **Blue/Green:** Run two identical environments. Switch 100% of traffic from old (Blue) to new (Green) instantly via routing changes.
- **Canary:** Gradually shift a percentage of traffic (e.g., 5% -> 20% -> 100%) to the new version while monitoring metrics.

**Interview point:** Acknowledge that native K8s Deployments don't do these natively (RollingUpdate is not Canary). You need tools like Istio, Flagger, or Argo Rollouts.

---

### Q16. How do you ensure High Availability (HA) for a K8s application? ⭐ MUST KNOW

**Answer:** By distributing resources and handling failures gracefully.

**How it works:** 
1. Multiple Replicas (always > 1).
2. Pod Anti-Affinity (ensure Pods don't schedule on the same Node or Zone).
3. PodDisruptionBudget (PDB) (ensure a minimum number of Pods stay up during voluntary disruptions like node upgrades).
4. Multi-zone Node pools.

**Interview point:** Don't just say "more replicas". Mentioning Anti-Affinity and PDBs proves you've managed actual production clusters.

---

### Q17. What is HPA (Horizontal Pod Autoscaler) and how does it work? ⭐ MUST KNOW

**Answer:** HPA automatically scales the number of Pod replicas in a Deployment based on observed metrics (like CPU or Memory utilization).

**How it works:** It requires the `metrics-server` to be installed.
```yaml
minReplicas: 2
maxReplicas: 10
metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```
When CPU exceeds 70%, HPA adds more Pods. When it drops, it removes Pods.

**Interview point:** Note that HPA scales *Pods*, not Nodes. Mention that resource requests MUST be set on the Pods for HPA to calculate percentages.

---

### Q18. Explain VPA and Cluster Autoscaler. 🟠 IMPORTANT

**Answer:** 
- **VPA (Vertical Pod Autoscaler):** Automatically adjusts CPU and Memory `requests` and `limits` for containers. Useful for right-sizing apps, but requires restarting Pods to apply changes.
- **Cluster Autoscaler (CA):** Scales the K8s cluster *Nodes* (VMs). 

**How it works together:** HPA scales up Pods -> Cluster runs out of CPU/Memory -> Pods go to `Pending` state -> Cluster Autoscaler notices Pending Pods and provisions a new Node.

**Interview point:** Differentiate clearly: HPA = more Pods, VPA = bigger Pods, CA = more Nodes.

---

### Q19. What are the key components of Kubernetes observability? 🟠 IMPORTANT

**Answer:** Observability relies on logs, metrics, and traces.

**How it works:** 
- **Logging:** `kubectl logs` for ad-hoc. For production, a centralized stack like EFK (Elasticsearch, Fluentd, Kibana) or Loki.
- **Monitoring & Alerting:** Prometheus (scrapes K8s and app metrics) + Grafana (dashboards) + Alertmanager.
- **Tracing:** Jaeger or OpenTelemetry to trace requests across microservices.

**Interview point:** Emphasize that K8s nodes are ephemeral; logs inside containers are lost on crash. Centralized logging is mandatory.

---

### Q20. 🎯 SCENARIO: You need to perform maintenance on a Node. How do you do it safely?

**Answer:** You must Cordon and Drain the node.

**How it works:** 
1. `kubectl cordon <node>`: Marks node as unschedulable (no new Pods).
2. `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data`: Evicts existing Pods gracefully. K8s will reschedule them on other nodes.
3. Perform maintenance.
4. `kubectl uncordon <node>`: Allows scheduling again.

**Interview point:** Mention that PDBs (PodDisruptionBudgets) are respected by the `drain` command, preventing you from accidentally taking down an entire service.

---

### Q21. 🎯 SCENARIO: Your app needs to handle sudden traffic spikes automatically.

**Answer:** Implement HPA combined with Cluster Autoscaler.

**How it works:** Configure HPA to scale on CPU or custom metrics (e.g., incoming HTTP requests). As traffic spikes, HPA schedules more Pods. If the nodes are full, Cluster Autoscaler provisions new underlying VMs. 

**Interview point:** Mention that scaling nodes takes time (1-3 minutes). If spikes are instant, you might need to "overprovision" resources slightly to handle the burst while nodes boot.

---

### Q22. 🎯 SCENARIO: A bad deployment caused production downtime. How do you ensure zero-downtime next time?

**Answer:** Ensure RollingUpdate is configured correctly with Readiness probes.

**How it works:** A RollingUpdate relies entirely on the Readiness probe. If a Readiness probe is missing, K8s assumes the new Pod is ready immediately and kills the old one, leading to downtime if the app takes 10 seconds to boot. 

**Interview point:** "No Readiness probe = No zero downtime." This is a classic trap interviewers look for.

---

### Q23. What are your top Kubernetes Production Best Practices? ⭐ MUST KNOW

**Answer & Interview point:** (Rapid fire list for interviews)
1. **Always set resource requests and limits** (prevents noisy neighbors and OOM kills).
2. **Use Liveness and Readiness probes** (self-healing and safe deployments).
3. **Use PodDisruptionBudgets (PDB)** (protects during node drains).
4. **Run containers as non-root** (security context).
5. **Use HPA** for auto-scaling.
6. **Use Namespaces & RBAC** (least privilege access).
7. **Use Helm or GitOps (ArgoCD)** (declarative, reproducible deployments).
8. **Pin image tags** (Never use `:latest` in production).

---

## ⚡ Quick Reference: Production Commands

```bash
# Rollouts
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>

# Node Maintenance
kubectl cordon <node>
kubectl drain <node> --ignore-daemonsets
kubectl uncordon <node>

# Helm
helm install <release> <chart> -f values.yaml
helm upgrade --install <release> <chart> -f values.yaml
helm rollback <release> <revision>
helm template <release> <chart> # Dry run rendering
```
