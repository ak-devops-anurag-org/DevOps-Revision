# Kubernetes Troubleshooting — Interview Revision

> Production troubleshooting scenarios for DevOps/SRE interviews.
> Covers: Pod issues, Service issues, Node issues, Ingress, Storage, Configuration, and Probes.

## Troubleshooting Methodology

```
Observe (what's the symptom?)
    ↓
Identify component (Pod, Service, Node, Ingress?)
    ↓
Check status (kubectl get)
    ↓
Check details (kubectl describe)
    ↓
Check events (kubectl get events)
    ↓
Check logs (kubectl logs)
    ↓
Check configuration (YAML, ConfigMap, Secret)
    ↓
Test connectivity (kubectl exec, curl, nslookup)
    ↓
Fix
    ↓
Verify
```

## Essential Troubleshooting Commands

```bash
kubectl get pods -n <ns> -o wide
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns>
kubectl logs <pod> -n <ns> --previous
kubectl logs <pod> -c <container> -n <ns>
kubectl get events -n <ns> --sort-by='.lastTimestamp'
kubectl exec -it <pod> -n <ns> -- /bin/sh
kubectl top pods -n <ns>
kubectl top nodes
kubectl get endpoints <svc> -n <ns>
kubectl get nodes
kubectl describe node <node>
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
```

---

## 🎯 Scenario 1: Pod stuck in Pending

**Problem:**
Pod stays in the `Pending` state indefinitely.

