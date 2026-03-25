# Armory Architecture

## Overview

Armory is a local-first application centered on a single HTML source file (`armory_combined.html`) that contains UI, styles, and business logic. It is distributed in three modes:

- Direct browser execution
- Docker-hosted static site
- Electron desktop wrapper

## Components

- `armory_combined.html`: Primary app logic and interface
- `assets/vendor/*`: PDF/export vendor dependencies
- `main.js`: Electron shell and secure app protocol wiring
- `armory-combined-docker/`: Nginx-based container distribution

## Data Model

- Primary storage: IndexedDB
- Attachments stored locally as binary payloads
- No remote persistence or API dependency

## Packaging

- `electron-builder` generates DMG and NSIS installer artifacts
- Docker image serves static app assets using nginx

## Security Model

- Local-only storage by design
- Strict CSP in application HTML
- Sensitive data handling relies on host/device security and user backup practices
