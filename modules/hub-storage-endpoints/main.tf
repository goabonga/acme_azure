# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

locals {
  storage_endpoints = { for e in var.storage_endpoints : e.key => e }
}

# The storage accounts themselves are created out-of-band by
# scripts/bootstrap-storage.sh (chicken-and-egg: they back the Terraform
# state backend, so Terraform can't create them) - look them up instead.
data "azurerm_storage_account" "target" {
  for_each            = local.storage_endpoints
  name                = each.value.storage_account_name
  resource_group_name = each.value.resource_group_name
}

resource "azurerm_private_endpoint" "blob" {
  for_each            = local.storage_endpoints
  name                = "pe-${each.key}-blob"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${each.key}-blob"
    private_connection_resource_id = data.azurerm_storage_account.target[each.key].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-${each.key}-blob"
    private_dns_zone_ids = [var.blob_private_dns_zone_id]
  }
}
