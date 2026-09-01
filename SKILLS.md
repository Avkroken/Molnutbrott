# SKILLS.md

## Terraform validation

Run from the repository root:

```sh
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
```

For formatting changes:

```sh
terraform -chdir=terraform fmt -recursive
```

## Live-state work

Authenticated plan/import work is local and deliberate. Supply Cloudflare authentication through environment variables; never put credentials in tracked files.

Before any import or apply, verify the real Cloudflare account, zone, MCP portal ID, MCP server ID, and DNS record ID.

Typical imports for the current MCP resources are documented in `README.md`.

## Read-only MCP inventory

Run a sanitized live inventory through `mcp.denied.se` with:

```sh
bash scripts/cloudflare-inventory.sh skvallerbyttan denied.se
```

The script may only invoke discovered Cloudflare `GET` tools through `portal_codemode_execute`. Generated inventory belongs under ignored `inventory/`; do not commit it. Review any `error` or `skipped` entries before drawing conclusions about live state.

## CI

`.github/workflows/terraform-check.yml` runs on pull requests to `main`, pushes to `main`, and manual dispatch. Its terminal job is named `Terraform / required` and is the only required status check in the active `Protect main` ruleset.

The ruleset uses strict required-status-check enforcement, so a pull request must be tested against the current `main` before merge. The workflow has no path filter, so the required context is created for every pull request targeting `main`.

The job checks out the exact GitHub ref, installs the Terraform version recorded in `.terraform-version` with checksum verification, then runs formatting, initialization without a backend, and validation.

CI must not receive Cloudflare production credentials and must not run `terraform plan` against live state or `terraform apply`.

CodeRabbit and Copilot Code Review are advisory review signals, not required status checks. Actionable findings still need to be evaluated and relevant review threads must be resolved before merge.
