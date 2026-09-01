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

`.github/workflows/terraform-check.yml` runs on pull requests to `main`, pushes to `main`, and manual dispatch. Its terminal job is `Terraform / required`.

The workflow has no PR path filter because the required context must be emitted for every PR targeting `main`. It installs the Terraform version recorded in `.terraform-version` with checksum verification and runs formatting, backendless initialization, and validation.

CI must not receive Cloudflare production credentials and must not run authenticated live plans or `terraform apply`.

OSV-Scanner is not added locally because Terraform provider lockfiles are not a supported dependency manifest for meaningful OSV scanning. The organization currently supplies `scan-pr / osv-scan` through a central required workflow; that is external policy, not repository-owned CI, and must be changed at organization level if the central OSV architecture is removed.

CodeRabbit and Copilot Code Review are advisory review signals, not required status checks. Actionable findings still need to be evaluated and relevant review threads resolved before merge.
