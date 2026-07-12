# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

output "vnet_id" {
  value = azurerm_virtual_network.hub.id
}

output "vnet_name" {
  value = azurerm_virtual_network.hub.name
}

output "runner_subnet_id" {
  value = azurerm_subnet.runners.id
}

output "private_endpoint_subnet_id" {
  value = azurerm_subnet.private_endpoints.id
}

output "blob_private_dns_zone_id" {
  value = azurerm_private_dns_zone.blob.id
}

output "blob_private_dns_zone_name" {
  value = azurerm_private_dns_zone.blob.name
}

output "vault_private_dns_zone_id" {
  value = azurerm_private_dns_zone.vault.id
}

output "vault_private_dns_zone_name" {
  value = azurerm_private_dns_zone.vault.name
}
