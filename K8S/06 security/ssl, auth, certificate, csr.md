# Kubernetes Authentication and TLS Revision

## Table of Contents
1. [Overview](#overview)
2. [Authentication in Kubernetes](#authentication-in-kubernetes)
3. [Authorization in Kubernetes](#authorization-in-kubernetes)
4. [TLS Basics for Kubernetes](#tls-basics-for-kubernetes)
5. [Kubernetes TLS Components](#kubernetes-tls-components)
6. [Certificate Signing Requests (CSR)](#certificate-signing-requests-csr)
7. [Practical Examples](#practical-examples)
8. [Diagnostic Commands](#diagnostic-commands)
9. [Revision Summary](#revision-summary)

---

## Overview

Kubernetes security has two key pillars: **Authentication** (who are you?) and **Authorization** (what can you do?). Underneath both pillars, **TLS** provides the cryptographic foundation that secures control plane and component communication.

This file is organized from basic concepts to advanced Kubernetes-specific TLS and authentication workflows.

---

## Authentication in Kubernetes

Authentication verifies the identity of a user, service account, or component before access is allowed.

### Types of Kubernetes identities

- **Human users**: Developers and administrators using `kubectl` or direct API calls.
- **Service accounts**: Cluster-managed identities for workloads and controllers.
- **Client certificates**: Most secure method for component and user authentication.
- **Bearer tokens**: Short-lived tokens from service accounts or external identity providers.
- **Static credentials**: Basic auth CSV or token auth CSV (deprecated for production use).

### Authentication methods

- `--basic-auth-file=<file>`: Static username/password authentication.
- `--token-auth-file=<file>`: Static bearer tokens.
- `--client-ca-file=<file>`: Trust a CA for client certificates.
- `--kubelet-client-certificate` / `--kubelet-client-key`: API server authenticating to kubelet.
- `--oidc-issuer-url`, `--oidc-client-id`: External OpenID Connect identity providers.

### Static user auth example (not for production)

Create a CSV file:

```csv
password123,user1,u0001
password123,user2,u0002
```

Start API server with:

```bash
kube-apiserver --basic-auth-file=/etc/kubernetes/basic-auth.csv
```

### Static token auth example (not for production)

Create a token CSV file:

```csv
KpjCVbI7cFAHYPkByTIzRb7gulcUc4B,user10,u0010,group1
```

Start API server with:

```bash
kube-apiserver --token-auth-file=/etc/kubernetes/token-auth.csv
```

### Recommended production authentication

- Use **client certificates** with `--client-ca-file`.
- Use **OpenID Connect** or **external providers** for human users.
- Use **Service Account Tokens** inside Pods.
- Avoid static auth files in production.

---

## Authorization in Kubernetes

Authorization decides whether an authenticated identity can perform the requested action.

### Kubernetes authorization modes

- `Node`: Authorize kubelet node requests.
- `RBAC`: Role-based access control. Recommended.
- `ABAC`: Attribute-based access control. Legacy.
- `Webhook`: External authorization service.
- `AlwaysAllow`: Permit all requests (dangerous).
- `AlwaysDeny`: Deny all requests.

Enable modes in API server:

```bash
kube-apiserver --authorization-mode=Node,RBAC
```

### RBAC example: Create a Role and RoleBinding

Role definition:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

RoleBinding definition:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Apply both with:

```bash
kubectl apply -f role.yaml
kubectl apply -f rolebinding.yaml
```

### Important authorization note

RBAC is the default and recommended authorization model. It is the standard for secure, scalable access control in Kubernetes.

---

## TLS Basics for Kubernetes

TLS is the foundation that secures Kubernetes control plane traffic and component communication.

### Core TLS concepts

- **Private key**: Secret key used to sign/decrypt. File extension is usually `.key`.
- **Certificate**: Public identity signed by a CA. File extension is usually `.crt` or `.pem`.
- **Certificate Authority (CA)**: Entity that signs certificates.
- **CSR**: Certificate Signing Request.
- **Subject Alternative Name (SAN)**: The allowed DNS names/IP addresses for the certificate.

### Client vs server certificates

- **Server certificates** authenticate a service to a client.
- **Client certificates** authenticate a client to a server.

In Kubernetes, both directions are common:
- API Server presents a server cert to kubectl.
- Kubelet presents a client cert to API Server.
- API Server may present a client cert to kubelet and etcd.

### Generate a key and CSR with `openssl`

```bash
openssl genrsa -out kube-user.key 2048
openssl req -new -key kube-user.key -out kube-user.csr \
  -subj "/CN=kube-user/O=dev-team"
```

Generate a self-signed CA (for lab/demo clusters):

```bash
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
  -out ca.crt -subj "/CN=Kubernetes-CA/O=cluster.local"
```

---

## Kubernetes TLS Components

Kubernetes uses TLS for several core components.

### Common certificate files

- `/etc/kubernetes/pki/ca.crt` and `ca.key` - root CA.
- `/etc/kubernetes/pki/apiserver.crt` and `apiserver.key` - API server TLS certificate.
- `/etc/kubernetes/pki/apiserver-kubelet-client.crt` and `apiserver-kubelet-client.key` - API Server client cert for kubelet.
- `/etc/kubernetes/pki/front-proxy-ca.crt` and `front-proxy-client.crt` - front proxy trust chain.
- `/etc/kubernetes/pki/etcd/ca.crt`, `etcd/server.crt`, `etcd/server.key` - etcd TLS certs.
- `/var/lib/kubelet/pki/kubelet-client-current.pem` - kubelet client certificate.

### API Server TLS flags

Key flags include:

```bash
--tls-cert-file=/etc/kubernetes/pki/apiserver.crt
--tls-private-key-file=/etc/kubernetes/pki/apiserver.key
--client-ca-file=/etc/kubernetes/pki/ca.crt
--service-account-key-file=/etc/kubernetes/pki/sa.pub
--kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
--kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
--requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
```

### Kubelet TLS flags

```bash
--client-ca-file=/etc/kubernetes/pki/ca.crt
--tls-cert-file=/var/lib/kubelet/pki/kubelet.crt
--tls-private-key-file=/var/lib/kubelet/pki/kubelet.key
--rotate-certificates=true
--authentication-token-webhook=true
```

### Certificate rotation

Kubernetes can rotate some certificates automatically if configured:

- `kubelet`: `--rotate-certificates=true`
- `kube-controller-manager`: automatic rotation for client certs when using `certificate-controller`

---

## Certificate Signing Requests (CSR)

Kubernetes CSR resources allow users and workloads to request signed certificates from the cluster CA.

### Generate a CSR YAML for Kubernetes

```bash
openssl genrsa -out myuser.key 2048
openssl req -new -key myuser.key -out myuser.csr \
  -subj "/CN=myuser/O=developers"
base64 -w 0 myuser.csr > csr.b64
```

Create the CSR manifest:

```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: myuser-csr
spec:
  request: <BASE64_CSR>
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
  - digital signature
  - key encipherment
```

Apply it:

```bash
kubectl apply -f myuser-csr.yaml
```

### Approve and retrieve the certificate

```bash
kubectl certificate approve myuser-csr
kubectl get csr myuser-csr -o jsonpath='{.status.certificate}' | base64 --decode > myuser.crt
```

### Deny or delete a CSR

```bash
kubectl certificate deny myuser-csr
kubectl delete csr myuser-csr
```

### Example signer names

- `kubernetes.io/kube-apiserver-client` for API server client certs.
- `kubernetes.io/kubelet-serving` for kubelet serving certs.
- `kubernetes.io/legacy-unknown` for older use cases.

---

## Practical Examples

### Example 1: Create a kubeconfig for a user certificate

```bash
kubectl config set-cluster mycluster \
  --server=https://<api-server-ip>:6443 \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --embed-certs=true \
  --kubeconfig=myuser.kubeconfig

kubectl config set-credentials myuser \
  --client-certificate=myuser.crt \
  --client-key=myuser.key \
  --embed-certs=true \
  --kubeconfig=myuser.kubeconfig

kubectl config set-context myuser-context \
  --cluster=mycluster \
  --user=myuser \
  --kubeconfig=myuser.kubeconfig

kubectl config use-context myuser-context --kubeconfig=myuser.kubeconfig
```

### Example 2: API server certificate SANs

A Kubernetes API server certificate must include SANs for all IPs and DNS names clients will use.

```bash
openssl req -new -key apiserver.key -out apiserver.csr -subj "/CN=kube-apiserver" \
  -addext "subjectAltName = DNS:kubernetes,DNS:kubernetes.default,DNS:kubernetes.default.svc,IP:10.96.0.1,IP:<api-server-ip>"
```

### Example 3: kubelet server cert request (CSR flow)

A kubelet can request a serving certificate using a CSR resource signed by the cluster.

```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: kubelet-serving-node1
spec:
  request: <BASE64_CSR>
  signerName: kubernetes.io/kubelet-serving
  usages:
  - server auth
  - digital signature
  - key encipherment
```
```

---

## Diagnostic Commands

### Inspect a certificate

```bash
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
```

### Check certificate expiration

```bash
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates
```

### List CSRs

```bash
kubectl get csr
```

### Show CSR status

```bash
kubectl get csr myuser-csr -o yaml
```

### Extract certificate from approved CSR

```bash
kubectl get csr myuser-csr -o jsonpath='{.status.certificate}' | base64 --decode | openssl x509 -text -noout
```

---

## Revision Summary

### Basic

- Kubernetes uses authentication to verify identities.
- Authorization decides access rights.
- TLS secures component communication.
- Certificates are signed by a cluster CA.

### Intermediate

- API Server, kubelet, and etcd all use TLS.
- RBAC is the recommended authorization model.
- Client certificates are preferred over static tokens.
- CSR resources let Kubernetes sign certificates.

### Hero

- Use `--client-ca-file` and `--kubelet-client-certificate` on the API server.
- Ensure API server certs have proper SAN entries.
- Approve CSRs with `kubectl certificate approve` and retrieve the signed cert.
- Rotate kubelet certificates automatically with `--rotate-certificates=true`.

