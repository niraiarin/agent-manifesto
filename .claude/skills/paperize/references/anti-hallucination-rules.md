# Anti-Hallucination Rules

Source: [S2 §4] PaperOrchestra Lit Review + Content Refinement twin defense

内部研究版に適応。外部引用は optional、**internal citation** を第一級化する。

## Rules

### R1: `[UNVERIFIED]` tag 強制

Phase 2 Extraction で `manifest.json:verifications[].evaluator_independent` が
`null` / `false` のエントリから抽出した narrative は必ず `[UNVERIFIED]` tag を付与。

例:
> K-plateau は K=16 以降で improvement が頭打ち [UNVERIFIED: sample-based, not rigorous].

### R2: Internal citation は hash 必須

Phase 2 で PR / issue / commit を引用する場合、SHA prefix (8 文字) を必ず含める。
例: `(PR #637, commit 76c18fa3)` ✓ / `(PR #637)` ✗

### R3: 外部引用は空のまま許容

arXiv / Semantic Scholar は呼ばない（cost）。もし外部を引用する必要があれば、
**LLM に URL を生成させない**。`paperize.yaml:input.external_citations:` に人手で記入。

### R4: "data が存在しなければ無視" ルール

Refinement phase で verifier が「新規 experiment を追加せよ」と要求した場合、
`evidence/` / `manifest.json` に該当データが無ければ:
- 該当 section の主張を弱めるか削除
- 新 experiment を追加しない
- `questions` カテゴリに "need additional experiment for X" を記入

### R5: Numeric claim は source 参照必須

「+10.9pp improvement」「K=16 plateau」等の数値主張は、`evidence/` 中のファイル
または `manifest.json:verifications[].margin` を指す内部 citation を付ける。
