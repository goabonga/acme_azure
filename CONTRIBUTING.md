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
[`multicz.toml`](multicz.toml)): `docs`, `azure`, `configs-dev`, and any
Terraform module registered under `modules/` (see
[`modules/README.md`](modules/README.md)). Only commits that touch a
component's tracked `paths` trigger that component's release — e.g. a change
under `docs/` bumps `docs`, a change under `azure/` bumps `azure`. Do not
append `Co-Authored-By` trailers.

## Releasing

`docs`, `azure` and every `modules-*` component release automatically: on
every push to `main`, the `ci` workflow runs `multicz bump` (signed commit +
tag) for whichever of them have qualifying commits. Maintainers do not bump
versions or edit their changelogs by hand.

`configs-<env>` components are different — they represent what is actually
**deployed**, not a library, so they are excluded from that automatic bump
and are only released by the deploy pipeline below.

## Deploying an environment

A change to `configs/config.<env>.yaml`, `azure/**` or `modules/**` can
change what's actually running in an Azure environment, so it goes through
a plan → review → apply gate instead of releasing immediately:

1. `terragrunt-plan.yml` runs `terragrunt plan` for every environment
   (discovered from `configs/config.*.yaml`) on every push to `main` that
   touches those paths.
2. If a plan has changes, it opens (or updates) a PR from `main` into
   `deploy/<env>`, with the plan attached as a comment. No changes → no PR
   (a stale one is closed).
3. That PR is reviewed like any other PR. Merging it into `deploy/<env>`
   (once the branch's required approvals are satisfied) is the "go" signal.
4. `terragrunt-apply.yml` triggers on the push to `deploy/<env>`, runs
   `terragrunt apply`, and on success bumps `configs-<env>` (patch bump if
   no commit on the config file itself already justified one — the deploy
   still happened and is recorded), tags it, and fast-forwards the release
   commit back onto `main`. Its changelog/release notes are enriched by
   multicz's `upstream-notes` plugin with what `azure`/`modules-*` commits
   this deploy actually shipped (see `[components.configs-dev].depends_on`
   in `multicz.toml`).

### One-time setup (per environment, once the repo has a GitHub remote)

I can write the workflow files but not configure GitHub repo settings —
someone with admin access needs to do this once per environment:

- Push the `deploy/<env>` branch (created locally from `main`).
- Protect `deploy/<env>` (Settings → Branches): require a pull request,
  require approval(s) from the authorized group before merging. This is
  the actual "only this group can validate an apply" gate.
- Create two GitHub Environments: `<env>-plan` (read-only Azure credentials
  for the plan job) and `<env>` (the apply job — optionally add required
  reviewers here too, as a second gate on top of branch protection).
- Add `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` secrets
  to both environments, backed by an Azure AD app registration with a
  federated credential trusting GitHub OIDC for this repo (no client
  secret needed) — see
  [Azure's GitHub Actions OIDC guide](https://learn.microsoft.com/azure/developer/github/connect-from-azure).

## Reporting bugs and asking for features

Please open a GitHub issue. For security-sensitive reports, follow
[SECURITY.md](SECURITY.md) instead of the public tracker.
