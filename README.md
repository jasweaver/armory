# Armory

A local-first personal firearms, ammunition, documents, and gear registry.

Armory is built as a single-file web app and can run in a browser, Docker container, or packaged desktop installers (macOS DMG and Windows EXE).

## Download Installers

- Latest release: https://github.com/jasweaver/armory/releases/latest
- macOS DMG: https://github.com/jasweaver/armory/releases/download/v1.0.0/Armory-1.0.0.dmg
- Windows EXE: https://github.com/jasweaver/armory/releases/download/v1.0.0/Armory-Setup-1.0.0.exe

Note: current installers are unsigned test builds and may show OS security prompts on first launch.

## Features

- Firearms registry with NFA tracking, statuses, and attachment support
- Ammunition inventory with stock alerts and cost-per-round calculations
- Document vault with expiry tracking and local file storage
- Gear inventory with type-specific fields (including Upper tracking)
- Local storage using IndexedDB (data stays on-device)
- CSV/PDF exports for firearms, ammo, and gear

## Project Layout

- `armory_combined.html`: Main application source (single-file app)
- `armory-combined-docker/`: Dockerfile + compose setup
- `main.js`: Electron desktop entrypoint
- `package.json`: Desktop packaging config (Electron + electron-builder)
- `assets/favicon.svg`: App favicon

## Run Options

### 1. Browser (quick local test)

Open `armory_combined.html` directly in your browser.

### 2. Docker

```bash
cd armory-combined-docker
docker compose up --build
```

Then open: `http://localhost:8080`

### 3. Desktop (Electron)

Install dependencies:

```bash
npm install
```

Run desktop app in dev mode:

```bash
npm run dev
```

Build installers:

```bash
npm run dist:mac
npm run dist:win
```

Artifacts are generated under `dist/`.

## Data and Privacy

- App data is stored locally in IndexedDB.
- No backend service is required.
- Clearing browser/app storage will remove local records and attachments.

## Repository Landing

Use this README as the repository landing page.

## Supporting Docs

- `README-desktop-packaging.md`
- `CONTRIBUTING.md`
- `SECURITY.md`
- `CHANGELOG.md`
- `CODE_OF_CONDUCT.md`
