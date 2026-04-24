#!/bin/bash
# --- Phase: Config set, permissions, LLM smoke test ---
# Requires: CONTAINER_NAME, CONTAINER_HOME, OPENCLAW_CMD, MODEL_*, FALLBACK_*_ARR, GATEWAY_TOKEN, etc.

run_phase_config() {
    _cfg_mode="${GATEWAY_TYPE:-local}"
    _cfg_bind="${GATEWAY_BIND:-lan}"
    _cfg_port="${OPENCLAW_GATEWAY_PORT:-18789}"
    _cfg_token="${GATEWAY_TOKEN}"
    _cfg_tailscale="${TAILSCALE_EXP:-off}"

    _primary="${MODEL_GENERAL:-}"
    [ -z "$_primary" ] && _primary="${MODEL_LITE:-}"
    [ -z "$_primary" ] && _primary="${MODEL_HEAVY:-}"
    if [ -z "$_primary" ]; then
        [ "$USE_OLLAMA" = true ] && _primary="ollama/glm-4.7-flash" || _primary="zai/glm-4.7-flash"
    fi
    _fallbacks=()
    [ "$FALLBACKS_SETUP" = true ] && _fallbacks+=("${FALLBACK_GENERAL_ARR[@]}" "${FALLBACK_LITE_ARR[@]}" "${FALLBACK_HEAVY_ARR[@]}")
    _fallbacks_json="[]"
    if [ ${#_fallbacks[@]} -gt 0 ]; then
        _fallbacks_json="[$(printf '"%s",' "${_fallbacks[@]}" | sed 's/,$//')]"
    fi

    _primary_general="${MODEL_GENERAL:-$_primary}"
    _primary_heavy="${MODEL_HEAVY:-$_primary}"
    _primary_light="${MODEL_LITE:-$_primary}"
    _fb_general="[]"
    _fb_heavy="[]"
    _fb_light="[]"
    [ ${#FALLBACK_GENERAL_ARR[@]} -gt 0 ] && _fb_general="[$(printf '"%s",' "${FALLBACK_GENERAL_ARR[@]}" | sed 's/,$//')]"
    [ ${#FALLBACK_HEAVY_ARR[@]} -gt 0 ] && _fb_heavy="[$(printf '"%s",' "${FALLBACK_HEAVY_ARR[@]}" | sed 's/,$//')]"
    [ ${#FALLBACK_LITE_ARR[@]} -gt 0 ] && _fb_light="[$(printf '"%s",' "${FALLBACK_LITE_ARR[@]}" | sed 's/,$//')]"

    _tmp_agents=""
    _tmp_ollama=""
    if [ "$USE_OLLAMA" = true ]; then
        _ollama_ids=()
        for m in "$MODEL_GENERAL" "$MODEL_LITE" "$MODEL_HEAVY" "${FALLBACK_GENERAL_ARR[@]}" "${FALLBACK_LITE_ARR[@]}" "${FALLBACK_HEAVY_ARR[@]}"; do
            [ -z "$m" ] && continue
            [[ "$m" != ollama/* ]] && continue
            _name="${m#ollama/}"
            [[ "$_name" == *:* ]] || _name="${_name}:latest"
            _seen=""
            for o in "${_ollama_ids[@]}"; do [ "$o" = "$_name" ] && _seen=1; done
            [ -z "$_seen" ] && _ollama_ids+=("$_name")
        done
        _models_json="[]"
        if [ ${#_ollama_ids[@]} -gt 0 ]; then
            _models_json="[$(for id in "${_ollama_ids[@]}"; do printf '{"id":"%s","name":"%s"},' "$id" "$id"; done | sed 's/,$//')]"
        fi
        _ollama_base="${OLLAMA_BASE_URL:-$(awk '/^ollama:/{f=1;next} f && /^  base_url:/{sub(/^[^:]+:[ \t]*/,""); sub(/[ \t#].*$/,""); print; exit} f && /^[a-z]/{exit}' "$PROJECT_DIR/config.yaml" 2>/dev/null)}"
        [ -z "$_ollama_base" ] && _ollama_base="http://host.docker.internal:11434"
        [[ "$_ollama_base" != */v1 ]] && _ollama_base="${_ollama_base%/}/v1"
        _ollama_provider="{\"api\":\"openai-completions\",\"baseUrl\":\"$_ollama_base\",\"apiKey\":\"ollama-local\",\"models\":$_models_json}"
    fi

    AGENTS_MODEL_JSON="{\"primary\":\"$_primary\",\"fallbacks\":$_fallbacks_json}"
    AGENTS_LIST_JSON='[{"id":"main","model":{"primary":"'"$_primary_general"'","fallbacks":'"$_fb_general"'}},{"id":"coding","model":{"primary":"'"$_primary_heavy"'","fallbacks":'"$_fb_heavy"'}},{"id":"chat","model":{"primary":"'"$_primary_light"'","fallbacks":'"$_fb_light"'}}]'

    _ph2_acc=$(get_accent)
    _ph2_dim_msg="${DIM}${_ph2_acc}"
    _ph2_reply_prefix="${ORANGE:-$YELLOW}[DEBUG]${RESET}"
    printf "%b%s%b%b%b\n" "$_ph2_acc" "$DIAMOND_FILLED" "$_ph2_acc" "Applying Configuration..." "$RESET"
    _ph2_lines=1
    _ph2_ok=1
    _ph2_env=(-e HOME="${CONTAINER_HOME:-/home/node}" -e OPENCLAW_BIND="${GATEWAY_BIND:-lan}")
    _ph2_dbg_log="/tmp/ph2_dbg_$$"
    { print_debug_cmd "$TUI_PREFIX" "Full command for each config step is printed below."; } 2>&1 | tee "$_ph2_dbg_log"
    _ph2_lines=$((_ph2_lines + $(wc -l < "$_ph2_dbg_log" 2>/dev/null || echo 0)))
    rm -f "$_ph2_dbg_log"
    printf "%b %b Container: %s\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}" "$CONTAINER_NAME"
    _ph2_lines=$((_ph2_lines + 1))
    printf "%b %b Env: HOME=%s OPENCLAW_BIND=%s\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}" "${CONTAINER_HOME:-/home/node}" "${GATEWAY_BIND:-lan}"
    _ph2_lines=$((_ph2_lines + 1))
    printf "%b %b %b%s%b\n" "$TUI_PREFIX" "${GREEN}[ OK ]${RESET}" "$GREEN" "Ready to configure" "$RESET"
    _ph2_lines=$((_ph2_lines + 1))
    printf "%b %b Starting subprocess...\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}"
    _ph2_lines=$((_ph2_lines + 1))
    _ph2_token_dbg="${_cfg_token:0:4}...${_cfg_token: -4}"
    [ ${#_cfg_token} -lt 12 ] && _ph2_token_dbg="***"
    _ph2_home="${CONTAINER_HOME:-/home/node}"
    if [[ "$_ph2_home" == "/root" ]]; then _ph2_u="root"; else _ph2_u="node"; fi
    [ "${ROOT_MODE:-false}" = "true" ] && _ph2_u="root" && _ph2_home="/root"
    CONTAINER_HOME="$_ph2_home"
    _ph2_logging_file="$_ph2_home/.openclaw/logs/openclaw.log"
    _ph2_trusted_json='["127.0.0.1","172.17.0.0/16","192.168.65.0/24"]'
    _ph2_trusted_display="127.0.0.1, 172.17.0.0/16, 192.168.65.0/24"
    _ph2_exec_base=(docker exec -u "$_ph2_u" -e HOME="$_ph2_home" -e OPENCLAW_BIND="${GATEWAY_BIND:-lan}" "$CONTAINER_NAME" $OPENCLAW_CMD)
    _ph2_do() {
        local _label="$1" _val="$2" _dbg="$3" _suffix="$4"; shift 4
        print_debug_cmd "$TUI_PREFIX" "$_dbg"
        local _tmp _out _rc _msg
        _tmp=$(mktemp 2>/dev/null) || _tmp="/tmp/ph2_$$_$RANDOM"
        "${@}" >"$_tmp" 2>&1; _rc=$?
        _out=$(cat "$_tmp" 2>/dev/null); rm -f "$_tmp"
        while IFS= read -r line; do
            line="${line#$'\r'}"; [ -z "$line" ] && continue
            if [[ "$line" =~ [eE][rR][rR][oO][rR] ]]; then printf "%b %b %b%s%b\n" "$TUI_PREFIX" "${RED}[ERROR]${RESET}" "$RED" "$line" "$RESET"; elif [ -n "${INSTALL_DEBUG:-}" ]; then printf "%b %b %s\n" "$TUI_PREFIX" "$_ph2_reply_prefix" "$line"; fi
        done <<< "$_out"
        [ "${_rc:-0}" -ne 0 ] && _ph2_ok=0
        if [ "${_rc:-0}" -eq 0 ]; then
            [ -n "$_val" ] && _msg="Set $_label = $_val" || _msg="Set $_label"
            if [ -n "$_suffix" ]; then
                printf "%b %b %b%s%b%b%s%b\n" "$TUI_PREFIX" "${GREEN}[ OK ]${RESET}" "$GREEN" "$_msg" "$RESET" "$_ph2_dim_msg" "$_suffix" "$RESET"
            else
                printf "%b %b %b%s%b\n" "$TUI_PREFIX" "${GREEN}[ OK ]${RESET}" "$GREEN" "$_msg" "$RESET"
            fi
            _ph2_lines=$((_ph2_lines + 1))
        fi
        return 0
    }

    printf "%b %b Setting gateway and agent config (CLI).\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}"
    _ph2_lines=$((_ph2_lines + 1))
    set +e
    _ph2_do "logging.file" "$_ph2_logging_file" "docker exec -u $_ph2_u -e HOME=$_ph2_home -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} \"$CONTAINER_NAME\" $OPENCLAW_CMD config set logging.file \"$_ph2_logging_file\"" "" "${_ph2_exec_base[@]}" config set logging.file "$_ph2_logging_file"
    _ph2_do "gateway.port" "$_cfg_port" "docker exec -u $_ph2_u -e HOME=$_ph2_home -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} \"$CONTAINER_NAME\" $OPENCLAW_CMD config set gateway.port $_cfg_port" "" "${_ph2_exec_base[@]}" config set gateway.port "$_cfg_port"
    _ph2_do "gateway.mode" "$_cfg_mode" "docker exec -u $_ph2_u -e HOME=$_ph2_home -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} \"$CONTAINER_NAME\" $OPENCLAW_CMD config set gateway.mode $_cfg_mode" "" "${_ph2_exec_base[@]}" config set gateway.mode "$_cfg_mode"
    _ph2_do "gateway.bind" "$_cfg_bind" "docker exec -u $_ph2_u -e HOME=$_ph2_home -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} \"$CONTAINER_NAME\" $OPENCLAW_CMD config set gateway.bind $_cfg_bind" "" "${_ph2_exec_base[@]}" config set gateway.bind "$_cfg_bind"
    _ph2_do "gateway.auth.token" "***" "docker exec -u $_ph2_u -e HOME=$_ph2_home -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} \"$CONTAINER_NAME\" $OPENCLAW_CMD config set gateway.auth.token ***" "" "${_ph2_exec_base[@]}" config set gateway.auth.token "$_cfg_token"
    _ph2_do "gateway.remote.token" "***" "docker exec -u $_ph2_u -e HOME=$_ph2_home -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} \"$CONTAINER_NAME\" $OPENCLAW_CMD config set gateway.remote.token ***" "" "${_ph2_exec_base[@]}" config set gateway.remote.token "$_cfg_token"
    _ph2_do "gateway.remote.url" "ws://openclaw-gateway:$_cfg_port" "docker exec -u $_ph2_u -e HOME=$_ph2_home -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} \"$CONTAINER_NAME\" $OPENCLAW_CMD config set gateway.remote.url \"ws://openclaw-gateway:$_cfg_port\"" "" "${_ph2_exec_base[@]}" config set gateway.remote.url "ws://openclaw-gateway:$_cfg_port"
    _ph2_do "gateway.tailscale.mode" "$_cfg_tailscale" "docker exec -u $_ph2_u -e HOME=$_ph2_home -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} \"$CONTAINER_NAME\" $OPENCLAW_CMD config set gateway.tailscale.mode $_cfg_tailscale" "" "${_ph2_exec_base[@]}" config set gateway.tailscale.mode "$_cfg_tailscale"
    _ph2_do "gateway.controlUi.allowInsecureAuth" "true" "docker exec -u $_ph2_u -e HOME=$_ph2_home -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} \"$CONTAINER_NAME\" $OPENCLAW_CMD config set gateway.controlUi.allowInsecureAuth true" " - only until pairing finishes!" "${_ph2_exec_base[@]}" config set gateway.controlUi.allowInsecureAuth true
    _ph2_do "gateway.trustedProxies" "$_ph2_trusted_display" "docker exec -u $_ph2_u -e HOME=$_ph2_home -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} \"$CONTAINER_NAME\" $OPENCLAW_CMD config set gateway.trustedProxies --json '[...]'" "" "${_ph2_exec_base[@]}" config set gateway.trustedProxies --json "$_ph2_trusted_json"
    _ph2_do "agents.defaults.model" "$_primary" "docker exec -u $_ph2_u -e HOME=$_ph2_home -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} \"$CONTAINER_NAME\" $OPENCLAW_CMD config set agents.defaults.model --json '...'" "" "${_ph2_exec_base[@]}" config set agents.defaults.model --json "$AGENTS_MODEL_JSON"
    _ph2_do "agents.list" "[3 agents]" "docker exec -u $_ph2_u -e HOME=$_ph2_home -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} \"$CONTAINER_NAME\" $OPENCLAW_CMD config set agents.list --json '...'" "" "${_ph2_exec_base[@]}" config set agents.list --json "$AGENTS_LIST_JSON"
    if [ "${HOOKS_ENABLED:-false}" = "true" ]; then
        _ph2_do "hooks.internal.enabled" "true" "docker exec -u $_ph2_u -e HOME=$_ph2_home -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} \"$CONTAINER_NAME\" $OPENCLAW_CMD config set hooks.internal.enabled true" "" "${_ph2_exec_base[@]}" config set hooks.internal.enabled true
    fi
    _ph2_port="${_cfg_port:-18789}"
    _ph2_ips="http://localhost:$_ph2_port"
    if [[ "${GATEWAY_BIND:-lan}" == "lan" ]] || [[ "${GATEWAY_BIND:-lan}" == "0.0.0.0" ]] || [[ "${GATEWAY_BIND:-lan}" =~ ^[0-9.]+$ ]]; then
        _lan_ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || { ifconfig 2>/dev/null | awk '/inet / && !/127.0.0.1/{print $2; exit}'; })
        [ -n "$_lan_ip" ] && _ph2_ips="$_ph2_ips  http://$_lan_ip:$_ph2_port"
    fi
    printf "%b %b %b%s%b\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}" "$CYAN" "Dashboard: $_ph2_ips" "$RESET"
    _ph2_lines=$((_ph2_lines + 1))
    set -e

    if [ "$USE_OLLAMA" = true ] && [ -n "$_ollama_provider" ]; then
        _ph2_lines=$((_ph2_lines + 1))
        printf "%b %b Setting models.providers.ollama to %s.\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}" "$_ollama_base"
        _ph2_ollama_log="/tmp/ph2_ollama_$$"
        set +e
        _ph2_ollama_dbg="docker exec -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} \"$CONTAINER_NAME\" $OPENCLAW_CMD config set models.providers.ollama --json \"$_ollama_provider\""
        { print_debug_cmd "$TUI_PREFIX" "$_ph2_ollama_dbg"; } 2>&1 | tee "$_ph2_ollama_log"
        docker exec -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} "$CONTAINER_NAME" $OPENCLAW_CMD config set models.providers.ollama --json "$_ollama_provider" 2>&1 | tee -a "$_ph2_ollama_log" | while read -r line; do line="${line#$'\r'}"; [[ "$line" =~ ^[✔✓x](.*) ]] && line="${BASH_REMATCH[1]}"; [ -z "$line" ] && continue; if [[ "$line" = *"Failed to discover Ollama"* ]]; then printf "%b %b %b%s%b\n" "$TUI_PREFIX" "${RED}[ERROR]${RESET}" "$RED" "$line" "$RESET"; elif [[ "$line" =~ [eE][rR][rR][oO][rR] ]]; then printf "%b %b %b%s%b\n" "$TUI_PREFIX" "${RED}[ERROR]${RESET}" "$RED" "$line" "$RESET"; elif [ -n "${INSTALL_DEBUG:-}" ]; then if [[ "$line" = *Updated* ]]; then printf "%b %b %b%s%b\n" "$TUI_PREFIX" "$_ph2_reply_prefix" "$_ph2_dim_msg" "$line" "$RESET"; else printf "%b %b %s\n" "$TUI_PREFIX" "$_ph2_reply_prefix" "$line"; fi; fi; done
        _ollama_rc="${PIPESTATUS[0]}"
        set -e
        if [ "${_ollama_rc:-0}" -ne 0 ]; then _ph2_ok=0; fi
        if grep -qiE 'failed to discover ollama|[eE][rR][rR][oO][rR]' "$_ph2_ollama_log" 2>/dev/null; then _ph2_ok=0; fi
        if grep -qiE 'is not running|Error response from daemon|Cannot find module|MODULE_NOT_FOUND' "$_ph2_ollama_log" 2>/dev/null; then
            rm -f "$_ph2_ollama_log"
            fail_install "Configuration failed (container not running or OpenClaw CLI broken). Check output above. Fix and re-run installer."
        fi
        _ph2_lines=$((_ph2_lines + $(wc -l < "$_ph2_ollama_log" 2>/dev/null || echo 0)))
        rm -f "$_ph2_ollama_log"
    fi

    _ph2_lines=$((_ph2_lines + 1))
    if [ "${_ph2_ok:-1}" -eq 1 ]; then
        printf "%b %b All gateway settings applied successfully\n" "$TUI_PREFIX" "${GREEN}[ OK ]${RESET}"
    else
        printf "%b %b %b%s%b\n" "$TUI_PREFIX" "${RED}[ERROR]${RESET}" "$RED" "Failed to apply one or more gateway settings" "$RESET"
        fail_install "Gateway configuration failed. Check the output above for errors (e.g. container not running, missing module). Fix the issue and re-run the installer."
    fi
    _ph2_lines=$((_ph2_lines + 2))
    printf "%b %b Securing state directory permissions..\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}"
    _ph2_perms_log="/tmp/ph2_perms_$$"
    _ph2_home="${CONTAINER_HOME:-/home/node}"
    _ph2_state_dir="$_ph2_home/.openclaw"
    _ph2_log_dir="$_ph2_state_dir/logs"
    _ph2_log_file="$_ph2_log_dir/openclaw.log"
    _ph2_owner_user="node"
    _ph2_owner_group="node"
    if [ "$_ph2_home" = "/root" ]; then
        _ph2_owner_user="root"
        _ph2_owner_group="root"
    fi
    _ph2_perms_run=(docker exec -u 0 "$CONTAINER_NAME")
    _ph2_perms_check() {
        [ -z "${INSTALL_DEBUG:-}" ] && return 0
        local label="$1"
        printf "%b %b %s\n" "$TUI_PREFIX" "$_ph2_reply_prefix" "$label"
        _ph2_lines=$((_ph2_lines + 1))
        "${_ph2_perms_run[@]}" /bin/sh -c '
            show_one() {
                p="$1"
                [ -e "$p" ] || return 0
                if stat -c "%a %U %G" "$p" >/dev/null 2>&1; then
                    set -- $(stat -c "%a %U %G" "$p" 2>/dev/null)
                    printf "%s mode=%s owner=%s:%s\n" "$p" "$1" "$2" "$3"
                    return 0
                fi
                out=$(ls -ld "$p" 2>/dev/null) || return 0
                perms=$(printf "%s" "$out" | awk "{print \$1}")
                owner=$(printf "%s" "$out" | awk "{print \$3}")
                group=$(printf "%s" "$out" | awk "{print \$4}")
                to_oct() {
                    s="$1"; s="${s#?}"
                    a=${s%????????}; b=${s#???}; b=${b%?????}; c=${s#??????}
                    val() { x="$1"; n=0; [ "${x#r}" != "$x" ] && n=$((n+4)); [ "${x#?w}" != "$x" ] && n=$((n+2)); [ "${x#??x}" != "$x" ] && n=$((n+1)); printf "%s" "$n"; }
                    printf "%s%s%s" "$(val "$a")" "$(val "$b")" "$(val "$c")"
                }
                mode=$(to_oct "$perms")
                printf "%s mode=%s owner=%s:%s\n" "$p" "$mode" "$owner" "$group"
            }
            show_one "'"$_ph2_state_dir"'"
            show_one "'"$_ph2_log_dir"'"
            show_one "'"$_ph2_log_file"'"
        ' 2>/dev/null | while read -r line; do
            line="${line#$'\r'}"
            [ -z "$line" ] && continue
            printf "%b %b %s\n" "$TUI_PREFIX" "$_ph2_reply_prefix" "$line"
            _ph2_lines=$((_ph2_lines + 1))
        done
    }
    _ph2_perms_check "Permissions before fix:"
    _ph2_perms_script="mkdir -p '$_ph2_state_dir' '$_ph2_log_dir' && chown '$_ph2_owner_user:$_ph2_owner_group' '$_ph2_state_dir' '$_ph2_log_dir' 2>/dev/null || true; chmod 700 '$_ph2_state_dir' '$_ph2_log_dir' 2>/dev/null || true; chmod 600 '$_ph2_log_file' 2>/dev/null || true"
    _ph2_perms_cmd="docker exec -u 0 \"$CONTAINER_NAME\" /bin/sh -c \"$_ph2_perms_script\""
    { print_debug_cmd "$TUI_PREFIX" "$_ph2_perms_cmd"; } 2>&1 | tee "$_ph2_perms_log"
    "${_ph2_perms_run[@]}" /bin/sh -c "$_ph2_perms_script" 2>&1 | tee -a "$_ph2_perms_log" | while read -r line; do
        line="${line#$'\r'}"
        [ -z "$line" ] && continue
        if [[ "$line" =~ [eE][rR][rR][oO][rR] ]]; then
            printf "%b %b %b%s%b\n" "$TUI_PREFIX" "${RED}[ERROR]${RESET}" "$RED" "$line" "$RESET"
        else
            printf "%b %b %s\n" "$TUI_PREFIX" "$_ph2_reply_prefix" "$line"
        fi
    done
    _ph2_lines=$((_ph2_lines + $(wc -l < "$_ph2_perms_log" 2>/dev/null || echo 0)))
    if grep -qiE 'is not running|Error response from daemon|Cannot find module|MODULE_NOT_FOUND' "$_ph2_perms_log" 2>/dev/null; then
        rm -f "$_ph2_perms_log"
        fail_install "Configuration failed (container not running or OpenClaw CLI broken). Check output above. Fix and re-run installer."
    fi
    rm -f "$_ph2_perms_log"
    _ph2_perms_check "Permissions after fix:"
    printf "\033[${_ph2_lines}A\r\033[K"
    printf "%b%s%b%b%b\033[K\n" "$_ph2_acc" "$DIAMOND_EMPTY" "$_ph2_acc" "Applying Configuration..." "$RESET"
    printf "\033[$(($_ph2_lines - 1))B"

    _ph3_acc=$(get_accent)
    printf "%b%s%b%b%b\n" "$_ph3_acc" "$DIAMOND_FILLED" "$_ph3_acc" "LLM smoke test" "$RESET"
    _ph3_lines=1
    _agents_script='var s=require("fs").readFileSync(0,"utf8"); var d; try{d=JSON.parse(s);}catch(e){process.exit(0);} if(!Array.isArray(d))process.exit(0); d.forEach(function(a){var m=a.model||{}; var p=typeof m==="string"?m:(m.primary||"?"); var fb=""; if(m&&m.fallbacks&&m.fallbacks.length)fb=" (+ "+m.fallbacks.join(", ")+")"; console.log(a.id+": "+p+fb);});'
    _ph3_agents_log="/tmp/ph3_agents_$$"
    if command -v node >/dev/null 2>&1; then
        printf '%s' "$AGENTS_LIST_JSON" | node -e "$_agents_script" 2>/dev/null | tee "$_ph3_agents_log" | while read -r line; do printf "%b %b %b%s%b\n" "$TUI_PREFIX" "${GREEN}[ OK ]${RESET}" "$GREEN" "$line" "$RESET"; done
    else
        docker exec -e HOME="${CONTAINER_HOME:-/home/node}" -e OPENCLAW_BIND="${GATEWAY_BIND:-lan}" "$CONTAINER_NAME" sh -c "$OPENCLAW_CMD config get agents.list 2>/dev/null | node -e \"$_agents_script\"" 2>/dev/null | tee "$_ph3_agents_log" | while read -r line; do printf "%b %b %b%s%b\n" "$TUI_PREFIX" "${GREEN}[ OK ]${RESET}" "$GREEN" "$line" "$RESET"; done
    fi
    _ph3_lines=$((_ph3_lines + $(wc -l < "$_ph3_agents_log" 2>/dev/null || echo 0)))
    rm -f "$_ph3_agents_log"
    printf "\033[${_ph3_lines}A\r\033[K"
    printf "%b%s%b%b%b\033[K\n" "$_ph3_acc" "$DIAMOND_EMPTY" "$_ph3_acc" "LLM smoke test" "$RESET"
    printf "\033[$(($_ph3_lines - 1))B"
}
