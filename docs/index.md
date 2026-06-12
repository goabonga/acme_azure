---
icon: lucide/house
---

# ACME Azure

**ACME Azure** is the Azure counterpart of the ACME landing zone — a
multi-environment [Terragrunt](https://terragrunt.gruntwork.io)
infrastructure designed to meet a strict, externally-audited
compliance baseline.

> Released under the [MIT License](https://github.com/goabonga/acme_azure/blob/main/LICENSE) ·
> Source on [GitHub](https://github.com/goabonga/acme_azure)

---

## Scope

The repository codifies the Azure platform foundation: subscription
and management-group layout, networking topology, identity, key
management and the guardrails required to keep the estate auditable.

| concern        | intent                                                  |
|----------------|---------------------------------------------------------|
| **Regions**    | EU residency — primary + DR region inside the EU         |
| **Topology**   | hub-and-spoke, environment-isolated spokes               |
| **Compliance** | external audit required, not just self-alignment          |
| **Environments** | dev / prod / shared / internal                         |

## Quickstart

```bash
git clone https://github.com/goabonga/acme_azure.git
cd acme_azure

# documentation toolchain
make install        # sync the doc venv (zensical)
make docs-dev       # live-reload docs on http://127.0.0.1:8800
```

## Requirements

- [Terraform](https://www.terraform.io) / [OpenTofu](https://opentofu.org)
- [Terragrunt](https://terragrunt.gruntwork.io) (>= v0.73, new CLI)
- [Azure CLI](https://learn.microsoft.com/cli/azure/), authenticated

## Documentation

This site is built with [`zensical`](https://github.com/zensical/zensical):

```bash
make docs           # build the static site into ./site
make docs-dev       # serve with live reload
```

See the [Changelog](changelog.md) for the release history.
