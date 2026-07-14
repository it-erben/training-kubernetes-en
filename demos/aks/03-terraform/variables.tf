# -----------------------------------------------------------------------------
# Input Variables
# -----------------------------------------------------------------------------

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-aks-terraform"
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "germanywestcentral"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-terraform-cluster"
}
