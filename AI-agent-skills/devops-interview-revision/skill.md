---
name: devops-interview-revision
description: Generates concise, interview-focused Markdown revision notes for any Cloud / DevOps / DevSecOps topic (Linux, Docker, Kubernetes, Terraform, Jenkins, CI/CD, Git, Networking, Azure, GCP, AWS, Helm, Ansible, SonarQube, Trivy, Prisma Cloud, Monitoring, Cloud Security, IaC, Production Troubleshooting, etc.). Use this skill whenever the user wants to revise, prepare for an interview on, or make quick notes, cheat sheets, or Q&A sheets for a Cloud/DevOps technology — even if they only say "I need to revise Kubernetes", "make interview notes for Terraform", or "client round prep for Azure".
---

# Cloud & DevOps Interview Revision Skill

## Purpose

Prepare a Cloud / DevOps engineer for a **client or technical interview** by revising the highest-value concepts, commands, architecture, troubleshooting approaches, and scenario questions.

These are **last-minute revision notes, not tutorials.** Optimize for interview readiness, practical understanding, production troubleshooting, and high-signal revision — not academic completeness.

---

## 1. Workflow

1. **Identify the topic** from the user's request (e.g. Kubernetes, Docker, Terraform, Azure networking).
2. **Determine the working directory** from the request. If the user names a directory, use it. Otherwise create `<topic>-revision/` in the current working location.
3. **Plan the file set** (see Section 2). Decide file names and scope before writing anything.
4. **Write the topic files** in order, then write `99_interview_questions.md` last (it summarizes everything).
5. **Run the quality checklist** (Section 14) and fix gaps.

Do not create unnecessary files (no README, index, or extras) unless the user asks.

---

## 2. File Structure

Generate **at most 8 topic files** plus one final interview file:

```text
01_<name>.md
02_<name>.md
...
08_<name>.md

99_interview_questions.md
```

Rules:

- The **number of topic files depends on topic breadth.** Never create a file just to reach 8. A narrow topic may need only 4–5.
- **File names are topic-specific**, not copied from a template. Order them from fundamentals → architecture → core components → networking → storage/config → security → troubleshooting → production/advanced.
- Each file covers one logical theme.
- If a concept is already explained in an earlier file, **reference it briefly** instead of repeating it:

```markdown
> For the basics of Kubernetes Services, see `04_networking_services.md`.
```

`99_interview_questions.md` is the exception — it intentionally re-summarizes key concepts because it is the final revision sheet.

Example (Kubernetes): `01_kubernetes_fundamentals.md`, `02_architecture_workloads.md`, `03_pods_containers.md`, `04_networking_services.md`, `05_config_storage.md`, `06_scheduling_resources.md`, `07_security_troubleshooting.md`, `08_helm_production.md`, `99_interview_questions.md`.

Example (Docker): `01_docker_basics.md`, `02_images_dockerfile.md`, `03_containers.md`, `04_networking.md`, `05_storage_volumes.md`, `06_security.md`, `07_docker_compose.md`, `08_production_best_practices.md`, `99_interview_questions.md`.

---

## 3. Revision-First Philosophy

**Prioritize (in order):**

1. Most commonly asked interview questions
2. Core concepts
3. Practical DevOps usage
4. Commands
5. Architecture
6. Troubleshooting
7. Production considerations
8. Security
9. Scenario-based questions
10. Common traps and misconceptions

**Avoid:** excessive theory, historical background, beginner filler, repeated explanations across files, rarely used commands/concepts, and large paragraphs.

Content must be **quick to scan** before an interview.

---

## 4. Question-Driven Format

Structure sections as interview questions wherever possible:

```text
Question → Short answer → Key points → Example → Interview tip
```

Template:

````markdown
## What is a Docker image?

A Docker image is a read-only template used to create containers.

### Key Points

- Immutable
- Built in layers
- Contains application + dependencies

### Example

```bash
docker build -t myapp:1.0 .
```

> [!TIP]
> Interview tip: mention layers and caching — it shows you understand build optimization.
````

Skip the Example / Tip parts when they add nothing.

---

## 5. Answer Depth

Answers must be short, straightforward, technically accurate, practical, and easy to **speak aloud** in an interview.

- Most answers: **2–6 lines.**
- Important concepts: add a command, example, or diagram.
- Never sacrifice technical accuracy for brevity.

---

## 6. Priority Markers

Use these consistently, and **selectively** — never mark everything as MUST KNOW.

| Marker | Meaning |
|--------|---------|
| `⭐ **MUST KNOW**` | Core concept almost guaranteed to be asked |
| `🟠 **IMPORTANT**` | Frequently asked or high practical value |
| `🎯 **SCENARIO**` | Production / troubleshooting scenario |
| `⚠️ **INTERVIEW TRAP**` | Common misconception or trick question |


