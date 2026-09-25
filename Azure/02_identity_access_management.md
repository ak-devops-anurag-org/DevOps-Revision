# Azure Identity & Access Management (IAM) Interview Notes

## Core Identity Concepts

### Q: What is Microsoft Entra ID (formerly Azure AD), and how does a Tenant differ from a Directory?
**A:** Microsoft Entra ID is Azure's cloud-based Identity and Access Management (IAM) service. 
**Key Points:**
- **Tenant:** A dedicated, isolated instance of Entra ID created when an organization signs up for a Microsoft cloud service. It represents the organization.
- **Directory:** The actual container within the tenant that holds users, groups, and applications. (In practice, Tenant and Directory are often used interchangeably).
> [!NOTE] Entra ID is primarily an identity provider (IdP), not a traditional domain controller like on-premises Active Directory.

### Q: What is the difference between Authentication (AuthN) and Authorization (AuthZ) in Azure?
**A:** 
- **Authentication (AuthN):** Proving *who* you are (e.g., verifying a password or MFA token against Entra ID).
- **Authorization (AuthZ):** Determining *what* you can do once authenticated (e.g., Azure RBAC determining if you can delete a VM).
⭐ **MUST KNOW:** Entra ID handles Authentication. Azure RBAC handles Authorization for Azure resources.

---

## Azure RBAC (Role-Based Access Control)

### Q: How does Azure RBAC work?
**A:** RBAC controls access to Azure resources by assigning roles to security principals (users, groups, service principals, or managed identities) at a specific scope.

### Q: What are the core built-in RBAC roles?
**A:**
- **Owner:** Full access to all resources, *including* the right to delegate access (assign roles) to others.
- **Contributor:** Can create and manage all types of Azure resources but *cannot* grant access to others.
- **Reader:** Can view existing Azure resources but cannot make any changes.
⚠️ **INTERVIEW TRAP:** Don't confuse Entra ID roles (Global Admin, User Admin - which manage directory resources) with Azure RBAC roles (Owner, Contributor - which manage Azure resources).

### Q: Explain Role Assignment Scope and Inheritance.
**A:** Scopes define the level at which an RBAC role is applied. Permissions are inherited downwards.
**RBAC Inheritance Flow:**
```mermaid
flowchart TD
    A[Management Group] --> B[Subscription]
    B --> C[Resource Group]
    C --> D[Resource (e.g., Storage Account)]
```
*If you assign 'Reader' at the Subscription level, the user has 'Reader' access to all Resource Groups and Resources within it.*

### Q: What is an Azure Deny Assignment?
**A:** A Deny Assignment explicitly prevents a user from performing specific actions, even if a role assignment grants them access. 
**Key Points:**
- Deny assignments take precedence over role assignments.
- You cannot create your own custom deny assignments (except via Azure Blueprints or managed apps); they are system-created to protect resources.

### Q: How do you create a custom RBAC role?
**A:** You define a JSON file specifying the `Actions` (allowed operations), `NotActions` (excluded operations), and `AssignableScopes`.

**Azure CLI Example:**
```bash
az role definition create --role-definition my-custom-role.json
az role assignment create --assignee user@domain.com --role "My Custom Role" --scope /subscriptions/{sub-id}
```

---

## Managed Identities & Service Principals

### Q: What is a Service Principal and an App Registration?
**A:** 
- **App Registration:** The global definition of an application in Entra ID (like a class in programming).
- **Service Principal:** The local representation/instance of that application in a specific tenant (like an object). It allows the app to be assigned RBAC roles to access resources.

### Q: What are Managed Identities, and why should you use them?
**A:** Managed Identities provide an automatically managed identity in Entra ID for applications to use when connecting to resources that support Microsoft Entra authentication.
⭐ **MUST KNOW:** They eliminate the need for developers to manage credentials (no passwords or certificates to rotate).

### Q: System-assigned vs. User-assigned Managed Identity?
**A:**

| Feature | System-Assigned | User-Assigned |
| :--- | :--- | :--- |
| **Lifecycle** | Tied to a single Azure resource. | Independent resource. |
| **Creation** | Created during or after resource creation. | Created standalone, then assigned. |
| **Sharing** | Cannot be shared. | Can be shared across multiple resources. |
| **Deletion** | Deleted automatically when resource is deleted. | Must be explicitly deleted. |

**Azure CLI Example - Enable System-Assigned MI:**
```bash
az webapp identity assign --name myApp --resource-group myRG
```
*(Note: Using Managed Identities to authenticate with Key Vault is covered in [07_security_reliability.md](07_security_reliability.md))*

---

## Advanced Identity & Security

### Q: What is Conditional Access?
**A:** An Entra ID feature that evaluates signals (user, location, device, risk) to make real-time access decisions (allow, block, or require MFA).
🎯 **SCENARIO:** "Block all logins from outside the US" or "Require MFA if the user connects from an unknown IP."

### Q: What is Privileged Identity Management (PIM)?
**A:** PIM manages, controls, and monitors access to important resources in Azure.
**Key Features:**
- **JIT (Just-In-Time) Access:** Grants temporary, time-bound elevated privileges instead of standing access.
- Requires approval or MFA to activate the role.
- Provides audit history for privileged actions.

### Q: Differentiate between Entra ID B2B and B2C.
**A:**
- **B2B (Business-to-Business):** Inviting guest users from partner organizations into your tenant. They use their own credentials.
- **B2C (Business-to-Consumer):** A customer identity access management (CIAM) solution for user-facing apps. Customers can sign in using social accounts (Google, Facebook) or local email/passwords.

### Q: How do SAML, OAuth 2.0, and OpenID Connect (OIDC) fit into Azure?
**A:**
- **SAML:** Older, XML-based protocol often used for enterprise SSO (Single Sign-On).
- **OAuth 2.0:** Modern framework for *Authorization* (granting apps access to APIs, like Microsoft Graph).
- **OpenID Connect (OIDC):** An identity layer on top of OAuth 2.0 used for *Authentication* (verifying user identity).

---

## Scenario-Based Questions

### 🎯 Q: You have an Azure App Service that needs to read data from an Azure SQL Database. How do you configure this securely without storing connection string passwords?
**A:** 
1. Enable a **System-Assigned Managed Identity** on the App Service.
2. In the Azure SQL Database, create a contained database user linked to that Managed Identity.
3. Grant the database user the `db_datareader` role.
4. The application connects using a connection string specifying `Authentication=Active Directory Managed Identity`.

### 🎯 Q: A developer needs to view the configuration of all resources in the 'Dev' Resource Group but shouldn't be able to change them. They occasionally need to restart a specific VM. How do you implement least privilege?
**A:** 
1. Assign the built-in **Reader** role at the 'Dev' Resource Group scope.
2. Assign the built-in **Virtual Machine Contributor** (or a custom role with only `Microsoft.Compute/virtualMachines/restart/action`) at the specific VM scope.
3. The developer inherits read access to everything but only has restart privileges on the exact VM they need.
