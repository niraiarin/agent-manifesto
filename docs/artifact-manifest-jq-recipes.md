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

# verifier_history に新 entry append (Day 87 schema 拡張: change_category enum + subagent_dispatch field)
jq '.verifier_history += [{"round": "Week 3 Day NN ...", "date": "2026-04-23", "result": "PASS", "addressable_count": 0, "evaluator": "...", "change_category": "additive_axiom", "subagent_dispatch": false}]' \
   agent-spec-lib/artifact-manifest.json > /tmp/m.json \
   && mv /tmp/m.json agent-spec-lib/artifact-manifest.json
# change_category enum: namespace_only / additive_axiom / additive_definition / additive_test / proof_addition / behavior_change / breaking / metadata_only / process_only / compatible_change
# Day 88 P2 guideline: structure World 拡張 + Inhabited update を含む変更は compatible_change 以上 (additive_axiom 不可)

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

## 11-pending-tasks.json recipes (Day 37、markdown → JSON 完全移行)

`docs/research/new-foundation-survey/11-pending-tasks.json` は同じ thin-catalog / jq-first 原則で運用。Schema: `11-pending-tasks.schema.json` (同ディレクトリ)。人間可読性は二次、narrative は `11-pending-tasks-archive.md` に退役。

```bash
# 全 pending_items の topic + status
PT=docs/research/new-foundation-survey/11-pending-tasks.json
jq '.pending_items[] | {section, topic, status}' $PT

# 特定 section の pending_items
jq '.pending_items[] | select(.section == "2.10")' $PT

# 全 day_plan の scope (done のみ)
jq '.day_plan[] | select(.status == "done") | {day, commit, scope}' $PT

# 次に着手する day (in_progress / pending の先頭)
jq '[.day_plan[] | select(.status == "in_progress" or .status == "pending")] | .[0]' $PT

# 新 day_plan entry 追加 (Day 38 example)
jq '.day_plan += [{"day": 38, "status": "pending", "scope": "Evolution DecidableEq 判定 (Day 36 I2)"}]' \
   $PT > /tmp/pt.json && mv /tmp/pt.json $PT

# day_plan status 更新 (day 指定)
jq '(.day_plan[] | select(.day == 37) | .status) = "done"' $PT \
   > /tmp/pt.json && mv /tmp/pt.json $PT

# 特定 Gap (GA-*) を指す pending_items 列挙
jq '.pending_items[] | select(.gaps[]? == "GA-S11") | .topic' $PT

# roadmap の status を week で参照
jq '.roadmap[] | select(.week == "4-5") | {scope, status}' $PT

# Schema 検証 (artifact-manifest と同パターン)
UV_CACHE_DIR=/tmp/uv-cache UV_TOOL_DIR=/tmp/uv-tools UV_TOOL_BIN_DIR=/tmp/uv-bin \
  uv tool run --from check-jsonschema check-jsonschema \
    --schemafile docs/research/new-foundation-survey/11-pending-tasks.schema.json \
    $PT

# last_updated を date 文字列で更新 (今日の日付)
jq --arg d "$(date -u +%Y-%m-%d)" '.last_updated = $d' $PT \
   > /tmp/pt.json && mv /tmp/pt.json $PT
```

### 11-pending-tasks 禁止 pattern (schema 強制)

- `^day[0-9]+_update$` / `^week[0-9]+_update$` / `^milestone_[0-9]+_day_rfl_preference$` / `^section_[0-9]+(_[0-9]+)?_narrative$` は top-level 追加不可 (patternProperties: false)
- `additionalProperties: false` につき new top-level field は schema 同 commit
- `pending_items[].status` は enum 固定 (pending/in_progress/deferred/done/... 等)、任意文字列は schema reject

## Day cycle compliance check (Day 54.1 追加、再発防止 script)

Day 49-54 の Step 7 mandatory checklist 部分省略 違反の構造的再発防止。commit 前 / Day 完了時に実行推奨。

```bash
# 全 check (breakdown / day_plan commit / 7-day empirical / long-deferred / schema 5 項目)
bash scripts/cycle-check.sh

# quick mode (breakdown + schema のみ、CI 向け高速版)
bash scripts/cycle-check.sh --quick
```

Exit コード:
- 0 = 全 PASS
- 1 = addressable (commit 前に対処)
- 2 = informational (確認推奨、block せず)

検出項目:
1. `build_status.example_count` vs `breakdown_sum` 整合 (Day 37-48 で 59 drift 蓄積の再発防止)
2. `day_plan` 直近 done entry の commit 欄 null 検出 (Day 48/50 で一時放置の再発防止)
3. 7-day empirical cycle 経過日数 (rule I 7 Day 周期、最終 empirical を verifier_history から逆算)
4. long-deferred pending_items (Day N timing の未解消 item、40+ Day stale 検出)
5. JSON Schema 準拠 (artifact-manifest + 11-pending-tasks 両方)
