USEFULL COMMANDS
==================
node dist/index.js onboard --install-daemon
node dist/index.js --config

deepseek setup
===============
node dist/index.js config set models.providers.ollama --json "{\"api\": \"openai-completions\", \"baseUrl\": \"http://host.docker.internal:11434/v1\", \"apiKey\": \"ollama-local\", \"models\": [{\"id\": \"glm-4.7-flash:latest\", \"name\": \"GLM 4,7 Flash\"}]}"
node dist/index.js config set agents.defaults.model --json "{\"primary\": \"ollama/glm-4.7-flash:latest\", \"fallbacks\": []}"
node dist/index.js models status --probe
node dist/index.js models list
node dist/index.js agents list
node dist/index.js agent --agent main --message "hello china"

Options:
  --workspace <dir>              Agent workspace directory (default:
                                 ~/.openclaw/workspace)
  --reset                        Reset config + credentials + sessions +
                                 workspace before running wizard
  --non-interactive              Run without prompts (default: false)
  --accept-risk                  Acknowledge that agents are powerful and full
                                 system access is risky (required for
                                 --non-interactive) (default: false)
  --flow <flow>                  Wizard flow: quickstart|advanced|manual
  --mode <mode>                  Wizard mode: local|remote
  --auth-choice <choice>         Auth:
                                 setup-token|token|chutes|openai-codex|openai-api-key|openrouter-api-key|ai-gateway-api-key|moonshot-api-key|kimi-code-api-key|synthetic-api-key|venice-api-key|gemini-api-key|zai-api-key|xiaomi-api-key|apiKey|minimax-api|minimax-api-lightning|opencode-zen|skip
  --token-provider <id>          Token provider id (non-interactive; used with
                                 --auth-choice token)
  --token <token>                Token value (non-interactive; used with
                                 --auth-choice token)
  --token-profile-id <id>        Auth profile id (non-interactive; default:
                                 <provider>:manual)
  --token-expires-in <duration>  Optional token expiry duration (e.g. 365d, 12h)
  --anthropic-api-key <key>      Anthropic API key
  --openai-api-key <key>         OpenAI API key
  --openrouter-api-key <key>     OpenRouter API key
  --ai-gateway-api-key <key>     Vercel AI Gateway API key
  --moonshot-api-key <key>       Moonshot API key
  --kimi-code-api-key <key>      Kimi Coding API key     
  --gemini-api-key <key>         Gemini API key
  --zai-api-key <key>            Z.AI API key
  --xiaomi-api-key <key>         Xiaomi API key
  --minimax-api-key <key>        MiniMax API key
  --synthetic-api-key <key>      Synthetic API key
  --venice-api-key <key>         Venice API key
  --opencode-zen-api-key <key>   OpenCode Zen API key
  --gateway-port <port>          Gateway port
  --gateway-bind <mode>          Gateway bind: loopback|tailnet|lan|auto|custom
  --gateway-auth <mode>          Gateway auth: token|password
  --gateway-token <token>        Gateway token (token auth)
  --gateway-password <password>  Gateway password (password auth)
  --remote-url <url>             Remote Gateway WebSocket URL
  --remote-token <token>         Remote Gateway token (optional)
  --tailscale <mode>             Tailscale: off|serve|funnel
  --tailscale-reset-on-exit      Reset tailscale serve/funnel on exit
  --install-daemon               Install gateway service
  --no-install-daemon            Skip gateway service install
  --skip-daemon                  Skip gateway service install
  --daemon-runtime <runtime>     Daemon runtime: node|bun
  --skip-channels                Skip channel setup
  --skip-skills                  Skip skills setup
  --skip-health                  Skip health check
  --skip-ui                      Skip Control UI/TUI prompts
  --node-manager <name>          Node manager for skills: npm|pnpm|bun
  --json                         Output JSON summary (default: false)
  -h, --help                     display help for command

Docs: https://docs.openclaw.ai/cli/onboard
