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
  source = local.config.hub.network.enabled ? "../../../modules/hub-network" : null
}

inputs = {
  name                             = "hub"
  resource_group_name              = local.config.hub.resource_group_name
  location                         = local.config.hub.location
  address_space                    = local.config.hub.network.address_space
  runner_subnet_prefixes           = local.config.hub.network.runner_subnet_prefixes
  private_endpoint_subnet_prefixes = local.config.hub.network.private_endpoint_subnet_prefixes
  tags                             = { environment = "hub" }
}
