# ⚙️ Commands and Arguments in Kubernetes Pods

In Kubernetes pod specs, you have two fields inside the container spec:

* `command`
* `args`

These correspond to what’s known as **ENTRYPOINT** and **CMD** in Docker.

---

### What they do:

| Kubernetes field | Docker equivalent | Purpose                                                  |
| ---------------- | ----------------- | -------------------------------------------------------- |
| `command`        | ENTRYPOINT        | Overrides the container’s default entrypoint executable. |
| `args`           | CMD               | Overrides default arguments passed to the entrypoint.    |

---

# How Kubernetes uses them:

* If **neither** `command` nor `args` is specified:
  Container runs using the image’s default ENTRYPOINT and CMD.

* If **only `command`** is specified:
  Runs the specified command, ignoring the image ENTRYPOINT and CMD.

* If **only `args`** is specified:
  Runs image ENTRYPOINT with the specified args (overrides CMD).

* If **both `command` and `args`** are specified:
  Runs `command` with `args` as parameters.

---

# Example

Say your Docker image’s default:

* ENTRYPOINT: `/bin/sh`
* CMD: `["-c", "echo Hello World"]`

---

### Kubernetes Pod Spec example overriding args only:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
spec:
  containers:
  - name: example
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "echo Overridden Args"]
```

**Result:** Runs `/bin/sh -c "echo Overridden Args"`

---

### Overriding command and args:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod-2
spec:
  containers:
  - name: example
    image: busybox
    command: ["echo"]
    args: ["Hello from command and args"]
```

**Result:** Runs `echo "Hello from command and args"`

---

# Summary Table

| Case                      | Runs inside container                            |
| ------------------------- | ------------------------------------------------ |
| No `command` or `args`    | Image default ENTRYPOINT and CMD                 |
| `command` only            | Runs `command` ignoring image ENTRYPOINT and CMD |
| `args` only               | Runs image ENTRYPOINT with `args`                |
| Both `command` and `args` | Runs `command` with `args`                       |

---

If you want, I can help you with examples for Deployments or explain how this affects containers built from different base images!
