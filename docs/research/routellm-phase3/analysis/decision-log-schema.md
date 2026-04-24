# Decision Event Log — Schema Documentation

**Status**: v1.0.0 initial design (2026-04-24)
**Purpose**: Capture every routing / tool / workflow decision with enough metadata
that future retrospective analysis becomes possible once ground truth (human GT,
outcome signals, satisfaction ratings) emerges.

Context: LLM routing quality cannot be measured today (no external oracle; see
`qwen-35b-vs-27b.md`). Instead of skipping measurement, we record raw decision
data in an append-only JSONL log. Later analysis can compute accuracy / drift /
preference agreement against whatever ground truth surfaces (human annotation,
outcome observations, long-term user feedback).

## Design principles

1. **Append-only**: every event is immutable. Late signals (user rewind, commit
   hash, subsequent verify result) are written as *new events* that reference an
   earlier `event_id` via `parent_event_id`.
2. **Versioned**: top-level `schema_version` (semver) so forward-compatible
   readers can skip unknown minor changes.
3. **Flat sections**: each dimension (context/input/decision/execution/...) is a
   top-level key — `jq '.decision.action'` stays simple.
4. **Extensible**: consumers MUST ignore unknown fields. New fields land as minor
   version bumps.
5. **Privacy-aware**: prompt content can be stored verbatim *or* redacted to a
   SHA-256 hash. Current default is verbatim (development). Production should
   redact.
6. **Join-ready**: `event_id` (UUIDv4) + `parent_event_id` form a DAG for
   cross-event analysis.

## Event lifecycle

A single user turn emits *multiple* events:

```
user.turn (prompt received)
  └─ router.classification       (mDeBERTa output)
      └─ router.decision         (utility_max, target)
          └─ agent.tool_call*    (zero or many)
          └─ agent.output        (final response delivered)
              ├─ user.rewind?    (later: if user presses ESC-ESC)
              ├─ user.correction?(later: if user corrects)
              ├─ outcome.verify? (later: /verify result on this work)
              └─ outcome.commit? (later: git commit that embodies this work)
```

Each arrow is `parent_event_id`. The log captures the full DAG, not just
isolated decisions.

## Top-level envelope

Every event has this shape:

```jsonc
{
  "schema_version": "1.0.0",
  "event_id": "550e8400-e29b-41d4-a716-446655440000",   // UUIDv4
  "parent_event_id": null | "uuid-v4",                   // null = root
  "event_type": "router.classification",                 // see enum below
  "timestamp_utc": "2026-04-24T14:30:00.123Z",           // ISO 8601 millis + Z
  "context": { /* section */ },
  "input":   { /* section, optional per event_type */ },
  "decision":{ /* section, optional per event_type */ },
  "execution":{ /* section, optional per event_type */ },
  "outcome": { /* section, optional per event_type */ },
  "provenance":{ /* section */ }
}
```

### `event_type` enum (v1.0.0)

| event_type | typical parent | required sections |
|---|---|---|
| `user.turn` | null | input |
| `router.classification` | `user.turn` | input, decision.classification |
| `router.decision` | `router.classification` | decision |
| `agent.tool_call` | `router.decision` | input, decision (tool), execution |
| `agent.output` | `router.decision` | execution, outcome (immediate) |
| `user.rewind` | `agent.output` | outcome |
| `user.correction` | `agent.output` | input |
| `outcome.verify` | `agent.output` | outcome |
| `outcome.commit` | `agent.output` | outcome |
| `outcome.pr_merged` | `outcome.commit` | outcome |
| `subagent.invocation` | `router.decision` | input, decision, execution |
| `skill.invocation` | `router.decision` | input, decision, execution |
| `manual.note` | anything | (free-form in `outcome.human_note`) |

Unknown `event_type` MUST be preserved by readers (treated as opaque). This
future-proofs additions like `outcome.human_gt_assigned`.

## `context` section

```jsonc
"context": {
  "session_id":         "sha-of-session",                  // Claude Code session UUID
  "turn_id":            42,                                 // monotonic within session
  "sequence_id":        17,                                 // monotonic within turn (tool_call index)
  "project_id":         "agent-manifesto",
  "project_path":       "/Users/nirarin/work/agent-manifesto",
  "working_directory":  "/Users/nirarin/work/agent-manifesto-research-671",
  "git_branch":         "research/671-qwen-llm-annotation",
  "git_commit_sha":     "e64c52f",
  "git_worktree":       true,
  "tz":                 "Asia/Tokyo",
  "machine_id":         "sha-of-hostname",                 // anonymizable
  "os":                 "darwin-25.3.0",
  "cli_version":        "claude-code-2.1.117",
  "model_version":      "claude-opus-4-7-1m"
}
```

