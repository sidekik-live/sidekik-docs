# Aadil: start here

You own **sidekik-web** (Lovable), **sidekik-voice** and **sidekik-meetbot**. Sahil reviews your PRs.

| Hours | Repo | Goal |
|---|---|---|
| 0–1.5 | sidekik-web | Lovable on your own Supabase (not Lovable Cloud), GitHub sync, Lovable prompts 1–3 (shell, dashboard, MiniERP) |
| 0–1.5 | sidekik-voice | Both agents created; **hour-1 spike**: does `skip_turn` keep the agent silent? Migration PR 0002/0003 to sidekik-platform |
| 1.5–6 | voice + web | `/internal/token`; Capture Room (Lovable prompt 4 + Claude Code ticket 3–4) → **Checkpoint 1 at H6** |
| 6–14 | voice + web | Post-call webhook, transcripts, KB/Procedure sync; Work Map page → **Checkpoint 2 at H14** |
| 14–18 | web | Tutor Room, MiniERP pre-save wiring, replay overlay → **Checkpoint 3 at H18** |
| 18–21 | sidekik-meetbot | Recall + Google Meet. **Hard cut at H21** if the bot can't speak |

**For each repo:**
1. Create the empty repo in the org. For web, let Lovable create it through GitHub sync.
2. Run `./scripts/sync-docs.sh <folder with your repo clones>` from sidekik-docs (see README).
3. Open Claude Code there.
4. Follow `docs/KICKOFF.md`. For web, also follow `docs/LOVABLE_PROMPTS.md`.
