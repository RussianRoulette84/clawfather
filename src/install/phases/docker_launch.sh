#!/bin/bash
# --- Docker launch: Compose env, pull/up, CONTAINER_*, OPENCLAW_CMD, Phase 1 (Initial Setup) ---
# Requires: setup_phase_runner.sh sourced first; pre_docker already run (PROJECT_DIR, TUI_PREFIX, etc.)

run_docker_launch() {
    cd "$PROJECT_DIR" || exit 1
    ensure_docker_running || exit 1

    [ -f "$PROJECT_DIR/.env" ] && set -a && . "$PROJECT_DIR/.env" && set +a

    export COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
    export COMPOSE_PROJECT_NAME="$(get_compose_project_name "${OPENCLAW_CONFIG_DIR:-${OPENCLAW_CONFIG_DIR_DEFAULT:-$HOME/.openclaw}}")"
    TUI_PREFIX="$(printf "%b" "${accent_color}${TREE_MID}${RESET}")"

    _acc=$(get_accent)
    printf "%b%s%b%b%b\n" "$_acc" "$DIAMOND_FILLED" "$_acc" "Starting docker" "$RESET"
    _docker_lines=1

    FALLBACK_GENERAL_ARR=()
    FALLBACK_LITE_ARR=()
    FALLBACK_HEAVY_ARR=()
    _cfg="${PROJECT_DIR}/config.yaml"
    if [ -f "$_cfg" ]; then
        _get_primary() { awk -v a="$1" '$0 ~ "^    " a ":" {f=1;next} f && /^      primary:/ {gsub(/^[^:]+:[ \t]*/,""); gsub(/[ \t#].*$/,""); print; exit} f && /^    [a-z]+:/ {exit}' "$_cfg"; }
        _get_fb_all() { awk -v a="$1" '$0 ~ "^    " a ":" {f=1;next} f && /^        - / {gsub(/^[ \t-]+/,""); gsub(/[ \t#].*$/,""); print} f && /^    [a-z]+:/ {exit}' "$_cfg"; }
        _g="$(_get_primary general)"; [ -n "$_g" ] && MODEL_GENERAL="$_g"
        _l="$(_get_primary light)"; [ -n "$_l" ] && MODEL_LITE="$_l"
        _h="$(_get_primary heavy)"; [ -n "$_h" ] && MODEL_HEAVY="$_h"
        while IFS= read -r _line; do [ -n "$_line" ] && FALLBACK_GENERAL_ARR+=("$_line"); done < <(_get_fb_all general)
        while IFS= read -r _line; do [ -n "$_line" ] && FALLBACK_LITE_ARR+=("$_line"); done < <(_get_fb_all light)
        while IFS= read -r _line; do [ -n "$_line" ] && FALLBACK_HEAVY_ARR+=("$_line"); done < <(_get_fb_all heavy)
        [ ${#FALLBACK_GENERAL_ARR[@]} -gt 0 ] || [ ${#FALLBACK_LITE_ARR[@]} -gt 0 ] || [ ${#FALLBACK_HEAVY_ARR[@]} -gt 0 ] && FALLBACKS_SETUP=true
    fi
    [ ${#FALLBACK_GENERAL_ARR[@]} -eq 0 ] && [ -n "${FALLBACK_GENERAL:-}" ] && FALLBACK_GENERAL_ARR=("$FALLBACK_GENERAL")
    [ ${#FALLBACK_LITE_ARR[@]} -eq 0 ] && [ -n "${FALLBACK_LITE:-}" ] && FALLBACK_LITE_ARR=("$FALLBACK_LITE")
    [ ${#FALLBACK_HEAVY_ARR[@]} -eq 0 ] && [ -n "${FALLBACK_HEAVY:-}" ] && FALLBACK_HEAVY_ARR=("$FALLBACK_HEAVY")

    [ -n "${INSTALL_DEBUG:-}" ] && _docker_lines=$((_docker_lines + 1)) && printf "%b %b %s\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}" "Launching containers (gateway + openclaw-cli)..." >&2
    _existing_q="$(docker compose ps -a -q 2>/dev/null)" || true
    if [ -n "$_existing_q" ]; then
        _existing_names="$(docker compose ps -a --format '{{.Name}}' 2>/dev/null | paste -sd ', ' - | sed 's/, *$//')" || true
        _docker_lines=$((_docker_lines + 1))
        printf "%b %b Stopping existing containers (%s)...\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}" "${_existing_names:-same project}" >&2
        _down_log="/tmp/docker_down_$$"
        if [ -n "${INSTALL_DEBUG:-}" ]; then
            docker compose down --remove-orphans 2>&1 | tee "$_down_log" | while IFS= read -r _line; do
                printf "%b %b %b%s%b\n" "$TUI_PREFIX" "${DIM}" "$_line" "$RESET" >&2
            done
        else
            docker compose down --remove-orphans </dev/null 2>&1 | tee "$_down_log" >/dev/null
            printf "%b %b %b%s%b\n" "$TUI_PREFIX" "${GREEN}[ OK ]${RESET}" "$GREEN" "Containers stopped." "$RESET" >&2
            _docker_lines=$((_docker_lines + 1))
        fi
        _docker_lines=$((_docker_lines + $(wc -l < "$_down_log" 2>/dev/null || echo 0)))
        rm -f "$_down_log"
    fi
    [ -n "${INSTALL_DEBUG:-}" ] && _docker_lines=$((_docker_lines + 1)) && printf "%b %b %s\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}" "Pulling images out of water..." >&2

    if [ "$USE_OLLAMA" = true ]; then
        LOCAL_VERIFY=()
        for m in "$MODEL_GENERAL" "$MODEL_LITE" "$MODEL_HEAVY" "${FALLBACK_GENERAL_ARR[@]}" "${FALLBACK_LITE_ARR[@]}" "${FALLBACK_HEAVY_ARR[@]}"; do
            [ -z "$m" ] && continue
            [[ "$m" != ollama/* ]] && continue
            LOCAL_VERIFY+=("$m")
        done
        [ ${#LOCAL_VERIFY[@]} -gt 0 ] && verify_local_models_health "${LOCAL_VERIFY[@]}" || verify_model_health
    fi

    _docker_done=0
    _pull_attempt=1
    _pull_max=3
    _pull_log="/tmp/docker_pull_$$"
    while true; do
        if [ -n "${INSTALL_DEBUG:-}" ]; then
            script -q "$_pull_log" sh -c 'docker compose pull 2>&1'
            _pull_rc=$?
        else
            run_with_progress_bar "Pulling images..." "docker compose pull -q 2>&1" ""
            _pull_rc=$?
        fi
        if [ "$_pull_rc" -eq 0 ]; then
            _docker_done=1
            if [ -n "${INSTALL_DEBUG:-}" ]; then
                _docker_lines=$((_docker_lines + $(wc -l < "$_pull_log" 2>/dev/null || echo 0)))
                [ -s "$_pull_log" ] && [ "$(tail -c 1 "$_pull_log" 2>/dev/null)" != $'\n' ] && _docker_lines=$((_docker_lines + 1))
            fi
            _docker_lines=$((_docker_lines + 1))
            printf "%b %b %b%s%b\n" "$TUI_PREFIX" "${GREEN}[ OK ]${RESET}" "$GREEN" "Images pulled" "$RESET" >&2
            [ -n "${INSTALL_DEBUG:-}" ] && _docker_lines=$((_docker_lines + 1)) && printf "%b %b %s\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}" "Starting torture containers..." >&2
            rm -f "$_pull_log"
            break
        fi
        rm -f "$_pull_log"
        if [ "$_pull_attempt" -ge "$_pull_max" ]; then
            fail_install "Pull failed after $_pull_max attempts (Docker Hub timeout?). Try: docker login; docker compose pull"
        fi
        _pull_attempt=$((_pull_attempt + 1))
        _docker_lines=$((_docker_lines + 1))
        warn "Pull failed (attempt $_pull_attempt/$_pull_max). Retrying in 15s..."
        sleep 15
    done
    _up_log="/tmp/docker_up_$$"
    set +e
    if [ -n "${INSTALL_DEBUG:-}" ]; then
        docker compose up -d 2>&1 | tee "$_up_log" | while IFS= read -r _line; do
            printf "%b %b %b%s%b\n" "$TUI_PREFIX" "${DIM}" "$_line" "$RESET" >&2
        done
        _up_rc=${PIPESTATUS[0]}
    else
        run_with_progress_bar "Starting containers..." "docker compose up -d 2>&1" ""
        _up_rc=$?
    fi
    set -e
    if [ -n "${INSTALL_DEBUG:-}" ]; then
        _docker_lines=$((_docker_lines + $(wc -l < "$_up_log" 2>/dev/null || echo 0)))
        [ -s "$_up_log" ] && [ "$(tail -c 1 "$_up_log" 2>/dev/null)" != $'\n' ] && _docker_lines=$((_docker_lines + 1))
    fi
    rm -f "$_up_log"
    if [ "${_up_rc:-0}" -ne 0 ]; then
        fail_install "Docker compose up failed. Check: docker compose logs"
    fi

    CONTAINER_NAME=$(docker compose ps -q "$GATEWAY_SERVICE" 2>/dev/null || true)
    CONTAINER_NAME="${CONTAINER_NAME%%$'\n'*}"
    CONTAINER_HOME=""
    USE_CLI_RUN=""
    CLI_RUN_SUBCMD_ONLY=""
    CLI_RUN_ENTRYPOINT=()
    CLI_RUN_SHELL_ENTRYPOINT=()
    [ -n "$CONTAINER_NAME" ] && CONTAINER_HOME=$(docker exec "$CONTAINER_NAME" sh -c 'echo $HOME' 2>/dev/null | tail -n 1)
    CONTAINER_HOME="${CONTAINER_HOME:-/home/node}"

    if docker compose ps | grep -q "Up"; then
        # Copy skills into gateway container (no bind mount)
        _skills_src="${OPENCLAW_SKILLS_DIR:-./skills}"
        [[ "$_skills_src" == ~* ]] && _skills_src="${_skills_src/#\~/$HOME}"
        [[ "$_skills_src" != /* ]] && _skills_src="$PROJECT_DIR/$_skills_src"
        _skills_dest="${OPENCLAW_DOCKER_BASE:-/home/node/.openclaw}/"
        if [ -d "$_skills_src" ]; then
            docker compose cp "$_skills_src" "$GATEWAY_SERVICE:$_skills_dest" 2>/dev/null || true
        fi

        _docker_lines=$((_docker_lines + 1))
        success "CLAWFATHER executed Docker! 🔫"
        printf "\033[${_docker_lines}A\r\033[K"
        printf "%b%s%b%b%b\033[K\n" "$_acc" "$DIAMOND_EMPTY" "$_acc" "Starting docker" "$RESET"
        printf "\033[$(($_docker_lines - 1))B"

        printf "%b%s%b%b%b\n" "$_acc" "$DIAMOND_FILLED" "$_acc" "Initializing OpenClaw..." "$RESET"

        _wait=0
        while [ "$_wait" -lt 30 ]; do
            _status=$(docker inspect "$CONTAINER_NAME" --format '{{.State.Status}}' 2>/dev/null || true)
            if [ "$_status" = "running" ]; then
                _restarts=$(docker inspect "$CONTAINER_NAME" --format '{{.RestartCount}}' 2>/dev/null || echo "0")
                [ "${_restarts:-0}" -le 1 ] && break
            fi
            sleep 1
            _wait=$((_wait + 1))
        done
        [ "$_wait" -ge 30 ] && warn "Container may still be restarting; Phase 1 might time out. Check: docker compose logs $GATEWAY_SERVICE"
        sleep 3

        _status=$(docker inspect "$CONTAINER_NAME" --format '{{.State.Status}}' 2>/dev/null || true)
        if [ "$_status" != "running" ] && [ -z "${USE_CLI_RUN:-}" ]; then
            printf "%b %b Gateway container is not running (status=%s). Using 'docker compose run openclaw-cli' for setup.\n" "$TUI_PREFIX" "${YELLOW}[WARN]${RESET}" "${_status:-unknown}"
            printf "%b %b Last lines of gateway log:\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}"
            docker compose logs --tail 20 "$GATEWAY_SERVICE" 2>/dev/null | while IFS= read -r _logline; do printf "%b %b %s\n" "$TUI_PREFIX" "$DIM" "$_logline"; done
            USE_CLI_RUN="1"
            CLI_RUN_SUBCMD_ONLY=""
            CLI_RUN_SHELL_ENTRYPOINT=("--entrypoint" "sh")
            CONTAINER_HOME=$(docker compose run --rm -T --entrypoint sh openclaw-cli -c 'echo $HOME' 2>/dev/null | tail -n 1 || true)
            CONTAINER_HOME="${CONTAINER_HOME:-/home/node}"
        fi

        case "${OPENCLAW_IMAGE:-}" in *fourplayers*)
            USE_CLI_RUN="1"
            CLI_RUN_SUBCMD_ONLY="1"
            CLI_RUN_ENTRYPOINT=("--entrypoint" "openclaw")
            CLI_RUN_SHELL_ENTRYPOINT=("--entrypoint" "sh")
            ;;
        *) ;;
        esac

        OPENCLAW_CMD="node dist/index.js"
        if [ -n "$USE_CLI_RUN" ]; then
            if [ ${#CLI_RUN_SHELL_ENTRYPOINT[@]} -gt 0 ]; then
                if docker compose run --rm -T "${CLI_RUN_SHELL_ENTRYPOINT[@]}" openclaw-cli -c 'command -v openclaw >/dev/null 2>&1 || which openclaw >/dev/null 2>&1' 2>/dev/null; then
                    OPENCLAW_CMD="openclaw"
                elif docker compose run --rm -T "${CLI_RUN_SHELL_ENTRYPOINT[@]}" openclaw-cli -c 'openclaw --version >/dev/null 2>&1' 2>/dev/null; then
                    OPENCLAW_CMD="openclaw"
                fi
            else
                if docker compose run --rm -T openclaw-cli sh -c 'command -v openclaw >/dev/null 2>&1 || which openclaw >/dev/null 2>&1' 2>/dev/null; then
                    OPENCLAW_CMD="openclaw"
                elif docker compose run --rm -T openclaw-cli sh -c 'openclaw --version >/dev/null 2>&1' 2>/dev/null; then
                    OPENCLAW_CMD="openclaw"
                fi
            fi
        else
            if docker exec "$CONTAINER_NAME" sh -c 'command -v openclaw >/dev/null 2>&1 || which openclaw >/dev/null 2>&1' 2>/dev/null; then
                OPENCLAW_CMD="openclaw"
            elif docker exec "$CONTAINER_NAME" sh -c 'openclaw --version >/dev/null 2>&1' 2>/dev/null; then
                OPENCLAW_CMD="openclaw"
            fi
        fi

        _ph1_cmd="$OPENCLAW_CMD setup"
        # For fourplayers we use docker exec (faster); exec needs full "openclaw setup"
        [ -n "${CLI_RUN_SUBCMD_ONLY:-}" ] && [ ${#CLI_RUN_ENTRYPOINT[@]} -eq 0 ] && _ph1_cmd="setup"
        run_setup_phase "Initializing OpenClaw..." "$_ph1_cmd" 120 "skip_header"
    else
        fail_install "Container failed to start. Check logs: docker compose logs $GATEWAY_SERVICE"
    fi
}
