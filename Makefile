.PHONY: help install docs docs-dev clean

UV       := uv
VENV     := .venv
ZENSICAL := $(VENV)/bin/zensical

help:
	@echo "Targets:"
	@echo "  make install         Sync the venv (doc group)"
	@echo "Docs:"
	@echo "  make docs            Build the static site into ./site"
	@echo "  make docs-dev        Serve docs with live reload (http://127.0.0.1:8800)"
	@echo "  make clean           Remove caches and ./site"

# uv sync installs the doc group (zensical).
install:
	$(UV) sync --group doc

$(ZENSICAL): pyproject.toml uv.lock
	$(UV) sync --group doc

docs: $(ZENSICAL)
	$(UV) run zensical build

docs-dev: $(ZENSICAL)
	$(UV) run zensical serve --dev-addr 127.0.0.1:8800

clean:
	rm -rf site/ .ruff_cache/
