# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

output "private_endpoint_ids" {
  value = { for k, v in azurerm_private_endpoint.blob : k => v.id }
}

output "private_ip_addresses" {
  value = { for k, v in azurerm_private_endpoint.blob : k => v.private_service_connection[0].private_ip_address }
}
