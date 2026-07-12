#!/usr/bin/env bash

# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

# One-time bootstrap: creates the Azure storage backing an environment's
# Terragrunt remote state and its private `terragrunt plan` upload target
# (see multicz.toml / terragrunt-plan.yml), read from
# configs/config.<env>.yaml. Must run before the first plan/apply for that
# environment - the remote_state backend can't create its own storage
# account, and it's a chicken-and-egg problem terragrunt doesn't solve.
#
# This is a manual, operator-run script (needs rights to create resource
# groups/storage accounts in the environment's subscription) - it is not
# part of any CI pipeline, which only ever gets narrowly-scoped RBAC on
# the storage accounts this script creates.
#
# Usage:
#   az login   # or: az login --identity, if run from a trusted host
#   ./scripts/bootstrap-storage.sh <env> [location]
#
#   # all environments:
#   for env in dev staging prod; do ./scripts/bootstrap-storage.sh "$env"; done
#
# Requires: az CLI (authenticated), yq (https://github.com/mikefarah/yq).

set -euo pipefail

ENV_NAME="${1:?usage: bootstrap-storage.sh <env> [location]}"
LOCATION="${2:-francecentral}"
CONFIG="configs/config.${ENV_NAME}.yaml"

if [[ ! -f "$CONFIG" ]]; then
	echo "error: ${CONFIG} not found" >&2
	exit 1
fi
command -v yq >/dev/null || { echo "error: yq is required (https://github.com/mikefarah/yq)" >&2; exit 1; }
command -v az >/dev/null || { echo "error: az CLI is required" >&2; exit 1; }

SUBSCRIPTION_ID=$(yq -r '.subscription.id' "$CONFIG")
if [[ -z "$SUBSCRIPTION_ID" || "$SUBSCRIPTION_ID" == "null" ]]; then
	echo "error: .subscription.id is not set in ${CONFIG}" >&2
	exit 1
fi
az account set --subscription "$SUBSCRIPTION_ID"

# Creates (idempotently) a resource group, a hardened storage account
# (TLS1.2+, HTTPS-only, no public blob access, versioning + 30-day soft
# delete) and a private container inside it.
create_storage() {
	local purpose="$1" rg="$2" account="$3" container="$4"

	if [[ -z "$rg" || "$rg" == "null" || -z "$account" || "$account" == "null" || -z "$container" || "$container" == "null" ]]; then
		echo "skip ${purpose}: resource_group_name/storage_account_name/container_name not set in ${CONFIG}"
		return
	fi

	echo "==> ${purpose}: resource group ${rg}"
	az group create --name "$rg" --location "$LOCATION" --output none

	if az storage account show --name "$account" --resource-group "$rg" --output none 2>/dev/null; then
		echo "==> ${purpose}: storage account ${account} already exists"
	else
		echo "==> ${purpose}: creating storage account ${account}"
		az storage account create \
			--name "$account" \
			--resource-group "$rg" \
			--location "$LOCATION" \
			--sku Standard_GRS \
			--kind StorageV2 \
			--min-tls-version TLS1_2 \
			--https-only true \
			--allow-blob-public-access false \
			--output none
	fi

	echo "==> ${purpose}: enabling blob versioning + 30-day soft delete"
	az storage account blob-service-properties update \
		--account-name "$account" \
		--resource-group "$rg" \
		--enable-versioning true \
		--enable-delete-retention true \
		--delete-retention-days 30 \
		--output none

	if az storage container show --name "$container" --account-name "$account" --auth-mode login --output none 2>/dev/null; then
		echo "==> ${purpose}: container ${container} already exists"
	else
		echo "==> ${purpose}: creating container ${container}"
		az storage container create \
			--name "$container" \
			--account-name "$account" \
			--auth-mode login \
			--public-access off \
			--output none
	fi
}

REMOTE_STATE_RG=$(yq -r '.remote_state.resource_group_name' "$CONFIG")

create_storage "remote state" \
	"$REMOTE_STATE_RG" \
	"$(yq -r '.remote_state.storage_account_name' "$CONFIG")" \
	"$(yq -r '.remote_state.container_name' "$CONFIG")"

# Plans share the remote-state resource group; only the account/container
# differ (configs/config.<env>.yaml has no separate `plans.resource_group_name`).
create_storage "plans" \
	"$REMOTE_STATE_RG" \
	"$(yq -r '.plans.storage_account_name' "$CONFIG")" \
	"$(yq -r '.plans.container_name' "$CONFIG")"

cat <<EOF

Done for '${ENV_NAME}'. Grant RBAC next (Azure Portal or 'az role assignment create'):
  - remote state container: Storage Blob Data Contributor for the
    terragrunt-plan.yml / terragrunt-apply.yml identity (AZURE_CLIENT_ID).
  - plans container: Storage Blob Data Contributor for the same identity
    (upload), and Storage Blob Data Reader for the approver group (download).
See CONTRIBUTING.md#deploying-an-environment.
EOF
