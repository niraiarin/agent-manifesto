import Manifest.DesignFoundation
import Manifest.Models.Instances.ClaudeCode.Assumptions
import Manifest.Models.Instances.ClaudeCode.ConditionalDesignFoundation

/-!
# Claude Code 条件付き公理系: エージェント実行基盤と指示設計 (#400)

Claude Code の hook 設計パターン、SKILL.md / AGENT.md 構造、
Agent モデル選択、TaskClassification の適用を条件付き公理として構造化する。

## 位置づけ

```
D1, D10, D3, D12, D15 (DesignFoundation.lean, プラットフォーム非依存)
  ↓ 条件付き導出（CC-C15~C17, CC-H19~H22）
  ↓ + 既存 CC-H1~H7 の運用パターン拡張
ID1-ID7 (このファイル, CC 運用パターン固有)
```

## 反証トリガー

Claude Code プラットフォームの仕様変更時に、
ConditionalDesignFoundation.lean と同時に再検証対象となる。
ただし本ファイルは「運用パターン」のため、CC 仕様が不変でも
プロジェクトの運用判断変更で独立に反証されうる。

## 設計方針

- 手書き（運用パターンの意味的推論が必要）
- 各 ID axiom に Derivation Card を付与
- 0 sorry を維持
-/

namespace Manifest.Models.Instances.ClaudeCode

open Manifest

-- ============================================================
-- Hook 設計パターンの型定義
-- ============================================================

/-- hook の段階的応答パターン。
    state file を使い、同一セッション内で応答を段階的に強化する。 -/
inductive GraduatedResponse where
  | firstOccurrence   -- 1 回目: 警告 (exit 0) + touch state file
  | subsequentBlock   -- 2 回目以降: ブロック (exit 2)
  deriving BEq, Repr

/-- hook が使用する入力取得パターン。 -/
inductive HookInputMethod where
  | stdinJson    -- INPUT=$(cat), jq で .tool_input.* にアクセス
  | envVar       -- 環境変数（非推奨、$CLAUDE_TOOL_INPUT は存在しない）
  deriving BEq, Repr

/-- hook 入力方法が正しいか。CC-H19 に基づく。 -/
def isCorrectInputMethod : HookInputMethod → Bool
  | .stdinJson => true
  | .envVar    => false

-- ============================================================
-- ID1: Hook stdin 仕様 (D1 実装詳細)
-- ============================================================

/-- [Derivation Card]
    Derives from: D1 (enforcement layering), CC-H1, CC-H19
    Proposition: ID1
    Content: The correct hook input method is stdin JSON, not environment variables.
      This is a D1 implementation detail: structural enforcement requires
      correct input parsing. $CLAUDE_TOOL_INPUT does not exist.
    Proof strategy: constructor with rfl -/
theorem id1_stdin_is_correct :
  isCorrectInputMethod .stdinJson = true ∧
  isCorrectInputMethod .envVar = false := by
  exact ⟨rfl, rfl⟩

-- ============================================================
-- ID2: State file による段階的応答 (D1 拡張)
-- ============================================================

/-- 段階的応答のブロック能力。
    1 回目は警告のみ（ユーザーが意図的な場合を考慮）、
    2 回目以降はブロック。 -/
def canBlock : GraduatedResponse → Bool
  | .firstOccurrence => false  -- 警告のみ
  | .subsequentBlock => true   -- ブロック

/-- [Derivation Card]
    Derives from: D1 (enforcement layering), CC-H20
    Proposition: ID2
    Content: Graduated response enables nuanced enforcement.
      First occurrence warns (allowing intentional override),
      subsequent occurrences block. This extends D1's structural
      enforcement with a "second chance" pattern.
    Proof strategy: constructor with rfl -/
theorem id2_graduated_response :
  canBlock .firstOccurrence = false ∧
  canBlock .subsequentBlock = true := by
  exact ⟨rfl, rfl⟩

-- ============================================================
-- ID3: PreToolUse Edit の構造的強制境界 (D1)
-- ============================================================

/-- PreToolUse hook が検証できる情報の範囲。
    Edit ツールの場合、変更後のファイル全体は見えない。 -/
inductive EditHookVisibility where
  | filePath      -- tool_input.file_path: 対象ファイルパス
  | oldString     -- tool_input.old_string: 置換前文字列
  | newString     -- tool_input.new_string: 置換後文字列
  | resultingFile -- 変更適用後のファイル全体（見えない）
  deriving BEq, Repr

/-- PreToolUse Edit hook で検証可能か。CC-H21 に基づく。 -/
def isVisibleToEditHook : EditHookVisibility → Bool
  | .filePath      => true
  | .oldString     => true
  | .newString     => true
  | .resultingFile => false  -- 構造的強制の境界

/-- [Derivation Card]
    Derives from: D1 (enforcement layering), CC-H1, CC-H21
    Proposition: ID3
    Content: PreToolUse Edit hook cannot see the resulting file.
      This defines the structural enforcement boundary:
      hooks can inspect inputs but not outcomes of Edit operations.
      "Breaking Edit" detection requires post-hoc verification (PostToolUse or /verify).
    Proof strategy: constructor with rfl -/
