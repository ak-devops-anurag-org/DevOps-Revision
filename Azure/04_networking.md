# Azure Networking - Interview Revision Notes

## Core Networking Concepts

### ⭐ **MUST KNOW**: What is an Azure Virtual Network (VNet) and how are subnets used?
**Short answer:** A VNet is the fundamental building block for your private network in Azure, providing isolation and segmentation. Subnets are smaller network segments within a VNet.
**Key Points:**
- VNets are bound to a single region.
- Defined by a private IP address space using CIDR notation (e.g., `10.0.0.0/16`).
- Azure reserves 5 IP addresses per subnet (first 3, last broadcast, and one for DNS).
**Example:** A `10.0.0.0/16` VNet can have a `10.0.1.0/24` subnet for web servers and `10.0.2.0/24` for databases.
**Interview tip:** Always mention that VNet is a Layer 3 overlay network, and it doesn't support multicast or broadcast natively.

### 🟠 **IMPORTANT**: Explain VNet Peering and transitivity.
**Short answer:** VNet peering connects two VNets seamlessly, routing traffic through Microsoft's private backbone.
**Key Points:**
- Regional (same region) vs Global (across regions).
- Peering is **non-transitive**. If A peers with B, and B peers with C, A cannot talk to C unless explicitly peered or routed via a hub (like Azure Firewall).
**Example:** Connecting a dev VNet to a central shared-services VNet.
**Interview tip:** Be prepared to explain how to overcome the non-transitive nature using a Hub-and-Spoke topology with a Network Virtual Appliance (NVA) or Azure Firewall in the hub.

### Hub-Spoke Network Topology Diagram
```text
      [Spoke 1 VNet]                      [Spoke 2 VNet]
      (Web servers)                       (App servers)
            \                                   /
             \ (VNet Peering)    (VNet Peering)/
              \                               /
               +-----------------------------+
               |        [Hub VNet]           |
               |                             |
               |  +-----------------------+  |
               |  | Azure Firewall / NVA  |  |
               |  +-----------------------+  |
               |                             |
               |  +-----------------------+  |
               |  |  VPN / ExpressRoute   |--|--> To On-Premises
               |  |       Gateway         |  |
               |  +-----------------------+  |
               +-----------------------------+
```

## Security & Filtering

### ⭐ **MUST KNOW**: What are Network Security Groups (NSGs)?
**Short answer:** NSGs act as a basic Layer 3/4 firewall to filter inbound and outbound network traffic to Azure resources.
**Key Points:**
- Attached to subnets or individual network interfaces (NICs).
- Rules evaluated by priority (100-4096; lower number = higher priority).
- Has default rules that allow VNet inbound, allow outbound, and deny all other inbound.
**Example:** Rule priority 100: Allow port 443 from Internet.
**Interview tip:** Mention Application Security Groups (ASGs) to group VMs by workload (e.g., "WebServers") instead of managing individual IPs in NSG rules.

### 🟠 **IMPORTANT**: What is Azure Firewall and how does it differ from NSG?
**Short answer:** Azure Firewall is a managed, cloud-based network security service (Layer 3-7) that protects VNet resources with built-in high availability and unrestricted cloud scalability.
**Key Points:**
- Supports FQDN (Fully Qualified Domain Name) filtering.
- Includes Threat Intelligence-based filtering.
- Stateful firewall, acts as a central chokepoint in a hub-and-spoke model.

#### Comparison: NSG vs Azure Firewall
| Feature | NSG | Azure Firewall |
|---------|-----|----------------|
| **OSI Layer** | Layer 3 and 4 | Layer 3 to 7 |
| **Scope** | Subnet or NIC | Entire VNet / Hub |
| **FQDN Filtering** | No | Yes |
| **Threat Intelligence** | No | Yes |
| **Cost** | Free | Paid (hourly + data processed) |

### ⚠️ **INTERVIEW TRAP**: Service Endpoints vs Private Endpoints
**Short answer:** Both secure access to Azure PaaS services, but Service Endpoints keep traffic on the Azure backbone routing to a public endpoint, while Private Endpoints assign a private IP from your VNet to the PaaS service.

#### Comparison: Service Endpoint vs Private Endpoint
| Feature | Service Endpoint | Private Endpoint (Private Link) |
|---------|------------------|---------------------------------|
| **IP Address** | PaaS retains Public IP | PaaS gets a Private IP from VNet |
| **On-Prem Access**| No (requires NAT/public routing) | Yes (over VPN/ExpressRoute) |
| **Cost** | Free | Paid (hourly + data processed) |
| **Data Exfiltration Risk**| Higher (opens route to entire service) | Lower (maps to specific resource) |

**Interview tip:** If they ask how to securely access Azure SQL from an on-premises datacenter over ExpressRoute, the answer is always **Private Endpoint**.

### 🟠 **IMPORTANT**: What is Azure Bastion?
**Short answer:** A fully managed PaaS service that provides secure RDP/SSH access to VMs directly from the Azure portal over TLS.
**Key Points:**
- Deployed in a dedicated `AzureBastionSubnet`.
- VMs do not need public IP addresses.
**Interview tip:** Bastion prevents port scanning and zero-day exploits targeting open RDP/SSH ports on the internet.

## Load Balancing & Routing

### ⭐ **MUST KNOW**: Explain the different Load Balancing options in Azure.

