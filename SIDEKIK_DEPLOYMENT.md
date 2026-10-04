# Sidekik: Deployment

How Sidekik runs in production, and what each piece needs. Everything here matches the code on each repo's `main` as of 2026-10-04. If this file and a repo's `src/env.ts` disagree, the code wins: fix this file.

| Layer | Runs on |
|---|---|
| Frontend (`sidekik-web`) | Lovable, custom domain `app.sidekik.live` |
| Backend services, Redis, Presidio | Railway, one project `sidekik`, auto-deploy from each repo's `main` |
| Database, Auth, Storage, Realtime | Supabase (our own project, not Lovable Cloud) |
| Edge | Cloudflare: DNS, TLS, proxy for `sidekik.live`; `sidekick.live` redirects to it |
| Vendors | Anthropic (Claude), ElevenLabs (voice agents), TypeSafe (Jev), Recall.ai (meeting bots) |

## Topology

```text
                              Cloudflare (sidekik.live)
   app ──► Lovable        api ──► gateway       ingest ──► perception
   hooks ─► voice         bot ──► meetbot       mcp ─────► tutor (DNS-only)

   ┌──────────────────────────── Railway private network ─────────────────────────────┐
   │  gateway ◄──► voice · mapper · tutor · brain · meetbot      (X-Internal-Token)   │
   │  meetbot ──► perception /internal/frames                                         │
   │  every service ◄──► Redis Streams (sk:*)                                         │
   │  gateway, perception ──► Presidio analyzer / anonymizer (/ image redactor)       │
   └──────────────────────────────────────────────────────────────────────────────────┘
   every service ──► Supabase (service role)      browser ──► Supabase (anon/publishable key)
   browser ◄─ WebRTC ─► ElevenLabs                Recall bot ──► meetbot (webhook + WS)
```

The browser holds the voice session; no backend streams audio. Services publish agent commands, and only the gateway pushes them to the page (Supabase Realtime).

## Services at a glance

| Repo | Host | Port | Public routes | Internal routes (X-Internal-Token) | Built |
|---|---|---|---|---|---|
| `sidekik-gateway` | `api.sidekik.live` | 8080 | `/v1/*`, `WS /ws/client/:sid`, `/v1/agent-host/claim` | `/internal/agent-host-token`, `/internal/redact`, `/internal/sessions/:id/{off-record,phase}` | yes |
| `sidekik-perception` | `ingest.sidekik.live` | 8081 | `WS /ws/frames/:sid` (sk_token) | `WS /internal/frames/:sid`, `/internal/clips`, `/internal/clips/:job_id`, `/internal/keyframe-url` | yes |
| `sidekik-brain` | private | 8082 | none | `/internal/decide` | yes |
| `sidekik-mapper` | private | 8083 | none | `/internal/workmaps/:id/{publish,export}`, `/internal/tools/recall_context`, `/internal/workflows/:id/compare` | yes |
| `sidekik-tutor` | `mcp.sidekik.live` | 8084 | `/mcp` (bearer `SK_TOOL_SECRET`) | `/internal/presave`, `/internal/tools/*` | yes |
| `sidekik-voice` | `hooks.sidekik.live` | 8085 | ElevenLabs post-call webhook | `/internal/token` | not yet |
| `sidekik-meetbot` | `bot.sidekik.live` | 8086 | `/recall/webhook`, `WS /recall/ws/:sid/` | `/internal/bots`, `DELETE /internal/bots/:sid` | yes |
| `sidekik-web` | `app.sidekik.live` | — | the app | — | Lovable |

Every service serves `GET /healthz` → `{ok, version, deps}` (503 when a dependency is down).

## Order

1. Supabase project, migrations, seed.
2. `@sidekik/contracts` tag (already cut: currently `v0.3.1`).
3. Railway: Redis, Presidio.
4. gateway → voice → perception → brain → mapper → tutor → meetbot.
5. Lovable custom domain and env.
6. Cloudflare records, then vendor webhooks (they need the public hosts).
7. Smoke tests and the H6 / H14 / H18 checks.

---

## Shared infrastructure

### Supabase

- Migrations and seed live in `sidekik-platform/supabase/`. Apply them with the Supabase CLI:
  ```bash
  cd sidekik-platform
  supabase link --project-ref <project-ref>
  supabase db push            # migrations 0001–0008
  supabase db reset --linked  # only on a fresh project: also loads seed.sql (demo org, Sabine, Lena)
  ```
- Check RLS is on for every table, and `agent_host_tokens` has **no** read policy.
- Keys: services get `SUPABASE_SERVICE_ROLE_KEY` (the secret key, `sb_secret_…`, or the legacy `service_role` JWT). The browser gets only the publishable/anon key.
- Auth: add `https://app.sidekik.live` to the allowed redirect URLs (magic links).
- Connect the project to Lovable through the Supabase connector.

### `@sidekik/contracts`

`sidekik-platform` is a package, not a service: never deploy it to Railway.

