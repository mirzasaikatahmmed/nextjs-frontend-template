# Golden Next.js Frontend Template

Clean, malware-hardened Next.js App Router + Tailwind starter. Use this — and only this — to scaffold new frontend client repos.

## Stack

- Next.js 15 (App Router) + React 19 + TypeScript
- Tailwind CSS v4
- Optional Nest golden-backend health check
- Config malware scanner (CI + pre-commit)

## Security (non-negotiable)

```bash
npm run security:scan
```

- `scripts/check-malware-configs.mjs` — signature + long-line gate
- `.github/workflows/security-config-scan.yml` — fails PRs with infected configs
- `.husky/pre-commit` — blocks bad commits locally
- Never copy `eslint.config.*` / `postcss.config.*` / `tailwind.config.*` from old client folders without scanning first


Also blocked by the scanner: fake `public/fonts/fa-solid-400.woff2`, malicious `.vscode/tasks.json` (`folderOpen`), and worm `.bat` helpers.

Policy: **no `npm install` / lint / dev until scan is clean; no merge to `main` unless Security Config Scan is green.**

## Quick start

```bash
cp .env.example .env.local
npm install
npm run security:scan
npm run dev
```

App: `http://localhost:3000` (or Next default port)

Point `NEXT_PUBLIC_API_URL` at the Nest golden backend (`http://localhost:3000/api` if API uses that port — change Next to `3001` if both run locally).

Suggested local ports:

- Backend API: `3000`
- This frontend: `3001` → `npm run dev -- -p 3001`

## Create a new client repo from this template

1. Copy this folder (or use GitHub "Use this template").
2. Rename `package.json` name + branding in `layout.tsx` / `page.tsx`.
3. Run `npm run security:scan` before trusting IDE lint on any machine with old clones.
4. Enable branch protection: require `Security Config Scan` + PR review.
5. Never commit `.env.local`.

## Lock `main` (do this after first GitHub push)

```bash
# requires: gh auth login (admin on the repo)
./scripts/enable-branch-protection.sh
# or: ./scripts/enable-branch-protection.sh owner/repo
# solo: APPROVALS=0 ./scripts/enable-branch-protection.sh owner/repo
```

This turns on a GitHub ruleset so **direct pushes to `main` are rejected**. Only pull requests (with required checks) can merge.

## Checklist before shipping a client fork

- [ ] `npm run security:scan` passes
- [ ] `.env.local` not committed
- [ ] API URL set for the client environment
- [ ] `./scripts/enable-branch-protection.sh` run (main is PR-only)
- [ ] Branch protection requires security + CI checks
- [ ] Write access limited to active collaborators