theorem id3_edit_hook_boundary :
  isVisibleToEditHook .newString = true ∧
  isVisibleToEditHook .resultingFile = false := by
  exact ⟨rfl, rfl⟩

-- ============================================================
-- ID4: SKILL.md テンプレート構造 (D10)
-- ============================================================

/-- SKILL.md のセクション構造。全 12 スキルが従う慣習。 -/
inductive SkillSection where
  | frontmatter    -- YAML: name, description, dependencies, agents
  | tracesAnnot    -- <!-- @traces D*, P*, ... -->
  | body           -- 本文: ワークフロー、手順、例
  | traceability   -- Traceability テーブル
  deriving BEq, Repr

/-- SKILL.md セクションの標準順序値。 -/
def skillSectionOrder : SkillSection → Nat
  | .frontmatter  => 0
  | .tracesAnnot  => 1
  | .body         => 2
  | .traceability => 3

/-- [Derivation Card]
    Derives from: D10 (structural permanence), CC-C15
    Proposition: ID4
    Content: SKILL.md sections have a canonical ordering.
      This standardizes D10's knowledge permanence template:
      frontmatter (metadata) → traces (traceability) → body (procedure) → traceability (audit).
    Proof strategy: omega on Nat ordering -/
theorem id4_skill_section_ordered :
  skillSectionOrder .frontmatter < skillSectionOrder .tracesAnnot ∧
  skillSectionOrder .tracesAnnot < skillSectionOrder .body ∧
  skillSectionOrder .body < skillSectionOrder .traceability := by
  simp [skillSectionOrder]

-- ============================================================
-- ID5: Agent モデル選択 (D3)
-- ============================================================

/-- Agent の役割分類。モデル選択基準に対応。 -/
inductive AgentRole where
  | creative     -- 創造的推論が必要（hypothesizer）
  | structured   -- 構造化タスク（observer, verifier, integrator）
  deriving BEq, Repr

/-- 役割に推奨されるモデルクラス。
    D3（可観測性優先）: 情報非対称性の削減に適したモデルを選択。 -/
inductive ModelClass where
  | opus    -- 高推論能力、高コスト
  | sonnet  -- 効率的、構造化タスクに適切
  deriving BEq, Repr

/-- 役割→モデルの推奨マッピング。CC-C16 に基づく。 -/
def recommendedModel : AgentRole → ModelClass
  | .creative   => .opus    -- 創造的推論には高推論能力が必要
  | .structured => .sonnet  -- 効率重視

/-- [Derivation Card]
    Derives from: D3 (observability first), CC-C16
    Proposition: ID5
    Content: Creative roles (hypothesizer) use opus; structured roles use sonnet.
      D3 requires reducing information asymmetry — creative roles need
      higher reasoning capability to generate novel hypotheses.
    Proof strategy: constructor with rfl -/
theorem id5_model_selection :
  recommendedModel .creative = .opus ∧
  recommendedModel .structured = .sonnet := by
  exact ⟨rfl, rfl⟩

-- ============================================================
-- ID6: TaskClassification 適用 (D12)
-- ============================================================

/-- タスク自動化分類。TaskClassification.lean の簡略版。 -/
inductive TaskClass where
  | deterministic  -- スクリプト化可能、判断不要
  | judgmental      -- LLM/人間の判断が必要
  | mixed           -- 両方を含む（decomposition 対象）
  deriving BEq, Repr

/-- 分類済みタスクはスクリプト化可能か。 -/
def canScript : TaskClass → Bool
  | .deterministic => true
  | .judgmental    => false
  | .mixed         => false  -- 分離が先

/-- [Derivation Card]
    Derives from: D12 (constraint satisfaction task design), CC-C17
    Proposition: ID6
    Content: Deterministic tasks should be scripted, not left to LLM judgment.
      D12 requires matching task complexity to solver capability.
      mixed_task_decomposition separates deterministic and judgmental components.
    Proof strategy: constructor with rfl -/
theorem id6_deterministic_scripted :
  canScript .deterministic = true ∧
  canScript .judgmental = false := by
  exact ⟨rfl, rfl⟩

-- ============================================================
-- ID7: Hook イベント完全性 (D15)
-- ============================================================

/-- 全 hook イベント種別。CC-H22 で UserPromptSubmit/TaskCompleted を含む。 -/
def allHookEvents : List HookKind :=
  [.preToolUse, .postToolUse, .sessionStart, .userPromptSubmit, .taskCompleted]

/-- [Derivation Card]
    Derives from: D15 (harness engineering), CC-H22
    Proposition: ID7
    Content: All 5 hook event kinds are available.
      D15 requires harness completeness.
      UserPromptSubmit and TaskCompleted are production-active
      but missing from CLAUDE.md documentation.
    Proof strategy: native_decide on list length -/
theorem id7_hook_event_completeness :
  allHookEvents.length = 5 := by native_decide

end Manifest.Models.Instances.ClaudeCode
