# Serverless — AWS Revision Notes

---

## Topics Covered
- AWS Lambda (also in Compute)
- API Gateway
- DynamoDB (also in Database)
- Amazon S3 (as a serverless component)
- AWS Fargate (also in Compute)
- Other Serverless Services Overview

---

# What is Serverless?

- **Serverless ≠ no servers** — you just don't manage/provision/see them
- AWS handles the infrastructure; you only manage code/config
- Originally = **FaaS (Function as a Service)** → Lambda
- Now includes: managed databases, messaging, storage, containers (Fargate)

## Serverless Services in AWS

| Service | Type |
|---|---|
| **AWS Lambda** | FaaS — run code without servers |
| **Amazon DynamoDB** | Serverless NoSQL DB |
| **Amazon S3** | Object storage (no servers) |
| **AWS Fargate** | Serverless containers (ECS/EKS) |
| **Amazon API Gateway** | Serverless HTTP API management |
| **AWS SNS & SQS** | Serverless messaging |
| **AWS Kinesis Data Firehose** | Serverless data streaming/delivery |
| **Aurora Serverless** | Serverless relational DB |
| **AWS Step Functions** | Serverless workflow orchestration |
| **AWS Cognito** | Serverless user authentication |

---

# AWS Lambda

> Full details in [compute.md](./compute.md). Quick summary here:

## Key Points
- **Event-driven** — triggered by: API Gateway, S3, DynamoDB Streams, SQS, SNS, CloudWatch Events, etc.
- **Max execution time: 15 minutes (900 sec)**
- Pay per request + per GB-second of compute (1M requests/month free tier)
- **Auto-scales** — AWS manages concurrency (up to 1,000 concurrent by default)
- **Stateless** — each invocation is independent (use S3, DynamoDB, or ElastiCache for state)

## Lambda Use Cases
- REST API backends (Lambda + API Gateway)
- Event processing (S3 upload → Lambda → resize image)
- Scheduled jobs (CloudWatch Events/EventBridge → Lambda)
- Stream processing (Kinesis/DynamoDB Streams → Lambda)
- Auth/validation (Cognito triggers)

---

# API Gateway

## Key Points
- **Serverless** HTTP/WebSocket API service — acts as a front door to backend services
- Equivalent to: Azure API Management (APIM)
- Works with: **Lambda** (most common), EC2, ECS, HTTP endpoints
- Handles: routing, throttling, auth, SSL termination, CORS, caching, logging
- **REST API** and **HTTP API** (lightweight, lower cost) and **WebSocket API**

## Core Features
- **Request routing**: URL path → specific Lambda/backend
- **Throttling**: per-method and per-stage rate limits
- **API keys** for access control
- **Authorizers**: Lambda Authorizer (custom auth logic) or Cognito User Pool Authorizer
- **Caching**: reduce backend calls (TTL configurable per stage)
- **CORS**: configure allowed origins at API GW level
- **Stages**: dev, staging, prod — independent deployments with separate settings

## API Gateway + Lambda Pattern
```
Client → API Gateway → Lambda → DynamoDB/RDS/S3
```
- Fully serverless, scales automatically, pay per request
- **No servers, no port management, no LBs to configure**

## Common Mistakes
- Not enabling CORS on API Gateway when frontend is on a different domain
- Forgetting to deploy to a **stage** after making changes — API GW changes don't auto-deploy
- Not setting throttling limits → Lambda gets flooded, hits concurrency limit
- Using API GW for non-HTTP workloads — use SQS/SNS instead for async messaging

---

# Serverless Architecture Patterns

## Pattern 1 — Standard REST API
```
Users → Route53 → CloudFront → API Gateway → Lambda → DynamoDB
```
- CloudFront: caches GET responses, DDoS protection
- API Gateway: routing, auth, throttling
- Lambda: business logic
- DynamoDB: low-latency NoSQL storage

## Pattern 2 — S3 + Lambda (Event Processing)
```
Upload to S3 → S3 Event → Lambda → Process (resize, index, move)
```
- Fully serverless, no EC2 needed
- Common: image processing, file validation, ETL

## Pattern 3 — Scheduled Job
```
EventBridge (cron) → Lambda → Any AWS service
```
- Replaces cron jobs on EC2
- Lambda runs on schedule, no server needed

---

# Key Serverless Limits to Remember

| Service | Limit |
|---|---|
| Lambda max execution | **15 minutes** |
| Lambda concurrency | **1,000** concurrent (soft limit) |
| Lambda memory | **128 MB – 10 GB** |
| Lambda deployment size | **50 MB** compressed, **250 MB** uncompressed |
| DynamoDB item size | **400 KB max** |
| API GW default timeout | **29 seconds** (hard limit for REST API) |
| API GW max payload | **10 MB** |
