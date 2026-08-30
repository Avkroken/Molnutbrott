variable "cloudflare_account_id" {
  description = "Cloudflare account ID containing the MCP portal."
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for denied.se."
  type        = string
}

variable "mcp_portal_id" {
  description = "Existing Cloudflare MCP portal ID."
  type        = string
}

variable "mcp_server_id" {
  description = "Existing Cloudflare MCP upstream server ID."
  type        = string
}

variable "mcp_dns_record_id" {
  description = "Existing DNS record ID for mcp.denied.se. Used when importing the record."
  type        = string
}

variable "mcp_server_on_behalf" {
  description = "Verified live value of the portal server on_behalf setting."
  type        = bool
}

variable "mcp_portal_hostname" {
  description = "Public hostname for the MCP portal."
  type        = string
  default     = "mcp.denied.se"
}

variable "mcp_portal_name" {
  description = "Display name for the MCP portal."
  type        = string
  default     = "MCP"
}

variable "cloudflare_api_mcp_url" {
  description = "Cloudflare API MCP upstream URL. Code Mode stays disabled upstream because it is enforced by the portal."
  type        = string
  default     = "https://mcp.cloudflare.com/mcp?codemode=false"
}
