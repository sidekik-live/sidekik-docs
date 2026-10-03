# Lovable prompts: sidekik-web

Run these prompts **in order** in Lovable. Lovable builds the screens; Claude Code then wires up the hard parts (see `KICKOFF.md` §3). After each prompt, let Lovable sync to GitHub before running Claude Code.

**Before prompt 1:**
- Connect **your own Supabase project** with the Supabase connector. **Do not enable Lovable Cloud.**
- Connect GitHub to `<org>/sidekik-web`.
- Paste `docs/DESIGN.md` into Lovable's project knowledge, or attach it.

---

### 1. Shell and brand

```
Build "Sidekik", an AI apprentice web app (domain app.sidekik.live). Calm, professional, light theme with a dark-mode toggle.
Brand: wordmark "sidekik" in lowercase, accent color deep teal (#0F766E), neutral grays, Inter font.
Layout: left sidebar (Home, Workflows, People, Work Maps, Sessions, Costs, Settings), top bar with org name and user menu.
Use Supabase auth with email magic link on /login. After login, route by role from the org_members table
(admin → dashboard, expert → "Start capture" card, learner → "Start practice" card).
Do not create database tables; they already exist. Read data with the Supabase client only.
```

### 2. Dashboard pages (read from Supabase, write through the API)

```
Create pages: /workflows (list + detail with Work Map versions and recent sessions), /people (experts and learners),
/org/settings (retention days, languages, Jev on/off, store learner keyframes, consent text version).
Reads come from Supabase tables workflows, work_maps, sessions, experts, learners, orgs.
All create/update actions call our API at import.meta.env.VITE_API_URL with the Supabase access token as
Bearer auth — put these calls in src/lib/api.ts as typed functions with TODO bodies; don't call Supabase for writes.
```

### 3. MiniERP sandbox

```
Create /sandbox/erp: a simple accounts-payable screen that looks like a plain enterprise ERP (dense table + form).
Load invoices from src/sandbox/invoices.json (create it with the 6 invoices below).
List on the left; form on the right with fields: invoice_id (read-only), supplier, supplier_known (checkbox),
company_code (DE01/CZ01), invoice_date, net_amount, currency, category (equipment/services/parts/office),
cost_center (select: 4711 Opex, 0400 Capex, 0410 Capex-IT), asset_number, approvals_count with a
"Send for 2nd approval" button, status (open/on hold/posted) and buttons "Hold" and "Save".
Every focus, change, record open and save attempt must call window.parent.postMessage and window.opener?.postMessage
with {type:"dom", kind, record:{kind:"invoice", id}, field, before, after, state} — put this in src/sandbox/domEvents.ts.
Save must call an async function presave(state) from src/sandbox/presave.ts (stub returns {allow:true}); if
allow is false show a red banner with the returned quote and highlight the field, and don't save.
Listen for postMessage {type:"highlight_field", field} and {type:"reset_case"}.
Invoices: 4471 Präzisionswerk Ulm, known, DE01, 6350 EUR, equipment, cost center 4711, CNC fixture;
4480 Kranbau GmbH, known, DE01, 1980 EUR, services, December date; 4492 Strojírna Brno s.r.o., known, CZ01, 3400 EUR, parts;
4501 Bürobedarf Weber, known, DE01, 240 EUR, office; 4510 Antriebstechnik Nord, NOT known, DE01, 7200 EUR, equipment, spindle motor;
4511 Kranbau GmbH, known, DE01, 2150 EUR, services, December date.
```

### 4. Capture / Debrief Room (UI only)

```
Create /capture/:sid. Left: a large area for the shared-screen preview (a <video> element with id "screen-preview")
and a "Share screen" button. Right side panel: agent status pill (Listening / Asking / Reviewing / Debrief /
OFF THE RECORD in red), live transcript list, "Questions asked: N" counter, a big "Off the record" toggle,
and a "Task done" button. Add a consent modal on first load (checkboxes for audio, screen, storage; text version v1).
Put all state in a hook stub src/hooks/useSidekikSession.ts that returns {status, transcript, questionsAsked,
offRecord, phase, start(), toggleOffRecord(), taskDone()} with mock data for now. Claude Code will implement it.
```

### 5. Work Map page

```
Create /workmaps/:id: header with workflow name, expert, version, status badge (draft/in debrief/confirmed/published).
Body: vertical clickable timeline of steps ("Step 4 of 7: Code the invoice to a cost center"). Each step expands to show:
Screen moment (time label like 03:12 + a "Play" button that opens a modal video player for a signed URL),
Decision, Reason (quoted, original language + English, with source label like "Sabine, live question at 03:15"),
Guardrails (chips; click shows the rule text and quote). Mark judgment-call steps with an icon.
Right column: open items and an "Export agent rules" button. Read work_maps, work_map_steps, guardrails,
step_evidence, open_items from Supabase. Clip URLs come from api.ts getClipUrl(workmapId, stepId) (stub).
```

### 6. Tutor Room (UI only)

```
Create /tutor/:sid with the same split layout as the Capture Room. Side panel: current step card ("What Sabine does here"),
a "Predict" card that appears when the tutor asks for a prediction, a red intervention banner with the expert's quote and
a "Replay Sabine's moment" button (opens the same video modal), and a Mastery panel shown at the end
(per-step outcome chips: independent / prompted / corrected / not attempted, and a "Practice next" list).
Use a stub hook src/hooks/useTutorSession.ts with mock data. Include a "Open MiniERP" button that opens /sandbox/erp in a new window.
```

### 7. Agent host page (for the meeting bot)

```
Create /agent-host/:sid as a full-screen 1280x720 tile with no app chrome: centered sidekik wordmark, a large animated
status ring (Listening / Asking / OFF THE RECORD in red), and a small line "Recording with consent · say 'off the record' to pause".
State comes from a stub hook src/hooks/useAgentHost.ts.
```

### 8. Sessions and costs

```
Create /sessions/:id: a vertical timeline merging screen events, transcript turns, questions and Jev decisions ordered by t_ms
(from tables screen_events, transcript_turns, questions, decisions_log). Decisions show decision id, answer, confidence bar,
provider (jev/llm), escalated badge and latency. Show off-record gaps as grey bands.
Create /costs: per-session table and a summary card "Jev-gated cost vs LLM-only counterfactual" from cost_ledger and decisions_log.
```

---

**After prompt 8,** switch to Claude Code for these `docs/DESIGN.md` tickets:

| Ticket | What Claude Code builds |
|---|---|
| 3 | `useSidekikSession` |
| 4 | the screen-capture worker |
| 6 | wiring `presave.ts` and `domEvents.ts` to the real API |
| 8 | `useTutorSession` |
| 9 | `useAgentHost` |
| 11 | replay mode |
