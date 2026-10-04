# sidekik-web: DESIGN

**Owner:** Aadil · **Reviewer:** Sahil · **Host:** `app.sidekik.live` (Lovable hosting, custom domain) · **Built with:** Lovable, with two-way GitHub sync to `<org>/sidekik-web`. Claude Code edits the same repo.

## 1. Purpose

Everything a human sees, all in one app:

- the org dashboard
- the Capture/Debrief Room (expert)
- the Work Map viewer
- the Tutor Room (new hire)
- the MiniERP sandbox
- `/agent-host` (the page the Recall bot runs as its camera)
- the admin decision/cost views

The web app **holds the ElevenAgents session** and carries out agent commands. It never makes product decisions.

## 2. Setup (do this before generating anything)

1. Create the Lovable project and connect **your own Supabase project** through the Supabase connector. Do **not** use Lovable Cloud.
2. Connect GitHub so Lovable syncs to `<org>/sidekik-web`.
3. Env (public values only):
   - `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`
   - `VITE_API_URL=https://api.sidekik.live`
   - `VITE_INGEST_URL=wss://ingest.sidekik.live`
4. Install the ElevenAgents React SDK (`@elevenlabs/react`). The browser never sees API keys: the gateway returns a conversation token.
5. Set up the custom domain `app.sidekik.live` in Lovable and add the DNS record in Cloudflare as **DNS-only**.

## 3. Routes

| Route | Who | What |
|---|---|---|
| `/login` | all | Supabase magic link |
| `/` | all | Role-aware home: Experts see "Start capture", Learners see "Start practice", Admins see the dashboard |
| `/org/settings` | admin | Retention days, languages, Jev on/off, store learner keyframes on/off, consent text version |
| `/workflows`, `/workflows/:id` | admin/expert | Workflow list; Work Map versions; sessions |
| `/people` | admin | Experts and learners, invites |
| `/capture/:sid` | expert | **Capture/Debrief Room** (§4) |
| `/workmaps/:id` | all | **Work Map timeline**: steps, decisions, verbatim reasons, guardrails, "screen moment" clip player, "Export agent rules" |
| `/tutor/:sid` | learner | **Tutor Room** (§5) |
| `/sandbox/erp` | all | **MiniERP** (§6); embedded or opened in a second tab |
| `/agent-host/:sid?t=` | Recall bot | Minimal page: agent session + status tile (§7) |
| `/sessions/:id` | admin | Timeline of events, turns, questions, Jev decisions (confidence, latency, provider), off-record gaps |
| `/costs` | admin | Cost per session, Jev-gated vs LLM-only counterfactual |

Data for all read-only views comes straight from Supabase with RLS. Writes go **only** through `api.sidekik.live`.

## 4. Capture/Debrief Room (`/capture/:sid`)

**Layout:** the shared screen preview on the left. On the right, a side panel with:
- the agent status ("listening" / "asking" / "OFF THE RECORD")
- the live transcript
- the "questions asked" counter
- an **Off the record** toggle
- a **Task done** button

**On start:**
1. `POST /v1/sessions {workflow_id, kind:"capture", mode:"browser", language}` → `{session_id, sk_token, el:{conversation_token, agent_id, dynamic_variables}}`
2. Consent modal → `POST /v1/sessions/:id/consent`
3. `navigator.mediaDevices.getDisplayMedia({video:{frameRate:5}})`
   - Draw to a canvas every **1 s** (1280 px wide, `toBlob('image/jpeg', 0.7)`).
   - Send over `WS VITE_INGEST_URL/ws/frames/:sid?t=sk_token`. Each message is the header length as a **big-endian uint32**, the JSON header `{t_ms, reason}`, then the JPEG bytes (sidekik-perception DESIGN §2).
   - Send an extra frame on MiniERP `blur`, `save` and navigation (via `postMessage` from the MiniERP tab or iframe). Perception drops frames that arrive less than ~500 ms apart, so send the extra frame in place of the next tick, or wait until 500 ms after the last frame.
4. `useConversation()` → `startSession({conversationToken, dynamicVariables, clientTools})`
5. Open `WS VITE_API_URL/ws/client/:sid?t=sk_token` and send:
   - `onMessage` → `{type:"turn", role, text, t_ms}`
   - VAD / `isSpeaking` / mode changes → `{type:"speech", kind}`
   - MiniERP DOM events → `{type:"dom", ...}`