**First checks:**
```bash
kubectl get events -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

**Likely causes:**
- No node has enough resources (CPU/Memory).
- Taint/Toleration mismatch.
- NodeAffinity/NodeSelector pointing to a non-existent label.
- PVC cannot be bound.

**Troubleshooting steps:**
1. Check `Events` in `kubectl describe pod` for scheduling failures.
2. Verify node capacity and available resources: `kubectl top nodes` / `kubectl describe nodes`.
3. Check PVC status if applicable: `kubectl get pvc`.

**Resolution:**
Scale up nodes, lower pod requests, fix taints/labels, or resolve PVC issues.

---

## 🎯 Scenario 2: Pod in CrashLoopBackOff

**Problem:**
Container starts, crashes, and Kubernetes tries to restart it repeatedly.

**First checks:**
```bash
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous
```

**Likely causes:**
- Application panic/exception during startup.
- Missing environment variables or configuration files.
- Command or args specified incorrectly.
- Port binding conflict inside the container.

**Troubleshooting steps:**
1. Check current and previous logs for stack traces or error messages.
2. Verify ConfigMaps and Secrets are properly mounted and have the right values.
3. Check `kubectl describe pod` for exit codes.

**Resolution:**
Fix application code/config, correct environment variables, or fix container entrypoint.

---

## 🎯 Scenario 3: Pod in ImagePullBackOff / ErrImagePull

**Problem:**
Kubernetes cannot pull the container image.

**First checks:**
```bash
kubectl describe pod <pod-name> -n <namespace>
```

**Likely causes:**
- Image name or tag is misspelled.
- Image registry is private and imagePullSecrets are missing/incorrect.
- Registry is down or network issues from the Node.

**Troubleshooting steps:**
1. Read the `Events` section in `describe pod` to see the exact pull error.
2. Manually try to `docker pull` or `crictl pull` the image on the node.
3. Verify `imagePullSecrets` in the pod spec.

**Resolution:**
Correct the image name/tag, create/attach correct Secret for private registry, or fix network to registry.

---

## 🎯 Scenario 4: Pod in OOMKilled (exit code 137)

**Problem:**
Pod gets killed because it exceeded its memory limit.

**First checks:**
```bash
kubectl describe pod <pod-name> -n <namespace>
```

**Likely causes:**
- Memory leak in the application.
- Traffic spike requiring more memory.
- Memory limits in the Pod spec are set too low.

**Troubleshooting steps:**
1. Check `State: Terminated` with `Reason: OOMKilled` in pod description.
2. Monitor memory usage trends using `kubectl top pod` or Prometheus/Grafana.
3. Check application memory profiling.

**Resolution:**
Increase the `limits.memory` in the pod spec, or fix the application memory leak.

---

## 🎯 Scenario 5: Pod Evicted

**Problem:**
Pod is forcibly removed from a node by kubelet.

**First checks:**
```bash
kubectl describe pod <pod-name> -n <namespace>
```

**Likely causes:**
- Node ran out of memory, disk space, or inodes (Resource pressure).
- Pod priority preemption.

**Troubleshooting steps:**
1. Check the reason in `describe pod` events.
2. Check node health: `kubectl describe node <node-name>`.

**Resolution:**
Clean up node resources (e.g., prune images), scale up cluster, or ensure proper resource requests/limits on all pods.

---

## 🎯 Scenario 6: Container starts and exits immediately (exit code 0 or 1)

**Problem:**
Pod says Completed (exit 0) or Error (exit 1) repeatedly for a background service.

**First checks:**
```bash
kubectl logs <pod-name> -n <namespace>
```

**Likely causes:**
- Container process finishes quickly (e.g., running `echo` or a brief script).
- Entrypoint is incorrect and doesn't run as a daemon.

**Troubleshooting steps:**
1. Check what the container entrypoint/CMD is.
2. Look at logs to see if it ran to completion successfully.

**Resolution:**
Ensure the container runs a blocking foreground process (e.g., `tail -f /dev/null` or start a web server).

---

## 🎯 Scenario 7: Pod Running but application not responding

**Problem:**
Pod status is `Running` but `curl` to the pod IP or service fails.

**First checks:**
```bash
kubectl logs <pod-name> -n <namespace>
kubectl exec -it <pod-name> -- curl 127.0.0.1:<port>
```

**Likely causes:**
- App listening on `127.0.0.1` instead of `0.0.0.0`.
- Application deadlocked or hanging.
- Port mismatch between app and container spec.

**Troubleshooting steps:**
1. Check logs for deadlocks.
2. Exec into the pod and test local reachability.
3. Verify application binding interface.

**Resolution:**
Change app config to listen on `0.0.0.0`, restart pod, or correct port mapping.

---

## 🎯 Scenario 8: Pod stuck in Terminating

**Problem:**
Pod remains in Terminating state for a long time.

**First checks:**
```bash
kubectl get pod <pod-name> -n <namespace> -o yaml
```

**Likely causes:**
- Finalizers on the pod prevent deletion.
- Node is dead and unreachable by the master.
- Unresponsive volume unmount.

**Troubleshooting steps:**
1. Check for `finalizers` in the yaml.
2. Check if the underlying node is `NotReady`.

**Resolution:**
Remove finalizers manually (edit pod), fix the node, or force delete: `kubectl delete pod <name> --grace-period=0 --force`.

---

## 🎯 Scenario 9: Service not reaching Pods (no traffic flowing)

**Problem:**
Cannot access application via ClusterIP or NodePort.

**First checks:**
```bash
kubectl get endpoints <service-name> -n <namespace>
```

**Likely causes:**
- Service selectors don't match pod labels.
- Pods are failing readiness probes.
- Target port is incorrect.

**Troubleshooting steps:**
1. Ensure Endpoints list is not empty.
2. Compare `Service` selector with `Pod` labels.
3. Verify Pods are `Ready` (Ready condition = True).

**Resolution:**
Correct labels/selectors, fix readiness probe, or fix the `targetPort` in the Service.

---

## 🎯 Scenario 10: Service has no endpoints

**Problem:**
`kubectl get endpoints <svc>` shows `<none>`.

**First checks:**
```bash
kubectl get svc <service-name> -o yaml
kubectl get pods --show-labels
```

**Likely causes:**
- Label selector typo in Service.
- No pods exist with those labels.

**Troubleshooting steps:**
1. Get the selector from the service: `kubectl get svc <svc> -o jsonpath='{.spec.selector}'`.
2. Search for matching pods: `kubectl get pods -l <key>=<value>`.

**Resolution:**
Align the Service selector and Pod labels perfectly.

---

## 🎯 Scenario 11: DNS resolution failing inside Pod

**Problem:**
Pod cannot resolve `kubernetes.default.svc.cluster.local` or external domains.

**First checks:**
```bash
kubectl exec -it <pod-name> -- nslookup kubernetes.default
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

**Likely causes:**
- CoreDNS pods are crashing or down.
- Node network misconfiguration blocking DNS traffic.
- Custom `dnsPolicy` in Pod spec.

**Troubleshooting steps:**
1. Check CoreDNS pods logs in `kube-system`.
2. Check if the Pod's `/etc/resolv.conf` is pointing to the CoreDNS service IP.

