# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

# Native Terraform tests (`terraform test`, Terraform >= 1.7). Replace this
# placeholder with real assertions once main.tf has real resources - see
# modules/hub-network/tests/*.tftest.hcl for the pattern (mock_provider,
# mock_resource/mock_data for cross-referenced Azure ids) and
# CONTRIBUTING.md#running-terraform-tests.

mock_provider "azurerm" {}

variables {
  name                = "test"
  resource_group_name = "rg-test"
  location            = "francecentral"
}

run "plans_cleanly_with_required_variables" {
  command = plan
}
