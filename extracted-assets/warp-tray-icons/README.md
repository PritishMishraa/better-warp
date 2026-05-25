# Extracted Cloudflare WARP Tray/Menu-Bar Icons

Extracted on: 2026-05-18

Source directory:

```text
/Applications/Cloudflare WARP.app/Contents/Frameworks/App.framework/Versions/A/Resources/flutter_assets/assets/tray_icons
```

Related source SVG directory:

```text
/Applications/Cloudflare WARP.app/Contents/Frameworks/App.framework/Versions/A/Resources/flutter_assets/assets/svgs
```

## Files

PNG tray icons:

```text
pngs/connected.png                  32x32 RGBA
pngs/disconnected.png               32x32 RGBA
pngs/attention.png                  50x50 RGBA
pngs/attention_disconnected.png     50x50 RGBA
```

PDF tray icons:

```text
pdfs/connected.pdf
pdfs/disconnected.pdf
pdfs/attention.pdf
pdfs/attention_disconnected.pdf
```

ICO tray icons:

```text
icons/connected.ico
icons/attention.ico
icons/disconnected_dark.ico
icons/disconnected_light.ico
icons/attention_disconnected_dark.ico
icons/attention_disconnected_light.ico
```

Related cloud-state SVGs:

```text
related-svgs/cloud-connected.svg
related-svgs/cloud-connecting.svg
related-svgs/cloud-disconnected.svg
related-svgs/cloud-empty-disconnected.svg
related-svgs/cloud-fill.svg
```

## Notes

- The PNG/PDF files under `tray_icons` appear to be the actual macOS tray/menu-bar assets used by the Flutter app.
- The `.ico` files are likely cross-platform tray assets, including dark/light disconnected variants.
- The related SVGs are not in the tray icon directory, but represent the same connection-state visual language used elsewhere in the app UI.
- These are Cloudflare-owned assets extracted from the installed app bundle. Treat them as reference assets unless you have rights to redistribute or ship them.
