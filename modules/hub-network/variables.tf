# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

variable "name" {
  description = "Prefix for every resource created by this module (e.g. \"hub\")."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the hub network is created in."
  type        = string
}

variable "location" {
  description = "Azure region for the hub network."
  type        = string
}

variable "address_space" {
  description = "Address space of the hub VNet."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "runner_subnet_prefixes" {
  description = "Address prefixes for the subnet the runner VMSS lives in."
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_endpoint_subnet_prefixes" {
  description = "Address prefixes for the subnet holding Private Endpoints to environment storage."
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
