# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

variable "name" {
  description = "Prefix for every resource created by this module (e.g. \"hub\")."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the runners are created in."
  type        = string
}

variable "location" {
  description = "Azure region for the runners."
  type        = string
}

variable "runner_subnet_id" {
  description = "Subnet the VMSS instances are placed in (modules/hub-network's runner_subnet_id). No public IP - outbound only, via the NAT Gateway this module creates."
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet the Key Vault's Private Endpoint is placed in (modules/hub-network's private_endpoint_subnet_id)."
  type        = string
}

variable "vault_private_dns_zone_id" {
  description = "Private DNS zone id for privatelink.vaultcore.azure.net (modules/hub-network's vault_private_dns_zone_id)."
  type        = string
}

variable "github_repo" {
  description = "\"<owner>/<repo>\" the runners register against."
  type        = string
}

variable "runner_labels" {
  description = "Labels the ephemeral runner registers with (comma-separated, no spaces)."
  type        = string
  default     = "self-hosted,azure,hub"
}

variable "runner_version" {
  description = "actions/runner release to install (see https://github.com/actions/runner/releases)."
  type        = string
  default     = "2.321.0"
}

variable "vm_size" {
  description = "VMSS instance size. Modest by default - bump if jobs need more CPU/RAM."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "instances" {
  description = <<-EOT
    Fixed VMSS capacity. Starts at 0 (no cost) until
    scripts/bootstrap-runner.sh does the first scale-out. There is no
    event-driven autoscaler yet (deferred - see CONTRIBUTING.md); an
    operator scales this manually (`az vmss scale`) or via this variable.
  EOT
  type        = number
  default     = 0
}

variable "admin_username" {
  description = "Local admin user created on each instance (SSH key auth only, no password)."
  type        = string
  default     = "runneradmin"
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
