variable "environment" {
  type        = string
  description = "Target environment (e.g. dev, prod)"
}

variable "project" {
  type        = string
  description = "Project or platform name"
}

variable "owner" {
  type        = string
  description = "Team or individual owner"
}

variable "cost_center" {
  type        = string
  description = "Cost center for billing"
}
