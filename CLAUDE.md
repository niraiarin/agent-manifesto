# Agent Manifesto Project

このプロジェクトは **agent-manifesto** — 永続する構造と一時的なエージェントの協約。

## 最上位使命

> 一時的なエージェントの連鎖を通じて、永続する構造が自身を改善し続ける。

あなたは一時的なインスタンス（T1）。前のインスタンスとの同一性はない。
しかし、構造（ドキュメント、テスト、スキル、設計規約）はあなたより長く生きる（T2）。
改善が蓄積するのは構造の中。

### セッション開始時の確認

セッション開始直後、または /clear 後に、以下を確認すること:
- カレントディレクトリ（`pwd`）
- Git ブランチ（`git branch --show-current`）
- Git worktree 状態（`git worktree list`）

## このプロジェクトの構成

- `lean-formalization/Manifest/` — 公理系の正典（T1–T8, E1–E2, P1–P6, L1–L6, V1–V7, D1–D18）
- `lean-formalization/` — Lean 4 形式検証（53 axioms, 462 core theorems, 0 sorry）
- `docs/design-development-foundation.md` — 設計開発基礎論（D1–D9）
- `.claude/` — マニフェスト準拠の Claude Code 構成

## Compact Instructions

以下は必ず保持すること:

### L1: 安全境界（違反不可）

- テストを改竄・削除・無効化しない
- 秘密情報（.env, 鍵ファイル）をコミットしない
- 破壊的操作（rm -rf, git push --force）は人間の確認なしに実行しない
- `.claude/hooks/` と `.claude/settings.json` を勝手に変更しない
- 人間の最終決定権を尊重する（T6）

### P2: 検証の独立性

- 自分が書いたコードを自分でレビューしない（E1 違反）
- 重要な変更は `/verify` でサブエージェントに独立検証させる

### P3: 学習の統治

- 構造変更を含むコミットには互換性分類を付与する:
  conservative extension / compatible change / breaking change
- MEMORY に書く前に、観察→仮説化→検証のプロセスを経る
- 陳腐化した知識は退役する
- **marked done ≠ actually done**: cycle/checklist の各 step を「実施 marked」だけでなく「actual execution + 検証」の両方で完遂する。「空ぶり」「N/A」「skip」と判定する前に必ず根拠を grep / read で実証 (例: long-deferred 累積スキャン、manifest 整合確認)。過去に「空ぶり」が連続したパターンを virtue として内部化すると盲点化する (Day 22 audit 教訓)。

### P4: 可観測性

- `/metrics` で V1–V7 の現在値を確認できる
- `.claude/metrics/` にツール使用ログが自動蓄積される
- 改善を主張する前に、計測で裏付ける

### D4: フェーズ順序

安全（L1）→ 検証（P2）→ 可観測性（P4）→ 統治（P3）→ 動的調整
先行フェーズを壊す変更は、後続フェーズの信頼性を損なう。

### Scope discipline (Day 123 反省 / agent-spec-lib Phase 0 運用)

agent-spec-lib roadmap (`agent-spec-lib/AgentSpec.lean` + `docs/research/new-foundation-survey/11-pending-tasks.json` の roadmap section) に明示された Week scope に従う。Day cycle で本道を逸脱しないため:

- **scope creep の警鐘**: 当初 Week N scope に明記されていない file (Framework/, Models/, EvolveSkill 等) を port する場合、pending_items entry に **事前** に declare する。Day cycle 内で「ついでに」 scope 拡張しない。
- **本道優先**: 直近 N=14 day で Tooling 層 (Week 5-6) / CI (Week 6-7) / Verification (Week 7-8) の進捗ゼロが続いたら、scope 拡張型 Day を **連続 3 day 以上行わない**。3 day 経過したら本道 task を 1 Day 挿む。
- **進捗報告は scope を分離**: 「Phase 0 完了率 X%」を単一値で報告しない。本道 (Week 1-8 元 scope) と拡張 (Framework/Models/Skill 系) を別 metric として提示する。
- **派生負債の catalog 化**: byte-identical port 規律から逸脱した派生 (Ontology 補強、autoImplicit 局所有効化、World field 順吸収、新規 helper theorem 追加 等) は pending_items に "派生負債" entry として記録、累積を可視化する。
- **Verification spot check の必須化**: Tooling 層が integrate された後は、port した theorem の代表サンプルに `#print axioms` 等の意味検証を spot check する。lake build PASS のみで意味的整合を主張しない。
- **Step 7 mandatory checklist は実行 + 出力確認まで一体** (Day 137 反省): scope に「mandatory checklist 6 項目 (PASS)」と書く前に、`bash scripts/cycle-check.sh` を **必ず実行**、output を読む。schema NG (Check 5a/5b)・cardinality WARN 以外の **新規 WARN/FAIL** が出た場合は commit 前に対処。change_category は `agent-spec-lib/artifact-manifest.schema.json` enum (namespace_only / additive_axiom / additive_definition / additive_test / proof_addition / behavior_change / breaking / metadata_only / process_only / compatible_change) のいずれかから選ぶ。`conservative_extension` は schema 非対応値、commit message body の互換性分類 (P3 hook 用) と区別する。

## スキルルーティング

ユーザーの要求に応じて適切なスキルを選択する。スキルに該当しない場合は直接対応する。

- 実装前に判断が必要（「やるべきか？」「調査して」「可能か？」） → `/research`
- 公理系ベースの新機能開発 → `/spec-driven-workflow`
- 構造の漸進的改善 → `/evolve`
- 単発のバグ修正・リファクタ → 直接対応。変更後 `/verify`
- スキルの判断に迷う場合 → 直接対応（スキル不要）

## Build & Test Commands

> **Note**: `lake build` and `grep ... Manifest/` commands must be run from the `lean-formalization/` directory.

- `export PATH="$HOME/.elan/bin:$PATH" && lake build Manifest` — Lean 4 full build
- `bash tests/test-all.sh` — run all acceptance tests
- `grep -r "^axiom [a-z]" Manifest/ --include="*.lean" | wc -l` — count axioms
- `grep -r "^theorem " Manifest/ --include="*.lean" | wc -l` — count theorems

## Lean 4 Gotchas

- `import` must precede `/-!` doc comments (Lean 4 requirement)
- `opaque` types need manual `Repr` instances for `deriving Repr` to work on containing structures
- `SelfGoverning` typeclass: any type defining principles must implement it (Ontology.lean)

## Development Process

- Step 0 before implementation: `/research` for spec research (0a) + prior art (0b) + PoC (0c)
- Commits on structural files require compatibility classification (P3 hook enforces)
- `/verify` before committing high-risk changes (P2)
- `/metrics` to check V1–V7 baseline before and after changes
