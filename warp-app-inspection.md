# Cloudflare WARP App Inspection

Date: 2026-05-18  
Machine path inspected: `/Applications/Cloudflare WARP.app`

## Summary

The installed WARP app is Cloudflare WARP for macOS. It is a menu-bar app backed by a privileged root daemon. The UI, CLI, and diagnostics tools all talk to the daemon; the daemon owns the actual network behavior.

Current observed state:

```text
Status: Connected
Reason: NetworkHealthy
Operation mode: warp
Tunnel protocol: MASQUE (HTTPS via TCP)
Tunnel interface: utun4
Edge colo: BOM
TLS: TLSv1.3
Post-quantum TLS: enabled
```

## Installed App

App bundle:

```text
/Applications/Cloudflare WARP.app
```

Bundle metadata:

```text
Bundle ID: com.cloudflare.1dot1dot1dot1.macos
Version: 2026.4.1350.0
Build: 20269004.1350
Minimum macOS: 14.0
UI mode: LSUIElement=true, menu-bar/background-style app
URL scheme: com.cloudflare.warp
```

Code signing:

```text
Authority: Developer ID Application: Cloudflare Inc. (68WVV388M8)
Team ID: 68WVV388M8
Hardened runtime: enabled
Universal binary: x86_64 and arm64
```

The app bundle includes a Flutter-based GUI and several native helper binaries.

## Runtime Processes

Observed running processes:

```text
root  /Applications/Cloudflare WARP.app/Contents/Resources/CloudflareWARP
user  /Applications/Cloudflare WARP.app/Contents/MacOS/Cloudflare WARP
```

The root process is the service daemon. The user process is the menu-bar GUI.

## Launchd Service

The daemon is managed by launchd:

```text
/Library/LaunchDaemons/com.cloudflare.1dot1dot1dot1.macos.warp.daemon.plist
```

Relevant launchd configuration:

```text
Label: com.cloudflare.1dot1dot1dot1.macos.warp.daemon
ProgramArguments:
  /Applications/Cloudflare WARP.app/Contents/Resources/CloudflareWARP
UserName: root
RunAtLoad: true
KeepAlive: true
SoftResourceLimits.NumberOfFiles: 32768
```

This means WARP starts at boot and launchd keeps the root daemon alive.

## Bundle Components

Important files in the app bundle:

```text
Contents/MacOS/Cloudflare WARP
Contents/Resources/CloudflareWARP
Contents/Resources/warp-cli
Contents/Resources/warp-diag
Contents/Resources/warp-dex
Contents/Resources/uninstall.sh
Contents/Resources/libaws_lc_fips_0_13_7_crypto.dylib
Contents/Resources/libaws_lc_fips_0_13_7_rust_wrapper.dylib
Contents/Frameworks/FlutterMacOS.framework
Contents/Frameworks/Sparkle.framework
Contents/Frameworks/Sentry.framework
Contents/Frameworks/rust_bridge.framework
Contents/Frameworks/App.framework
```

Roles:

- `Cloudflare WARP`: Flutter menu-bar GUI.
- `CloudflareWARP`: privileged networking daemon.
- `warp-cli`: command-line client for the daemon.
- `warp-diag`: diagnostics collector.
- `warp-dex`: Cloudflare DEX/device-experience diagnostics.
- `Sparkle.framework`: updater framework.
- `Sentry.framework`: crash/error reporting.
- `rust_bridge.framework`: native bridge used by the Flutter app to talk to WARP IPC/native code.
- AWS-LC FIPS libraries: cryptography support.

## Current Registration

The local client is registered as:

```text
Managed: false
Account type: free
Alternate networks: none
```

The CLI also returned a device ID, public key, account ID, and license string. Those are local identifiers/secrets and are intentionally omitted here.

## Current Settings

Observed daemon settings:

```text
always_on: true
switch_locked: false
operation_mode: warp
disable_for_wifi: false
disable_for_ethernet: false
split_tunnel_mode: exclude
warp_tunnel_protocol: masque
post_quantum_config: enabled_with_downgrades
```

