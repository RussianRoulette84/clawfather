#!/bin/bash
# Bootstrap: downloads clawfather into current directory and runs the real installer.
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/RussianRoulette84/clawfather/master/install.sh)

set -e
REPO="https://github.com/RussianRoulette84/clawfather/archive/refs/heads/master.tar.gz"
DEST="$(pwd)"
curl -fsSL "$REPO" | tar xz -C "$DEST"
cd "$DEST/clawfather-master"
[ -f config.yaml ] || cp config.example.yaml config.yaml
[ -f .env.sensitive ] || cp .env.sensitive.example .env.sensitive
chmod +x src/install_clawfather.sh
exec bash src/install_clawfather.sh "$@" < /dev/tty
