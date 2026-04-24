# OpenClaw Docker Image Comparison

## Base Image Quick Reference

When building custom images or choosing a base, these common Debian/Node variants differ significantly. Prefer explicit `node:X-bookworm` over bare `node:X`—the latter uses Docker's default OS (currently Bookworm) and can change when a new Debian becomes standard.

| Feature | debian:bookworm-slim | debian:bookworm | node:22-bookworm-slim | node:24-bookworm-slim | node:22-bookworm | node:24-bookworm |
| :------ | :------------------: | :------------: | :-------------------: | :-------------------: | :--------------: | :--------------: |
| **Image size** | ~75 MB | ~120 MB | ~280 MB | ~280 MB | ~1.1 GB | ~1.1 GB |
| **Node.js** | ❌ | ❌ | ✅ v22 | ✅ v24 | ✅ v22 | ✅ v24 |
| **npm / npx** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **yarn** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Python3** | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| **apt** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Man pages** | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| **Locales** | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| **tzdata** | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| **Build essentials** | ❌ | Some | Some | Some | ✅ | ✅ |
| **Good for production** | ✅ | ❌ | ✅ | ✅ | ❌ | ❌ |
| **Good for dev/debugging** | Needs setup | ✅ | Needs setup | Needs setup | ✅ | ✅ |
| **Best used when** | Lean custom builds | General base | Node 22, lean prod | Node 24, lean prod | Node 22, full comfort | Node 24, full comfort |

### Root vs Node User

Same image, different runtime user—a critical security and usability tradeoff:

| Feature | node:24 as root | node:24 as node user |
| :------ | :-------------: | :-------------------: |
| **Default user** | root (uid 0) | node (uid 1000) |
| **File permissions** | Full access to everything | Limited to own files |
| **Security risk** | High — container escape = host root | Low — limited blast radius |
| **npm global install** | ✅ works freely | ❌ needs sudo or `--prefix` workaround |
| **apt-get install** | ✅ works freely | ❌ needs sudo |
| **Write anywhere in container** | ✅ | ❌ restricted |
| **Production safe** | ❌ bad practice | ✅ recommended |
| **Docker best practice** | ❌ violates least privilege | ✅ follows least privilege |
| **CVE / vulnerability impact** | Critical — attacker gets root | Contained — attacker gets unprivileged user |
| **Volume mount issues** | Rarely | Sometimes — host file ownership can mismatch |
| **Good for vibe coding / dev** | ✅ frictionless | ⚠️ can be annoying |
| **Good for production** | ❌ | ✅ |

---

## Official & Popular Images

---

### `alpine/openclaw`

