# AGENTS.md

This file is authoritative for work in this repository. Read `SKILLS.md` as well. Live GitHub configuration is enforcement truth when documentation and actual policy differ.

## Purpose

Molnutbrott versions Cloudflare infrastructure for Avkroken. The initial scope is the MCP portal at `mcp.denied.se` and its Cloudflare API upstream.

## Safety and ownership

- Never commit Cloudflare API tokens, OAuth grants, client secrets, Access service tokens, Terraform state, or other credentials.
- Existing production resources must be imported before Terraform is allowed to manage them.
- Never invent resource IDs, authentication settings, Access policies, or live Cloudflare state.
- Do not replace, destroy, baseline, or recreate live resources on assumptions.
- Use `prevent_destroy` for production MCP resources unless there is a reviewed reason not to.
- Cloudflare is the runtime and production control plane. GitHub Actions is validation only; no production `terraform apply` from CI.
- Dashboard-only configuration should be moved into code only when the provider/API supports it and exact live state has been verified.

## Git workflow and live merge policy

- Do not push directly to `main`.
- Use a short-lived branch and a ready pull request to `main`.
- Squash is the only allowed merge method.
- Do not bypass rulesets, required checks, reviews, or thread resolution.
- Re-verify exact PR HEAD after every push.

The active organization rulesets currently enforce:

- pull request required;
- 0 required approvals;
- stale approvals dismissed on push;
- last-push approval is not required;
- review threads resolved before merge;
- deletion and non-fast-forward/force push blocked;
- strict required status checks;
- `Terraform / required` through the org `terraform` ruleset;
- `scan-pr / osv-scan` and CodeQL merge protection through the org `main` ruleset;
- no bypass actors.

The org `main` ruleset currently also invokes Regelverket's `.github/workflows/osv-scanner.yml` as a central required workflow. That is external organization-level state and must be removed separately to complete the repo-specific target architecture.

Molnutbrott does not add a repository-local OSV workflow merely to reproduce that context: OSV-Scanner does not treat Terraform provider lockfiles as a supported dependency manifest, so such a workflow would not provide meaningful repository-specific dependency scanning. Terraform validation remains this repository's substantive local gate.

## Terraform workflow

Before proposing infrastructure changes:

1. Read the current Cloudflare provider documentation for the affected resource.
2. Inventory the live resource and its actual IDs/settings.
3. Import existing resources before apply.
4. Run `terraform fmt -check -recursive`, `terraform init -backend=false`, and `terraform validate`.
5. Run an authenticated `terraform plan` locally when live-state comparison is required.
6. Treat any unexpected replacement/destruction as a blocker until explained from verified state.

## Dependency versions

Prefer the newest stable release by default. Do not add an upper version bound or exact pin merely to avoid future upgrades. A pin or upper bound is an exception for a demonstrated incompatibility and must document why it exists and what condition allows its removal.

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

## GitHub Actions

- `.github/workflows/terraform-check.yml` is the only repository-owned workflow and produces `Terraform / required`.
- It checks out the exact GitHub ref, resolves the newest stable Terraform release from HashiCorp's release index, verifies HashiCorp's published checksum, then runs formatting, backendless init, and validate.
- `.terraform-version` is intentionally not used; routine Terraform releases, including future major releases accepted by `required_version`, must not require repository maintenance.
- CI must not receive Cloudflare production credentials.
- CI must not run authenticated live `terraform plan` or `terraform apply`.
- GitHub Actions must not create/update branches or PRs, arm auto-merge, or implement cross-repository remediation.
- Pin third-party Actions to full commit SHAs when used; Dependabot is responsible for advancing those immutable references.

## Review and verification

Copilot Code Review and CodeRabbit are advisory rather than required status checks. Evaluate actual actionable findings. Quota, rate limits, pending state, or temporary service failure do not by themselves replace the live required gates.

Review the full diff against `main` before PR. After every corrective commit, rerun relevant validation and re-check current HEAD, required checks, Code Scanning, mergeability, and review threads.

## Definition of done

A PR-based task is done only when the implementation is complete, the final diff is reviewed, relevant validation has passed, all actionable review feedback is handled, required checks and Code Scanning apply to exact final HEAD, all live required gates are satisfied, relevant review threads are resolved, and the PR is merged through normal ruleset enforcement or is waiting on a verified legitimate external gate.
