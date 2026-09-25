## How this fits into the complete MLOps architecture you're planning

Given your target architecture (Airflow + DVC + MLflow + KServe on AKS), the overall flow becomes:

```text
GitHub
   │
   ▼
CI/CD (GitHub Actions / Azure DevOps)
   │
   ▼
Airflow
   │
   ├── ETL
   ├── Data Validation
   ├── Feature Engineering
   └── DVC versions processed dataset
   │
   ▼
Kubeflow Pipeline
   │
   ├── Prepare training inputs
   ├── Launch Kubeflow Trainer
   │       │
   │       ├── Train model (single-node or distributed)
   │       └── Produce trained model artifact
   │
   ├── Evaluate model
   ├── Log metrics to MLflow
   ├── Register model in MLflow
   └── Trigger deployment
   │
   ▼
KServe
   │
   ▼
Online Inference
   │
   ▼
Monitoring & Drift Detection
   │
   ▼
Continuous Training (CT) triggers a new Kubeflow Pipeline run
```

