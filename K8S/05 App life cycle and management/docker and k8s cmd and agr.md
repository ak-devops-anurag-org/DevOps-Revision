# 🐳☸️ **Commands and Arguments in Docker and Kubernetes**

## Overview

Both **Docker** and **Kubernetes** let you define what process (or command) runs when a container starts.
These commands determine **the main executable** and **its arguments** inside the container.

However, the way you **define and override** them differs slightly between **Dockerfiles** and **Kubernetes manifests**.

---

## 🐳 **Docker: Commands and Arguments**

### 🧩 Key Instructions in Dockerfile

Docker provides two main instructions related to container startup behavior:

| Instruction    | Purpose                                                     | Example                 |
| -------------- | ----------------------------------------------------------- | ----------------------- |
| **ENTRYPOINT** | Defines the main executable (cannot be easily changed).     | `ENTRYPOINT ["python"]` |
| **CMD**        | Provides default arguments or commands (can be overridden). | `CMD ["app.py"]`        |

---

### ⚙️ How They Work Together

```dockerfile
FROM python:3.10
WORKDIR /app
COPY . .
ENTRYPOINT ["python"]
CMD ["app.py"]
```

When you run:

```bash
docker run myimage
```

Executes → `python app.py`

When you run:

```bash
docker run myimage test.py
```

Executes → `python test.py`

---

### 🔁 Overriding Behavior

| Level             | Override Type                                          | Example                                |
| ----------------- | ------------------------------------------------------ | -------------------------------------- |
| **At runtime**    | Override `CMD`                                         | `docker run myimage another_script.py` |
| **At runtime**    | Override both `ENTRYPOINT` and `CMD`                   | `docker run --entrypoint bash myimage` |
| **In Kubernetes** | Overriding is done via Pod spec (`command` and `args`) | Explained below 👇                     |

---

## ☸️ **Kubernetes: Commands and Arguments**

In Kubernetes, when you define a container in a Pod, you can specify:

| Field       | Purpose                           | Corresponds to in Docker |
| ----------- | --------------------------------- | ------------------------ |
| **command** | Overrides the Docker `ENTRYPOINT` | `ENTRYPOINT`             |
| **args**    | Overrides the Docker `CMD`        | `CMD`                    |

These fields define what the container will **actually execute** inside the Pod.

---

### 🧩 Example 1: Using command and args

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: demo-pod
spec:
  containers:
  - name: myapp
    image: python:3.10
    command: ["python"]       # Overrides ENTRYPOINT
    args: ["app.py"]          # Overrides CMD
```

Equivalent Docker run:

```bash
docker run python:3.10 python app.py
```

---

### 🧩 Example 2: Overriding only args

If the Dockerfile already has:

```dockerfile
ENTRYPOINT ["python"]
CMD ["app.py"]
```

You can override only `args` in Kubernetes:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: override-args
spec:
  containers:
  - name: myapp
    image: myimage
    args: ["manage.py", "runserver"]
```

Final execution inside container:

```bash
python manage.py runserver
```

---

### 🧩 Example 3: Overriding both command and args

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: debug
spec:
  containers:
  - name: alpine
    image: alpine
    command: ["sleep"]        # Override ENTRYPOINT
    args: ["3600"]            # Override CMD
```

Final execution:

```bash
sleep 3600
```

---

### ⚙️ Precedence Order

| Priority | Source                                  | Description                          |
| -------- | --------------------------------------- | ------------------------------------ |
| 1️⃣      | Kubernetes Pod spec (`command`, `args`) | Highest priority                     |
| 2️⃣      | Dockerfile (`ENTRYPOINT`, `CMD`)        | Default if not overridden            |
| 3️⃣      | Base image ENTRYPOINT/CMD               | Used only if nothing else is defined |

---

### 🧠 Quick Comparison

| Concept                            | Docker                                        | Kubernetes                                       |
| ---------------------------------- | --------------------------------------------- | ------------------------------------------------ |
| Defines what runs inside container | `ENTRYPOINT` and `CMD`                        | `command` and `args`                             |
| Default behavior                   | Run `ENTRYPOINT` with `CMD` as args           | Use Docker’s ENTRYPOINT/CMD if not overridden    |
| Override method                    | `docker run --entrypoint` or provide new args | Use `command` and/or `args` fields in YAML       |
| Common use                         | Define main app process                       | Modify runtime behavior without rebuilding image |

---

### 💡 Real-World Example

You have a Docker image built with:

```dockerfile
ENTRYPOINT ["python"]
CMD ["main.py"]
```

If you deploy it in Kubernetes with:

```yaml
command: ["python3"]
args: ["manage.py", "runserver"]
```

Then the actual executed process becomes:

```bash
python3 manage.py runserver
```

Kubernetes **completely overrides** Docker’s ENTRYPOINT and CMD in this case.

---

## 🧾 **Summary**

| Level      | Command    | Argument | Overridable By                      |
| ---------- | ---------- | -------- | ----------------------------------- |
| Dockerfile | ENTRYPOINT | CMD      | Docker run flags or Kubernetes spec |
| Kubernetes | command    | args     | Highest priority in Pod spec        |

---

### ✅ Key Takeaways

* In **Docker**, `ENTRYPOINT` = main executable, `CMD` = default arguments.
* In **Kubernetes**, `command` overrides `ENTRYPOINT`, and `args` overrides `CMD`.
* Kubernetes always takes priority over Dockerfile settings if both are defined.
* Use this to **customize container behavior per environment** without rebuilding images.

