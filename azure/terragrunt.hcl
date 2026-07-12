# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

# The 'locals' block defines local variables used within the Terraform configuration.
locals {
  # Retrieves the environment variable 'ENV' or defaults to 'dev'.
  environment = get_env("ENV", "dev")

  # Merges configuration from YAML files based on the environment.
  config = merge(
    yamldecode(file(find_in_parent_folders(format("configs/config.%s.yaml", local.environment)))),
  )
}

# Generates provider configurations.
generate "provider" {
  path      = "generated_provider.tf" # Specifies the file path for generated provider configurations.
  if_exists = "overwrite_terragrunt"  # Defines the behavior if the file already exists.

  # Contents of the generated provider configurations.
  contents = <<EOF
provider "azurerm" {
  features {}
  subscription_id = "${local.config.subscription.id}"
}
EOF
}

# Configures remote state settings for managing Terraform state.
remote_state {
  backend = "azurerm" # Specifies the backend for remote state management.
  config = {
    resource_group_name  = local.config.remote_state.resource_group_name
    storage_account_name = local.config.remote_state.storage_account_name
    container_name       = local.config.remote_state.container_name
    key                  = "${format("%s/%s", local.environment, path_relative_to_include())}/terraform.tfstate"
    # Use the CI job's Azure AD identity (from `az login` / azure/login OIDC)
    # for blob access instead of the storage account's shared key. Needs
    # "Storage Blob Data Contributor" on the container - no key-listing
    # permission, and the account can have shared-key access disabled
    # entirely (see scripts/bootstrap-storage.sh).
    use_azuread_auth = true
  }

  # Generates remote state backend configurations.
  generate = {
    path      = "generated_backend.tf" # Specifies the file path for generated backend configurations.
    if_exists = "overwrite_terragrunt" # Defines the behavior if the file already exists.
  }
}

# Generates Terraform version configurations.
generate "versions" {
  path      = "generated_versions.tf" # Specifies the file path for generated version configurations.
  if_exists = "overwrite_terragrunt"  # Defines the behavior if the file already exists.

  # Contents of the generated version configurations.
  contents = <<EOF
terraform {
  required_version = ">= 1.4.6"   # Sets the minimum required Terraform version.

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
EOF
}
