variable "resource_prefix" {
  description = "Prefix for the ACR"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location for the ACR"
  type        = string
}

variable "acr_sku" {
  description = "SKU for the ACR"
  type        = string
}

variable "tags" {
  description = "Tags for the ACR"
  type        = map(string)
}
