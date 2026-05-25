#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Better WARP"
EXECUTABLE="BetterWarp"
BUILD_DIR="$ROOT/.build/release"
DIST_DIR="$ROOT/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
APP_RESOURCES_DIR="$CONTENTS_DIR/Resources"
RESOURCES_DIR="$ROOT/Resources"
SIGN_IDENTITY="${BETTER_WARP_SIGN_IDENTITY:--}"
BUNDLE_ID="${BETTER_WARP_BUNDLE_ID:-local.better-warp.app}"
APP_VERSION="${BETTER_WARP_VERSION:-0.1.0}"
BUILD_NUMBER="${BETTER_WARP_BUILD:-1}"

cd "$ROOT"
swift build -c release --product "$EXECUTABLE"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$APP_RESOURCES_DIR"

cp "$BUILD_DIR/$EXECUTABLE" "$MACOS_DIR/$EXECUTABLE"
cp "$RESOURCES_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$CONTENTS_DIR/Info.plist"
cp "$RESOURCES_DIR/MenuBarIcons/WarpOn.png" "$APP_RESOURCES_DIR/WarpOn.png"
cp "$RESOURCES_DIR/MenuBarIcons/WarpOff.png" "$APP_RESOURCES_DIR/WarpOff.png"
chmod +x "$MACOS_DIR/$EXECUTABLE"

codesign \
    --force \
    --deep \
    --options runtime \
    --entitlements "$RESOURCES_DIR/BetterWarp.entitlements" \
    --sign "$SIGN_IDENTITY" \
    "$APP_DIR" >/dev/null

if [[ "${BETTER_WARP_NOTARIZE:-0}" == "1" ]]; then
    xcrun notarytool submit "$APP_DIR" --wait
    xcrun stapler staple "$APP_DIR"
fi

echo "$APP_DIR"
