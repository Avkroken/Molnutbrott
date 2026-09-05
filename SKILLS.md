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

Before any import or apply, verify the real Cloudflare account, zone, MCP portal ID, MCP server ID, and DNS record ID. Typical imports for the current MCP resources are documented in `README.md`.

## Read-only MCP inventory

Run a sanitized live inventory through `mcp.denied.se` and pass the target Worker name explicitly:

```sh
bash scripts/cloudflare-inventory.sh worker-name denied.se
```

The script may only invoke discovered Cloudflare `GET` tools through `portal_codemode_execute`. Generated inventory belongs under ignored `inventory/`; do not commit it. Review any `error` or `skipped` entries before drawing conclusions about live state.

## CI implementation

`.github/workflows/terraform-check.yml` emits `Terraform / required` for pull requests to `main`, pushes to `main`, and manual dispatch. It resolves the newest stable Terraform release from HashiCorp's release index, verifies the published checksum, and runs formatting, backendless initialization, and validation.

`terraform/versions.tf` keeps only the minimum supported Terraform version and intentionally has no upper bound. There is no `.terraform-version` pin to maintain.

CI must not receive Cloudflare production credentials and must not run authenticated live plans or `terraform apply`.

The authoritative repository CI and merge contract is in `REPO.md`; organization-wide agent policy is only in `Avkroken/.github/AGENTS.md`.
