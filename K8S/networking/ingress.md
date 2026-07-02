# What is Ingress in Kubernetes?

* **Ingress** = API object that **manages external HTTP/HTTPS access** to services in a cluster.
* Instead of exposing each service with NodePort/LoadBalancer, we define **Ingress rules**.
* Example:

  * `example.com/app1 → Service A`
  * `example.com/app2 → Service B`

👉 Ingress acts like a **reverse proxy + L7 load balancer**.


# Why Ingress?

* NodePort → Exposes app on random port, not user-friendly.
* LoadBalancer → Each service = 1 cloud LB (expensive).
* Ingress → **One entrypoint (single LB/IP)** for multiple apps, with path/host-based routing.


# Ingress Controller

* Ingress resource is **just configuration (rules)**.
* To actually work, we need an **Ingress Controller** (a pod/daemonset that watches Ingress objects and configures reverse proxy inside cluster).
* Popular Ingress Controllers:

  * **NGINX Ingress Controller** (most common).
  * **HAProxy Ingress**.
  * **Traefik**.
  * **Cloud-specific** (GKE Ingress, AWS ALB Ingress).

👉 Without a controller, Ingress resource does nothing.


# Ingress vs Ingress Controller

* **Ingress (API object)**: Defines rules (`host`, `path`, → Service).
* **Ingress Controller**: Implements those rules using a proxy (NGINX, Traefik, etc.).


# How Ingress Works (Flow)

1. **Client (Browser)** → DNS resolves `app.example.com` → external IP of LB/Ingress Controller.
2. **Ingress Controller (NGINX pod)** receives traffic on port 80/443.
3. It checks the **Ingress rules**:

   * If `host = app1.example.com` and `path = /api` → forward to `service-app1`.
   * If `host = app2.example.com` → forward to `service-app2`.
4. **Service** routes traffic to the right **Pod(s)**.
5. **CNI plugin** handles final Pod IP routing.


# Anatomy of Ingress Resource (Example YAML)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: service-app1
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: service-app2
            port:
              number: 80
```

👉 Here:

* `app.example.com/app1` → forwards to **service-app1**.
* `app.example.com/app2` → forwards to **service-app2**.


# TLS with Ingress

* Ingress supports HTTPS using **TLS secrets**.

```yaml
spec:
  tls:
  - hosts:
      - app.example.com
    secretName: tls-secret
```

👉 `tls-secret` must contain cert + key (`kubectl create secret tls tls-secret --key privkey.pem --cert fullchain.pem`).


# IngressClass

* Defines which **Ingress Controller** should handle which Ingress resources.
* Example: `ingressClassName: nginx`.

Multiple Ingress Controllers can coexist (NGINX, Traefik), each handling its own class.


# CoreDNS with Ingress

* DNS entry (e.g., `app.example.com`) should point to the **external IP of LB/Ingress Controller**.
* CoreDNS inside the cluster resolves only **service names**, not public domains.


# Summary

* **Ingress Resource** = rules.
* **Ingress Controller** = implementation (reverse proxy).
* **Ingress** enables:

  * Host-based routing (different domains → services).
  * Path-based routing (`/api`, `/web`).
  * TLS termination.
  * Single LoadBalancer → multiple services.


# Commands Reference

```bash
# Check Ingress objects
kubectl get ingress -A

# Describe ingress
kubectl describe ingress my-ingress

# Check Ingress Controller pods
kubectl get pods -n ingress-nginx

# Check external IP of controller service
kubectl get svc -n ingress-nginx
```