- Releases: `pnpm release X.Y.Z && git push upstream vX.Y.Z`. The tag points at a detached commit carrying the prebuilt `dist/`; `main` never holds `dist/`.
- Services pin a tag: `"@sidekik/contracts": "github:sidekik-live/sidekik-platform#v0.3.1"`. Never a branch.
- If the platform repo is private, add a read-only `NPM_GITHUB_TOKEN` to Railway's build variables.

### Redis

Railway's Redis plugin. Every service gets the same `REDIS_URL`. Streams and consumer groups are created on first use (`XGROUP CREATE … MKSTREAM`), so there is nothing to set up.

### Presidio

Railway image services from `mcr.microsoft.com/presidio-*` (container port 3000). The analyzer with the German model and our AP recognizers is built from `sidekik-platform/infra/presidio`.

| Component | Used by | Variable |
|---|---|---|
| Analyzer | gateway (transcript redaction), perception (screen text) | `PRESIDIO_ANALYZER_URL` |
| Anonymizer | gateway, perception | `PRESIDIO_ANONYMIZER_URL` |
| Image redactor (optional) | perception (keyframes) | `PRESIDIO_IMAGE_URL` |

Redaction fails closed: if Presidio is down, gateway's `/internal/redact` answers 503 instead of passing text through.

---

## Railway conventions

