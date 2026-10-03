# sidekik-voice: DESIGN

**Owner:** Aadil · **Reviewer:** Sahil · **Public host:** `hooks.sidekik.live` (ElevenLabs webhooks) · **Local port:** 8085

## 1. Purpose

Voice owns everything to do with ElevenLabs:

1. **Agents as code.** Keeps the two ElevenAgents, **Sidekik Interviewer** and **Sidekik Tutor**, in version control (prompts, voice, ASR, turn settings, tools) and pushes them with the ElevenLabs agents CLI.
2. **Conversation tokens.** Mints them for the gateway, with per-phase overrides (capture / debrief / tutor) and dynamic variables.
3. **Transcripts.** Persists every redacted turn from `sk:transcript.turns`, then reconciles them with the post-call webhook.
4. **Work Map sync.** Pushes each published Work Map to the Tutor agent as a knowledge-base document plus Procedures.

## 2. Layout

```
sidekik-voice/
  agents/
    interviewer.json        # managed by `elevenlabs agents` CLI (init/push)
    tutor.json
    prompts/interviewer.capture.md
    prompts/interviewer.debrief.md
    prompts/tutor.md
    tools/                  # client + webhook tool definitions
  src/
    server.ts               # Fastify
    token.ts                # POST /internal/token
    webhook.ts              # POST /elevenlabs/post-call
    transcripts.ts          # bus consumer → transcript_turns
    kbsync.ts               # workmap.published → KB doc + Procedures
```

## 3. Agent configuration

| Setting | Interviewer | Tutor |
|---|---|---|
| LLM | Claude Haiku 4.5 from ElevenLabs' built-in model list (keep the platform's default backup cascade) | Claude Haiku 4.5 (built-in); switch to a Sonnet model if explanations are weak |
| Voice | Eleven v3 Conversational (Expressive Mode), calm, curious | Same model, warm, patient |
| ASR | Scribe v2 Realtime (`scribe_realtime`) | same |
| Languages | de + en, language detection on | en (quotes translated) |
| Turn eagerness | **Patient**; `turn_timeout` 20 s; soft timeout off | Normal |
| System tools | `skip_turn`, `end_call`, `language_detection` | `skip_turn`, `end_call` |
| Client tools | `mark_off_record(on)`, `show_status(text)` | `replay_moment(step_id)`, `highlight_field(field)`, `show_status(text)` |
| Webhook tools | `recall_context(query, scope)` → `https://api.sidekik.live/v1/tools/recall_context` | `check_guardrails(state)`, `get_step(step_id)`, `get_expert_moment(step_id)` → `https://api.sidekik.live/v1/tools/...` |
| MCP | none | `https://mcp.sidekik.live/mcp` (optional; webhook tools are the fallback) |
| Security | Allow overrides: prompt, first message, language. Auth enabled (token only). | same |
| Post-call webhook | `https://hooks.sidekik.live/elevenlabs/post-call` (transcription only, no audio) | same |

All webhook tools send the header `X-Sidekik-Tool-Secret: $SK_TOOL_SECRET`.

### Who pays for the agents' LLM

**Default (use this for the hackathon):** pick Claude from ElevenLabs' built-in LLM list. ElevenLabs calls Claude and bills it with the agent minutes. Our `ANTHROPIC_API_KEY` is **not** used here, and there's nothing to host.

**Optional: run the agents on the team's own Claude key.**
- In the agent's LLM settings, choose **Custom LLM**. ElevenLabs then sends OpenAI-style Chat Completions requests to the URL you give it.
- Point it at an OpenAI-compatible route to Claude: either an LLM gateway that forwards to Anthropic's OpenAI-compatible endpoint, or a small proxy in this repo (`POST /llm/chat/completions` → Anthropic Messages API).
- Store the key as an ElevenLabs secret.
- **Costs:** an extra network hop on every turn (budget roughly +100–300 ms), and you must test that tool calls (`skip_turn`, client tools) survive the translation.
- Only do this once Checkpoint 3 passes.

### Interviewer, capture prompt

