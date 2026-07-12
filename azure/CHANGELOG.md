# Changelog

All notable changes to the Terragrunt root wiring (`azure/terragrunt.hcl`:
providers, remote state backend, version constraints) are documented here.
Versions follow [Semantic Versioning](https://semver.org) and are derived
from [Conventional Commits](https://www.conventionalcommits.org) scoped to
`azure/**`, tagged `azure-v<version>`.

## [0.0.1] - 2026-07-12

### Fixed

- **azure**: require azure ad auth for state and disable storage shared keys (`a825f63`)
- **azure**: remove root versions generate block causing duplicate providers (`0db9c57`)
