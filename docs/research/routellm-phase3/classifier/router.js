// router.js — ccr CUSTOM_ROUTER_PATH hook for routing via classifier
//
// Install:
//   1. Copy to ~/.claude-code-router/router.js
//   2. Add to ~/.claude-code-router/config.json:
//        "CUSTOM_ROUTER_PATH": "/Users/<you>/.claude-code-router/router.js"
//   3. Start classifier serve: uv run python3 serve.py
//   4. ccr restart
//
// Behavior:
//   - Extracts last user message
//   - POSTs to classifier service (localhost:9001)
//   - Maps label → provider,model string
//   - Returns null (fallback to default) on any error

const CLASSIFIER_URL = process.env.ROUTING_CLASSIFIER_URL || "http://localhost:9001/classify";

// Decision log sink (append-only JSONL, daily-partitioned). Matches Python
// DecisionLogger. When unset, decision logging is silently disabled.
const DECISION_LOG_DIR = process.env.DECISION_LOG_DIR || null;
const DECISION_LOG_REDACTION = process.env.DECISION_LOG_REDACTION || "prompt_sha_only";
const SCHEMA_VERSION = "1.0.0";
const LOGGER_VERSION = "1.0.0";

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

function newEventId() {
  return crypto.randomUUID();
}

function sha256Hex(text) {
  return crypto.createHash("sha256").update(text).digest("hex");
}

function utcNowIso() {
  return new Date().toISOString().replace(/\.\d{3}/, "");
}

// Per-process session id. ccr starts once per shell, so every request within
// this ccr process shares this id. Claude Code hooks can override by setting
// DECISION_LOG_SESSION_ID before ccr starts.
const _SESSION_ID = process.env.DECISION_LOG_SESSION_ID || `ccr-${newEventId()}`;

function emitDecisionEvent(event) {
  if (!DECISION_LOG_DIR) return;
  try {
    fs.mkdirSync(DECISION_LOG_DIR, { recursive: true });
    const date = new Date().toISOString().slice(0, 10);
    const file = path.join(DECISION_LOG_DIR, `decisions-${date}.jsonl`);
    const envelope = {
      schema_version: SCHEMA_VERSION,
      event_id: event.event_id || newEventId(),
      parent_event_id: event.parent_event_id || null,
      event_type: event.event_type,
      timestamp_utc: utcNowIso(),
      context: event.context || {},
      ...(event.input ? { input: event.input } : {}),
      ...(event.decision ? { decision: event.decision } : {}),
      ...(event.execution ? { execution: event.execution } : {}),
      ...(event.outcome ? { outcome: event.outcome } : {}),
      provenance: {
        schema_version: SCHEMA_VERSION,
        logger_version: LOGGER_VERSION,
        recorded_by: "router.js",
        redaction_level: DECISION_LOG_REDACTION,
        ...(event.provenance || {}),
      },
    };
    fs.appendFileSync(file, JSON.stringify(envelope) + "\n");
    return envelope.event_id;
  } catch (err) {
    // Best-effort: logging must never break routing.
    process.stderr.write(`[router.js] decision log emit failure: ${err.message}\n`);
    return null;
  }
}

// Rule-based safety net: これらのプレフィックスを含む prompt は classifier を
// bypass して必ず Cloud に流す。分類器の Cloud → Local 誤分類 (safety risk) を
// 構造的に防ぐ (router-accuracy.md v2 の既知リスク)
const FORCE_CLOUD_PREFIXES = [
  "/research", "/verify", "/formal-derivation", "/evolve", "/ground-axiom",
  "/spec-driven-workflow", "/instantiate-model", "/generate-plugin", "/brownfield",
  "/design-implementation-plan",
];

