# AGENTS.md

## Clawfather Project Policies
- **fourplayers/openclaw runs as root only:** The fourplayers/openclaw Docker image must run with `user: root`. Its entrypoint uses `runuser -u node`, which requires root; running as node causes "runuser: may not be used by non-root users".
- **Paths for host machines:** Don't use full paths (e.g. `/Users/username/Projects/`) when displaying paths to the user in terminal. Use home-relative format instead: `~/Projects/`.
- **Debug Command visible:** While executing install_clawfather.sh (or root install.sh) -> Before running any setup step (install wizard, docker exec, npm install, onboard wizard, etc.), print the **exact real command** that will be run so the user can reproduce or debug it. Format: `│  [DEBUG] Debug Command: <full command>`. **Never cheat:** show the full invocation (e.g. `docker compose run --rm -T --entrypoint openclaw -e HOME=... openclaw-cli config set ...` or `docker exec ... /bin/sh -c "..."`), never a shortened or "inner only" version (e.g. not just `openclaw config set ...`). Mask secrets (tokens, passwords) as `***` in the printed command. Use the `[DEBUG]` tag in orange; add new lines with nice tabbulation when printing long commands.
- **Debugging:** When something misbehaves, always read the logs first — use the **install directory** chosen by the wizard (shown as `Install dir:` in the installer summary, e.g. `~/.openclaw`) and inspect its `logs/` files (e.g. `logs/gateway.log`, `logs/openclaw.log`).


## Code Style & Conventions
- Imports
  - Place imports at module top; no imports inside functions.
  - Group: stdlib, third-party, local. Avoid unused imports.
  - Remove unused imports to keep linting clean.
- Formatting
  - **VERY IMPORTANT**: Keep files ~≤400 lines; split large modules logically. Do it when the time comes. NOTIFY USER with big **warning sign** that this will happen in next step.
- Organization
  - Keep functions small and single-purpose. Prefer composition.
  - Group related functions together in modules (for example, label-related helpers in the same file).
- Errors & Exceptions
  - Never swallow exceptions silently. Log and propagate appropriately.
- Comments
  - Stop spamming comments about design changes and change requests. If user requests code changes then do NOT add code comments about the changes made unless it's really important.
- Visual Output (CLI/UIs)
  - always welcome, with status labels, different text colors. I'm very visual. Rich console.
  - Color semantics when printing/logging to console:
    - [ERROR][EXCEPTION] messages: RED (high-visibility)
    - [WARN]Warning messages: YELLOW.
    - [INFO] Informational/success messages: GREEN or CYAN as appropriate.


## Policies
- `Ask` agent `no code policy` 
  - Try to avoid posting code implementation in response. Try to keep it short.
- Testing
  - Do not add pytest or other frameworks. Prefer smoke tests and tiny scripts under `scripts/`.
- Safety
  - Never commit secret files (e.g., `.env`) and make sure they are managed in `.gitignore` file when creating such files.
  - No SSH/SCP/remote edits; all edits are local to the workspace.
- Backward Compatibility
  - Refactors need not preserve deprecated behavior; assume users upgrade to supported releases.
- No-Silent-Fallback
  - Do NOT add silent fallback code paths that change behavior or mask missing files/conditions. Fallbacks are a major source of subtle bugs and hard-to-debug behavior.
- File Deletion Policy

    When deleting files or directories on host system, use macOS Trash instead of permanent deletion:

    - Use: `trash file1 file2 dir/`
    - Supports multiple files and directories in one command
    - Only use `/bin/rm` when explicitly told to permanently delete
    - Always ask for confirmation before deleting unless told otherwise

- Error/Warning Handling Policy

  **NEVER filter out warnings or errors as a solution.** Console filtering or silencing errors masks real problems and makes debugging impossible. Instead:

  - **Fix the root cause** - If warnings or errors appear, identify and resolve the underlying issue.
  - **Prevent the error** - Change code or configuration to stop the error from occurring in the first place.
  - **Document known third-party issues** - If the error comes from external libraries (like YouTube embed scripts), add inline comments explaining why it's acceptable (e.g., "YouTube embed always tries to fetch ads; ad-blockers refuse connection - expected behavior").
  - **Add proper error handling** - Wrap third-party code in try/catch blocks and handle failures gracefully instead of hiding them.

  **Do NOT:**
  - Add console filters to silence warnings
  - Suppress errors as a "solution" to a problem
  - Add silent catch blocks that ignore exceptions
  - Add flags like `NO_WARNINGS` or `QUIET` as a workaround


