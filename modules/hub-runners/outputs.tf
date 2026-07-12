# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

output "vmss_id" {
  value = azurerm_linux_virtual_machine_scale_set.runners.id
}

output "vmss_name" {
  value = azurerm_linux_virtual_machine_scale_set.runners.name
}

output "runner_identity_principal_id" {
  description = "Grant this identity Storage Blob Data Contributor on each environment's state/plans containers."
  value       = azurerm_user_assigned_identity.runner.principal_id
}

output "key_vault_name" {
  value = azurerm_key_vault.runners.name
}

output "key_vault_id" {
  value = azurerm_key_vault.runners.id
}

output "nat_gateway_public_ip" {
  value = azurerm_public_ip.nat.ip_address
}