Interpretation:

- WARP is configured to stay connected whenever possible.
- The user-facing switch is not locked by policy.
- It is using full WARP mode, not DNS-only mode.
- Split tunneling is in exclude mode: most traffic goes through WARP except listed exclusions.
- MASQUE is the preferred tunnel protocol.
- Post-quantum TLS is enabled, with downgrade allowed if needed.

## Split Tunnel Exclusions

The current exclude list contains private/local/link-local/multicast ranges and several Apple ranges. Examples:

```text
10.0.0.0/8
100.64.0.0/10
169.254.0.0/16
172.16.0.0/12
192.168.0.0/16
224.0.0.0/24
240.0.0.0/4
fe80::/10
fc00::/7
fd00::/8
ff01::/16 through ff05::/16
```

The observed local LAN, `192.168.88.0/24`, remains directly reachable on `en0`.

## DNS Behavior

macOS DNS is configured to use WARP-controlled loopback resolvers:

```text
127.0.2.2
127.0.2.3
::ffff:127.0.2.2
::ffff:127.0.2.3
```

Those addresses are configured on `lo0`.

Observed daemon/network debug output shows:

```text
Primary interface: en0
Primary IPv4: 192.168.88.9
Primary gateway: 192.168.88.1
Tunnel interface: utun4
Captive portal detected: false
```

The service logs show periodic DNS health checks:

```text
DNS proxy health status: Healthy
```

So DNS queries are pointed at local WARP loopback listeners, and the daemon forwards/resolves them through WARP policy/tunnel handling.

## Tunnel Interface

The active WARP tunnel interface is:

```text
utun4
IPv4: 172.16.0.2
IPv6: 2606:4700:110:...
MTU: 1280
```

Tunnel stats:

```text
WARP on: true
Endpoint: 162.159.198.2
Protocol: MASQUE (HTTPS via TCP)
Estimated latency: 27 ms
Estimated loss: ~0.00995506
TLS version: TLSv1.3
TLS curve: P256Kyber768Draft00
Cipher: TLS_AES_256_GCM_SHA384
Edge colo: BOM
```

## Routing Behavior

The route table has a normal default route through the LAN gateway:

```text
default -> 192.168.88.1 via en0
```

It also has a WARP default and many more-specific routes through `utun4`:

```text
default -> link#31 via utun4
many IPv4 prefixes -> utun4
many IPv6 prefixes -> utun4
```

The effect is that most internet traffic is steered through WARP, while excluded private/local ranges stay on the physical network.

## Logs And State

WARP stores logs and operational files under:

```text
/Library/Application Support/Cloudflare
```

Observed files include:

```text
cfwarp_service_log.txt
cfwarp_daemon_dns.txt
cfwarp_service_dns_stats.txt
cfwarp_service_connection_stats.txt
cfwarp_service_network_health_stats.txt
cfwarp_service_dex.txt
cfwarp_service_captive_portal.txt
cfwarp_route_change_log.txt
cfwarp_service_taskdump.txt
cfwarp_snapshots_collection.txt
.warp_dns.lock
```

The daemon logs show IPC requests from both the GUI and `warp-cli`, DNS/firewall health checks, statistics collection, tunnel loop stats, and registration/settings reads.

## CLI Surface

The bundled CLI is:

```text
/Applications/Cloudflare WARP.app/Contents/Resources/warp-cli
```

It describes itself as:

```text
CLI to the WARP service daemon
```

Major command groups:

```text
connect
disconnect
status
settings
mode
dns
tunnel
registration
proxy
trusted
override
mdm
environment
debug
stats
certs
target
vnet
```

This is a client interface to the daemon, not the daemon itself.

## Is The Flutter Menu-Bar UI Just A Wrapper Around warp-cli?

No. Based on the inspected bundle and runtime logs, the Flutter menu-bar app is not simply shelling out to `warp-cli`.

What I found:

