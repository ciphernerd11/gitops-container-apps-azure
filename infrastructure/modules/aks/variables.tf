variable "resource_prefix" {
  description = "Prefix for the AKS cluster and DNS"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location for the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "aks_node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
}

variable "aks_node_vm_size" {
  description = "VM size for the default node pool"
  type        = string
}

variable "acr_id" {
  description = "ID of the ACR for role assignment"
  type        = string
}

variable "tags" {
  description = "Tags for the AKS cluster"
  type        = map(string)
}
