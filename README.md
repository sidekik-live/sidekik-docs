# sidekik-docs

The shared design reference for **Sidekik**, an AI apprentice built for the Hack-Nation 7th Global AI Hackathon, Challenge 01 (ElevenLabs).

- Sidekik joins an expert's screen (browser or Meet/Zoom/Teams) and asks *why* at natural pauses.
- It turns the session into a confirmed, evidence-linked **Work Map**.
- It then coaches a new hire on their own screen, catching mistakes before they're saved.

**Domain:** sidekik.live · **Team:** Sahil, Aadil, Mayukh

This repo holds documentation only. It is the **single source of truth**. Every code repo carries synced copies of these docs in its `docs/` folder, so Claude Code always has full context.

---

## Start here

1. **Read [`ARCHITECTURE.md`](ARCHITECTURE.md)** (20 minutes). It covers:
   - the system map and the 9 code repos
   - who owns which repo
   - how services talk (bus, internal HTTP, Realtime)
   - every contract (§5 and Appendices A–B)
   - Cloudflare domains, hosting and the 24-hour timeline
2. **Open your guide in [`team/`](team/):** [Sahil](team/sahil.md), [Aadil](team/aadil.md) or [Mayukh](team/mayukh.md).
3. **Clone your code repos side by side with this one**, then sync the docs into them:

   ```bash
   ~/code/sidekik-docs        # this repo
   ~/code/sidekik-gateway     # your code repos (empty is fine)
   ~/code/sidekik-mapper
   ...
   cd ~/code/sidekik-docs
   bash scripts/sync-docs.sh ~/code            # all clones found in ~/code
   bash scripts/sync-docs.sh ~/code --only sidekik-gateway
   ```

4. **In each code repo:** commit the synced files, open Claude Code, and follow `docs/KICKOFF.md`.

## What's in here

| Path | What it is | Who uses it |
|---|---|---|
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Whole system, contracts, ownership, domains, deployment, timeline, decision specs D1–D12, Work Map types, demo guardrails G1–G5 | everyone (synced to every repo) |
| [`SCHEMA.md`](SCHEMA.md) | Every Supabase table, column, index, RLS policy, bucket, plus the seed/demo data | everyone (synced to every repo) |
| `repos/<repo>/docs/DESIGN.md` | Build spec for one repo: interfaces, pipeline, env vars, **ordered tickets**, definition of done | that repo's owner and Claude Code |
| `repos/<repo>/docs/KICKOFF.md` | Copy-paste prompts: first plan, ticket loop, checkpoint checks, contract issues, deploy | that repo's owner |
| `repos/<repo>/CLAUDE.md` | Claude Code entry point; imports `docs/DESIGN.md`, `docs/ARCHITECTURE.md`, `docs/SCHEMA.md` and sets repo rules | Claude Code |
| `repos/<repo>/.env.example` | Every env var the service needs | that repo's owner |
| `repos/sidekik-web/docs/LOVABLE_PROMPTS.md` | 8 ordered Lovable prompts for the UI | Aadil |
| [`team/`](team/) | Each person's hour-by-hour plan | each teammate |
| [`scripts/sync-docs.sh`](scripts/sync-docs.sh) | Copies docs into local clones of the code repos | everyone |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | How to change a doc without breaking a teammate | everyone |
| [`CHANGELOG.md`](CHANGELOG.md) | What changed in the docs, by version | everyone |

## Repos and owners

| Owner | Repos | Slice |
|---|---|---|
| **Sahil** | `sidekik-platform` · `sidekik-perception` · `sidekik-brain` | what's on screen and when/what to ask (Jev) |
| **Aadil** | `sidekik-web` · `sidekik-voice` · `sidekik-meetbot` | everything the user sees and hears |
| **Mayukh** | `sidekik-gateway` · `sidekik-mapper` · `sidekik-tutor` | sessions/trust, the Work Map, teaching |
| all three | `sidekik-docs` (this repo) | shared design |

## Public endpoints

| Host | Service |
|---|---|
| `app.sidekik.live` | sidekik-web (Lovable; Cloudflare DNS-only) |
| `api.sidekik.live` | sidekik-gateway |
| `ingest.sidekik.live` | sidekik-perception (frames WebSocket) |
| `hooks.sidekik.live` | sidekik-voice (ElevenLabs webhooks) |
| `bot.sidekik.live` | sidekik-meetbot (Recall.ai) |
| `mcp.sidekik.live` | sidekik-tutor (MCP) |

## Checkpoints

| Time | Checkpoint | Pass condition |
|---|---|---|
| **H6** | 1 | a grounded question asked at a natural pause |
| **H14** | 2 | a confirmed Work Map with evidence for every step |
| **H18** | 3 | the €7,200 opex mistake caught before save, explained in the expert's words |

Full pass/fail criteria for each checkpoint are in `ARCHITECTURE.md §9` and each repo's `DESIGN.md`.

## Using these docs with Claude Code without syncing

If you'd rather point Claude Code at this repo directly, start it from your code repo with `claude --add-dir ../sidekik-docs` and tell it to read `../sidekik-docs/repos/<your-repo>/docs/DESIGN.md`. Syncing is still the recommended path, because `CLAUDE.md` imports only resolve inside the repo.
