# Azure Monitoring, Logging & Governance - Interview Revision Notes

## 1. Azure Monitor & Log Analytics

### ⭐ **MUST KNOW**: What is Azure Monitor and how does its architecture work?
**Short Answer:** Azure Monitor is a comprehensive solution for collecting, analyzing, and acting on telemetry from your cloud and on-premises environments.

**Key Points:**
- Collects data into two fundamental types: **Metrics** (numerical values, time-series) and **Logs** (events, traces, performance data).
- Uses **Log Analytics Workspaces** to store log data and allows querying with **KQL (Kusto Query Language)**.
- Can trigger **Alerts** and **Action Groups** based on metrics or logs.

**Architecture Diagram:**
```text
[Data Sources]             [Data Platform]                 [Destinations]
Azure Resources ---->
Applications    ---->   ( Metrics )   ( Logs )     ---->   Alerts / Action Groups
Guest OS        ---->   (time-series) (records)    ---->   Autoscale
Tenant/Sub Logs ---->        Azure Monitor         ---->   Dashboards/Workbooks
Custom Sources  ---->                              ---->   Event Hubs / Storage
```
**Interview Tip:** Always mention that Metrics are for near real-time alerting, while Logs are for deep troubleshooting and trend analysis.

### 🟠 **IMPORTANT**: What is KQL and what are some common queries?
**Short Answer:** Kusto Query Language (KQL) is a read-only request to process data and return results, used extensively in Log Analytics and Application Insights.

**Key Points:**
- Uses a pipeline model with `|` to chain operations.
- Key operators: `search`, `where`, `summarize`, `project`, `extend`, `render`.

**Examples (Sample KQL Queries):**
```kusto
// 1. Find all errors in the last 24 hours
AppTraces 
| where TimeGenerated > ago(24h) 
| where SeverityLevel == 3 // Error
| project TimeGenerated, Message, OperationId

// 2. Count requests by response code
AppRequests
| summarize Count=count() by ResultCode
| order by Count desc

// 3. Render CPU usage chart for VMs
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize AvgCPU = avg(CounterValue) by bin(TimeGenerated, 5m), Computer
| render timechart
```

### 🎯 **SCENARIO**: How do you configure diagnostic settings for an Azure resource?
**Question:** A web app is returning 500 errors. You need to send its logs to Log Analytics for analysis. How do you do this?
**Short Answer:** I would configure a **Diagnostic Setting** on the App Service to send "AppServiceHTTPLogs" and "AppServiceConsoleLogs" to a Log Analytics workspace.
**Command Example:**
```bash
az monitor diagnostic-settings create \
  --name "SendToLogAnalytics" \
  --resource $APP_ID \
  --workspace $WORKSPACE_ID \
  --logs '[{"category": "AppServiceHTTPLogs","enabled": true}]'
```

### ⭐ **MUST KNOW**: What is Application Insights and how does it differ from Azure Monitor?
**Short Answer:** Application Insights is a feature of Azure Monitor specifically designed for Application Performance Management (APM) of live web applications.

**Key Points:**
- Features include distributed tracing (Application Map), live metrics stream, and availability tests (web tests).
- SDKs available for .NET, Java, Node.js, Python.
- Uses auto-instrumentation or custom telemetry tracking.
**Interview Tip:** Mention "Distributed Tracing" and "Application Map" if asked how to identify bottlenecks in microservices.

---

## 2. Azure Governance: Policy, Blueprints, & Management Groups

### ⭐ **MUST KNOW**: Explain Management Groups and Policy Inheritance.
**Short Answer:** Management Groups provide a level of scope above Subscriptions to manage access, policies, and compliance across multiple subscriptions.

**Key Points:**
- Hierarchy: Root Management Group -> Child MGs -> Subscriptions -> Resource Groups -> Resources.
- Policies applied at a higher level are inherited by all child resources.
- Maximum depth is 6 levels (excluding Root and Subscriptions).

> [!NOTE] 
> Custom role definitions and policy assignments can be made at the MG level, reducing administrative overhead for multi-subscription environments.

### 🟠 **IMPORTANT**: What is Azure Policy and how do its effects work?
**Short Answer:** Azure Policy evaluates resources against business rules in JSON format to ensure compliance.

