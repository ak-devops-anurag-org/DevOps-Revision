### Terraform agent skill and MCP server
Timeframe: Sep 2026

- GitHub repo - https://github.com/ak-devops-anurag-org/DevOps-Revision
- dir - Terraform_AI_Agent_Skills


### Critical Secured Banking Client Project: (BFSI project - On-Prem & GCP Cloud)
Timeframe: November 2025 – July 2026
Role: DevOps & DevSecOps Engineer (DevOps & App Modernization Dept.)
Sub-Projects Covered:
InTrade Project (Core Banking On-Prem Infrastructure, Patching & Security Audit)
CEP Project (Corporate Employee Portal — GCP Cloud & and app deployment on GKE with DevSecOps)

Project Scope & Key Achievements :
- Worked in a highly secured banking environment, supporting cloud infrastructure, Kubernetes, DevOps, security, and production operations. 
- GCP & GKE Infrastructure: Provisioned landing zones, VPCs, subnets, GKE, GCS, etc.. using Terraform; managed Google Kubernetes Engine (GKE) and  optimized cloud costs to reduce the monthly cost to ~20%
- Implemented and supported layered application security using Global Load Balancing, WAF, DDoS protection, API rate limiting, and private network access.
- Integrated DevSecOps security tools including Prisma Cloud (CSPM & CWPP), Checkmarx, SonarQube, OPSWAT, and Jenkins into secure application delivery processes; and secured VAPT scan sign-offs
- Supported SIEM/DAM logging, VAPT sign-offs, 120+ audit compliance requirements, CyberArk access management, and zero-downtime patching activities.
- Resolved multiple production network issues helping developers and team to meet deadlines. 
- Site Reliability & Access Control: Executed monthly zero-downtime OS and Database patching cycles; resolved production DB disk space bottlenecks and DB connectivity issues in prod env; managed CyberArk and Active Directory (ADID/LDAP) provisioning 
- 
Tech Stack & Skills: GCP (VPC, GKE, IAM, CloudSQL, Secret Manager), Terraform, Global App LB, WAF, DDoS, Rate Limiting, Prisma Cloud (CSPM/CWPP), Checkmarx, SonarQube, OPSWAT, SIEM, DAM, CyberArk, Guardicore, Zscaler, QuestDB, Commvault, Jenkins, Python, Bash

BFSI project - Banking, Financial Services, and Insurance.



### Agent garage Project: (Cloud and DevSecOps engineer)
Timeframe: July 2026 - Aug 2026
Role: Cloud & DevSecOps Engineer 

- Exploring the existing Azure public service set up - Explore the current set up and the traffic flow to understand the exsisting PubBus setup
- Sub Domain creation and DNS mapping - Got specific subdomains for PubSub service and mapped it to the App gtw LB 
- Routing - Updated/add the app gtw configuration (listener, backend pool, roules) to disable the public access of the pubsub service with any app downtime
- Mirgation - Mirgated the same cofiguration from Dev to UAT and then to the prod client environment 
- App deployment - App deployemnt using CICD on Azure DevOps with CICD on private AKS cluster across multiple env troubleshooting the deployment issues

Tech: Azure, Application Gateway, Azure Web PubSub, Private Endpoints, Private DNS zone, VNet Peering, Network Security, Private AKS 


### Blooger GitOps Project: (Cloud and DevSecOps engineer)
Timeframe: July 2026 - Sept 2026
Role: Cloud & DevSecOps Engineer 

Project Scope & Key Achievements :
- Containerizing app - Tested the app locally, containerized the app using multi-stage docker build
- Local deployment and testing - deployed on kind and tested the app locally 
- IAC - Provisioned infra - Private AKS cluster, Cosmos DB, Private endpoint, Jump VM, etc using terraform
- CI - Created CI pipeline for testing, scaning, building and pushing the images to GHCR 
- CD - after successfuly security sacnning and pushing the image to GHCR triggers a PR to update the image tag in the Blooger GitOps repo for the deploymend vai ArgoCD
- ArgoCD set up - Set up argoCD for CD using HELM and set up self healing and enabled auto sync   
- App Deployment - App deployment using Helm and argoCD on private AKS cluster
- App access - Configured App gtw and exposing on the app UI to the internet users 

