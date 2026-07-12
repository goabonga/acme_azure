# Terraform modules

Local Terraform modules consumed by the Terragrunt units under `azure/`.

Each module lives in its own subdirectory (e.g. `modules/<name>/`) with the
standard `main.tf` / `variables.tf` / `outputs.tf` / `versions.tf` layout,
plus a `VERSION` file and a `CHANGELOG.md` — each module is versioned and
tagged independently (see [`multicz.toml`](../multicz.toml)).

## Adding a new module

1. Copy [`_template/`](_template) to `modules/<name>/` and replace the
   placeholder in `main.tf` with the real `azurerm_*` resources.
2. Register it in `multicz.toml` by adding a `[components.modules-<name>]`
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

3. For every `configs-<env>` that deploys this module, add it to that
   component's `depends_on` so the `upstream-notes` plugin surfaces the
   module's commits in that environment's deploy changelog:

   ```toml
   [components.configs-dev]
   ...
   depends_on = ["azure", "modules-<name>"]
   ```

4. Run `uvx --from multicz multicz validate --strict` before committing.

`_template/` itself is not a real module and is not registered in
`multicz.toml`.
