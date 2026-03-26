# ─────────────────────────────────────────────────────
# UAT Environment — Variable Values
# ─────────────────────────────────────────────────────

project_name       = "disaster-relief"
environment        = "uat"
location           = "East US"
vnet_cidr           = ["10.1.0.0/16"]
app_subnets_cidr    = ["10.1.1.0/24", "10.1.2.0/24"]
db_subnets_cidr     = ["10.1.3.0/24", "10.1.4.0/24"]
gateway_subnet_cidr = "10.1.0.0/24"

tags = {
  Owner       = "devops-team"
  Project     = "disaster-relief"
  Environment = "uat"
}
