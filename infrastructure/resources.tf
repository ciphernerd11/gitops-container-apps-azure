# ─────────────────────────────────────────────────────
# Local Values
# ─────────────────────────────────────────────────────

locals {
  resource_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ─────────────────────────────────────────────────────
# 1. Resource Group
# ─────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_prefix}"
  location = var.location
  tags     = local.common_tags
}

# ─────────────────────────────────────────────────────
# 2. Azure Container Registry (ACR) Module
# ─────────────────────────────────────────────────────

module "acr" {
  source = "./modules/acr"

  resource_prefix     = local.resource_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  acr_sku             = var.acr_sku
  tags                = local.common_tags
}

# ─────────────────────────────────────────────────────
# 3. Azure Kubernetes Service (AKS) Module
# ─────────────────────────────────────────────────────

module "aks" {
  source = "./modules/aks"

  resource_prefix     = local.resource_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  kubernetes_version  = var.kubernetes_version
  aks_node_count      = var.aks_node_count
  aks_node_vm_size    = var.aks_node_vm_size
  acr_id              = module.acr.id
  tags                = local.common_tags
}