// v3 (#651): 期待効用最大化ベースの routing 判定.
// cost_safety:cost_cloud = 2:1 で eval set 上 zero-leak + 98.64% routing accuracy,
// real corpus 1173 件で Local 17.3% (cost_safety=10 の 2x) を両立。
// argmax だと eval で 0.68% leak が出る。非対称コストを明示的に扱うのが正解。
// utility_decision.py の sweep 結果 (analysis/utility-decision.json) 参照。
const COST_SAFETY = parseFloat(process.env.ROUTING_COST_SAFETY || "1.8");
const COST_CLOUD = parseFloat(process.env.ROUTING_COST_CLOUD || "1.0");

const LOCAL_PROVIDER = process.env.ROUTING_LOCAL_PROVIDER || "llama-server,qwen3.6-35b-a3b-bf16";
// null = fallback to default (= Cloud via anthropic provider)

// Circuit breaker: 5 consecutive failures → skip classifier for 30s
let _consecutiveFailures = 0;
let _circuitOpenUntil = 0;
const CB_THRESHOLD = 5;
const CB_COOLDOWN_MS = 30 * 1000;

function utilityDecide(probs, costSafety, costCloud) {
  // probs: {local_confident, local_probable, cloud_required, hybrid, unknown}
  const pLocal = (probs.local_confident ?? 0) + (probs.local_probable ?? 0);
  const pCloud = (probs.cloud_required ?? 0) + (probs.hybrid ?? 0) + (probs.unknown ?? 0);
  const uCloud = pCloud * 1.0 + pLocal * (-costCloud);
  const uLocal = pCloud * (-costSafety) + pLocal * 1.0;
  return uLocal > uCloud ? "local" : "cloud";
}

