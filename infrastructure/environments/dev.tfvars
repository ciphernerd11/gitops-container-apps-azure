# ─────────────────────────────────────────────────────
# Dev Environment — Variable Values
# ─────────────────────────────────────────────────────

project_name       = "disaster-relief"
environment        = "dev"
location           = "East US 2"
vnet_cidr           = ["10.0.0.0/16"]
app_subnets_cidr    = ["10.0.1.0/24", "10.0.2.0/24"]
db_subnets_cidr     = ["10.0.3.0/24", "10.0.4.0/24"]
gateway_subnet_cidr = "10.0.0.0/24"

tags = {
  Owner       = "devops-team"
  Project     = "disaster-relief"
  Environment = "dev"
}

allowed_ips        = ["64.236.153.146"]

# Managed Services (Phase 1) — Set these values before running Terraform
db_admin_password  = "Sealion@1204"
# aca_vnet_subnet_id = "Optional: Use if you want to override the default ACA subnet"
