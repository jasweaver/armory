# Armory Project State

**Updated:** 2026-03-25

## Current Status

- Standards rollout project created: Project 12
- Standards backlog issues created: #10 through #17
- Labels expanded to include priority/type/workflow taxonomy
- Desktop packaging updated to 1.0.2 artifacts

## Key Decisions

- Keep Armory as a single-file core application architecture
- Keep local-first storage model (IndexedDB) and no backend dependency
- Use explicit standards docs/scripts/hooks instead of ad-hoc process

## Active Risks

- CodeQL mode conflict if both default setup and advanced workflow run
- Branch protection can block merge when required checks are misaligned

## Next Actions

- Finalize standards docs and contribution policy
- Resolve CodeQL mode conflict cleanly
- Close standards rollout issues as acceptance criteria are met
