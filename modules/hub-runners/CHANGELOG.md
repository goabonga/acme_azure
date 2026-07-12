# Changelog

All notable changes to this module are documented here. Versions follow
[Semantic Versioning](https://semver.org) and are derived from
[Conventional Commits](https://www.conventionalcommits.org) scoped to this
directory, tagged `modules-hub-runners-v<version>`.

## [0.1.0] - 2026-07-12

### Added

- **hub**: add ephemeral vmss github runner module (`2e70064`)
- **hub**: version the hub terraform modules independently (`6b8fd61`)
- **hub**: generate the runner admin ssh key with terraform (`63ba637`)

### Fixed

- **hub**: lock down key vault network access and harden vmss for checkov (`d82516f`)
