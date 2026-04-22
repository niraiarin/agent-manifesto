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

// v3 (#651): 期待効用最大化ベースの routing 判定.
// cost_safety:cost_cloud = 2:1 で eval set 上 zero-leak + 98.64% routing accuracy,
// real corpus 1173 件で Local 17.3% (cost_safety=10 の 2x) を両立。
// argmax だと eval で 0.68% leak が出る。非対称コストを明示的に扱うのが正解。
// utility_decision.py の sweep 結果 (analysis/utility-decision.json) 参照。
const COST_SAFETY = parseFloat(process.env.ROUTING_COST_SAFETY || "2.0");
const COST_CLOUD = parseFloat(process.env.ROUTING_COST_CLOUD || "1.0");

const LOCAL_PROVIDER = "llama-server,qwen3.6-35b-a3b-bf16";
// null = fallback to default (= Cloud via anthropic provider)

function utilityDecide(probs, costSafety, costCloud) {
  // probs: {local_confident, local_probable, cloud_required, hybrid, unknown}
  const pLocal = (probs.local_confident ?? 0) + (probs.local_probable ?? 0);
  const pCloud = (probs.cloud_required ?? 0) + (probs.hybrid ?? 0) + (probs.unknown ?? 0);
  const uCloud = pCloud * 1.0 + pLocal * (-costCloud);
  const uLocal = pCloud * (-costSafety) + pLocal * 1.0;
  return uLocal > uCloud ? "local" : "cloud";
}

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

    const { label, confidence, probs, fallback } = await resp.json();

    // v3 (#651): Utility-based decision with asymmetric safety cost.
    // Argmax (which classifier label did) can silently leak at ~0.7% even with calibrated probs.
    // Expected-utility decision with cost_safety >= 2 eliminates leak while keeping Local high.
    const decision = utilityDecide(probs || {}, COST_SAFETY, COST_CLOUD);
    const provider = decision === "local" ? LOCAL_PROVIDER : null;
    request.log?.info?.(`[router.js] label=${label} conf=${confidence} utility=${decision} costSafety=${COST_SAFETY}`);
    return provider;
  } catch (err) {
    request.log?.warn?.(`[router.js] classifier unreachable: ${err.message}`);
    return null;  // fallback to default on any error
  }
};
