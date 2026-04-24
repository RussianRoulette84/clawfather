#!/bin/bash

# --- Security Settings: Map SEC_OPTS to Variables & Apply to docker-compose ---
# Requires: PROJECT_DIR, SEC_OPTS_0..SEC_OPTS_12, lib/utils.sh (sed_inplace)

apply_security_settings() {
    # Map checklist output to variables (checklist_tui sets SEC_OPTS_0..SEC_OPTS_12). Display order: 0=Root 1=Safe 2=Bridge 3=Browser 4=Tools 5=Hooks 6=NoNewPrivs 7=AutoStart 8=Sandbox 9=Paranoid 10=Offline 11=ReadOnly 12=God
    # When SEC_ROOT_HIDDEN=true (fourplayers), inject Root=true at index 0 and skip SEC_OPTS_0 so array indices stay aligned
    if [ "${SEC_ROOT_HIDDEN:-false}" = "true" ]; then
        SEC_OPTS="true,${SEC_OPTS_1:-false},${SEC_OPTS_2:-false},${SEC_OPTS_3:-false},${SEC_OPTS_4:-false},${SEC_OPTS_5:-false},${SEC_OPTS_6:-false},${SEC_OPTS_7:-false},${SEC_OPTS_8:-false},${SEC_OPTS_9:-false},${SEC_OPTS_10:-false},${SEC_OPTS_11:-false},${SEC_OPTS_12:-false}"
    else
        SEC_OPTS="${SEC_OPTS_0:-false},${SEC_OPTS_1:-false},${SEC_OPTS_2:-false},${SEC_OPTS_3:-false},${SEC_OPTS_4:-false},${SEC_OPTS_5:-false},${SEC_OPTS_6:-false},${SEC_OPTS_7:-false},${SEC_OPTS_8:-false},${SEC_OPTS_9:-false},${SEC_OPTS_10:-false},${SEC_OPTS_11:-false},${SEC_OPTS_12:-false}"
    fi
    IFS=',' read -r -a SEC_ARRAY <<< "$SEC_OPTS"

    ROOT_MODE="$([ "${SEC_ARRAY[0]}" == "true" ] && echo "true" || echo "false")"
    SAFE_MODE="$([ "${SEC_ARRAY[1]}" == "true" ] && echo "true" || echo "false")"
    BRIDGE_ENABLED="$([ "${SEC_ARRAY[2]}" == "true" ] && echo "true" || echo "false")"
    BROWSER_CONTROL="$([ "${SEC_ARRAY[3]}" == "true" ] && echo "true" || echo "false")"
    TOOLS_ELEVATED="$([ "${SEC_ARRAY[4]}" == "true" ] && echo "true" || echo "false")"
    HOOKS_ENABLED="$([ "${SEC_ARRAY[5]}" == "true" ] && echo "true" || echo "false")"
    NO_NEW_PRIVS="$([ "${SEC_ARRAY[6]}" == "true" ] && echo "true" || echo "false")"
    AUTO_START="$([ "${SEC_ARRAY[7]}" == "true" ] && echo "true" || echo "false")"
    SANDBOX_MODE="$([ "${SEC_ARRAY[8]}" == "true" ] && echo "true" || echo "false")"
    PARANOID_MODE="$([ "${SEC_ARRAY[9]}" == "true" ] && echo "true" || echo "false")"
    NETWORKING_OFFLINE="$([ "${SEC_ARRAY[10]}" == "true" ] && echo "true" || echo "false")"
    READ_ONLY_MOUNTS="$([ "${SEC_ARRAY[11]}" == "true" ] && echo "true" || echo "false")"
    GOD_MODE="$([ "${SEC_ARRAY[12]}" == "true" ] && echo "true" || echo "false")"
    COMMAND_LOGGER="true"

    local _dc="$PROJECT_DIR/docker-compose.yml"
    if [ -f "$_dc" ]; then
        [ "$PARANOID_MODE" == "true" ] && sed_inplace 's/cap_drop: .*/cap_drop: ["ALL"]/' "$_dc" || true
        [ "$NO_NEW_PRIVS" == "true" ] && sed_inplace 's/security_opt: .*/security_opt: ["no-new-privileges:true"]/' "$_dc" || true
        [ "$NETWORKING_OFFLINE" == "true" ] && sed_inplace 's/network_mode: .*/network_mode: none/' "$_dc" || true
        [ "$BRIDGE_ENABLED" == "true" ] && sed_inplace 's/extra_hosts: .*/extra_hosts: ["host.docker.internal:host-gateway"]/' "$_dc" || true
        # READ_ONLY_MOUNTS: OPENCLAW_VOL_MODE is set in .env by gateway.sh
        [ "$AUTO_START" == "true" ] && sed_inplace 's/restart: .*/restart: unless-stopped/' "$_dc" || true
        [ "$AUTO_START" == "false" ] && sed_inplace 's/restart: .*/restart: no/' "$_dc" || true
        [ "$GOD_MODE" == "true" ] && sed_inplace 's/# - \/var\/run\/docker.sock/- \/var\/run\/docker.sock/' "$_dc" || true
        [ "$GOD_MODE" == "false" ] && sed_inplace 's/- \/var\/run\/docker.sock/# - \/var\/run\/docker.sock/' "$_dc" || true
    fi
}

# Build comma-separated list of enabled security options for display (e.g. "Sandbox, Safe-Mode, Bridge, ...")
get_active_sec_summary() {
    local list=()
    [ "${SANDBOX_MODE:-false}" = "true" ] && list+=("Sandbox")
    [ "${ROOT_MODE:-false}" = "true" ] && list+=("Root")
    [ "${SAFE_MODE:-false}" = "true" ] && list+=("Safe-Mode")
    [ "${BRIDGE_ENABLED:-false}" = "true" ] && list+=("Bridge")
    [ "${BROWSER_CONTROL:-false}" = "true" ] && list+=("Browser")
    [ "${TOOLS_ELEVATED:-false}" = "true" ] && list+=("Tools")
    [ "${HOOKS_ENABLED:-false}" = "true" ] && list+=("Hooks")
    [ "${NO_NEW_PRIVS:-false}" = "true" ] && list+=("NoNewPrivs")
    [ "${AUTO_START:-false}" = "true" ] && list+=("AutoStart")
    [ "${PARANOID_MODE:-false}" = "true" ] && list+=("Paranoid")
    [ "${NETWORKING_OFFLINE:-false}" = "true" ] && list+=("Offline")
    [ "${READ_ONLY_MOUNTS:-false}" = "true" ] && list+=("ReadOnly")
    [ "${GOD_MODE:-false}" = "true" ] && list+=("God")
    if [ ${#list[@]} -eq 0 ]; then
        echo "None"
    else
        printf '%s' "$(IFS=,; echo "${list[*]}")"
    fi
}
