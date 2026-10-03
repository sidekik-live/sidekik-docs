# Changelog

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
