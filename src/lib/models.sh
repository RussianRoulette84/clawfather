#!/bin/bash

# --- API & Model Management for Clawfather ---

# API Key Scanner
scan_for_key() {
    local key_name="$1"
    local env_file="${2:-}"
    local found_key=""
    local source_file=""

    [ -z "$env_file" ] || [ ! -f "$env_file" ] && return

    local match
    match=$(grep -E "^${key_name}=.+" "$env_file" 2>/dev/null | tail -n 1 | sed "s/^${key_name}=//")
    if [ -n "$match" ]; then
        found_key="$match"
        source_file="$env_file"
    fi

    if [ -n "$found_key" ]; then
        printf "%s|%s" "$found_key" "$source_file"
    fi
}

# Ollama Model Puller
check_and_pull() {
    local MODEL_NAME=$1
    if ollama list | grep -q "$MODEL_NAME"; then
        success "$MODEL_NAME"
    else
        warn "$MODEL_NAME (Downloading...)"
        ollama pull "$MODEL_NAME"
        success "$MODEL_NAME"
    fi
}

# API Key Validation helper
is_valid_key() {
    local key="$1"
    if [[ -z "$key" ]] || [[ "$key" == *"your_"* ]] || [[ "$key" == *"xxx"* ]]; then
        return 1
    fi
    return 0
}

# Functional Smoke Test (Live Inference) — single hardcoded model (backward compatible)
verify_model_health() {
    verify_local_models_health "ollama/glm-4.7-flash:latest"
}

# Extract Ollama model name from provider/model (e.g. ollama/glm-4.7-flash -> glm-4.7-flash, add :latest if no tag)
ollama_model_id() {
    local prov_model="$1"
    if [[ "$prov_model" != ollama/* ]]; then
        echo ""
        return
    fi
    local name="${prov_model#ollama/}"
    [[ "$name" == *:* ]] || name="${name}:latest"
    echo "$name"
}

# Verify/pull/smoke-test a list of ollama models (provider/model format). TUI_PREFIX and success/info/warn available.
verify_local_models_health() {
    local models=("$@")
    local ollama_models=()
    local m
    for m in "${models[@]}"; do
        [ -z "$m" ] && continue
        [[ "$m" != ollama/* ]] && continue
        ollama_models+=("$m")
    done
    [ ${#ollama_models[@]} -eq 0 ] && return 0

    info "Verifying local AI Models..."
    # Check Ollama service
    if ! pgrep -x "ollama" > /dev/null && ! pgrep -f "ollama serve" > /dev/null; then
        warn "Ollama is not running. Attempting to start..."
        if command -v brew &>/dev/null; then
            brew services start ollama 2>/dev/null || true
        elif command -v systemctl &>/dev/null; then
            sudo systemctl start ollama 2>/dev/null || true
        else
            ollama serve >/dev/null 2>&1 &
        fi
        sleep 3
    fi

    local id
    for m in "${ollama_models[@]}"; do
        id=$(ollama_model_id "$m")
        [ -z "$id" ] && continue
        check_and_pull "$id"
    done

    local all_ok=true
    for m in "${ollama_models[@]}"; do
        id=$(ollama_model_id "$m")
        [ -z "$id" ] && continue
        info "Running ${id} smoke test..."
        if curl -s -o /dev/null -w "%{http_code}" -d "{\"model\": \"${id}\", \"prompt\": \"hi\", \"stream\": false}" http://localhost:11434/api/generate | grep -q "200"; then
            success "${id}"
            # Tool capability: required for OpenClaw agentic loop
            if ollama show "$id" 2>/dev/null | grep -qE '^\s+tools\s*$'; then
                success "Tool capability: OK"
            else
                warn "Tool capability: WARN (model may not support tool/function calling)"
            fi
        else
            warn "Smoke test failed: ${id}"
            all_ok=false
        fi
    done
    if [ "$all_ok" = true ]; then
        success "All LLMs are responding!"
    else
        warn "Some local LLM smoke tests failed. Check: ollama list, ollama serve"
    fi
}
