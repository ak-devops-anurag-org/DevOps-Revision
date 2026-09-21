# Scheduling & Resources — Interview Revision

> Covers: Scheduler, requests/limits, QoS, affinity, taints/tolerations, PDB, resource management.

## Kubernetes Scheduler

### Q1. How does the Kubernetes Scheduler assign Pods to Nodes? ⭐ MUST KNOW

**Answer:**
The kube-scheduler watches for newly created Pods that have no Node assigned. It selects the optimal Node through a specific lifecycle: Filtering, Scoring, and Binding.

**How it works:**
1. **Filtering (Predicates):** Filters out nodes that don't meet the Pod's requirements (e.g., lack of resources, taint mismatches, node selectors).
2. **Scoring (Priorities):** Ranks the remaining feasible nodes based on optimization rules (e.g., node resource utilization, image locality).
3. **Binding:** Assigns the Pod to the highest-scoring Node by notifying the API server.

**Interview point:**
Be prepared to explain what happens if no node matches during filtering: the Pod stays in the `Pending` state.

---

### Q2. What factors does the scheduler consider during the Filtering phase? 🟠 IMPORTANT

**Answer:**
The scheduler checks hard constraints to ensure a node is capable of running the Pod.

**How it works:**
Key factors include:
- **Resource Requests:** Does the node have enough allocatable CPU/Memory?
- **Taints and Tolerations:** Does the node have a taint that the Pod doesn't tolerate?
- **Node Affinity/nodeSelector:** Does the node match the Pod's node selection rules?
- **Port Conflicts:** Are the requested host ports available?

**Interview point:**
Interviewers often ask why a Pod is Pending. The answer is almost always a failure in one of these filtering checks.

---

### Q3. What is a Custom Scheduler and when would you use it?

**Answer:**
Kubernetes allows you to run multiple schedulers simultaneously alongside the default scheduler. You can specify which scheduler a Pod should use via the `schedulerName` field.

**How it works:**
You deploy a custom scheduler as another Pod in the cluster. If a Pod spec defines `schedulerName: my-custom-scheduler`, the default scheduler ignores it, and your custom scheduler takes over the placement logic.

**Interview point:**
Used for highly specialized workloads requiring unique placement logic (e.g., advanced GPU scheduling or strict regulatory compliance placement) that the default scheduler cannot handle.

---

## Resource Management

### Q4. What is the difference between Resource Requests and Limits? ⭐ MUST KNOW

**Answer:**
Requests guarantee minimum resources, while Limits restrict the maximum resources a container can consume.

**How it works:**
| Feature | Requests | Limits |
|---------|----------|--------|
| **Definition** | Minimum guaranteed resources | Maximum allowed resources |
| **Used by** | Scheduler (for node placement) | Kubelet/container runtime (for enforcement) |
| **Effect** | Node must have enough *allocatable* capacity | Container is throttled or killed if exceeded |

**Interview point:**
A node might physically have resources, but if its *allocatable* resources minus the *sum of all existing Pod requests* is less than your new Pod's request, the Pod won't schedule there.

---

### Q5. How do CPU and Memory behave differently when Limits are exceeded? ⭐ MUST KNOW

**Answer:**
CPU is a compressible resource, while memory is incompressible. 

**How it works:**
| Resource | Over Limit Behavior | Under-Provisioned Behavior |
|----------|---------------------|----------------------------|
| **CPU** | Container is throttled (performance degrades) | Slow performance |
| **Memory**| Container is OOMKilled (Exit Code 137) | Potential node pressure / Pod eviction |

**Interview point:**
If an interviewer asks "My app is restarting with exit code 137, what's wrong?", immediately state that the container is hitting its memory limit and getting OOMKilled.

---

### Q6. What are Quality of Service (QoS) Classes in Kubernetes? 🟠 IMPORTANT

**Answer:**
QoS classes determine the priority of Pods when a Node experiences resource pressure and needs to evict Pods to recover.