- One service per backend repo, built from its `Dockerfile` (`node:22-slim`; perception and meetbot add `ffmpeg`), deploying `main` on every merge.
- Services listen on `::` (Railway's private network is IPv6). Set `PORT` explicitly to the port in the table above, so teammates' URLs stay stable.
- Service-to-service URLs use the private network: `http://<service>.railway.internal:<port>`, e.g. `TUTOR_URL=http://sidekik-tutor.railway.internal:8084`, `PERCEPTION_INTERNAL_URL=ws://sidekik-perception.railway.internal:8081`.
- Shared secrets (`SK_INTERNAL_TOKEN`, `SK_SESSION_SECRET`, `SK_TOOL_SECRET`, Supabase, Redis) go in one shared variable group and are referenced from each service. Generate the `SK_*` ones with `openssl rand -hex 32`.
- Health check path: `/healthz`.

## Per-service settings

Only what isn't obvious from the table above. Each repo's `.env.example` lists every variable.

**gateway**: `VOICE_URL`, `MEETBOT_URL`, `MAPPER_URL`, `TUTOR_URL`, `BRAIN_URL` (private URLs); `INGEST_URL=wss://ingest.sidekik.live` (handed to the browser); `CORS_ORIGIN=https://app.sidekik.live`. Presave proxies to tutor with a 250 ms budget, so keep the two in the same region.

**perception**: `ANTHROPIC_API_KEY`; `VISION_PRIMARY` / `VISION_FALLBACK` (Haiku 4.5, optionally Sonnet 5.5). `PERSISTENCE` and `FAKE_VISION` are dev-only; leave them unset in production.

**brain**: `TYPESAFE_API_KEY` (Jev), with `OPENROUTER_API_KEY` and `ANTHROPIC_API_KEY` as fallbacks; `GATEWAY_INTERNAL_URL`. `PERSISTENCE`, `FAKE_VENDORS` and `THRESHOLDS_JSON` are dev or tuning only.

**mapper**: `ANTHROPIC_API_KEY`, `BUILDER_MODEL`, `PATCH_MODEL`; `BRAIN_URL`, `GATEWAY_INTERNAL_URL`, `PERCEPTION_URL`. The Work Map build is an async job: Cloudflare cuts proxied requests at 100 s. (The repo's `.env.example` still lists `GEMINI_API_KEY` / `EMBED_*`; they're unused since v0.2.)

**tutor**: `SK_TOOL_SECRET` (MCP bearer), `BRAIN_URL`. The presave path is deterministic JSON-Logic with no model call.

**voice**: `ELEVENLABS_API_KEY`, `EL_INTERVIEWER_AGENT_ID`, `EL_TUTOR_AGENT_ID`, `EL_WEBHOOK_SECRET`, `SK_TOOL_SECRET`, `GATEWAY_INTERNAL_URL`.

**meetbot**: `RECALL_API_KEY` and `RECALL_REGION` (the region the key belongs to; ours is `us-east-1`); `RECALL_WEBHOOK_SECRET` (Recall's workspace verification secret, `whsec_…`); `RECALL_WS_SECRET`; `PUBLIC_URL=https://bot.sidekik.live`; `APP_URL=https://app.sidekik.live`; `GATEWAY_INTERNAL_URL`; `PERCEPTION_INTERNAL_URL` (`ws://…`).

**web** (Lovable): `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` (publishable key), `VITE_API_URL=https://api.sidekik.live`, `VITE_INGEST_URL=wss://ingest.sidekik.live`. Nothing else: no vendor key or service secret ever goes into the web repo.

## Secrets matrix

| Variable | gateway | perception | brain | mapper | tutor | voice | meetbot | web |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | |
| `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` | | | | | | | | ✓ |
| `REDIS_URL`, `SK_INTERNAL_TOKEN` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | |
| `SK_SESSION_SECRET` | ✓ | ✓ | | | | | | |
| `SK_TOOL_SECRET` | ✓ | | | | ✓ | ✓ | | |
| `ANTHROPIC_API_KEY` | | ✓ | ✓ | ✓ | | | | |
| `TYPESAFE_API_KEY`, `OPENROUTER_API_KEY` | | | ✓ | | | | | |
| `ELEVENLABS_API_KEY`, `EL_*` | | | | | | ✓ | | |
| `RECALL_*` | | | | | | | ✓ | |
| `PRESIDIO_*_URL` | ✓ | ✓ | | | | | | |

---

## Vendor setup

**ElevenLabs**: the Interviewer and Tutor agents are pushed from `sidekik-voice` (config as code). Post-call webhook → `https://hooks.sidekik.live/…` signed with `EL_WEBHOOK_SECRET`. Webhook tools call `https://api.sidekik.live/v1/tools/*` with header `X-Sidekik-Tool-Secret`; MCP uses `https://mcp.sidekik.live/mcp` with bearer `SK_TOOL_SECRET`.

**Recall.ai** (meeting mode only):
- Webhook endpoint `https://bot.sidekik.live/recall/webhook`, subscribed to every `bot.*` status event. Recall signs it with the workspace verification secret (`RECALL_WEBHOOK_SECRET`).
- Bots are created per session by meetbot with `web_4_core` (needed for per-participant video, $0.60/h) and zero data retention, so there are no recordings to delete.
- The real-time endpoint URL meetbot hands Recall needs a `/` before the query (`/recall/ws/:sid/?secret=`); Recall answers 400 otherwise.
- Google Meet first: the host must admit the bot. Zoom external meetings need an OBF token; Teams may hit lobby policies.

**Anthropic, TypeSafe**: keys only; no webhooks.

## Cloudflare

| Host | Target | Proxy |
|---|---|---|
| `sidekik.live` | redirect rule → `app.sidekik.live` | proxied |
| `app` | Lovable custom-domain target | **DNS-only** (Lovable issues its own certificate) |
| `api`, `ingest`, `hooks`, `bot` | Railway custom domain of gateway, perception, voice, meetbot | proxied |
| `mcp` | Railway custom domain of tutor | DNS-only until MCP streaming is verified |

**`sidekick.live`** (the common misspelling, also in our Cloudflare account) only redirects; it serves nothing itself:

| Host | Record | Rule |
|---|---|---|
| `sidekick.live`, `www` | proxied placeholder (`AAAA 100::`) | redirect rule: 301 → `https://app.sidekik.live` |
| `*.sidekick.live` | proxied placeholder (`AAAA 100::`, wildcard) | redirect rule (wildcard pattern): `https://*.sidekick.live/*` → 301 `https://${1}.sidekik.live/${2}`, so `app.sidekick.live/x` lands on `app.sidekik.live/x` |

Keep the apex/`www` rule above the wildcard rule, so `www.sidekick.live` goes to the app and not to a `www.sidekik.live` that doesn't exist.

Never point APIs, webhooks or WebSockets at `sidekick.live`: gateway's CORS origin, Supabase Auth redirect URLs, the Recall and ElevenLabs webhook URLs and the meetbot real-time URL all use `sidekik.live`, and redirects break POST bodies and WebSocket upgrades.

- SSL/TLS **Full (strict)**; WebSockets on.
- If a Railway certificate won't issue behind the proxy, switch the record to DNS-only until it does, then proxy again.
- Proxied HTTP is cut at 100 s (524), and proxied WebSockets can drop when Cloudflare deploys. Clients reconnect with backoff; Recall retries its socket every 3 s, and meetbot pings it every 30 s against idle timeouts.

---

## Verify

**Smoke**
- `curl https://<host>/healthz` for every public service (and from a Railway shell for private ones): `ok: true` and every dep `true`.
- `sidekik-platform/dev/smoke.sh` against production URLs.
- Browser: sign in, Capture Room, screen permission, WebSocket reconnect after a network blip, voice, off-record badge.
- PII: a transcript with a name and an IBAN arrives redacted; keyframes are redacted; signed Storage URLs expire after 10 minutes; the browser bundle has no secret.

**Checkpoints**
- **H6 capture loop:** browser frames → perception `screen.events` → brain asks → gateway → agent speaks a grounded question at a pause.
- **H14 Work Map:** capture → draft → debrief with ≥ 3 follow-ups → teach-back → confirmed map; every step has a screen moment and the expert's words.
- **H18 tutor:** €7,200 equipment invoice on opex 4711 is blocked before save, explained in Sabine's words, the MiniERP highlights `cost_center`, and the 03:12 clip replays.
- **H21 meeting (optional):** in Google Meet the bot joins as "Sidekik (recording)", perception gets frames, and the Interviewer asks its question in the meeting.

## Rules that matter in production

- Contract changes go through `@sidekik/contracts` with a version bump (additive = minor, breaking = major); every consumer updates its pin.
- Every bus handler is idempotent on `event.id`; every log line carries `session_id` and `org_id`.
- Secrets live only in Railway variables (and Lovable's public env for the two `VITE_` Supabase values). Never in git.
- Squash-merge `feat/*` branches to `main`; `main` deploys.
