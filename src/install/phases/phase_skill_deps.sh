#!/bin/bash
# --- Phase: Checklist, install skill dependencies (npm in container only) + hooks ---
# fourplayers image: npm only. No brew, no go.
# Requires: CONTAINER_NAME, TUI_PREFIX

run_phase_skill_deps() {
    select_tui "Package manager" "npm
bun" "" "" "PM_SEL" 0 "true" 1 0
    _pm="${PM_SEL:-npm}"

    SKILL_DEPS_OPTIONS="Skip for now
🔐 1password
📰 blogwatcher
🫐 blucli
📸 camsnap
🧩 clawhub
🎛️ eightctl
♊️ gemini
🧲 gifgrep
🎮 gog
📍 goplaces
📧 himalaya
📦 mcporter
🍌 nano-banana-pro
📄 nano-pdf
💎 obsidian
🎙️ openai-whisper
💡 openhue
🧿 oracle
🛵 ordercli
🗣️ sag
🌊 songsee
🔊 sonoscli
🧾 summarize
📱 wacli"
    SKILL_DEPS_DESC="
Set up and use 1Password CLI (op). Use when installing the CLI, enabling desktop app integration.
Monitor blogs and RSS/Atom feeds for updates using the blogwatcher CLI.
BluOS CLI (blu) for discovery, playback, grouping, and volume.
Capture frames or clips from RTSP/ONVIF cameras.
Use the ClawHub CLI to search, install, update, and publish agent skills from clawhub.com.
Control Eight Sleep pods (status, temperature, alarms, schedules).
Gemini CLI for one-shot Q&A, summaries, and generation.
Search GIF providers with CLI/TUI, download results, and extract stills/sheets.
Google Workspace CLI for Gmail, Calendar, Drive, Contacts, Sheets, and Docs.
Query Google Places API (New) via the goplaces CLI for text search, place details, resolve.
CLI to manage emails via IMAP/SMTP. Use himalaya to list, read, write, reply, forward.
Use the mcporter CLI to list, configure, auth, and call MCP servers/tools directly.
Generate or edit images via Gemini 3 Pro Image (Nano Banana Pro).
Edit PDFs with natural-language instructions using the nano-pdf CLI.
Work with Obsidian vaults (plain Markdown notes) and automate via obsidian-cli.
Local speech-to-text with the Whisper CLI (no API key).
Control Philips Hue lights/scenes via the OpenHue CLI.
Best practices for using the oracle CLI (prompt + file bundling, engines, sessions).
Foodora-only CLI for checking past orders and active order status (Deliveroo WIP).
ElevenLabs text-to-speech with mac-style say UX.
Generate spectrograms and feature-panel visualizations from audio with the songsee CLI.
Control Sonos speakers (discover/status/play/volume/group).
Summarize or extract text/transcripts from URLs, podcasts, and local files.
Send WhatsApp messages or search/sync WhatsApp history via the wacli CLI."
    SKILL_DEPS_SUBTITLES="




Install via npm


Install via npm



Install via npm





Install via npm

"
    checklist_tui "Install missing skill dependencies" "$SKILL_DEPS_OPTIONS" "$SKILL_DEPS_DESC" "$SKILL_DEPS_SUBTITLES" "" "SKILL_DEPS" "true" 1 0

    _skip_deps=false
    [ "${SKILL_DEPS_0:-false}" = "true" ] && _skip_deps=true
    _has_any=false
    for i in $(seq 1 24); do
        eval "_v=\${SKILL_DEPS_${i}:-false}"
        [ "$_v" = "true" ] && _has_any=true && break
    done
    if [ "$_skip_deps" = "true" ] || [ "$_has_any" = "false" ]; then
        printf "%b%s %b%s%b\n" "$(get_accent)" "$TREE_MID" "$RESET" "skipped" "$RESET"
    else
        _npm_container=()

        [ "${SKILL_DEPS_5:-false}" = "true" ] && _npm_container+=("clawhub")
        [ "${SKILL_DEPS_7:-false}" = "true" ] && _npm_container+=("@google/gemini-cli")
        [ "${SKILL_DEPS_12:-false}" = "true" ] && _npm_container+=("mcporter")
        [ "${SKILL_DEPS_23:-false}" = "true" ] && _npm_container+=("@steipete/summarize")

        if [ ${#_npm_container[@]} -gt 0 ]; then
            _npm_pkgs=$(IFS=' '; echo "${_npm_container[*]}")
            if [ "$_pm" = "bun" ]; then
                _user_local="export PATH=\"\\\$HOME/.bun/bin:\\\$PATH\" && mkdir -p \"\\\$HOME/.bun/bin\" 2>/dev/null; "
                _install_cmd="${_user_local}bun install -g $_npm_pkgs"
            else
                _user_local="export PATH=\"\\\$HOME/.local/bin:\\\$PATH\" && export NPM_CONFIG_PREFIX=\"\\\$HOME/.local\" && mkdir -p \"\\\$HOME/.local/bin\" && "
                _install_cmd="${_user_local}npm install -g --no-color --no-progress $_npm_pkgs"
            fi
            _cmd="docker exec \"$CONTAINER_NAME\" sh -c \"$_install_cmd\""
            print_debug_cmd "$TUI_PREFIX" "$_cmd"
            set +e
            run_with_progress_bar "Installing $_npm_pkgs in container..." "docker exec \"$CONTAINER_NAME\" sh -c \"$_install_cmd\"" "NPM"
            _npm_rc=$?
            set -e
            if [ "${_npm_rc:-0}" -ne 0 ]; then
                fail_install "npm install failed (exit ${_npm_rc})."
            fi
            printf "%b %b %b%s installed in container.%b\n" "$TUI_PREFIX" "${GREEN}[ OK ]${RESET}" "$GREEN" "$_npm_pkgs" "$RESET"
        fi
    fi

    HOOKS_OPTIONS="Skip for now
🚀 boot-md
📎 bootstrap-extra-files
📝 command-logger
💾 session-memory"
    HOOKS_DESC=""
    HOOKS_SUBTITLES="
Run BOOT.md on gateway startup
Inject additional workspace bootstrap files via glob/path patterns
Log all command events to a centralized audit file
Save session context to memory when /new command is issued"
    HOOKS_INITIAL="$(hooks_defaults_for_checklist)"
    checklist_tui "Enable hooks?" "$HOOKS_OPTIONS" "$HOOKS_DESC" "$HOOKS_SUBTITLES" "$HOOKS_INITIAL" "HOOKS_SEL" "false" 1 1
    _has_hooks=false
    [ "${HOOKS_SEL_1:-false}" = "true" ] && _has_hooks=true
    [ "${HOOKS_SEL_2:-false}" = "true" ] && _has_hooks=true
    [ "${HOOKS_SEL_3:-false}" = "true" ] && _has_hooks=true
    [ "${HOOKS_SEL_4:-false}" = "true" ] && _has_hooks=true
    _skip_only=false
    [ "$_has_hooks" = "false" ] && _skip_only=true
    if [ "$_skip_only" = "true" ]; then
        printf "%b%s %b%s%b\n" "$(get_accent)" "$TREE_MID" "$RESET" "skipped" "$RESET"
    elif [ "${HOOKS_ENABLED:-false}" = "false" ]; then
        printf "%b%s %b%s%b\n" "$(get_accent)" "$TREE_MID" "$DIM" "skipped (hooks disabled in Security Settings)" "$RESET"
    else
        _hooks_to_enable=()
        [ "${HOOKS_SEL_1:-false}" = "true" ] && _hooks_to_enable+=("boot-md")
        [ "${HOOKS_SEL_2:-false}" = "true" ] && _hooks_to_enable+=("bootstrap-extra-files")
        [ "${HOOKS_SEL_3:-false}" = "true" ] && _hooks_to_enable+=("command-logger")
        [ "${HOOKS_SEL_4:-false}" = "true" ] && _hooks_to_enable+=("session-memory")
        if [ ${#_hooks_to_enable[@]} -eq 0 ]; then
            printf "%b%s %b%s%b\n" "$(get_accent)" "$TREE_MID" "$RESET" "skipped" "$RESET"
        else
            _ph2_home="${CONTAINER_HOME:-/home/node}"
            _ph2_u="node"
            [[ "$_ph2_home" == "/root" ]] && _ph2_u="root"
            for _h in "${_hooks_to_enable[@]}"; do
                _hooks_cmd="docker exec -u $_ph2_u -e HOME=$_ph2_home -e OPENCLAW_BIND=${GATEWAY_BIND:-lan} \"$CONTAINER_NAME\" $OPENCLAW_CMD hooks enable $_h"
                print_debug_cmd "$TUI_PREFIX" "$_hooks_cmd"
                if docker exec -u "$_ph2_u" -e HOME="$_ph2_home" -e OPENCLAW_BIND="${GATEWAY_BIND:-lan}" "$CONTAINER_NAME" $OPENCLAW_CMD hooks enable "$_h" 2>&1 | while read -r line; do
                    line="${line#$'\r'}"
                    [ -z "$line" ] && continue
                    if [[ "$line" =~ [eE][rR][rR][oO][rR] ]]; then
                        printf "%b %b %b%s%b\n" "$TUI_PREFIX" "${RED}[ERROR]${RESET}" "$RED" "$line" "$RESET"
                    elif [ -n "${INSTALL_DEBUG:-}" ]; then
                        printf "%b %b %s\n" "$TUI_PREFIX" "${ORANGE:-$YELLOW}[DEBUG]${RESET}" "$line"
                    fi
                done; then
                    printf "%b %b %bEnabled hook: %s%b\n" "$TUI_PREFIX" "${GREEN}[ OK ]${RESET}" "$GREEN" "$_h" "$RESET"
                fi
            done
            HOOKS_ENTRIES="$(IFS=,; echo "${_hooks_to_enable[*]}")"
            [ -n "${HOOKS_ENTRIES:-}" ] && [ -n "${PROJECT_DIR:-}" ] && [ -f "${PROJECT_DIR}/config.yaml" ] && yaml_upsert_section_kv "${PROJECT_DIR}/config.yaml" "hooks" "entries" "$HOOKS_ENTRIES" 2>/dev/null || true
        fi
    fi
}
