# Terraform modules

Local Terraform modules consumed by the Terragrunt units under `azure/`.

Each module lives in its own subdirectory (e.g. `modules/<name>/`) with the
standard `main.tf` / `variables.tf` / `outputs.tf` / `versions.tf` layout,
plus a `VERSION` file, a `CHANGELOG.md`, and a `tests/*.tftest.hcl` — each
module is versioned and tagged independently (see
[`multicz.toml`](../multicz.toml)) and tested with real Terraform, offline
(see [`CONTRIBUTING.md`](../CONTRIBUTING.md#running-terraform-tests)).

## Adding a new module

1. Copy [`_template/`](_template) to `modules/<name>/` (this brings the
   `VERSION`, `CHANGELOG.md` and `tests/` skeleton) and replace the
   placeholder in `main.tf` with the real `azurerm_*` resources.
2. Write `tests/*.tftest.hcl` assertions for the module's actual resources
   (`mock_provider`, no real Azure needed) — see
   `modules/hub-network/tests/*.tftest.hcl` for the pattern. Run with
   `cd modules/<name> && terraform test` or `make test` from the repo root.
3. Register it in `multicz.toml` by adding a `[components.modules-<name>]`
   block modeled on `[components.azure]` — it releases immediately on every
   push to `main` like `docs`/`azure` (a module is a library, not deployment
   state), so no `ci.yml` edit is needed (the `release` job bumps every
   component whose name does not start with `configs-`):

   ```toml
   [components.modules-<name>]
   paths = ["modules/<name>/**"]
   bump_files = [
       { file = "modules/<name>/VERSION" },
   ]
   changelog = "modules/<name>/CHANGELOG.md"
   ```

4. For every `configs-<env>` that deploys this module, add it to that
   component's `depends_on` so the `upstream-notes` plugin surfaces the
   module's commits in that environment's deploy changelog:

   ```toml
   [components.configs-dev]
   ...
   depends_on = ["azure", "modules-<name>"]
   ```

5. Run `uvx --from multicz multicz validate --strict` before committing.

`_template/` itself is not a real module and is not registered in
`multicz.toml`.
