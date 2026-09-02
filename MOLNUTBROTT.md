# MOLNUTBROTT.md

Repository-specific instructions for `Avkroken/Molnutbrott`. These instructions supplement the canonical Avkroken policy in `Avkroken/.github/AGENTS.md`.

## Purpose

Molnutbrott versions Cloudflare infrastructure for Avkroken. Its current scope includes the MCP portal at `mcp.denied.se` and its Cloudflare API upstream.

## Terraform safety and ownership

- Never commit Cloudflare API tokens, OAuth grants, client secrets, Access service tokens, Terraform state or other credentials.
- Existing production resources must be imported before Terraform manages them.
- Never invent resource IDs, authentication settings, Access policies or live Cloudflare state.
- Do not replace, destroy, baseline or recreate live resources from assumptions.
- Use `prevent_destroy` for production MCP resources unless a reviewed change explicitly requires otherwise.
- Cloudflare is the runtime and production control plane. GitHub Actions is validation only; do not run production `terraform apply` from CI.
- Move dashboard-only configuration into code only when the provider/API supports it and exact live state has been verified.

## Terraform workflow

Before proposing infrastructure changes:

1. Read the current Cloudflare provider documentation for the affected resource.
2. Inventory the live resource and its actual IDs/settings.
3. Import existing resources before apply.
4. Run `terraform fmt -check -recursive`, `terraform init -backend=false`, and `terraform validate`.
5. Run an authenticated `terraform plan` locally when live-state comparison is required.
6. Treat unexpected replacement or destruction as a blocker until explained from verified state.

Prefer the newest stable dependency release by default. A Terraform/provider pin or upper bound is an exception for a demonstrated incompatibility and must document why it exists and what condition permits removal.

## MCP invariants

Unless a concrete defect or intentional design change is established:

- portal hostname is `mcp.denied.se`;
- portal Code Mode is `enforced`;
- Secure Web Gateway is disabled;
- Cloudflare API upstream is `https://mcp.cloudflare.com/mcp?codemode=false`;
- upstream authentication is OAuth;
- the shared Cloudflare-hosted OAuth callback is disabled;
- DNS is a proxied CNAME to `gateway.agents.cloudflare.com`;
- OAuth credentials remain server-side in Cloudflare and are never represented as repository secrets.

## GitHub Actions contract

- `.github/workflows/terraform-check.yml` owns the `Terraform / required` context.
- It checks out the exact GitHub ref, resolves the newest stable Terraform release from HashiCorp's release index, verifies HashiCorp's published checksum, then runs formatting, backendless init and validate.
- `.terraform-version` is intentionally not used; routine Terraform releases, including future major releases accepted by `required_version`, must not require repository maintenance.
- CI must not receive Cloudflare production credentials.
- CI must not run authenticated live `terraform plan` or `terraform apply`.
- Pin third-party GitHub Actions to full commit SHAs; Dependabot advances those immutable references.

## Metadata-only AI triage

- `.github/workflows/issue-classification.yml` may only classify opened or reopened issues through the SHA-pinned central metadata-only workflow.
- `.github/workflows/metadata-routing.yml` may only call Avkroken's SHA-pinned deterministic metadata routing for assignee and labels.
- The AI workflow may read the triggering issue and read-only repository context, and may add exactly one temporary `classification:<difficulty>:<security>` label from the central allowlist.
- Deterministic routing converts the temporary label to canonical `difficulty:*` and `security:*` labels, removes the temporary label, and maintains routing metadata. Existing canonical classification labels take precedence; malformed or conflicting classification metadata must fail closed to `triage:invalid`.
- The caller may explicitly pass only `COPILOT_GITHUB_TOKEN`; `secrets: inherit` is prohibited. Credential values must never be committed or logged.
- The metadata-only workflows must not change code, branches, pull requests, reviews, merge state, deployments, Terraform state, or Cloudflare resources, and must not perform or propose remediation.

## Response format

Read and follow `SKILLS.md` when working in this repository.
