#!/bin/bash
set -e
set +m

# YWIZZ_DEBUG=1: print line number on exit (for debugging TUI crashes)
[ -n "${YWIZZ_DEBUG:-}" ] && trap 'echo "[DEBUG] Exit at line $LINENO err=$?" >&2' EXIT

# Require bash (BASH_SOURCE, [[, etc.). Re-exec if run with sh/dash.
case "${BASH:-}" in *bash) ;; *) exec /bin/bash "$0" "$@" ;; esac

# --- Bootstrap ---
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$INSTALL_DIR"
LIB_DIR="$INSTALL_DIR/lib"
PROJECT_ROOT="$(cd "$INSTALL_DIR/.." && pwd)"

[ -f "$LIB_DIR/ywizz/theme.sh" ] && source "$LIB_DIR/ywizz/theme.sh"
accent_color="$C7"
dim_color="${C7}${DIM}"
row_selected_color="\033[1;37m"

source "$LIB_DIR/ywizz/ywizz.sh"
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/checks.sh"
source "$LIB_DIR/models.sh"

[ -f "$PROJECT_ROOT/.env" ] && { set +e; source "$PROJECT_ROOT/.env" 2>/dev/null; set -e; }

# --- Version from README badge (consumed by ywizz banner footer) ---
CLAWFATHER_VERSION=$(grep -oE 'Version-v[0-9.]+' "$PROJECT_ROOT/README.md" 2>/dev/null | head -1 | sed 's/Version-//' || echo "v1.1")
export CLAWFATHER_VERSION

# --- ASCII & Banner Config (consumed by ywizz via YWIZZ_ASCII_*) ---
BANNER_C_PINK="${C9:-}"
BANNER_C_BLUE="${C2:-}"
BANNER_C_LBL="${C4:-}"
# Animation: INVERT_COLORS (ON/OFF), ANIMATION_PHASE_SHIFT_ROWS, ANIMATION_CYCLES (-1=endless)
# ANIMATION_DIRECTION: NW, N, NE, E, SE, S, SW, W — prefix - to reverse
INVERT_COLORS="OFF"
ANIMATION_PHASE_SHIFT_ROWS="4"
ANIMATION_CYCLES="1"
ANIMATION_DIRECTION="-NW"
YWIZZ_ASCII_PRIMARY=(
'⠀   ⠀    ⠀⢀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀  '
'⠀⠀   ⢀⣠⣤⣼⣿⣿⣿⣾⣶⡤⠄⠀⠀⠀⠀⠀⠀⠀'
'⠀   ⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⡀⠀⠀⠀⠀⠀⠀'
'   ⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣉⡄⠀⠀⠀⠀    /$$$$$$  /$$        /$$$$$   /$$       /$$ /$$$$$$$ /$$$$$$  /$$$$$$$$ /$$   /$$  /$$$$$$$ /$$$$$$ '
'   ⢀⣾⢿⣿⣿⡿⠿⠿⠿⠿⢿⣿⣿⡿⣿⢇⠀⠀⠀⠀   /$$__  $$| $$       /$$__  $$| $$  /$$ | $$|$$_____/|$$__  $$|__  $$__/| $$  | $$| $$_____/| $$__  $$ '
'   ⠀⠀⠀⠀⢨⣷⡀⠀⠀⠐⣢⣬⣿⣷⡁⣾⠀⠀⠀⠀  | $$  \__/| $$      | $$  \ $$| $$ /$$$| $$| $$     | $$  \ $$   | $$   | $$  | $$| $$      | $$  \ $$ '
'   ⢀⡠⣤⣴⣾⣿⣿⣷⣦⣿⣿⣿⣿⣿⠿⡇⠀⠀⠀⠀  | $$      | $$      | $$$$$$$$| $$ $$/$$ $$| $$$$$  | $$$$$$$$   | $$   | $$$$$$$$| $$$$$   | $$$$$$/ '
'   ⠈⠙⣿⡿⠚⠿⠟⢿⣟⣿⣿⣿⣿⣿⠉⠀⠀⠀⠀⠀  | $$      | $$      | $$__  $$| $$$$_  $$$$| $$__/  | $$__  $$   | $$   | $$__  $$| $$__/   | $$__  $$ '
'   ⠀⠀⣹⠵⠀⠠⠼⠯⠝⣻⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀  | $$    $$| $$      | $$  | $$| $$$/ \  $$$| $$     | $$  | $$   | $$   | $$  | $$| $$      | $$  \ $$ '
'   ⠀⠀⠻⢂⡄⠒⠒⠛⣿⡿⠛⠻⠋⣼⠀⠀⠀⠀⠀⠀  |  $$$$$$/| $$$$$$$$| $$  | $$| $$/   \  $$| $$     | $$  | $$   | $$   | $$  | $$| $$$$$$$$| $$  | $$ '
'   ⠀⠀⠠⡀⠰⠶⠿⠿⠷⠞⠀⣠⣴⠟⠀⠀⠀⠀⠀⠀   \______/ |________/|__/  |__/|__/     \__/|__/     |__/  |__/   |__/   |__/  |__/|________/|__/  |__/ '
'⠀⠀⠀⠈⠂⣀⠀⠀⠀⠀⢠⠟⠉⠀⠀⠀⠀⠀⠀⠀'
'⠀⠀⠀⠀⠀⠘⠓⠂⠀⠐⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀'
)
YWIZZ_ASCII_SECONDARY=(
'⠀   ⠀⠀⢀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀'
'⠀⠀⢀⣠⣤⣼⣿⣿⣿⣾⣶⡤⠄⠀⠀⠀⠀⠀⠀⠀'
'⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⡀⠀⠀⠀⠀⠀⠀'
'⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣉⡄⠀⠀⠀⠀'
'⢀⣾⢿⣿⣿⡿⠿⠿⠿⠿⢿⣿⣿⡿⣿⢇⠀⠀⠀⠀'
'⠀⠀⠀⠀⢨⣷⡀⠀⠀⠐⣢⣬⣿⣷⡁⣾⠀⠀⠀⠀'
'⢀⡠⣤⣴⣾⣿⣿⣷⣦⣿⣿⣿⣿⣿⠿⡇⠀⠀⠀⠀'
'⠈⠙⣿⡿⠚⠿⠟⢿⣟⣿⣿⣿⣿⣿⠉⠀⠀⠀⠀⠀'
'⠀⠀⣹⠵⠀⠠⠼⠯⠝⣻⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀'
'⠀⠀⠻⢂⡄⠒⠒⠛⣿⡿⠛⠻⠋⣼⠀⠀⠀⠀⠀⠀'
'⠀⠀⠠⡀⠰⠶⠿⠿⠷⠞⠀⣠⣴⠟⠀⠀⠀⠀⠀⠀'
'⠀⠀⠀⠈⠂⣀⠀⠀⠀⠀⢠⠟⠉⠀⠀⠀⠀⠀⠀⠀'
'⠀⠀⠀⠀⠀⠘⠓⠂⠀⠐⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀'
)
CLAWFATHER_BANNER=("${YWIZZ_ASCII_PRIMARY[@]}")