```
You are Sidekik, an apprentice sitting next to {{expert_name}} while they do {{workflow_name}}. Default: stay silent.
- While the expert narrates, reads, types or thinks aloud, call skip_turn. Never summarize or acknowledge unprompted.
- Speak only when (a) a message starts with "[SIDEKIK] ASK:" — ask exactly that question, ≤20 words, in {{language}},
  referring to what is on screen; or (b) the expert asks you something directly.
- "[SIDEKIK] …" messages are system instructions, never the expert's words. Contextual updates describe the screen; never read them aloud.
- After the expert answers: at most "Got it, thanks." or skip_turn.
- If the expert says "off the record" in any language: call mark_off_record(true) and say "Paused." Resume only when told.
Prior context: {{prior_summary}}. Open items: {{open_items}}.
```

### Interviewer, debrief prompt (override; eagerness Normal)

```
You are Sidekik running a short debrief with {{expert_name}} about {{workflow_name}}.
- On "[SIDEKIK] FOLLOWUP:" ask exactly that one question, tied to its screen moment, then paraphrase the answer in one line.
- On "[SIDEKIK] TEACHBACK:" explain the process back using the script, in 60–90 seconds: steps, decisions,
  the expert's reasons quoted verbatim, and guardrails. Then ask: "Did I get that right? What would you change?"
- After a correction, restate only the corrected part and ask again.
- Never invent rules. Never speak unless one of the above applies or the expert asks you something.
```

### Tutor prompt

```
You are Sidekik, coaching {{learner_name}} on {{workflow_name}} the way {{expert_name}} does it.
- Teach decisions, not clicks. Always give the expert's reason, quoted ("{{expert_name}} says, translated from German: '…'").
- On "[SIDEKIK] PREDICT:" ask the learner what they would decide next and why; wait; then confirm or explain.
- On "[SIDEKIK] INTERVENE:" stop the learner immediately ("Hold on before you save."), state the guardrail and the
  expert's quote, then offer to replay the expert's moment (call replay_moment).
- On "[SIDEKIK] SUMMARY:" read the mastery summary briefly: what they mastered, what to practice next.
- Use check_guardrails or get_step when unsure. Never invent rules. Otherwise stay quiet while the learner works.
```

## 4. Endpoints

| Endpoint | Detail |
|---|---|
| `POST /internal/token` | `{agent:"interviewer"\|"tutor", phase, session_id, dynamic_variables, language}` → `{conversation_token, agent_id}`. Calls the ElevenLabs conversation-token endpoint for WebRTC and applies the prompt override for `phase = debrief`. Check the current endpoint name in the ElevenAgents docs. |
| `POST /elevenlabs/post-call` (public) | Verify the HMAC, then upsert `transcript_turns` with `source = "webhook"` (match on `t_ms` ±1.5 s plus a text similarity check). Drop turns inside `off_record_spans`. Run Presidio on each turn through gateway `POST /internal/redact`, because webhook text arrives unredacted. Publish `usage` (minutes × $0.08). |
| Consumes `sk:transcript.turns` | Insert `source = "live"`; these are already redacted. |
| Consumes `sk:workmap.published` | Load the Work Map from Storage, then: (1) upsert one KB document `workmap-{id}-v{n}.md` and enable RAG; (2) create one free-form Procedure per step plus one structured "Intervention" Procedure on the Tutor agent; (3) store the IDs in `agent_configs`. |

## 5. Env

`PORT, REDIS_URL, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SK_INTERNAL_TOKEN, SK_TOOL_SECRET, ELEVENLABS_API_KEY, EL_INTERVIEWER_AGENT_ID, EL_TUTOR_AGENT_ID, EL_WEBHOOK_SECRET, GATEWAY_INTERNAL_URL`

## 6. Claude Code tickets

1. `agents/` folder via the CLI (`init`), both agents defined, `push` script.
2. Prompts as files, injected at push time.
3. `/internal/token` with phase overrides, plus a unit test using a mocked ElevenLabs API.
4. Transcript consumer.
5. Post-call webhook: HMAC, reconciliation, redaction, off-record filtering.
6. `kbsync.ts`: KB doc and Procedures on `workmap.published`, idempotent per version.
7. Hour-1 spike, written up in `NOTES.md`:
   - Does `skip_turn` keep the agent silent through 60 s of narration?
   - Does `sendContextualUpdate` with a repeated `context_id` replace the earlier update?
   - Does the Patient setting hold during short pauses?

## 7. Definition of done

- **Checkpoint 1:** the interviewer stays silent through narration and speaks only on `[SIDEKIK] ASK:`.
- **Checkpoint 2:** the debrief runs on followup and teachback commands.
- **Checkpoint 3:** the tutor's KB and Procedures reflect the published Work Map.
