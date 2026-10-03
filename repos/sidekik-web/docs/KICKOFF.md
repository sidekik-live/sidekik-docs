# Claude Code kickoff: sidekik-web

**Owner:** Aadil · **Reviewer:** Sahil · **This repo is:** the Lovable app: dashboard, Capture/Debrief Room, Work Map viewer, Tutor Room, MiniERP sandbox, agent-host page.

## 0. Setup (10 minutes, before opening Claude Code)

1. Clone `<org>/sidekik-web`; create it in the org first if it doesn't exist (empty, `main` protected, reviewer in CODEOWNERS).
2. From your clone of **sidekik-docs**, run `./scripts/sync-docs.sh <folder that contains your repo clones>`. It copies `CLAUDE.md`, `.env.example`, `docs/DESIGN.md`, `docs/KICKOFF.md` and the shared `docs/ARCHITECTURE.md` + `docs/SCHEMA.md` into this repo. Commit them.
3. `cp .env.example .env` and fill it in from the team vault. Never commit `.env`.
4. **Dependencies:** the gateway API (Mayukh) and voice tokens (Aadil). Until they're ready, build against a mock `useSidekikSession` that replays `capture_sabine.jsonl` commands.
5. **Contracts before the tag exists (H0–H1.5):** do ticket 1 (scaffold) first; it doesn't need contracts. If you need types early, use `github:<org>/sidekik-platform#main` and switch to the `v0.1.0` tag as soon as it's posted.
6. Start the shared dev stack from a clone of sidekik-platform: `docker compose -f dev/docker-compose.yml up -d` (Redis + Presidio).
7. Open Claude Code in the repo root and run `/memory`. You should see `CLAUDE.md`, which imports `docs/DESIGN.md`, `docs/ARCHITECTURE.md` and `docs/SCHEMA.md`.

## 1. First prompt (plan mode; press Shift+Tab until it says plan mode)

```
Read CLAUDE.md, docs/DESIGN.md, docs/ARCHITECTURE.md and the tables this service owns in docs/SCHEMA.md.
Do not write code yet. Give me:
1. This service's responsibilities in 5 bullets.
2. Every stream it consumes/produces, every endpoint it serves/calls, every table it writes — as one table.
3. Every ambiguity, contradiction or missing detail you find across the docs (quote the lines).
4. A file-by-file plan for ticket 1, plus the order you'd do the remaining tickets in.
Wait for my approval.
```

Fix any real contradictions it finds **in the docs first**, and tell the team if they touch another repo. Then approve the plan.

## 2. Ticket loop (repeat for every ticket in `docs/DESIGN.md`, in order)

```
Implement ticket <N> from docs/DESIGN.md: "<ticket title>".
- Follow CLAUDE.md rules. Import contracts from @sidekik/contracts; never redefine them.
- Write or update tests first where practical, then the code.
- Run `pnpm typecheck && pnpm test` (and `pnpm lint` if configured) and fix until green.
- Don't touch files outside this repo. Don't change docs/ARCHITECTURE.md or docs/SCHEMA.md.
- Finish with: files changed, how to run/verify it manually, and any TODOs or doc questions.
Then stop.
```

Commit after each ticket (`feat(<area>): ticket <N> …`). Open a PR to `main` at least every 2 tickets so Sahil can review without a backlog.

## 3. Repo-specific notes

- **Split the work:** Lovable builds the UI (see `docs/LOVABLE_PROMPTS.md`). Claude Code builds the hard parts: tickets 3, 4, 9 and 11, plus the WebSocket and Realtime wiring.
- **Avoid sync clashes:** let Lovable finish a prompt and sync to GitHub before you `git pull` and run Claude Code, then push back. Never edit the same files in both at once.

## 4. Integration checkpoints

### H6: Checkpoint 1

```
We're at H6: Checkpoint 1. Run this service against the shared dev stack and teammates' deployed services.
Verify exactly this and report pass/fail per item with log or test evidence:
An expert shares the MiniERP, recodes 4711→0400, pauses, and hears the agent ask about it.
Fix only problems inside this repo. For problems in another repo, write a short bug note
(repo, observed, expected, payload sample) that I can paste to its owner. Then stop.
```

### H14: Checkpoint 2

```
We're at H14: Checkpoint 2. Run this service against the shared dev stack and teammates' deployed services.
Verify exactly this and report pass/fail per item with log or test evidence:
The Work Map page shows all steps with clips and quotes, and export works.
Fix only problems inside this repo. For problems in another repo, write a short bug note
(repo, observed, expected, payload sample) that I can paste to its owner. Then stop.
```

### H18: Checkpoint 3

```
We're at H18: Checkpoint 3. Run this service against the shared dev stack and teammates' deployed services.
Verify exactly this and report pass/fail per item with log or test evidence:
A learner presses Save on the €7,200 invoice with 4711 and is blocked with Sabine's quote and the replay.
Fix only problems inside this repo. For problems in another repo, write a short bug note
(repo, observed, expected, payload sample) that I can paste to its owner. Then stop.
```

## 5. When a contract is wrong or missing

Don't patch it locally. Use this prompt:

```
Write a GitHub issue for sidekik-platform: the contract change needed (exact zod diff), which services
are affected, and whether it's additive (minor bump) or breaking (major bump). Keep it under 15 lines.
```

Post the issue in the team chat. Sahil bumps the tag, and every affected owner updates their pin in the same hour.

## 6. Deploy

Publish from Lovable and attach the custom domain `app.sidekik.live` in Lovable's domain settings. In Cloudflare, add the record Lovable gives you as **DNS-only** (grey cloud). Set the `VITE_*` values in Lovable's environment settings, not in the repo.

Public hostname for this service: `app.sidekik.live` (Lovable custom domain).