## `input` section

Shared shape across events that carry a prompt:

```jsonc
"input": {
  "prompt":             "text OR null",                   // verbatim or redacted
  "prompt_sha256":      "hex 64 chars",                    // always present
  "prompt_length":      420,                               // chars
  "prompt_language":    "ja",                              // ISO 639-1
  "prompt_source":      "user" | "hook" | "subagent_return" | "cron",
  "context_preview_sha":"hex",                             // hash of prior N turns
  "tool_context_sha":   "hex",                             // hash of tool outputs in window
  "file_context":       ["path/a.py", "path/b.md"],        // files read/implied
  "environment_vars": { "ROUTING_COST_SAFETY": "1.8" }     // relevant envs only
}
```

When `event_type = user.correction` the same fields apply; the text is the
user's follow-up turn.

## `decision` section

### 1. `decision.classification` (router.classification)

```jsonc
"decision": {
  "kind": "classification",
  "classifier_id":        "mdeberta-v3-base-agent-manifesto",
  "classifier_model_hash":"sha-of-model-files",
  "classifier_version":   "2026-04-23T12:00Z",
  "probs": {
    "local_confident": 0.10,
    "local_probable":  0.17,
    "cloud_required":  0.48,
    "hybrid":          0.20,
    "unknown":         0.05
  },
  "predicted_label":      "cloud_required",
  "predicted_confidence": 0.48,
  "p_local":              0.27,
  "p_cloud":              0.73,
  "alt_classifiers": [
    {"id":"qwen3.6-35b-a3b-q2", "label":"local_confident", "confidence":null, "source":"offline-batch-2026-04-23"},
    {"id":"qwen3.6-27b-q4",     "label":"cloud_required",  "confidence":null, "source":"offline-batch-2026-04-24"}
  ],
  "latency_ms": 80.4
}
```

### 2. `decision` (router.decision)

```jsonc
"decision": {
  "kind":                 "routing",
  "action":               "route_to_cloud",              // route_to_cloud | route_to_local | fallback_cloud | force_cloud | error
  "rule_applied":         "utility_max",                 // utility_max | fallback_low_confidence | force_cloud_prefix | circuit_breaker_open | manual_override
  "rule_inputs": {
    "cost_safety":        1.8,
    "cost_cloud":         1.0,
    "oov_threshold":      0.3,
    "force_cloud_prefix": null,                          // "`/research`" if matched
    "circuit_breaker":    "closed"                       // closed | open | half_open
  },
  "rule_outputs": {
    "utility_local":     -0.27,
    "utility_cloud":      0.70,
    "margin":             0.97
  },
  "target": {
    "provider":           "anthropic",                    // anthropic | ccr | llama-server | subagent
    "model":              "claude-opus-4-7",
    "endpoint":           "https://api.anthropic.com/v1/messages",
    "model_tier":         "frontier"                      // frontier | mid | small | local
  },
  "alternatives_considered": [
    {"target":"ccr/qwen3.6-35b-a3b", "utility":-0.27, "rejected_because":"utility < cloud"}
  ],
  "rationale_human":      "utility_cloud (0.70) > utility_local (-0.27); no force prefix; circuit breaker closed."
}
```

### 3. `decision` (agent.tool_call, skill.invocation, subagent.invocation)

```jsonc
"decision": {
  "kind":   "tool_call" | "skill_invocation" | "subagent_invocation",
  "name":   "Edit" | "/research" | "code-review",
  "args_sha":"hex",                                        // hash args JSON
  "args_preview":"first 200 chars of stringified args"
}
```

## `execution` section

Applies to events that actually execute something.

```jsonc
"execution": {
  "started_at_utc": "2026-04-24T14:30:00.123Z",
  "ended_at_utc":   "2026-04-24T14:30:01.367Z",
  "duration_ms":    1244,
  "success":        true,
  "error_class":    null,                                  // "TimeoutError", "JSONDecodeError", ...
  "error_message":  null,
  "retry_count":    0,
  "tool_calls_made":["Read","Edit"],
  "files_read":     ["docs/foo.md"],
  "files_modified": ["src/bar.py"],
  "tokens_in":      420,
  "tokens_out":     1100,
  "output_sha256":  "hex"
}
```

## `outcome` section

Split into `observable_now` and `observable_later` semantics. In practice they
land in different events (via parent_event_id), but the shape is uniform.

### Immediate outcomes (agent.output, agent.tool_call)

```jsonc
"outcome": {
  "horizon":         "immediate",
  "exit_status":     "completed",                          // completed | interrupted | failed | blocked
  "tool_calls_count":3,
  "output_tokens":   1100,
  "response_hash":   "hex"
}
```

