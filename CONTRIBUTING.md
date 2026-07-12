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
[`multicz.toml`](multicz.toml)): `docs`, `azure`, `configs-dev`, `configs-hub`
(the shared network + self-hosted runners, see
[Network isolation: the hub](#network-isolation-the-hub) below), and any
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

I can write the workflow files and the bootstrap script but not configure
GitHub repo settings or grant Azure RBAC — someone with the right access
needs to do this once per environment, after filling in
`configs/config.<env>.yaml`:

- Run `./scripts/bootstrap-storage.sh <env>` (needs `az login` with rights
  to create resource groups/storage accounts in that subscription). It
  creates the remote-state storage account/container and the private
  plans storage account/container, both hardened (TLS1.2+, HTTPS-only, no
  public blob access, versioning + soft delete).
- Grant Azure RBAC on those containers: `Storage Blob Data Contributor` on
  both for the plan/apply identity (`AZURE_CLIENT_ID` below), and
  `Storage Blob Data Reader` on the plans container for the approver group
  (so they can fetch the full plan the PR comment points at).
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

### How the pipelines authenticate to "private" storage

Both storage accounts have `--allow-blob-public-access false` (no
anonymous access) and `--allow-shared-key-access false` (no account-key
auth at all - `bootstrap-storage.sh` disables it, and
`azure/terragrunt.hcl` sets `use_azuread_auth = true` so the state backend
never needs a key either). "Private" here means **identity-gated**, not
network-blocked: the storage accounts accept connections from any network
(GitHub-hosted runners don't have static IPs to allowlist), but every
request must carry a valid Azure AD token.

`azure/login@v3` (OIDC, no stored secret - GitHub mints a short-lived
token, Azure AD exchanges it for one scoped to the `AZURE_CLIENT_ID` app
registration's federated credential) authenticates the `az` CLI session
that both `az storage blob upload/download --auth-mode login` and the
terragrunt/terraform run use. Access is authorized purely by the RBAC role
assignments above - revoke the role and the pipeline loses access
immediately, no key to rotate.

Network-level isolation (not just identity-based) is exactly what the hub
below provides.

## Network isolation: the hub

`configs/config.hub.yaml` + `azure/hub/**` define a dedicated hub VNet
(`modules/hub-network`), Private Endpoints into every environment's state
and plans storage (`modules/hub-storage-endpoints`), and a fleet of
ephemeral self-hosted runners on a VM Scale Set
(`modules/hub-runners`) that can reach them privately. It's treated as its
own environment (`configs-hub`), going through the exact same plan → PR →
apply flow as `dev`/`staging`/`prod` above - **except its first apply**,
which has a chicken-and-egg problem: the self-hosted runner doesn't exist
yet to run the pipeline that creates it.

### Bootstrap sequence (once, per hub)

1. Fill in `configs/config.hub.yaml` (resource group, address space,
   `admin_ssh_public_key`, the `storage_endpoints` list - one `state` +
   `plans` pair per environment already registered).
2. `./scripts/bootstrap-storage.sh hub` - state storage for the hub's own
   Terraform state (same chicken-and-egg as any other environment).
3. Push `main` and `deploy/hub` (created locally from `main`). Leave the
   `hub`/`hub-plan` GitHub Environments' `RUNNER_LABEL` variable **unset**
   for now - the first apply runs on `ubuntu-latest`, same as any other
   environment before this section existed.
4. Let `terragrunt-plan.yml` → PR → `terragrunt-apply.yml` run once for
   `hub`, same as any other environment (see the numbered flow above).
   This creates the VNet, Private Endpoints, VMSS (0 instances), Key Vault
   and runner managed identity - all still driven by a GitHub-hosted
   runner over the public (identity-gated) storage endpoint.
5. Grant the runner identity RBAC: `Storage Blob Data Contributor` on
   every environment's state + plans containers (`terraform output
   runner_identity_principal_id` from `azure/hub/runners`), and `Key Vault
   Secrets User` is already wired by Terraform.
6. `./scripts/bootstrap-runner.sh` - pushes a GitHub fine-grained PAT
   (`Administration: write` on this repo, needed to mint runner
   registration tokens - see the script's header) into the hub Key Vault,
   and scales the VMSS to 1. Confirm a runner shows up "Idle" at
   `github.com/<repo>/settings/actions/runners`.
7. Set the `hub` and `hub-plan` GitHub Environments' `RUNNER_LABEL`
   variable to match `.hub.runners.runner_labels` in
   `configs/config.hub.yaml` (e.g. `self-hosted`). From the next `hub`
   deploy onward, `hub` deploys itself through its own runner.
8. Optionally, once confirmed working: flip `RUNNER_LABEL` for other
   environments (`dev`, ...) the same way, then disable public network
   access on their storage accounts entirely (`az storage account update
   --name <account> --public-network-access Disabled`) - the hub's
   Private Endpoint is now the only path in. Do this **after** the
   switch-over, not before, or the GitHub-hosted fallback (still used by
   `terragrunt-plan.yml` until you flip the label) locks itself out.

### Known gaps, deliberately deferred

- **No event-driven autoscaler.** Capacity is fixed/operator-managed
  (`az vmss scale`, or `.hub.runners.instances` in
  `configs/config.hub.yaml`). A webhook-triggered autoscaler (GitHub
  `workflow_job` event → Azure Function → `az vmss scale`) is a natural
  follow-up once usage justifies it.
- **PAT, not a GitHub App.** A fine-grained PAT is the simplest option for
  a personal-account repo (Actions Runner Controller / org-level runner
  fleets assume an organization). It's stored only in Key Vault, never in
  git, and instances fetch it via managed identity at boot - but it's a
  long-lived credential you must remember to rotate
  (`./scripts/bootstrap-runner.sh` again with a fresh PAT).
- **VNet peering to environment networks** isn't wired yet - `dev`/
  `staging`/`prod` don't have their own Terraform-managed VNets to peer to
  yet (only their state/plans storage exists). Add peering (or Private
  Endpoints, same pattern as `hub-storage-endpoints`) once those networks
  exist.

## Reporting bugs and asking for features

Please open a GitHub issue. For security-sensitive reports, follow
[SECURITY.md](SECURITY.md) instead of the public tracker.