[ -f "$INSTALL_DIR/install/args.sh" ] && source "$INSTALL_DIR/install/args.sh"
[ -f "$INSTALL_DIR/install/defaults.sh" ] && source "$INSTALL_DIR/install/defaults.sh"

parse_install_args "$@"
PROJECT_DIR="${PROJECT_DIR:-$PROJECT_DIR_DEFAULT}"

# --- Wipe / Clean ---
if [ "$WIPE_ALL" = true ] || [ "$CLEAN_INSTALL" = true ]; then
    [ "$WIPE_ALL" = true ] && warn "Wiping ALL Clawfather containers, volumes, and IMAGES..."
    [ "$WIPE_ALL" = false ] && warn "Cleaning up previous installation..."
    if command -v docker &>/dev/null; then
        if [ "$WIPE_ALL" = true ]; then
            docker compose down --volumes --rmi all --remove-orphans 2>/dev/null || docker-compose down --volumes --rmi all --remove-orphans 2>/dev/null || true
        else
            _gw_id=$(cd "$PROJECT_DIR" && docker compose ps -q "$GATEWAY_SERVICE" 2>/dev/null)
            [ -n "$_gw_id" ] && docker rm -f "$_gw_id" 2>/dev/null || true
        fi
    fi
    warn "Cleaning log directory..."
    # Clear logs under the *default* OpenClaw dir (avoid creating/depending on project-local .openclaw)
    _default_cfg_dir="${OPENCLAW_CONFIG_DIR_DEFAULT:-$HOME/.openclaw}"
    _default_log_dir="${_default_cfg_dir%/}/logs"
    if [ -d "$_default_log_dir" ]; then
        command -v trash >/dev/null 2>&1 && trash "$_default_log_dir"/* 2>/dev/null || rm -rf "$_default_log_dir"/* 2>/dev/null || true
    fi
    success "Log directory cleared."
    [ "$WIPE_ALL" = true ] && { success "Full wipe complete."; exit 0; }
fi

# --- Wizard ---
[ -t 1 ] && clear || true
ywizz_ascii_primary
ywizz_show type=security
ywizz_show type=confirm title="I understand this is powerful and inherently risky. Continue?" out=confirm default=y
[[ "$confirm" == "n" ]] && { style_item "Wise choice!"; printf "%b%s %s%b\n" "$accent_color" "$TREE_BOT" "Exiting safely." "$RESET"; exit 0; }

: "${WORKSPACE_DIR_DEFAULT:=${OPENCLAW_CONFIG_DIR_DEFAULT:-$HOME/.openclaw}/workspace}"
# --- macOS / host directories first ---
# Allow install inside project (.openclaw) or outside (e.g. ~/Projects/openclaw); default from config or project
ask_path_tui "OpenClaw directory on your $HOST_OS_LABEL" "${OPENCLAW_CONFIG_DIR_DEFAULT:-$HOME/.openclaw}" "OPENCLAW_CONFIG_DIR_INPUT" "$TREE_TOP" 1 0
OPENCLAW_CONFIG_DIR="${OPENCLAW_CONFIG_DIR_INPUT:-${OPENCLAW_CONFIG_DIR_DEFAULT:-$HOME/.openclaw}}"
# Resolve to absolute path so Docker and all steps use the same path.
# Key fix: on macOS, treat "Users/..." as "/Users/..." (otherwise we'd create ./Users in the repo).
resolve_host_path_abs() {
    local base="$1" p="$2"
    [ -z "$p" ] && return 0
    # Expand ~
    [[ "$p" == ~* ]] && p="${p/#\~/$HOME}"
    # macOS convenience: Users/... -> /Users/... (common copy/paste omission)
    if [ "${OS_TYPE:-}" = "macos" ] && [[ "$p" == Users/* ]]; then
        p="/$p"
    fi
    # Resolve relative paths against the project dir (base)
    if [[ "$p" != /* ]]; then
        local resolved=""
        resolved="$(cd "$base" 2>/dev/null && cd "$p" 2>/dev/null && pwd)"
        if [ -n "$resolved" ]; then
            p="$resolved"
        else
            p="$base/${p#./}"
        fi
    fi
    echo "$p"
}
OPENCLAW_CONFIG_DIR="$(resolve_host_path_abs "$PROJECT_DIR" "$OPENCLAW_CONFIG_DIR")"
# Wipe brain (OpenClaw dir on host): ask right after OpenClaw directory so order is clear
_brain_dir="${OPENCLAW_CONFIG_DIR:-}"
if [ -n "$_brain_dir" ] && [ -d "$_brain_dir" ]; then
    _brain_display="${_brain_dir/#$HOME/~}"
    _brain_prompt="Wipe existing OpenClaw directory on ${HOST_OS_LABEL:-macOS}? ${DIM}${accent_color}${_brain_display}${RESET}"
    ask_yes_no_tui "$_brain_prompt" "y" "WIPE_BRAIN" 1 0
else
    WIPE_BRAIN="n"
fi
# Workspace default: always derived from previous answer (OpenClaw dir) so next question updates
_ws_default="$OPENCLAW_CONFIG_DIR/workspace"
ask_path_tui "Workspace directory on your $HOST_OS_LABEL" "$_ws_default" "WORKSPACE_DIR_INPUT" "$TREE_TOP" 1 0
OPENCLAW_WORKSPACE_DIR="${WORKSPACE_DIR_INPUT:-$_ws_default}"
# Resolve workspace to absolute as well.
OPENCLAW_WORKSPACE_DIR="$(resolve_host_path_abs "$PROJECT_DIR" "$OPENCLAW_WORKSPACE_DIR")"

ask_yes_no_tui "Mirror all your projects folder with Docker? ${dim_color}Risky if this folder contains sensitive information!${RESET}" "${MIRROR_PROJECTS_DEFAULT:-n}" "MIRROR_PROJECTS_SEL" 1 0
MIRROR_PROJECTS=false
[[ "$MIRROR_PROJECTS_SEL" =~ ^[Yy] ]] && MIRROR_PROJECTS=true

if [ "$MIRROR_PROJECTS" = true ]; then
    ask_path_tui "Projects directory on your $HOST_OS_LABEL" "$PROJECTS_DIR_DEFAULT" "PROJECTS_DIR_INPUT" "$TREE_TOP" 1 0
    PROJECTS_DIR="${PROJECTS_DIR_INPUT:-$PROJECTS_DIR_DEFAULT}"
    # Resolve projects dir to absolute (expand ~, handle macOS Users/..., resolve relative from project dir).
    # Docker mounts require a real absolute path; otherwise Docker may create repo-local directories like ./Users/...
    PROJECTS_DIR="$(resolve_host_path_abs "$PROJECT_DIR" "$PROJECTS_DIR")"
else
    PROJECTS_DIR=""
fi

# --- Docker directories: each next default derived from previous answer ---
ask_tui "OpenClaw directory on Docker" "${OPENCLAW_DOCKER_BASE:-~/.openclaw}" "OPENCLAW_DOCKER_BASE_INPUT" "$TREE_TOP" 1 0
OPENCLAW_DOCKER_BASE="${OPENCLAW_DOCKER_BASE_INPUT:-${OPENCLAW_DOCKER_BASE:-~/.openclaw}}"
# Workspace on Docker: default = previous answer + /workspace
ask_tui "Workspace directory on Docker" "$OPENCLAW_DOCKER_BASE/workspace" "OPENCLAW_DOCKER_WORKSPACE_INPUT" "$TREE_TOP" 1 0
OPENCLAW_DOCKER_WORKSPACE="${OPENCLAW_DOCKER_WORKSPACE_INPUT:-$OPENCLAW_DOCKER_BASE/workspace}"

if [ "$MIRROR_PROJECTS" = true ]; then
    # Projects on Docker: default = workspace + basename of host projects dir (e.g. ~/.openclaw/workspace/ai)
    _projects_basename="$(basename "${PROJECTS_DIR}" 2>/dev/null)"
    [ -z "$_projects_basename" ] && _projects_basename="ai"
    _default_docker_projects="$OPENCLAW_DOCKER_WORKSPACE/$_projects_basename"
    ask_tui "${HOST_OS_LABEL:-macOS} Projects directory on Docker" "$_default_docker_projects" "DOCKER_PROJECTS_PATH_INPUT" "$TREE_TOP" 1 0
    DOCKER_PROJECTS_PATH="${DOCKER_PROJECTS_PATH_INPUT:-$_default_docker_projects}"
    DOCKER_PROJECTS_BASENAME="$(basename "${DOCKER_PROJECTS_PATH}" 2>/dev/null || echo "workspace")"
else
    DOCKER_PROJECTS_BASENAME="Projects"
    DOCKER_PROJECTS_PATH=""
fi

select_tui "What do you want to set up?" "Local gateway (this machine) ${DIM}${C8}Recommended for ClawFather${RESET}
Remote gateway (info-only)" "" "" "GATEWAY_TYPE_SEL" 0 "true" 1 0

select_tui "Gateway bind" "LAN (0.0.0.0) ${DIM}${C8}Recommended for ClawFather${RESET}
Loopback (127.0.0.1)
Tailnet (Tailscale IP)
Auto (Loopback -> LAN)
Custom IP" "" "" "GATEWAY_BIND_SEL" "${GATEWAY_BIND_DEFAULT_INDEX:-0}" "true" 1 0

[[ "$GATEWAY_BIND_SEL" == *"Custom IP"* ]] && ask_tui "Custom bind IP" "${GATEWAY_BIND_CUSTOM_IP:-0.0.0.0}" "GATEWAY_BIND_CUSTOM_IP" "$TREE_TOP" 1 0

ask_tui "Gateway port" "${OPENCLAW_GATEWAY_PORT:-18789}" "OPENCLAW_GATEWAY_PORT" "$TREE_TOP" 1 0

select_tui "Gateway auth" "Token (Recommended)
Password" "" "" "GATEWAY_AUTH_SEL" 0 "true" 1 0

[[ "$GATEWAY_AUTH_SEL" == *"Password"* ]] && { ask_tui "Gateway password" "" "GATEWAY_PASSWORD" "$TREE_TOP" 1 0; }
[[ "$GATEWAY_AUTH_SEL" != *"Password"* ]] && {
    GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-$GATEWAY_TOKEN}"
    ask_tui "Gateway token ${dim_color}(Press ENTER to generate token)" "" "GATEWAY_TOKEN_INPUT" "$TREE_TOP" 1 0 "Gateway token"
    if [ -z "$GATEWAY_TOKEN_INPUT" ]; then
        GATEWAY_TOKEN="${GATEWAY_TOKEN:-$(openssl rand -hex 32 2>/dev/null || date +%s | head -c 32)}"
        [ -n "$GATEWAY_TOKEN" ] && printf "\033[1A\r\033[K%b%s %b%s%b\n" "$accent_color" "$TREE_MID" "$GREEN" "$GATEWAY_TOKEN" "$RESET"
    else
        GATEWAY_TOKEN="$GATEWAY_TOKEN_INPUT"
    fi
}

[ -f "$INSTALL_DIR/install/api_keys.sh" ] && source "$INSTALL_DIR/install/api_keys.sh" && run_api_keys_config

select_tui "Tailscale exposure" "Off (No Tailscale exposure)
Serve
Funnel" "Standard local/LAN access only.
Expose gateway to your Tailnet devices.
Expose gateway to the public internet via Tailscale." "" "TAILSCALE_EXP_SEL" 0 "true" 1 0

[[ "$GATEWAY_TYPE_SEL" == *"Local"* ]] && GATEWAY_TYPE="local" || GATEWAY_TYPE="remote"
case "$GATEWAY_BIND_SEL" in *"Loopback"*) GATEWAY_BIND="loopback" ;; *"LAN"*) GATEWAY_BIND="lan" ;; *"Tailnet"*) GATEWAY_BIND="tailscale" ;; *"Auto"*) GATEWAY_BIND="auto" ;; *) GATEWAY_BIND="${GATEWAY_BIND_CUSTOM_IP:-0.0.0.0}" ;; esac
case "$TAILSCALE_EXP_SEL" in *"Off"*) TAILSCALE_EXP="off" ;; *"Serve"*) TAILSCALE_EXP="serve" ;; *"Funnel"*) TAILSCALE_EXP="funnel" ;; esac

IMG_OPTIONS="fourplayers/openclaw:latest
alpine/openclaw:latest
ghcr.io/phioranex/openclaw-docker
coollabsio/openclaw:latest
1panel/openclaw:latest"
IMG_SUBTITLES="Security Rating: ⭐⭐⭐⭐⭐
Security Rating: ⭐⭐
Security Rating: ⭐⭐⭐⭐
Security Rating: ⭐⭐⭐
Security Rating: ⭐⭐⭐"
IMG_DESC="Proactive security with built-in HTTPS support. Actively maintained with very frequent updates and optimized for zero-config security configurations. Reduced attack surface via automated setup. Recommended for security-conscious production use.
Official image, widely compatible and stable. Built on Debian to ensure musl library compatibility and standard security profile with no extra hardening. Requires manual coordination for security patches. Best for users who prefer the official distribution.
Bleeding-edge updates every 6 hours via automation. Minimizes exposure to known CVEs in OpenClaw. Standard container security with standard permissions. Uses GitHub Container Registry for verified pulls. Best for users who prioritize the latest security fixes.
Includes Nginx proxy by default for front-facing security. Hardened for the Coolify deployment platform. Environment-variable based security configuration. Simplifies the addition of SSL/TLS certificates. Good for deployments requiring an integrated proxy.
Optimized for the 1Panel security ecosystem. Smaller image size (~1GB) reducing some overhead. Recently updated and actively maintained with standard security defaults within the panel environment. Best if already using 1Panel for server management."
# Default index from config docker.image when it matches an option
DOCKER_IMAGE_DEFAULT_INDEX=0
if [ -n "${DOCKER_IMAGE_SEL:-}" ]; then
    _di_idx=0
    while IFS= read -r _di_opt; do
        [ "$_di_opt" = "$DOCKER_IMAGE_SEL" ] && { DOCKER_IMAGE_DEFAULT_INDEX=$_di_idx; break; }
        _di_idx=$((_di_idx + 1))
    done <<< "$IMG_OPTIONS"
fi
select_tui "Docker Image" "$IMG_OPTIONS" "$IMG_DESC" "$IMG_SUBTITLES" "DOCKER_IMAGE_SEL" "${DOCKER_IMAGE_DEFAULT_INDEX}" "true" 1 0

# fourplayers/openclaw: Root Mode is hidden (forced on); other images default root off
FOURPLAYERS_IMAGE=false
case "${DOCKER_IMAGE_SEL:-}" in *fourplayers/openclaw*) FOURPLAYERS_IMAGE=true ;; esac
export FOURPLAYERS_IMAGE
SEC_ROOT_HIDDEN=false
[ "$FOURPLAYERS_IMAGE" = true ] && SEC_ROOT_HIDDEN=true
export SEC_ROOT_HIDDEN
# fourplayers: root on is forced in security.sh (Root hidden in UI); checklist defaults always from config below

ask_yes_no_tui "Install local LLM using ollama?" "n" "USE_OLLAMA_SEL" 1 0
[[ "$USE_OLLAMA_SEL" =~ ^[Yy] ]] && USE_OLLAMA=true || USE_OLLAMA=false
export USE_OLLAMA

[ -f "$INSTALL_DIR/install/models.sh" ] && source "$INSTALL_DIR/install/models.sh" && run_model_setup

# Full 13-option list: 0=Root 1=Safe 2=Bridge 3=Browser 4=Tools 5=Hooks 6=NoNewPrivs 7=AutoStart 8=Sandbox 9=Paranoid 10=Offline 11=ReadOnly 12=God
SEC_OPTIONS_FULL="Root Mode
Safe Mode
OpenClaw Bridge (Host Access)
Browser Control
Tools Elevated
Hooks
No New Privileges
Auto-Start Docker
Sandbox Mode
Paranoid Mode (cap_drop)
Offline Mode
Read-Only Mounts
God Mode"
SEC_DESCRIPTIONS_FULL="Enabled: Runs the container as root so the setup wizard and global npm installs (e.g. skills) work.\\nDisabled: Uses the image default user (node), which may cause EACCES during skill install.
Enabled: Prevents the agent from executing destructive commands without your explicit manual verification.\\nDisabled: Allows the agent to silently delete or overwrite files, which could lead to accidental data loss.
Enabled: Essential for local AI workflows. Allows the container to communicate with services like Ollama on your Mac.\\nDisabled: Strictly isolates the container from host services, preventing the use of local LLM models and bridges.
Enabled: Allows the agent to drive a browser (tabs, navigate, snapshot) for web automation and testing.\\nDisabled: Browser tool is disabled; agent cannot control a browser.
Enabled: Allows elevated host exec and other high-privilege tools; required for full agentic workflows.\\nDisabled: Elevated tools are disabled; agent runs with reduced tool blast radius.
Enabled: Enables gateway hooks for automation and custom event handling.\\nDisabled: Hooks are disabled; no custom hook handlers run (default for minimal attack surface).
Enabled: Hardens the container by preventing process privilege escalation and disabling all standard sudo-based exploits.\\nDisabled: Runs with standard container isolation, which may allow certain administrative operations or privilege gains.
Enabled: Ensures your OpenClaw gateway is always available by automatically restarting the container after a system reboot.\\nDisabled: The container remains stopped after a reboot and must be manually started via the terminal for each use.
Enabled: Restricts agent file access strictly to the local workspace folder for maximum data safety.\\nDisabled: Grants agent access to your entire user home directory, exposing personal files and sensitive keys.
Enabled: Drops all Linux kernel capabilities to provide the highest level of container isolation against zero-day exploits.\\nDisabled: Uses standard Docker capability defaults, providing more flexibility for complex system-level agent tasks.
Enabled: Completely disconnects the container from all external networks for maximum privacy and air-gapped security.\\nDisabled: Standard internet access is enabled, allowing the agent to perform web research and download updates.
Enabled: Protects your skills folder from any accidental or malicious modification by the agent.\\nDisabled: Allows the agent to self-update, modify its own skills, and manage files within the skills folder.
Enabled: Grants the agent direct control over your Docker socket, allowing it to manage other containers (God Mode).\\nDisabled: Strict confinement. The agent is locked inside its own container and cannot see or control other Docker services."
SEC_OPTIONS="$SEC_OPTIONS_FULL"
SEC_DESCRIPTIONS="$SEC_DESCRIPTIONS_FULL"
# Always use config.yaml as checklist defaults when present (config wins over any image/default)
[ -f "$PROJECT_DIR/config.yaml" ] && load_security_defaults_from_config "$PROJECT_DIR/config.yaml"
checklist_tui "Security Settings" "$SEC_OPTIONS" "$SEC_DESCRIPTIONS" "" "$(sec_opts_for_checklist)" "SEC_OPTS" "true" 1 0

# --- Run Executor ---
[ -f "$INSTALL_DIR/install/executor.sh" ] && source "$INSTALL_DIR/install/executor.sh"
run_install
