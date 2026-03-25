# Quickstart

## Browser

Open `armory_combined.html` directly.

## Docker

```bash
cd armory-combined-docker
docker compose up --build
```

Open http://localhost:8080

## Desktop

```bash
npm install
npm run dev
```

Build installers:

```bash
npm run dist:mac
npm run dist:win
```

## Standards Workflow Helpers

```bash
./scripts/new-branch.sh 10 "standards-docs"
./scripts/project-status.sh
./scripts/end-of-day.sh
```