- The GUI process connects to the daemon over IPC directly.
- The app bundle contains `rust_bridge.framework`, with symbols and strings for an `AsyncIpcClient`.
- The Flutter app strings include IPC methods such as `GetDaemonStatus`, `GetNetworkInfo`, `GetRegistrationInfo`, `GetAppSettings`, `SetAlwaysOn`, `SetOperationMode`, and other daemon operations.
- The daemon logs show IPC connections from the GUI process directly:

```text
process_name="/Applications/Cloudflare WARP.app/Contents/MacOS/Cloudflare WARP"
Ipc request: GetDaemonStatus
Ipc request: GetNetworkInfo
```

- The daemon logs also show separate IPC connections from `warp-cli` when the CLI is run:

```text
process_name="/Applications/Cloudflare WARP.app/Contents/Resources/warp-cli"
```

So the GUI and `warp-cli` are peers. Both are clients of the same privileged WARP daemon. The GUI uses a Flutter/Dart app plus a Rust FFI bridge to call the WARP IPC layer directly; `warp-cli` is a separate command-line client for that same IPC/service API.

Cloudflare's own documentation matches this model. Their Cloudflare One Client docs describe the client as consisting of a GUI plus a WARP daemon/service. They list the macOS daemon path as `/Applications/Cloudflare WARP.app/Contents/Resources/CloudflareWARP`, the GUI path as `/Applications/Cloudflare WARP.app/Contents/MacOS/Cloudflare WARP`, and describe `warp-cli` as the command-line interface for managing and configuring the client. Source: <https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/>

## Practical Architecture

The architecture is:

```text
Flutter menu-bar UI
        |
        | Rust bridge / WARP IPC client
        v
Root WARP daemon
        |
        | owns DNS, routes, tunnel, settings, stats, registration
        v
macOS network stack: lo0 DNS listeners, utun4 tunnel, route table

warp-cli
        |
        | WARP IPC client
        v
Root WARP daemon
```

The privileged daemon is the source of truth. The GUI is richer than a CLI wrapper, but functionally it exposes a subset of the same daemon capabilities available through `warp-cli`.

## Programmatically Disabling The Official Menu-Bar UI

The official Flutter menu-bar UI can be disabled without disabling the actual WARP networking daemon.

Do not disable this daemon:

```text
/Library/LaunchDaemons/com.cloudflare.1dot1dot1dot1.macos.warp.daemon.plist
```

That daemon runs `CloudflareWARP` as root and controls DNS, routes, tunnel state, registration, and settings. A replacement UI should leave it running.

The GUI login launcher observed on this machine is:

```text
com.cloudflare.1dot1dot1dot1.macos.loginlauncherapp
```

Disable the official menu-bar UI at login:

```bash
launchctl disable gui/$(id -u)/com.cloudflare.1dot1dot1dot1.macos.loginlauncherapp
```

Quit the currently running official GUI cleanly:

```bash
osascript -e 'tell application id "com.cloudflare.1dot1dot1dot1.macos" to quit'
```

If it does not quit cleanly, stop only the GUI process:

```bash
pkill -f '/Applications/Cloudflare WARP.app/Contents/MacOS/Cloudflare WARP'
```

Re-enable the official menu-bar UI later:

```bash
launchctl enable gui/$(id -u)/com.cloudflare.1dot1dot1dot1.macos.loginlauncherapp
open -b com.cloudflare.1dot1dot1dot1.macos
```

For a replacement UI, the intended flow is:

```text
on first launch:
  disable Cloudflare GUI login launcher
  quit Cloudflare GUI if running
  keep CloudflareWARP daemon running
  use warp-cli for control/status
```

Caveats:

- Cloudflare updates may re-enable the login item.
- Manually launching the official Cloudflare WARP app may bring the official menu-bar UI back.
- A replacement app should periodically detect whether the official GUI is running if the user has selected a "replace official UI" mode.
- Do not unload or disable the root LaunchDaemon unless the goal is to stop WARP networking entirely.
