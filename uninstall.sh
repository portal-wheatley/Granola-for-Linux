#!/usr/bin/env bash
# Remove the Granola install created by granola-linux.sh.
# Your notes database in ~/.config/Granola is left alone unless you pass --purge.
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/Applications/granola}"
DESKTOP_FILE="${DESKTOP_FILE:-$HOME/.local/share/applications/granola.desktop}"
DATA_DIR="$HOME/.config/Granola"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/granola"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Native messaging host manifests the app wrote for the browser extension.
# Same browser list as the patched app, one manifest per profile root.
MANIFESTS=()
for browser in google-chrome google-chrome-beta google-chrome-unstable \
               BraveSoftware/Brave-Browser microsoft-edge microsoft-edge-beta \
               microsoft-edge-dev chromium vivaldi opera; do
  m="$CONFIG_HOME/$browser/NativeMessagingHosts/com.granola.app.json"
  [[ -f "$m" ]] && MANIFESTS+=("$m")
done

echo "This will remove:"
echo "  $INSTALL_DIR"
echo "  $DESKTOP_FILE"
echo "  $LOG_DIR"
for m in "${MANIFESTS[@]:-}"; do [[ -n "$m" ]] && echo "  $m"; done
[[ "${1:-}" == "--purge" ]] && echo "  $DATA_DIR  (local notes cache and login)"
read -rp "Continue? [y/N] " reply
[[ "$reply" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }

pkill -f "^$INSTALL_DIR/granola" 2>/dev/null || true
pkill -f "^$INSTALL_DIR/electron" 2>/dev/null || true   # installs made before the binary was renamed
sleep 1
rm -rf "$INSTALL_DIR" "$DESKTOP_FILE" "$LOG_DIR"
for m in "${MANIFESTS[@]:-}"; do [[ -n "$m" ]] && rm -f "$m"; done
[[ "${1:-}" == "--purge" ]] && rm -rf "$DATA_DIR"

command -v update-desktop-database >/dev/null && update-desktop-database "$(dirname "$DESKTOP_FILE")" 2>/dev/null || true
echo "Done."
