---
name: tech-interview-revision
description: Generates concise, interview-focused Markdown revision notes for ANY technology topic — programming languages, frameworks, data structures & algorithms, system design, databases/SQL, AI/ML/LLMs, data engineering, MLOps, cloud, DevOps, security, networking, testing, mobile, and more. Use this skill whenever the user wants to revise a tech topic, prepare for a technical/client/coding interview, build a cheat sheet or Q&A sheet, or says things like "notes on X for interview", "I need to revise Y", "quick revision for Z", "prep me for a <role> interview", even if they don't say "skill" or "markdown".
---

# Tech Interview Revision Skill

## Purpose

Help a candidate **revise and prepare for a technical interview** on any technology topic by producing concise Markdown notes covering the highest-value concepts, code/commands, architecture, trade-offs, troubleshooting, and scenario questions.

These are **last-minute revision notes, not tutorials.** Optimize for interview readiness, practical understanding, and high-signal recall — not academic completeness.

---

## 1. Workflow

1. **Identify the topic** from the request (e.g. "Python", "RAG", "system design", "SQL joins", "React", "Kafka").
2. **Gather context that changes the notes** — but only what is missing and only if it materially matters. Infer from the request first. Useful signals:
   - **Role / level** (fresher, mid, senior; backend, ML engineer, data engineer, SRE…)
   - **Interview type** (technical screen, coding round, system design, client round, HR-technical mix)
   - **Provided material** (job description, syllabus, resume, existing notes) → use it to prioritize topics.
   If the user gave none of this, assume **mid-level, general technical interview** and state that assumption in one line. Do not interrogate the user.
3. **Choose the working directory** from the request. If none is named, create `<topic>-revision/` in the current working location.
4. **Plan the file set** (Section 2) before writing.
5. **Write topic files in order**, then `99_interview_questions.md` last.
6. **Run the quality checklist** (Section 15) and fix gaps.
7. **Report briefly** — list the files created and any assumptions. No long recap.

Do not create unnecessary files (no README/index/extras) unless asked.

---

## 2. File Structure

Generate **at most 8 topic files** plus one final interview file:

```text
01_<name>.md
...
08_<name>.md

99_interview_questions.md
```

Rules:

- The **number of files follows topic breadth.** Never pad to reach 8. A narrow topic (e.g. "SQL window functions") may need 2–3 files; a broad one (e.g. "Machine Learning") may need all 8.
- **File names are topic-specific** — derive them from the real scope. Order files roughly: fundamentals → core concepts → deeper components → practical usage → performance/trade-offs → security/reliability → troubleshooting/debugging → production/advanced.
- Each file covers one logical theme.
- If a concept is already explained in an earlier file, **cross-reference it briefly** instead of repeating:

```markdown
> For the basics of indexing, see `03_indexes_query_performance.md`.
```

- `99_interview_questions.md` is the exception — it intentionally re-summarizes key material as the final revision sheet.

Example (Python): `01_python_fundamentals.md`, `02_data_types_collections.md`, `03_functions_oop.md`, `04_iterators_generators_decorators.md`, `05_memory_gil_concurrency.md`, `06_error_handling_testing.md`, `07_performance_best_practices.md`, `99_interview_questions.md`.

Example (Machine Learning): `01_ml_fundamentals.md`, `02_supervised_algorithms.md`, `03_unsupervised_learning.md`, `04_model_evaluation_metrics.md`, `05_overfitting_regularization.md`, `06_feature_engineering_data.md`, `07_deep_learning_basics.md`, `08_mlops_production.md`, `99_interview_questions.md`.

---

## 3. Revision-First Philosophy

**Prioritize (in order):**

