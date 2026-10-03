# Sahil: start here

You own **sidekik-platform**, **sidekik-perception** and **sidekik-brain**. Mayukh reviews your PRs. Everyone is blocked on you for the first 90 minutes, so platform comes first.

| Hours | Repo | Goal |
|---|---|---|
| 0–1.5 | sidekik-platform | Tickets 1–5, then **tag `v0.1.0`** and post it in the team chat |
| 1.5–2 | sidekik-platform | Merge the migration PRs from Mayukh and Aadil, write 0004/0007/0008, run `supabase db reset` |
| 1.5–6 | sidekik-perception | Frames, diff, vision benchmark, `screen.events`, `ctx` |
| 4–6 | sidekik-brain | `jev.ts`, pause gate, planner, `ask` → **Checkpoint 1 at H6** |
| 6–14 | brain + perception | D2–D7, keyframes, clips, `/internal/decide` → **Checkpoint 2 at H14** |
| 14–18 | brain | D9–D11 for tutor → **Checkpoint 3 at H18** |
| 18–21 | brain | Calibration on rehearsal data, cost counterfactual |

**For each repo:**
1. Create the empty repo in the org.
2. Run `./scripts/sync-docs.sh <folder with your repo clones>` from sidekik-docs (see README).
3. Open Claude Code there.
4. Follow `docs/KICKOFF.md`.
