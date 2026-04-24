#!/bin/bash

# --- Install Defaults ---
# Requires: INSTALL_DIR (dir containing install_clawfather.sh, e.g. src/). PROJECT_ROOT = parent of INSTALL_DIR.

: "${PROJECT_ROOT:=$(cd "${INSTALL_DIR:-.}/.." 2>/dev/null && pwd)}"
PROJECT_DIR_DEFAULT="${PROJECT_ROOT}"
PROJECTS_DIR_DEFAULT="$HOME/Projects"

# Detect OS for path prompt labels
[[ "$(uname -s 2>/dev/null)" =~ [Dd]arwin ]] && HOST_OS_LABEL="macOS" || HOST_OS_LABEL="Linux"

# Container detection
CONTAINER_NAME=""
GATEWAY_SERVICE="openclaw-gateway"

# Load config.yaml first; config values become wizard defaults (config wins over hardcoded)
_CONFIG="${PROJECT_ROOT:-}/config.yaml"
_ci_port="" _ci_bind="" _ci_img="" _ci_dbase="" _ci_dws="" _ci_config_dir="" _ci_workspace_dir="" _ci_projects_dir="" _ci_docker_projects="" _ci_mirror=""
if [ -f "$_CONFIG" ]; then
    _cv() {
        awk -v section="$1" -v key="$2" '
            /^[a-zA-Z_][a-zA-Z0-9_]*:/ { gsub(/:.*/, ""); current = $0 }
            current == section && $0 ~ key ":" {
                sub(/^[^:]+:[ \t]*/, "");
                sub(/[ \t#].*$/, "");
                gsub(/^["\047]|["\047]$/, "");
                print;
                exit
            }
        ' "$_CONFIG" 2>/dev/null || true
    }
    _ci_port=$(_cv "gateway" "port")
    _ci_bind=$(_cv "gateway" "bind")
    _ci_img=$(_cv "docker" "image")
    _ci_dbase=$(_cv "workspace" "docker_base")
    _ci_dws=$(_cv "workspace" "docker_workspace")
    _ci_config_dir=$(_cv "workspace" "config_dir")
    _ci_workspace_dir=$(_cv "workspace" "workspace_dir")
    _ci_projects_dir=$(_cv "workspace" "projects_dir")
    _ci_docker_projects=$(_cv "workspace" "docker_projects_path")
    _ci_mirror=$(_cv "workspace" "mirror_projects")
fi

# Docker-side defaults: config wins when present
OPENCLAW_DOCKER_BASE="${_ci_dbase:-~/.openclaw}"
OPENCLAW_DOCKER_WORKSPACE="${_ci_dws:-$OPENCLAW_DOCKER_BASE/workspace}"

# OpenClaw dir on host (config_dir): from config or default to ~/.openclaw
# Note: user can still choose a project-local directory in the wizard, but we don't default to it.
OPENCLAW_CONFIG_DIR_DEFAULT="${_ci_config_dir:-$HOME/.openclaw}"

# Workspace dir on host: config workspace_dir (absolute ~/ or /) or relative to project, else derived from config_dir
if [ -n "$_ci_workspace_dir" ]; then
    if [[ "$_ci_workspace_dir" == [~/]* ]] || [[ "$_ci_workspace_dir" == /* ]]; then
        WORKSPACE_DIR_DEFAULT="$_ci_workspace_dir"
    else
        _ws_rel="${_ci_workspace_dir#./}"
        WORKSPACE_DIR_DEFAULT="${PROJECT_ROOT}/${_ws_rel}"
    fi
elif [ -n "$_ci_config_dir" ]; then
    WORKSPACE_DIR_DEFAULT="${_ci_config_dir}/workspace"
else
    WORKSPACE_DIR_DEFAULT="${OPENCLAW_CONFIG_DIR_DEFAULT}/workspace"
fi

# Projects / mirror defaults
[ -n "$_ci_projects_dir" ] && PROJECTS_DIR_DEFAULT="$_ci_projects_dir" || true
[ -n "$_ci_docker_projects" ] && DOCKER_PROJECTS_PATH_DEFAULT="$_ci_docker_projects" || true
[ "$_ci_mirror" = "true" ] && MIRROR_PROJECTS_DEFAULT="y" || MIRROR_PROJECTS_DEFAULT="n"

# Gateway / image from config
[ -n "$_ci_port" ] && OPENCLAW_GATEWAY_PORT="${_ci_port}" || OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
[ -n "$_ci_bind" ] && GATEWAY_BIND_PREF="${_ci_bind}" || GATEWAY_BIND_PREF="${GATEWAY_BIND:-lan}"
# Map bind to select index: lan=0 loopback=1 tailscale=2 auto=3 custom=4; unknown (e.g. IP) = custom with prefill
case "${GATEWAY_BIND_PREF}" in lan) GATEWAY_BIND_DEFAULT_INDEX=0 ;; loopback) GATEWAY_BIND_DEFAULT_INDEX=1 ;; tailscale) GATEWAY_BIND_DEFAULT_INDEX=2 ;; auto) GATEWAY_BIND_DEFAULT_INDEX=3 ;; custom) GATEWAY_BIND_DEFAULT_INDEX=4 ;; *) GATEWAY_BIND_DEFAULT_INDEX=4; GATEWAY_BIND_CUSTOM_IP="${GATEWAY_BIND_PREF}" ;; esac
[ -n "$_ci_img" ] && DOCKER_IMAGE_SEL="${_ci_img}" || true

# Security options from config; display order 1-based: 1=Root 2=Safe 3=Bridge 4=Browser 5=Tools 6=Hooks 7=NoNewPrivs 8=AutoStart 9=Sandbox 10=Paranoid 11=Offline 12=ReadOnly 13=God
load_security_defaults_from_config() {
    local cfg="${1:-}"
    [ ! -f "$cfg" ] && return
    _cv_local() {
        awk -v section="$1" -v key="$2" '
            /^[a-zA-Z_][a-zA-Z0-9_]*:/ { gsub(/:.*/, ""); current = $0 }
            current == section && $0 ~ key ":" {
                sub(/^[^:]+:[ \t]*/, "");
                sub(/[ \t#].*$/, "");
                gsub(/^["\047 \t]+|["\047 \t]+$/, "");
                print;
                exit
            }
        ' "$cfg" 2>/dev/null || true
    }
    _cb() { local v="$(_cv_local "security" "$1")"; v="${v// /}"; [ "$v" = "true" ] && echo 1 || echo 0; }
    local _sec_sandbox _sec_root _sec_safe _sec_bridge _sec_browser _sec_tools _sec_hooks _sec_nnp _sec_auto _sec_paranoid _sec_offline _sec_ro _sec_god
    _sec_sandbox=$(_cb "sandbox_mode"); _sec_root=$(_cb "root_mode"); _sec_safe=$(_cb "safe_mode"); _sec_bridge=$(_cb "bridge_enabled")
    _sec_browser=$(_cb "browser_control"); _sec_tools=$(_cb "tools_elevated"); _sec_hooks=$(_cb "hooks_enabled"); _sec_nnp=$(_cb "no_new_privs")
    _sec_auto=$(_cb "auto_start"); _sec_paranoid=$(_cb "paranoid_mode"); _sec_offline=$(_cb "networking_offline"); _sec_ro=$(_cb "read_only_mounts"); _sec_god=$(_cb "god_mode")
    local _opts=()
    [ "$_sec_root" = "1" ] && _opts+=(1); [ "$_sec_safe" = "1" ] && _opts+=(2); [ "$_sec_bridge" = "1" ] && _opts+=(3); [ "$_sec_browser" = "1" ] && _opts+=(4)
    [ "$_sec_tools" = "1" ] && _opts+=(5); [ "$_sec_hooks" = "1" ] && _opts+=(6); [ "$_sec_nnp" = "1" ] && _opts+=(7); [ "$_sec_auto" = "1" ] && _opts+=(8); [ "$_sec_sandbox" = "1" ] && _opts+=(9)
    [ "$_sec_paranoid" = "1" ] && _opts+=(10); [ "$_sec_offline" = "1" ] && _opts+=(11); [ "$_sec_ro" = "1" ] && _opts+=(12); [ "$_sec_god" = "1" ] && _opts+=(13)
    SEC_OPTS_DEFAULT=$(IFS=,; echo "${_opts[*]}")
    SEC_OPTS_FROM_CONFIG=1
}

SEC_OPTS_DEFAULT="1,2,3,4,6,7"
[ -f "$_CONFIG" ] && load_security_defaults_from_config "$_CONFIG"

# Convert 1-based SEC_OPTS_DEFAULT to 0-based for checklist_tui. Display order: 1=Root 2=Safe ... 8=AutoStart 9=Sandbox ... 13=God
# When SEC_ROOT_HIDDEN=true (fourplayers), Root is forced on in apply_security_settings; always include index 0 (Root) so checklist shows it checked.
# Return comma-separated 0-based indices for hooks checklist. Default: 1,2,3,4 (all 4 hooks enabled).
hooks_defaults_for_checklist() {
    local cfg="${PROJECT_DIR:-${PROJECT_ROOT:-}}/config.yaml"
    [ -n "${1:-}" ] && cfg="$1"
    [ ! -f "$cfg" ] && { echo "1,2,3,4"; return; }
    local _raw
    _raw=$(awk -v section="hooks" -v key="entries" '
        /^[a-zA-Z_][a-zA-Z0-9_]*:/ { gsub(/:.*/,""); current=$0 }
        current==section && $0~key":" { gsub(/^[^:]+:[ \t]*/,""); gsub(/[ \t#].*$/,""); gsub(/["\047]/,""); print; exit }
    ' "$cfg" 2>/dev/null)
    [ -z "$_raw" ] && { echo "1,2,3,4"; return; }
    local out=""
    local h
    for h in $(echo "$_raw" | tr ',' ' '); do
        case "$h" in
            boot-md) out="${out}1," ;;
            bootstrap-extra-files) out="${out}2," ;;
            command-logger) out="${out}3," ;;
            session-memory) out="${out}4," ;;
        esac
    done
    [ -z "$out" ] && out="1,2,3,4" || out="${out%,}"
    echo "$out"
}

sec_opts_for_checklist() {
    local def
    if [ "${SEC_OPTS_FROM_CONFIG:-0}" = "1" ]; then
        def="${SEC_OPTS_DEFAULT}"
    else
        def="${SEC_OPTS_DEFAULT:-1,2,3,4,6,7}"
    fi
    local out
    out="$(echo "$def" | tr ',' '\n' | while read -r n; do
        if [ -n "$n" ] && [ "$n" -ge 1 ] 2>/dev/null; then
            echo $((n - 1))
        fi
    done | tr '\n' ',' | sed 's/,$//')"
    if [ "${SEC_ROOT_HIDDEN:-false}" = "true" ]; then
        # fourplayers: ensure Root (0) is in the list so it shows as checked
        case ",$out," in *,0,*) ;; *) out="0${out:+,$out}" ;; esac
    fi
    echo "$out"
}
