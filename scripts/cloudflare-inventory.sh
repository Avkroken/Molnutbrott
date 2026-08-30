#!/usr/bin/env bash
set -euo pipefail

WORKER_NAME="${1:-skvallerbyttan}"
ZONE_NAME="${2:-denied.se}"
MCP_URL="${MCP_URL:-https://mcp.denied.se/mcp}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${OUT_DIR:-inventory/${WORKER_NAME}-${STAMP}}"

for bin in npx jq; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "Missing required command: $bin" >&2
    exit 1
  fi
done

mkdir -p "$OUT_DIR"

INSPECTOR=(
  npx -y @modelcontextprotocol/inspector --cli
  npx -y mcp-remote "$MCP_URL" --transport http-only
  --
  --format json
)

mcp_call() {
  local tool="$1"
  local args_json="$2"
  "${INSPECTOR[@]}" \
    --method tools/call \
    --tool-name "$tool" \
    --tool-args-json "$args_json"
}

portal_text() {
  jq -r '.result.content[]? | select(.type == "text") | .text'
}

unwrap_execute() {
  jq '
    def parse_json:
      if type == "string" then
        . as $s | try ($s | fromjson) catch $s
      else . end;
    [
      .result.content[]?
      | select(.type == "text")
      | .text
      | parse_json
      | if type == "array" then .[] else . end
      | if type == "object" and .type? == "text" and has("text")
        then .text | parse_json
        else .
        end
    ]
    | if length == 1 then .[0] else . end
  '
}

redact() {
  jq '
    def scrub:
      walk(
        if type == "object" then
          with_entries(
            if (.key | ascii_downcase) as $k
              | ($k == "value"
                 or $k == "text"
                 or $k == "token"
                 or $k == "client_secret"
                 or $k == "auth_credentials"
                 or $k == "environment_variables"
                 or $k == "vars"
                 or $k == "password"
                 or $k == "private_key")
            then .value = "[REDACTED]"
            else .
            end
          )
        else . end
      );
    scrub
  '
}

search_code='async () => {
  const tools = await codemode.tools();
  const wanted = [
    "workers_scripts",
    "workers_domains",
    "workers_routes",
    "storage_kv_namespaces",
    "d1_database",
    "r2_buckets",
    "accounts_queues",
    "builds_workers"
  ];
  return tools
    .filter(t => t.name === "cloudflare_api_get_zones" ||
      (t.name.startsWith("cloudflare_api_get_") && wanted.some(x => t.name.includes(x))))
    .map(t => ({
      name: t.name,
      rawName: t.rawName,
      params: Object.keys(t.inputSchema?.properties || {}),
      readOnly: t.annotations?.readOnlyHint
    }));
}'

search_args="$(jq -nc --arg code "$search_code" '{code:$code}')"
mcp_call portal_codemode_search "$search_args" > "$OUT_DIR/tool-search-envelope.json"
portal_text < "$OUT_DIR/tool-search-envelope.json" | jq . > "$OUT_DIR/tools.json"

pick_tool() {
  local exact="$1"
  local contains="${2:-}"
  local found
  found="$(jq -r --arg exact "$exact" '.[] | select(.name == $exact) | .name' "$OUT_DIR/tools.json" | head -n1)"
  if [[ -z "$found" && -n "$contains" ]]; then
    found="$(jq -r --arg contains "$contains" '[.[] | select(.name | contains($contains)) | .name] | sort_by(length) | .[0] // empty' "$OUT_DIR/tools.json")"
  fi
  printf '%s' "$found"
}

tool_param() {
  local tool="$1"
  local regex="$2"
  jq -r --arg tool "$tool" --arg regex "$regex" \
    '.[] | select(.name == $tool) | .params[]? | select(test($regex; "i"))' \
    "$OUT_DIR/tools.json" | head -n1
}

