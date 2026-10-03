# Changelog

## v0.2 (2026-10-03): Claude API as the only LLM/vision provider

- **Vision (perception):** Gemini Flash-Lite replaced by **Claude Haiku 4.5**, with optional escalation to Sonnet 5.5 for low-confidence numeric fields. Timeout raised to 2 s, and cropped tiles are preferred.
- **Retrieval (mapper):** embeddings dropped. `kb_chunks` now uses **Postgres full-text search** (`tsv` generated column + trigram fallback, `search_kb()` function). No embeddings vendor.
- **Contracts:** `UsageRecord.vendor` and `cost_ledger.vendor` no longer include `gemini`. If `@sidekik/contracts` v0.1.0 is already tagged, this is a breaking change: bump the tag and tell the team.
- **Voice:** documented who pays for the agents' LLM (built-in Claude via ElevenLabs by default; optional Custom LLM route on the team's own key).
- **Secrets:** `GEMINI_API_KEY` removed from perception and mapper.

## v0.1 (2026-10-03): initial design

- `ARCHITECTURE.md`:
  - system map and repo ownership (Sahil / Aadil / Mayukh)
  - Redis Streams bus, internal HTTP, Realtime egress
  - auth, agent commands, contracts
  - data ownership, Cloudflare domains on sidekik.live, hosting, secrets matrix
  - 24-hour timeline with checkpoints H6/H14/H18
  - Appendix A (Jev decision specs D1–D12), Appendix B (Work Map types, demo guardrails G1–G5)
- `SCHEMA.md`: all tables (migrations 0001–0008), RLS, storage buckets, demo seed data.
- `repos/*`: DESIGN.md, KICKOFF.md, CLAUDE.md and .env.example for all 9 code repos; Lovable prompts for sidekik-web.
- `scripts/sync-docs.sh`.
