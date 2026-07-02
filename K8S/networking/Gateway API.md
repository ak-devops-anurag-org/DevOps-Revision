# What is Gateway API?

* **Gateway API** = Evolving standard (by SIG-NETWORK) that improves on **Ingress** and **Service**.
* It’s an **API set of CRDs** (Custom Resource Definitions) that define how traffic enters and moves inside the cluster.
* Think of it as **Ingress v2** → more flexible, role-oriented, and supports advanced traffic routing.

# Why Gateway API? (Problems with Ingress)

* **Ingress limitations**:

  * Only HTTP/HTTPS support (L7).
  * Vendor-specific annotations (NGINX vs Traefik vs AWS ALB).
  * Hard to express complex routing (headers, weights, TCP, gRPC).
* **Gateway API fixes this**:

  * Standard CRDs, no vendor lock-in.
  * Supports **L4 + L7 traffic** (TCP, UDP, HTTP, HTTPS, gRPC).
  * Separation of roles: infra team manages Gateways, app team manages Routes.
  * Portable across cloud & on-prem.

# Core Concepts

1. **GatewayClass** → Defines a type of Gateway (like IngressClass).

   * Example: `nginx`, `istio`, `traefik`.

2. **Gateway** → Instance of a GatewayClass. Defines infra (like LB/ports).

3. **Route** → (HTTPRoute, TCPRoute, GRPCRoute, etc.) defines traffic rules.

   * Example: `example.com/app1` → Service A.

4. **BackendRef** → The Service/Pod traffic should go to.

👉 This separation = infra team controls **Gateway**, app team controls **Routes**.

# Example: Gateway API (NGINX Controller)

### 1. GatewayClass

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx
spec:
  controllerName: k8s.io/ingress-nginx
```

### 2. Gateway

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway
  namespace: default
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    hostname: "example.com"
```

### 3. HTTPRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-route
  namespace: default
spec:
  parentRefs:
  - name: my-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /app1
    backendRefs:
    - name: service-app1
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /app2
    backendRefs:
    - name: service-app2
      port: 80
```

# Flow (How It Works)

1. Client → `example.com/app1`.
2. DNS → points to Gateway LB IP.
3. **Gateway** receives traffic on port 80.
4. **HTTPRoute** matches `/app1` → forwards to `service-app1`.
5. CNI → handles Pod-to-Pod routing.

# Key Benefits over Ingress

* Multi-protocol (HTTP, TCP, UDP, gRPC).
* Role separation: **Infra team = Gateway**, **Dev team = Routes**.
* No messy vendor-specific annotations.
* Fine-grained traffic policies (timeouts, retries, weights).

✅ **In short:**

* Ingress = basic, HTTP-only, annotation-heavy.
* Gateway API = modern, flexible, vendor-neutral, future of K8s networking.









## Problems with Ingress API

1. **Limited Protocol Support**

   * Ingress only works for **HTTP/HTTPS** traffic.
   * No support for **TCP, UDP, gRPC, or WebSockets** natively.
   * Workarounds require custom annotations or ConfigMaps, making things messy.

2. **Single Shared Resource (Not Multi-Tenant Friendly)**

   * Only **one Ingress object per cluster/namespace** can control routing for an entire domain.
   * Hard to manage when multiple teams/apps want their own routing rules.
   * Example: Team A and Team B deploying apps in the same cluster → they fight for the same Ingress resource.

3. **Controller-Specific Configurations (Vendor Lock-In)**

   * Different Ingress Controllers (NGINX, HAProxy, Traefik, etc.) use **different annotations**.
   * Example:

     ```yaml
     # Works with NGINX but not with HAProxy
     nginx.ingress.kubernetes.io/rewrite-target: /
     ```
   * Means you can’t easily switch controllers without rewriting manifests.

4. **Limited Extensibility & Features**

   * Things like **canary releases, traffic splitting, weighted routing, header-based routing** are hacky in Ingress.
   * Requires custom CRDs (e.g., NGINX Ingress Controller’s own CRDs).

5. **Complicated Configuration Management**

   * Ingress tries to do too much in **one YAML resource** → routes, TLS, host/path rules, etc.
   * No clean separation of concerns between infra teams (networking) and app teams (routes).

6. **Scalability & Maintainability Issues**

   * As cluster grows with many apps, **Ingress YAML becomes huge and unmanageable**.
   * No fine-grained control like delegating routes per namespace or team.

👉 Because of these issues, **Gateway API** was introduced to:

* Support more protocols (TCP, UDP, gRPC).
* Allow **multi-tenant routing** with delegation.
* Provide a **standardized, vendor-neutral API** (no controller-specific annotations).
* Separate infra responsibilities (GatewayClass/Gateway) from app responsibilities (HTTPRoute, TCPRoute, etc.).

