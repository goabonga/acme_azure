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
   block modeled on `[components.configs-dev]`:

   ```toml
   [components.modules-<name>]
   paths = ["modules/<name>/**"]
   bump_files = [
       { file = "modules/<name>/VERSION" },
   ]
   changelog = "modules/<name>/CHANGELOG.md"
   ```

3. Run `uvx --from multicz multicz validate --strict` before committing.

`_template/` itself is not a real module and is not registered in
`multicz.toml`.
