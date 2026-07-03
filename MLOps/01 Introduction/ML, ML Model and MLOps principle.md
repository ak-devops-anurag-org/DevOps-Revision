## Machine Learning (ML)

> Teaching computers to learn patterns from data instead of writing rules manually.

**Traditional Programming**

```text
Rules + Data → Output
```

**Machine Learning**

```text
Data + Output → Learn Rules → Model
```

## Model

> A trained "brain" that makes predictions using learned patterns.

Example:

```text
Input:
Area = 1200 sqft
Bedrooms = 2

Model Output:
House Price = ₹58 Lakhs
```

# Core MLOps Principles

## 1. Traceability

> **"What exactly did we do to get this result?"**

Track:

* Dataset version
* Code version
* Parameters
* Features
* Environment
* Model version

Example:

```text
Data v5
Code v3
Learning Rate = 0.01
Model = v7
```

## 2. Reproducibility

> **"Can we do it again perfectly?"**

Using same:

* Data
* Code
* Parameters
* Environment

should produce:

```text
Same Model
Same Accuracy
Same Results
```

## Relationship

```text
Traceability
     ↓
Provides information required for
     ↓
Reproducibility
```

Without traceability:

```text
No one knows:
- data version
- code version
- parameters
- environment
```

Therefore:

```text
No Traceability
        ↓
No Reproducibility
```

# Data Cleaning

## Data Wrangling

> Fix messy data.

Examples:

* Remove duplicates
* Fill missing values
* Fix incorrect data

---

## EDA (Exploratory Data Analysis)

> Understand the data.

Questions:

* Average value?
* Missing values?
* Outliers?
* Data distribution?

## Transformation

> Convert data into model-friendly format.

Examples:

```text
Male → 1
Female → 0
```

```text
50000 → 0.05
70000 → 0.07
```

## Preprocessing

> Prepare data before training.

Includes:

* Missing value handling
* Encoding
* Scaling
* Outlier removal

## Visualization

> Understand data using graphs.

Examples:

* Histogram
* Bar Chart
* Scatter Plot
* Box Plot

---

# Complete ML Flow

```text
Raw Data
   ↓
Data Cleaning
   ↓
Feature Engineering
   ↓
Model Training
   ↓
Model Evaluation
   ↓
Deployment
   ↓
Monitoring
```

# DevOps vs MLOps

| DevOps            | MLOps            |
| ----------------- | ---------------- |
| Source Code       | Training Data    |
| Build             | Training         |
| Docker Image/JAR  | Model            |
| Artifact Registry | Model Registry   |
| Deployment        | Model Serving    |
| Monitoring        | Model Monitoring |

