## 1. What is Ansible?

**Ansible is an agentless automation/configuration-management tool** used to configure servers, deploy applications, install packages, manage users, and perform operational tasks.

In simple terms: **instead of SSH-ing into 50 servers and doing the same thing manually, you write the task once and Ansible does it across all 50 servers.**

---

## 2. Why use Ansible?

Typical production problem:

> You have **100 Linux VMs** and need to install Docker + configure users + deploy an application on all of them.

Without Ansible:

```text
SSH → Server 1 → commands
SSH → Server 2 → commands
SSH → Server 3 → commands
...
SSH → Server 100
```

With Ansible:

```text
Ansible Controller
       |
       +---- Server 1
       +---- Server 2
       +---- Server 3
       ...
       +---- Server 100
```

You define the desired configuration once, and Ansible executes it consistently.

---

# 3. How is Ansible used in production?

A common production setup looks like:

```text
                 Git
                  |
                  | Playbooks / Roles
                  v
          CI/CD Pipeline
          (Jenkins/GitHub)
                  |
                  v
        Ansible Control Node
                  |
        -----------------------
        |          |          |
        v          v          v
      VM-01      VM-02      VM-03
      Prod       Prod       Prod
```

For example, your deployment pipeline might do:

```text
Developer
   ↓
Git Push
   ↓
Jenkins
   ↓
Build Docker image
   ↓
Terraform → Infrastructure
   ↓
Ansible → Configure VM
   ↓
Deploy application
```

Ansible is particularly useful when you have **VM-based infrastructure**.

For Kubernetes-based environments, Ansible is still useful for things around the cluster, but you generally use **Kubernetes manifests/Helm/GitOps** for application deployment rather than Ansible.

