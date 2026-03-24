# Contributing

Thanks for your interest in improving Armory.

## Development Basics

- Main app source: `armory_combined.html`
- Desktop wrapper: `main.js`, `package.json`
- Docker setup: `armory-combined-docker/`

## Local Workflow

1. Create a branch from `main`.
2. Make focused changes.
3. Validate behavior in browser and, when relevant, desktop packaging.
4. Open a pull request with:
   - Clear summary
   - Screenshots/GIFs for UI changes
   - Test notes

## Suggested Validation

- App loads without console errors
- CRUD flows work for firearms, ammo, docs, and gear
- Exports (CSV/PDF) still run
- Attachments can be saved and viewed
- If changed, Docker and Electron flows still build

## Commit Style

Use concise, action-oriented commit messages, for example:

- `feat: add upper type fields to gear`
- `fix: preserve attachment previews with missing mime types`
- `docs: update help modal field reference`
