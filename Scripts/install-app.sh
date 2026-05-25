#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_APP="$ROOT/dist/Better WARP.app"
TARGET_APP="/Applications/Better WARP.app"

"$ROOT/Scripts/build-app.sh"

rm -rf "$TARGET_APP"
cp -R "$SOURCE_APP" "$TARGET_APP"
xattr -dr com.apple.quarantine "$TARGET_APP" 2>/dev/null || true
codesign --verify --deep --strict "$TARGET_APP" >/dev/null

if [[ "${BETTER_WARP_LAUNCH_AFTER_INSTALL:-1}" == "1" ]]; then
    open "$TARGET_APP"
fi

echo "$TARGET_APP"
