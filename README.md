# ACME Azure

[![CI](https://github.com/goabonga/acme_azure/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/goabonga/acme_azure/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.4.6-844FBA.svg)](https://www.terraform.io)
[![Terragrunt](https://img.shields.io/badge/terragrunt-%3E%3D0.73-1E4472.svg)](https://terragrunt.gruntwork.io)
[![uv](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/uv/main/assets/badge/v0.json)](https://github.com/astral-sh/uv)

Multi-environment [Terragrunt](https://terragrunt.gruntwork.io) infrastructure for
Azure, scaffolded in the spirit of
[cookiecutter-terragrunt-project](https://github.com/goabonga/cookiecutter-terragrunt-project).

## Layout

```
.
├── .bashrc                  # helper commands wrapping the Terragrunt CLI
├── configs/
│   ├── config.dev.yaml      # per-environment values
│   ├── dev.VERSION          # version of the dev environment config
│   └── dev.CHANGELOG.md
├── modules/                 # local Terraform modules (each independently versioned)
│   └── _template/           # copy-paste starting point, see modules/README.md
└── azure/
    └── terragrunt.hcl       # root config: providers, azurerm backend, versions
```

Each environment config and each Terraform module is versioned, tagged and
changelogged independently — see [Versioning and release](#versioning-and-release).

## Requirements

- [Terraform](https://www.terraform.io) / [OpenTofu](https://opentofu.org)
- [Terragrunt](https://terragrunt.gruntwork.io) (>= v0.73, new CLI)
- [Azure CLI](https://learn.microsoft.com/cli/azure/), authenticated
- [uv](https://docs.astral.sh/uv/), for the documentation toolchain and
  `pre-commit`

## Helper commands (`.bashrc`)

The `.bashrc` defines small functions that wrap Terragrunt with the right
flags and an environment switch. Load them into your shell first:

```bash
source .bashrc
```

Then pick an environment (sets `ENV` and the active Azure subscription from
`configs/config.<env>.yaml`):

```bash
switch_env dev
```

All commands take a path to a unit or a subtree:

| Command | What it runs |
| --- | --- |
| `init ./azure/<unit>` | `terragrunt run --all -- init -reconfigure` |
| `plan ./azure/<unit>` | `terragrunt run --all -- plan` over the subtree |
| `apply ./azure/<unit>` | `terragrunt run --all -- apply` (auto-approved) |
| `destroy ./azure/<unit>` | `terragrunt run --all -- destroy` |
| `output ./azure/<unit>` | `terragrunt run --all -- output` |
| `refresh ./azure/<unit>` | `terragrunt run --all -- refresh` |
| `providers ./azure/<unit>` | `terragrunt run -- providers` (single unit) |
| `state ./azure/<unit> list` | `terragrunt run -- state ...` (single unit) |
| `import ./azure/... <addr> <id>` | `terragrunt run -- import ...` (single unit) |
| `show ./azure/<unit>` | `terragrunt run -- show` (single unit) |
| `clean` | remove `.terragrunt-cache`, lockfiles and generated `*.tf` |

Typical loop:

```bash
source .bashrc
switch_env dev
plan  ./azure/<unit>
apply ./azure/<unit>
```

Add another environment by creating `configs/config.<env>.yaml` and running
`switch_env <env>` - no changes to the modules are needed.

## Populating modules

Generate per-unit `terragrunt.hcl` files (and their input skeletons in
`configs/config.<env>.yaml`) with
[terragrunt-generator](https://github.com/goabonga/terragrunt-generator).

For local Terraform modules consumed by those units, copy
[`modules/_template/`](modules/_template) — see
[`modules/README.md`](modules/README.md) for the full steps, including
registering the module in `multicz.toml`.

## Formatting

```bash
make fmt         # terraform fmt + terragrunt hcl format, in place
make fmt-check   # same, non-mutating (what CI runs)
```

## Documentation

See [docs/](docs/index.md) for the project site (built with
[`zensical`](https://github.com/zensical/zensical), see `make docs` /
`make docs-dev`), published to
<https://goabonga.github.io/acme_azure/>.

## Versioning and release

The repository is not a single versioned unit: `docs/` (the documentation
toolchain), `configs/config.<env>.yaml` (each environment), and each
Terraform module under `modules/` are versioned, changelogged and tagged
**independently** by [multicz](https://github.com/goabonga/multicz), driven
by [Conventional Commits](https://www.conventionalcommits.org/) scoped to
each component's files. See [`multicz.toml`](multicz.toml) for the
component list and [`modules/README.md`](modules/README.md) for how to
register a new one.

On every push to `main`, CI computes the bump per component, writes each
`CHANGELOG.md`, and tags (`<component>-v<version>`). Maintainers do not bump
versions or edit changelogs by hand — with one exception: `configs-<env>`
components represent **deployed** state, not a library, so they release
only after a reviewed `terragrunt apply` (plan → PR into `deploy/<env>` →
approval → apply → bump). See
[Deploying an environment](CONTRIBUTING.md#deploying-an-environment) in
CONTRIBUTING.md for the full flow and the required one-time GitHub setup.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow, the commit-message
convention, and the formatting/validation expectations. By participating you
agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

Security issues: please follow the disclosure process in
[SECURITY.md](SECURITY.md).

## License

Distributed under the [MIT License](LICENSE).
