# Security Policy

## Scope

Molnutbrott versions Cloudflare infrastructure. Security-sensitive production credentials, OAuth grants, Access service tokens, Terraform state and other secrets must never be committed to this repository or exposed through CI logs, pull-request comments or artifacts.

Existing production resources must be inventoried and imported before Terraform manages them. CI is validation-only and must not receive Cloudflare production credentials, run an authenticated production `terraform plan`, or run `terraform apply`.

Merge and CI enforcement is documented once in `MOLNUTBROTT.md` rather than duplicated here.

## Reporting sensitive findings

Do not include credentials, tokens, private keys, Terraform state or other secrets in public issues or pull requests. When a report requires sensitive details, use a private channel available to the repository maintainers.