6. Subscribe to Supabase Realtime `session:{sid}` (broadcast) and dispatch the command with `toPageMessage()` from `@sidekik/contracts`:

| Command | Action |
|---|---|
| `ctx` | `conversation.sendContextualUpdate(text)` |
| `ask` / `followup` / `teachback` / `predict` / `intervene` / `summary` | `conversation.sendUserMessage(toPageMessage(cmd))` |
| `offrecord` | mute mic, stop the frame timer, show the red badge |
| `phase` | `endSession()`, then `startSession()` with the new token and variables; the panel switches to "Debrief" |
| `replay` | open the clip overlay |

**Client tools** to register:
- `mark_off_record({on})` → `POST /v1/sessions/:id/off-record`
- `show_status({text})`
- `replay_moment({step_id})` → `GET /v1/tools/expert_moment/:step_id` → overlay
- `highlight_field({field})` → `postMessage` to MiniERP

**Task done** → `POST /v1/sessions/:id/phase {event:"task_done"}`. Show "Sidekik is reviewing your session…" until the `phase` command arrives.

**Reconnect:** both WebSockets use exponential backoff (0.5 s → 8 s). The agent session restarts with the latest `dynamic_variables.prior_summary`.

## 5. Tutor Room (`/tutor/:sid`)

- **Same mechanics as Capture.** Use `kind:"tutor"` and pick the Work Map with a `workmap_id` picker.
- **Panel shows:**
  - the current step, in the expert's words
  - a "Predict" card
  - the intervention banner (red) with the expert quote and a **Replay Sabine's moment** button
  - a mastery panel when the session ends

## 6. MiniERP sandbox (`/sandbox/erp`)

Built in Lovable. The 6 invoices live in `src/sandbox/invoices.json` and are listed in `docs/SCHEMA.md` (seed section).

- **Fields:** supplier, supplier_known, company_code, invoice_date, net_amount, currency, category, cost_center (4711 opex / 0400 capex / 0410), asset_number, approvals (button "Send for 2nd approval"), status (open / on hold / posted).
- **DOM events:** every focus, change, record open and save attempt sends `postMessage({type:"dom", kind, record, field, before, after, state})`. The room relays it to the gateway.
- **Pre-save hook (critical for the demo):** on Save, call `POST /v1/sessions/:sid/presave {state}` with a 300 ms timeout.
  - `{allow:false, guardrail_id, quote, field?}` → block the save, show the banner, highlight `field` (the same field the `intervene` command carries).
  - Timeout or error → allow the save in capture mode, block it in tutor mode.
- **Respond to commands:** `highlight_field` and `reset_case`.

## 7. `/agent-host/:sid?t=` (meeting mode)

1. `POST /v1/agent-host/claim {t}` → `sk_token` + EL token.
2. Start the agent session. Recall plays this page into the meeting, and meeting audio comes in as the page's mic.
3. Subscribe to Realtime and handle commands exactly as in §4.
4. Render a 1280×720 status tile: the Sidekik logo, "Listening" / "Asking" / "OFF THE RECORD", and the "Recording with consent" notice.
5. **Mute input while the agent speaks** to prevent echo. Frames come from meetbot, not this page.

## 8. Claude Code / Lovable tickets

1. Supabase connection, auth, role-aware layout, Sidekik branding.
2. Org settings, workflows, people pages (CRUD through the gateway, reads from Supabase).
3. `useSidekikSession(kind)` hook: create session, consent, both WebSockets, Realtime dispatcher, reconnect.
4. Screen capture worker: canvas, JPEG, binary framing, 1 fps timer, extra frames on DOM events.
5. Capture/Debrief Room UI, plus the `phase` switch.
6. MiniERP with DOM events and the pre-save hook.
7. Work Map timeline page with the clip player (signed URL from the gateway) and the export button.
8. Tutor Room with predict card, intervention banner, replay overlay and mastery panel.
9. `/agent-host`.
10. `/sessions/:id` decision viewer and `/costs` card.
11. Replay mode: `?replay=<sid>` calls `POST /v1/replay/:sid` and renders from the Realtime stream with no mic or screen.

## 9. Definition of done

- **Checkpoint 1:** in a browser, an expert shares the MiniERP, recodes 4711→0400, pauses, and hears a question about it.
- **Checkpoint 3:** a learner chooses 4711 on the €7,200 equipment invoice, presses Save, and the save is blocked with Sabine's quote and the replay.
