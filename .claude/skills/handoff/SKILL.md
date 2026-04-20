---
name: handoff
user-invocable: true
description: >
  context 逼迫時にスキル実行状態を永続化し、次セッションで LLM が正確に再開できる
  resumption prompt を生成する。T1（一時性）+ T2（永続性）の運用インスタンス。
  Layer 1: フェーズ境界での deterministic checkpoint。
  Layer 2: judgmental な状態統合 + resumption prompt 生成。
  「handoff」「引き継ぎ」「context 逼迫」「セッション切り替え」で起動。
dependencies:
  invokes: []
  invoked_by:
    - skill: evolve
      phase: "Phase 1→2, 2→3, 3→4 boundary"
      expected_output: "checkpoint JSONL entry"
    - skill: spec-driven-workflow
      phase: "Phase 0→1, 1→2, 2→3, 3→4 boundary"
      expected_output: "checkpoint JSONL entry"
    - skill: brownfield
      phase: "Phase 0→1, 1→2 boundary"
      expected_output: "checkpoint JSONL entry"
    - skill: formal-derivation
      phase: "Phase 1→2, 2→3, 3→4 boundary"
      expected_output: "checkpoint JSONL entry"
---
<!-- @traces T1, T2, D1, D10, P4 -->

# /handoff — セッション引き継ぎスキル

> **Portability: platform-generic** — checkpoint/resume の概念は Claude Code 固有ではなく、
> 任意の LLM ハーネスに適用可能。hook 実装のみが Claude Code 固有。

> 一時的なインスタンスは消滅する。しかし構造に状態を書き込むことで、
> 次のインスタンスが正確に作業を再開できる。— T1 + T2

## 設計根拠

### 先行研究

| 手法 | 出典 | 本スキルでの採用 |
|------|------|----------------|
| Anchored Iterative Summarization | Factory.ai | 構造化セクション（intent, progress, next_steps）で情報損失を防止 |
| 70% 閾値ハード停止 | claude-code-session-kit | フェーズ境界での自動 checkpoint（劣化前に切る） |
| Typed dict checkpoint | LangGraph | JSONL スキーマで typed state を永続化 |
| 3 層圧縮 | LangChain Deep Agents | Layer 1 (checkpoint) + Layer 2 (handoff summary) の 2 層構造 |

### マニフェスト公理系との対応

| 概念 | 公理系 | 本スキルでの使い方 |
|------|--------|-----------------|
| インスタンス消滅 | T1 一時性 | handoff はインスタンス消滅を前提に設計 |
| 構造への書き込み | T2 永続性 | checkpoint/resume を永続ファイルに記録 |
| 二重注入防止 | D1 構造的強制 | .injected リネームで LLM 判断に依存しない |
| 構造永続性 | D10 | エージェント消滅後もログが残る |
| 状態の可視化 | P4 可観測性 | sorry-count, evolve last run をセッション開始時に通知 |

## タスク自動化分類

| ステップ | 分類 | 推奨実装手段 | 備考 |
|---|---|---|---|
| Layer 1: Checkpoint 書き込み | **deterministic** | JSONL append | スキーマ固定、フェーズ境界で機械的実行 |
| Layer 2: 状態統合 | **judgmental** | LLM | intent, progress, next_steps の要約は創造的行為 |
| Layer 2: JSONL 書き込み | **deterministic** | JSONL append | スキーマ固定 |
| Layer 2: handoff-resume.md 生成 | **judgmental** | LLM | LLM が読んで再開できるフォーマットの生成 |
| SessionStart: resume 注入 | **deterministic** | hook (bash) | additionalContext パターン、p4-drift-detector.sh と同一 |
| SessionStart: .injected リネーム | **deterministic** | hook (bash) | mv コマンド、D1 構造的強制 |
| SessionStart: sorry-count | **deterministic** | hook (bash) | grep + wc、evolve-state-loader.sh から統合 |

## 2 層アーキテクチャ

### Layer 1: Checkpoint (deterministic)

各スキルのフェーズ境界で自動的に状態を記録する。

