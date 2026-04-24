#!/bin/bash

# --- Gateway Configuration: config.yaml, .env (install + .env.sensitive merged), .env.sensitive (secrets) ---
# Requires: PROJECT_DIR, SRC_DIR, GATEWAY_*, ROOT_MODE, etc., lib/utils.sh (sed_inplace)

# Read a simple YAML value (section.key or section.sub.key)
# Usage: get_yaml_val file.yml "ollama.base_url"
get_yaml_val() {
    local file="$1" key="$2"
    [ ! -f "$file" ] && return
    awk -v key="$key" '
        BEGIN { n = split(key, parts, "."); section = parts[1]; key2 = parts[2] }
        /^[a-zA-Z_][a-zA-Z0-9_]*:/ { gsub(/:.*/, ""); current = $0 }
        current == section && $0 ~ key2 ":" {
            sub(/^[^:]+:[ \t]*/, "");
            sub(/[ \t#].*$/, "");
            gsub(/^["\047]|["\047]$/, "");
            print;
            exit
        }
    ' "$file"
}

# Extract models block from config.yaml (from "models:" to next top-level key or EOF)
extract_models_block() {
    local file="$1"
    [ ! -f "$file" ] && return
    awk '/^models:/{f=1} f && /^[a-z]/ && !/^models:/{exit} f{print}' "$file" 2>/dev/null || true
}

# Emit the canonical security section (order + comments). Used for new config and for in-place replacement.
emit_security_block() {
    echo "security:"
    echo "  # ENABLED by default for ClawFather"
    echo "  sandbox_mode: ${SANDBOX_MODE:-true}"
    echo "  safe_mode: ${SAFE_MODE:-true}"
    echo "  bridge_enabled: ${BRIDGE_ENABLED:-true}"
    echo "  no_new_privs: ${NO_NEW_PRIVS:-true}"
    echo "  browser_control: ${BROWSER_CONTROL:-true}"
    echo "  tools_elevated: ${TOOLS_ELEVATED:-true}"
    echo "  # Extra security"
    echo "  read_only_mounts: ${READ_ONLY_MOUNTS:-false}"
    echo "  networking_offline: ${NETWORKING_OFFLINE:-false}"
    echo "  paranoid_mode: ${PARANOID_MODE:-false}"
    echo "  # Convinience"
    echo "  hooks_enabled: ${HOOKS_ENABLED:-false}"
    echo "  auto_start: ${AUTO_START:-false}"
    echo "  # Danger zone"
    echo "  root_mode: ${ROOT_MODE:-false}"
    echo "  god_mode: ${GOD_MODE:-false}"
}

# Build models block from wizard variables (MODEL_GENERAL, FALLBACK_GENERAL, etc.)
build_models_block_from_wizard() {
    local _gen="${MODEL_GENERAL:-zai/glm-4.7}"
    local _lite="${MODEL_LITE:-zai/glm-4.7-flash}"
    local _heavy="${MODEL_HEAVY:-zai/glm-4.7}"
    local _fb_gen_def="google/gemini-3-pro-preview
google-antigravity/gemini-3-pro-high
anthropic/claude-sonnet-4-5"
    local _fb_lite_def="google/gemini-3-flash-preview
google-antigravity/gemini-3-flash
anthropic/claude-haiku-4-5"
    local _fb_heavy_def="google/gemini-3-pro-preview
google-antigravity/gemini-3-pro-high
anthropic/claude-opus-4-5"
    _write_fb() {
        local user_pick="$1" defs="$2"
        if [ "${FALLBACKS_SETUP:-false}" != true ]; then echo "      fallbacks: []"; return; fi
        echo "      fallbacks:"
        [ -n "$user_pick" ] && echo "        - $user_pick"
        echo "$defs" | while IFS= read -r _d; do [ -n "$_d" ] && [ "$_d" != "$user_pick" ] && echo "        - $_d"; done
    }
    echo "models:"
    echo "  agents:"
    echo "    general:"
    echo "      primary: $_gen"
    _write_fb "${FALLBACK_GENERAL:-}" "$_fb_gen_def"
    echo "    light:"
    echo "      primary: $_lite"
    _write_fb "${FALLBACK_LITE:-}" "$_fb_lite_def"
    echo "    heavy:"
    echo "      primary: $_heavy"
    _write_fb "${FALLBACK_HEAVY:-}" "$_fb_heavy_def"
}

# Convert path to ~/ form for config.yaml (never write full /Users/username paths).
to_config_path() {
    local p="${1:-}"
    [[ -z "$p" ]] && echo "" && return
    [[ "$p" == ~* ]] && p="${p/#\~/$HOME}"
    [[ "$p" == "$HOME" ]] && echo "~" && return
    [[ "$p" == "$HOME/"* ]] && echo "~/${p#$HOME/}" && return
    echo "$p"
}

# Return Compose project name from OpenClaw config dir path (basename, sanitized for [a-z0-9_.-]).
# Used by executor for wipe check and by generate_env for .env.
get_compose_project_name() {
    local _dir="${1:-}"
    [[ "$_dir" == ~* ]] && _dir="${_dir/#\~/$HOME}"
    [ -z "$_dir" ] && echo "openclaw" && return
    local _base
    _base="$(basename "$_dir" 2>/dev/null || echo "openclaw")"
    _base="$(echo "$_base" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_.-]/-/g' | sed 's/^[.-]*//;s/[.-]*$//' | sed 's/--*/-/g')"
    if [[ -z "$_base" ]] || [[ "$_base" != [a-z0-9]* ]]; then
        echo "openclaw"
    else
        echo "$_base"
    fi
}

# Merge .env.sensitive (API keys, token) into .env. .env = install config + sensitive, used by Docker.
merge_env_sensitive_into_env() {
    local _env="$PROJECT_DIR/.env"
    local _sensitive="$PROJECT_DIR/.env.sensitive"
    [ ! -f "$_env" ] && return
    [ ! -f "$_sensitive" ] && return
    local _tmp="$PROJECT_DIR/.env.merged.tmp"
    awk '
        FNR==NR {
            if ($0 ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { key=$0; sub(/=.*/, "", key); sensitive[key]=$0 }
            next
        }
        {
            if ($0 ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { key=$0; sub(/=.*/, "", key); if (key in sensitive) { print sensitive[key]; seen[key]=1; next }; seen[key]=1 }
            print
        }
        END { for (k in sensitive) if (!(k in seen)) print sensitive[k] }
    ' "$_sensitive" "$_env" > "$_tmp" && mv "$_tmp" "$_env"
}

# Update (or insert) a simple "section.key: value" while preserving comments and alignment.
# - Preserves all unrelated lines as-is (including comments/blank lines).
# - If the key exists: replaces only the value, keeps inline comment and padding (structure unchanged).
# - If the section/key is missing, inserts it.
yaml_upsert_section_kv() {
    local file="$1" section="$2" key="$3" value="$4"
    [ -z "$file" ] || [ -z "$section" ] || [ -z "$key" ] && return 1
    local _tmp
    _tmp="$(mktemp 2>/dev/null || echo "/tmp/cfg_upsert_$$")"
    awk -v section="$section" -v key="$key" -v val="$value" '
        BEGIN { in_section = 0; section_found = 0; key_done = 0 }
        # Top-level key (no indentation)
        /^[a-zA-Z_][a-zA-Z0-9_]*:/ {
            if ($0 ~ ("^" section ":")) { in_section = 1; section_found = 1 }
            else {
                if (in_section && !key_done) {
                    print "  " key ": " val
                    key_done = 1
                }
                in_section = 0
            }
        }
        {
            if (in_section && match($0, "^  " key ":[ \t]*")) {
                kp = "  " key ": "
                pad_between = substr($0, RSTART + length(kp), RLENGTH - length(kp))
                rest = substr($0, RSTART + RLENGTH)
                comment_part = ""
                value_plus = rest
                if (match(rest, /[ \t]+#/)) {
                    comment_part = substr(rest, RSTART)
                    value_plus = substr(rest, 1, RSTART - 1)
                }
                pad_before = ""
                if (match(value_plus, /[ \t]*$/)) { pad_before = substr(value_plus, RSTART) }
                print "  " key ": " pad_between val pad_before comment_part
                key_done = 1
                next
            }
            print
        }
        END {
            if (in_section && !key_done) { print "  " key ": " val; key_done = 1 }
            if (!section_found) {
                print ""
                print section ":"
                print "  " key ": " val
            }
        }
    ' "$file" > "$_tmp" && mv "$_tmp" "$file" || { rm -f "$_tmp" 2>/dev/null || true; return 1; }
}

# Update models in-place (primaries + fallbacks) without rewriting the whole file.
# Uses build_models_block_from_wizard for the desired values, but preserves all existing comments outside the replaced lines.
yaml_update_models_from_wizard() {
    local file="$1"
    [ ! -f "$file" ] && return 0

    local _mb _tmp _fb_gen _fb_lite _fb_heavy
    _mb="$(build_models_block_from_wizard)"
    _fb_gen="$(mktemp 2>/dev/null || echo "/tmp/fb_gen_$$")"
    _fb_lite="$(mktemp 2>/dev/null || echo "/tmp/fb_lite_$$")"
    _fb_heavy="$(mktemp 2>/dev/null || echo "/tmp/fb_heavy_$$")"

    # Extract the rendered fallback list lines ("        - ...") for each agent from the wizard block.
    printf "%s\n" "$_mb" | awk '
        $0 ~ /^    general:$/ { a="general"; next }
        $0 ~ /^    light:$/   { a="light"; next }
        $0 ~ /^    heavy:$/   { a="heavy"; next }
        $0 ~ /^      fallbacks:/ { in_fb=1; next }
        $0 ~ /^      / { in_fb=0 }
        in_fb && $0 ~ /^        - / { print a "\t" $0 }
    ' | while IFS=$'\t' read -r a line; do
        case "$a" in
            general) printf "%s\n" "$line" >> "$_fb_gen" ;;
            light)   printf "%s\n" "$line" >> "$_fb_lite" ;;
            heavy)   printf "%s\n" "$line" >> "$_fb_heavy" ;;
        esac
    done

    local _fb_gen_empty=0 _fb_lite_empty=0 _fb_heavy_empty=0
    [ ! -s "$_fb_gen" ] && _fb_gen_empty=1
    [ ! -s "$_fb_lite" ] && _fb_lite_empty=1
    [ ! -s "$_fb_heavy" ] && _fb_heavy_empty=1

    _tmp="$(mktemp 2>/dev/null || echo "/tmp/models_upd_$$")"
    awk -v gen="${MODEL_GENERAL:-}" -v lite="${MODEL_LITE:-}" -v heavy="${MODEL_HEAVY:-}" \
        -v fb_enabled="${FALLBACKS_SETUP:-false}" \
        -v fb_gen_file="$_fb_gen" -v fb_lite_file="$_fb_lite" -v fb_heavy_file="$_fb_heavy" \
        -v fb_gen_empty="$_fb_gen_empty" -v fb_lite_empty="$_fb_lite_empty" -v fb_heavy_empty="$_fb_heavy_empty" '
        function print_fb(file,    l) {
            while ((getline l < file) > 0) { print l }
            close(file)
        }
        BEGIN { in_models=0; agent=""; in_fb=0 }
        # Enter/exit top-level models section
        /^models:/ { in_models=1; print; next }
        /^[a-zA-Z_][a-zA-Z0-9_]*:/ {
            if (in_models) { in_models=0; agent=""; in_fb=0 }
        }
        {
            if (!in_models) { print; next }

            if ($0 ~ /^    general:$/) { agent="general"; in_fb=0; print; next }
            if ($0 ~ /^    light:$/)   { agent="light";   in_fb=0; print; next }
            if ($0 ~ /^    heavy:$/)   { agent="heavy";   in_fb=0; print; next }

            # Update primary model line while preserving inline comment.
            if ($0 ~ /^      primary:/) {
                c = ""
                if (match($0, /[ \t]+#/)) { c = substr($0, RSTART) }
                if (agent=="general" && gen!="")  { print "      primary: " gen c; next }
                if (agent=="light"   && lite!="") { print "      primary: " lite c; next }
                if (agent=="heavy"   && heavy!=""){ print "      primary: " heavy c; next }
                print
                next
            }

            # Replace fallbacks block content (list items only), preserving comment lines.
            if ($0 ~ /^      fallbacks:/) {
                c = ""
                if (match($0, /[ \t]+#/)) { c = substr($0, RSTART) }
                if (fb_enabled != "true") {
                    print "      fallbacks: []" c
                    in_fb=1
                    next
                }
                # Safety: if we could not render a fallback list for this agent, do not touch existing list.
                if (agent=="general" && fb_gen_empty=="1") { print; in_fb=0; next }
                if (agent=="light" && fb_lite_empty=="1") { print; in_fb=0; next }
                if (agent=="heavy" && fb_heavy_empty=="1") { print; in_fb=0; next }
                print "      fallbacks:" c
                if (agent=="general") { print_fb(fb_gen_file) }
                else if (agent=="light") { print_fb(fb_lite_file) }
                else if (agent=="heavy") { print_fb(fb_heavy_file) }
                in_fb=1
                next
            }

            # When inside the fallbacks list, drop only list items; keep comments/blank lines.
            if (in_fb) {
                if ($0 ~ /^        - /) { next }
                if ($0 ~ /^        #/ || $0 ~ /^        *$/) { print; next }
                if ($0 !~ /^        /) { in_fb=0 }
            }

            print
        }
    ' "$file" > "$_tmp" && mv "$_tmp" "$file" || { rm -f "$_tmp" 2>/dev/null || true; }

    rm -f "$_fb_gen" "$_fb_lite" "$_fb_heavy" 2>/dev/null || true
}

# Write wizard values to config.yaml (preserves all sections; never overwrites gateway/workspace/docker/ollama/security)
write_config() {
    local _cfg="$PROJECT_DIR/config.yaml"
    local _port="${OPENCLAW_GATEWAY_PORT:-18789}"
    local _bridge="${OPENCLAW_BRIDGE_PORT:-18790}"
    local _bind="${GATEWAY_BIND:-lan}"
    local _img="${DOCKER_IMAGE_SEL:-alpine/openclaw:latest}"
    local _user="node"
    case "${DOCKER_IMAGE_SEL:-}" in *fourplayers*) _user="root" ;; *)
        [ "$ROOT_MODE" = "true" ] && _user="root"
    ;; esac
    local _mirror="false"
    [ "$MIRROR_PROJECTS" = true ] && _mirror="true"
    local _proj="${LOCAL_PROJECTS_DIR_ABS:-$PROJECTS_DIR}"
    local _dproj="${DOCKER_PROJECTS_PATH:-}"
    local _dbase="${OPENCLAW_DOCKER_BASE:-~/.openclaw}"
    local _dws="${OPENCLAW_DOCKER_WORKSPACE:-$OPENCLAW_DOCKER_BASE/workspace}"
    local _proj_abs="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)"
    local _cfg_dir _ws_dir
    if [ -n "${OPENCLAW_CONFIG_DIR:-}" ]; then
        _cfg_dir="$OPENCLAW_CONFIG_DIR"
        _ws_dir="${OPENCLAW_WORKSPACE_DIR:-$OPENCLAW_CONFIG_DIR/workspace}"
        _cfg_dir_resolved="$(cd "$OPENCLAW_CONFIG_DIR" 2>/dev/null && pwd)" || _cfg_dir_resolved="$_cfg_dir"
        [[ "$_cfg_dir_resolved" == "$_proj_abs/.openclaw" ]] && _cfg_dir="./.openclaw" && _ws_dir="./.openclaw/workspace"
    else
        local _cfg_dir_abs="${OPENCLAW_WORKSPACE_DIR_ABS:-$PROJECT_DIR}/.openclaw"
        local _ws_dir_abs="${OPENCLAW_WORKSPACE_DIR_ABS:-$PROJECT_DIR}/.openclaw/workspace"
        _cfg_dir="$_cfg_dir_abs"
        _ws_dir="$_ws_dir_abs"
        [[ "$_cfg_dir_abs" == "$_proj_abs/.openclaw" ]] && _cfg_dir="./.openclaw" && _ws_dir="./.openclaw/workspace"
    fi
    local _vol_mode=""
    [ "${READ_ONLY_MOUNTS:-false}" = "true" ] && _vol_mode=":ro"
    local _net_mode="$(get_yaml_val "$_cfg" "docker.network_mode" 2>/dev/null)"
    [ -z "$_net_mode" ] && _net_mode="bridge"
    local _ollama_url=""
    if [ "${USE_OLLAMA:-}" = "true" ]; then
        _ollama_url="$(get_yaml_val "$_cfg" "ollama.base_url" 2>/dev/null)"
        [ -z "$_ollama_url" ] && _ollama_url="http://host.docker.internal:11434"
    fi
    # Models: use wizard selection when set, else preserve from existing config, else defaults
    if [ -n "${MODEL_GENERAL:-}" ]; then
        _models_block="$(build_models_block_from_wizard)"
    else
        _models_block="$(extract_models_block "$_cfg")"
    fi
    [ -z "$_models_block" ] && _models_block="models:
  agents:
    general:
      primary: zai/glm-4.7
      fallbacks:
        - google/gemini-3-pro-preview
        - google-antigravity/gemini-3-pro-high
        - anthropic/claude-sonnet-4-5
    light:
      primary: zai/glm-4.7-flash
      fallbacks:
        - google/gemini-3-flash-preview
        - google-antigravity/gemini-3-flash
        - anthropic/claude-haiku-4-5
    heavy:
      primary: zai/glm-4.7
      fallbacks:
        - google/gemini-3-pro-preview
        - google-antigravity/gemini-3-pro-high
        - anthropic/claude-opus-4-5"
    # Write paths as ~/ in config.yaml (never full /Users/username)
    local _cfg_dir_out _ws_dir_out _proj_out _dproj_out _dbase_out _dws_out
    _cfg_dir_out="$(to_config_path "$_cfg_dir")"
    _ws_dir_out="$(to_config_path "$_ws_dir")"
    _proj_out="$(to_config_path "$_proj")"
    _dproj_out="$(to_config_path "$_dproj")"
    _dbase_out="$(to_config_path "$_dbase")"
    _dws_out="$(to_config_path "$_dws")"
    local _vol_mode_yaml="\"$_vol_mode\""

    # If missing, create a baseline config with the default comment blocks.
    if [ ! -f "$_cfg" ]; then
        cat > "$_cfg" << EOF
# Clawfather config — models + wizard defaults
# Edit below. Run install to apply changes.

$_models_block

gateway:
  port: $_port
  bind: $_bind
  bridge_port: $_bridge

workspace:
  config_dir: $_cfg_dir_out
  workspace_dir: $_ws_dir_out
  mirror_projects: $_mirror
  projects_dir: $_proj_out
  docker_projects_path: $_dproj_out
  docker_base: $_dbase_out
  docker_workspace: $_dws_out

docker:
  image: $_img
  user: $_user
  network_mode: $_net_mode
  vol_mode: $_vol_mode_yaml
  service_manager: none
  no_service: true
EOF
        [ "${USE_OLLAMA:-}" = "true" ] && [ -n "$_ollama_url" ] && cat >> "$_cfg" << OLLAMA

ollama:
  base_url: $_ollama_url
OLLAMA
        echo "" >> "$_cfg"
        emit_security_block >> "$_cfg"
        return 0
    fi

    # Update existing file in-place to preserve all user comments.
    if [ -n "${MODEL_GENERAL:-}" ]; then
        yaml_update_models_from_wizard "$_cfg"
    fi

    yaml_upsert_section_kv "$_cfg" "gateway" "port" "$_port"
    yaml_upsert_section_kv "$_cfg" "gateway" "bind" "$_bind"
    yaml_upsert_section_kv "$_cfg" "gateway" "bridge_port" "$_bridge"

    yaml_upsert_section_kv "$_cfg" "workspace" "config_dir" "$_cfg_dir_out"
    yaml_upsert_section_kv "$_cfg" "workspace" "workspace_dir" "$_ws_dir_out"
    yaml_upsert_section_kv "$_cfg" "workspace" "mirror_projects" "$_mirror"
    yaml_upsert_section_kv "$_cfg" "workspace" "projects_dir" "$_proj_out"
    yaml_upsert_section_kv "$_cfg" "workspace" "docker_projects_path" "$_dproj_out"
    yaml_upsert_section_kv "$_cfg" "workspace" "docker_base" "$_dbase_out"
    yaml_upsert_section_kv "$_cfg" "workspace" "docker_workspace" "$_dws_out"

    yaml_upsert_section_kv "$_cfg" "docker" "image" "$_img"
    yaml_upsert_section_kv "$_cfg" "docker" "user" "$_user"
    yaml_upsert_section_kv "$_cfg" "docker" "network_mode" "$_net_mode"
    yaml_upsert_section_kv "$_cfg" "docker" "vol_mode" "$_vol_mode_yaml"
    yaml_upsert_section_kv "$_cfg" "docker" "service_manager" "none"
    yaml_upsert_section_kv "$_cfg" "docker" "no_service" "true"

    if [ "${USE_OLLAMA:-}" = "true" ] && [ -n "$_ollama_url" ]; then
        yaml_upsert_section_kv "$_cfg" "ollama" "base_url" "$_ollama_url"
    fi

    # Upsert security keys in place so user comments and structure are preserved
    yaml_upsert_section_kv "$_cfg" "security" "sandbox_mode" "${SANDBOX_MODE:-false}"
    yaml_upsert_section_kv "$_cfg" "security" "root_mode" "${ROOT_MODE:-false}"
    yaml_upsert_section_kv "$_cfg" "security" "safe_mode" "${SAFE_MODE:-true}"
    yaml_upsert_section_kv "$_cfg" "security" "bridge_enabled" "${BRIDGE_ENABLED:-true}"
    yaml_upsert_section_kv "$_cfg" "security" "no_new_privs" "${NO_NEW_PRIVS:-true}"
    yaml_upsert_section_kv "$_cfg" "security" "browser_control" "${BROWSER_CONTROL:-true}"
    yaml_upsert_section_kv "$_cfg" "security" "tools_elevated" "${TOOLS_ELEVATED:-true}"
    yaml_upsert_section_kv "$_cfg" "security" "hooks_enabled" "${HOOKS_ENABLED:-false}"
    yaml_upsert_section_kv "$_cfg" "security" "read_only_mounts" "${READ_ONLY_MOUNTS:-false}"
    yaml_upsert_section_kv "$_cfg" "security" "networking_offline" "${NETWORKING_OFFLINE:-false}"
    yaml_upsert_section_kv "$_cfg" "security" "paranoid_mode" "${PARANOID_MODE:-false}"
    yaml_upsert_section_kv "$_cfg" "security" "auto_start" "${AUTO_START:-false}"
    yaml_upsert_section_kv "$_cfg" "security" "god_mode" "${GOD_MODE:-false}"
}

# Generate .env from config.yaml (install config), then merge .env.sensitive (API keys, token).
generate_env() {
    local _cfg="$PROJECT_DIR/config.yaml"
    local _out="$PROJECT_DIR/.env"
    [ ! -f "$_cfg" ] && return
    local _port _bridge _bind _img _user _mirror _proj _dproj _dbase _dws _cfg_dir _ws_dir _skills_dir _vol _net _ollama
    _port="$(get_yaml_val "$_cfg" "gateway.port" 2>/dev/null)"
    [ -z "$_port" ] && _port="18789"
    _bridge="$(get_yaml_val "$_cfg" "gateway.bridge_port" 2>/dev/null)"
    [ -z "$_bridge" ] && _bridge="18790"
    _bind="$(get_yaml_val "$_cfg" "gateway.bind" 2>/dev/null)"
    [ -z "$_bind" ] && _bind="lan"
    _img="$(get_yaml_val "$_cfg" "docker.image" 2>/dev/null)"
    [ -z "$_img" ] && _img="alpine/openclaw:latest"
    _user="$(get_yaml_val "$_cfg" "docker.user" 2>/dev/null)"
    [ -z "$_user" ] && _user="node"
    _mirror="$(get_yaml_val "$_cfg" "workspace.mirror_projects" 2>/dev/null)"
    [ -z "$_mirror" ] && _mirror="false"
    _proj="$(get_yaml_val "$_cfg" "workspace.projects_dir" 2>/dev/null)"
    _dproj="$(get_yaml_val "$_cfg" "workspace.docker_projects_path" 2>/dev/null)"
    _dbase="$(get_yaml_val "$_cfg" "workspace.docker_base" 2>/dev/null)"
    [ -z "$_dbase" ] && _dbase="~/.openclaw"
    _dws="$(get_yaml_val "$_cfg" "workspace.docker_workspace" 2>/dev/null)"
    [ -z "$_dws" ] && _dws="~/.openclaw/workspace"
    # Expand docker_projects_path template if it contains ${...}
    if [[ -n "$_dproj" ]] && [[ "$_dproj" == *'${'* ]]; then
        _base="${DOCKER_PROJECTS_BASENAME:-$(basename "${_proj:-}" 2>/dev/null || echo "Projects")}"
        _dproj="${_dws}/${_base}"
    fi
    _cfg_dir="$(get_yaml_val "$_cfg" "workspace.config_dir" 2>/dev/null)"
    _ws_dir="$(get_yaml_val "$_cfg" "workspace.workspace_dir" 2>/dev/null)"
    _skills_dir="$(get_yaml_val "$_cfg" "workspace.skills_dir" 2>/dev/null)"
    [ -z "$_skills_dir" ] && _skills_dir="./skills"
    _vol="$(get_yaml_val "$_cfg" "docker.vol_mode" 2>/dev/null)"
    _net="$(get_yaml_val "$_cfg" "docker.network_mode" 2>/dev/null)"
    [ -z "$_net" ] && _net="bridge"
    _ollama="$(get_yaml_val "$_cfg" "ollama.base_url" 2>/dev/null)"
    [ -z "$_ollama" ] && _ollama="http://host.docker.internal:11434"
    # When user chose not to use local LLM, leave OLLAMA_BASE_URL empty so the app skips Ollama discovery
    [ "$USE_OLLAMA" = "false" ] && _ollama=""
    # Shell vars override (same run) — use wizard values so install outside project (e.g. ~/Projects/openclaw) works
    [ -n "${OPENCLAW_CONFIG_DIR:-}" ] && _cfg_dir="$OPENCLAW_CONFIG_DIR"
    [ -n "${OPENCLAW_WORKSPACE_DIR:-}" ] && _ws_dir="$OPENCLAW_WORKSPACE_DIR"
    [ -n "${OPENCLAW_SKILLS_DIR:-}" ] && _skills_dir="$OPENCLAW_SKILLS_DIR"
    # Docker needs absolute paths for mounts when install dir is outside project
    [[ "$_cfg_dir" == ~* ]] && _cfg_dir="${_cfg_dir/#\~/$HOME}"
    [[ "$_ws_dir" == ~* ]] && _ws_dir="${_ws_dir/#\~/$HOME}"
    [[ "$_skills_dir" == ~* ]] && _skills_dir="${_skills_dir/#\~/$HOME}"
    if [[ "$_cfg_dir" != /* ]]; then
        _cfg_orig="$_cfg_dir"
        _cfg_dir="$(cd "$PROJECT_DIR" 2>/dev/null && cd "$_cfg_orig" 2>/dev/null && pwd)" || _cfg_dir="$PROJECT_DIR/$_cfg_orig"
    fi
    if [[ "$_ws_dir" != /* ]]; then
        _ws_orig="$_ws_dir"
        _ws_dir="$(cd "$PROJECT_DIR" 2>/dev/null && cd "$_ws_orig" 2>/dev/null && pwd)" || _ws_dir="$PROJECT_DIR/$_ws_orig"
    fi
    if [[ "$_skills_dir" != /* ]]; then
        _skills_orig="$_skills_dir"
        _skills_dir="$(cd "$PROJECT_DIR" 2>/dev/null && cd "$_skills_orig" 2>/dev/null && pwd)" || _skills_dir="$PROJECT_DIR/$_skills_orig"
    fi
    [ -n "${OPENCLAW_IMAGE:-}" ] && _img="$OPENCLAW_IMAGE"
    [ -n "${GATEWAY_BIND:-}" ] && _bind="$GATEWAY_BIND"
    [ -n "${OPENCLAW_GATEWAY_PORT:-}" ] && _port="$OPENCLAW_GATEWAY_PORT"
    [ -n "${OPENCLAW_BRIDGE_PORT:-}" ] && _bridge="$OPENCLAW_BRIDGE_PORT"
    [ -n "${OPENCLAW_USER:-}" ] && _user="$OPENCLAW_USER"
    case "$_img" in *fourplayers*) _user="root" ;; esac
    [ -n "${MIRROR_PROJECTS:-}" ] && _mirror="$([ "$MIRROR_PROJECTS" = true ] && echo "true" || echo "false")"
    [ -n "${LOCAL_PROJECTS_DIR:-}" ] && _proj="$LOCAL_PROJECTS_DIR"
    [ -n "${DOCKER_PROJECTS_PATH:-}" ] && _dproj="$DOCKER_PROJECTS_PATH"
    # Docker bind mounts require an absolute host path; expand ~ and resolve relative paths.
    if [[ -n "${_proj:-}" ]]; then
        [[ "$_proj" == ~* ]] && _proj="${_proj/#\~/$HOME}"
        if [[ "$_proj" != /* ]]; then
            _proj_orig="$_proj"
            _proj="$(cd "$PROJECT_DIR" 2>/dev/null && cd "$_proj_orig" 2>/dev/null && pwd)" || _proj="$PROJECT_DIR/$_proj_orig"
        fi
    fi
    [ -n "${OPENCLAW_DOCKER_BASE:-}" ] && _dbase="$OPENCLAW_DOCKER_BASE"
    [ -n "${OPENCLAW_DOCKER_WORKSPACE:-}" ] && _dws="$OPENCLAW_DOCKER_WORKSPACE"
    [ -n "${OPENCLAW_NETWORK_MODE:-}" ] && _net="$OPENCLAW_NETWORK_MODE"
    [ -n "${OPENCLAW_VOL_MODE:-}" ] && _vol="$OPENCLAW_VOL_MODE"
    [ -n "${OLLAMA_BASE_URL:-}" ] && _ollama="$OLLAMA_BASE_URL"
    # Docker volume mounts require absolute paths; expand ~ to container home
    _container_home="/home/$_user"
    [ "$_user" = "root" ] && _container_home="/root"
    [[ "$_dbase" == ~* ]] && _dbase="$_container_home/${_dbase#\~/}"
    [[ "$_dws" == ~* ]] && _dws="$_container_home/${_dws#\~/}"
    [[ "$_dproj" == ~* ]] && _dproj="$_container_home/${_dproj#\~/}"
    _compose_project="$(get_compose_project_name "$_cfg_dir")"
    {
        echo "# Generated from config.yaml — do not edit by hand"
        echo "COMPOSE_PROJECT_NAME=$_compose_project"
        echo "OPENCLAW_CONFIG_DIR=$_cfg_dir"
        echo "OPENCLAW_WORKSPACE_DIR=$_ws_dir"
        echo "OPENCLAW_SKILLS_DIR=$_skills_dir"
        echo "OPENCLAW_GATEWAY_PORT=$_port"
        echo "OPENCLAW_BRIDGE_PORT=$_bridge"
        echo "OPENCLAW_GATEWAY_BIND=$_bind"
        echo "OPENCLAW_USER=$_user"
        echo "OPENCLAW_IMAGE=$_img"
        # fourplayers image has openclaw binary, not node dist/index.js; gateway command must use openclaw
        case "$_img" in *fourplayers*) echo "OPENCLAW_GATEWAY_CMD=openclaw" ;; esac
        echo "SANDBOX_MODE=${SANDBOX_MODE:-true}"
        echo "SAFE_MODE=${SAFE_MODE:-true}"
        echo "BOOT_MD=${BOOT_MD:-false}"
        echo "SESSION_MEMORY=${SESSION_MEMORY:-false}"
        echo "GOD_MODE=${GOD_MODE:-false}"
        echo "COMMAND_LOGGER=${COMMAND_LOGGER:-true}"
        echo "OPENCLAW_SERVICE_MANAGER=none"
        echo "OPENCLAW_NO_SERVICE=true"
        echo "MIRROR_PROJECTS=$_mirror"
        echo "LOCAL_PROJECTS_DIR=$_proj"
        echo "DOCKER_PROJECTS_PATH=$_dproj"
        echo "DOCKER_PROJECTS_BASENAME=${DOCKER_PROJECTS_BASENAME:-Projects}"
        echo "OPENCLAW_DOCKER_BASE=$_dbase"
        echo "OPENCLAW_DOCKER_WORKSPACE=$_dws"
        echo "OPENCLAW_DOCKER_HOME=$_container_home"
        # Only set OLLAMA_BASE_URL when user chose local LLM; when No, leave empty so container skips discovery
        if [ -n "$_ollama" ]; then
            echo "OLLAMA_BASE_URL=$_ollama"
            echo "OLLAMA_API_KEY=${OLLAMA_API_KEY:-ollama-local}"
        else
            echo "OLLAMA_BASE_URL="
            echo "OLLAMA_API_KEY="
        fi
        echo "OPENCLAW_VOL_MODE=$_vol"
        echo "OPENCLAW_NETWORK_MODE=$_net"
    } > "$_out"
    merge_env_sensitive_into_env
    # When local LLM not used, omit Ollama env from container so the app never runs Ollama discovery
    local _dc="$PROJECT_DIR/docker-compose.yml"
    if [ -f "$_dc" ]; then
        if [ -z "$_ollama" ]; then
            sed_inplace 's/^\([[:space:]]*\)- \(OLLAMA_BASE_URL=.*\)/\1# - \2/' "$_dc"
            sed_inplace 's/^\([[:space:]]*\)- \(OLLAMA_API_KEY=.*\)/\1# - \2/' "$_dc"
        else
            sed_inplace 's/^\([[:space:]]*\)# - \(OLLAMA_BASE_URL=.*\)/\1- \2/' "$_dc"
            sed_inplace 's/^\([[:space:]]*\)# - \(OLLAMA_API_KEY=.*\)/\1- \2/' "$_dc"
        fi
    fi
}

run_gateway_config() {
    if [[ "$GATEWAY_AUTH_SEL" != *"Password"* ]] && [ -z "$GATEWAY_TOKEN" ]; then
        GATEWAY_TOKEN=$(openssl rand -hex 32 2>/dev/null || date +%s | head -c 32)
    fi
    GATEWAY_SECRET="${GATEWAY_TOKEN:-$GATEWAY_PASSWORD}"

    [ ! -f "$PROJECT_DIR/.env.sensitive" ] && { cp "${PROJECT_DIR}/.env.sensitive.example" "$PROJECT_DIR/.env.sensitive" 2>/dev/null || touch "$PROJECT_DIR/.env.sensitive"; }
    OPENCLAW_WORKSPACE_DIR_ABS="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)"
    # Resolve config dir (before mkdir) so we create the chosen path, not project .openclaw
    _proj_abs="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)"
    if [ -z "${OPENCLAW_CONFIG_DIR:-}" ] || [ -z "${OPENCLAW_WORKSPACE_DIR:-}" ]; then
        # Prefer the installer default (~/.openclaw) if wizard variables are missing.
        _cfg_abs="${OPENCLAW_CONFIG_DIR_DEFAULT:-$HOME/.openclaw}"
        _ws_abs="${WORKSPACE_DIR_DEFAULT:-${_cfg_abs%/}/workspace}"
        OPENCLAW_CONFIG_DIR="$_cfg_abs"
        OPENCLAW_WORKSPACE_DIR="$_ws_abs"
    fi
    _oc_dir="${OPENCLAW_CONFIG_DIR:-${OPENCLAW_CONFIG_DIR_DEFAULT:-$HOME/.openclaw}}"
    [[ "$_oc_dir" == ~* ]] && _oc_dir="${_oc_dir/#\~/$HOME}"
    # macOS convenience: Users/... -> /Users/... (common copy/paste omission)
    if [ "${OS_TYPE:-}" = "macos" ] && [[ "$_oc_dir" == Users/* ]]; then
        _oc_dir="/$_oc_dir"
    fi
    # Resolve relative paths against the project directory; keep absolute paths untouched.
    if [[ "$_oc_dir" != /* ]]; then
        local _resolved=""
        _resolved="$(cd "$PROJECT_DIR" 2>/dev/null && cd "${_oc_dir}" 2>/dev/null && pwd)"
        if [ -n "$_resolved" ]; then
            _oc_dir="$_resolved"
        else
            _oc_dir="$PROJECT_DIR/${_oc_dir#./}"
        fi
    fi
    mkdir -p "$_oc_dir"
    # When OpenClaw dir is custom, skills live there (sync already wrote to OPENCLAW_CONFIG_DIR/skills)
    [ -n "${OPENCLAW_CONFIG_DIR:-}" ] && OPENCLAW_SKILLS_DIR="${OPENCLAW_CONFIG_DIR%/}/skills"
    [ -z "$DOCKER_PROJECTS_BASENAME" ] && DOCKER_PROJECTS_BASENAME="Projects"
    LOCAL_PROJECTS_DIR_ABS=""
    _projects_dir_raw="${PROJECTS_DIR:-}"
    [[ "$_projects_dir_raw" == ~* ]] && _projects_dir_raw="${_projects_dir_raw/#\~/$HOME}"
    if [[ -n "$_projects_dir_raw" ]] && [[ "$_projects_dir_raw" != /* ]]; then
        _projects_dir_raw="$PROJECT_DIR/$_projects_dir_raw"
    fi
    [ -n "$_projects_dir_raw" ] && LOCAL_PROJECTS_DIR_ABS="$(cd "$_projects_dir_raw" 2>/dev/null && pwd)"

    # Resolve runtime vars — use wizard-set paths when present, else derive from project dir
    # fourplayers/openclaw must run as root: its entrypoint uses runuser which only works as root
    case "${DOCKER_IMAGE_SEL:-}" in *fourplayers*) OPENCLAW_USER=root ;; *)
        OPENCLAW_USER=$([ "$ROOT_MODE" = "true" ] && echo "root" || echo "node")
    ;; esac
    OPENCLAW_IMAGE="${DOCKER_IMAGE_SEL:-alpine/openclaw:latest}"
    OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
    OPENCLAW_BRIDGE_PORT="${OPENCLAW_BRIDGE_PORT:-18790}"
    OPENCLAW_GATEWAY_BIND="${GATEWAY_BIND:-lan}"
    MIRROR_PROJECTS_VAL=$([ "$MIRROR_PROJECTS" = true ] && echo "true" || echo "false")
    LOCAL_PROJECTS_DIR="${LOCAL_PROJECTS_DIR_ABS:-$PROJECTS_DIR}"
    DOCKER_PROJECTS_PATH="${DOCKER_PROJECTS_PATH:-}"
    OPENCLAW_DOCKER_BASE="${OPENCLAW_DOCKER_BASE:-~/.openclaw}"
    OPENCLAW_DOCKER_WORKSPACE="${OPENCLAW_DOCKER_WORKSPACE:-${OPENCLAW_DOCKER_BASE:-~/.openclaw}/workspace}"
    OPENCLAW_VOL_MODE=""
    [ "${READ_ONLY_MOUNTS:-false}" = "true" ] && OPENCLAW_VOL_MODE=":ro"
    # Only set OLLAMA_BASE_URL when user chose local LLM (avoids passing it to compose when cloud-only)
    if [ "${USE_OLLAMA:-}" = "true" ]; then
        OLLAMA_BASE_URL="$(get_yaml_val "$PROJECT_DIR/config.yaml" "ollama.base_url" 2>/dev/null)"
        [ -z "$OLLAMA_BASE_URL" ] && OLLAMA_BASE_URL="http://host.docker.internal:11434/v1"
    else
        OLLAMA_BASE_URL=""
    fi
    OPENCLAW_NETWORK_MODE="$(get_yaml_val "$PROJECT_DIR/config.yaml" "docker.network_mode" 2>/dev/null)"
    [ -z "$OPENCLAW_NETWORK_MODE" ] && OPENCLAW_NETWORK_MODE="bridge"

    # Write OPENCLAW_GATEWAY_TOKEN to .env.sensitive (merged into .env by generate_env)
    if grep -q "^OPENCLAW_GATEWAY_TOKEN=" "$PROJECT_DIR/.env.sensitive" 2>/dev/null; then
        sed_inplace "s|^OPENCLAW_GATEWAY_TOKEN=.*|OPENCLAW_GATEWAY_TOKEN=$GATEWAY_SECRET|" "$PROJECT_DIR/.env.sensitive"
    else
        echo "OPENCLAW_GATEWAY_TOKEN=$GATEWAY_SECRET" >> "$PROJECT_DIR/.env.sensitive"
    fi

    # Write config.yaml and generate .env (install config + merge .env.sensitive)
    write_config
    generate_env

    # Keep docker-compose sed for MIRROR_PROJECTS / LOCAL_PROJECTS_DIR
    local _dc="$PROJECT_DIR/docker-compose.yml"
    if [ -f "$_dc" ]; then
        if [ "$MIRROR_PROJECTS" = true ] && [ -n "$LOCAL_PROJECTS_DIR_ABS" ] && [ -n "$DOCKER_PROJECTS_PATH" ]; then
            # docker-compose.yml has this line indented; preserve indentation when uncommenting.
            sed_inplace 's|^\([[:space:]]*\)# - \${LOCAL_PROJECTS_DIR}:\${DOCKER_PROJECTS_PATH}|\1- ${LOCAL_PROJECTS_DIR}:${DOCKER_PROJECTS_PATH}|' "$_dc"
        else
            sed_inplace 's|^\([[:space:]]*\)- \${LOCAL_PROJECTS_DIR}:\${DOCKER_PROJECTS_PATH}|\1# - ${LOCAL_PROJECTS_DIR}:${DOCKER_PROJECTS_PATH}|' "$_dc"
        fi
    fi
}
