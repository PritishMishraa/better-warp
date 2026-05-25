#!/usr/bin/env bash
set -euo pipefail

APP="/Applications/Better WARP.app"
LOGIN_ITEM="com.cloudflare.1dot1dot1dot1.macos.loginlauncherapp"
OFFICIAL_BUNDLE="com.cloudflare.1dot1dot1dot1.macos"
EXECUTABLE="$APP/Contents/MacOS/BetterWarp"

if [[ -x "$EXECUTABLE" ]]; then
    "$EXECUTABLE" --unregister-login-item --restore-official-ui 2>/dev/null || true
fi
pkill -f "$APP/Contents/MacOS/BetterWarp" 2>/dev/null || true
launchctl enable "gui/$(id -u)/$LOGIN_ITEM" 2>/dev/null || true
open -b "$OFFICIAL_BUNDLE" 2>/dev/null || true
rm -rf "$APP"

echo "Better WARP removed. Cloudflare WARP UI restored."
