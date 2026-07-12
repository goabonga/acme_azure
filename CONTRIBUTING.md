# Contributing to ACME Azure

Thanks for taking the time to contribute. This document is the short version
of how to propose a change and what the project expects in return.

## Code of Conduct

Participation in this project is governed by the
[Code of Conduct](CODE_OF_CONDUCT.md). By contributing you agree to abide by
its terms.

## Development setup

```bash
git clone https://github.com/goabonga/acme_azure.git
cd acme_azure

# documentation toolchain
uv sync --group doc
uv run pre-commit install   # installs the pre-commit + commit-msg hooks

# terragrunt / terraform
source .bashrc
switch_env dev
```

## Quality gates

Before pushing, make sure your change passes the same gates the `ci`
workflow runs:

```bash
# Terraform / Terragrunt (azure/, modules/)
terraform fmt -check -recursive modules
terragrunt --working-dir azure hcl format --check

# Documentation toolchain (docs/)
make docs

# Every change, regardless of area
uv tool run multicz validate --strict
python scripts/add_license_header.py --path . --types tf,hcl,yml,toml --check
```

## Commit messages

Commit messages MUST follow
[Conventional Commits](https://www.conventionalcommits.org/). They drive the
per-component version bump and CHANGELOG computed by
[multicz](https://github.com/goabonga/multicz).

| Type | Effect on version | Use it for |
| --- | --- | --- |
| `feat` | minor | new capability |
| `fix` | patch | bug fix |
| `perf` | patch | performance improvement |
| `refactor`, `docs`, `test`, `chore`, `ci`, `build`, `style` | none | maintenance |
| `feat!` / `BREAKING CHANGE:` | major | incompatible change |

The repository has **multiple independently versioned components** (see
[`multicz.toml`](multicz.toml)): `docs`, `configs-dev`, and any Terraform
module registered under `modules/` (see
[`modules/README.md`](modules/README.md)). Only commits that touch a
component's tracked `paths` trigger that component's release — e.g. a change
under `docs/` bumps `docs`, a change to `configs/config.dev.yaml` bumps
`configs-dev`. Do not append `Co-Authored-By` trailers.

## Releasing

Releases are automated: on every push to `main`, the `ci` workflow runs
`multicz bump` (signed commit + tag per bumped component). Maintainers do
not bump versions or edit changelogs by hand.

## Reporting bugs and asking for features

Please open a GitHub issue. For security-sensitive reports, follow
[SECURITY.md](SECURITY.md) instead of the public tracker.
