.PHONY: help install docs docs-dev fmt fmt-check test clean

UV         := uv
VENV       := .venv
ZENSICAL   := $(VENV)/bin/zensical
TERRAGRUNT := terragrunt --working-dir azure

help:
	@echo "Targets:"
	@echo "  make install         Sync the venv (doc group)"
	@echo "Docs:"
	@echo "  make docs            Build the static site into ./site"
	@echo "  make docs-dev        Serve docs with live reload (http://127.0.0.1:8800)"
	@echo "Terraform / Terragrunt:"
	@echo "  make fmt             Format modules/ and azure/ in place"
	@echo "  make fmt-check       Check formatting (same as CI)"
	@echo "  make test            Run terraform test for every module with a tests/ dir"
	@echo "  make clean           Remove caches, ./site and terraform artifacts"

# uv sync installs the doc group (zensical).
install:
	$(UV) sync --group doc

$(ZENSICAL): pyproject.toml uv.lock
	$(UV) sync --group doc

docs: $(ZENSICAL)
	$(UV) run zensical build

docs-dev: $(ZENSICAL)
	$(UV) run zensical serve --dev-addr 127.0.0.1:8800

fmt:
	terraform fmt -recursive modules
	$(TERRAGRUNT) hcl format

fmt-check:
	terraform fmt -check -recursive modules
	$(TERRAGRUNT) hcl format --check

# mock_provider (used by tests/*.tftest.hcl) needs no real Azure
# credentials or network access - see CONTRIBUTING.md#running-terraform-tests.
test:
	@for dir in modules/*/; do \
		if [ -d "$${dir}tests" ]; then \
			echo "=== terraform test $${dir} ==="; \
			(cd "$$dir" && terraform init -backend=false -input=false && terraform test) || exit 1; \
		fi; \
	done

clean:
	rm -rf site/ .ruff_cache/
	find . -type d -name ".terragrunt-cache" \
		-o -type f -name ".terraform.lock.hcl" \
		-o -type d -name ".terraform" \
		-o -type f -name "generated_*.tf" | \
		xargs rm -Rf
