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

// Mapping from routing label to ccr provider,model string
// null = fallback to default (= Cloud via anthropic provider)
const LABEL_TO_PROVIDER = {
  local_confident: "llama-server,qwen3.6-35b-a3b-bf16",
  local_probable: "llama-server,qwen3.6-35b-a3b-bf16",
  cloud_required: null,
  hybrid: null,
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

    const resp = await fetch(CLASSIFIER_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt }),
      signal: AbortSignal.timeout(1000),  // Don't block routing longer than 1s
    });
    if (!resp.ok) return null;

    const { label, confidence, fallback } = await resp.json();
    request.log?.info?.(`[router.js] label=${label} conf=${confidence} fallback=${fallback}`);

    return LABEL_TO_PROVIDER[label] ?? null;
  } catch (err) {
    request.log?.warn?.(`[router.js] classifier unreachable: ${err.message}`);
    return null;  // fallback to default on any error
  }
};
