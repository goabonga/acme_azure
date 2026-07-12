# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

variable "storage_endpoints" {
  description = <<-EOT
    One entry per storage account (created out-of-band by
    scripts/bootstrap-storage.sh, not by Terraform) to reach privately from
    the hub VNet. `key` must be unique, e.g. "dev-state", "dev-plans".
  EOT
  type = list(object({
    key                  = string
    resource_group_name  = string
    storage_account_name = string
  }))
}

variable "resource_group_name" {
  description = "Resource group the Private Endpoints are created in (the hub's)."
  type        = string
}

variable "location" {
  description = "Azure region for the Private Endpoints."
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet the Private Endpoints are placed in (modules/hub-network's private_endpoint_subnet_id)."
  type        = string
}

variable "blob_private_dns_zone_id" {
  description = "Private DNS zone id for privatelink.blob.core.windows.net (modules/hub-network's blob_private_dns_zone_id)."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