module.exports = async function customRouter(request, allConfig, { event }) {
  const baseContext = {
    session_id: _SESSION_ID,
    project_id: "agent-manifesto",
  };
  try {
    const msgs = request.messages || [];
    const lastUser = [...msgs].reverse().find(m => m.role === "user");
    if (!lastUser) return null;

    let content = lastUser.content;
    if (Array.isArray(content)) {
      // Anthropic content block format: extract text parts only
      content = content.filter(b => b.type === "text").map(b => b.text).join("\n");
    }
    if (!content || content.length < 8) return null;

    // Cap prompt to ~2KB for classifier latency
    const prompt = content.slice(0, 2000);
    const promptSha = sha256Hex(prompt);

    // Safety net 1: force Cloud for known safety-critical skill prefixes.
    // Search across *full content* (not just 2000-char truncation) to prevent
    // bypass via long preamble (Verifier finding C-2). Check both leading
    // and occurrences at line start.
    for (const prefix of FORCE_CLOUD_PREFIXES) {
      if (content.includes("\n" + prefix) || content.trimStart().startsWith(prefix)) {
        request.log?.info?.(`[router.js] force-cloud prefix=${prefix}`);
        emitDecisionEvent({
          event_type: "router.decision",
          context: baseContext,
          input: { prompt_sha256: promptSha, prompt_length: prompt.length, prompt_source: "hook" },
          decision: {
            kind: "routing",
            action: "force_cloud",
            rule_applied: "force_cloud_prefix",
            rule_inputs: { force_cloud_prefix: prefix },
            rationale_human: `force-cloud prefix matched: ${prefix}`,
          },
        });
        return null;  // → default (Cloud)
      }
    }

    // Circuit breaker check (Verifier finding C-1)
    const now = Date.now();
    if (now < _circuitOpenUntil) {
      request.log?.info?.(`[router.js] circuit open, fallback to default`);
      emitDecisionEvent({
        event_type: "router.decision",
        context: baseContext,
        input: { prompt_sha256: promptSha, prompt_length: prompt.length, prompt_source: "hook" },
        decision: {
          kind: "routing",
          action: "fallback_cloud",
          rule_applied: "circuit_breaker_open",
          rule_inputs: { circuit_breaker: "open", reopen_at_utc: new Date(_circuitOpenUntil).toISOString() },
          rationale_human: "classifier circuit breaker is open; defaulting to cloud",
        },
      });
      return null;
    }

    let resp;
    const classifyBody = {
      prompt,
      session_id: _SESSION_ID,
    };
    try {
      resp = await fetch(CLASSIFIER_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(classifyBody),
        signal: AbortSignal.timeout(1000),
      });
    } catch (err) {
      _consecutiveFailures++;
      if (_consecutiveFailures >= CB_THRESHOLD) {
        _circuitOpenUntil = now + CB_COOLDOWN_MS;
        request.log?.warn?.(`[router.js] circuit opened for ${CB_COOLDOWN_MS}ms after ${_consecutiveFailures} failures`);
      }
      emitDecisionEvent({
        event_type: "router.decision",
        context: baseContext,
        input: { prompt_sha256: promptSha, prompt_length: prompt.length, prompt_source: "hook" },
        decision: {
          kind: "routing",
          action: "error",
          rule_applied: "manual_override",
          rule_inputs: { error_class: err.name, classifier_url: CLASSIFIER_URL },
          rationale_human: `classifier fetch failure: ${err.message}`,
        },
      });
      throw err;
    }
    if (!resp.ok) {
      _consecutiveFailures++;
      emitDecisionEvent({
        event_type: "router.decision",
        context: baseContext,
        input: { prompt_sha256: promptSha, prompt_length: prompt.length, prompt_source: "hook" },
        decision: {
          kind: "routing",
          action: "error",
          rule_applied: "manual_override",
          rule_inputs: { http_status: resp.status },
          rationale_human: `classifier returned HTTP ${resp.status}`,
        },
      });
      return null;
    }
    _consecutiveFailures = 0;

    const classifyJson = await resp.json();
    const { label, confidence, probs, fallback, event_id: classificationEventId } = classifyJson;

    // v3 (#651): Utility-based decision with asymmetric safety cost.
    // Argmax (which classifier label did) can silently leak at ~0.7% even with calibrated probs.
    // Expected-utility decision with cost_safety >= 2 eliminates leak while keeping Local high.
    const pLocal = (probs?.local_confident ?? 0) + (probs?.local_probable ?? 0);
    const pCloud = (probs?.cloud_required ?? 0) + (probs?.hybrid ?? 0) + (probs?.unknown ?? 0);
    const uLocal = pCloud * (-COST_SAFETY) + pLocal * 1.0;
    const uCloud = pCloud * 1.0 + pLocal * (-COST_CLOUD);
    const decision = uLocal > uCloud ? "local" : "cloud";
    const provider = decision === "local" ? LOCAL_PROVIDER : null;

    request.log?.info?.(`[router.js] label=${label} conf=${confidence} utility=${decision} costSafety=${COST_SAFETY}`);

    emitDecisionEvent({
      parent_event_id: classificationEventId || null,
      event_type: "router.decision",
      context: baseContext,
      input: { prompt_sha256: promptSha, prompt_length: prompt.length, prompt_source: "hook" },
      decision: {
        kind: "routing",
        action: decision === "local" ? "route_to_local" : "route_to_cloud",
        rule_applied: fallback ? "fallback_low_confidence" : "utility_max",
        rule_inputs: {
          cost_safety: COST_SAFETY,
          cost_cloud: COST_CLOUD,
          circuit_breaker: "closed",
        },
        rule_outputs: {
          utility_local: Math.round(uLocal * 10000) / 10000,
          utility_cloud: Math.round(uCloud * 10000) / 10000,
          margin: Math.round((uCloud - uLocal) * 10000) / 10000,
        },
        target: {
          provider: decision === "local" ? "ccr" : "anthropic",
          model: decision === "local" ? LOCAL_PROVIDER : "default",
          model_tier: decision === "local" ? "local" : "frontier",
        },
        rationale_human: `utility_${decision} wins (uLocal=${uLocal.toFixed(3)} uCloud=${uCloud.toFixed(3)}); label=${label} conf=${confidence.toFixed(3)}`,
      },
    });

    return provider;
  } catch (err) {
    request.log?.warn?.(`[router.js] classifier unreachable: ${err.message}`);
    return null;  // fallback to default on any error
  }
};