**Resolution:**
Fix CoreDNS pods, correct network overlays (CNI), or adjust `dnsPolicy`.

---

## 🎯 Scenario 12: Pod can resolve DNS but cannot connect

**Problem:**
`nslookup google.com` works, but `curl https://google.com` times out.

**First checks:**
```bash
kubectl exec -it <pod-name> -- curl -I https://google.com
```

**Likely causes:**
- Egress blocked by NetworkPolicy.
- SNAT/Masquerade issues on the node or CNI.
- External firewall blocking node IPs.

**Troubleshooting steps:**
1. Check NetworkPolicies in the namespace.
2. Test connectivity from the node itself.

**Resolution:**
Add allow egress NetworkPolicy, fix CNI routing/SNAT rules, or whitelist node IPs in external firewall.

---

## 🎯 Scenario 13: NetworkPolicy blocking traffic

**Problem:**
Microservice A cannot talk to Microservice B.

**First checks:**
```bash
kubectl get netpol -n <namespace>
```

**Likely causes:**
- Default deny policy is active without an explicit allow.
- Incorrect labels in podSelector or namespaceSelector.
- Wrong ports specified in the policy.

**Troubleshooting steps:**
1. Describe the policies applied to the target pod.
2. Verify labels of source pods/namespaces.

**Resolution:**
Create or fix the NetworkPolicy to explicitly allow ingress from Service A to Service B on the right port.

---

## 🎯 Scenario 14: ClusterIP works but external access fails

**Problem:**
Can curl Service internally, but Ingress/LoadBalancer fails.

**First checks:**
```bash
kubectl get svc <svc-name>
kubectl get ingress
```

**Likely causes:**
- LoadBalancer pending (Cloud provider issue).
- Ingress misconfigured (wrong path, wrong service name).
- NodePort blocked by security groups.

**Troubleshooting steps:**
1. Check LoadBalancer external IP status.
2. Check Ingress controller logs.

**Resolution:**
Fix cloud IAM permissions for LoadBalancer creation, or fix Ingress rule paths.

---

## 🎯 Scenario 15: Ingress returning 404

**Problem:**
Accessing URL via Ingress returns 404 Not Found.

**First checks:**
```bash
kubectl describe ingress <ingress-name> -n <namespace>
```

**Likely causes:**
- Hostname doesn't match Ingress rules.
- Path rule misconfigured (e.g., missing regex or rewrite).
- Ingress class not specified or wrong.

**Troubleshooting steps:**
1. Check Ingress controller logs to see which rule matched.
2. Ensure the `Host` header in the request matches the Ingress spec.

**Resolution:**
Correct the Ingress path/host, or add proper rewrite annotations (e.g., nginx rewrite-target).

---

## 🎯 Scenario 16: Ingress returning 502 Bad Gateway

**Problem:**
Ingress returns 502 Bad Gateway when accessed.

**First checks:**
```bash
kubectl logs -n <ingress-namespace> <ingress-controller-pod>
```

**Likely causes:**
- Application is listening on a different port than the Service targetPort.
- Service points to pods, but application is dead/refusing connections.
- Application returning invalid HTTP responses.

**Troubleshooting steps:**
1. Bypass Ingress and test Service directly.
2. Check Ingress controller logs for upstream connection refused.

**Resolution:**
Match the Service `targetPort` with the container port. Ensure app is healthy.

---

## 🎯 Scenario 17: Ingress returning 503 Service Unavailable

**Problem:**
Ingress returns 503 Service Unavailable.

**First checks:**
```bash
kubectl get endpoints <service-name>
```

**Likely causes:**
- No endpoints exist for the service.
- All pods are failing readiness probes.

**Troubleshooting steps:**
1. Verify pods are running and Ready.
2. Verify Service selector.

**Resolution:**
Fix the underlying application so pods become Ready, or fix Service selectors.

---

## 🎯 Scenario 18: Node in NotReady state

**Problem:**
`kubectl get nodes` shows a node as `NotReady`.

**First checks:**
```bash
kubectl describe node <node-name>
```

**Likely causes:**
- Kubelet service crashed on the node.
- Node ran out of resources (disk/memory) causing kubelet to hang.
- Network partition between node and API server.

**Troubleshooting steps:**
1. SSH into the node and run `systemctl status kubelet`.
2. Check `/var/log/syslog` or `journalctl -u kubelet`.

**Resolution:**
Restart kubelet, clean up disk space, or fix node networking.

