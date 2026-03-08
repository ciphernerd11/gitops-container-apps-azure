variable "resource_prefix" {
  description = "Prefix for the networking resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location for the Virtual Network"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR block for the Virtual Network"
  type        = list(string)
}

variable "app_subnets_cidr" {
  description = "CIDR blocks for the App Subnets"
  type        = list(string)
}

variable "db_subnets_cidr" {
  description = "CIDR blocks for the DB Subnets"
  type        = list(string)
}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
}
