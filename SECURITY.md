# Security Policy

## Supported versions

Security fixes are applied only to the latest released version of each
component on the `main` branch (see [`multicz.toml`](multicz.toml) for the
component list — `docs`, `configs-dev`, and any registered Terraform
module).

| Version | Supported |
| --- | --- |
| latest release of a component | ✅ |
| older releases | ❌ |

## Reporting a vulnerability

**Please do not open a public issue.** GitHub's
[private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
is the preferred channel:

1. Go to the repository's **Security** tab.
2. Click **Report a vulnerability**.
3. Describe the issue with reproduction steps and a suggested mitigation.

If you cannot use GitHub's form, email **goabonga@pm.me** with the same
information. PGP encryption is available on request.

You can expect an acknowledgement within **3 business days**, a triage
assessment within **10 business days**, and a fix or written mitigation
plan before any public disclosure.

## Scope

This repository codifies an Azure landing zone with Terragrunt/Terraform
(`azure/`, `modules/`) and its documentation toolchain (`docs/`). Security-
relevant issues include: misconfigured Azure resources or IAM in a module,
secrets committed to `configs/*.yaml`, or a compromised CI/CD supply chain
(GitHub Actions, Dependabot, the `multicz` release pipeline). Vulnerabilities
in third-party Terraform providers/modules or Python dependencies should be
reported upstream, but please let us know so the pinned versions can be
bumped.

Thanks for helping keep the project and its users safe.