---

## 🎯 Scenario 19: Node has DiskPressure / MemoryPressure

**Problem:**
Pods are evicted and node status shows pressure conditions.

**First checks:**
```bash
kubectl describe node <node-name>
```

**Likely causes:**
- Log files or container images filling up disk.
- Unbounded pods consuming all memory.

**Troubleshooting steps:**
1. Check Node conditions in `describe node`.
2. SSH to node and check `df -h` and `free -m`.

**Resolution:**
Prune unused docker images (`crictl rmi -a`), configure log rotation, or apply ResourceQuotas.

---

## 🎯 Scenario 20: Deployment rollout stuck (not progressing)

**Problem:**
`kubectl rollout status` hangs and new pods are not replacing old ones.

**First checks:**
```bash
kubectl describe deployment <deployment-name>
kubectl get rs
```

**Likely causes:**
- New ReplicaSet pods are failing to start (CrashLoop, Pending).
- MaxUnavailable/MaxSurge strategy misconfigured.
- Resource quota exceeded.

**Troubleshooting steps:**
1. Check the new ReplicaSet and describe its pods.
2. Fix whatever is preventing new pods from becoming Ready.

**Resolution:**
Fix the image/config of the new version, scale cluster, or adjust rollout strategy.

---

## 🎯 Scenario 21: Deployment shows desired replicas but pods not created

**Problem:**
Deployment says 3 replicas desired, but `get pods` shows 0.

**First checks:**
```bash
kubectl describe rs <replicaset-name>
```

**Likely causes:**
- ServiceAccount missing or RBAC issues (often in Operators/Helm).
- Namespace ResourceQuota exceeded.
- API server issues preventing ReplicaSet controller from creating pods.

**Troubleshooting steps:**
1. Look at ReplicaSet events for creation failures.
2. Check namespace quotas: `kubectl get resourcequota`.

**Resolution:**
Increase ResourceQuota or fix RBAC permissions for the Deployment.

---

## 🎯 Scenario 22: PVC stuck in Pending

**Problem:**
PersistentVolumeClaim remains `Pending`.

**First checks:**
```bash
kubectl describe pvc <pvc-name>
```

**Likely causes:**
- No matching PV available.
- StorageClass missing or incorrect.
- Dynamic provisioner failing (e.g., AWS EBS CSI driver down).

**Troubleshooting steps:**
1. Check `Events` in PVC description.
2. Check if the StorageClass exists: `kubectl get sc`.
3. Check CSI provisioner logs.

**Resolution:**
Create matching PV, fix StorageClass name, or repair CSI driver.

---

## 🎯 Scenario 23: Pod cannot mount volume (FailedMount)

**Problem:**
Pod stays in ContainerCreating and events show `FailedMount`.

**First checks:**
```bash
kubectl describe pod <pod-name>
```

**Likely causes:**
- ConfigMap or Secret being mounted doesn't exist.
- EBS/Disk already attached to a different node.
- Node missing mount utilities (like nfs-common).

**Troubleshooting steps:**
1. Check exact volume name failing in events.
2. Verify ConfigMap/Secret exists in the same namespace.
3. Check cloud console for stuck disk attachments.

**Resolution:**
Create the missing ConfigMap/Secret, force detach cloud volume, or install required mount packages on node.

---

## 🎯 Scenario 24: Pod cannot access Secret / ConfigMap

**Problem:**
Application errors out missing configuration files.

**First checks:**
```bash
kubectl get secret <secret-name> -n <namespace>
```

**Likely causes:**
- Typo in Secret/ConfigMap name in Pod spec.
- Secret/ConfigMap is in a different namespace.
- Keys inside ConfigMap don't match volume mount paths or env var keys.

**Troubleshooting steps:**
1. Exec into pod and `ls` the mount directory.
2. Compare YAML keys with app expectations.

**Resolution:**
Fix typos, ensure resources are in the same namespace, or update keys.

---

## 🎯 Scenario 25: Environment variable not set in container

**Problem:**
App crashes saying required env var is missing.

**First checks:**
```bash
kubectl exec -it <pod-name> -- env
```

**Likely causes:**
- `envFrom` pointing to wrong ConfigMap.
- Value not properly quoted in YAML (e.g., boolean vs string).

**Troubleshooting steps:**
1. Check pod describe for environment variable sources.
2. Check the raw ConfigMap YAML.

