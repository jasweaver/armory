# Armory Desktop Packaging

This workspace includes an Electron wrapper to package `armory_combined.html` as a desktop app.

## Quick Start

```bash
npm install
npm run dev
```

## Build Installers

### macOS DMG

```bash
npm run dist:mac
```

### Windows EXE (NSIS)

```bash
npm run dist:win
```

### Both (from matching CI runners)

```bash
npm run dist
```

## Output

Build artifacts are generated under `dist/`.

## Notes

- The Electron app serves `armory_combined.html` via a custom `app://` protocol.
- App data (IndexedDB) remains local to each machine.
- For production distribution, add platform code-signing certificates:
  - macOS: Developer ID Application + notarization
  - Windows: Authenticode certificate

## Optional Icon Upgrade

Current setup includes a browser favicon at `assets/favicon.svg`.
For branded installer/taskbar icons, add:

- `assets/icon.icns` for macOS builds
- `assets/icon.ico` for Windows builds

Then add icon fields under `build.mac.icon` and `build.win.icon` in `package.json`.
