#!/bin/bash
# --- Phase: Hatch choice, TUI, payload, cleanup, summary ---
# Requires: CONTAINER_NAME, CONTAINER_HOME, OPENCLAW_CMD, _cfg_port, _cfg_token, GATEWAY_BIND, security vars

run_phase_hatch() {
    HATCH_OPTIONS="Hatch in TUI (recommended, press CTRL+C twice to exit)
Open the Web UI
Do this later"
    select_tui "How do you want to hatch your bot?" "$HATCH_OPTIONS" "" "" "HATCH_SEL" 0 "true" 1 0

    _hatch_auth_secret="${_cfg_token}"
    _hatch_dash_url_display="http://localhost:${_cfg_port:-18789} (token redacted)"
    if [[ "${GATEWAY_AUTH_SEL:-}" == *"Password"* ]]; then
        _hatch_auth_secret="${GATEWAY_PASSWORD}"
        _hatch_dash_url_display="http://localhost:${_cfg_port:-18789} (password auth)"
    fi
    _hatch_gateway_url="ws://0.0.0.0:${_cfg_port:-18789}"
    _hatch_ws_dir="${OPENCLAW_DOCKER_WORKSPACE:-${CONTAINER_HOME:-/home/node}/.openclaw/workspace}"
    _hatch_projects_dir="${DOCKER_PROJECTS_PATH:-$_hatch_ws_dir}"
    _hatch_sessions_dir="${CONTAINER_HOME:-/home/node}/.openclaw/agents/main/sessions"
    _hatch_names=$( (cd "$PROJECT_DIR" && docker compose ps --format '{{.Name}}' 2>/dev/null) | paste -sd ' ' - | sed 's/ *$//')
    _hatch_image=$(docker inspect "$CONTAINER_NAME" --format '{{.Config.Image}}' 2>/dev/null || true)
    [ -z "$_hatch_image" ] && _hatch_image="${OPENCLAW_IMAGE:-alpine/openclaw:latest}"
    _hatch_host_note=""
    if [ "${USE_OLLAMA:-false}" = true ]; then
        if [ "${BRIDGE_ENABLED:-false}" = "true" ]; then
            _hatch_host_note="- Host access from container: use host.docker.internal\n- Ollama (host) base URL: http://host.docker.internal:11434/v1"
        else
            _hatch_host_note="- Host access is disabled (Bridge is OFF). If you need Ollama on the host, enable Bridge and re-run setup."
        fi
    fi
    _sec_on_off() { [ "${1:-false}" = "true" ] && echo "ON" || echo "OFF"; }
    [ -z "${AUTO_START:-}" ] && [ -f "$PROJECT_DIR/config.yaml" ] && AUTO_START="$(get_yaml_val "$PROJECT_DIR/config.yaml" "security.auto_start" 2>/dev/null)"
    [ -z "${GOD_MODE:-}" ] && [ -f "$PROJECT_DIR/config.yaml" ] && GOD_MODE="$(get_yaml_val "$PROJECT_DIR/config.yaml" "security.god_mode" 2>/dev/null)"
    _hatch_sec_sandbox="$(_sec_on_off "${SANDBOX_MODE:-false}")"
    _hatch_sec_root="$(_sec_on_off "${ROOT_MODE:-false}")"
    _hatch_sec_safe="$(_sec_on_off "${SAFE_MODE:-false}")"
    _hatch_sec_bridge="$(_sec_on_off "${BRIDGE_ENABLED:-false}")"
    _hatch_sec_browser="$(_sec_on_off "${BROWSER_CONTROL:-false}")"
    _hatch_sec_tools="$(_sec_on_off "${TOOLS_ELEVATED:-false}")"
    _hatch_sec_hooks="$(_sec_on_off "${HOOKS_ENABLED:-false}")"
    _hatch_sec_nnp="$(_sec_on_off "${NO_NEW_PRIVS:-false}")"
    _hatch_sec_autostart="$(_sec_on_off "${AUTO_START:-false}")"
    _hatch_sec_paranoid="$(_sec_on_off "${PARANOID_MODE:-false}")"
    _hatch_sec_offline="$(_sec_on_off "${NETWORKING_OFFLINE:-false}")"
    _hatch_sec_readonly="$(_sec_on_off "${READ_ONLY_MOUNTS:-false}")"
    _hatch_sec_god="$(_sec_on_off "${GOD_MODE:-false}")"
    _hatch_payload="$(cat <<EOF
Environment settings (permanent):
- You are running inside a Docker container on Linux.
- You DO NOT have direct access to the host (macOS) filesystem.
- Do not assume host paths like /Users/... exist inside the container.
- You DO have access to the mounted OpenClaw workspace and (if configured) projects directories (see paths below).

Runtime + networking:
- Gateway (inside container): ws://127.0.0.1:${_cfg_port:-18789}
- Gateway (bind address): ${_hatch_gateway_url}
- Dashboard (on host): ${_hatch_dash_url_display}
${_hatch_host_note}

Docker + install paths (inside container):
- Image: ${_hatch_image}
- Container: ${_hatch_names:-${CONTAINER_NAME}}
- OpenClaw config: ${CONTAINER_HOME:-/home/node}/.openclaw/openclaw.json
- Workspace dir: ${_hatch_ws_dir}
- Projects dir: ${_hatch_projects_dir}
- Sessions dir: ${_hatch_sessions_dir}

Security features enabled:
- Sandbox Mode: ${_hatch_sec_sandbox} — Limits file access to the workspace.
- Root Mode: ${_hatch_sec_root} — Runs container as root (can avoid EACCES during installs).
- Safe Mode: ${_hatch_sec_safe} — Requires manual verification for destructive actions.
- Bridge (Host Access): ${_hatch_sec_bridge} — Allows reaching host services via host.docker.internal.
- Browser Control: ${_hatch_sec_browser} — Enables browser automation tools.
- Tools Elevated: ${_hatch_sec_tools} — Enables high-privilege tools/workflows.
- Hooks: ${_hatch_sec_hooks} — Enables automation hooks/event handlers.
- No New Privileges: ${_hatch_sec_nnp} — Prevents privilege escalation.
- Auto-Start Docker: ${_hatch_sec_autostart} — Restarts container automatically after reboot.
- Paranoid Mode: ${_hatch_sec_paranoid} — Drops Linux capabilities (cap_drop ALL).
- Offline Mode: ${_hatch_sec_offline} — Disables external networking.
- Read-Only Mounts: ${_hatch_sec_readonly} — Mounts workspace/projects as read-only.
- God Mode: ${_hatch_sec_god} — Grants access to Docker socket (can control other containers).

Please respond with: done
EOF
)"
    printf -v _hatch_payload_q '%q' "$_hatch_payload"
    _hatch_send_cmd="docker exec -e OPENCLAW_BIND=\"${GATEWAY_BIND:-lan}\" -e HOME=\"${CONTAINER_HOME:-/home/node}\" -e OPENCLAW_GATEWAY_TOKEN=\"${_hatch_auth_secret}\" \"$CONTAINER_NAME\" $OPENCLAW_CMD agent --agent main --message ${_hatch_payload_q}"
    _hatch_debug_blob="Extra hatch info (sent after hatch):"$'\n'"$_hatch_payload"

    if [[ "$HATCH_SEL" == *"TUI"* ]]; then
        _tui_port="${_cfg_port:-18789}"
        _tui_url="ws://127.0.0.1:$_tui_port"
        _tui_first_msg="Wake up, my friend!"
        if [ -f "$PROJECT_DIR/.env.sensitive" ] || [ -f "$PROJECT_DIR/.env" ]; then
            _hatch_from_env=$(set -a; [ -f "$PROJECT_DIR/.env.sensitive" ] && . "$PROJECT_DIR/.env.sensitive" 2>/dev/null; [ -f "$PROJECT_DIR/.env" ] && . "$PROJECT_DIR/.env" 2>/dev/null; set +a; printf '%s' "${HATCH_INFO:-}")
            [ -n "$_hatch_from_env" ] && _tui_first_msg="$_hatch_from_env"
        fi
        if [[ "$GATEWAY_AUTH_SEL" == *"Password"* ]]; then
            _tui_cmd="docker exec -it \"$CONTAINER_NAME\" $OPENCLAW_CMD tui --url $_tui_url --password *** --message \"$_tui_first_msg\""
            _tui_auth_args=(--password "$GATEWAY_PASSWORD" --message "$_tui_first_msg")
        else
            _tui_cmd="docker exec -it \"$CONTAINER_NAME\" $OPENCLAW_CMD tui --url $_tui_url --token $_cfg_token --message \"$_tui_first_msg\""
            _tui_auth_args=(--token "${_cfg_token}" --message "$_tui_first_msg")
        fi
        print_debug_cmd "$TUI_PREFIX" "$_tui_cmd"
        header_tui "Hatching" "" "1"
        _hatch_lines=1
        printf "%b %b %s\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}" "Running hatch (TUI) in container; exit TUI to return to setup..."
        _hatch_lines=2
        tput smcup 2>/dev/null || true
        docker exec -it -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} "$CONTAINER_NAME" $OPENCLAW_CMD tui --url "$_tui_url" "${_tui_auth_args[@]}"
        tput rmcup 2>/dev/null || true
        printf "%b %b %b%s%b\n" "$TUI_PREFIX" "${GREEN}[ OK ]${RESET}" "$GREEN" "Hatch TUI finished, we are family now" "$RESET"
        _hatch_lines=$((_hatch_lines + 1))
        header_tui_collapse "Hatching" "$_hatch_lines"
        print_debug_cmd "$TUI_PREFIX" "$_hatch_debug_blob"
        printf "%b%s%b%b%b\n" "$accent_color" "$DIAMOND_EMPTY" "$accent_color" "Telling who is the boss" "$RESET"
        print_debug_cmd "$TUI_PREFIX" "docker exec -e OPENCLAW_BIND=\"${GATEWAY_BIND:-lan}\" -e HOME=\"${CONTAINER_HOME:-/home/node}\" -e OPENCLAW_GATEWAY_TOKEN=*** \"$CONTAINER_NAME\" $OPENCLAW_CMD agent --agent main --message <payload>"
        printf "%b %b %s\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}" "Sending Docker info to OpenClaw..."
        ( eval "$_hatch_send_cmd" >/dev/null 2>&1 ) &
        printf "%b %b %byes sir!%b\n" "$TUI_PREFIX" "${GREEN}[ OK ]${RESET}" "$GREEN" "$RESET"
    elif [[ "$HATCH_SEL" == *"later"* ]] || [[ "$HATCH_SEL" == *"Web UI"* ]]; then
        header_tui "Docker Hatching" "" "1"
        ask_yes_no_tui "Send Docker context to OpenClaw now?" "y" "DOCKER_HATCH_NOW" 1 0
        if [[ "$DOCKER_HATCH_NOW" == "y" ]]; then
            print_debug_cmd "$TUI_PREFIX" "docker exec -e OPENCLAW_BIND=\"${GATEWAY_BIND:-lan}\" -e HOME=\"${CONTAINER_HOME:-/home/node}\" -e OPENCLAW_GATEWAY_TOKEN=*** \"$CONTAINER_NAME\" $OPENCLAW_CMD agent --agent main --message <payload>"
            printf "%b %b %s\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}" "Sending Docker info to OpenClaw..."
            ( eval "$_hatch_send_cmd" >/dev/null 2>&1 ) &
            printf "%b %b %byes sir!%b\n" "$TUI_PREFIX" "${GREEN}[ OK ]${RESET}" "$GREEN" "$RESET"
        fi
    fi

    _cfg_dir="${OPENCLAW_CONFIG_DIR:-${OPENCLAW_CONFIG_DIR_DEFAULT:-$HOME/.openclaw}}"
    _has_bak=0
    for _bak in openclaw.json.bak openclaw.json.bak.1 openclaw.json.bak.2 openclaw.json.bak.3 openclaw.json.bak.4; do
        _f="$_cfg_dir/$_bak"
        [ -f "$_f" ] && _has_bak=1 && break
    done
    if [ "$_has_bak" -eq 1 ]; then
        printf "%b %b cleaning up the crime scene..\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}"
        _cleanup_files=()
        for _bak in openclaw.json.bak openclaw.json.bak.1 openclaw.json.bak.2 openclaw.json.bak.3 openclaw.json.bak.4; do
            _f="$_cfg_dir/$_bak"
            [ -f "$_f" ] && _cleanup_files+=("$_f")
        done
        if [ "${#_cleanup_files[@]}" -gt 0 ]; then
            if command -v trash >/dev/null 2>&1; then
                _cleanup_cmd="trash"
                for _f in "${_cleanup_files[@]}"; do _cleanup_cmd+=" $(printf '%q' "$_f")"; done
                print_debug_cmd "$TUI_PREFIX" "$_cleanup_cmd"
                trash "${_cleanup_files[@]}" 2>/dev/null || true
            else
                _cleanup_cmd="rm -f"
                for _f in "${_cleanup_files[@]}"; do _cleanup_cmd+=" $(printf '%q' "$_f")"; done
                print_debug_cmd "$TUI_PREFIX" "$_cleanup_cmd"
                rm -f "${_cleanup_files[@]}" 2>/dev/null || true
            fi
        fi
    fi

    _summary_cfg_dir="${OPENCLAW_CONFIG_DIR:-${OPENCLAW_CONFIG_DIR_DEFAULT:-$HOME/.openclaw}}"
    _summary_cfg_display="${_summary_cfg_dir/#$HOME/~}"
    _summary_states=$( (cd "$PROJECT_DIR" && docker compose ps -a --format '{{.State}}' 2>/dev/null) )
    _summary_total=$(echo "$_summary_states" | grep -c . 2>/dev/null || echo "0")
    _summary_running=$(echo "$_summary_states" | grep -c 'running' 2>/dev/null || echo "0")
    _summary_names=$( (cd "$PROJECT_DIR" && docker compose ps --format '{{.Name}}' 2>/dev/null) | paste -sd ' ' - | sed 's/ *$//')
    _summary_image=$(docker inspect "$CONTAINER_NAME" --format '{{.Config.Image}}' 2>/dev/null || true)
    [ -z "$_summary_image" ] && _summary_image="${OPENCLAW_IMAGE:-alpine/openclaw:latest}"
    CONTAINER_HOME=$( (docker exec "$CONTAINER_NAME" sh -c 'echo $HOME' 2>/dev/null || echo "/root") | tail -n 1 )
    OPENCLAW_SESSIONS="${CONTAINER_HOME}/.openclaw/agents/main/sessions"
    _ws_display="${OPENCLAW_DOCKER_WORKSPACE:-${CONTAINER_HOME:-/home/node}/.openclaw/workspace}"
    _mac_projects="${LOCAL_PROJECTS_DIR:-$PROJECTS_DIR}"
    [ -n "${_mac_projects:-}" ] && _mac_projects_display="${_mac_projects/#$HOME/~}" || _mac_projects_display="none"
    _docker_projects_display="${DOCKER_PROJECTS_PATH:-$_ws_display}"

    printf "%b%s%b%b%b\n" "$accent_color" "$DIAMOND_EMPTY" "$accent_color" "Summary" "$RESET"
    printf "%b│%b\n" "$accent_color" "$RESET"
    _dim="${dim_color:-$DIM}"
    printf "%b│%b      %b%-18s%b %s\n"      "$accent_color" "$RESET" "${_dim}" "Dashboard URL:" "$RESET" "http://localhost:${_cfg_port}/?token=${_cfg_token}"
    printf "%b│%b      %b%-18s%b %bImage:%b %s  %bContainer:%b %s  %bStatus:%b %s\n" \
        "$accent_color" "$RESET" "$_dim" "Docker:" "$RESET" "$_dim" "$RESET" "$_summary_image" \
        "$_dim" "$RESET" "${_summary_names:-—}" "$_dim" "$RESET" "running ($_summary_running/$_summary_total)"
    printf "%b│%b      %b%-18s%b %s\n"       "$accent_color" "$RESET" "${_dim}" "Gateway URL:" "$RESET" "ws://0.0.0.0:${_cfg_port}"
    _sec_raw=$(get_active_sec_summary)
    _sec_display=""
    _acc="$accent_color"
    _first=1
    while IFS= read -r -d ',' part; do
        part=$(printf '%s' "$part" | sed 's/^ *//;s/ *$//')
        [ -z "$part" ] && continue
        [ "$_first" -eq 0 ] && _sec_display+=" ${_acc}|${RESET} "
        _sec_display+="${_dim}${part}${RESET}"
        _first=0
    done <<< "${_sec_raw},"
    [ -z "$_sec_display" ] && _sec_display="${_dim}${_sec_raw}${RESET}"
    printf "%b│%b      %b%-18s%b %b%b\n"      "$accent_color" "$RESET" "${dim_color:-$DIM}" "Security:" "$RESET" "$_sec_display" "$RESET"
    printf "%b│%b\n" "$accent_color" "$RESET"
    printf "%b%s%b%b%b\n" "$accent_color" "$DIAMOND_EMPTY" "$accent_color" "Install locations" "$RESET"
    printf "%b│%b\n" "$accent_color" "$RESET"
    printf "%b│%b    %b[ %s ]%b\n" "$accent_color" "$RESET" "$BOLD" "${HOST_OS_LABEL:-macOS}" "$RESET"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Install dir:" "$RESET" "${_summary_cfg_display}"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Projects dir:" "$RESET" "${_mac_projects_display}"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Config:" "$RESET" "${PROJECT_DIR/#$HOME/~}/config.yaml"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Gateway log:" "$RESET" "${_summary_cfg_display}/logs/gateway.log"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "OpenClaw log:" "$RESET" "${_summary_cfg_display}/logs/openclaw.log"
    printf "%b│%b\n" "$accent_color" "$RESET"
    printf "%b│%b    %b[ Docker ]%b\n" "$accent_color" "$RESET" "$BOLD" "$RESET"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "OpenClaw Config:" "$RESET" "${CONTAINER_HOME:-/home/node}/.openclaw/openclaw.json"
    printf "%b│%b      %b%-18s%b %s\n"      "$accent_color" "$RESET" "${dim_color:-$DIM}" "Workspace dir:" "$RESET" "$_ws_display"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Projects dir:" "$RESET" "$_docker_projects_display"
    printf "%b│%b      %b%-18s%b %s\n"      "$accent_color" "$RESET" "${dim_color:-$DIM}" "Sessions dir:" "$RESET" "$OPENCLAW_SESSIONS"
    printf "%b│%b\n" "$accent_color" "$RESET"
    _oc_cmd="${OPENCLAW_CMD:-node dist/index.js}"
    header_tui "Useful Commands" "" "1"
    printf "%b│%b\n" "$accent_color" "$RESET"
    printf "%b│%b    %b[ Docker Management ]%b\n" "$accent_color" "$RESET" "$BOLD" "$RESET"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Gateway logs:" "$RESET" "docker compose logs -f $GATEWAY_SERVICE"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "CLI (exec):" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd <command>"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Start/Stop/Restart:" "$RESET" "docker compose start | docker compose stop | docker compose restart"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Update:" "$RESET" "docker compose pull && docker compose up -d"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Shell:" "$RESET" "docker compose exec -it $GATEWAY_SERVICE sh"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Stats:" "$RESET" "docker stats \$(docker compose ps -q $GATEWAY_SERVICE)"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Container OS:" "$RESET" "docker compose exec $GATEWAY_SERVICE cat /etc/os-release"
    [ "${MIRROR_PROJECTS:-false}" = "true" ] && [ -n "${DOCKER_PROJECTS_PATH:-}" ] && printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Projects mount:" "$RESET" "docker compose exec $GATEWAY_SERVICE ls -la ${DOCKER_PROJECTS_PATH}"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Shell (-p):" "$RESET" "docker compose -p project_name exec -it $GATEWAY_SERVICE sh"
    printf "%b│%b\n" "$accent_color" "$RESET"
    printf "%b│%b    %b[ Gateway ]%b\n" "$accent_color" "$RESET" "$BOLD" "$RESET"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "TUI (chat):" "$RESET" "docker compose exec -it $GATEWAY_SERVICE $_oc_cmd tui"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Bash shell:" "$RESET" "docker compose exec -it $GATEWAY_SERVICE bash"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Help:" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd --help"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Gateway stop:" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd gateway stop"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Audit Deep:" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd security audit --deep"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Audit Fix:" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd security audit --fix"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Sync Skills:" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd skill sync"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Scan Models:" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd model scan"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Environment:" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd env"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Status:" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd status --all"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Version:" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd --version"
    printf "%b│%b\n" "$accent_color" "$RESET"
    printf "%b│%b    %b[ Gateway Config ]%b\n" "$accent_color" "$RESET" "$BOLD" "$RESET"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Config get:" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd config get <key>"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Config set:" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd config set <key> <value>"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Config unset:" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd config unset <key>"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "config.get:" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd gateway call config.get --params '{}'"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "config.apply:" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd gateway call config.apply --params '<raw> <baseHash>'"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "config.patch:" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd gateway call config.patch --params '<raw> <baseHash>'"
    printf "%b│%b      %b%-18s%b %s\n" "$accent_color" "$RESET" "${dim_color:-$DIM}" "Doctor:" "$RESET" "docker compose exec $GATEWAY_SERVICE $_oc_cmd doctor"
    printf "%b│%b\n" "$accent_color" "$RESET"

    ywizz_head_left_smoke_exit
    printf "%b%s%b\n" "$accent_color" "Installation succeeded. Use the dashboard link above to control OpenClaw." "$RESET"
}
