#!/bin/bash

echo "🚀 Initializning Clawfather logs, browser config and cache..."

# Create logs directory
mkdir -p /home/node/.openclaw/logs

# PATCH: Ensure browser config points to Playwright Chrome
node /tmp/patch-browser-config.js

# SEED CACHE: If mounted volume is empty, copy Playwright files from image layers
if [ -z "$(ls -A /home/node/.cache)" ]; then
    echo "📦 Cache is empty, seeding from image layers..."
    
    if [ -d "/root/.cache/ms-playwright/chromium-1208/chrome-linux64" ]; then
        echo "📦 Found Playwright cache in /root/.cache, copying to mount..."
        cp -r /root/.cache/ms-playwright /home/node/.cache/
        chown -R node:node /home/node/.cache
        echo "✅ Cache seeded from image"
    else
        echo "⚠️ Playwright cache not found in image, run 'npx playwright install' manually"
    fi
else
    echo "✅ Cache is already populated"
fi