### Late outcomes (user.rewind, user.correction, outcome.verify, outcome.commit, outcome.pr_merged, outcome.human_gt_assigned)

```jsonc
"outcome": {
  "horizon":               "late",
  "user_rewind":           true,                           // ESC-ESC detected
  "user_correction_prompt_sha":"hex",
  "time_to_rewind_ms":     8200,
  "subsequent_verify": {
    "status":"PASS",
    "findings_count":0,
    "addressable":0
  },
  "git_commit_hash":       "abc123",
  "pr_number":             674,
  "pr_merged_at_utc":      "2026-04-24T03:05:00Z",
  "human_gt_label":        "cloud_required",
  "human_gt_annotator":    "alice",
  "human_gt_notes":        "/research command requires orchestration",
  "satisfaction_signal":   null                            // +1 / -1 / null
}
```

## `provenance` section

```jsonc
"provenance": {
  "logger_version":  "1.0.0",
  "schema_version":  "1.0.0",
  "recorded_by":     "router.js" | "serve_encoder" | "claude-code-hook" | "decision_logger.py",
  "hook_id":         "PreToolUse.decision-log",
  "redaction_level": "none" | "prompt_sha_only"
}
```

## Storage

- **Format**: JSONL, one event per line.
- **Path**: `docs/research/routellm-phase3/logs/decisions-YYYY-MM-DD.jsonl`
  (daily partition; analysis scripts glob `decisions-*.jsonl`).
- **Rotation**: new file at UTC midnight. No rewrites to prior-day files.
- **Compression**: files older than 7 days SHOULD be `gzip`'d — readers must
  handle both `.jsonl` and `.jsonl.gz`.
- **Retention**: unlimited by default. Runbook should include a prune command
  referencing `find -mtime +N`.

## Integrity & safety

- Writers SHOULD write one line per event atomically (`open(..., 'a')` with
  line-buffered `write(json.dumps(event, ensure_ascii=False) + "\n")`).
- Writers MUST NOT block the caller. If I/O fails, caller behavior is
  unaffected (logger is best-effort). Log the write failure to stderr.
- Readers MUST tolerate partially written lines (truncate at last valid
  newline).
- Secrets MUST NOT appear in `input.prompt` when the session writes tokens
  (Bearer, API keys). Writers SHOULD redact `Authorization:` headers and
  `*.env` contents; future work: regex scrub or opt-in salted-hash.

## Analysis recipes

### Routing accuracy once human GT arrives

```bash
# Join router.classification with outcome.human_gt_assigned by event_id chain
jq -s '
  [.[] | select(.event_type == "router.classification")] as $cls |
  [.[] | select(.event_type == "outcome.human_gt_assigned")] as $gt |
  $cls | map(
    . + {human_gt: (
      $gt[] | select(.parent_event_id == .event_id) | .outcome.human_gt_label
    )}
  ) | map(select(.human_gt))
  | map({predicted: .decision.predicted_label, gt: .human_gt})
' decisions-*.jsonl
```

### User rewind rate per classifier

```bash
jq -s '
  group_by(.provenance.recorded_by)
  | map({by: .[0].provenance.recorded_by, n: length,
         rewinds: map(select(.event_type == "user.rewind")) | length})
' decisions-*.jsonl
```

### Commit rate by predicted label

```bash
jq -r 'select(.event_type == "router.classification")
     | [.event_id, .decision.predicted_label] | @tsv' decisions-*.jsonl > /tmp/cls.tsv
jq -r 'select(.event_type == "outcome.commit")
     | [.parent_event_id, .outcome.git_commit_hash] | @tsv' decisions-*.jsonl > /tmp/cmt.tsv
# join -t$'\t' -1 1 -2 1 ...
```

## Roadmap (explicit non-goals for v1)

- **Sampling**: everything is logged verbatim. Sampling/downsampling is v1.1.
- **Schema migration**: only breaking changes bump major (v2.0.0). Adding fields
  = minor bump.
- **Real-time analytics**: v1 targets batch analysis. Streaming in v2.
- **Multi-machine aggregation**: v1 is single-machine. Multi-machine rollup
  is follow-up.

## References

- `docs/research/routellm-phase3/classifier/serve_encoder.py` — existing
  `DriftLogger` emits a predecessor of `router.classification` (label,
  confidence, fallback, latency, label/ts/sha). Decision logger is a superset.
- `docs/research/routellm-phase3/classifier/router.js` — should gain a
  `router.decision` emitter.
- `.claude/hooks/` — candidate location for PreToolUse / UserPromptSubmit
  hooks that emit `user.turn`, `user.correction`, `user.rewind`.
- `docs/research/routellm-phase3/classifier/monitor_drift.py` — current drift
  analysis, can be re-pointed at `router.classification` events in the new log.
