# artifact-manifest.json jq recipes

Day 29.1 以降、`agent-spec-lib/artifact-manifest.json` は **thin artifact catalog** として運用。
CRUD 操作は jq + 標準ツール経由で行う (narrative 直書き禁止、per-Day story は git log へ)。

## Role 定義

- **保持する情報**: artifact metadata (dependencies / provides_types / provides_definitions / assumptions / scope / refs) / build_status 現在値 snapshot / verifier_history compact log
- **保持しない情報**: per-Day narrative / milestone labels / long-deferred narrative / subagent_verification 物語 (details は git log と docstring へ)

## Read / Query recipes

```bash
# 全 artifact の id + scope
jq '.artifacts[] | {id, scope}' agent-spec-lib/artifact-manifest.json

# 指定 type を提供する artifact 検索
jq '.artifacts[] | select(.provides_types[]? | contains("ResearchActivity")) | .id' agent-spec-lib/artifact-manifest.json

# 指定 module に依存する artifacts を検索
jq --arg target "agent-spec-lib:AgentSpec.Process.Hypothesis" \
   '.artifacts[] | select(.dependencies[]?.id == $target) | .id' \
   agent-spec-lib/artifact-manifest.json

# scope 別 artifact 件数
jq '.artifacts | group_by(.scope) | map({scope: .[0].scope, count: length})' \
   agent-spec-lib/artifact-manifest.json

# 現在の build status snapshot
jq '.build_status | {last_verified, last_verified_phase, lake_build_results}' \
   agent-spec-lib/artifact-manifest.json

# 最新 verifier_history entry
jq '.verifier_history[-1]' agent-spec-lib/artifact-manifest.json

# 直近 5 entries の result 推移
jq '.verifier_history[-5:] | map({round, date, result, addressable_count})' \
   agent-spec-lib/artifact-manifest.json

# 全 verifier_history で addressable_count > 0 の Round
jq '.verifier_history[] | select(.addressable_count > 0) | {round, result, addressable_count}' \
   agent-spec-lib/artifact-manifest.json

# example_count 総和検算 (breakdown vs build_status)
jq '[.build_status.breakdown | to_entries[] | .value.examples] | add as $sum |
    {sum_of_breakdown: $sum, build_status_total: $build_status.example_count}' \
   agent-spec-lib/artifact-manifest.json
```

## Update recipes (in-place は tmp 経由)

```bash
# version bump
jq '.version = "0.30.0-week2-day30"' agent-spec-lib/artifact-manifest.json \
   > /tmp/m.json && mv /tmp/m.json agent-spec-lib/artifact-manifest.json

# 新規 artifact entry 追加 (idempotent check 付き)
jq --slurpfile new /tmp/new-artifact.json \
   'if (.artifacts | map(.id) | index($new[0].id)) then . else .artifacts += $new end' \
   agent-spec-lib/artifact-manifest.json > /tmp/m.json \
   && mv /tmp/m.json agent-spec-lib/artifact-manifest.json

# 既存 artifact の field 更新 (id 指定)
jq '(.artifacts[] | select(.id == "agent-spec-lib:AgentSpec.Provenance.ResearchActivity") | .example_count) = 43' \
   agent-spec-lib/artifact-manifest.json > /tmp/m.json \
   && mv /tmp/m.json agent-spec-lib/artifact-manifest.json

# verifier_history に新 entry append
jq '.verifier_history += [{"round": "Week 2 Day 30 Round 1", "date": "2026-04-21", "result": "PASS", "addressable_count": 0, "evaluator": "..."}]' \
   agent-spec-lib/artifact-manifest.json > /tmp/m.json \
   && mv /tmp/m.json agent-spec-lib/artifact-manifest.json

# build_status の job_count / counts 更新
jq '.build_status.lake_build_results.AgentSpec.job_count = 105' \
   agent-spec-lib/artifact-manifest.json > /tmp/m.json \
   && mv /tmp/m.json agent-spec-lib/artifact-manifest.json
```

## Delete recipes

```bash
# 指定 id の artifact 削除
jq 'del(.artifacts[] | select(.id == "agent-spec-lib:OldModule"))' \
   agent-spec-lib/artifact-manifest.json > /tmp/m.json \
   && mv /tmp/m.json agent-spec-lib/artifact-manifest.json

# verifier_history の古い entry 切り詰め (最新 N 件のみ保持、N=10)
jq '.verifier_history |= .[-10:]' \
   agent-spec-lib/artifact-manifest.json > /tmp/m.json \
   && mv /tmp/m.json agent-spec-lib/artifact-manifest.json
```

## Validation

```bash
# JSON 構文検査
jq empty agent-spec-lib/artifact-manifest.json && echo OK

# breakdown 合計が build_status.example_count と一致するか
jq '[.build_status.breakdown | to_entries[] | .value.examples] | add as $sum |
    if $sum == .build_status.example_count then "OK" else "MISMATCH: sum=\($sum) stated=\(.build_status.example_count)" end' \
   agent-spec-lib/artifact-manifest.json

# JSON Schema 準拠 (Day 29.2 導入、thin catalog + narrative forbid 強制)
UV_CACHE_DIR=/tmp/uv-cache UV_TOOL_DIR=/tmp/uv-tools UV_TOOL_BIN_DIR=/tmp/uv-bin \
  uv tool run --from check-jsonschema check-jsonschema \
    --schemafile agent-spec-lib/artifact-manifest.schema.json \
    agent-spec-lib/artifact-manifest.json
```

## Navigation patterns (Day 29.2、arXiv:2604.14572 Corpus2Skill 示唆)

```bash
# Zoom-out: 層一覧で scope を把握 (最小 context、最初に読む)
jq '.navigation_index.by_layer.Provenance' agent-spec-lib/artifact-manifest.json

# Zoom-in: 層で絞った後、特定 module の詳細を取得
jq '.artifacts[] | select(.id == "agent-spec-lib:AgentSpec.Provenance.ProvRelation")
     | {provides_types, dependencies, refs}' \
   agent-spec-lib/artifact-manifest.json

# Test pair lookup: production → test
jq '.navigation_index.test_pairs."AgentSpec.Provenance.ProvRelation"' \
   agent-spec-lib/artifact-manifest.json

# Concern-based search (navigation_index にない場合の fallback、regex で grep)
jq '[.artifacts[] | select(.id | test("Retirement"; "i")) | .id]' \
   agent-spec-lib/artifact-manifest.json
```

## 禁止事項 (Day 27 efficiency audit 教訓)

- **python `json.dump` 禁止**: 全体 reformat で noise commit を生む (Day 27 で 1095 行 noise 実例)
- **narrative field 追加禁止**: `dayN_update` / `milestone_*` / `long_deferred_resolved` 等は git log/ docstring へ
- **ceremonial token 禁止**: 「N 度目」「N 段階発展」等の装飾 status は記録しない
