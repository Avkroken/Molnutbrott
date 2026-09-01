# AGENTS.md

This file is authoritative for work in this repository. Read `SKILLS.md` as well.

## Purpose

Molnutbrott versions Cloudflare infrastructure for Avkroken. The initial scope is the MCP portal at `mcp.denied.se` and its Cloudflare API upstream.

## Safety and ownership

- Never commit Cloudflare API tokens, OAuth grants, client secrets, Access service tokens, Terraform state, or other credentials.
- Existing production resources must be imported before Terraform is allowed to manage them.
- Never invent resource IDs, authentication settings, Access policies, or live Cloudflare state.
- Do not replace, destroy, baseline, or recreate live resources on assumptions.
- Use `prevent_destroy` for production MCP resources unless there is a reviewed reason not to.
- Cloudflare is the runtime and production control plane. GitHub Actions is validation only; no production `terraform apply` from CI.
- Dashboard-only configuration should be moved into code when the provider/API supports it and the exact live state has been verified.

## Git workflow

- Do not push directly to `main` except for repository bootstrap when no commit exists.
- Use a short-lived branch and a ready pull request.
- `main` is protected by the active `Protect main` ruleset.
- `Terraform / required` must pass for GitHub's current pull-request merge ref, which combines the current PR changes with the current `main`.
- Resolve all relevant review threads before merge.
- General required approvals are `0`; do not invent a human-approval gate.
- Only squash merge is allowed by the ruleset.
- There are no ruleset bypass actors.
- Copilot Code Review and CodeRabbit are advisory. Evaluate actionable findings, but service quota, rate limits, pending status, or unavailability are not merge gates unless the live ruleset changes.
- Do not delete branches without explicit approval.

## Terraform workflow

Before proposing infrastructure changes:

1. Read the current Cloudflare provider documentation for the affected resource.
2. Inventory the live resource and its actual IDs/settings.
3. Import existing resources before apply.
4. Run `terraform fmt -check -recursive`, `terraform init -backend=false`, and `terraform validate`.
5. Run an authenticated `terraform plan` locally when live-state comparison is required.
6. Treat any unexpected replacement/destruction as a blocker until explained from verified state.

## MCP invariants

Unless a concrete defect or intentional design change is established:

- Portal hostname is `mcp.denied.se`.
- Portal Code Mode is `enforced`.
- Secure Web Gateway is disabled.
- Cloudflare API upstream is `https://mcp.cloudflare.com/mcp?codemode=false`.
- Upstream authentication is OAuth.
- The shared Cloudflare-hosted OAuth callback is disabled.
- DNS is a proxied CNAME to `gateway.agents.cloudflare.com`.
- OAuth credentials remain server-side in Cloudflare and are never represented as repository secrets.
