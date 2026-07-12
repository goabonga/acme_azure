# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "runner" {
  name                = "id-${var.name}-runner"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# RBAC-authorized (no access policies): holds the GitHub PAT used to mint
# runner registration tokens. scripts/bootstrap-runner.sh writes the secret
# after this is created - Terraform never sees the PAT value.
resource "azurerm_key_vault" "runners" {
  name                       = "kv-${var.name}-runners"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 90
  tags                       = var.tags
}

resource "azurerm_role_assignment" "runner_reads_pat" {
  scope                = azurerm_key_vault.runners.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.runner.principal_id
}

# Outbound-only Internet access for the runners (no public IP on the
# instances themselves - they only need to reach github.com/api.github.com).
resource "azurerm_public_ip" "nat" {
  name                = "pip-${var.name}-nat"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "runners" {
  name                = "nat-${var.name}-runners"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "runners" {
  nat_gateway_id       = azurerm_nat_gateway.runners.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "runners" {
  subnet_id      = var.runner_subnet_id
  nat_gateway_id = azurerm_nat_gateway.runners.id
}

resource "azurerm_linux_virtual_machine_scale_set" "runners" {
  name                = "vmss-${var.name}-runners"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.vm_size
  instances           = var.instances
  admin_username      = var.admin_username
  tags                = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic-${var.name}-runners"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.runner_subnet_id
      # No public_ip_address block - outbound-only via the NAT Gateway.
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.runner.id]
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init.sh.tftpl", {
    key_vault_name  = azurerm_key_vault.runners.name
    pat_secret_name = "github-runner-pat"
    github_repo     = var.github_repo
    runner_version  = var.runner_version
    runner_labels   = var.runner_labels
  }))

  depends_on = [
    azurerm_role_assignment.runner_reads_pat,
    azurerm_subnet_nat_gateway_association.runners,
  ]
}
