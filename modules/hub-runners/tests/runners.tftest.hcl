# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

# Native Terraform tests (`terraform test`, Terraform >= 1.7). All runs use
# `mock_provider` - no real Azure credentials or network access needed, see
# CONTRIBUTING.md#running-terraform-tests.

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}

variables {
  name                       = "hub"
  resource_group_name        = "rg-hub-test"
  location                   = "francecentral"
  runner_subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-runners"
  private_endpoint_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-pe"
  vault_private_dns_zone_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-test/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
  github_repo                = "goabonga/acme_azure"
}

run "key_vault_has_no_public_network_access" {
  command = plan

  assert {
    condition     = azurerm_key_vault.runners.public_network_access_enabled == false
    error_message = "the Key Vault must not be reachable over the public internet"
  }

  assert {
    condition     = azurerm_key_vault.runners.network_acls[0].default_action == "Deny"
    error_message = "the Key Vault firewall must default-deny"
  }

  assert {
    condition     = azurerm_key_vault.runners.purge_protection_enabled == true
    error_message = "purge protection should be on for a vault holding the runner registration PAT"
  }
}

run "vmss_disables_password_auth_and_enables_encryption_at_host" {
  command = plan

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.runners.disable_password_authentication == true
    error_message = "SSH key auth only - password authentication must stay disabled"
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.runners.encryption_at_host_enabled == true
    error_message = "encryption at host should be enabled on the runner VMSS"
  }

  assert {
    condition     = length([for ni in azurerm_linux_virtual_machine_scale_set.runners.network_interface : ni if length(ni.ip_configuration[0].public_ip_address) > 0]) == 0
    error_message = "runner instances must not get a public IP - outbound only, via the NAT Gateway"
  }
}

run "vmss_defaults_to_zero_instances" {
  command = plan

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.runners.instances == 0
    error_message = "capacity should default to 0 until scripts/bootstrap-runner.sh scales it up (no cost when idle)"
  }
}

run "vmss_honors_a_custom_instance_count" {
  command = plan

  variables {
    instances = 3
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.runners.instances == 3
    error_message = "a custom instances value should be honored"
  }
}

run "runner_identity_can_read_the_pat_secret" {
  command = plan

  assert {
    condition     = azurerm_role_assignment.runner_reads_pat.role_definition_name == "Key Vault Secrets User"
    error_message = "the runner's managed identity needs Key Vault Secrets User to fetch the PAT at boot"
  }
}
