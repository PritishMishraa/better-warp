# Better WARP

Better WARP is a lightweight macOS menu-bar app for Cloudflare WARP. It gives you a simple one-click way to connect or disconnect WARP without opening Cloudflare's larger desktop window.

## Who It Is For

Better WARP is for people who already use Cloudflare WARP and mostly need a fast menu-bar toggle. It does not replace Cloudflare's VPN service, account settings, device registration, DNS settings, or network policy controls.

## How It Works

- Left-click the Better WARP menu-bar icon to connect or disconnect.
- Right-click the icon to see status, refresh, startup options, and quit.
- If Better WARP cannot read WARP status, it offers to open the official Cloudflare WARP app.
- Cloudflare's background WARP service stays installed and in control of networking.

## Important Note

Better WARP controls the official Cloudflare WARP service. You still need Cloudflare WARP installed and working on your Mac.

## Install From Source

This repository currently builds the app locally.

```bash
bash Scripts/install-app.sh
```

The app is installed as:

```text
/Applications/Better WARP.app
```

## Remove

To remove Better WARP and restore Cloudflare's normal menu-bar app:

```bash
bash Scripts/uninstall-app.sh
```

## Troubleshooting

If the app appears to do nothing, open the official Cloudflare WARP app first and make sure it is signed in and working. Better WARP depends on Cloudflare's installed WARP tools.
