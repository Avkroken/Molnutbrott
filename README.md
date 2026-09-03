# Molnutbrott

Versioned Cloudflare infrastructure for Avkroken. The first managed surface is the MCP portal at `https://mcp.denied.se/mcp` and its Cloudflare API upstream.

Repository-specific infrastructure, CI and safety contracts are maintained in `MOLNUTBROTT.md`. Validation commands and live-state procedures are in `SKILLS.md`.

## Current MCP design

- Portal hostname: `mcp.denied.se`
- Portal Code Mode: `enforced`
- Secure Web Gateway: disabled
- Upstream: `https://mcp.cloudflare.com/mcp?codemode=false`
- Upstream authentication: OAuth
- Shared Cloudflare OAuth callback: disabled
- DNS target: proxied CNAME to `gateway.agents.cloudflare.com`

The upstream has Code Mode disabled intentionally because Code Mode is enforced at the portal layer.

## Read-only Cloudflare inventory

`scripts/cloudflare-inventory.sh` uses the MCP portal through the MCP Inspector CLI and only invokes discovered Cloudflare `GET` tools. It does not create, update, or delete Cloudflare resources.

Requirements:

- Node.js 22.19 or newer
- `npx`
- `jq`
- a previously authorized Inspector OAuth session for `https://mcp.denied.se/mcp`

Inventory a Worker by passing its name explicitly:

```sh
bash scripts/cloudflare-inventory.sh worker-name denied.se
```

The script writes sanitized JSON under `inventory/`, which is ignored by Git. It inventories the target Worker plus Worker settings/bindings, workers.dev and preview status, cron schedules, deployments, custom domains/routes, Workers Builds triggers/history, and account-level D1/KV/R2/Queues metadata. Secret-like values are redacted before the review files are written.

If Inspector authentication has expired, authorize it once with:

```sh
npx -y @modelcontextprotocol/inspector --cli \
  https://mcp.denied.se/mcp \
  --transport http \
  --method tools/list
```

Then rerun the inventory script.

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
