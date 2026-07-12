# ACME Azure

Multi-environment [Terragrunt](https://terragrunt.gruntwork.io) infrastructure for
Azure, scaffolded in the spirit of
[cookiecutter-terragrunt-project](https://github.com/goabonga/cookiecutter-terragrunt-project).

## Layout

```
.
├── .bashrc                  # helper commands wrapping the Terragrunt CLI
├── configs/
│   └── config.dev.yaml      # per-environment values
├── modules/                 # local Terraform modules
└── azure/
    └── terragrunt.hcl       # root config: providers, azurerm backend, versions
```

## Requirements

- [Terraform](https://www.terraform.io) / [OpenTofu](https://opentofu.org)
- [Terragrunt](https://terragrunt.gruntwork.io) (>= v0.73, new CLI)
- [Azure CLI](https://learn.microsoft.com/cli/azure/), authenticated

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

## Documentation

See [docs/](docs/index.md) for the project site (built with
[`zensical`](https://github.com/zensical/zensical), see `make docs` /
`make docs-dev`).