#### Comparison: Load Balancer vs App Gateway vs Front Door vs Traffic Manager
| Feature | Azure Load Balancer | Application Gateway | Azure Front Door | Traffic Manager |
|---------|---------------------|---------------------|------------------|-----------------|
| **Scope** | Regional | Regional | Global | Global |
| **OSI Layer** | Layer 4 (TCP/UDP) | Layer 7 (HTTP/HTTPS)| Layer 7 (HTTP/HTTPS)| DNS-based (Any) |
| **Use Case** | Internal/External VM traffic | Web apps in a region, SSL offload | Global web apps, CDN | Global routing, DR |
| **WAF Support**| No | Yes | Yes | No |

### 🟠 **IMPORTANT**: Detail Azure Application Gateway.
**Short answer:** A web traffic load balancer that enables you to manage traffic to your web applications based on HTTP attributes.
**Key Points:**
- Features URL-path based routing (e.g., `/images` to one pool, `/video` to another).
- Supports SSL termination/offloading to free up backend servers.
- WAF (Web Application Firewall) protects against OWASP top 10 vulnerabilities.

### 🟠 **IMPORTANT**: Detail Azure Front Door.
**Short answer:** A global Layer 7 load balancer and Content Delivery Network (CDN) service.
**Key Points:**
- Uses Microsoft's global edge network (Anycast IP).
- Best for global scale, performance acceleration, and global WAF.

### 🟠 **IMPORTANT**: Explain UDR (User-Defined Routes).
**Short answer:** Custom routes you create to override Azure's default system routes.
**Key Points:**
- Often used for **forced tunneling**, which routes all internet-bound traffic from a VNet to an on-premises firewall or Azure Firewall for inspection.
**Example:** Route table with `0.0.0.0/0` next hop type `VirtualAppliance` pointing to Azure Firewall IP.

## Connectivity & DNS

### ⭐ **MUST KNOW**: VPN Gateway vs ExpressRoute
**Short answer:** Both connect on-premises to Azure. VPN uses encrypted tunnels over the public internet. ExpressRoute uses a private, dedicated connection via a connectivity provider.
**Key Points:**
- VPN: Max ~10 Gbps, internet latency, cheaper. Supports Site-to-Site (S2S), Point-to-Site (P2S), VNet-to-VNet.
- ExpressRoute: Up to 100 Gbps, low latency, private, expensive. Peering types: Private (to VNets) and Microsoft (to PaaS/M365).

### 🟠 **IMPORTANT**: Azure DNS
**Short answer:** Hosting service for DNS domains that provides name resolution using Microsoft Azure infrastructure.
**Key Points:**
- **Public zones:** Resolve domain names on the internet.
- **Private zones:** Resolve domain names within VNets.
- **Alias records:** Point domains directly to Azure resources (like Public IP, Traffic Manager) without needing IP addresses.

## Diagnostics

### 🟠 **IMPORTANT**: What is Network Watcher?
**Short answer:** A regional service to monitor and diagnose conditions at a network scenario level.
**Key Points:**
- **IP Flow Verify:** Checks if a packet is allowed or denied (great for testing NSG rules).
- **Next Hop:** Shows how traffic is being routed (verifies UDRs).
- **NSG Flow Logs:** Logs information about IP traffic flowing through an NSG.

## 🎯 **SCENARIO QUESTIONS**

### 🎯 **SCENARIO 1**: Debugging Connectivity
**Question:** An application in Subnet A cannot reach a database in Subnet B within the same VNet. How do you troubleshoot this?
**Short answer:** Use Network Watcher's IP Flow Verify to check if an NSG is blocking traffic.
**Key points to mention:**
1. Check Effective Security Rules on the VM's NIC.
2. Ensure no UDRs are routing traffic incorrectly.
3. Check the OS-level firewall (Windows Firewall or iptables).

### 🎯 **SCENARIO 2**: Global Application Routing
**Question:** You are deploying a web application in three global regions. You need high availability, SSL offloading, protection from SQL injection, and users must be routed to the closest region. What do you choose?
**Short answer:** Azure Front Door.
**Key points to mention:**
- Front Door provides global routing and closest-edge performance.
- Layer 7 load balancing supports SSL offloading.
- Built-in WAF policy protects against SQL injection globally.

### 🎯 **SCENARIO 3**: Secure On-Premises Connection
**Question:** Your company requires that all internet-bound traffic from Azure VMs must be inspected by an on-premises firewall. How do you implement this?
**Short answer:** Implement Forced Tunneling using a Route Table (UDR).
**Key points to mention:**
- Create a UDR with prefix `0.0.0.0/0`.
- Set the next hop to the Virtual Network Gateway (VPN/ExpressRoute).
- Assign the route table to the VM subnets.

## Relevant Azure CLI Commands

```bash
# Create a VNet and Subnet
az network vnet create -g MyResourceGroup -n MyVNet --address-prefix 10.0.0.0/16 --subnet-name MySubnet --subnet-prefix 10.0.1.0/24

# Create an NSG and a rule
az network nsg create -g MyResourceGroup -n MyNsg
az network nsg rule create -g MyResourceGroup --nsg-name MyNsg -n AllowHTTPS --priority 100 --destination-port-ranges 443 --access Allow --protocol Tcp

# Associate NSG to a Subnet
az network vnet subnet update -g MyResourceGroup --vnet-name MyVNet -n MySubnet --network-security-group MyNsg

# Check IP Flow (Network Watcher)
az network watcher test-ip-flow --resource-group MyResourceGroup --vm MyVM --direction Outbound --protocol TCP --local 10.0.1.4:60000 --remote 10.0.2.4:80
```
