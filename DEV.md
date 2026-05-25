# Better WARP Developer Guide

This guide is for developers working on Better WARP itself. The user-facing README intentionally stays focused on installation and basic use.

## Project Overview

Better WARP is a Swift Package Manager project that builds a macOS menu-bar app. The app does not implement VPN networking. It drives Cloudflare's installed WARP service through `warp-cli`, displays status in the menu bar, and optionally suppresses Cloudflare's official menu-bar UI.

The package requires macOS 14 or newer and Swift tools version 6.0.

## Repository Layout

```text
Package.swift                         Swift package manifest
Sources/BetterWarp/                   AppKit menu-bar application
Sources/BetterWarpCore/               CLI, process, and status parsing logic
Tests/BetterWarpCoreTestRunner/       Lightweight executable test runner
Resources/Info.plist                  App bundle metadata template
Resources/BetterWarp.entitlements     Codesigning entitlements
Resources/MenuBarIcons/               Bundled menu-bar icon assets
Scripts/build-app.sh                  Release build and .app bundle creation
Scripts/install-app.sh                Build, install to /Applications, and launch
Scripts/uninstall-app.sh              Remove Better WARP and restore official UI
Scripts/test.sh                       Run core tests
dist/                                 Generated app bundle output
.build/                               SwiftPM build output
```

## Prerequisites

- macOS 14+
- Xcode Command Line Tools or Xcode with Swift 6 support
- Cloudflare WARP installed when testing real app behavior
- `warp-cli` available from one of:
  - `/Applications/Cloudflare WARP.app/Contents/Resources/warp-cli`
  - `/usr/local/bin/warp-cli`
  - `/opt/homebrew/bin/warp-cli`
  - any path resolved by `which warp-cli`

Unit-style core tests do not require Cloudflare WARP, except for future tests that explicitly shell out to the real CLI.

## Common Commands

Run the core test runner:

```bash
bash Scripts/test.sh
```

Build the Swift executable only:

```bash
swift build
```

Build a release `.app` bundle into `dist/Better WARP.app`:

```bash
bash Scripts/build-app.sh
```

Install the app to `/Applications/Better WARP.app` and launch it:

```bash
bash Scripts/install-app.sh
```

Install without launching:

```bash
BETTER_WARP_LAUNCH_AFTER_INSTALL=0 bash Scripts/install-app.sh
```

Uninstall Better WARP and restore Cloudflare's official menu-bar app:

```bash
bash Scripts/uninstall-app.sh
```

## Build and Signing

`Scripts/build-app.sh` performs the release build, creates the macOS bundle structure, copies resources, patches `Info.plist`, and signs the app.

Supported environment variables:

```bash
BETTER_WARP_SIGN_IDENTITY="-"                  # defaults to ad-hoc signing
BETTER_WARP_BUNDLE_ID="local.better-warp.app"  # bundle identifier
BETTER_WARP_VERSION="0.1.0"                    # CFBundleShortVersionString
BETTER_WARP_BUILD="1"                          # CFBundleVersion
BETTER_WARP_NOTARIZE=0                         # set to 1 to run notarytool/stapler
```

For local development, the default ad-hoc signature is enough. Distribution builds should provide a Developer ID signing identity and notarization credentials accepted by `xcrun notarytool`.

## Runtime Behavior

The app runs as an accessory app (`LSUIElement`) and owns a single `NSStatusItem`.

Important runtime details:

- Left-click toggles WARP only when status is a stable connected or disconnected state.
- Right-click opens the status/menu options.
- Status refreshes every 8 seconds.
- If "Replace Cloudflare Menu-Bar UI" is enabled, the app periodically disables Cloudflare's login launcher and quits the official UI.
- App logs are written to `~/Library/Application Support/Better WARP/BetterWarp.log`.
- Maintenance flags exist for scripts:
  - `--unregister-login-item`
  - `--restore-official-ui`

## Core Design

`BetterWarpCore` is intentionally independent of AppKit so parsing and process behavior can be tested without launching the menu-bar app.

Key types:

- `WarpCLI`: locates `warp-cli`, runs status/connect/disconnect commands, and falls back from JSON status to plain-text status.
- `WarpStatusParser`: parses JSON and plain `warp-cli status` output into `WarpStatus`.
- `WarpStatus`: normalizes stable, transitional, unknown, and unavailable states.
- `ProcessRunner`: runs subprocesses with stdout/stderr capture and timeout handling.

The app target maps `WarpStatus` to menu labels, icons, tooltips, and menu actions.

## Testing Notes

There is no XCTest target at the moment. Tests are implemented as an executable target at `Tests/BetterWarpCoreTestRunner` and run with:

```bash
swift run BetterWarpCoreTestRunner
```

Keep parser and process tests in this runner unless the project is migrated to XCTest. Prefer adding coverage in `BetterWarpCore` for logic changes, because that avoids UI automation and does not require Cloudflare WARP to be installed.

Before opening a PR or handing off a change, run:

```bash
bash Scripts/test.sh
bash Scripts/build-app.sh
```

For changes that affect install, login item, official UI replacement, icons, or bundle metadata, also run an install/uninstall cycle on macOS:

```bash
bash Scripts/install-app.sh
bash Scripts/uninstall-app.sh
```

## Development Guidelines

- Keep user-facing behavior simple: Better WARP should remain a fast menu-bar toggle, not a replacement for Cloudflare's full settings UI.
- Treat `warp-cli` output as unstable. Prefer tolerant parsing and add parser tests for every new output shape.
- Avoid blocking the main actor with process work. Shell commands should stay off the UI thread.
- Be careful around Cloudflare's official login item and UI process. Restore paths should be maintained whenever replacement behavior changes.
- Do not commit generated `.build/` or `dist/` output.
- Keep the README user-oriented. Put developer workflow, internals, and release notes here.

## Troubleshooting Development Builds

If the status is unavailable, check that Cloudflare WARP is installed and that `warp-cli` is executable:

```bash
/Applications/Cloudflare\ WARP.app/Contents/Resources/warp-cli --json status
```

If the app launches but no icon appears, inspect:

```bash
tail -f ~/Library/Application\ Support/Better\ WARP/BetterWarp.log
```

If the installed app fails signature verification, rebuild from a clean bundle:

```bash
rm -rf dist/Better\ WARP.app /Applications/Better\ WARP.app
bash Scripts/install-app.sh
```
