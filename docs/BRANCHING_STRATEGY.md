# Branching Strategy

## Branch Types

- `feature/<issue>-<short-description>`
- `fix/<issue>-<short-description>`
- `docs/<issue>-<short-description>`
- `refactor/<issue>-<short-description>`
- `chore/<issue>-<short-description>`

Examples:
- `feature/10-standards-docs`
- `fix/15-codeql-conflict`

## Commit Policy

Use conventional commits and include an issue reference.

Examples:
- `feat: add standards quickstart docs #10`
- `fix: remove conflicting CodeQL workflow #15`

## Pull Request Rules

- Each PR should map to at least one issue
- Keep PR size manageable
- Include testing/validation notes in PR template
- Ensure required checks pass before merge