## Documentation & Fixtures
- Prefer concise, actionable docs. Avoid noisy or ambiguous comments about removed/disabled features.
- When updating `README.md` or files under `docs/`, insert or update the most relevant section rather than appending at the end.
- Add minimal fixtures under `docs/fixtures/` for Trello card examples to guide schema design.

## Communication Guidelines
- Keep communication concise and actionable.
- Be 70% less chatty by default: prefer short, single-paragraph or single-line actionable responses. When the user requests a command or a short change, return the exact commands or minimal edits only. Ask clarifying questions only when essential.


## install_clawfather.sh -y (non-interactive / default-accept)
- **When adding or changing wizard steps:** Always use the same TUI helpers—`ask_tui`, `ask_yes_no_tui`, `select_tui`, `ask_path_tui`, `checklist_tui`, `header_tui`, `header_tui_collapse`, `print_loading_header_tui`, `wait_for_condition_tui`—and pass the **displayed default** as you would for interactive use. The `-y` flow picks whatever is shown as the default (first option, default index, or default text)—**do not hardcode separate defaults for -y**.
- **Behavior:** `install.sh -y` or `src/install_clawfather.sh -y` runs the wizard visually the same as interactive, but selects the displayed default at each step (as if the user pressed only ENTER). Exceptions: **password** prompts always require real input; **Dashboard loaded?** is always interactive (install unsets `INSTALL_AUTO_YES` before the “Open this URL” block and restores it after the user confirms).
- **Reminder:** If you add a new question or change defaults, -y will use whatever default you pass to the TUI helper; add a comment in code if the step is security-sensitive or must stay interactive.


## ywizz library
- **TUI input — no ghost input, no extra newlines:** Use this technique in every widget that reads user input:
  1. **Start flush:** Before drawing the question, flush stdin (`while read -t 0.01 -r -n 10000 discard; do :; done`). Keys pressed before the question was drawn are discarded, so the question effectively “waits” for its own input (no accidental confirm from a buffered ENTER).
  2. **End flush:** After accepting the answer and before returning, flush stdin again. Extra keypresses (e.g. user hammering ENTER) are consumed so they don’t leak into the next prompt or echo as newlines.
  3. **No artificial delays:** Default `secure_enter_ms` is 0. Optional `secure_enter_ms` (e.g. 2000) can be passed for destructive prompts if you want a short “arm” time.
  4. **Line input (`ask_tui`):** `read -r` runs in cooked mode, so the terminal echoes ENTER as a newline and the cursor ends up one line lower. When collapsing to the answered view, move up **3** lines (`\033[3A`) so you overwrite the ◆ prompt line and the value line; then clear the leftover line (`\r\033[K`) so no duplicate ◇/◆ or blank line appears before the next question.
- **After a question was selected:** do NOT print unselected options in the final/summary view. Show only the selected option(s): for single-choice (`select_tui`) only the chosen line; for multi-choice (`checklist_tui`) only the checked items.
- **Diamonds — answered vs current:** Use **◇** (empty diamond) for answered questions/sections; use **◆** (full diamond) only for the current question/section. Never leave ◆ on a block that is already done.
- **Tree always connected — no newlines between steps:** Do NOT add blank lines before any `◇` section. The next question/block must follow immediately after the previous answer (no `printf '\n'` or connector line between steps). When `continuation=1` and more questions follow (`last_q=0`), do not print `TREE_CONNECTOR`; only print `TREE_BOT` when it's the last question. Apply in all ywizz widgets and any block that chains into the wizard (e.g. `style_security_warning`).


## Config layout
- **`.env`** (gitignored): Generated by install from `config.yaml` + merged `.env.sensitive`. Used by Docker. Use `docker compose up -d` directly (Play button works).
- **`.env.sensitive`** (gitignored): API keys, token, HATCH_INFO. Wizard writes here. Install merges into `.env`.
- **`config.yaml`**: Single config — models, gateway, workspace, docker, ollama, security. Wizard writes chosen values here. Used to prefill wizard on re-run.
- **`config.default.yaml`**: Backup of the original config. Do not touch!

### Connectivity
- **Ollama URL**: Always use `http://host.docker.internal:11434/v1` (the `/v1` is required) IF ollama was enabled during setup process 
- **Protocol**: Use `openai-completions` for R1 and `openai-responses` for tool-capable models (like Qwen).