**Key Points:**
- **Initiatives** (Policy Set Definitions) group multiple policies together.
- Evaluates resources upon creation/update and periodically in the background.

**Comparison Table: Azure Policy Effects**
| Effect | Description | Use Case |
|---|---|---|
| **Audit** | Logs non-compliant resources but allows creation. | Assessing current state without breaking changes. |
| **Deny** | Prevents creation of non-compliant resources. | Enforcing strict rules (e.g., allowed regions). |
| **DeployIfNotExists** | Deploys a related resource if missing. | Auto-installing monitoring agents on VMs. |
| **Modify** | Adds, updates, or removes properties/tags on creation/update. | Ensuring standard tags exist. |
| **Append** | Adds additional fields to the resource request. | Forcing allowed IP ranges on DBs. |

### ⚠️ **INTERVIEW TRAP**: Azure Policy vs Azure Blueprints vs ARM Templates
**Question:** When would you use Blueprints over ARM Templates or Policy?
**Short Answer:** ARM templates deploy resources. Policies enforce rules. Blueprints combine both along with RBAC into a single deployable package for environment setup.
*Trap:* Microsoft is deprecating Azure Blueprints in favor of **Bicep** and **Template Specs**. It's crucial to mention you would prefer Bicep/Template Specs for new projects.

### 🎯 **SCENARIO**: Enforcing Tagging Compliance
**Question:** How do you ensure all new Resource Groups have a 'CostCenter' tag?
**Short Answer:** I would assign an Azure Policy with a `Deny` effect at the Subscription or Management Group level for Resource Groups missing the 'CostCenter' tag. Alternatively, use `Modify` or `Append` to inherit it from the subscription.
**Bicep Snippet (Policy Assignment):**
```bicep
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: 'require-costcenter-tag'
  properties: {
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/...' // Built-in Require Tag policy ID
    parameters: {
      tagName: { value: 'CostCenter' }
    }
  }
}
```

### 🟠 **IMPORTANT**: What are Resource Locks?
**Short Answer:** Resource locks prevent accidental deletion or modification of critical Azure resources.

**Key Points:**
- **CanNotDelete:** Authorized users can read/modify, but no one can delete.
- **ReadOnly:** Authorized users can read, but no one can delete or modify (similar to Reader role).
- Locks apply regardless of RBAC permissions (even to Owners).

---

## 3. Cost Management, Advisor & Health

### 🟠 **IMPORTANT**: How do you monitor and control costs in Azure?
**Short Answer:** Using Azure Cost Management to analyze spending, set budgets, and configure alerts.

**Key Points:**
- **Budgets:** Set spending thresholds and trigger Action Groups (e.g., email or webhooks) when exceeded.
- **Cost Analysis:** Break down costs by tags, resource groups, or services.
- **Azure Advisor:** Provides cost-saving recommendations (e.g., right-sizing VMs, buying reserved instances).

### ⭐ **MUST KNOW**: What are the 5 pillars of Azure Advisor?
**Short Answer:** Azure Advisor is a free service that provides personalized best practices.

**Key Points (Categories):**
1. **Cost:** Unused resources, reserved instances.
2. **Security:** Integrates with Defender for Cloud (see [07_security_reliability.md](07_security_reliability.md)).
3. **Reliability:** Availability sets, multi-region redundancy.
4. **Performance:** DB indexing, App Service SKUs.
5. **Operational Excellence:** Service Health alerts, Azure Policy recommendations.

### 🟠 **IMPORTANT**: Azure Service Health vs Azure Status vs Azure Resource Health
**Short Answer:** 
- **Azure Status:** Public page showing global Azure outages.
- **Service Health:** Personalized dashboard showing incidents, planned maintenance, and advisories affecting *your* specific resources.
- **Resource Health:** Health of a single specific resource (e.g., is this specific VM running?).

### 🟠 **IMPORTANT**: What is the Azure Activity Log?
**Short Answer:** It provides insight into subscription-level events (the control plane).
**Key Points:**
- Captures *who* did *what* and *when* for any write/modify/delete operation on an ARM resource.
- Retained for 90 days by default (should be exported to Log Analytics for longer retention).
