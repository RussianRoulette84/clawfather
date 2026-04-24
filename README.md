![Version](https://img.shields.io/badge/Version-v1.2-blue?style=for-the-badge)
![Security First](https://img.shields.io/badge/Security-First-8A2BE2?style=for-the-badge&logo=lock&logoColor=white)
![Shell Script](https://img.shields.io/badge/Shell_Script-Automated-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Curated Skills](https://img.shields.io/badge/Skills-Curated-blue?style=for-the-badge)
![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![OpenClaw](https://img.shields.io/badge/OpenClaw-Install-6B7280?style=for-the-badge)
![License](https://img.shields.io/badge/License-Free_to_use-brightgreen?style=for-the-badge)

![Logo](logo.png)

---

# About

ClawFather is an **easy**, **secure**, and **customizable** way to install OpenClaw inside Docker using a wizard.

**WHY**: Becasue OpenClaw is an awesome tool BUT I'm not ready yet for AI to read & install shit around my macOS :D

*“It’s not personal. It’s strictly business.”*

**CLAWFATHER PHILOSOPHY**

> A docker setup that avoids full system access to your macOS  
> **WHILE**  
> preserving as much as possible of the cool features


# Install

Run this in terminal:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/RussianRoulette84/clawfather/master/install.sh)
```

And it will do EVERYTHING with tons of options to pick from ;)



# Demo
![Demo](screenshots/playback.gif)


# Features
- **Setup wizard**: an easy/secure/customizable way to install OpenClaw inside Docker
- **Folder Mirroring**: two-way persistant storage between Docker and macOS
  | From | To | Description |
  |------|----|-------------|
  | **macOS/Linux** | **Docker** | "Projects" folder mirrored into Docker workspace (optionally) |
  | **Docker** | **macOS/Linux** | 'workspace' folder mirrored into your macOS |
- **Range of Docker images/builds to select**:
  | Image       | Security | Notes | Problems | User | Risks
  |-------------|----------|-------|----------|------|--
  | clawfather  | ⭐⭐⭐⭐ | Pre-packed with all the goodies | none :) | - `root` (only) | - `no-new-privileges` disabled<br>- cap_add(CHOWN/SETGID/SETUID/DAC_OVERRIDE)
  | fourplayers | ⭐⭐⭐⭐ | Image extended with Dockerfile | none :) | - `root` (only) | - `no-new-privileges` disabled<br>- cap_add(CHOWN/SETGID/SETUID/DAC_OVERRIDE)
  | alpine      | ⭐⭐⭐⭐⭐ | Slim (50MB) alpine image only | no apt/pip install | - `node` (default)<br>- `root` (optional) | none :)
  | phioranex   | ⭐⭐⭐⭐ | [UNTESTED] | |
  | coollabsio  | ⭐⭐⭐ | [UNTESTED] | |
  | 1panel      | ⭐⭐⭐ | [UNTESTED] | |
- **Internet Browsing in Docker**: Fully supported! Order pizza, make screenshots, defeat bot-detectors and battele JS heavy websites!
  - **headful browsing** with system Chromium, optionally with noVNC + Fluxbox for live viewing
  - **headless browsing** with Playwright

  
- **Easy Pairing process**: so that no one (even with token) can talk to your OpenClaw
- **Skills**: Hand picked collection from clawhub.ai with `sync_skills.sh` which downloads skills inside  [CLAWHUB_SKILLS.md](./skills/CLAWHUB_SKILLS.md)
- **Guides**: [Pre-install](docs/01-pre_install/00-TABLE-OF-CONTENTS.md) · [Post-install](docs/02-post_install/00-TABLE-OF_CONTENTS.md) · [OpenClaw Reference](docs/03-openclaw_cli/00-TABLE-OF-CONTENTS.md) · [Bonus](docs/04-bonus/00-TABLE-OF-CONTENTS.md)
- **Pre-configured with 3 agents (general/light/heavy)**:
  Fine-tuned model and agent selection for different use cases. Keeps costs low.
- **Local LLM support**: pre-configures Docker to work with Ollama, installs everything needed. **DANGER**: pront injections loves weak LLMs!!
- **OpenClaw Bridge**: lightweight bridge for Docker → macOS enabled by default




# Notes

Setup does not include channel configuration; you must configure channels yourself.

Please at least read this before installing OpenClaw: [01-security-risks.md](docs/01-pre_install/01-security-risks.md)
Why? So that you don't fuck up. From there, you are on your own my friend.

**Please don't create Skynets or Molt churches. Use Asimov's laws as a guide. And always be careful with API keys!**


# Security Toggles

  - **Sandbox Mode**: restricts agent file access to the workspace folder only
  - **Safe Mode**: blocks destructive commands unless you approve them manually
  - **OpenClaw Bridge (Host Access)**: allows container to reach Ollama, bridges, and host services
  - **Browser Control**: lets the agent drive a browser for web automation
  - **Tools Elevated**: enables elevated host exec and high-privilege tools
  - **Hooks**: enables gateway hooks for automation and custom event handling
  - **No New Privileges**: prevents process privilege escalation (hardens container)
  - **Offline Mode**: disconnects the container from all networks (air-gapped)
  - **Paranoid Mode (cap_drop)**: drops all Linux capabilities for maximum container isolation
  - **Auto-Start Docker**: restarts the container automatically after system reboot
  - **Read-Only Mounts**: protects the skills folder from agent modification
  - **Root Mode**: runs container as root 
  - **God Mode**: grants agent control over the Docker socket to manage other containers


# Browsing

You can browse the internet and order pizza from Docker using "headful" or "headless" methods of running chromium
- **headful browsing**: you see wtf is going on with noVPN + fluxbox (lightwight window manager)
- **headless browsing**: you don't. used primeraly fro tasks, like ordering pizza

| Feature  | Source                                    | Usage                                              | Path                                                                 |
| -------- | ----------------------------------------- | -------------------------------------------------- | -------------------------------------------------------------------- |
| Headful  | apt-get (chromium, xvfb, fluxbox, dbus, x11vnc, novnc, websockify, fonts, libatk, ffmpeg, imagemagick, build-essential) + HTTP_PROXY | 🌐 Manual browsing, view session via noVNC         | http://localhost:7007/vnc.html?host=localhost&port=7007              |
| Headless | npx (Playwright) + apt-get (chromium-headless-shell) | 🍕 Pizza automation, 📸 Screenshots (no display) | /home/node/.cache/ms-playwright/chromium-1208/chrome-linux64/chrome, /usr/bin/chromium-headless-shell |


### JS / Anti-Bot / Cookie Techniques

| Technique                                                             | Headless | Headful |
| --------------------------------------------------------------------- | -------- | ------- |
| Basic anti-bot flags (AutomationControlled, --no-sandbox)             | ✅       | ✅      |
| Realistic user-agent                                                  | ✅       | ✅      |
| 1920×1080 viewport                                                    | ✅       | ✅      |
| navigator.webdriver = false                                           | ✅       | ✅      |
| Language/accept headers                                               | ✅       | ✅      |
| Smart JS content detection (waitForFunction)                          | ✅       | ✅      |
| Mocked plugins                                                        | ✅       | ✅      |
| Mocked window.chrome object                                           | ✅       | ✅      |
| Mocked permissions API                                                | ✅       | ✅      |
| Screen properties override                                            | ✅       | ✅      |
| Advanced sec-headers (sec-ch-ua, sec-fetch-*)                         | ✅       | ✅      |
| Used networkidle0                                                     | ✅       | ✅      |
| Cookie OK button click                                                | ✅       | ✅      |
| Persistent browser profile, cache, cookies (mirrored with Docker)     | ✅       | ✅      |


### Packages added

| Item                              | Source | Version                      | Needed for            |
| --------------------------------- | ------ | ---------------------------- | --------------------- |
| build-essential                   | apt    | 12.9                         | Build awsome stuff    |
| ffmpeg                            | apt    | 7:5.1.8-0+deb12u1            | Media                 |
| imagemagick                       | apt    | 8:6.9.11.60+dfsg-1.6+deb12u6  | Media                 |
| chromium-headless-shell           | apt    | 145.0.7632.75                | Browsing headless     |
| chromium                          | apt    | 145.0.7632.75                | Browsing headful      |
| fonts-liberation                  | apt    | 1:1.07.4-11                  | Browsing headful      |
| fonts-noto-color-emoji           | apt    | 2.042-0+deb12u1              | Browsing headful      |
| libatk-bridge2.0-0                | apt    | 2.46.0-5                     | Browsing headful      |
| dbus                              | apt    | 1.14.10-1~deb12u1            | Browsing headful noVNC |
| xvfb                              | apt    | 2:21.1.7-3+deb12u11          | Browsing headful noVNC |
| x11vnc                            | apt    | 0.9.16-9                     | Browsing headful noVNC |
| novnc                             | apt    | 1:3.0-1                      | Browsing headful noVNC |
| websockify                        | apt    | 0.10.0+dfsg1-4+b1            | Browsing headful noVNC |
| fluxbox                           | apt    | 1.3.5-2.1                    | Window manager + Browsing headful noVNC |
| openclaw                          | npm    | latest                       | CLI + Gateway         |
| playwright                        | npm    | latest                       | Browsing headless     |
| @playwright/test                  | npm    | latest                       | Browsing headless     |
| @vector-im/matrix-bot-sdk         | npm    | 0.8.0-element.3              | Matrix channel        |
| @matrix-org/matrix-sdk-crypto-nodejs | npm | 0.4.0                        | Matrix channel        |
| markdown-it                       | npm    | 14.1.1                       | Matrix channel        |
| music-metadata                    | npm    | 11.12.0                      | Matrix channel        |

### Cache & Components

| Component               | Location                                                     |
| ----------------------- | ------------------------------------------------------------ |
| Playwright CLI          | /usr/local/bin/playwright                                    |
| Playwright Library      | /usr/local/lib/node_modules/playwright/                      |
| Chromium Browsers       | /home/node/.cache/ms-playwright/chromium-1208                |
| Chromium Headless Shell | /home/node/.cache/ms-playwright/chromium_headless_shell-1208 |
| FFmpeg (for Playwright) | /home/node/.cache/ms-playwright/ffmpeg-1011                  |

### Test Verified

Ran a Playwright test:
```javascript
  chromium.launch() → newPage() → goto('about:blank') → title() → close()
```

run `install_report.sh` inside docker:
| Test                              | Result                                        |
| --------------------------------- | --------------------------------------------- |
| chromium --version                | Working (145.0.7632.75)                        |
| chromium-headless-shell --version | Working (145.0.7632.75)                        |
| novnc_proxy                       | Available at /usr/share/novnc/utils/novnc_proxy |
| websockify                        | Available as /usr/bin/websockify               |



# Config layout
- **`.env`** (gitignored): Generated by install from `config.yaml` + merged `.env.sensitive`. Used by Docker. Use `docker compose up -d` directly (Play button works).
- **`.env.sensitive`** (gitignored): API keys, token, HATCH_INFO. Wizard writes here. Install merges into `.env`.
- **`config.yaml`**: Single config — models, gateway, workspace, docker, ollama, security. Wizard writes chosen values here. Used to prefill wizard on re-run.

# ENV variables lookup table

| Variable                   | Source         | Default                   | Description                                      |
| -------------------------- | -------------- | ------------------------- | ------------------------------------------------ |
| COMPOSE_PROJECT_NAME       | config → .env  | openclaw                  | Docker Compose project name                      |
| OPENCLAW_CONFIG_DIR        | config → .env  | ./.openclaw               | Host path to OpenClaw config                     |
| OPENCLAW_WORKSPACE_DIR     | config → .env  | ./.openclaw/workspace     | Host path to workspace                           |
| OPENCLAW_SKILLS_DIR        | config → .env  | ./.openclaw/skills        | Host path to skills                              |
| OPENCLAW_GATEWAY_PORT      | config → .env  | 18789                     | Gateway WebSocket port                           |
| OPENCLAW_BRIDGE_PORT       | config → .env  | 18790                     | Bridge port                                      |
| OPENCLAW_GATEWAY_BIND      | config → .env  | lan                       | Gateway bind address                             |
| OPENCLAW_GATEWAY_CMD       | config → .env  | openclaw                  | Gateway command (openclaw or node dist/index.js) |
| OPENCLAW_USER              | config → .env  | node                      | Container user (root for fourplayers)            |
| OPENCLAW_IMAGE             | config → .env  | fourplayers/openclaw:latest | CLI image                                      |
| OPENCLAW_DOCKER_BASE       | config → .env  | /home/node/.openclaw      | Container path for config mount                  |
| OPENCLAW_DOCKER_WORKSPACE  | config → .env  | /home/node/.openclaw/workspace | Container workspace path                    |
| OPENCLAW_DOCKER_HOME       | config → .env  | /home/node                | Container HOME                                   |
| OPENCLAW_NETWORK_MODE      | config → .env  | bridge                    | bridge, host, or none                            |
| OPENCLAW_SERVICE_MANAGER   | config → .env  | none                      | Service manager inside container                 |
| OPENCLAW_NO_SERVICE        | config → .env  | true                      | Disable OpenClaw service manager                 |
| MIRROR_PROJECTS            | config → .env  | —                         | Mount host projects into container               |
| LOCAL_PROJECTS_DIR         | config → .env  | —                         | Host path to projects (when mirror)              |
| DOCKER_PROJECTS_PATH       | config → .env  | —                         | Container path for mounted projects              |
| NOVNC_PORT                 | config → .env  | 7007                      | noVNC web port                                   |
| SANDBOX_MODE               | config → .env  | true                      | Restrict file access to workspace                |
| SAFE_MODE                  | config → .env  | true                      | Require manual verification for destructive cmds |
| GOD_MODE                   | config → .env  | false                     | Grant Docker socket access                       |
| OLLAMA_BASE_URL            | .env.sensitive | —                         | Ollama API URL (empty = cloud-only)              |
| OLLAMA_API_KEY             | .env.sensitive | —                         | Ollama API key                                   |
| OPENCLAW_GATEWAY_TOKEN     | .env.sensitive | —                         | Gateway auth token (generated if empty)          |
| ZAI_API_KEY                | .env.sensitive | —                         | ZAI cloud model API key                          |
| ANTHROPIC_API_KEY          | .env.sensitive | —                         | Anthropic API key                                |
| GEMINI_API_KEY             | .env.sensitive | —                         | Google Gemini API key                            |
| HATCH_INFO                 | .env.sensitive | —                         | Prefilled hatch message / persona                |



# Guides — Table of Contents

| Doc Set | Entry |
|---------|-------|
| **Pre-install** | [00-TABLE-OF-CONTENTS](docs/01-pre_install/00-TABLE-OF-CONTENTS.md) · [Post-install](docs/02-post_install/00-TABLE-OF_CONTENTS.md) · [OpenClaw](docs/03-openclaw_cli/00-TABLE-OF-CONTENTS.md) |
| **Post-install** | [00-TABLE-OF-CONTENTS](docs/02-post_install/00-TABLE-OF_CONTENTS.md) · [README](docs/02-post_install/README.md) |
| **OpenClaw** | [00-TABLE-OF-CONTENTS](docs/03-openclaw_cli/00-TABLE-OF-CONTENTS.md) |
| **Bonus** | [Use cases & monetization](docs/04-bonus/00-use-cases-and-monetization.md) · [Top 30 time-saving skills](docs/04-bonus/01-ways-to-save-time.md) |

## Pre-install (10 guides)

| # | Guide | Description |
|---|-------|-------------|
| 01 | [Security Risks](docs/01-pre_install/01-security-risks.md) | Threat model, API keys, bridge exposure |
| 02 | [Security Pre-Install](docs/01-pre_install/02-security-pre-install.md) | Environment hardening, firewall, secrets |
| 03 | [Cost Estimations](docs/01-pre_install/03-cost-estimations.md) | API costs, model pricing, usage estimates |
| 04 | [Docker vs Local](docs/01-pre_install/04-docker-vs-local.md) | Trade-offs, isolation, host access |
| 05 | [Bridge Options](docs/01-pre_install/05-bridge-options.md) | OpenClaw Bridge, Keyboard Maestro, host commands |
| 06 | [OpenClaw Readme](docs/01-pre_install/06-openclaw-readme.md) | Architecture, apps, official docs |
| 07 | [Manual Install](docs/01-pre_install/07-manual-install.md) | Docker setup, multi-model, hardening |
| 08 | [Docker Image Comparison](docs/01-pre_install/08-docker-image-comparison.md) | Image variants, sizes, tags |
| 09 | [Dashboard & Assistant Troubleshooting](docs/01-pre_install/09-dashboard-and-assistant-troubleshooting.md) | Startup issues, UI, debugging |
| 10 | [Security Post-Install](docs/01-pre_install/10-security-post-install.md) | → redirects to post-install |

## Bonus

| # | Guide | Description |
|---|-------|-------------|
| 00 | [Use Cases & Monetization](docs/04-bonus/00-use-cases-and-monetization.md) | Ideas, earning, integrations |
| 01 | [Ways to Save Time](docs/04-bonus/01-ways-to-save-time.md) | Top 30 time-saving OpenClaw skills |

## Post-install (33 guides)

| # | Guide | Description |
|---|-------|-------------|
| 01 | [Security Post-Install](docs/02-post_install/01-security-post-install.md) | Bridge audit, Docker hardening, skill scanner, log review |
| 02 | [Cron Jobs](docs/02-post_install/02-cron-jobs.md) | Scheduled tasks, reminders, morning briefings |
| 03 | [Heartbeat Builder](docs/02-post_install/03-heartbeat-builder.md) | Periodic checks via HEARTBEAT.md |
| 04 | [Session Reset Rules](docs/02-post_install/04-session-reset-rules.md) | Idle timeout, daily reset, custom triggers |
| 05 | [WhatsApp](docs/02-post_install/05-channels-whatsapp.md) | Chat via Baileys with allowlist & pairing |
| 06 | [Telegram](docs/02-post_install/06-channels-telegram.md) | Bot in DMs and groups |
| 07 | [Discord](docs/02-post_install/07-channels-discord.md) | Bot in guilds and DMs |
| 08 | [Slack](docs/02-post_install/08-channels-slack.md) | Bot in channels, slash commands |
| 09 | [Matrix](docs/02-post_install/09-channels-matrix.md) | E2EE rooms via plugin |
| 10 | [Secure DM Mode](docs/02-post_install/10-secure-dm-mode.md) | Per-user session isolation |
| 11 | [Webhook Presets](docs/02-post_install/11-webhook-presets.md) | Gmail, GitHub, custom wake/agent webhooks |
| 12 | [Identity Wizard](docs/02-post_install/12-identity-wizard.md) | Name, theme, emoji, avatar |
| 13 | [Boot Personas](docs/02-post_install/13-boot-personas.md) | BOOT.md startup instructions |
| 14 | [Message Formatting](docs/02-post_install/14-message-formatting.md) | Prefixes, reactions, typing indicators |
| 15 | [OpenClaw Bridge](docs/02-post_install/15-openclaw-bridge.md) | HTTP server, AppleScript, host commands |
| 16 | [macOS Docker Setup](docs/02-post_install/16-macos-docker-setup.md) | Security-focused Docker options |
| 17 | [Keyboard Maestro](docs/02-post_install/17-keyboard-maestro-macos.md) | KM Web Server, macros, auth |
| 18 | [macOS Skills](docs/02-post_install/18-macos-skills.md) | peekaboo, apple-mail, accli, etc. |
| 19 | [Tool Allowlist](docs/02-post_install/19-tool-allowlist.md) | Control exec, read, write, elevated |
| 20 | [Sandbox Options](docs/02-post_install/20-sandbox-options.md) | Workspace restriction, Docker sandbox |
| 21 | [Media & Transcription](docs/02-post_install/21-media-transcription.md) | Audio/video transcription (Whisper, Gemini) |
| 22 | [Model Role Routing](docs/02-post_install/22-model-role-routing.md) | General, light, heavy model routing |
| 23 | [Custom Provider](docs/02-post_install/23-custom-provider.md) | LiteLLM, self-hosted models |
| 24 | [Tailscale Setup](docs/02-post_install/24-tailscale-setup.md) | Serve, Funnel for remote access |
| 25 | [Remote Gateway](docs/02-post_install/25-remote-gateway.md) | Connect clients to remote gateway |
| 26 | [Discovery mDNS](docs/02-post_install/26-discovery-mdns.md) | LAN discovery |
| 27 | [Logging Config](docs/02-post_install/27-logging-config.md) | Level, file, redaction |
| 28 | [Background Exec](docs/02-post_install/28-background-exec.md) | Long-running commands |
| 29 | [Health & Doctor](docs/02-post_install/29-health-doctor.md) | doctor, security audit commands |
| 30 | [Memory Search](docs/02-post_install/30-memory-search.md) | Embeddings, RAG |
| 31 | [Queue & Routing](docs/02-post_install/31-queue-routing.md) | Batching, mention patterns |
| 32 | [Skill Quick-Install](docs/02-post_install/32-skill-quick-install.md) | Sync, clawhub, scanner |
| 33 | [Scheduled Backup](docs/02-post_install/33-scheduled-backup.md) | Config and skills backup automation |

## OpenClaw Reference (12 docs)

| # | Doc | Description |
|---|-----|-------------|
| 01 | [Configuration](docs/03-openclaw_cli/01-configuration.md) | Config file, paths, RPC apply/patch, key options |
| 02 | [Security](docs/03-openclaw_cli/02-security.md) | Audit, checklist, hardening, credential storage |
| 03 | [CLI Reference](docs/03-openclaw_cli/03-cli-reference.md) | Command tree, global flags, all CLI commands |
| 04 | [CLI config](docs/03-openclaw_cli/04-cli-config.md) | `config get/set/unset` — config by path |
| 05 | [CLI gateway](docs/03-openclaw_cli/05-cli-gateway.md) | `gateway run` — WebSocket server, channels, nodes |
| 06 | [CLI health](docs/03-openclaw_cli/06-cli-health.md) | `health` — gateway health probe |
| 07 | [CLI security](docs/03-openclaw_cli/07-cli-security.md) | `security audit` — config + state checks, fix |
| 08 | [CLI devices](docs/03-openclaw_cli/08-cli-devices.md) | `devices list/approve/reject` — pairing |
| 09 | [CLI models](docs/03-openclaw_cli/09-cli-models.md) | `models status/set/scan` — model discovery, auth |
| 10 | [CLI agent](docs/03-openclaw_cli/10-cli-agent.md) | `agent` — run one LLM turn |
| 11 | [CLI message](docs/03-openclaw_cli/11-cli-message.md) | `message send/poll/react` — channel ops (needs `--target`) |
| 12 | [RPC API](docs/03-openclaw_cli/12-rpc-api.md) | Gateway RPC, adapters, config.apply/patch |


### Skills included
```text
skills/
├── AI Security
│   ├── skill-scanner: Malware scanner for skills
│   ├── openclaw-security-hardening: Protect from prompt injection
│   ├── hivefence: Collective immunity network
│   └── ai-skill-scanner: Audit & scan skills
├── Managers
│   ├── agents-manager: Profile & route tasks
│   ├── agnxi-search-skill: Search AI tools directory
│   ├── clawhub: Install skills from chat
│   ├── clawdbot-skill-update: Backup & update workflow
│   ├── update-plus: Config & skill backups
│   ├── auto-updater: Daily auto-updates
│   ├── skills-search: Search skill registry
│   ├── skillcraft: Create & package skills
│   └── skillvet: Security scanner
├── Web Browsing
│   ├── browser-use: Cloud browser with profiles
│   └── browser-use-api: Cloud automation API
├── MCP
│   └── openclaw-mcp-plugin: Model Context Protocol
├── macOS
│   ├── peekaboo: Capture UI & automate
│   ├── homebrew: Manage packages & casks
│   ├── apple-mail: Read & send emails
│   ├── apple-mail-search-safe: Fast safe search
│   ├── accli (Calendar): Manage calendar events
│   ├── apple-reminders: Manage todo lists
│   ├── apple-photos: Search & view photos
│   ├── apple-music: Control playback & playlists
│   └── mac-tts: Text-to-speech
├── Smart Home
│   └── moltbot-ha: Control Home Assistant
├── Crawlers / Searchers
│   ├── exa-web-search-free: AI web & code search
│   ├── google-search: Custom Search Engine
│   ├── firecrawler: Scrape & extract data
│   ├── job-search-mcp-jobspy: Job aggregator
│   └── topic-monitor: Monitor topics & alerts
├── News
│   ├── clawnews: Aggregator & reader
│   ├── finance-news: Market briefings
│   ├── market-news-analyst: Impact analysis
│   ├── hn-digest: Hacker News digestion
│   ├── news-aggregator-skill: Multi-source aggregation
│   ├── hn: Browse Hacker News
│   └── news-summary: Daily briefings
├── YouTube
│   ├── yt-dlp-downloader-skill: Download videos
│   ├── youtube: Search & details
│   ├── youtube-summarizer: Transcripts & summaries
│   └── yt-video-downloader: Download formats
├── Crypto
│   ├── crypto-price: Token prices & charts
│   └── stock-analysis: Analyze assets
├── Polymarket
│   ├── polymarket: Check odds & markets
│   ├── polymarket-odds: Sports & politics odds
│   ├── polymarket-agent: Auto-trading agent
│   ├── polymarket-trading-bot: Trading bot for prediction markets.
│   ├── pm-odds: Query markets
│   ├── polymarket-api: API queries
│   ├── polymarket-analysis: Arbitrage & sentiment
│   ├── polymarket-all-in-one: All-in-one tool
│   ├── better-polymarket: Improved market tool
│   ├── polymarket-7ceau: Trade & analyze
│   ├── unifai-trading-suite: Prediction markets suite
│   ├── polymarket-trading: Trading operations
│   ├── reef-polymarket-arb: Arbitrage discovery
│   ├── alpha-finder: Market intelligence oracle
│   ├── polyclaw: Autonomous trader agent
│   ├── simmer: Trading arena
│   ├── clawstake: Agent prediction markets
│   ├── reef-polymarket-research: Research & direction
│   ├── simmer-copytrading: Mirror top traders
│   ├── test: Portfolio tracking
│   ├── onchain-test: Onchain portfolio
│   ├── simmer-weather: Weather markets
│   ├── simmer-signalsniper: Signal based trading
│   ├── prediction-markets-roarin: Roarin network betting
│   └── reef-paper-trader: Paper trading system
├── Coding
│   ├── roast-gen: Humorous code review
│   ├── code-roaster: Brutal code review
│   └── coding-agent-3nd: Coding & refactoring
├── Source Control
│   ├── github: Issues, PRs, runs
│   ├── glab-cli: GitLab CLI
│   ├── github-kb: Local KB & search
│   ├── gitclaw: Agent workspace backup
│   ├── gitlab-cli-skills: GitLab CLI wrapper
│   ├── git-sync: Sync local to remote
│   ├── github-pr: PR tool
│   ├── ai-ci: Generate CI pipelines
│   ├── github-mentions: Track mentions
│   └── gitflow: Monitor CI status
├── Server Monitoring & Security
│   ├── linux-service-triage: Diagnose issues
│   └── security-system-zf: Security ops
├── Memory & Persistence
│   └── penfield: Knowledge graphs
├── Productivity
│   ├── procrastination-buster: Task breakdown
│   ├── adhd-assistant: Life management
│   ├── proactive-agent: Anticipate needs
│   ├── todo: Task management
│   └── personas: AI personalities
├── Assistants
│   └── founder-coach: Startup mindset
└── Office
    └── caldav-calendar: Sync calendars
```

---
