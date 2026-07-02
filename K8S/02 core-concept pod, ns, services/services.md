# Kubernetes Services

Kubernetes services are an abstraction that defines a logical set of pods and a policy by which to access them. This allows for stable networking and load balancing across the pods. There are several types of services in Kubernetes, each serving different use cases.

## 1. Cluster IP Service

The Cluster IP service is the default type of service in Kubernetes. It provides a stable IP address for a set of pods, allowing them to communicate with each other within the cluster. This service type is only accessible from within the cluster.

### Example YAML Configuration

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-clusterip-service
spec:
  type: ClusterIP
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 8080
```

## 2. NodePort Service

A NodePort service exposes the service on each node's IP at a static port (the NodePort). This allows external traffic to access the service by requesting `<NodeIP>:<NodePort>`. NodePort services are useful for development and testing purposes.

### Example YAML Configuration

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-nodeport-service
spec:
  type: NodePort
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 8080
      nodePort: 30007
```

## 3. Load Balancer Service

A Load Balancer service automatically provisions a load balancer for the service in supported cloud environments. This service type provides a stable external IP address that can be used to access the service from outside the cluster.

### Example YAML Configuration

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-loadbalancer-service
spec:
  type: LoadBalancer
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 8080
```

## Summary

Kubernetes services provide a way to expose applications running in pods to other applications and users. The choice of service type depends on the specific requirements for accessibility and load balancing.