**Resolution:**
Quote values in ConfigMap (e.g., `"true"`), or fix the reference in the Pod spec.

---

## 🎯 Scenario 26: Private registry authentication failure

**Problem:**
ErrImagePull with "unauthorized" or "authentication required".

**First checks:**
```bash
kubectl get secret <secret-name> --type=kubernetes.io/dockerconfigjson
```

**Likely causes:**
- Secret doesn't exist or is in the wrong namespace.
- Pod spec missing `imagePullSecrets`.
- Token/Password in the secret expired.

**Troubleshooting steps:**
1. Decode the secret data to check credentials: `echo <base64> | base64 -d`.
2. Verify `imagePullSecrets` array in pod spec.

**Resolution:**
Recreate the docker-registry secret with valid credentials and attach it to the pod or service account.

---

## 🎯 Scenario 27: Image tag not found

**Problem:**
ImagePullBackOff with "manifest unknown".

**First checks:**
```bash
kubectl describe pod <pod>
```

**Likely causes:**
- Using `latest` tag that was deleted.
- CI/CD pipeline failed to push the image but updated deployment anyway.
- Typo in the tag name.

**Troubleshooting steps:**
1. Check registry UI/CLI to verify the tag exists.
2. Fix the deployment image tag.

**Resolution:**
Deploy a tag that actually exists in the registry.

---

## 🎯 Scenario 28: Liveness probe failing — container keeps restarting

**Problem:**
Pod is Running but restart count keeps increasing.

**First checks:**
```bash
kubectl describe pod <pod-name>
```

**Likely causes:**
- Liveness probe path (e.g., `/health`) is wrong or returning 500.
- `initialDelaySeconds` is too short, probing before app starts.
- App is under heavy load and timing out.

**Troubleshooting steps:**
1. Look for `Liveness probe failed` in pod Events.
2. Exec into the pod and manually run the probe command/curl.

**Resolution:**
Increase `initialDelaySeconds`, `timeoutSeconds`, or fix the application health endpoint.

---

## 🎯 Scenario 29: Readiness probe failing — Pod Running but not receiving traffic

**Problem:**
Pod is Running but Ready column shows `0/1`. No traffic routed.

**First checks:**
```bash
kubectl describe pod <pod-name>
```

**Likely causes:**
- Application takes a long time to warm up.
- Readiness probe depends on a down external database.
- Probe port is wrong.

**Troubleshooting steps:**
1. Look for `Readiness probe failed` in Events.
2. Check application logs for initialization errors (e.g., DB connection failed).

**Resolution:**
Fix backend dependencies (DB), or correct the probe port/path.

---

## 🎯 Scenario 30: High CPU usage / throttling

**Problem:**
Application is slow, latency is high.

**First checks:**
```bash
kubectl top pods
```

**Likely causes:**
- CPU limits are set too low, causing kernel throttling (CFS quota).
- Infinite loop in application.
- Traffic spike.

**Troubleshooting steps:**
1. Check Prometheus/Grafana for CPU throttling metrics.
2. Compare `top` output against pod `limits.cpu`.

**Resolution:**
Increase CPU limits, remove CPU limits entirely (relying on requests), or profile the application code.

---

## Quick Troubleshooting Cheat Sheet

| Symptom | First Command | Likely Cause |
|---------|--------------|---------------|
| Pending | `kubectl describe pod` | Resource limits, Scheduling, Taints/Tolerations, PVC issue |
| CrashLoopBackOff | `kubectl logs --previous` | App crash, missing config/env vars, wrong entrypoint |
| ImagePullBackOff | `kubectl describe pod` | Typo in image name, Missing auth secret, Registry down |
| OOMKilled (Exit 137)| `kubectl describe pod` | App exceeded memory limits, Memory leak |
| Evicted | `kubectl describe pod` | Node out of memory/disk, Priority preemption |
| No Service Endpoints | `kubectl get endpoints` | Selector labels don't match pod labels |
| NotReady Node | `kubectl describe node` | Kubelet crash, DiskPressure, Network partition |
| FailedMount | `kubectl describe pod` | Missing ConfigMap/Secret, EBS attach failure |
| Liveness Probe Fail | `kubectl describe pod` | App deadlocked, initialDelay too short, high load |
| 502/503 Ingress | `kubectl logs <ingress-pod>` | App crash, Port mismatch between Service and Container |
