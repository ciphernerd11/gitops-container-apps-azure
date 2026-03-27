# ─────────────────────────────────────────────────────
# Local Values & Shared Tags
# ─────────────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

data "http" "myip" {
  url = "https://ifconfig.me/ip"
}

module "tags" {
  source      = "./modules/tag"
  environment = var.environment
  project     = var.project_name
  owner       = var.owner
  cost_center = var.cost_center
}

# ─────────────────────────────────────────────────────
# 1. Base Infrastructure (Group & Network)
# ─────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = merge(module.tags.tags, { Name = "rg-${local.name_prefix}" })
}

module "network" {
  source              = "./modules/network"
  resource_prefix     = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_cidr           = var.vnet_cidr
  app_subnets_cidr    = var.app_subnets_cidr
  db_subnets_cidr     = var.db_subnets_cidr
  gateway_subnet_cidr = var.gateway_subnet_cidr
  tags                = module.tags.tags
}

# ─────────────────────────────────────────────────────
# 2. Supporting Services (Governance & Security)
# ─────────────────────────────────────────────────────

module "log_analytics" {
  source              = "./modules/log_analytics"
  resource_prefix     = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = module.tags.tags
}

module "app_insights" {
  source              = "./modules/app_insights"
  resource_prefix     = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  workspace_id        = module.log_analytics.workspace_id
  tags                = module.tags.tags
}

module "keyvault" {
  source              = "./modules/keyvault"
  resource_prefix     = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  # Passing subnet IDs for Network ACLs
  app_subnet_ids = module.network.app_subnet_ids
  allowed_ips    = distinct(concat(var.allowed_ips, [chomp(data.http.myip.response_body)]))
  tags           = module.tags.tags
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = var.db_admin_password
  key_vault_id = module.keyvault.id
}

# ─────────────────────────────────────────────────────
# 3. Application Hosting (Registry & Cluster)
# ─────────────────────────────────────────────────────

module "acr" {
  source              = "./modules/acr"
  resource_prefix     = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  acr_sku             = var.acr_sku
  tags                = module.tags.tags
}


# ─────────────────────────────────────────────────────
# 4. Azure Container Apps (ACA) — Target Platform
# ─────────────────────────────────────────────────────

module "aca_environment" {
  source                     = "./modules/aca_environment"
  resource_prefix            = local.name_prefix
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  log_analytics_workspace_id  = module.log_analytics.workspace_id
  vnet_subnet_id             = coalesce(var.aca_vnet_subnet_id, module.network.app_subnet_ids[1]) # Use second app subnet for ACA
  app_insights_connection_string = module.app_insights.connection_string
  tags                       = module.tags.tags
}

resource "azurerm_user_assigned_identity" "aca_identity" {
  name                = "id-aca-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = module.tags.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}

# ─────────────────────────────────────────────────────
# 5. Managed Data Tier (PostgreSQL & Redis)
# ─────────────────────────────────────────────────────

module "postgresql" {
  source              = "./modules/postgresql"
  resource_prefix     = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_id              = module.network.vnet_id
  subnet_id           = module.network.db_subnet_ids[0]
  admin_password      = var.db_admin_password
  tags                = module.tags.tags
}

module "redis" {
  source              = "./modules/redis"
  resource_prefix     = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = module.tags.tags
}

# ─────────────────────────────────────────────────────
# 6. Microservices (Azure Container Apps)
# ─────────────────────────────────────────────────────

module "resource_api" {
  # (No changes here, keeping for context)
  source                       = "./modules/aca_app"
  name                         = "resource-api"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = module.aca_environment.id
  identity_id                  = azurerm_user_assigned_identity.aca_identity.id
  image                        = var.resource_api_image
  container_port               = 3000
  is_external_ingress          = false
  app_insights_connection_string = module.app_insights.connection_string
  env_vars = [
    { name = "PGHOST", value = module.postgresql.fqdn },
    { name = "PGUSER", value = "psqladmin" },
    { name = "PGDATABASE", value = "resources" },
    { name = "PGPORT", value = "5432" }
  ]
  secrets = [
    { name = "pgpassword", value = azurerm_key_vault_secret.db_password.value }
  ]
  tags = module.tags.tags
}

module "alert_api" {
  source                       = "./modules/aca_app"
  name                         = "alert-api"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = module.aca_environment.id
  identity_id                  = azurerm_user_assigned_identity.aca_identity.id
  image                        = var.alert_api_image
  container_port               = 8000
  is_external_ingress          = false
  app_insights_connection_string = module.app_insights.connection_string
  env_vars = [
    { name = "REDIS_HOST", value = module.redis.hostname },
    { name = "REDIS_PORT", value = "6379" }
  ]
  tags = module.tags.tags
}

module "alert_generator" {
  source                       = "./modules/aca_app"
  name                         = "alert-generator"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = module.aca_environment.id
  identity_id                  = azurerm_user_assigned_identity.aca_identity.id
  image                        = var.alert_generator_image
  ingress_enabled              = false # Background worker
  app_insights_connection_string = module.app_insights.connection_string
  env_vars = [
    { name = "REDIS_HOST", value = module.redis.hostname },
    { name = "REDIS_PORT", value = "6379" }
  ]
  tags = module.tags.tags
}

module "notification_worker" {
  source                       = "./modules/aca_app"
  name                         = "notification-worker"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = module.aca_environment.id
  identity_id                  = azurerm_user_assigned_identity.aca_identity.id
  image                        = var.notification_worker_image
  ingress_enabled              = false # Background worker
  app_insights_connection_string = module.app_insights.connection_string
  env_vars = [
    { name = "PGHOST", value = module.postgresql.fqdn },
    { name = "PGUSER", value = "psqladmin" },
    { name = "PGDATABASE", value = "resources" }
  ]
  secrets = [
    { name = "pgpassword", value = azurerm_key_vault_secret.db_password.value }
  ]
  tags = module.tags.tags
}

module "frontend" {
  source                       = "./modules/aca_app"
  name                         = "frontend"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = module.aca_environment.id
  identity_id                  = azurerm_user_assigned_identity.aca_identity.id
  image                        = var.frontend_image
  container_port               = 80
  is_external_ingress          = true
  app_insights_connection_string = module.app_insights.connection_string
  env_vars = [
    { name = "API_BASE_URL", value = "https://${module.resource_api.fqdn}" },
    { name = "ALERT_API_URL", value = "https://${module.alert_api.fqdn}" }
  ]
  tags = module.tags.tags
}

# ─────────────────────────────────────────────────────
# 7. GitOps & Application Configuration
# ─────────────────────────────────────────────────────

