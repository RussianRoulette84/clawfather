const fs = require('fs');
const path = '/home/node/.openclaw/openclaw.json';
console.log('🔧 Patching browser config for Playwright Chrome...');

try {
  let config;

  if (fs.existsSync(path)) {
    config = JSON.parse(fs.readFileSync(path, 'utf8'));
    console.log('✅ Found existing config');
  } else {
    console.log('⚠️ Config not found, creating default...');
    config = {
      meta: {
        lastTouchedVersion: "2026.2.14",
        lastTouchedAt: new Date().toISOString()
      },
      browser: {
        enabled: true,
        color: "#FF4500",
        executablePath: "/home/node/.cache/ms-playwright/chromium-1208/chrome-linux64/chrome",
        headless: false,
        noSandbox: true,
        defaultProfile: "openclaw",
        profiles: {
          openclaw: {
            cdpPort: 18800,
            color: "#FF4500"
          }
        }
      }
    };
  }

  // CRITICAL: Update to Playwright Chrome path (for automation & screenshots)
  config.browser.executablePath = '/home/node/.cache/ms-playwright/chromium-1208/chrome-linux64/chrome';
  
  fs.writeFileSync(path, JSON.stringify(config, null, 2));
  console.log('✅ Config patched: executablePath = Playwright Chrome');
  
} catch (error) {
  console.error('❌ Patch failed:', error.message);
  process.exit(1);
}