# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

# Native Terraform tests (`terraform test`, Terraform >= 1.7). All runs use
# `mock_provider` - no real Azure credentials or network access needed, see
# CONTRIBUTING.md#running-terraform-tests.

mock_provider "azurerm" {
  mock_data "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/sttest"
    }
  }
}

variables {
  resource_group_name        = "rg-hub-test"
  location                   = "francecentral"
  private_endpoint_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-pe"
  blob_private_dns_zone_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-test/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
  storage_endpoints = [
    {
      key                  = "dev-state"
      resource_group_name  = "rg-dev"
      storage_account_name = "stdevstate"
    },
    {
      key                  = "dev-plans"
      resource_group_name  = "rg-dev"
      storage_account_name = "stdevplans"
    },
  ]
}

run "creates_one_private_endpoint_per_storage_entry" {
  command = plan

  assert {
    condition     = length(azurerm_private_endpoint.blob) == 2
    error_message = "should create exactly one Private Endpoint per storage_endpoints entry"
  }

  assert {
    condition     = azurerm_private_endpoint.blob["dev-state"].name == "pe-dev-state-blob"
    error_message = "Private Endpoint name should be pe-<key>-blob"
  }
}

run "targets_the_blob_subresource_only" {
  command = plan

  assert {
    condition     = azurerm_private_endpoint.blob["dev-state"].private_service_connection[0].subresource_names[0] == "blob"
    error_message = "must target the blob subresource specifically"
  }

  assert {
    condition     = azurerm_private_endpoint.blob["dev-state"].private_service_connection[0].is_manual_connection == false
    error_message = "connection should be automatic, not manual (no separate approval step)"
  }
}

run "registers_in_the_given_dns_zone" {
  command = plan

  assert {
    condition     = contains(azurerm_private_endpoint.blob["dev-plans"].private_dns_zone_group[0].private_dns_zone_ids, var.blob_private_dns_zone_id)
    error_message = "must register in the blob_private_dns_zone_id passed in, or DNS won't resolve to the private IP"
  }
}

run "no_entries_creates_nothing" {
  command = plan

  variables {
    storage_endpoints = []
  }

  assert {
    condition     = length(azurerm_private_endpoint.blob) == 0
    error_message = "an empty storage_endpoints list should create zero Private Endpoints"
  }
}
