# sidekik-web

Part of **Sidekik**, an AI apprentice (sidekik.live). Team: Sahil, Aadil, Mayukh. This repo's spec is `docs/DESIGN.md`. The system design and contracts are in `docs/ARCHITECTURE.md`, and the database is in `docs/SCHEMA.md`.

@docs/DESIGN.md
@docs/ARCHITECTURE.md
@docs/SCHEMA.md

## Rules for Claude Code in this repo
- This repo is built with Lovable (two-way GitHub sync). Keep Lovable's project structure, small focused components, Tailwind.
- Only public env (`VITE_*`). Never call vendor APIs (ElevenLabs keys, Jev, Recall, Anthropic, Gemini) from the browser. Go through `https://api.sidekik.live`.
- Read from Supabase (RLS); write only through the gateway.
- Use the `AgentCommand` types and `toPageMessage()` from `@sidekik/contracts`.
- Both WebSockets auto-reconnect with backoff; a reconnect must never kill the agent session.
- Don't edit files Lovable is generating at the same moment; pull before you start, push when done.
- Never edit docs/ARCHITECTURE.md or docs/SCHEMA.md here. They are synced copies; the source is the sidekik-docs repo (change it there by PR).
