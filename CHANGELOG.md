# Changelog

## v0.3.2 (2026-10-04): sidekik-perception as built

- **sidekik-perception:**
  - `.env.example` matches the service. Gemini is gone; new: `PRESIDIO_ANALYZER_URL` / `PRESIDIO_ANONYMIZER_URL` (screen-text redaction), `FFMPEG_PATH` (optional), and the dev-only `PERSISTENCE` / `FAKE_VISION`.
  - DESIGN documents:
    - the frame wire format (big-endian uint32 header length) and the 2 fps cap;
    - tile-level change detection;
    - typing hold, keyframe rules and redaction fallback;
    - `ctx` privacy;
    - the clip slideshow;
    - `GET /internal/clips/:job_id`.
  - Perception now consumes `ask` commands (ARCHITECTURE §4.2).
- **sidekik-web, sidekik-meetbot (needs Aadil's review):** the frames header length is a big-endian uint32. Frames less than ~500 ms apart are dropped, so the web page's extra blur/save/nav frame should replace the next tick.

## v0.3.1 (2026-10-04): what the switch to @sidekik/contracts v0.1.0 changed

- **All repos:** use pnpm 10 (`packageManager: pnpm@10.34.6`). pnpm 9 puts `#` in the git dependency's install path, which vitest can't load.
- **sidekik-gateway:** `.env.example` lists `INGEST_URL` (it was only in the gateway repo). The agent-host `sk_token` carries the session's own role (`expert` or `learner`), since `SessionRole` has no agent-host role. `/internal/redact` takes `lang` and `keep` and answers 503 when Presidio fails.
- **sidekik-mapper:** publish checks the map against `WorkMapSchema`, writes `work_map_steps`/`guardrails`/`step_evidence` before requesting clips (also on confirmation), retires the previously published version and deletes its `kb_chunks`. `confirmed_turn_id` is written to its column. `recall_context` omits `t_ms` for published knowledge.
- **sidekik-tutor:** `get_expert_moment` omits `clip_url` until a clip exists and answers 404 for a step without a reason. A mastery summary for a session without a learner uses `learner_id: "anonymous"`.

## v0.3 (2026-10-03): Node 22, per-question decision answers, contracts release flow

- **Stack:** Node 22 and `node:22-slim` in every repo. Node 20 reached end of life in April 2026, and `@supabase/supabase-js` now requires Node ≥ 22.
- **Contracts (additive):** `DecisionResult.answers?: Record<string, QuestionAnswer>` carries every question of a decision, because D6, D1, D5 and D7 ask more than one. `answer` stays the first question's.
- **Contracts release:** `@sidekik/contracts` tags carry a prebuilt `dist/`, cut with `pnpm release <version>`. pnpm 10 refuses to run build scripts in git dependencies. Pin tags only.
- **Schema (mapper, needs Mayukh's review):** `search_kb()` trigram fallback now uses word similarity (`<%`, threshold 0.4). With whole-string `%`, a short query never matched a long chunk, so typos never matched.
- **Schema (RLS, platform):** `agent_host_tokens` has RLS but no read policy (one-time credentials, gateway-only), and the SECURITY DEFINER helpers pin `search_path`.
- **PII (gateway, perception):** `redact()` in `@sidekik/contracts` (analyzer → anonymizer, fails closed). NER redacts PERSON only, and callers pass `keep: [supplier]`. The analyzer image with the German model is in `sidekik-platform/infra/presidio`.
- **Contracts (additive):** `contracts/api.ts` (endpoint request/response schemas), `PRICE_TABLE` + `priceUsd()`, `toPageMessage()` / `pageAction()`.
- **sidekik-brain:** new env vars `JEV_TIMEOUT_MS`, `OPENROUTER_JEV_MODEL`, `PLANNER_MODEL`, `PERSISTENCE`, `THRESHOLDS_JSON` and `FAKE_VENDORS`. `LLM_FALLBACK_MODEL` defaults to `claude-haiku-4-5`. `/internal/decide` doesn't serve D3.

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
