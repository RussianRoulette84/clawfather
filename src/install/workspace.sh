#!/bin/bash

# --- Workspace Scaffolding & Skills Sync ---
# Requires: PROJECT_DIR, SRC_DIR, ywizz
# Order: 1) Sync skills into project cache (before Scaffolding). 2) Scaffolding (dirs, copy to OpenClaw).

run_workspace_setup() {
    _skills_cache="$PROJECT_DIR/skills"
    _oc_base="${OPENCLAW_CONFIG_DIR:-${OPENCLAW_CONFIG_DIR_DEFAULT:-$HOME/.openclaw}}"
    _oc_base="${_oc_base%/}"
    _openclaw_skills="${_oc_base}/skills"
    _skills_display="${_openclaw_skills/#$HOME/~}"

    # Copy a directory tree without ever creating symlinks in the destination.
    # - Skips symlink files and symlink directories
    # - Does not follow links (prevents pulling in outside data)
    copy_tree_no_symlinks() {
        local src="$1"
        local dst="$2"
        local py=""
        if command -v python3 >/dev/null 2>&1; then
            py="python3"
        elif command -v python >/dev/null 2>&1; then
            py="python"
        else
            warn "python3/python missing; cannot safely copy without symlinks."
            return 2
        fi
        "$py" - "$src" "$dst" <<'PY'
import os, shutil, sys
from pathlib import Path

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
dst.mkdir(parents=True, exist_ok=True)

for root, dirnames, filenames in os.walk(src, topdown=True, followlinks=False):
    root_p = Path(root)
    rel = root_p.relative_to(src)
    out_root = dst / rel
    out_root.mkdir(parents=True, exist_ok=True)

    # Prune symlinked directories so we never traverse them.
    keep_dirs = []
    for d in dirnames:
        p = root_p / d
        if os.path.islink(p):
            continue
        keep_dirs.append(d)
    dirnames[:] = keep_dirs

    for f in filenames:
        sp = root_p / f
        if os.path.islink(sp):
            continue
        dp = out_root / f
        dp.parent.mkdir(parents=True, exist_ok=True)
        try:
            shutil.copy2(sp, dp)
        except Exception:
            try:
                shutil.copyfile(sp, dp)
            except Exception:
                pass
PY
    }

    # 1) Skill sync FIRST (into project cache) — so the sync process appears before Scaffolding
    if [ -f "$SRC_DIR/sync_skills.sh" ]; then
        mkdir -p "$PROJECT_DIR/skills" "$PROJECT_DIR/src"
        [ ! "$SRC_DIR/sync_skills.sh" -ef "$PROJECT_DIR/src/sync_skills.sh" ] && cp "$SRC_DIR/sync_skills.sh" "$PROJECT_DIR/src/sync_skills.sh" || true
        chmod +x "$PROJECT_DIR/src/sync_skills.sh"
        ask_yes_no_tui "Sync skills with CLAWHUB_SKILLS.md?" "y" "RUN_SYNC" 1 0
        if [[ "$RUN_SYNC" =~ ^[Yy]$ ]]; then
            _sync_log="/tmp/sync_$$"
            SKILLS_ROOT="$_skills_cache" bash "$PROJECT_DIR/src/sync_skills.sh" 2>&1 | tee "$_sync_log" || warn "Skill sync had errors; continuing."
            _sync_lines=$(wc -l < "$_sync_log" 2>/dev/null || echo "0")
            [ "$_sync_lines" -gt 0 ] && _sync_lines=$((_sync_lines + 1))
            if [ "$_sync_lines" -gt 0 ]; then
                printf "\033[${_sync_lines}A\r\033[K"
                printf "%b%s%b%b%b\033[K\n" "$(get_accent)" "$DIAMOND_EMPTY" "$(get_accent)" "Syncing skills" "$RESET"
                printf "\033[$(($_sync_lines - 1))B"
            fi
            rm -f "$_sync_log"
        fi
    fi

    # 2) Scaffolding Workspace
    header_tui "Scaffolding Workspace" "" "1"
    _ws_lines=1
    printf "%b%s %b[ OK ]%b Target: %s\n" "$(get_accent)" "$TREE_MID" "$GREEN" "$RESET" "${PROJECT_DIR/#$HOME/~}" >&2
    _ws_lines=$((_ws_lines + 1))
    [ -f "$PROJECT_DIR/config.yaml" ] && success "config.yaml" || warn "config.yaml missing"
    _ws_lines=$((_ws_lines + 1))
    [ -f "$PROJECT_DIR/docker-compose.yml" ] && success "docker-compose.yml" || warn "docker-compose.yml missing"
    _ws_lines=$((_ws_lines + 1))
    [ -f "$PROJECT_DIR/.env.sensitive" ] && success ".env.sensitive (secrets) exists" || warn ".env.sensitive (secrets) missing"
    _ws_lines=$((_ws_lines + 1))

    mkdir -p "$PROJECT_DIR/skills" "${_oc_base}/logs" "${_oc_base}/workspace"
    if [ -n "${OPENCLAW_CONFIG_DIR:-}" ]; then
        mkdir -p "${_oc_base}/skills" 2>/dev/null || true
        [ -d "${OPENCLAW_CONFIG_DIR}" ] && sudo chown -R $(id -u):$(id -g) "${OPENCLAW_CONFIG_DIR}" 2>/dev/null || true
    fi
    _oc_display="${_oc_base/#$HOME/~}"
    success "Created directories: ${_skills_display}, ${_oc_display}/logs, ${_oc_display}/workspace"
    _ws_lines=$((_ws_lines + 1))
    sudo chown -R $(id -u):$(id -g) "$PROJECT_DIR" 2>/dev/null || true
    success "Permissions fixed"
    _ws_lines=$((_ws_lines + 1))

    # Copy from cache to OpenClaw dir — only subdirectories (skip API_KEY_NEEDED.md, CLAWHUB_SKILLS.md, SYNC_SKILLS_README.md at root)
    if [ -f "$SRC_DIR/sync_skills.sh" ] && [ -n "$(ls -A "$_skills_cache" 2>/dev/null)" ]; then
        if [ "$_skills_cache" != "$_openclaw_skills" ]; then
            mkdir -p "$_openclaw_skills"
            for _d in "$_skills_cache"/*/ ; do
                [ -d "$_d" ] || continue
                # Prefer rsync but never preserve symlinks (and never follow them).
                if command -v rsync >/dev/null 2>&1; then
                    rsync -a --no-links "$_d" "$_openclaw_skills/" 2>/dev/null || copy_tree_no_symlinks "$_d" "$_openclaw_skills/$(basename "${_d%/}")" 2>/dev/null || true
                else
                    copy_tree_no_symlinks "$_d" "$_openclaw_skills/$(basename "${_d%/}")" 2>/dev/null || true
                fi
            done
            [ -n "${OPENCLAW_CONFIG_DIR:-}" ] && sudo chown -R $(id -u):$(id -g) "${_openclaw_skills}" 2>/dev/null || true
        fi
        # Only show when user did not select No for "Sync skills with CLAWHUB_SKILLS.md?"
        if ! [[ "${RUN_SYNC:-}" =~ ^[Nn]$ ]]; then
            success "Skills installed: ${_skills_display}"
            _ws_lines=$((_ws_lines + 1))
        fi
    fi
    printf "\033[${_ws_lines}A\r\033[K"
    printf "%b%s%b%b%b\033[K\n" "$(get_accent)" "$DIAMOND_EMPTY" "$(get_accent)" "Scaffolding Workspace" "$RESET"
    printf "\033[$(($_ws_lines - 1))B"
}