NOTE : 
- Do not mark every question as MUST KNOW/ IMPORTANT. Use it only for the most important concepts. Use IMPORTANT for frequently asked or high-value questions. Use SCENARIO for production/troubleshooting scenarios. Use INTERVIEW TRAP for common misconceptions or tricky questions. 
- In inverview.md sheet skill do not mark any questions as MUST KNOW or IMPORTANT as all questions are important and should be revised.

---

## 7. GitHub Callouts

Use GitHub-compatible callouts only where they add real value:

```markdown
> [!TIP]
> **DevOps Highlights:** `/etc` holds configuration, `/var/log` is the first stop for logs, `/proc` and `/sys` expose kernel/system info.
```

```markdown
> [!IMPORTANT]
> **DevOps Scenario: "Disk Full" but `df -h` shows free space?**
>
> Check whether deleted files are still held open by processes using `lsof`.
```

Also available: `> [!WARNING]` for security warnings and `> [!NOTE]` for context.

Use callouts for: interview tips, production practices, common mistakes, troubleshooting shortcuts, DevOps-specific observations, security warnings, scenario insights.

---

## 8. Commands

For command-heavy topics, include the commands DevOps engineers actually use. **Every important command must state what it does.** Group by task, never dump long unexplained lists.

````markdown
## Check Disk Usage

```bash
df -h
```

Shows filesystem-level disk usage.

```bash
du -sh /var/log/*
```

Shows per-directory usage under `/var/log`.
````

---

## 9. Diagrams

Use simple ASCII / Markdown diagrams whenever they make architecture or flow easier to grasp. Strongly encouraged for: networking, cloud architecture, CI/CD, Kubernetes architecture, Docker architecture, Terraform workflow, request flows.

```text
User
  |
  v
Load Balancer
  |
  v
Kubernetes Service
  |
  v
Pod
  |
  v
Application
```

Keep diagrams small (under ~15 lines) and inside ```` ```text ```` blocks so alignment is preserved.

---

## 10. Scenario-Based Questions

Include realistic production scenarios in topic files where applicable. Use a check-list approach:

```markdown
🎯 **Scenario: Application container is running but users cannot access it.**

Check:

1. Container status
2. Application process
3. Listening port
4. Port mapping
5. Application binding (0.0.0.0 vs 127.0.0.1)
6. Firewall / network rules
7. Logs
```

Scenario categories to draw from: application unavailable, deployment failure, network connectivity failure, resource exhaustion, authentication/authorization issue, configuration problem, security issue, performance issue, production incident, CI/CD failure, infrastructure drift, cloud connectivity, Kubernetes troubleshooting.

---

## 11. Production Perspective

Wherever relevant, cover: HA, scalability, security, observability, backup, disaster recovery, least privilege, secrets management, resource limits, rollback, zero/low-downtime deployment, monitoring, logging, alerting, and incident troubleshooting.

```text
Development → Build → Security Scan → Artifact → Deployment → Monitoring → Troubleshooting
```

Include only what is relevant to the topic.

---

## 12. DevSecOps Perspective

Where applicable, explain security from the DevOps angle:

```text
Source Code → SAST → SCA → Build → Container Scan → IaC Scan → Deploy → Runtime Security
```

Cover as relevant: authentication vs authorization, secrets management, encryption, IAM/RBAC, least privilege, vulnerability scanning, image security, network security, runtime security, compliance, secure configuration.

---

## 13. `99_interview_questions.md` — The Most Important File

This is the final interview revision sheet. It covers the entire topic with short, interview-ready answers.

**Cover:** frequently asked questions, fundamentals, practical questions, troubleshooting, scenarios, production, security, commands, architecture, and common misconceptions.

### 13.1 Required header and Table of Contents

```markdown
# <Topic> — Interview Questions

## Table of Contents