**How it works:**
1. **Guaranteed:** `requests == limits` for all resources on all containers. Highest priority, last to be evicted.
2. **Burstable:** Requests are set, but are less than limits (or some containers don't have limits). Medium priority.
3. **BestEffort:** No requests or limits set. Lowest priority, first to be evicted.

**Interview point:**
For production databases or critical apps, always ensure they are in the `Guaranteed` QoS class to prevent arbitrary evictions.

---

### Q7. What is a ResourceQuota? 🟠 IMPORTANT

**Answer:**
A ResourceQuota provides constraints that limit aggregate resource consumption per Namespace.

**How it works:**
It can limit:
- Total CPU and Memory requests/limits across all Pods in the namespace.
- Total object counts (e.g., max 10 Pods, max 5 Services, max 2 LoadBalancers).

**Interview point:**
Crucial for multi-tenant clusters. It prevents one team or application from consuming the entire cluster's capacity.

---

### Q8. What is a LimitRange and how does it differ from ResourceQuota?

**Answer:**
While ResourceQuota limits the *namespace total*, LimitRange sets constraints and defaults for *individual Pods/Containers* within a namespace.

**How it works:**
- Enforces min/max resource limits per container.
- Automatically injects default requests and limits if a developer forgets to specify them in the Pod spec.

**Interview point:**
Use LimitRange to ensure no one deploys a container requesting 100 CPUs, and use ResourceQuota to ensure the whole team doesn't exceed 500 CPUs total.

---

## Scheduling Controls

### Q9. What is a nodeSelector?

**Answer:**
`nodeSelector` is the simplest form of node selection constraint. It relies on node labels.

**How it works:**
In the Pod spec, you define key-value pairs (e.g., `disktype: ssd`). The scheduler will only place the Pod on a node that has this exact label.

**Interview point:**
It's simple but lacks expressiveness (no "OR" or "NOT" operators). Modern deployments favor Node Affinity.

---

### Q10. What is Node Affinity and how is it better than nodeSelector? ⭐ MUST KNOW

**Answer:**
Node Affinity allows you to constrain which nodes your Pod is eligible to be scheduled on, with much greater expressiveness than `nodeSelector`.

**How it works:**
It supports two types:
- `requiredDuringSchedulingIgnoredDuringExecution`: Hard requirement. Pod *must* be on a matching node.
- `preferredDuringSchedulingIgnoredDuringExecution`: Soft preference. Scheduler *tries* to place it there, but will schedule elsewhere if impossible.
Supports operators: `In, NotIn, Exists, DoesNotExist, Gt, Lt`.

**Interview point:**
"IgnoredDuringExecution" means if a node's label changes after the Pod is running, the Pod is NOT evicted.

---

### Q11. What are Pod Affinity and Pod Anti-Affinity? ⭐ MUST KNOW

**Answer:**
They allow you to constrain which nodes your Pod is eligible to be scheduled on based on labels of *other Pods* already running on that node, rather than node labels.

**How it works:**
- **Pod Affinity (Co-locate):** Schedule this Pod on the same node/zone as another specific Pod (e.g., put web frontend near its cache).
- **Pod Anti-Affinity (Spread):** Prevent this Pod from scheduling on the same node/zone as another specific Pod (e.g., don't put two replicas of the same DB on one node).

**Interview point:**
The `topologyKey` (like `kubernetes.io/hostname` or `topology.kubernetes.io/zone`) determines the domain. Anti-affinity with hostname spreads pods across nodes; with zone, it spreads across AZs for high availability.

---

### Q12. What are Taints and Tolerations? ⭐ MUST KNOW

**Answer:**
Taints are applied to Nodes to *repel* Pods. Tolerations are applied to Pods to *allow* them to schedule on tainted nodes.

**How it works:**
A node taint has a key, value, and effect.
Effects:
- `NoSchedule`: Hard block for new pods.
- `PreferNoSchedule`: Soft block for new pods.
- `NoExecute`: Evicts existing running pods that do not have a matching toleration.

**Interview point:**
Remember this core rule: **Taints REPEL, Affinity ATTRACTS.** Taints are for dedicating nodes (e.g., GPU nodes, control-plane nodes), while Affinity is for attracting specific workloads to nodes.

---

### Q13. If a node has a Taint, but a Pod has a matching Toleration AND a Node Affinity for a different node, where does it go?

**Answer:**
The Pod will go to the node specified by the Node Affinity.

**How it works:**
Tolerations do *not* attract Pods to a node; they merely "unlock" a tainted node, making it feasible. The scheduler then uses Affinity rules and Scoring to make the final placement decision.

**Interview point:**
This is a common trick question to see if you understand that tolerations grant permission, but don't dictate placement.

---

### Q14. Comparison of Scheduling Mechanisms 🟠 IMPORTANT

**Answer:**
A quick summary of what mechanism to use when.

**How it works:**
| Mechanism | Applied To | Purpose |
|-----------|-----------|----------|
| **nodeSelector** | Pod | Select specific nodes (simple exact match) |
| **Node Affinity** | Pod | Select specific nodes (expressive, hard/soft rules) |
| **Pod Affinity** | Pod | Co-locate with other specific Pods |
| **Pod Anti-Affinity**| Pod | Spread away from other specific Pods |
| **Taint** | Node | Repel Pods from this node |
| **Toleration** | Pod | Allow this Pod to ignore a node's taint |

**Interview point:**
Use this table to quickly map a scenario to a technical solution.

---

## PodDisruptionBudget (PDB)

### Q15. What is a PodDisruptionBudget (PDB)? 🟠 IMPORTANT

**Answer:**
A PDB limits the number of Pods of a replicated application that can go down simultaneously due to *voluntary* disruptions.

**How it works:**
You specify either `minAvailable` (e.g., always keep 2 replicas running) or `maxUnavailable` (e.g., allow at most 1 replica to be down).
When a cluster admin runs `kubectl drain` for node maintenance, the eviction API checks the PDB. If evicting the Pod violates the PDB, the drain operation is blocked until a new Pod spins up elsewhere.

**Interview point:**
PDBs protect against **voluntary** disruptions (node drains, cluster upgrades). They CANNOT protect against **involuntary** disruptions (hardware failure, kernel panic, node crash).

---

### Q16. Can a PDB prevent a node from shutting down?

**Answer:**
It prevents a graceful `kubectl drain`, but it cannot stop a hard shutdown or physical failure.

**How it works:**
If an admin forcefully deletes pods or shuts down the VM, the PDB is bypassed. PDB relies on the Kubernetes Eviction API.

**Interview point:**
Always highlight that PDB is about safe, coordinated maintenance, not disaster prevention.

---

## Scenario Questions

### Q17. 🎯 SCENARIO: Pod stuck in Pending State

**Problem:** You deployed a Deployment, but `kubectl get pods` shows the Pods in `Pending` state.

**Likely causes:** 
- Insufficient CPU or Memory allocatable on any node.
- No node matches the Pod's `nodeSelector` or `NodeAffinity`.
- All nodes have taints that the Pod does not tolerate.
- PersistentVolumeClaim (PVC) cannot be provisioned or bound.

**Commands:**
`kubectl describe pod <pod-name>` (Check the Events section for scheduler errors).

**Resolution:**
Lower resource requests, add a new node to the cluster, fix affinity labels, or add the necessary toleration.

---

### Q18. 🎯 SCENARIO: Node has free CPU, but Pod isn't scheduled

**Problem:** You have a node with 4 CPUs free. Your Pod requests 1 CPU, but remains Pending.

**Likely causes:**
- The node might have a taint (e.g., `node-role.kubernetes.io/master:NoSchedule`).
- The Pod has a `nodeSelector` that doesn't match this node's labels.
- The Node has sufficient CPU, but lacks sufficient *Memory* for the Pod's memory request.

**Commands:**
`kubectl describe node <node-name>` (Check Taints, Labels, and Allocatable resources).
`kubectl describe pod <pod-name>` (Read the scheduler failure reason).

**Resolution:**
Add the missing label to the node, add a toleration to the Pod, or check memory requirements.

---

### Q19. 🎯 SCENARIO: Pod gets OOMKilled

**Problem:** A Pod's status shows `OOMKilled` (Exit Code 137).

**Likely causes:**
The application consumed more memory than the `limits.memory` specified in the container spec. The Linux kernel's OOM killer terminated the process.

**Commands:**
`kubectl describe pod <pod-name>` (Check State: Terminated, Reason: OOMKilled).
`kubectl logs <pod-name> --previous` (Check for application memory leaks).

**Resolution:**
Increase the memory limit in the Pod spec, or profile the application code to fix the memory leak.

---

### Q20. 🎯 SCENARIO: Pod Evicted due to Node Pressure

**Problem:** Your Pod suddenly restarts, and you see an `Evicted` status in the cluster.

**Likely causes:**
The Node ran out of physical memory or disk space (Node Pressure). The kubelet started evicting Pods to reclaim resources, starting with `BestEffort` QoS Pods, then `Burstable` Pods exceeding their requests.

**Commands:**
`kubectl get events --sort-by='.metadata.creationTimestamp'` (Look for node pressure events).

**Resolution:**
Set appropriate resource Requests and Limits to ensure your critical Pod gets `Guaranteed` QoS, protecting it from eviction.

---

### Q21. 🎯 SCENARIO: High Availability during Node Maintenance

**Problem:** You need to upgrade the OS on all worker nodes. You have an app with 3 replicas. How do you ensure no downtime?

**Likely causes/Setup:**
Nodes will be drained one by one. If all 3 replicas happen to be on one node, draining it causes total downtime.

**Resolution Strategy:**
1. Implement **Pod Anti-Affinity** (topologyKey: hostname) so the 3 replicas are spread across 3 different nodes.
2. Create a **PodDisruptionBudget** with `maxUnavailable: 1` to ensure the eviction API only drains one node's Pod at a time, waiting for it to reschedule before continuing.
3. Run `kubectl drain <node-name> --ignore-daemonsets`.

---

### Q22. 🎯 SCENARIO: Dedicated GPU Nodes

**Problem:** You have expensive GPU nodes. You want ONLY machine learning Pods to run on them, and they must run nowhere else.

**Resolution Strategy:**
1. **Taint the GPU nodes:** `kubectl taint nodes gpu-node gpu=true:NoSchedule`. (Keeps normal web pods away).
2. **Add Toleration to ML Pods:** Allow ML pods to tolerate `gpu=true:NoSchedule`.
3. **Add Node Affinity to ML Pods:** Use Node Affinity (or nodeSelector) to force the ML pods onto the GPU nodes. (Without this, ML pods might schedule on standard worker nodes).

---

# Quick Reference
- **Pending?** -> `kubectl describe pod` -> Check resources, taints, affinity.
- **OOMKilled?** -> Memory limit hit (Exit 137).
- **Throttled?** -> CPU limit hit.
- **Evicted?** -> Node out of resources -> check QoS (Guaranteed > Burstable > BestEffort).
- **Taints** = Repel.
- **Affinity** = Attract/Spread.
