# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "../../../modules/hub-storage-endpoints"
}

locals {
  config = include.root.locals.config
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    private_endpoint_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock/providers/Microsoft.Network/virtualNetworks/mock/subnets/mock"
    blob_private_dns_zone_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock/providers/Microsoft.Network/privateDnsZones/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  resource_group_name        = local.config.hub.resource_group_name
  location                   = local.config.hub.location
  private_endpoint_subnet_id = dependency.network.outputs.private_endpoint_subnet_id
  blob_private_dns_zone_id   = dependency.network.outputs.blob_private_dns_zone_id
  storage_endpoints          = local.config.hub.storage_endpoints
  tags                       = { environment = "hub" }
}
