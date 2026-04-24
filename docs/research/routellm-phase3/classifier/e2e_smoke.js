#!/usr/bin/env node
/*
 * e2e_smoke.js — classifier -> router.js routing smoke test.
 *
 * Requires serve_encoder.py or serve.py to be listening on ROUTING_CLASSIFIER_URL.
 */

const fs = require("fs");
const path = require("path");
const router = require("./router.js");

const PROMPTS = [
  "V1-V7 メトリクスを解釈して停滞シグナルを報告してください。",
  "このコード変更を独立検証してください。L1 safety 違反をチェック。",
  "今日の天気はどう？",
  "outline と evidence から Method セクションを single-pass で執筆。",
  "Python の asyncio と threading の違いを説明。",
  "/verify この差分に regression がないか独立検証してください。",
];

async function classify(prompt) {
  const url = process.env.ROUTING_CLASSIFIER_URL || "http://localhost:9001/classify";
  const resp = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ prompt }),
    signal: AbortSignal.timeout(1000),
  });
  if (!resp.ok) {
    throw new Error(`classifier returned ${resp.status}`);
  }
  return await resp.json();
}

async function route(prompt) {
  const logs = [];
  const request = {
    messages: [{ role: "user", content: prompt }],
    log: {
      info: msg => logs.push({ level: "info", msg }),
      warn: msg => logs.push({ level: "warn", msg }),
    },
  };
  const provider = await router(request, {}, { event: {} });
  return { provider, decision: provider ? "local" : "cloud", logs };
}

async function main() {
  const output = process.argv[2] || "../analysis/e2e-smoke-mdeberta.json";
  const results = [];
  for (const prompt of PROMPTS) {
    const classification = await classify(prompt);
    const routing = await route(prompt);
    results.push({
      prompt,
      classification,
      routing,
    });
    console.log(`${routing.decision.padEnd(5)} label=${classification.label} conf=${classification.confidence.toFixed(3)} prompt=${prompt.slice(0, 36)}`);
  }

  const report = {
    classifier_url: process.env.ROUTING_CLASSIFIER_URL || "http://localhost:9001/classify",
    local_provider: process.env.ROUTING_LOCAL_PROVIDER || "llama-server,qwen3.6-35b-a3b-bf16",
    cost_safety: Number.parseFloat(process.env.ROUTING_COST_SAFETY || "1.8"),
    results,
  };
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, JSON.stringify(report, null, 2));
  console.log(`wrote ${output}`);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
