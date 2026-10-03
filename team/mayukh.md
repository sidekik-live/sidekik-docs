# Mayukh: start here

You own **sidekik-gateway**, **sidekik-mapper** and **sidekik-tutor**. Aadil reviews your PRs. You also set up the shared infrastructure at H0.

| Hours | Repo | Goal |
|---|---|---|
| 0–1.5 | infra | Supabase project, Railway project + Redis, Cloudflare DNS records, the three `SK_*` secrets in the team vault, migration PRs 0001/0005/0006 to sidekik-platform |
| 1.5–6 | sidekik-gateway | Sessions, `sk_token`, `/ws/client` + Presidio, Realtime egress → **Checkpoint 1 at H6** |
| 2–14 | sidekik-mapper | Builder against the fixture, debrief driver, publish; gateway phase + off-record → **Checkpoint 2 at H14** |
| 14–18 | sidekik-tutor | Rule engine + presave first (the demo test), then predict loop and MCP → **Checkpoint 3 at H18** |
| 18–21 | tutor + gateway | Mastery, gap flags, export, cost ledger, replay mode |

**For each repo:**
1. Create the empty repo in the org.
2. Run `./scripts/sync-docs.sh <folder with your repo clones>` from sidekik-docs (see README).
3. Open Claude Code there.
4. Follow `docs/KICKOFF.md`.
