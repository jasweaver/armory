# Repository Structure

## Core Files

- `armory_combined.html` - Main application source
- `main.js` - Electron entrypoint
- `package.json` - Desktop build scripts/config

## Distribution

- `armory-combined-docker/` - Dockerfile, compose, and static index
- `dist/` - Generated installer artifacts

## Assets

- `assets/` - Favicon and bundled JS vendor libraries

## Governance and Standards

- `docs/` - Project and workflow documentation
- `.github/` - CI workflows and PR/issue templates
- `scripts/` - Operations and hygiene helpers
- `.githooks/` - Commit/push guardrails

## Conventions

- Keep app behavior changes primarily in `armory_combined.html`
- Keep release/package changes constrained to `package.json`, `main.js`, and Docker files
- Keep process changes documented in `docs/` and `CONTRIBUTING.md`
