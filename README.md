# Molnutbrott

Versioned Cloudflare infrastructure for Avkroken.

The first managed surface is the MCP portal at `https://mcp.denied.se/mcp` and its Cloudflare API upstream.

## Ownership

- Cloudflare remains the runtime and production control plane.
- Terraform is the intended source of truth for configuration that Cloudflare exposes through the provider.
- Existing live resources must be imported before any `terraform apply`.
- GitHub Actions validates Terraform only. It must not apply production changes.
- OAuth grants, API tokens, Access credentials, Terraform state, and other secrets must never be committed.

## Current MCP design

- Portal hostname: `mcp.denied.se`
- Portal Code Mode: `enforced`
- Secure Web Gateway: disabled
- Upstream: `https://mcp.cloudflare.com/mcp?codemode=false`
- Upstream authentication: OAuth
- Shared Cloudflare OAuth callback: disabled
- DNS target: proxied CNAME to `gateway.agents.cloudflare.com`

The upstream has Code Mode disabled intentionally because Code Mode is enforced at the portal layer.

## Bootstrap safely

1. Copy `terraform/terraform.tfvars.example` to a local `terraform.tfvars` and fill in the existing resource IDs.
2. Authenticate Terraform locally using a suitably scoped Cloudflare API token through the environment. Do not store it in this repository.
3. Run `terraform init` and `terraform plan`.
4. Import the existing live resources before any apply:

   ```sh
   terraform import cloudflare_zero_trust_access_ai_controls_mcp_server.cloudflare_api '<account_id>/<server_id>'
   terraform import cloudflare_zero_trust_access_ai_controls_mcp_portal.main '<account_id>/<portal_id>'
   terraform import cloudflare_dns_record.mcp '<zone_id>/<dns_record_id>'
   ```

5. Run `terraform plan` again and reconcile drift from verified live state. Do not apply a plan that proposes replacement or destruction of the existing portal, server, or DNS record.

## Not yet imported

The Cloudflare Access application/policy and Managed OAuth client settings are live but are not guessed into Terraform. Inventory their exact live configuration first, then add/import them separately.

## Validation

```sh
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
```

References:

- Cloudflare MCP Portals: https://developers.cloudflare.com/cloudflare-one/access-controls/ai-controls/mcp-portals/
- Cloudflare Terraform provider: https://registry.terraform.io/providers/cloudflare/cloudflare/latest
