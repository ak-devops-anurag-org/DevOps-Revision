# Azure Advanced Services & Architecture Patterns: Interview Revision Notes

## 1. Messaging & Eventing

### ⭐ What is the difference between Azure Service Bus, Event Grid, and Event Hubs?
**Short Answer:** Service Bus is for high-value enterprise messaging (commands/workflows), Event Grid is for reactive event routing (state changes), and Event Hubs is for big data streaming (telemetry).

**Key Points:**
- **Service Bus:** Brokered messaging, FIFO, transactions, dead-lettering, sessions. Pull model.
- **Event Grid:** Pub/sub event routing, reactive programming. Push model. High throughput.
- **Event Hubs:** Append-only log, partition-based, consumer groups, high-throughput ingestion. Pull model.

**Comparison Table:**

| Feature | Service Bus | Event Grid | Event Hubs |
| :--- | :--- | :--- | :--- |
| **Type** | Message Broker (Commands) | Event Router (Notifications) | Event Streamer (Telemetry) |
| **Model** | Pull (mostly) | Push | Pull (Partitioned) |
| **Order** | Strict FIFO (Sessions) | Unordered | Ordered within partition |
| **Payload** | Heavy (Business Data) | Lightweight (State changes) | Medium (Telemetry) |
| **Use Case** | Order processing, Financials | Resource created, Blob uploaded | IoT telemetry, Log ingestion |

**Interview Tip:** Always clarify if the payload contains the *data itself* (Message -> Service Bus) or just a *notification* that something happened (Event -> Event Grid/Hubs).

### 🟠 Explain Azure Service Bus Queues vs. Topics
**Short Answer:** Queues provide 1:1 point-to-point communication, while Topics provide 1:N publish/subscribe communication using Subscriptions.

**Key Points:**
- **Queues:** Each message is processed by a single consumer.
- **Topics:** A message is sent to a topic and copied to multiple subscriptions based on filter rules. Multiple consumers get their own copy.
- **Dead-Letter Queue (DLQ):** Secondary sub-queue for messages that can't be delivered or processed.
- **Sessions:** Guarantee ordered processing (FIFO) for related messages.

> [!NOTE] 
> See `04_storage_databases.md` for a comparison of Service Bus Queues vs. Storage Queues.

### 🎯 SCENARIO: Choosing a Messaging Service
**Question:** Your architecture has an e-commerce checkout API. Once an order is placed, you need to bill the customer, update inventory, and send an email. Which service do you use?
**Short Answer:** Azure Service Bus Topics.
**Why:** You need 1:N publish/subscribe (one order -> three distinct downstream tasks). You also need reliability (no lost messages if a downstream service goes down), which Service Bus provides. 

**ASCII Diagram: Event-Driven Order Processing**
```text
[Checkout API] 
      │ 
      ▼ (Message: Order Placed)
[Service Bus Topic] ──► [Filter: All] ──────► [Billing Subscription]  ──► [Billing Function]
      │
      ├───────────────► [Filter: Physical] ─► [Inventory Subscription]──► [Inventory App]
      │
      └───────────────► [Filter: All] ──────► [Email Subscription]    ──► [Logic App]
```

## 2. Integration Services

### ⭐ Azure Logic Apps vs. Azure Functions
**Short Answer:** Both are serverless compute services, but Functions are code-centric while Logic Apps are design-centric (visual workflow).