args_for() {
  local tool="$1"
  local kind="${2:-}"
  local value="${3:-}"
  local param=""
  local args='{}'

  case "$kind" in
    script)
      param="$(tool_param "$tool" 'script.*name|script_name')"
      ;;
    external_script)
      param="$(tool_param "$tool" 'external.*script.*id|external_script_id')"
      ;;
    zone)
      param="$(tool_param "$tool" '^zone_?id$|^zoneId$')"
      ;;
    name)
      param="$(tool_param "$tool" '^name$')"
      ;;
  esac

  if [[ -n "$param" && -n "$value" ]]; then
    args="$(jq -nc --arg p "$param" --arg v "$value" '{($p):$v}')"
  fi

  if jq -e --arg tool "$tool" '.[] | select(.name == $tool) | .params | index("per_page")' "$OUT_DIR/tools.json" >/dev/null 2>&1; then
    args="$(jq -c '. + {per_page:100}' <<<"$args")"
  fi

  printf '%s' "$args"
}

execute_tool() {
  local label="$1"
  local tool="$2"
  local args_json="$3"
  local envelope="$OUT_DIR/${label}-envelope.json"
  local output="$OUT_DIR/${label}.json"

  if [[ -z "$tool" ]]; then
    jq -nc --arg label "$label" '{skipped:true, reason:"matching MCP tool not discovered", label:$label}' > "$output"
    return 0
  fi

  local code
  local call_args
  code="$(jq -nr --arg name "$tool" --argjson args "$args_json" '"async () => await codemode[" + ($name|tojson) + "](" + ($args|tojson) + ")"')"
  call_args="$(jq -nc --arg code "$code" '{code:$code}')"

  if mcp_call portal_codemode_execute "$call_args" > "$envelope"; then
    if unwrap_execute < "$envelope" | redact > "$output"; then
      :
    else
      jq -nc --arg tool "$tool" '{error:"could not decode MCP response", tool:$tool}' > "$output"
    fi
  else
    jq -nc --arg tool "$tool" '{error:"MCP tool call failed", tool:$tool}' > "$output"
  fi
}

WORKERS_TOOL="$(pick_tool cloudflare_api_get_accounts_workers_scripts 'get_accounts_workers_scripts')"
ZONES_TOOL="$(pick_tool cloudflare_api_get_zones 'get_zones')"
DOMAINS_TOOL="$(pick_tool cloudflare_api_get_accounts_workers_domains 'get_accounts_workers_domains')"
KV_TOOL="$(pick_tool cloudflare_api_get_accounts_storage_kv_namespaces 'get_accounts_storage_kv_namespaces')"
D1_TOOL="$(pick_tool cloudflare_api_get_accounts_d1_database 'get_accounts_d1_database')"
R2_TOOL="$(pick_tool cloudflare_api_get_accounts_r2_buckets 'get_accounts_r2_buckets')"
QUEUES_TOOL="$(pick_tool cloudflare_api_get_accounts_queues 'get_accounts_queues')"

execute_tool workers "$WORKERS_TOOL" '{}'
execute_tool zones "$ZONES_TOOL" "$(args_for "$ZONES_TOOL" name "$ZONE_NAME")"
execute_tool workers-domains "$DOMAINS_TOOL" '{}'
execute_tool kv-namespaces "$KV_TOOL" '{}'
execute_tool d1-databases "$D1_TOOL" '{}'
execute_tool r2-buckets "$R2_TOOL" '{}'
execute_tool queues "$QUEUES_TOOL" '{}'

WORKER_TAG="$(jq -r --arg worker "$WORKER_NAME" '.result[]? | select(.id == $worker) | .tag // empty' "$OUT_DIR/workers.json" | head -n1)"
ZONE_ID="$(jq -r --arg zone "$ZONE_NAME" '.result[]? | select(.name == $zone) | .id // empty' "$OUT_DIR/zones.json" | head -n1)"

jq -nc --arg worker "$WORKER_NAME" --arg tag "$WORKER_TAG" --arg zone "$ZONE_NAME" --arg zone_id "$ZONE_ID" \
  '{worker:$worker, worker_tag:$tag, zone:$zone, zone_id:$zone_id}' > "$OUT_DIR/target.json"

