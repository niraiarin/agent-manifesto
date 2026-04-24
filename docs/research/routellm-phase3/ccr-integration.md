# ccr CUSTOM_ROUTER_PATH 統合設計

調査結果: ccr 2.x には `CUSTOM_ROUTER_PATH` config オプションが存在。

## 発動機構

`~/.volta/.../claude-code-router/dist/cli.js` 抜粋:

```js
let f = n.get("CUSTOM_ROUTER_PATH");
if (f) try {
  let g = Rt(f);  // require() 相当
  e.tokenCount = A;
  d = await g(e, n.getAll(), { event: s });
} catch(g) {
  e.log.error(`failed to load custom router: ${g.message}`)
}
if (d) e.scenarioType = "default";
else {
  let g = await B6(e, A, n, o);  // default routing
  d = g;
}
```

## 契約

CUSTOM_ROUTER_PATH が指すファイルは CommonJS module で、以下を export する:

```js
module.exports = async function customRouter(request, allConfig, { event }) {
  // request: { messages, tokenCount, log, ... }
  // return: "provider_name,model_name" or null
  // null を返すと default routing にフォールバック
};
```

## Causal LM Router の組込み設計

### 方式 A: embedded classifier (sentence-transformers + linear head)

```js
const { pipeline } = require('@xenova/transformers');
let classifier;

module.exports = async function(request, config, { event }) {
  if (\!classifier) {
    classifier = await pipeline('text-classification', 'local/routing-classifier');
  }
  const prompt = request.messages[request.messages.length - 1].content;
  const [{ label }] = await classifier(prompt);

  switch (label) {
    case 'local_confident':
    case 'local_probable':
      return 'llama-server,qwen3.6-35b-a3b-bf16';
    case 'cloud_required':
      return null;  // default routing (=cloud)
    case 'hybrid':
      return request.tokenCount > 8000
        ? 'llama-server,qwen3.6-35b-a3b-bf16'
        : null;
  }
};
```

### 方式 B: external HTTP service

分類器を別プロセスで稼働、HTTP で呼ぶ。latency +5-20ms だが言語非依存。

```js
module.exports = async function(request, config, { event }) {
  const prompt = request.messages[request.messages.length - 1].content;
  const res = await fetch('http://localhost:9001/classify', {
    method: 'POST', body: JSON.stringify({ prompt })
  });
  const { label } = await res.json();
  // same switch as 方式 A
};
```

## 採用方針

方式 B (external HTTP) を第一採用:
- Python で学習した分類器 (sklearn / sentence-transformers / torch) をそのまま FastAPI で serve
- ccr 側は薄い JS。分類器の実装言語・フレームワーク non-binding
- デバッグが容易（ccr と分類器が別プロセス）

実装ステップ:
1. Python 側: FastAPI + 分類器 endpoint (`POST /classify`)
2. ccr 側: `~/.claude-code-router/router.js` に方式 B の実装
3. config.json に `"CUSTOM_ROUTER_PATH": "~/.claude-code-router/router.js"` 追加
4. `ccr restart` で反映

## 発見日

2026-04-22 (#649 Gap 3 調査中、cli.js grep で確認)
