# REPO.md

This is the repository governance document for `Avkroken/Molnutbrott`. Binding AI coding-agent policy is defined only in `Avkroken/.github/AGENTS.md`. This document records repository-specific technical contracts, invariants, validation requirements, and operational context required by that policy; it must not define, supplement, narrow, or override agent policy.

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

## GitHub Actions and merge contract

- `.github/workflows/terraform-check.yml` owns the repository required status `Terraform / required`; its organization-level status ruleset uses strict latest-base verification.
- The workflow checks out the exact GitHub ref, resolves the newest stable Terraform release from HashiCorp's release index, verifies the published checksum, then runs formatting, backendless init and validate.
- `.terraform-version` is intentionally not used; routine Terraform releases, including future major releases accepted by `required_version`, must not require repository maintenance.
- CI must not receive Cloudflare production credentials or run authenticated live `terraform plan` or `terraform apply`.
- Third-party GitHub Actions are pinned to full commit SHAs; Dependabot advances those immutable references.
- The organization `main` ruleset requires the central OSV workflow from `Avkroken/.github`. It runs `scan-pr` for pull requests and `scan-merge-group` for merge-queue candidates; `scan-pr / osv-scan` is not a separate organization-level required status.
- The repository uses merge queue. Common review-thread, CodeQL, squash-only and other organization merge enforcement is owned by the active organization rulesets rather than duplicated here.
- `.github/workflows/issue-classification.yml` and `.github/workflows/metadata-routing.yml` are repository callers for the centrally authorized metadata-only automation; permitted behavior is defined only by `Avkroken/.github/AGENTS.md`.

## Response format

Read and follow `SKILLS.md` when working in this repository.
