# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

# Native Terraform tests (`terraform test`, Terraform >= 1.7). All runs use
# `mock_provider` - no real Azure credentials or network access needed, see
# CONTRIBUTING.md#running-terraform-tests.

mock_provider "azurerm" {
  # azurerm parses resource IDs client-side even against a mocked backend,
  # so cross-resource references (e.g. subnet_id = azurerm_subnet.x.id)
  # need Azure-shaped ids on `apply` runs, not mock_provider's default
  # random strings.
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test"
    }
  }

  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
    }
  }

  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/networkSecurityGroups/nsg-test"
    }
  }
}

variables {
  name                = "test"
  resource_group_name = "rg-test"
  location            = "francecentral"
}

run "creates_vnet_with_default_address_space" {
  command = plan

  assert {
    condition     = contains(azurerm_virtual_network.hub.address_space, "10.0.0.0/16")
    error_message = "default address space should include 10.0.0.0/16"
  }
}

run "creates_runner_and_private_endpoint_subnets" {
  command = plan

  assert {
    condition     = contains(azurerm_subnet.runners.address_prefixes, "10.0.1.0/24")
    error_message = "runner subnet should default to 10.0.1.0/24"
  }

  assert {
    condition     = contains(azurerm_subnet.private_endpoints.address_prefixes, "10.0.2.0/24")
    error_message = "private endpoint subnet should default to 10.0.2.0/24"
  }

  assert {
    condition     = azurerm_subnet.private_endpoints.private_endpoint_network_policies == "Disabled"
    error_message = "private endpoint subnet must have network policies disabled, or Private Endpoints can't be placed in it"
  }
}

run "runner_subnet_has_nsg_attached" {
  # mock_provider fully intercepts apply too (no real Azure calls) - needed
  # here because both sides of the assertion are unknown-until-apply IDs.
  command = apply

  assert {
    condition     = azurerm_subnet_network_security_group_association.runners.subnet_id == azurerm_subnet.runners.id
    error_message = "the runner subnet must have its NSG associated"
  }
}

run "creates_blob_and_vault_private_dns_zones" {
  command = plan

  assert {
    condition     = azurerm_private_dns_zone.blob.name == "privatelink.blob.core.windows.net"
    error_message = "blob private DNS zone name must match Azure's well-known zone name exactly, or Private Endpoint DNS resolution breaks"
  }

  assert {
    condition     = azurerm_private_dns_zone.vault.name == "privatelink.vaultcore.azure.net"
    error_message = "vault private DNS zone name must match Azure's well-known zone name exactly"
  }

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.blob.virtual_network_id == azurerm_virtual_network.hub.id
    error_message = "the blob DNS zone must be linked to the hub VNet, or names won't resolve there"
  }
}

run "honors_custom_address_prefixes" {
  command = plan

  variables {
    address_space          = ["10.99.0.0/16"]
    runner_subnet_prefixes = ["10.99.1.0/24"]
  }

  assert {
    condition     = contains(azurerm_virtual_network.hub.address_space, "10.99.0.0/16")
    error_message = "custom address_space should be honored"
  }

  assert {
    condition     = contains(azurerm_subnet.runners.address_prefixes, "10.99.1.0/24")
    error_message = "custom runner_subnet_prefixes should be honored"
  }
}
