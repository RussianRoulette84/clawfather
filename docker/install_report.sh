#!/bin/bash

# install_report.sh - OpenClaw Browser Environment Installation Check
# Tests all browser-related packages and generates a status report

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Box drawing characters
H='─'
V='│'
TL='┌'
TR='┐'
BL='└'
BR='┘'
LM='├'
RM='┤'

# Helper functions
print_status() {
    local status=$1
    case $status in
        "✅") echo -e "${GREEN}${status}${NC}" ;;
        "❌") echo -e "${RED}${status}${NC}" ;;
        "⚠️") echo -e "${YELLOW}${status}${NC}" ;;
        *) echo "$status" ;;
    esac
}

check_package() {
    local pkg=$1
    if dpkg -l | grep -q "^ii  $pkg "; then
        local version=$(dpkg -l | grep "^ii  $pkg " | awk '{print $3}')
        echo "$(print_status "✅") $version"
        return 0
    else
        echo "$(print_status "❌") NOT INSTALLED"
        return 1
    fi
}

check_binary() {
    local bin=$1
    local test_cmd=$2
    if which "$bin" >/dev/null 2>&1; then
        if [ -n "$test_cmd" ]; then
            local result=$($test_cmd 2>&1 | head -1 || echo "Failed to execute")
            echo "$(print_status "✅") $result"
        else
            echo "$(print_status "✅") Available at $(which $bin)"
        fi
        return 0
    else
        echo "$(print_status "❌") NOT FOUND"
        return 1
    fi
}

check_dir() {
    local dir=$1
    local desc=$2
    if [ -d "$dir" ]; then
        local contents=$(ls -1 "$dir" 2>/dev/null | tr '\n' ' ' | head -c 80)
        echo "$(print_status "✅") $dir exists - $contents"
        return 0
    else
        echo "$(print_status "❌") $dir NOT FOUND"
        return 1
    fi
}

print_section() {
    echo ""
    echo -e "${BLUE}### $1 ###${NC}"
}

print_header() {
    local width=$1
    printf "${TL}"
    printf "%${width}s" | tr ' ' "$H"
    printf "${TR}\n"
}

print_row() {
    local col1=$1
    local col2=$2
    local col3=$3
    printf "${V} %-30s %-8s %-36s ${V}\n" "$col1" "$col2" "$col3"
}

print_separator() {
    local width=$1
    printf "${LM}"
    printf "%${width}s" | tr ' ' "$H"
    printf "${RM}\n"
}

print_footer() {
    local width=$1
    printf "${BL}"
    printf "%${width}s" | tr ' ' "$H"
    printf "${BR}\n"
}

# Main script
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   OpenClaw Browser Environment Installation Report          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo -e "${BLUE}Generated:$(date '+%Y-%m-%d %H:%M:%S UTC')${NC}"
echo -e "${BLUE}User:$(whoami)${NC}"
echo -e "${BLUE}Host:$(hostname)${NC}"

# Section 1: Packages
print_section "Packages"

print_header 80
print_row "Item" "Status" "Version"
print_separator 80

packages=(
    "build-essential"
    "ffmpeg"
    "imagemagick"
    "chromium"
    "chromium-headless-shell"
    "fonts-liberation"
    "fonts-noto-color-emoji"
    "libatk-bridge2.0-0"
    "dbus"
    "xvfb"
    "x11vnc"
    "novnc"
    "websockify"
    "fluxbox"
)

pkg_all_ok=true
for pkg in "${packages[@]}"; do
    status=$(check_package "$pkg")
    if [[ $status == *"❌"* ]]; then
        pkg_all_ok=false
    fi
    print_row "$pkg" "$(echo "$status" | awk '{print $1}')" "$(echo "$status" | cut -d' ' -f2-)"
done

print_footer 80

if $pkg_all_ok; then
    echo -e "${GREEN}✅ All packages installed!${NC}"
else
    echo -e "${YELLOW}⚠️ Some packages missing${NC}"
fi

# Section 2: Cache & Components
print_section "Cache & Components"

print_header 80
print_row "Item" "Status" "Details"
print_separator 80

