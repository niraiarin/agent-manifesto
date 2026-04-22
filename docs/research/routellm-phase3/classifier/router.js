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

// Rule-based safety net: これらのプレフィックスを含む prompt は classifier を
// bypass して必ず Cloud に流す。分類器の Cloud → Local 誤分類 (safety risk) を
// 構造的に防ぐ (router-accuracy.md v2 の既知リスク)
const FORCE_CLOUD_PREFIXES = [
  "/research", "/verify", "/formal-derivation", "/evolve", "/ground-axiom",
  "/spec-driven-workflow", "/instantiate-model", "/generate-plugin", "/brownfield",
  "/design-implementation-plan",
];

// Conservative fallback: confidence が中間帯 (0.3-0.5) のときは Local 系予測でも
// Cloud に倒す。非対称リスク対応: Local → Local 誤分類は無害だが Cloud → Local は safety risk。
// v2 (#651): Calibration (isotonic) により confidence と accuracy が一致、conservative fallback 不要化
// router-accuracy.md §7: ECE 0.44 → 0.073。serve.py:oov_threshold=0.3 が OOD detection を担当
const CONSERVATIVE_THRESHOLD = 0.0;  // 旧 logic 無効化 (FORCE_CLOUD_PREFIXES は維持)

// Mapping from routing label to ccr provider,model string
// null = fallback to default (= Cloud via anthropic provider)
const LABEL_TO_PROVIDER = {
  local_confident: "llama-server,qwen3.6-35b-a3b-bf16",
  local_probable: "llama-server,qwen3.6-35b-a3b-bf16",
  cloud_required: null,
  hybrid: null,
  unknown: null,
};

module.exports = async function customRouter(request, allConfig, { event }) {
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

    // Safety net 1: force Cloud for known safety-critical skill prefixes
    const trimmed = prompt.trimStart();
    for (const prefix of FORCE_CLOUD_PREFIXES) {
      if (trimmed.startsWith(prefix)) {
        request.log?.info?.(`[router.js] force-cloud prefix=${prefix}`);
        return null;  // → default (Cloud)
      }
    }

    const resp = await fetch(CLASSIFIER_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt }),
      signal: AbortSignal.timeout(1000),
    });
    if (!resp.ok) return null;

    const { label, confidence, fallback } = await resp.json();

    // Safety net 2: Conservative fallback on mid-confidence Local predictions
    // Cloud→Local misclassification is safety-critical; Local→Cloud is cost-only
    const isLocalLabel = label === "local_confident" || label === "local_probable";
    if (isLocalLabel && confidence < CONSERVATIVE_THRESHOLD) {
      request.log?.info?.(`[router.js] conservative-fallback label=${label} conf=${confidence} → cloud`);
      return null;  // → default (Cloud)
    }

    request.log?.info?.(`[router.js] label=${label} conf=${confidence} fallback=${fallback}`);
    return LABEL_TO_PROVIDER[label] ?? null;
  } catch (err) {
    request.log?.warn?.(`[router.js] classifier unreachable: ${err.message}`);
    return null;  // fallback to default on any error
  }
};
