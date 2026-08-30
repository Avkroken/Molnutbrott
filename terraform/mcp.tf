resource "cloudflare_zero_trust_access_ai_controls_mcp_server" "cloudflare_api" {
  account_id                       = var.cloudflare_account_id
  id                               = var.mcp_server_id
  auth_type                        = "oauth"
  hostname                         = var.cloudflare_api_mcp_url
  name                             = "Cloudflare API"
  is_shared_oauth_callback_enabled = false
  secure_web_gateway               = false

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      auth_credentials,
      client_secret,
    ]
  }
}

resource "cloudflare_zero_trust_access_ai_controls_mcp_portal" "main" {
  account_id         = var.cloudflare_account_id
  id                 = var.mcp_portal_id
  hostname           = var.mcp_portal_hostname
  name               = var.mcp_portal_name
  description        = "Avkroken Cloudflare API MCP portal"
  code_mode          = "enforced"
  secure_web_gateway = false

  servers = [{
    server_id        = var.mcp_server_id
    default_disabled = false
    on_behalf        = var.mcp_server_on_behalf
  }]

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "mcp" {
  zone_id = var.cloudflare_zone_id
  name    = var.mcp_portal_hostname
  content = "gateway.agents.cloudflare.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1

  lifecycle {
    prevent_destroy = true
  }
}
