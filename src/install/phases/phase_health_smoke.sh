#!/bin/bash
# --- Phase: Health check, final health question, onboard wizard, optional smoke ---
# Requires: CONTAINER_NAME, CONTAINER_HOME, OPENCLAW_CMD, _cfg_port, _cfg_token, _cfg_bind, _cfg_tailscale (from phase_config)

run_phase_health_smoke() {
    if [ -n "${_cfg_token:-}" ]; then
        printf "%b %b Syncing gateway.remote.token before health check...\n" "$TUI_PREFIX" "${CYAN}[INFO]${RESET}"
        docker exec -e HOME="${CONTAINER_HOME:-/home/node}" "$CONTAINER_NAME" $OPENCLAW_CMD config set gateway.remote.token "$_cfg_token" >/dev/null 2>&1 || true
    fi
    HEALTH_CMD="$OPENCLAW_CMD health"
    run_setup_phase "Checking Health" "$HEALTH_CMD"
    success "Health check passed! Clawfather is ready."
    docker exec -e HOME="${CONTAINER_HOME:-/home/node}" "$CONTAINER_NAME" $OPENCLAW_CMD config set gateway.remote.url "ws://openclaw-gateway:${_cfg_port}" >/dev/null 2>&1 || true

    while read -r -t 0 2>/dev/null; do read -r -n 1 discard; done

    ask_yes_no_tui "Setup complete. Dashboard health status OK?" "y" "FINAL_HEALTH" 1 0
    if [[ "$FINAL_HEALTH" == "n" ]]; then
        warn "Setup completed with reported health issues. Check logs."
    fi

    _ob_acc=$(get_accent)
    _ob_prompt="Run OpenClaw onboard wizard now?  ${_ob_acc}${DIM}setup: additional models, channels..${RESET}"
    ask_yes_no_tui "$_ob_prompt" "n" "RUN_ONBOARD" 1 0 1
    if [[ "$RUN_ONBOARD" =~ ^[Yy]$ ]]; then
        _ob_port="${_cfg_port:-18789}"
        _ob_bind="${_cfg_bind:-lan}"
        _ob_auth="token"
        _ob_secret_arg="--gateway-token"
        _ob_secret_val="${_cfg_token}"
        if [[ "$GATEWAY_AUTH_SEL" == *"Password"* ]]; then
            _ob_auth="password"
            _ob_secret_arg="--gateway-password"
            _ob_secret_val="${GATEWAY_PASSWORD}"
        fi
        _ob_tailscale="${_cfg_tailscale:-off}"
        _ob_workspace="${OPENCLAW_DOCKER_WORKSPACE:-~/.openclaw/workspace}"
        _ob_extra=()
        [ -n "${ANTHROPIC_API_KEY:-}" ] && _ob_extra+=(--anthropic-api-key "$ANTHROPIC_API_KEY")
        [ -n "${GEMINI_API_KEY:-}" ] && _ob_extra+=(--gemini-api-key "$GEMINI_API_KEY")
        [ -n "${ZAI_API_KEY:-}" ] && _ob_extra+=(--zai-api-key "$ZAI_API_KEY")
        _ob_cmd="docker exec -it \"$CONTAINER_NAME\" $OPENCLAW_CMD onboard --flow quickstart --mode local --gateway-port $_ob_port --gateway-bind $_ob_bind --gateway-auth $_ob_auth $_ob_secret_arg $_ob_secret_val --no-install-daemon --skip-health --tailscale $_ob_tailscale --workspace $_ob_workspace ${_ob_extra[*]}"
        print_debug_cmd "$TUI_PREFIX" "$_ob_cmd"
        info "Running onboard wizard in container (params prefilled from install)..."
        set +e
        docker exec -it "$CONTAINER_NAME" $OPENCLAW_CMD onboard \
            --flow quickstart --mode local \
            --gateway-port "$_ob_port" --gateway-bind "$_ob_bind" --gateway-auth "$_ob_auth" \
            "$_ob_secret_arg" "$_ob_secret_val" \
            --no-install-daemon --skip-health \
            --tailscale "$_ob_tailscale" \
            --workspace "$_ob_workspace" \
            "${_ob_extra[@]}"
        _ob_rc=$?
        set -e
        tput rmcup 2>/dev/null || true
        stty sane 2>/dev/null || true
        while read -t 0.01 -r -n 10000 discard; do :; done 2>/dev/null || true
        acc=$(get_accent)
        printf "%b%s%b%b%b\n" "$acc" "$DIAMOND_EMPTY" "$acc" "Back to Clawfather" "$RESET"
        printf "%b│%b\n" "$accent_color" "$RESET"
        printf "%b│%b  %s\n" "$accent_color" "$RESET" "Onboarding finished. Use the dashboard to control OpenClaw:"
        printf "%b│%b  %bhttp://localhost:${_cfg_port:-18789}/?token=${_cfg_token}%b\n" "$accent_color" "$RESET" "$BOLD" "$RESET"
        printf "%b│%b  %s\n" "$accent_color" "$RESET" "Logs: docker compose logs -f $GATEWAY_SERVICE   |   Shell: docker compose exec -it $GATEWAY_SERVICE sh"
        printf "%b│%b\n" "$accent_color" "$RESET"
        sleep 2
        SMOKE_CMD="$OPENCLAW_CMD agent --agent main --timeout 240 --message \"Reply with 'We are good bro', nothing else\""
        run_setup_phase "Smoke test: OpenClaw reply with OK" "$SMOKE_CMD" 250
    fi

    _upd_acc=$(get_accent)
    _upd_prompt="Update OpenClaw now?  ${_upd_acc}${DIM}openclaw update in container${RESET}"
    ask_yes_no_tui "$_upd_prompt" "n" "RUN_OPENCLAW_UPDATE" 1 0 1
    if [[ "$RUN_OPENCLAW_UPDATE" =~ ^[Yy]$ ]]; then
        _upd_cmd="docker exec -e HOME=\"${CONTAINER_HOME:-/home/node}\" -e OPENCLAW_BIND=\"${GATEWAY_BIND:-lan}\" \"$CONTAINER_NAME\" $OPENCLAW_CMD update"
        print_debug_cmd "$TUI_PREFIX" "$_upd_cmd"
        info "Running openclaw update in container..."
        set +e
        docker exec -e HOME="${CONTAINER_HOME:-/home/node}" -e OPENCLAW_BIND="${GATEWAY_BIND:-lan}" "$CONTAINER_NAME" $OPENCLAW_CMD update
        _upd_rc=$?
        set -e
        if [ "${_upd_rc:-0}" -eq 0 ]; then
            success "OpenClaw update completed."
        else
            warn "OpenClaw update exited with code ${_upd_rc}. Check output above."
        fi
    fi
}
