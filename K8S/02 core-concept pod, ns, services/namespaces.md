# Namespaces in Kubernetes

## Introduction
Namespaces in Kubernetes provide a mechanism for isolating groups of resources within a single cluster. They allow for the organization of resources and can help manage access control, resource quotas, and more. Namespaces are particularly useful in environments where multiple teams or projects share the same cluster.

## Purpose of Namespaces
- **Resource Isolation**: Namespaces allow different teams or applications to operate in the same cluster without interfering with each other.
- **Access Control**: Role-Based Access Control (RBAC) can be applied at the namespace level, allowing for fine-grained permissions.
- **Resource Quotas**: Administrators can set resource limits for each namespace, ensuring fair resource distribution among teams.

## Creating a Namespace
To create a namespace in Kubernetes, you can use the following YAML configuration:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
```

You can save this configuration in a file named `namespace.yaml` located in the `core-concept/examples` directory.

## Using Namespaces
Once a namespace is created, you can specify it when creating other Kubernetes resources. For example, to create a pod in a specific namespace, you can include the `namespace` field in the metadata section of the pod's YAML configuration.

## Example Commands
To create a namespace using the command line, you can use the following command:

```bash
kubectl apply -f examples/namespace.yaml
```

To list all namespaces in your cluster, use:

```bash
kubectl get namespaces
```

## Conclusion
Namespaces are a powerful feature in Kubernetes that help manage resources and provide isolation within a cluster. By organizing resources into namespaces, teams can work more effectively and securely within shared environments.