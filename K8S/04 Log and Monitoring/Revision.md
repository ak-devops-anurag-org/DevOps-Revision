# Kubernetes Logging and Monitoring: Core Revision Notes

## 1. Basic Troubleshooting (Manual & Ephemeral)
These are your day-to-day commands for checking the immediate health of your cluster. 

* **Metrics Server:** An in-memory metric scraper. It collects CPU/Memory usage from the `kubelet` on each node. It does *not* store historical data.
* **Installation:** `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`
* **Key Commands:**
  * `kubectl top node` (Check if a node is running out of resources)
  * `kubectl top pod --sort-by=cpu` (Find CPU-heavy pods)

## 2. Managing Application Logs (`kubectl logs`)
Kubernetes expects your applications (frontend, backend, etc.) to print their logs to standard output (`stdout`) and standard error (`stderr`). 

**Crucial Log Commands:**
* `kubectl logs <pod-name>` : Get logs for a single-container pod.
* `kubectl logs -f <pod-name>` : Stream the logs live (like `tail -f`).
* `kubectl logs <pod-name> -c <container-name>` : Get logs from a specific container inside a multi-container pod (e.g., if you have an app container and a database container in one pod).
* `kubectl logs <pod-name> -p` : **Important!** Get logs from a *previous*, crashed instance of a pod. This is vital for finding out why a pod restarted.

## 3. Beyond Basics: The "Other Ways" (Production Standard)
Because pods die and logs are lost, production environments use a **Centralized Logging Architecture**. 

### A. The Node-Level Logging Agent Pattern
Instead of checking logs pod-by-pod, you deploy a logging agent on every single node (using the **DaemonSet** we revised in Section 3). 
1. Your apps write to `stdout`/`stderr`.
2. The container runtime (ContainerD) writes these to a log file on the Worker Node.
3. The Logging Agent (e.g., Fluentd, Promtail, or Logstash) reads these node-level files.
4. The Agent ships the logs to an external, permanent database.

*(Note: If you are running on a managed cloud platform like GKE, these node-level agents are usually pre-installed and route logs directly to services like Google Cloud Logging without you doing anything).*

### B. Industry Standard Stacks
You should know these names as they are the standard answers for "How do you monitor K8s?"

* **For Logging: The EFK/ELK Stack**
  * **E**lasticsearch (The database that stores the logs)
  * **F**luentd / Logstash (The DaemonSet agent that collects the logs)
  * **K**ibana (The UI dashboard to search and read the logs)
* **For Monitoring: Prometheus & Grafana**
  * **Prometheus:** A time-series database that continuously scrapes and stores metrics over time (unlike the basic Metrics Server).
  * **Grafana:** A visualization tool to build beautiful graphs and set up alerts (e.g., "Slack me if database CPU > 80%").

## 4. Kubernetes Events (Don't forget this!)
Logs tell you what happened *inside* the application. **Events** tell you what happened to the infrastructure (e.g., "Image pull failed," "Pod scheduled," "Node out of memory").
* **Command:** `kubectl get events --sort-by='.metadata.creationTimestamp'`