# Changelog

All notable changes to this project will be documented in this file.

## [1.0.1] - 2026-03-24

### Added

- GitHub release `v1.0.1` with updated macOS and Windows installers

### Changed

- Repository renamed from `armory-v5` to `armory`
- Download/install documentation updated to `v1.0.1` artifacts and new repo URLs
- Docker web entry (`armory-combined-docker/index.html`) synchronized with canonical `armory_combined.html`

### Fixed

- Home dashboard now refreshes correctly after ammo add/edit/quantity updates
- Security hardening retained in release builds by using local vendored PDF libraries instead of remote CDN script includes

## [1.0.0] - 2026-03-24

### Added

- Desktop packaging scaffold (Electron + electron-builder)
- macOS DMG and Windows NSIS build scripts
- Docker context update to package canonical app source
- Gear photo attachments (Photo 1/Photo 2) with viewer integration
- Gear `Upper` type with `Receiver Only` / `Complete Upper`
- Gear `Upper Type` and shared `Length (in)` table columns

### Changed

- Help/Glossary updated to match tab fields and new gear workflows
- File type handling improved for preview/view/download robustness
- Export docs and packaging guidance added

### Notes

- Unsigned installer builds are intended for internal testing.
