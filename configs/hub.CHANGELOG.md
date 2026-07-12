# Changelog

All notable changes to the hub environment (the shared network + self-hosted
GitHub Actions runners, `configs/config.hub.yaml` + `azure/hub/**`) are
documented here. Versions follow
[Semantic Versioning](https://semver.org) and are derived from
[Conventional Commits](https://www.conventionalcommits.org) scoped to those
paths, tagged `configs-hub-v<version>`.

## [0.1.0] - 2026-07-12

### Added

- **hub**: wire terragrunt units and register configs-hub component (`7b90e75`)
- **hub**: add enabled toggle per terragrunt unit (`2078c51`)
- **hub**: generate the runner admin ssh key with terraform (`63ba637`)

### Fixed

- **hub**: lock down key vault network access and harden vmss for checkov (`d82516f`)

### Upstream: azure (v∅ → v0.0.1)

- - build: add azure terragrunt root config (d1af416)
- - build: apply spdx license headers to config and terragrunt files (6144368)
- - build: add azure component and upstream-notes plugin to multicz (5dc726e)
- - fix(azure): require azure ad auth for state and disable storage shared keys (a825f63)
- - fix(azure): remove root versions generate block causing duplicate providers (0db9c57)

### Upstream: modules-hub-network (v∅ → v0.1.0)

- - feat(hub): add hub vnet module with private dns zone for blob storage (c4eca4c)
- - fix(hub): lock down key vault network access and harden vmss for checkov (d82516f)
- - feat(hub): version the hub terraform modules independently (6b8fd61)
- - test(modules): add native terraform tests with mocked azurerm provider (f6332d3)

### Upstream: modules-hub-storage-endpoints (v∅ → v0.1.0)

- - feat(hub): add private endpoints module for environment storage (564cb52)
- - feat(hub): version the hub terraform modules independently (6b8fd61)
- - test(modules): add native terraform tests with mocked azurerm provider (f6332d3)

### Upstream: modules-hub-runners (v∅ → v0.1.0)

- - feat(hub): add ephemeral vmss github runner module (2e70064)
- - fix(hub): lock down key vault network access and harden vmss for checkov (d82516f)
- - feat(hub): version the hub terraform modules independently (6b8fd61)
- - test(modules): add native terraform tests with mocked azurerm provider (f6332d3)
- - feat(hub): generate the runner admin ssh key with terraform (63ba637)