**Key Points:**
- **Functions:** Write custom code (C#, Python, Node.js). Best for complex logic, custom algorithms.
- **Logic Apps:** Drag-and-drop visual designer. Connects services using 1000+ pre-built connectors. Best for orchestrating APIs and services without writing code.

**Comparison Table:**

| Feature | Azure Functions | Azure Logic Apps |
| :--- | :--- | :--- |
| **Development** | Code-first (IDE) | Design-first (Visual UI/JSON) |
| **State** | Stateless (except Durable Functions) | Stateful (every step tracked) |
| **Integration** | Bindings & Triggers | Connectors (SaaS, enterprise, B2B) |
| **Debugging** | Local debugging, App Insights | Run history in Azure Portal |

### 🟠 What is Azure API Management (APIM)?
**Short Answer:** A managed gateway for publishing, routing, securing, and analyzing APIs.

**Key Points:**
- **Gateway:** Routes requests to backends, caches responses.
- **Developer Portal:** Auto-generated catalog for external/internal devs to discover APIs and get keys.
- **Policies:** XML-based rules applied to requests/responses (e.g., rate limiting, JWT validation, transformation).

**Example:**
```xml
<!-- Rate limiting policy to prevent abuse -->
<rate-limit calls="100" renewal-period="60" />
```

## 3. Web, Edge & Real-time Services

### 🟠 What are Azure Cognitive Services / Azure AI Services?
**Short Answer:** Pre-built machine learning models accessible via REST APIs and SDKs.
**Key Points:** Categorized into Vision, Speech, Language, Decision, and OpenAI. Use when you don't want to build/train custom ML models from scratch.

### 🟠 Azure SignalR Service
**Short Answer:** A fully managed service for adding real-time web functionality to applications.
**Key Points:** Abstraction over WebSockets. Pushes content from backend to connected clients instantly (e.g., chat apps, live dashboards).

### 🟠 Azure CDN (Content Delivery Network)
**Short Answer:** A distributed network of servers that caches static web content close to users to reduce latency.
**Key Points:** Uses edge servers (POP locations - Point of Presence). Improves load times and reduces bandwidth costs on the origin server.

## 4. Architecture Patterns & Frameworks

### ⭐ The Azure Well-Architected Framework (WAF)
**Short Answer:** A set of guiding tenets to improve the quality of a workload, consisting of five pillars.

| Pillar | Focus | Key Concept |
| :--- | :--- | :--- |
| **Reliability** | System recovers from failures | Resiliency, Availability, Disaster Recovery |
| **Security** | Protect data and systems | Zero Trust, Identity, Encryption |
| **Cost Optimization** | Maximizing value | Reserved Instances, Autoscaling, Budgets |
| **Operational Excellence** | Keep system running in prod | CI/CD, Monitoring, Infrastructure as Code |
| **Performance Efficiency** | Scale to meet demand | PaaS, Autoscaling, Caching, Partitioning |

⚠️ **INTERVIEW TRAP:** Don't just list the pillars. Be ready to explain *how* you implement them (e.g., "For reliability, I use multi-region deployments and Availability Zones").

### 🟠 Azure Landing Zones
**Short Answer:** The output of a multi-subscription Azure environment that accounts for scale, security, governance, and identity.
**Key Points:** Part of the Cloud Adoption Framework (CAF). Provides a pre-configured environment with Management Groups, Policies, RBAC, and networking (Hub-Spoke).

### 🟠 Common Cloud Architecture Patterns
- **Microservices:** Breaking down monolithic apps into small, independent services.
- **CQRS (Command and Query Responsibility Segregation):** Separating read and write operations into different data stores (e.g., SQL for writes, CosmosDB for reads).
- **Saga Pattern:** Managing distributed transactions across microservices using a sequence of local transactions and compensating actions on failure.

### 🎯 SCENARIO: Multi-Region Architecture
**Question:** How would you design a highly available, globally distributed web application?
**Short Answer:** I would use Azure Front Door or Traffic Manager to route users to the closest region. Inside each region, I'd deploy the app using App Service or AKS across Availability Zones. For data, I'd use Cosmos DB for global multi-write capabilities or Azure SQL with Geo-Replication.

## 5. Hybrid & Migration

### 🟠 Azure Arc
**Short Answer:** A service that extends Azure management and services to any infrastructure.
**Key Points:** Manage Windows/Linux servers, Kubernetes clusters, and data services across on-premises, edge, or other clouds (AWS/GCP) from a single Azure control plane.

### 🟠 Azure Migrate & Migration Strategies
**Short Answer:** A centralized hub to assess and migrate on-premises servers, infrastructure, apps, and data to Azure.

**Key Migration Strategies (The "R"s):**
1. **Rehost (Lift & Shift):** Move VMs as-is. Quickest, but doesn't optimize for cloud.
2. **Refactor (Repackage):** Minor changes to use PaaS (e.g., moving SQL Server VM to Azure SQL Database).
3. **Rearchitect:** Modify code to be cloud-native (e.g., breaking a monolith into microservices).
4. **Rebuild:** Rewrite the app from scratch using cloud-native PaaS/Serverless technologies.

## 6. Relevant CLI Commands

```bash
# Create a Service Bus Namespace
az servicebus namespace create --resource-group myRG --name mySBNamespace --location eastus

# Create a Service Bus Topic
az servicebus topic create --resource-group myRG --namespace-name mySBNamespace --name myTopic

# Create an Event Grid Topic
az eventgrid topic create --name myEGTopic --resource-group myRG --location eastus

# Create an API Management instance (takes a long time to provision)
az apim create --name myAPIM --resource-group myRG --publisher-name "MyCorp" --publisher-email "admin@mycorp.com"
```