**Docker Hub:** [alpine/openclaw](https://hub.docker.com/r/alpine/openclaw)

| Feature | Details |
|---------|---------|
| **Size** | ~1–1.3 GB (Debian-based despite name, see base table) |
| **Last Updated** | 2026.1.30 |
| **Maintenance** | Active |
| **Configuration** | Manual |
| **Security** | Standard |
| **Setup** | Manual configuration required |
| **Best For** | Users familiar with Alpine/Debian |

**Pros:**
- Intended to be lightweight (Alpine-based)
- Tagged with version numbers (2026.1.30)

**Cons:**
- **Currently built on Debian** (not Alpine) due to musl library compatibility issues
- Misleading name (says Alpine but uses Debian)
- Older update compared to fourplayers

---

### `fourplayers/openclaw`

**Docker Hub:** [fourplayers/openclaw](https://hub.docker.com/r/fourplayers/openclaw)

| Feature | Details |
|---------|---------|
| **Size** | 1.3 GB |
| **Last Updated** | ~2 hours ago (as of Feb 3, 2026) |
| **Maintenance** | ✅ Actively maintained |
| **Configuration** | ✅ Zero-config startup |
| **Security** | ✅ HTTPS support built-in |
| **Setup** | ✅ Auto-configuration on first run |
| **Best For** | Production use, quick setup, security-conscious deployments |

**Pros:**
- Ready-to-run with no complex setup
- Most recently updated (active development)
- HTTPS support for secure bridge connections
- Auto-configuration reduces setup errors
- Well-suited for custom configurations (like Clawfather)

**Cons:**
- Larger size (1.3 GB)

**Clawfather behaviour:** When you select this image, Root Mode is **auto-enabled** and **hidden** from the Security checklist (the image requires root for its entrypoint). You see one fewer security toggle.

---

### `ghcr.io/phioranex/openclaw-docker`

**GitHub:** [phioranex/openclaw-docker](https://github.com/phioranex/openclaw-docker)

| Feature | Details |
|---------|---------|
| **Size** | ~1–1.3 GB (node base + OpenClaw, similar to fourplayers) |
| **Last Updated** | Daily automated builds |
| **Maintenance** | ✅ Automated (checks every 6 hours) |
| **Configuration** | Manual |
| **Security** | Standard |
| **Setup** | Manual configuration required |
| **Best For** | Users who want bleeding-edge updates |

**Pros:**
- Automatically builds daily
- Checks for new OpenClaw releases every 6 hours
- Always up-to-date with latest OpenClaw version
- GitHub Container Registry (good for CI/CD)

**Cons:**
- Requires manual configuration
- Less documentation than fourplayers
- May include unstable features

---

### `coollabsio/openclaw`

**Provider:** Coolify/Coolabs

| Feature | Details |
|---------|---------|
| **Size** | ~1.2–1.5 GB (includes nginx proxy) |
| **Last Updated** | Community-sourced; check Docker Hub |
| **Maintenance** | Community maintained |
| **Configuration** | Environment-based |
| **Security** | ✅ Nginx proxy included |
| **Setup** | Automated with environment variables |
| **Best For** | Coolify platform users, nginx proxy setups |

**Pros:**
- Fully featured with nginx proxy
- Environment-based configuration (good for Docker Compose)
- Designed for Coolify platform integration

**Cons:**
- May be overkill if you don't need nginx proxy
- Less frequently updated than fourplayers

---

### `1panel/openclaw`

**Docker Hub:** [1panel/openclaw](https://hub.docker.com/r/1panel/openclaw)

| Feature | Details |
|---------|---------|
| **Size** | 1011.6 MB (~1 GB) |
| **Last Updated** | 1 day ago (as of Feb 3, 2026) |
| **Maintenance** | ✅ Actively maintained |
| **Configuration** | Manual |
| **Security** | Standard |
| **Setup** | Manual configuration required |
| **Best For** | 1Panel platform users |

**Pros:**
- Smaller size than fourplayers
- Recently updated
- Optimized for 1Panel management platform

**Cons:**
- Designed for 1Panel ecosystem
- May not work well outside 1Panel
- Less documentation for standalone use

## Sandbox Images

OpenClaw uses specialized sandbox images for isolated code execution. These are typically used internally by OpenClaw and don't need to be specified in your `docker-compose.yml`.

### `openclaw-sandbox:bookworm-slim`

| Feature | Details |
|---------|---------|
| **Base** | Debian Bookworm Slim (~75 MB) |
| **Size** | ~75–100 MB |
| **Purpose** | Basic sandbox for code execution |
| **Includes** | Minimal runtime environment |
| **Best For** | Lightweight code execution |

---

### `openclaw-sandbox-common:bookworm-slim`

| Feature | Details |
|---------|---------|
| **Base** | Debian Bookworm Slim (~75 MB) |
| **Size** | ~500 MB–1 GB (Node, Go, Rust, build tools) |
| **Purpose** | Development sandbox |
| **Includes** | Node.js, Go, Rust, common build tools |
| **Best For** | Multi-language development tasks |

---

### `openclaw-sandbox-browser:bookworm-slim`

| Feature | Details |
|---------|---------|
| **Base** | Debian Bookworm Slim (~75 MB) |
| **Size** | ~800 MB–1.2 GB (Chromium-heavy) |
| **Purpose** | Browser automation sandbox |
| **Includes** | Chromium with Chrome DevTools Protocol (CDP) |
| **Best For** | Web scraping, browser automation, UI testing |

---

## Recommendation Matrix

| Use Case | Recommended Image | Why |
|----------|------------------|-----|
| **Production** | `fourplayers/openclaw` | Zero-config, HTTPS, actively maintained |
| **Bleeding Edge** | `ghcr.io/phioranex/openclaw-docker` | Daily builds, auto-updates |
| **Coolify Platform** | `coollabsio/openclaw` | Native Coolify integration |
| **1Panel Platform** | `1panel/openclaw` | Native 1Panel integration |
| **Smallest Size** | `1panel/openclaw` | 1 GB vs 1.3 GB |

---

## Clawfather Default

**Current:** `fourplayers/openclaw:latest`

This image is selected as the default for Clawfather because:
1. ✅ Zero-config startup works well with Clawfather's custom security settings
2. ✅ HTTPS support complements the OpenClaw Bridge
3. ✅ Most recently updated (active maintenance)
4. ✅ Auto-configuration reduces conflicts with custom volume mounts
5. ✅ Well-documented and community-tested

When this image is chosen, the installer automatically enables Root Mode and hides it from the Security step (fewer toggles).
