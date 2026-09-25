# GCP provider conventions

## Backend

```hcl
terraform {
  backend "gcs" {
    bucket = "<project>-tfstate"
    prefix = "<env>/<component>"
  }
}
```

GCS has native object versioning and locking — enable versioning on the
bucket (`gsutil versioning set on gs://<bucket>` or via a bootstrap config)
so state history is recoverable.

## Project & IAM

- One GCP project per environment where the org structure allows it (cleanest
  blast-radius separation); otherwise use separate VPCs/namespaces within a
  shared project and be extra careful with IAM scoping.
- Use dedicated service accounts per workload/component
  (`google_service_account`), not the default Compute Engine service account.
- Prefer Workload Identity for GKE workloads authenticating to GCP APIs over
  service account key files — key files are a standing secret-management
  liability.
- Scope IAM bindings with `google_project_iam_member` per role per SA, not
  broad `roles/editor`/`roles/owner` grants.

## GKE-specific patterns

```hcl
resource "google_container_cluster" "this" {
  name     = "${var.project}-${var.environment}-gke"
  location = var.region   # regional cluster for HA; use var.zone for zonal/cheaper

  # Recommended: manage node pools as separate resources, not the default pool
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network_self_link
  subnetwork = var.subnetwork_self_link

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false  # true if the control plane must be fully private
    master_ipv4_cidr_block  = var.master_cidr
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "primary" {
  name       = "primary"
  cluster    = google_container_cluster.this.name
  location   = google_container_cluster.this.location
  node_count = var.node_count

  node_config {
    machine_type    = var.machine_type
    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
```

Notes relevant to a banking/regulated environment:
- Default to `enable_private_nodes = true`; treat a fully public node pool
  as something to flag, not assume.
- Enable network policy (`network_policy { enabled = true }`) if workload
  segmentation is a requirement — common for banking-grade clusters.
- Binary Authorization and VPC Service Controls are worth surfacing as
  options for regulated workloads, even if not implemented by default.
- Node pool `machine_type` and several other node-level fields force
  replacement of the node pool — check plan output before applying changes
  to an existing pool; consider surge upgrade settings
  (`upgrade_settings { max_surge = ... max_unavailable = ... }`) to avoid
  downtime during rollout.

## Tagging (labels)

GCP calls them labels, not tags, and they're stricter: lowercase only,
`[a-z0-9_-]`, no spaces:

```hcl
labels = {
  environment = var.environment
  project     = var.project
  owner       = var.owner
  managed-by  = "terraform"
}
```