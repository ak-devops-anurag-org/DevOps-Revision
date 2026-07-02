# Commands in Kubernetes

## Imperative vs. Declarative Commands

In Kubernetes, commands can be executed in two primary styles: imperative and declarative.

### Imperative Commands
Imperative commands are direct commands that tell Kubernetes what to do. They are executed immediately and are often used for quick tasks. For example, creating a pod can be done with a single command:

```bash
kubectl run my-pod --image=nginx
```

### Declarative Commands
Declarative commands, on the other hand, involve defining the desired state of the system in a configuration file (usually in YAML format) and then applying that configuration. This approach allows for better version control and management of resources. For example, to create a pod using a YAML file, you would first define the pod in a file (e.g., `pod.yaml`) and then apply it:

```bash
kubectl apply -f pod.yaml
```

## The `kubectl apply` Command

The `kubectl apply` command is used to create or update resources in a Kubernetes cluster based on the configuration defined in a YAML file. It is a declarative way to manage resources, allowing you to specify the desired state and letting Kubernetes handle the changes.

### Example Usage

To create or update a resource defined in a YAML file, use the following command:

```bash
kubectl apply -f <filename>.yaml
```

For example, to apply the configuration for a pod defined in `pod.yaml`, you would run:

```bash
kubectl apply -f examples/pod.yaml
```

### Benefits of Using `kubectl apply`
- **Idempotency**: You can apply the same configuration multiple times without changing the result beyond the initial application.
- **Version Control**: You can keep track of changes in your YAML files, making it easier to manage configurations over time.
- **Ease of Updates**: You can modify the YAML file and reapply it to update the resource without needing to delete and recreate it.

By understanding the difference between imperative and declarative commands, as well as how to use `kubectl apply`, you can effectively manage your Kubernetes resources.

Edit command : kubectl edit <any_k8s_object>/<deploy_name>

Describe command : 

To get any Kubernetes object as a YAML file
kubectl get pod <pod_name> -o yaml > abc.yml

Rolling update and rollback

Trigger an Update : kubectl set image deploy/<deploy_name> <container_name>=<new_image_name:tag>
Watch the update: kubectl rollout status deploy/<deploy_name>
Check history: kubectl rollout history deployment/<deploy_name>
Undo (Rollback): kubectl rollout undo deployment/<deploy_name>

To get the env inside the pod/container 
kubectl exec <pod_name> -- env