# Disaster Relief Platform: Complete Project Walkthrough

Welcome to the Disaster Relief Platform repository. This document serves as a comprehensive guide to understanding the project structure, what each file and folder does, and how the entire workflow (from code to deployment) operates. 

This guide is designed to help you quickly understand the architecture so you can comfortably explain it to team members, stakeholders, or other engineers.

---

## 🏗️ 1. High-Level Architecture

![Disaster Relief Architecture Diagram](C:\Users\VICTUS\.gemini\antigravity\brain\bf8acea3-7983-4020-838e-e52d40c54d12\disaster_relief_architecture_1772882391402.png)

This project is built using a **Microservices Architecture** deployed on **Microsoft Azure (AKS)**, leveraging **Infrastructure as Code (Terraform)**, and continuous deployment via **GitOps (ArgoCD)**.

The system consists of three main backend microservices and one frontend dashboard, backed by Redis (caching/messaging) and PostgreSQL (persistent data).

---

## 📁 2. Folder & File Breakdown

### `/src` (Application Source Code)
Contains the actual microservices that power the platform.

*   **/alert-api**: A Python (FastAPI) service responsible for receiving and broadcasting emergency alerts. It connects to Redis to cache active alerts for fast retrieval.
*   **/resource-api**: A Node.js (Express) service responsible for tracking physical resources (water, medical supplies, personnel) across different locations. It stores its data in PostgreSQL.
*   **/notification-worker**: A Python background worker that connects to Redis. It listens for newly created alerts and processes them (e.g., in a real-world scenario, sending SMS or email notifications).
*   **/frontend**: A React application that displays the Real-Time Coordination Dashboard. It fetches data from both the `alert-api` and `resource-api` to present a unified view.

> **Note on Workflows**: Each service has its own `Dockerfile`. When a developer pushes code, a CI/CD pipeline builds these Docker files into images and pushes them to Azure Container Registry (ACR).

### `/infrastructure` (Infrastructure as Code)
Contains Terraform configurations that automatically provision the underlying Microsoft Azure cloud resources.

*   **`main.tf` & `variables.tf`**: The core entry points defining the Azure provider, backend state configurations, and all global input variables.
*   **`resources.tf`**: The file that glues everything together, calling individual modules (Network, AKS, etc.) to deploy the full stack.
*   **`outputs.tf`**: Defines what information Terraform should print out after a successful deployment (e.g., Kubernetes cluster connection string).
*   **/environments**: Contains variable files (`dev.tfvars`, `prod.tfvars`, etc.). This enables us to use the *same* Terraform code to deploy *different* environments by simply swapping the variable inputs (e.g., using larger VMs for production).
*   **/modules**: Reusable blocks of Terraform code:
    *   **`/acr`**: Azure Container Registry for storing our Docker images.
    *   **`/aks`**: Azure Kubernetes Service, the platform where our microservices will actually run.
    *   **`/log_analytics`**: Azure Monitor Log Analytics workspace for centralized logging and metrics.
    *   **`/network`**: Sets up the Virtual Networks (VNet) and Subnets. *(Recently refactored to securely isolate Application traffic from Database traffic using strict Network Security Groups).*

### `/kube` (Kubernetes Manifests)
Contains the raw YAML files that tell Kubernetes *how* to run our applications.

*   **`alert-api-deployment.yaml`, `resource-api-deployment.yaml`, `frontend-deployment.yaml`, `notification-worker-deployment.yaml`**: These files instruct Kubernetes to pull our Docker images from ACR, define how many replicas to run, set environment variables, and create Services to allow internal communication.
*   **`postgres-statefulset.yaml` & `redis-statefulset.yaml`**: Deployments for our databases. They are defined as `StatefulSets` (rather than generic deployments) to ensure data persistence and guarantee stable network identities.

### `/cicd` & `/.github` (Automation)
(If GitHub Actions are actively used)
These folders contain the pipelines that automate testing, Docker building, and Terraform planning/applying. Whenever code is pushed, these workflows ensure quality and deploy updates automatically.

### `/docs` (Documentation)
Contains supporting documentation like Architecture Diagrams, Deployment Guides, and this Walkthrough.

### `argocd-app.yaml` 
The declarative configuration for ArgoCD (GitOps). Instead of manually running `kubectl apply`, ArgoCD constantly monitors the `/kube` folder in this Git repository. If you change a YAML file in Git, ArgoCD automatically detects it and syncs the changes to the live AKS cluster.

---

## 🔄 3. The Complete Workflow (End-to-End)

To explain this to others, you can trace the life of a feature through the following 4 stages:

### Stage 1: Local Development
1. A developer writes new code in the `/src/frontend` folder.
2. They test it locally.
3. Once satisfied, they commit the code and push it to GitHub.

### Stage 2: Continuous Integration (CI)
1. GitHub Actions detects the push.
2. It runs automated tests.
3. It builds a new Docker image from the `/src/frontend/Dockerfile`.
4. It pushes this newly built image to the Azure Container Registry (provisioned by our `/infrastructure` Terraform code).

### Stage 3: Configuration Update
1. The developer (or the automated CI pipeline) updates the image tag inside `/kube/frontend-deployment.yaml` to point to the newly built image version.
2. This change is committed to the Git repository.

### Stage 4: GitOps Deployment (ArgoCD)
1. ArgoCD, running inside our Azure Kubernetes Cluster, is constantly watching the `/kube` directory in GitHub via the `argocd-app.yaml` configuration.
2. It notices that `frontend-deployment.yaml` was updated.
3. ArgoCD automatically pulls the new configuration and instructs Kubernetes to seamlessly roll out the new frontend version and terminate the old pods.

### 🛡️ What about Infrastructure Changes?
If someone wants to add more nodes to the Kubernetes cluster:
1. They modify `infrastructure/environments/prod.tfvars`.
2. A Terraform pipeline plans and applies the change to Azure.
3. Azure scales up the cluster. The application code (`/src`) and Kubernetes configurations (`/kube`) remain completely untouched.

---

## 🎯 Summary for Stakeholders

*"Our platform is highly automated and modular. **Terraform** provisions the secure Azure cloud foundation (VNet, security groups, AKS). Our developers write **Microservices** in Python and Node.js. When they push code, automated pipelines build it into **Docker containers**. Finally, **ArgoCD** uses Git as the single source of truth to continuously synchronize our latest Kubernetes configurations into the live cluster, ensuring exactly what is in version control is what is running in production."*
