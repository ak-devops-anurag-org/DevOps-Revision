## Introduction to MLOps

### What is MLOps?
MLOps = DevOps principles applied to Machine Learning.
Just like DevOps automates and streamlines software delivery (CI/CD), MLOps automates and streamlines the ML lifecycle — from data to a deployed, monitored model.

**Simple analogy:** In DevOps you version code and deploy via pipelines. In MLOps you version **code + data + model**, and deploy via pipelines too — but the "product" (the model) can silently go stale even if nothing changes in the code (more on this in Monitoring below).

---

### Traditional ML Lifecycle (Iterative — like Agile sprints, not a one-time waterfall)

| Step | What happens | Who does it |
|---|---|---|
| 1. Business Understanding | Define the problem, gather requirements | Subject Matter Experts (SMEs) |
| 2. Data Acquisition | Collect data from sources (DBs, APIs, data lakes) | Data Engineer |
| 3. Data Cleaning | Wrangling, EDA, preprocessing, visualization | Data Engineer / Data Scientist |
| 4. Modelling | Select algorithm, build, train, validate model | Data Scientist |
| 5. Model Deployment | Expose model for use | ML Engineer |
| 6. Monitoring | Track model performance, retrain if needed | ML Engineer |

**Note:** This is iterative — like a CI/CD loop. You don't do steps 1→6 once and stop; you cycle back (e.g., retraining after monitoring detects issues).

---

### Step-by-step Details

**2. Data Acquisition**
- Identify data sources & formats, store in a data lake.
- Rule of thumb: **more (quality) data → better model accuracy.**

**3. Data Cleaning**
- Includes: Data wrangling (Converting messy raw data into usable data), EDA (Exploratory Data Analysis - Understanding your data before building the model), transformation, preprocessing, visualization.
- Goal: raw messy data → clean, structured data ready for training.

**4. Modelling**
- Select algorithm → Build model → Train on ~70% of data → Validate/Test on remaining data.
- **AutoML tools** exist (analogous to automated pipeline optimizers) that try different algorithms/hyperparameters automatically to find the best model — reduces manual trial-and-error.
- If validation fails or performance isn't good → **retrain**.

**5. Model Deployment**
Two main patterns:
- **Model as a Service** → Deployed as a REST API endpoint (e.g., a `/predict` endpoint apps can call). Similar to microservice deployment in DevOps.
- **Embedded Deployment** → Model is packaged directly inside an app/software (like a bundled library, no separate service call needed).

**6. Monitoring**
- **Why:** Once deployed, a model isn't "done forever" — its accuracy can degrade over time.
- **Model/Data Drift (Model Shift):** Real-world data patterns change over time, so the model (trained on old data) starts making inaccurate predictions.
  - **Example:** A model trained to predict customer spending using pre-COVID shopping data would fail post-COVID because buying behavior completely changed (online shopping surge, different priorities). The underlying data pattern shifted → model needs **retraining** on fresh data.
- Monitoring detects this drift → triggers **retraining** → back to Step 4. This is why the lifecycle is a loop, not a straight line.

---

### Roles & Responsibilities (Quick Reference)

| Role | Responsibility |
|---|---|
| **Subject Matter Expert (SME)** | Defines business problem/requirements |
| **Data Engineer** | Data acquisition, data lake setup, ETL pipelines, cleaning/transformation |
| **Data Scientist** | Algorithm selection, model building, training, validation |
| **ML Engineer** | Deployment, operationalizing the model, integrating into apps, monitoring |

**Memory tip (DevOps mapping):**
- Data Engineer ≈ builds the "data pipeline" (like a build pipeline for raw material)
- Data Scientist ≈ writes the "application logic" (the model)
- ML Engineer ≈ does the "release engineering" (deploy, monitor, operate) — this is closest to your current DevOps skillset

---

### Two Phases of an ML Project

1. **Data Science Phase** (build the model):
   `Data Acquisition → Data Processing → Model Building → Model Training → Model Validation`

2. **Operations Phase** (ship & run the model — this is where MLOps/DevOps skills apply):
   `Package → Compile → Deploy → Release → Monitoring`

**Key insight:** MLOps exists to bridge these two phases smoothly — just like DevOps bridges Dev and Ops. Phase 1 = "Dev" (data scientists build), Phase 2 = "Ops" (ML engineers run) — MLOps is the glue (CI/CD/CT — Continuous Training) connecting them.

