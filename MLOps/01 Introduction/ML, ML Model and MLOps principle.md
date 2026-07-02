Machine Learning?
Model?


### Main MLOps Principle

### Traceability vs Reproducibility

| Traceability                    | Reproducibility                      |
| ------------------------------- | ------------------------------------ |
| What did we do?                 | Can we do it again?                  |
| Historical record               | Repeatability                        |
| Focus on tracking               | Focus on recreating                  |
| "Which ingredients did we use?" | "Can we bake the same cake again?"   |
| Requires metadata storage       | Requires metadata + same environment |


### Relationship Between Them

```text
Traceability
     ↓
Provides information required for
     ↓
Reproducibility
```

Without traceability:
No one knows:
- data version
- code version
- parameters
- environment

Therefore reproducibility becomes impossible.

