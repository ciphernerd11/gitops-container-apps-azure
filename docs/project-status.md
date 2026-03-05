# Project Status Report — Disaster Relief Platform

**Repository**: [github.com/ciphernerd11/gitops-aks-microservices](https://github.com/ciphernerd11/gitops-aks-microservices)
**Date**: March 6, 2026

---

## What Has Been Completed

### 1. Application Code (4 Microservices)

| Service | Tech | Port | What It Does |
|---------|------|------|-------------|
| **frontend** | React 18 + NGINX | 80 | Dashboard showing alerts & resources, reverse-proxies API calls |
| **alert-api** | Python / FastAPI | 8000 | POST/GET alerts, Redis caching (degrades gracefully if unavailable) |
| **resource-api** | Node.js / Express | 3000 | CRUD for relief supplies, connects to PostgreSQL, auto-creates table |
| **notification-worker** | Go | — | Polls alert-api every 10s, simulates SMS/Email dispatch |

**Locally verified**: Dashboard shows ● Live with 3 test alerts at `http://localhost:3000`.

---

### 2. Dockerfiles (4 files)

Each service has a production-optimized Dockerfile:

| Service | Base Image | Optimizations |
|---------|-----------|---------------|
| frontend | `node:20-alpine` → `nginx:1.25-alpine` | Multi-stage, NGINX serves static + reverse-proxy |
| alert-api | `python:3.12-slim` | Layer-cached pip install, non-root user |
| resource-api | `node:20-alpine` | `npm ci --omit=dev`, non-root user |
| notification-worker | `golang:1.22-alpine` → `alpine:3.19` | Multi-stage, stripped binary (`-ldflags="-s -w"`), non-root |

---

### 3. Kubernetes Manifests (`kube/`)

| Manifest | Kind | Details |
|----------|------|---------|
| `frontend-deployment.yaml` | Deployment + Service | 2 replicas, ClusterIP:80, health probes |
| `alert-api-deployment.yaml` | Deployment + Service | 2 replicas, ClusterIP:8000, Redis env vars |
| `resource-api-deployment.yaml` | Deployment + Service | 2 replicas, ClusterIP:3000, PG secret ref |
| `notification-worker-deployment.yaml` | Deployment | 1 replica, no Service (background worker) |
| `redis-statefulset.yaml` | StatefulSet + headless Svc | 1 replica, 1Gi PVC, redis-cli probes |
| `postgres-statefulset.yaml` | Secret + StatefulSet + headless Svc | 1 replica, 5Gi PVC, pg_isready probes |

**All manifests include**: `app.kubernetes.io/*` labels, matching selectors, resource requests/limits, Prometheus scraping annotations.

---

### 4. CI/CD Pipeline (`cicd/.github/workflows/main.yml`)

```
Push to main → Build 4 images → Push to ACR → yq updates kube/ tags → Commit back
```

This is a **GitOps-compatible CI pipeline** — it does NOT deploy directly. Instead, it updates the manifests in Git, and ArgoCD handles the actual deployment.

---

### 5. ArgoCD GitOps (`argocd-app.yaml`)

- Points to `kube/` directory of `ciphernerd11/gitops-aks-microservices`
- Auto-sync enabled with **prune** (removes deleted resources) and **selfHeal** (reverts manual changes)
- Targets `default` namespace

---

### 6. Terraform Infrastructure (`infrastructure/`)

| File | Purpose |
|------|---------|
| `main.tf` | Azure provider (v3.90+), optional remote state backend |
| `variables.tf` | Inputs: project name, region, node count/size, K8s version, ACR SKU |
| `resources.tf` | Resource Group + ACR + AKS (Azure CNI, Calico, SystemAssigned identity) + AcrPull role |
| `outputs.tf` | RG name, ACR login server, AKS cluster name, kubeconfig |
| `terraform.tfvars` | Dev defaults: 2× Standard_B2s (~$65/month) |

---

### 7. Monitoring (`monitoring/`)

- **Promtail DaemonSet** with ConfigMap, ServiceAccount, and RBAC for pod log scraping → Loki
- **Prometheus annotations** on all 4 application deployments

---

### 8. Documentation (`docs/`)

- `architecture.md` — System design, Mermaid diagrams, service interactions, GitOps flow
- `deployment-guide.md` — 12-step guide from local code to AKS production

---

### 9. GitHub

- Repo initialized and pushed to `main` branch
- `.gitignore` covers node_modules, __pycache__, .terraform, build artifacts

---

## What Is Remaining

### Must Do (before it works in production)

| # | Task | Effort | Details |
|---|------|--------|---------|
| 1 | **Provision Azure infra** | ~10 min | Run `terraform apply` in `infrastructure/` (requires `az login`) |
| 2 | **Set GitHub Secrets** | ~5 min | Add `ACR_NAME` and `AZURE_CREDENTIALS` in repo Settings → Secrets |
| 3 | **Change Postgres password** | ~1 min | Replace `changeme-in-production` in `kube/postgres-statefulset.yaml` |
| 4 | **Install ArgoCD on AKS** | ~5 min | `kubectl apply` the ArgoCD manifests + apply `argocd-app.yaml` |
| 5 | **Trigger first CI/CD build** | ~1 min | Push to `main` to trigger GitHub Actions pipeline |
| 6 | **Expose frontend externally** | ~5 min | Add LoadBalancer Service or NGINX Ingress |

### Optional Enhancements

| # | Task | Details |
|---|------|---------|
| 7 | Grafana dashboards | Create JSON dashboard files for log/metric visualization |
| 8 | `container_app/` directory | Add docker-compose.yml for local full-stack testing |
| 9 | Sealed Secrets / Key Vault | Replace plain-text postgres Secret with encrypted secrets |
| 10 | Horizontal Pod Autoscaler | Auto-scale APIs based on CPU/memory |
| 11 | HTTPS / TLS | Add cert-manager + Let's Encrypt for production SSL |

---

## DevOps Concepts Used in This Project

### GitOps

**What**: The entire cluster state is defined in Git. Git is the single source of truth — not `kubectl` commands, not manual changes.

**How it works here**:
```
Developer pushes code → CI builds images → CI updates manifests in Git → ArgoCD syncs to AKS
```

**Key principle**: No one runs `kubectl apply` manually. ArgoCD watches the `kube/` directory in Git and auto-reconciles the cluster to match.

---

### CI/CD Pipeline (Continuous Integration / Continuous Delivery)

**CI (Continuous Integration)**: Every push to `main` automatically builds and tests the code.

**CD (Continuous Delivery)**: The updated manifests are committed back to Git, which triggers ArgoCD to deploy.

**Our pipeline flow**:
```
git push → GitHub Actions → docker build × 4 → docker push to ACR → yq updates image tags → git commit
```

**Why `yq` for tag updates?** Instead of using `latest` (which is unpredictable), we tag every image with the exact Git commit SHA. This gives full traceability — you can always tell which commit is running in production.

---

### Infrastructure as Code (IaC) — Terraform

**What**: Infrastructure (servers, networks, registries) is defined in code files, not created manually through the Azure portal.

**Why**: Repeatable, version-controlled, reviewable. You can recreate the entire infra in minutes.

**Our resources**:
- `azurerm_resource_group` — logical container for everything
- `azurerm_container_registry` — stores Docker images (like a private Docker Hub)
- `azurerm_kubernetes_cluster` — the AKS cluster that runs our containers
- `azurerm_role_assignment` — grants AKS permission to pull images from ACR

---

### Kubernetes Concepts Used

| Concept | Where Used | Purpose |
|---------|-----------|---------|
| **Deployment** | All 4 apps | Manages pod replicas, rolling updates |
| **StatefulSet** | Redis, PostgreSQL | Stable network identity + persistent storage |
| **Service (ClusterIP)** | Frontend, APIs | Internal load balancing between pods |
| **Service (Headless)** | Redis, PostgreSQL | Direct DNS to individual StatefulSet pods |
| **Secret** | Postgres password | Stores sensitive data, referenced by pods |
| **PersistentVolumeClaim** | Redis, PostgreSQL | Persistent storage that survives pod restarts |
| **Labels & Selectors** | Everything | How Services find their Pods |
| **Resource Limits** | Everything | CPU/memory caps to prevent runaway containers |
| **Liveness Probe** | Apps + DBs | Kubernetes restarts unhealthy pods |
| **Readiness Probe** | Apps + DBs | Kubernetes only sends traffic to ready pods |

---

### Monitoring Stack

| Tool | Role | How It Works |
|------|------|-------------|
| **Prometheus** | Metrics collection | Scrapes `/metrics` endpoints via pod annotations |
| **Promtail** | Log shipping | DaemonSet on every node → ships logs to Loki |
| **Loki** | Log aggregation | Stores and indexes logs for querying |
| **Grafana** | Dashboards | (Not yet deployed) Visualizes metrics and logs |

---

### Container Strategy

**Multi-stage builds** (frontend, notification-worker): Separate build and runtime stages to keep final images small.

**Non-root users**: All containers run as non-root for security.

**Layer caching**: Dependencies (`package.json`, `requirements.txt`, `go.mod`) are copied and installed before application code to maximize Docker build cache hits.