1. Most commonly asked interview questions
2. Core concepts and "why" behind them
3. Practical usage (how it's used in real projects)
4. Code / commands / queries
5. Architecture and how components interact
6. Trade-offs and "when to use X vs Y"
7. Debugging and troubleshooting
8. Performance and production considerations
9. Security and reliability
10. Scenario-based questions
11. Common traps and misconceptions

**Avoid:** long theory, history, beginner filler, repeated explanations, rarely-asked trivia, walls of text.

Notes must be **fast to scan** before an interview.

---

## 4. Question-Driven Format

Structure sections as interview questions wherever possible:

```text
Question → Short answer → Key points → Example → Interview tip
```

Template:

````markdown
## What is a database index?

A data structure (commonly a B-tree) that speeds up reads by avoiding full table scans, at the cost of slower writes and extra storage.

### Key Points

- Speeds up `WHERE`, `JOIN`, `ORDER BY`
- Slows down `INSERT`/`UPDATE`/`DELETE`
- Composite index order matters (leftmost prefix)

### Example

```sql
CREATE INDEX idx_orders_user_date ON orders (user_id, created_at);
```

> [!TIP]
> Interview tip: always mention the write-cost trade-off — it shows you know indexes aren't free.
````

Skip Example / Tip when they add nothing.

---

## 5. Answer Depth

Answers must be short, accurate, practical, and **easy to say out loud**.

- Most answers: **2–6 lines.**
- Important concepts: add code, a formula, a diagram, or a comparison table.
- Never trade correctness for brevity. If something is nuanced, say so in one line.

---

## 6. Priority Markers

Use consistently and **selectively** — never mark everything as MUST KNOW.

| Marker | Meaning |
|--------|---------|
| `⭐ **MUST KNOW**` | Core concept almost certain to be asked |
| `🟠 **IMPORTANT**` | Frequently asked or high practical value |
| `🎯 **SCENARIO**` | Practical / production / design scenario |
| `⚠️ **INTERVIEW TRAP**` | Common misconception or trick question |

**NOTE** : 
- Do not mark every question as MUST KNOW/ IMPORTANT. Use it only for the most important concepts. Use IMPORTANT for frequently asked or high-value questions. Use SCENARIO for production/troubleshooting scenarios. Use INTERVIEW TRAP for common misconceptions or tricky questions. 
- In inverview.md sheet skill do not mark any questions as MUST KNOW or IMPORTANT as all questions are important and should be revised.
---

## 7. GitHub Callouts

Use GitHub-compatible callouts only where they add real value:

```markdown
> [!TIP]
> **Highlight:** Python's `list` is a dynamic array — `append` is amortized O(1), `insert(0, x)` is O(n).
```

```markdown
> [!IMPORTANT]
> **Scenario: Model has 99% training accuracy but 70% on test data.**
>
> Classic overfitting — check data leakage, regularization, model complexity, and train/test split.
```

Also: `> [!WARNING]` for pitfalls/security, `> [!NOTE]` for context. Use them for interview tips, common mistakes, debugging shortcuts, production insights, and security warnings.

---

## 8. Code, Commands & Queries

Include the most interview-relevant snippets for the topic, in the **language/tool that fits** (Python, SQL, JS/TS, Java, Go, Bash, YAML, etc.). If the user names a language, use it.

Rules:

- **Every important snippet states what it does** (one line before or after).
- Keep snippets **short** — the minimum that demonstrates the idea (typically under 15 lines).
- Show **input/output or complexity** when helpful.
- No long command/API dumps without context. Prioritize what practitioners use daily.
- For algorithms/DSA topics: include the **pattern, the template code, and time/space complexity**.

````markdown
## Check disk usage

```bash
df -h
```

Shows filesystem-level disk usage.
````

---

## 9. Diagrams, Tables & Formulas

- **ASCII/Markdown diagrams** for architecture, request flows, pipelines, data flow, and lifecycles. Keep them small (under ~15 lines) inside ```` ```text ```` blocks.
- **Comparison tables** for "X vs Y" questions (e.g. SQL vs NoSQL, REST vs GraphQL, bagging vs boosting, process vs thread).
- **Formulas** (ML/stats/math topics): give the formula once, then a one-line intuition. Use plain text or simple LaTeX (`$...$`) sparingly.

```text
Client → Load Balancer → App Servers → Cache → Database
                                  \→ Message Queue → Workers
```

---

## 10. Scenario-Based Questions

Include realistic scenarios in topic files where applicable. Match the scenario style to the domain:

- **Debugging / production:** app slow, memory leak, deadlock, failing deployment, 500 errors, data inconsistency.
- **Design:** "Design a URL shortener / rate limiter / notification system / RAG chatbot / recommendation engine."
- **ML/AI:** overfitting, data drift, class imbalance, hallucinations, latency/cost of LLM inference, evaluation strategy.
- **Data:** slow query, pipeline failure, duplicate records, schema change, late-arriving data.
- **Security:** leaked secret, injection vulnerability, broken auth, compromised container.
- **Behavioral-technical:** "Tell me about a hard bug you fixed" — provide a STAR-style skeleton, not a fake story.

```markdown
🎯 **Scenario: API latency suddenly doubled after a release.**

Check:

1. Recent deploy diff and config changes
2. Dashboards: latency percentiles (p95/p99), error rate, saturation
3. Downstream dependencies (DB, cache, third-party APIs)
4. Slow queries / N+1 calls
5. Resource limits, GC pauses, connection pool exhaustion
6. Roll back if the cause isn't found fast
```

---

## 11. Production & Real-World Perspective

Wherever relevant, cover: scalability, reliability/HA, performance, observability (logs/metrics/traces), testing, security, cost, maintainability, rollback/failure handling, and trade-offs. Interviewers reward candidates who say **"it depends — here's how I'd decide."**

Include only what is relevant to the topic.

---

## 12. Security Perspective

Where applicable, cover security from the practitioner's angle: authentication vs authorization, secrets handling, encryption (at rest/in transit), input validation and injection, least privilege, dependency/supply-chain risk, and secure defaults. For AI/ML topics, also consider prompt injection, data privacy, and model misuse where relevant.

---

## 13. Domain Adaptation Guide

Adapt emphasis to the domain. Combine profiles for hybrid topics (e.g. "ML system design" = ML + System Design).

**Programming languages** (Python, Java, JS/TS, Go, C++…)
Core syntax and types, memory model, OOP/functional features, collections and complexity, concurrency, error handling, standard library gotchas, testing, performance, idiomatic best practices.

**Web / frameworks** (React, Node, Spring, Django, Angular…)
Architecture and lifecycle, state management, routing, data fetching, auth, performance optimization, testing, common pitfalls, deployment.

**Data Structures & Algorithms**
Patterns (two pointers, sliding window, BFS/DFS, DP, binary search, heaps, graphs), template code, complexity, when to pick which structure, common edge cases. Prefer pattern recognition over problem dumps.

**System Design**
Requirements → estimation → API → data model → high-level design → scaling → bottlenecks. Cover load balancing, caching, sharding/replication, CAP/consistency, queues, CDNs, rate limiting, observability, and trade-offs. Include 4–6 classic design walk-throughs in the final file.

**Databases / SQL / NoSQL**
Joins, indexes, normalization, transactions/ACID, isolation levels, query optimization/`EXPLAIN`, window functions, replication/sharding, NoSQL types and trade-offs.

**AI / Machine Learning**
Problem framing, data prep, algorithms and intuition, bias–variance, evaluation metrics (precision/recall/F1/AUC, RMSE), overfitting/regularization, feature engineering, cross-validation, deep learning basics (backprop, optimizers, CNN/RNN/Transformer), deployment and monitoring (drift), common trade-off questions.

**LLMs / Generative AI**
Transformer basics, tokenization, embeddings, prompting, fine-tuning vs RAG, vector databases, chunking/retrieval, evaluation, hallucination mitigation, agents/tool use, guardrails, latency/cost optimization. For fast-moving areas, prefer stable concepts over specific model/version names, and **verify current facts via web search if a search tool is available**.

**Data Engineering**
Batch vs streaming, ETL/ELT, data modeling (star/snowflake), warehouses/lakes/lakehouses, Spark/Kafka/Airflow concepts, partitioning, idempotency, data quality, schema evolution, late data.

**MLOps**
Experiment tracking, feature stores, model registry, CI/CD for ML, serving patterns, monitoring/drift, retraining triggers, reproducibility.

**Cloud & DevOps** (AWS/Azure/GCP, Docker, Kubernetes, Terraform, CI/CD, Linux)
IAM, networking, compute/storage, containers and orchestration, IaC state/drift, pipelines, observability, HA/DR, cost, security, and production troubleshooting. Prefer diagrams, commands, and troubleshooting checklists.

**Security / DevSecOps**
Threat models, OWASP Top 10, authN/authZ, cryptography basics, secrets management, SAST/DAST/SCA, container/IaC scanning, network security, incident response.

**Networking**
OSI/TCP-IP, DNS, HTTP/HTTPS/TLS, load balancing, NAT, subnets/CIDR, routing, firewalls, and diagnostics (`curl`, `dig`, `traceroute`, `ss`, `tcpdump`).

**Testing / QA / SDLC**
Test pyramid, unit vs integration vs e2e, mocking, TDD, CI integration, flaky tests, code review, Agile/Scrum basics.

**Mobile / Frontend / Other**
Apply the same pattern: fundamentals → lifecycle/architecture → state/data → performance → testing → common pitfalls → scenarios.

**Unknown or niche topic:** Identify the 5–8 themes an interviewer would probe (fundamentals, architecture, usage, trade-offs, failure modes, production), and build the file set around those.

---

## 14. `99_interview_questions.md` — The Most Important File

The final interview revision sheet for the entire topic. Short, interview-ready answers.

**Cover:** frequently asked questions, fundamentals, practical/coding questions, trade-off questions, troubleshooting, scenarios/design, production, security, architecture, and common misconceptions.

### 14.1 Header and Table of Contents (required)

```markdown
# <Topic> — Interview Questions

## Table of Contents

1. [Core Concepts & Architecture](#1-core-concepts--architecture)
2. [Practical Usage & Code](#2-practical-usage--code)
3. [Trade-offs & Comparisons](#3-trade-offs--comparisons)
4. [Performance & Optimization](#4-performance--optimization)
5. [Security](#5-security)
6. [Troubleshooting & Debugging](#6-troubleshooting--debugging)
7. [Production & Best Practices](#7-production--best-practices)
8. [Scenario-Based Questions](#8-scenario-based-questions)
9. [Rapid-Fire Questions](#9-rapid-fire-questions)
```

Adjust sections to the topic (drop irrelevant ones, add domain-specific ones such as "Algorithms & Complexity" or "Model Evaluation").

**TOC link rules (GitHub anchors):** lowercase the heading; remove punctuation except hyphens; replace spaces with hyphens; remove emojis. `&` is dropped but its surrounding spaces remain, giving a **double hyphen** (`Core Concepts & Architecture` → `#core-concepts--architecture`). Every TOC link must resolve to a real `##` heading — verify each one.

### 14.2 Question format

```markdown
## 1. What is <concept>?

Short interview-ready answer.

### Key Points

- Point 1
- Point 2
- Point 3
```

Use a `##` heading per numbered section in the TOC and `###` for individual questions if that keeps anchors clean. Number questions continuously.

### 14.3 Scenario format

```markdown
## 🎯 Scenario: <problem>

### What would you check?

1. Step 1
2. Step 2
3. Step 3

### Interview Answer

Short, direct answer explaining the approach.
```

For **design scenarios**, use: Requirements → Key decisions → Trade-offs → Scaling/failure handling.

### 14.4 Rapid-Fire section (must be last)

Very short Q&A for a 5–10 minute revision right before the interview:

```markdown
## 9. Rapid-Fire Questions

**Q: What is a primary key?**
A: A column (or set) that uniquely identifies each row and cannot be NULL.

**Q: Precision vs recall?**
A: Precision = correct positives / predicted positives; recall = correct positives / actual positives.

**Q: What is Big-O of binary search?**
A: O(log n).
```

Aim for **30–50 items** on broad topics, fewer on narrow ones.

---

## 15. Quality Checklist

Before finishing, verify:

```text
□ Maximum 8 topic files (fewer if the topic is narrow)
□ 99_interview_questions.md exists
□ Notes match the stated/assumed role, level, and interview type
□ Questions are interview-focused; answers are concise
□ Core concepts, trade-offs, and common traps are covered
□ Code/commands/queries included where relevant, each explained
□ Scenarios included (debugging, design, or production as fits the domain)
□ Security and performance covered where relevant
□ Diagrams/tables used where they help
□ Callouts used sparingly and usefully
□ Priority markers used selectively
□ No unnecessary theory or major duplication (cross-references used)
□ Technical claims are accurate; fast-changing facts verified or kept generic
□ Markdown is clean (code fences closed, tables render)
□ TOC links match headings exactly
□ Rapid-fire section is the last section of 99_interview_questions.md
```

---

## 16. Core Objective

The user should be able to go from:

```text
"I need to revise <topic>"
```

to an ordered set of files they can revise start to finish:

```text
01 → Fundamentals
02 → Core Concepts
03 → Components / Architecture
04 → Practical Usage & Code
05 → Trade-offs & Performance
06 → Security / Reliability
07 → Troubleshooting & Scenarios
08 → Production / Advanced
99 → Interview Questions
```

and walk into a technical interview confident — with **high-signal, accurate, speakable answers** rather than academic completeness.