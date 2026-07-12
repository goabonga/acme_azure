# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

variable "name" {
  description = "Name of the resource created by this module."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the resource is created in."
  type        = string
}

variable "location" {
  description = "Azure region for the resource."
  type        = string
}

variable "tags" {
  description = "Tags applied to the resource."
  type        = map(string)
  default     = {}
}
