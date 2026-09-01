# Security Policy

## Scope

Molnutbrott versions Cloudflare infrastructure. Security-sensitive production credentials, OAuth grants, Access service tokens, Terraform state, and other secrets must never be committed to this repository or exposed through CI logs, pull-request comments, or artifacts.

Existing production resources must be inventoried and imported before Terraform manages them. CI is validation-only and must not receive Cloudflare production credentials, run an authenticated production `terraform plan`, or run `terraform apply`.

## Merge security enforcement

The active `Protect main` ruleset protects the default branch.

- `Terraform / required` is the required GitHub Actions status check.
- Required checks use strict latest-base enforcement.
- Relevant review threads must be resolved before merge.
- Required general approvals are `0` and last-push approval is disabled.
- Only squash merge is allowed.
- Deletion and non-fast-forward/force pushes are blocked.
- There are no bypass actors.

CodeQL Code Scanning merge protection is not currently configured because no verified CodeQL check is produced for relevant pull requests. No CodeQL severity threshold therefore applies today.

Trivy is not currently configured as a producer or merge gate, so no Trivy severity threshold applies today.

OSV or another dependency scanner is not currently a required merge gate because no stable dependency-scanning context is produced for relevant pull requests.

If any of these scanners are introduced, their actual check or Code Scanning tool names and enforcement thresholds must be verified live before documentation or rulesets claim that they block merge.

## Automated review

CodeRabbit is best effort and is not a required status check. Missing, pending, rate-limited, or unavailable CodeRabbit status does not by itself block merge. Actual findings must still be evaluated, and relevant review threads must be resolved.

Copilot Code Review is advisory. Review-on-push is enabled and draft pull requests are excluded. Copilot quota or service availability is not a hard merge gate, but actionable feedback must still be evaluated.

## Reporting sensitive findings

Do not include credentials, tokens, private keys, Terraform state, or other secrets in public issues or pull requests. When a report requires sensitive details, use a private channel available to the repository maintainers rather than publishing those details in the repository.