**トリガー**: 対象スキルの SKILL.md に埋め込まれた checkpoint 指示
**出力先**: `.claude/handoffs/checkpoints.jsonl`
**スキーマ**:
```json
{
  "timestamp": "2026-04-12T10:00:00Z",
  "skill": "evolve",
  "phase": "Phase 2",
  "git_sha": "abc1234",
  "branch": "research/514-handoff-scoping",
  "completed": ["Phase 1: Observer"],
  "remaining": ["Phase 3: Verifier", "Phase 4: Integrator"],
  "blocked": null
}
```

**`branch` フィールド** (#514 G3): `git branch --show-current` の出力。
detached HEAD の場合は `null`。未設定の既存エントリは `null` と同等に扱う（後方互換）。

**対象スキルとチェックポイント境界**:

| スキル | 境界 |
|--------|------|
| evolve | Phase 1→2, 2→3, 3→4（Observer/Hypothesizer/Verifier/Integrator 間） |
| spec-driven-workflow | Phase 0→1, 1→2, 2→3, 3→4（設計/テスト/実装/検証 間） |
| brownfield | Phase 0→1, 1→2（観察→構築→検証） |
| formal-derivation | Phase 1→2, 2→3, 3→4（形式化→検証→監査） |

### Layer 2: Handoff (judgmental + manual)

context 逼迫時に、checkpoint と現在の会話状態を統合して resumption prompt を生成する。

**トリガー**: `/handoff`（人間/LLM 起動）
**入力**: checkpoints.jsonl + 現在の会話状態
**出力先**:
- `.claude/handoffs/handoff-<timestamp>.jsonl` — 永続ログ
- `.claude/handoffs/handoff-resume-<scope>.md` — 次セッション注入用 (#514 G2)
  - `<scope>` = ブランチ名（slash→hyphen 変換。例: `research/514-x` → `handoff-resume-research-514-x.md`）
  - detached HEAD の場合は `handoff-resume.md`（スコープなし、後方互換）

**JSONL スキーマ**:
```json
{
  "timestamp": "2026-04-12T10:30:00Z",
  "skill": "spec-driven-workflow",
  "phase": "Phase 2",
  "git_sha": "def5678",
  "branch": "feature/handoff-impl",
  "intent": "handoff skill の実装。spec-driven-workflow Phase 2 (TDD) 実行中",
  "progress": {
    "done": ["Phase 0: 設計 v4 確定", "Phase 1: テスト計画 24 tests"],
    "remaining": ["Phase 2: 残りの実装", "Phase 3: 検証"]
  },
  "next_steps": [
    "SKILL.md の作成",
    "4 スキルへの checkpoint 参照追加",
    "テスト全 PASS の確認"
  ],
  "files_modified": [
    ".claude/hooks/handoff-resume-loader.sh",
    "tests/phase5/test-handoff-structural.sh"
  ],
  "blocked": null,
  "decisions": "additionalContext JSON パターンを採用（p4-drift-detector.sh と同一）"
}
```

**handoff-resume.md のフォーマット**:
```markdown
# Handoff Resume
git_sha: <current HEAD>
branch: <current branch or null>
skill: <running skill>
phase: <current phase>
structured_log: `.claude/handoffs/handoff-<timestamp>.jsonl` (対応 JSONL へのポインタ。本 resume.md と同 state の typed checkpoint、audit / scripting / 別エージェント統合時に参照)
intent: <what the user originally asked for>

## Progress
### Done
- <completed items>

### Remaining
- <remaining items>

## Next Steps
1. <concrete next action>
2. <concrete next action>

## Files Modified
- <path>

## Key Decisions
- <decision with rationale>
```

**設計根拠 (`structured_log` cross-reference フィールド)**:
- resume.md は human/LLM-readable、JSONL は machine-readable typed state
- 2 つの artifact が parallel に書かれるが、resume.md から JSONL への参照がないと次セッションは JSONL の存在を認識できない
- `structured_log` フィールドで両者を明示的に link、audit 時や別エージェント統合時に JSONL を findable にする
- Added 2026-04-20 (Day 26 handoff 実施時にユーザー指摘で identify)

### 次セッション起動（handoff-resume-loader.sh）

SessionStart hook が以下を実行:

1. `.claude/handoffs/handoff-resume*.md` からスコープに合致するファイルを選択 (#514 G2):
   a. `handoff-resume-<current-branch>.md` が存在すれば選択（完全一致）
   b. なければ `handoff-resume.md`（旧形式フォールバック）
   c. どちらもなければ noop
2. `branch` フィールドと `git branch --show-current` を比較 (#514 G1):
   a. `branch` 未設定（旧形式） → 後方互換: SHA 照合のみで注入
   b. `branch` が `null`（detached HEAD で書き込み） → 任意のブランチにマッチ
   c. ブランチ一致 → `git_sha` 照合へ進む
   d. ブランチ不一致 → 注入をスキップ。stderr に `[HANDOFF] skipped: for branch <X>, current is <Y>` を出力
3. `git_sha` と `git rev-parse HEAD` を比較
4. 一致 → `additionalContext` で注入
5. 不一致 → warn 付きで注入（intent/progress は有効、ファイル状態は要確認）
6. 注入後 → `.injected` にリネーム（D1: 二重注入の構造的防止）。
   リネーム失敗時は stderr に警告を出力（`|| true` ではなく明示的エラーログ）
7. sorry-count チェック（evolve-state-loader.sh から統合）

**既知の制限**:
- 複数 Claude Code ウィンドウの同時起動で race condition が理論上発生する。通常使用（1 ウィンドウ）では問題なし。
- ブランチ名の slash→hyphen 変換で理論上の衝突あり（`a/b-c` と `a-b/c`）。メタデータ照合（Step 2c）が defense in depth として機能。

### 退役

- LLM が再開完了後に `handoff-resume-<scope>.md`（または `handoff-resume.md`）を削除（ベストエフォート）
- 構造的には `.injected` リネームで二重注入を防止済み
- `.claude/handoffs/handoff-<timestamp>.jsonl` は永続ログとして残る

## /handoff 実行手順

1. **checkpoint 読み込み** — `checkpoints.jsonl` の最新エントリを確認
2. **状態統合** — checkpoint + 現在の会話状態から以下を抽出:
   - intent: ユーザーの元の要求
   - progress: 完了/未完了
   - next_steps: 具体的な次のアクション
   - files_modified: 変更したファイル
   - decisions: 重要な設計判断（オプション）
3. **JSONL 書き込み** — `.claude/handoffs/handoff-<timestamp>.jsonl` に永続記録。タイムスタンプは `date -u +%Y-%m-%dT%H%M%SZ` 等で UTC 生成
4. **resume.md 生成** — 上記フォーマットで書き込み。
   - ファイル名: `BRANCH=$(git branch --show-current)` を取得し、
     ブランチがあれば `handoff-resume-$(echo "$BRANCH" | sed 's|/|-|g').md`、
     なければ `handoff-resume.md`（detached HEAD フォールバック）
   - `branch` フィールド: `${BRANCH:-null}` の出力を使用
   - **`structured_log` フィールド必須**: step 3 で書いた JSONL の path を記録 (resume.md と JSONL の cross-reference、次セッションが JSONL を findable にする)
5. **確認** — 生成した resume.md の内容をユーザーに表示
6. **resumption prompt 出力** — 次セッションでユーザーがそのまま貼り付けられる prompt を出力する。
   フォーマット:
   ```
   --- ✂ 次のセッションに貼り付けてください ---

   前セッションの引き継ぎです。`.claude/handoffs/handoff-resume-<scope>.md` を読んで作業を再開してください。

   --- ✂ ここまで ---
   ```
   - `<scope>` は実際に生成したファイル名に置換する
   - resume.md にすべての状態が記録されているため、prompt 自体は短く保つ
   - ユーザーがコピーしやすいようコードブロックで囲む

## Lean 形式化との対応

| スキルの概念 | Lean ファイル | 定理/定義 |
|------------|-------------|----------|
| T1 一時性 | Axioms.lean | `session_bounded` |
| T2 永続性 | Axioms.lean | `structure_persists` |
| D1 構造的強制 | DesignFoundation.lean | `StructuralEnforcement` |
| D10 構造永続性 | DesignFoundation.lean | `agent_temporary_structure_permanent` |

## Traceability

| 命題 | このスキルとの関係 |
|------|-------------------|
| T1 | セッション消滅を前提に、状態を構造に書き込む設計 |
| T2 | handoff-resume.md と checkpoints.jsonl が構造として永続する |
| D1 | .injected リネームで二重注入を構造的に防止（LLM 判断に依存しない） |
| D10 | エージェント消滅後も handoff ログが残り、次インスタンスが参照可能 |
| P4 | sorry-count と evolve last run をセッション開始時に自動通知 |
