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

`.github/workflows/terraform-check.yml` runs formatting, initialization without a backend, and validation. CI must not receive Cloudflare production credentials and must not run `terraform plan` against live state or `terraform apply`.
