# Better WARP

Better WARP is a small native macOS menu-bar wrapper for Cloudflare WARP. It keeps Cloudflare's privileged WARP daemon in place and uses `warp-cli` to connect, disconnect, and read status.

## What It Does

- Left-click the menu-bar icon to connect or disconnect WARP.
- Right-click for status, refresh, login-item controls, official UI controls, and quit.
- Optionally replace Cloudflare's menu-bar UI without disabling the WARP daemon.
- Fall back to opening the official app when `warp-cli` status is unavailable.

## Build

```bash
swift build
bash Scripts/test.sh
bash Scripts/build-app.sh
```

The app bundle is written to `dist/Better WARP.app`.

## Install

```bash
bash Scripts/install-app.sh
```

To remove Better WARP and restore Cloudflare's menu-bar UI:

```bash
bash Scripts/uninstall-app.sh
```

## Notes

Better WARP intentionally stays narrow: it provides a fast menu-bar toggle and status display while Cloudflare WARP remains responsible for networking, DNS, routing, registration, and policy.
