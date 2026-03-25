# Armory Project

**Project Type:** Desktop + Browser local-first web app  
**Created:** 2026-03-25  
**Last Updated:** 2026-03-25

## Vision

Armory provides a private, local-first registry for firearms, ammunition, documents, and gear without requiring a cloud backend. The app is intentionally packaged for multiple delivery modes: direct browser use, Docker-hosted local use, and desktop installers for macOS and Windows.

## Problem Statement

Owners need reliable local inventory records, attachment support, and exportable summaries without handing sensitive data to third-party services.

## Target Users

- Primary: Individual firearm owners maintaining private inventory records
- Secondary: Hobbyists and collectors who need local export/reporting workflows

## Success Criteria

- Accurate CRUD management across firearms, ammo, docs, and gear
- Attachment workflows (upload/view/download) work reliably
- Desktop and Docker packaging remain reproducible

## Scope

### In Scope

- Single-file Armory application UI and data logic
- Desktop packaging via Electron
- Local Docker distribution
- Documentation, standards automation, and workflow quality gates

### Out of Scope

- Cloud sync and hosted backend storage
- Multi-user identity management
- Remote API service layer

## Technical Approach

- Runtime: Browser + Electron
- Core app: `armory_combined.html`
- Desktop wrapper: `main.js`
- Packaging: `electron-builder`
- Local storage: IndexedDB

## Related Documentation

- [ROADMAP.md](ROADMAP.md)
- [STATE.md](STATE.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)
- [STRUCTURE.md](STRUCTURE.md)
- [BRANCHING_STRATEGY.md](BRANCHING_STRATEGY.md)
- [QUICKSTART.md](QUICKSTART.md)
- [GITHUB_LABELS.md](GITHUB_LABELS.md)
