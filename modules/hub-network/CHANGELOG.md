# Changelog

All notable changes to this module are documented here. Versions follow
[Semantic Versioning](https://semver.org) and are derived from
[Conventional Commits](https://www.conventionalcommits.org) scoped to this
directory, tagged `modules-hub-network-v<version>`.

## [0.1.0] - 2026-07-12

### Added

- **hub**: add hub vnet module with private dns zone for blob storage (`c4eca4c`)
- **hub**: version the hub terraform modules independently (`6b8fd61`)

### Fixed

- **hub**: lock down key vault network access and harden vmss for checkov (`d82516f`)