Tech stact and skills - Azure, terraform, SonarQube, CICD, GitOps, ArgoCD, Helm, Docker, Kubernetes, Git, GitHub

GitHub repo - https://github.com/Githubak2002/blooger-gitops


### CT-VISA Project

Timeframe: July 2025 – August 2025
Role: DevOps & DevSecOps Engineer

Project Scope & Key Achievements:
- App deployment - App deployment on Azure App service (container based) across multiple environment
- Container Security Hardening: Updated Dockerfiles to use Distroless base images, stripping away shell access (sh/bash) to reduce container attack surfaces 
- SonarQube Integration: Set up SonarQube embedded quality gate checks into Azure DevOps CI/CD pipelines.
- Secrets Management: Migrated plain-text .env variables into Azure Key Vault, linking Vault secrets directly to Azure DevOps Variable Groups across DEV, DEMO, and PROD environments
- Nginx & SSL Configuration: Deployed Nginx reverse proxies with SSL/TLS domain certificates, resolving proxy timeout issues and browser "Blocked: Mixed-Content" warnings

Tech Stack & Skills: Azure DevOps, YAML Pipelines, Docker (Distroless), SonarQube, Azure Key Vault, Nginx, SSL/TLS, ACR, Bash scripting

### CAM (Celebal Alliance Manager) Project
Timeframe: September 2025 – October 2025
Role: DevOps Engineer

Project Scope & Key Achievements:
- Azure App Service Deployments: Deployed multi-tier web application frontend and backend services to Microsoft Azure App Services
- CI/CD Pipeline Optimization: Restructured build and execution steps in Azure DevOps YAML pipelines, cutting backend build/deployment processing times from 10–20 minutes down to 1–3 minutes
- Observability & Logging: integrated Azure Monitor, App Service Live Metrics, and Azure Log Analytics
- Redirect & App Registrations: Configured Azure Active Directory App Registrations and solved OAuth Redirect URL mismatches
- Cost Analysis: Evaluated App Service Plan pricing structures, estimating baseline operational costs at ~₹3000/month

Tech Stack & Skills: Azure App Service, Azure DevOps (YAML CI/CD), Winston Logger, Azure Monitor, Log Analytics, Azure App Registrations, Node.js


### DR Migrate & Azure Migrate POC (Celebal Tech / TCC Partnership)
Timeframe: August 2025 – September 2025
Role: Cloud Migration & Infrastructure Engineer

Project Scope & Key Achievements:
- Client intraction : Had multiple calls with international clients to help them set up azure migrate and explore their onprem inventory (servers and SQL DBs)
- Appliance Deployment & Discovery: Configured and registered the Azure Migrate Appliance to conduct agentless discovery across 326+ servers across VMware, Hyper-V, and physical environments
- Infrastructure as Code (IaC): Authored reusable Terraform scripts to deploy test infrastructure on AWS, including VPCs, subnets, and EC2 instances running SQL Server databases
- Defect & Network Troubleshooting: Resolved validation errors, appliance service startup failures, and inter-subnet EC2 ping connectivity issues
- Migration Architecture & Reporting: Drafted GDT-formatted pre-requisite checklists, security flow documents, and Power BI dashboard integration guidelines for client migration roadmaps

Tech Stack & Skills: AWS (EC2, VPC, Subnets, Security Groups), Terraform, Azure Migrate Appliance, VMware, Hyper-V, Power BI, SPN Security



### Production-Grade MLOps Pipeline on Kubernetes (Self-Directed)
Built a complete MLOps lifecycle on a local Kubernetes (Kind) cluster, applying GitOps/DevOps principles to the ML pipeline domain.
Implemented an orchestrated pipeline using Kubeflow Pipelines (KFP v2 SDK), porting data validation, EDA, cleaning, feature engineering, preprocessing, training, and evaluation into modular KFP components.
Deployed MLflow with a PostgreSQL metadata backend and persistent-volume artifact storage via Helm, resolving dependency conflicts with a custom Docker image.
Deployed KServe for model serving, laying the foundation for automated model registration and inference deployment.
Documented DevOps-to-MLOps transferable practices (e.g., "deploy the pipeline, not the model").

Tech: Kubernetes (Kind), Kubeflow Pipelines, MLflow, KServe, PostgreSQL, Helm, Docker, MLOps


