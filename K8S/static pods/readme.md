# Static Pods in Kubernetes

## What Are Static Pods?
**Static Pods** are special Pods managed directly by the kubelet on a specific node, rather than by the Kubernetes API server or control plane[1][7][9]. They are used to ensure critical system components (like the API server, etcd, controller-manager, and scheduler) can run even before or without a fully running Kubernetes control plane[2][9].

## Key Characteristics

- **Created and managed by kubelet**: Not scheduled or managed by the API server or kubectl commands[1][7][9].
- **YAML manifests**: Defined by plain Pod YAML files placed in a directory specified in the kubelet config (commonly `/etc/kubernetes/manifests/`)[1][3][7].
- **Node-specific**: Static Pods only run on the node where their manifest exists. To run the same static Pod on multiple nodes, you must place the manifest on each node separately[4][5].
- **Bootstraps the Control Plane**: Often used to run core cluster services before the control plane is fully available[2][5].
- **Mirror Pods**: When a control plane is present, kubelet creates a "mirror pod" on the API server for each static pod, making them visible with `kubectl get pods`, but not manageable via the API server or kubectl[1][4][5].
- **Direct management**: Cannot be created, deleted, or updated via kubectl or the Kubernetes API. Changes require editing (or removing) the manifest files on the node[1][4][7].
- **Survive API outages**: Will continue to run even if the API server is down[8][7].
- **Node name prefix**: Pod names include the node name as a prefix (e.g., `my-node_kube-apiserver-my-node`).

## Directory for Static Pods

- **Default manifest path**: `/etc/kubernetes/manifests/`
- The kubelet may be configured to watch a different directory via its configuration. Check `/var/lib/kubelet/config.yaml` for the `staticPodPath` option.

#### Example: Static pod manifest files
ls /etc/kubernetes/manifests/
etcd.yaml
kube-apiserver.yaml
kube-controller-manager.yaml
kube-scheduler.yaml


## Creating a Static Pod

1. **Write a Pod definition YAML** (similar to regular pods):

    ```
    apiVersion: v1
    kind: Pod
    metadata:
      name: my-static-pod
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
    ```

2. **Place the YAML file** in the kubelet’s manifest directory:

    ```
    sudo cp pod-definition.yaml /etc/kubernetes/manifests/
    ```

3. **Kubelet detects the file** and launches the pod immediately, independent of the API server[1][7].

## How to Find a Static Pod

If you see a pod running that isn’t controlled by a Deployment, DaemonSet, or ReplicaSet, but don’t see its manifest in `/etc/kubernetes/manifests/`, it may be running as a static pod from a different path on another node.

**Steps to locate:**
- Use:
    ```
    kubectl get pods --all-namespaces -o wide
    ```
  to identify the node the pod runs on.
- SSH to that node.
- Check the kubelet config to determine the manifest path:
    ```
    cat /var/lib/kubelet/config.yaml | grep staticPodPath
    ```
- Locate and edit/remove the static pod manifest in that directory.

## Limitations of Static Pods

- **Not scalable**: To run on more nodes, data must be manually copied.
- **No advanced scheduling**: Not aware of taints, tolerations, or cluster-wide scheduling logic.
- **No controllers/replicas**: No built-in health checks or rolling updates—changes are manual[3][7].
- **Limited API support**: The `spec` section can’t reference other Kubernetes objects like Secrets or ConfigMaps[1].
- **No owner references**: Describing the pod will show no ReplicaSet/Deployment ownership; status will be “managed by kubelet only”[1].

## Use Cases

- **Cluster bootstrapping**: Used to start essential control plane components during initial cluster setup[2][5].
- **Critical node-specific workloads**: For workloads needing direct and persistent presence on a node, even in API server outages[7].
- **Special monitoring/debugging**: Running node-level monitoring or debugging agents before the control plane is ready.

---

*Note: Use static pods only when regular Kubernetes constructs (like Deployments or DaemonSets) do not meet your needs, as static pods require more manual management and lack cluster-wide orchestration features[1][3][5].*