1. [Core Concepts & Architecture](#1-core-concepts--architecture)
2. [Installation & Configuration](#2-installation--configuration)
3. [Commands & Daily Operations](#3-commands--daily-operations)
4. [Networking](#4-networking)
5. [Security](#5-security)
6. [Troubleshooting](#6-troubleshooting)
7. [Production & Best Practices](#7-production--best-practices)
8. [Scenario-Based Questions](#8-scenario-based-questions)
9. [Rapid-Fire Questions](#9-rapid-fire-questions)
```

Adjust sections to the actual topic.

**TOC link rules (GitHub anchors):** lowercase the heading; remove punctuation except hyphens; replace spaces with hyphens; remove emojis. Note that `&` is dropped but its surrounding spaces remain, producing a **double hyphen** (`Core Concepts & Architecture` → `#core-concepts--architecture`). Every TOC link must resolve to a real heading. Verify each one before finishing.

### 13.2 Question format

```markdown
## 1. What is <concept>?

Short interview-ready answer.

### Key Points

- Point 1
- Point 2
- Point 3
```

Number questions continuously within the file, and use `###` sub-headings for section groups if needed so the TOC stays clean.

### 13.3 Scenario format

```markdown
## 🎯 Scenario: <problem>

### What would you check?

1. Step 1
2. Step 2
3. Step 3

### Interview Answer

Short, direct answer explaining the troubleshooting approach.
```

### 13.4 Rapid-Fire section (must be last)

Very short Q&A optimized for a 5–10 minute revision right before the interview:

```markdown
## 9. Rapid-Fire Questions

**Q: What is a container?**
A: A lightweight isolated process that packages an application with its dependencies.

**Q: What is an image?**
A: A read-only template used to create containers.

**Q: What does `docker ps` do?**
A: Lists running containers.
```

Aim for 30–50 rapid-fire items on broad topics.

---

## 14. Topic Adaptation

Adapt content emphasis to the topic. Priorities for common topics:

- **Linux:** filesystem, permissions, processes, services (systemd), networking, disk/memory/CPU, logs, users, shell, troubleshooting, security, production scenarios.
- **Docker:** containers, images, Dockerfile, layers, build cache, multi-stage builds, networking, volumes, Compose, registry, security, resource limits, troubleshooting, production practices.
- **Kubernetes:** architecture, Pods, Deployments, StatefulSets, DaemonSets, Services, CNI, kube-proxy, CoreDNS, networking, ConfigMaps/Secrets, storage, scheduling, probes, RBAC, SecurityContext, Helm, troubleshooting, production deployments.
- **Terraform:** IaC, providers, resources, variables, outputs, modules, state, remote backend, locking, drift, plan/apply, import, lifecycle, workspaces, dependencies, secrets, CI/CD, production practices, troubleshooting scenarios.
- **CI/CD (Jenkins, GitHub Actions, GitLab, Azure DevOps):** pipeline structure, agents/runners, credentials, artifacts, triggers, branching strategies, deployment strategies, rollback, pipeline-as-code, failure troubleshooting.
- **Cloud (Azure / AWS / GCP):** identity & IAM, compute, networking (VNet/VPC, peering, private endpoints, NSG/security groups), storage, load balancing, managed Kubernetes, monitoring, cost, HA/DR, security, connectivity troubleshooting.
- **Networking:** OSI/TCP-IP, DNS, HTTP/HTTPS/TLS, load balancing, NAT, firewalls, subnets/CIDR, routing, troubleshooting with `curl`, `dig`, `traceroute`, `ss`, `tcpdump`.
- **DevSecOps tools (SonarQube, Checkmarx, Trivy, Prisma Cloud):** what each scans (SAST/SCA/container/IaC/runtime), where it sits in the pipeline, quality gates, handling false positives, remediation workflow, failing the build on severity.
- **Monitoring & Logging:** metrics vs logs vs traces, Prometheus/Grafana/ELK concepts, alerting, SLIs/SLOs, golden signals, incident response.
- **Other topics (Helm, Ansible, Git, etc.):** apply the same pattern — fundamentals, core components, daily commands, production practices, troubleshooting, scenarios.

Do not blindly copy the file names or section lists above; derive them from the real scope of the requested topic.

---

## 15. Quality Checklist

Before considering the set complete, verify:

```text
□ Maximum 8 topic files
□ 99_interview_questions.md exists
□ Questions are interview-focused
□ Answers are concise
□ Important concepts are covered
□ Production scenarios are included
□ Commands are included where relevant (each explained)
□ Security is covered
□ Troubleshooting is covered
□ Diagrams are used where useful
□ Important/TIP callouts are used
□ Priority markers used selectively (not everything is MUST KNOW)
□ No unnecessary theory
□ No major duplication (cross-references used instead)
□ Markdown formatting is clean (code fences closed, tables render)
□ Table of Contents links match headings exactly
□ Interview questions are prioritized
□ Rapid-fire section is the last section of 99_interview_questions.md
```

---

## 16. Core Objective

The user should be able to go from:

```text
"I need to revise <topic>"
```

to a set of files they can revise in order:

```text
01 → Fundamentals
02 → Architecture
03 → Core Components
04 → Networking
05 → Storage / Configuration
06 → Scheduling / Security
07 → Troubleshooting
08 → Production / Advanced
99 → Interview Questions
```

and be fully prepared for a Cloud/DevOps client interview — efficiently, with high-signal content only.