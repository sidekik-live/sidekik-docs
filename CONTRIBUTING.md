# Changing the docs

These docs are a contract between three people building nine repos in parallel. A small wording change can break a teammate's build, so follow these rules.

## Rules

1. **Never edit the synced copies** in a code repo's `docs/`. Change the doc here, then sync.
2. **Every change goes through a PR** in this repo, with one approval:
   - The **owner of the affected repo** approves changes to `repos/<repo>/…`.
   - **The other two teammates** approve changes to `ARCHITECTURE.md` or `SCHEMA.md` (one of them is enough during the hackathon).
3. **Contract changes need code too.** For changes to ARCHITECTURE §5, Appendix A (decision specs) or Appendix B (types):
   - open the matching change in `sidekik-platform` (`@sidekik/contracts`) and bump its tag;
   - additive changes are a minor bump; renamed or removed fields are a major bump;
   - link the two PRs.
4. **Schema changes need a migration.** Changes to `SCHEMA.md` need a matching migration PR in `sidekik-platform/supabase/migrations`, reviewed by the table's owner.
5. **Bump the doc version and log it.** Bump the version in the `ARCHITECTURE.md` title (`v0.1` → `v0.2`) and add a line to `CHANGELOG.md`.
6. **After merge:**
   - run `bash scripts/sync-docs.sh ~/code` and commit `docs: sync from sidekik-docs vX.Y` in each affected repo;
   - post the change in the team chat with the affected repos tagged.

## Fast path during the hackathon

Typos, clarifications and notes that don't change a contract, an endpoint, a table or a threshold can be pushed straight to `main`. Post a one-line note in the chat.

## Where things live

| If you're changing… | Edit | Also update |
|---|---|---|
| A stream, payload, command or decision spec | `ARCHITECTURE.md` §4–5, Appendix A/B | `sidekik-platform` contracts and tag |
| A table or column | `SCHEMA.md` | migration in `sidekik-platform` |
| One service's endpoints, pipeline or tickets | `repos/<repo>/docs/DESIGN.md` | callers listed in ARCHITECTURE §4.3 if the interface changed |
| Prompts for Claude Code | `repos/<repo>/docs/KICKOFF.md` | none |
| Claude Code rules for a repo | `repos/<repo>/CLAUDE.md` | run sync with `--force --only <repo>` |
| Env vars | `repos/<repo>/.env.example` + DESIGN.md "Env" | ARCHITECTURE §7.3 secrets matrix |
| Timeline or ownership | `ARCHITECTURE.md` §3, §9 + `team/*.md` | none |