if [[ -z "$WORKER_TAG" ]]; then
  echo "Worker '$WORKER_NAME' was not found. See $OUT_DIR/workers.json" >&2
  exit 2
fi

SCRIPT_SETTINGS_TOOL="$(pick_tool cloudflare_api_get_accounts_workers_scripts_by_script_name_script_settings 'workers_scripts_by_script_name_script_settings')"
VERSION_SETTINGS_TOOL="$(pick_tool cloudflare_api_get_accounts_workers_scripts_by_script_name_settings 'workers_scripts_by_script_name_settings')"
SUBDOMAIN_TOOL="$(pick_tool cloudflare_api_get_accounts_workers_scripts_by_script_name_subdomain 'workers_scripts_by_script_name_subdomain')"
SCHEDULES_TOOL="$(pick_tool cloudflare_api_get_accounts_workers_scripts_by_script_name_schedules 'workers_scripts_by_script_name_schedules')"
DEPLOYMENTS_TOOL="$(pick_tool cloudflare_api_get_accounts_workers_scripts_by_script_name_deployments 'workers_scripts_by_script_name_deployments')"
BUILD_TRIGGERS_TOOL="$(pick_tool cloudflare_api_get_accounts_builds_workers_by_external_script_id_triggers 'builds_workers_by_external_script_id_triggers')"
BUILDS_TOOL="$(pick_tool cloudflare_api_get_accounts_builds_workers_by_external_script_id_builds 'builds_workers_by_external_script_id_builds')"
ROUTES_TOOL="$(pick_tool cloudflare_api_get_zones_workers_routes 'get_zones_workers_routes')"

execute_tool script-settings "$SCRIPT_SETTINGS_TOOL" "$(args_for "$SCRIPT_SETTINGS_TOOL" script "$WORKER_NAME")"
execute_tool version-settings "$VERSION_SETTINGS_TOOL" "$(args_for "$VERSION_SETTINGS_TOOL" script "$WORKER_NAME")"
execute_tool subdomain "$SUBDOMAIN_TOOL" "$(args_for "$SUBDOMAIN_TOOL" script "$WORKER_NAME")"
execute_tool schedules "$SCHEDULES_TOOL" "$(args_for "$SCHEDULES_TOOL" script "$WORKER_NAME")"
execute_tool deployments "$DEPLOYMENTS_TOOL" "$(args_for "$DEPLOYMENTS_TOOL" script "$WORKER_NAME")"
execute_tool build-triggers "$BUILD_TRIGGERS_TOOL" "$(args_for "$BUILD_TRIGGERS_TOOL" external_script "$WORKER_TAG")"
execute_tool builds "$BUILDS_TOOL" "$(args_for "$BUILDS_TOOL" external_script "$WORKER_TAG")"

if [[ -n "$ZONE_ID" ]]; then
  execute_tool routes "$ROUTES_TOOL" "$(args_for "$ROUTES_TOOL" zone "$ZONE_ID")"
else
  jq -nc --arg zone "$ZONE_NAME" '{skipped:true, reason:"zone not found", zone:$zone}' > "$OUT_DIR/routes.json"
fi

jq -n \
  --arg worker "$WORKER_NAME" \
  --arg zone "$ZONE_NAME" \
  --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg output_directory "$OUT_DIR" \
  '{
    worker:$worker,
    zone:$zone,
    generated_at:$generated_at,
    output_directory:$output_directory,
    read_only:true,
    files:[
      "target.json",
      "workers.json",
      "script-settings.json",
      "version-settings.json",
      "subdomain.json",
      "schedules.json",
      "deployments.json",
      "workers-domains.json",
      "routes.json",
      "build-triggers.json",
      "builds.json",
      "d1-databases.json",
      "kv-namespaces.json",
      "r2-buckets.json",
      "queues.json",
      "tools.json"
    ]
  }' > "$OUT_DIR/manifest.json"

printf 'Inventory written to %s\n' "$OUT_DIR"
printf 'Send manifest.json and the generated *.json files for review.\n'
