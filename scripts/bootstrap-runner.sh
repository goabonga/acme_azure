#!/usr/bin/env bash

# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Chris <goabonga@pm.me>

# Post-apply glue for the hub self-hosted runners - distinct from
# bootstrap-storage.sh (which bootstraps state/plans storage BEFORE any
# terragrunt unit can run). This one runs AFTER `terragrunt apply` on
# azure/hub/network + azure/hub/runners has succeeded, and:
#
#   1. pushes a GitHub PAT into the hub Key Vault (Terraform never sees it -
#      it can't be committed to git-tracked configs/config.hub.yaml, and
#      modules/hub-runners/cloud-init.sh.tftpl reads it from Key Vault at
#      instance boot to mint a runner registration token).
#   2. scales the runner VMSS up from 0 for the first time.
#
# The PAT itself is a manual, one-time GitHub step (fine-grained personal
# access token, scoped to this repo only, "Administration: write"
# permission - required to mint self-hosted runner registration tokens):
# https://github.com/settings/personal-access-tokens/new
#
# Usage:
#   az login
#   ./scripts/bootstrap-runner.sh [instances]   # default: 1
#
# Requires: az CLI (authenticated, rights to set Key Vault secrets and
# scale the VMSS - see CONTRIBUTING.md for the RBAC), yq.

set -euo pipefail

CONFIG="configs/config.hub.yaml"
INSTANCES="${1:-1}"
KEY_VAULT_NAME="kv-hub-runners"
VMSS_NAME="vmss-hub-runners"

command -v yq >/dev/null || { echo "error: yq is required (https://github.com/mikefarah/yq)" >&2; exit 1; }
command -v az >/dev/null || { echo "error: az CLI is required" >&2; exit 1; }
[[ -f "$CONFIG" ]] || { echo "error: ${CONFIG} not found" >&2; exit 1; }

SUBSCRIPTION_ID=$(yq -r '.subscription.id' "$CONFIG")
RESOURCE_GROUP=$(yq -r '.hub.resource_group_name' "$CONFIG")
GITHUB_REPO=$(yq -r '.hub.runners.github_repo' "$CONFIG")

if [[ -z "$SUBSCRIPTION_ID" || "$SUBSCRIPTION_ID" == "null" || -z "$RESOURCE_GROUP" || "$RESOURCE_GROUP" == "null" ]]; then
	echo "error: .subscription.id / .hub.resource_group_name not set in ${CONFIG}" >&2
	exit 1
fi
az account set --subscription "$SUBSCRIPTION_ID"

if [[ -z "${GITHUB_PAT:-}" ]]; then
	read -rsp "GitHub PAT (fine-grained, Administration:write on ${GITHUB_REPO}): " GITHUB_PAT
	echo
fi
[[ -n "$GITHUB_PAT" ]] || { echo "error: no PAT provided" >&2; exit 1; }

echo "==> writing secret 'github-runner-pat' to Key Vault ${KEY_VAULT_NAME}"
az keyvault secret set \
	--vault-name "$KEY_VAULT_NAME" \
	--name github-runner-pat \
	--value "$GITHUB_PAT" \
	--output none

unset GITHUB_PAT

echo "==> scaling ${VMSS_NAME} to ${INSTANCES} instance(s)"
az vmss scale \
	--name "$VMSS_NAME" \
	--resource-group "$RESOURCE_GROUP" \
	--new-capacity "$INSTANCES" \
	--output none

cat <<EOF

Done. Each instance is ephemeral: it registers, runs at most one job, then
shuts itself down (see modules/hub-runners/cloud-init.sh.tftpl) - capacity
is operator-managed until an event-driven autoscaler exists (deferred, see
CONTRIBUTING.md). Re-run this script whenever you need to change capacity
(it will re-prompt for the PAT and overwrite the Key Vault secret with the
same or a rotated value - harmless):

  ./scripts/bootstrap-runner.sh <n>

Check registration: https://github.com/${GITHUB_REPO}/settings/actions/runners

Once a runner shows up "Idle", flip the GitHub Environment variable
RUNNER_LABEL (for the 'hub' environment first, then others once verified)
to match .hub.runners.runner_labels in configs/config.hub.yaml - see
CONTRIBUTING.md#deploying-an-environment.
EOF
