Major Topics - K8S 



# 02 Basics Core concepts

### Architecture 
  - control plane conponents
  - worker node components 
### Pod
### Services 
  - Load balancer
  - Node Port service
  - Cluster IP services
  - other?? 
### Namespaces
### Deployments 
Imperative and declerative commad
 

# 03 Schuduling 

### Manual scheduling 
yaml file - nodeName field
### Automatic scheduling
kube schedular in control plan looks for 
 - taint/toleration
 - Node selector, node affinity and anti-affinity
 - Resource availability (CPU/memory)
 - Pod constraints (if any)
### Range and Limit (resource quota ?)
### Deamon set 
when a new node is added a pod isautomatically scheduled - such as log/monitoring pod
### StatefulSets?  
A StatefulSet manages pods that require:
Stable, unique network ID
Stable storage (persistent volumes)
Ordered, graceful deployment and scaling
### static pods (Example - kube proxy pod is scheduled as static pod on every node)
Static Pods are special Pods managed directly by the kubelet on a specific node, rather than by the Kubernetes API server or control plane. They are used to ensure critical system components (like the API server, etcd, controller-manager, and scheduler) can run even before or without a fully running Kubernetes control plane
### Priority classes ?
### Multiple schedular ?

# 04 Looginf and Monitoring

### Metrix server 
### Prometheus + Grafana

# 05 Application Lifecycle Management


### Rolling updates and rollout
### Commands and Arguments in Docker?
### Commands and Arguments in Kubernetes?
### Env - and types we can feed env in pods? (plane key value in pod defination, config map, secrete) 