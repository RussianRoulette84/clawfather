#!/bin/bash

# --- API Keys Configuration ---
# Requires: PROJECT_DIR, lib/models.sh (is_valid_key, scan_for_key), ywizz

# Mask token for display: first 6 + ... + last 4
mask_token() {
    local v="$1"
    [ -z "$v" ] && return
    if [ ${#v} -le 12 ]; then
        echo "$v"
    else
        echo "${v:0:6}...${v: -4}"
    fi
}

run_api_keys_config() {
    set +e

    _keys="ZAI_API_KEY|GEMINI_API_KEY|ANTHROPIC_API_KEY|GITHUB_TOKEN"
    _labels="Zai API key|Gemini API key|Anthropic API key|GitHub token"
    _key_arr=()
    _label_arr=()
    IFS='|' read -ra _key_arr <<< "$_keys"
    IFS='|' read -ra _label_arr <<< "$_labels"

    local acc
    acc=$(get_accent)
    for i in "${!_key_arr[@]}"; do
        key_name="${_key_arr[$i]}"
        label="${_label_arr[$i]}"
        current_val=""
        if [ -f "$PROJECT_DIR/.env.sensitive" ]; then
            DETECTED=$(scan_for_key "$key_name" "$PROJECT_DIR/.env.sensitive" 2>/dev/null) || true
            [ -n "$DETECTED" ] && current_val="${DETECTED%|*}"
        fi

        _display=""
        [ -n "$current_val" ] && _display=$(mask_token "$current_val")
        if [ -n "$_display" ]; then
            ask_tui "$label ${dim_color}(Enter to keep, or type to change)${RESET}" "$current_val" "$key_name" "$TREE_TOP" 1 "0" "$label" "" "skipped" "$_display"
        else
            ask_tui "$label ${dim_color}(Enter to skip)${RESET}" "" "$key_name" "$TREE_TOP" 1 "0" "$label" "" "skipped"
        fi
    done

    [ ! -f "$PROJECT_DIR/.env.sensitive" ] && { cp "${PROJECT_DIR}/.env.sensitive.example" "$PROJECT_DIR/.env.sensitive" 2>/dev/null || touch "$PROJECT_DIR/.env.sensitive"; } || true
    for key_name in ANTHROPIC_API_KEY GEMINI_API_KEY ZAI_API_KEY GITHUB_TOKEN; do
        eval "val=\"\${$key_name:-}\""
        [ -z "$val" ] && continue
        if grep -q "^${key_name}=" "$PROJECT_DIR/.env.sensitive" 2>/dev/null; then
            sed_inplace "s|^${key_name}=.*|${key_name}=$val|" "$PROJECT_DIR/.env.sensitive" || true
        else
            echo "${key_name}=$val" >> "$PROJECT_DIR/.env.sensitive"
        fi
    done

    set -e
}
