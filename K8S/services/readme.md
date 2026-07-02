# Kubernetes Services Documentation

Kubernetes Services provide a stable way to access Pods running in a cluster. Since Pods are ephemeral and their IP addresses can change, Services act as an abstraction layer and ensure reliable communication.

There are three commonly used Service types:

- **ClusterIP** (default): Exposes the Service on a cluster-internal IP.
- **NodePort**: Exposes the Service on each Node’s IP at a static port.
- **LoadBalancer**: Provisions an external load balancer (available on cloud providers).

***

## ClusterIP Service

### Use Case

- Default service type.
- Used for **internal communication** between applications inside the cluster (e.g., frontend connecting to backend).
- Not accessible externally.


### Declarative (YAML)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-clusterip-service
  labels:
    app: svc-clusterip
    env: dev
spec:
  type: ClusterIP
  ports:
    - name: http
      port: 80
      targetPort: 80
  selector:
    run: nginx-pod
    env: dev
```


### Imperative Command

```bash
kubectl expose pod nginx-pod \
  --name=nginx-clusterip-service \
  --type=ClusterIP \
  --port=80 \
  --target-port=80
```


***

## NodePort Service

### Use Case

- Exposes an application **outside the cluster** on each node’s IP at a static port (range: 30000–32767).
- Useful for **development, testing, and demo setups**.
- Can be accessed as `http://<NodeIP>:<NodePort>`.


### Declarative (YAML)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport-service
  labels:
    app: svc-nodeport
    env: dev
spec:
  type: NodePort
  ports:
    - name: http
      port: 80
      targetPort: 80
      nodePort: 30001
  selector:
    run: nginx-pod
    env: dev
```


### Imperative Command

```bash
kubectl expose pod nginx-pod \
  --name=nginx-nodeport-service \
  --type=NodePort \
  --port=80 \
  --target-port=80 \
  --node-port=30001
```


***

## LoadBalancer Service

### Use Case

- Exposes the Service externally using a **cloud provider’s load balancer**.
- Suitable for **production workloads** with external traffic.
- Automatically provisions an external IP.
- Works with cloud providers like AWS, GCP, Azure.


### Declarative (YAML)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-loadbalancer-service
  labels:
    app: svc-loadbalancer
    env: dev
spec:
  type: LoadBalancer
  ports:
    - name: http
      port: 80
      targetPort: 80
  selector:
    run: nginx-pod
    env: dev
```


### Imperative Command

```bash
kubectl expose pod nginx-pod \
  --name=nginx-loadbalancer-service \
  --type=LoadBalancer \
  --port=80 \
  --target-port=80
```


***

## Comparison of Service Types

| Service Type | Visibility | Access Method | Typical Use Case |
| :-- | :-- | :-- | :-- |
| ClusterIP | Internal only (within cluster) | `http://<service-name>.<namespace>.svc.cluster.local:<port>` | Internal app-to-app communication |
| NodePort | External access via node IP and port | `http://<NodeIP>:<NodePort>` | Simple external access, dev/testing |
| LoadBalancer | External access via cloud LB | Public IP from cloud provider | Production-grade external access |


***

## Checking the Services

- List services:

```bash
kubectl get svc
```

- Describe a service:

```bash
kubectl describe svc <service-name>
```

- Test ClusterIP inside the cluster:

```bash
kubectl exec -it <pod-name> -- curl http://nginx-clusterip-service:80
```

- Access NodePort service externally:

```text
http://<NodeIP>:30001
```

- Access LoadBalancer service (on cloud):

```text
http://<EXTERNAL-IP>
```


***

Would you like me to also add **example manifests for creating Pods/Deployments** so these services can be tested end-to-end?

