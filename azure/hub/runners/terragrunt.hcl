# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

locals {
  config = include.root.locals.config
}

terraform {
  # null when disabled - terragrunt skips this unit entirely (no plan/apply).
  source = local.config.hub.runners.enabled ? "../../../modules/hub-runners" : null
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    runner_subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock/providers/Microsoft.Network/virtualNetworks/mock/subnets/mock"
    private_endpoint_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock/providers/Microsoft.Network/virtualNetworks/mock/subnets/mock"
    vault_private_dns_zone_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock/providers/Microsoft.Network/privateDnsZones/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name                       = "hub"
  resource_group_name        = local.config.hub.resource_group_name
  location                   = local.config.hub.location
  runner_subnet_id           = dependency.network.outputs.runner_subnet_id
  private_endpoint_subnet_id = dependency.network.outputs.private_endpoint_subnet_id
  vault_private_dns_zone_id  = dependency.network.outputs.vault_private_dns_zone_id
  github_repo                = local.config.hub.runners.github_repo
  runner_labels              = local.config.hub.runners.runner_labels
  runner_version             = local.config.hub.runners.runner_version
  vm_size                    = local.config.hub.runners.vm_size
  instances                  = local.config.hub.runners.instances
  admin_username             = local.config.hub.runners.admin_username
  tags                       = { environment = "hub" }
}
