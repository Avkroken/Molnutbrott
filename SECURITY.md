# Security Policy

## Scope

Molnutbrott versions Cloudflare infrastructure. Security-sensitive production credentials, OAuth grants, Access service tokens, Terraform state, and other secrets must never be committed to this repository or exposed through CI logs, pull-request comments, or artifacts.

Existing production resources must be inventoried and imported before Terraform manages them. CI is validation-only and must not receive Cloudflare production credentials, run an authenticated production `terraform plan`, or run `terraform apply`.

## Merge security enforcement

Live organization rulesets are the enforcement source of truth for `main`. At the latest verification:

- `Terraform / required` is the repository-owned required GitHub Actions status check.
- `scan-pr / osv-scan` is additionally required by the organization-level `main` ruleset through its current central Regelverket OSV workflow reference.
- Required checks use strict latest-base enforcement.
- General required approvals are `0`.
- Stale approvals are dismissed after a push.
- Last-push approval is not required.
- Relevant review threads must be resolved before merge.
- Only squash merge is allowed.
- Deletion and non-fast-forward/force pushes are blocked.
- There are no bypass actors.
- CodeQL is enforced separately through Code Scanning merge protection with `security_alerts_threshold: medium_or_higher` and `alerts_threshold: errors_and_warnings`.
- CodeQL Default Setup analyzes the repository's GitHub Actions workflows; repository-owned CI must not duplicate the CodeQL workflow.

Trivy is not currently configured as a producer or merge gate, so no Trivy severity threshold applies.

Molnutbrott intentionally has no repository-local OSV workflow because Terraform provider lockfiles do not provide a meaningful supported OSV dependency manifest. The current `scan-pr / osv-scan` requirement is inherited central organization state and must be removed at organization level to complete the repository-specific architecture; repository CI must not fabricate a local scanner merely to satisfy that coupling.

## Automated review

CodeRabbit and Copilot Code Review are advisory and not required status checks. Missing, pending, rate-limited, quota-limited, or unavailable review does not by itself replace the enforced gates. Actual relevant findings must still be evaluated, and relevant review threads must be resolved.

## Reporting sensitive findings

Do not include credentials, tokens, private keys, Terraform state, or other secrets in public issues or pull requests. When a report requires sensitive details, use a private channel available to the repository maintainers rather than publishing those details in the repository.