# Playwright cache
playwright_cache="/root/.cache/ms-playwright"
if [ -d "$playwright_cache" ]; then
    chromium_dirs=$(ls -d "$playwright_cache"/chromium* 2>/dev/null | xargs -n1 basename 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
    ffmpeg_dir=$(ls -d "$playwright_cache"/ffmpeg* 2>/dev/null | xargs -n1 basename 2>/dev/null)
    print_row "Playwright Cache" "$(print_status "✅")" "$playwright_cache exists"
    if [ -n "$chromium_dirs" ]; then
        print_row "- Chromium browsers" "$(print_status "✅")" "$chromium_dirs"
    else
        print_row "- Chromium browsers" "$(print_status "❌")" "NOT FOUND"
    fi
    if [ -n "$ffmpeg_dir" ]; then
        print_row "- FFmpeg" "$(print_status "✅")" "$ffmpeg_dir"
    else
        print_row "- FFmpeg" "$(print_status "❌")" "NOT FOUND"
    fi
else
    print_row "Playwright Cache" "$(print_status "❌")" "$playwright_cache NOT FOUND"
fi

print_separator 80

# Browser config
browser_config="/usr/bin/chromium"
if [ -x "$browser_config" ]; then
    print_row "Browser config" "$(print_status "✅")" "Configured to use $browser_config"
else
    print_row "Browser config" "$(print_status "❌")" "Chromium not found"
fi

# Playwright npm
if command -v playwright >/dev/null 2>&1; then
    pw_version=$(playwright --version 2>/dev/null || echo "Unknown")
    print_row "Playwright" "$(print_status "✅")" "Installed - $pw_version"
else
    print_row "Playwright" "$(print_status "❌")" "NOT installed (npm package missing)"
fi

print_footer 80

# Section 3: Browser Testing
print_section "Browser Testing"

print_header 80
print_row "Test" "Result"
print_separator 80

# Chromium version
if chromium --version >/dev/null 2>&1; then
    chromium_ver=$(chromium --version 2>/dev/null | head -1)
    print_row "chromium --version" "$(print_status "✅") Working ($chromium_ver)"
else
    print_row "chromium --version" "$(print_status "❌") NOT WORKING"
fi

# Chromium headless shell
if chromium-headless-shell --version >/dev/null 2>&1; then
    ch_ver=$(chromium-headless-shell --version 2>/dev/null | head -1)
    print_row "chromium-headless-shell --version" "$(print_status "✅") Working ($ch_ver)"
else
    print_row "chromium-headless-shell --version" "$(print_status "❌") NOT WORKING"
fi

# novnc_proxy
if [ -f "/usr/share/novnc/utils/novnc_proxy" ]; then
    print_row "novnc_proxy" "$(print_status "✅") Available at /usr/share/novnc/utils/novnc_proxy"
else
    print_row "novnc_proxy" "$(print_status "❌") NOT FOUND"
fi

# websockify
if which websockify >/dev/null 2>&1; then
    print_row "websockify" "$(print_status "✅") Available as $(which websockify)"
else
    print_row "websockify" "$(print_status "❌") NOT FOUND"
fi

print_footer 80

# Section 4: Playwright Functionality Test
print_section "Playwright Functionality Test"

if command -v playwright >/dev/null 2>&1; then
    echo -e "${BLUE}Testing Playwright browser launch...${NC}"
    
    # Try to run a simple Playwright test
    test_result=$(node -e "
        const playwright = require('/usr/local/lib/node_modules/playwright');
        playwright.chromium.launch({headless: true}).then(async browser => {
            const page = await browser.newPage();
            await page.goto('about:blank');
            await browser.close();
            console.log('SUCCESS');
        }).catch(err => {
            console.log('FAILED:', err.message.split('\n')[0]);
        });
    " 2>&1 || echo "FAILED")

    if [[ $test_result == *"SUCCESS"* ]]; then
        echo -e "${GREEN}✅ Playwright working! Can launch Chromium browser${NC}"
    else
        echo -e "${RED}❌ Playwright test failed:${NC}"
        echo "$test_result"
    fi
else
    echo -e "${YELLOW}⚠️ Playwright not installed - skipping test${NC}"
fi

# Final Summary
echo ""
print_section "Final Summary"

all_ok=true

if ! $pkg_all_ok; then
    all_ok=false
fi

if ! command -v playwright >/dev/null 2>&1; then
    all_ok=false
fi

if [[ $test_result == *"FAILED"* ]] || [[ $test_result == *"not found"* ]]; then
    all_ok=false
fi

if $all_ok; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              ✅ ALL SYSTEMS OPERATIONAL ✅                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "All packages installed. Browsers working. Playwright functional."
    exit 0
else
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║              ⚠️ SOME ISSUES DETECTED ⚠️                     ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Please review the report above for issues."
    exit 1
fi
