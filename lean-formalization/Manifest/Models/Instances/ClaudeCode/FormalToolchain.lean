import Manifest.DesignFoundation
import Manifest.Models.Instances.ClaudeCode.Assumptions
import Manifest.Models.Instances.ClaudeCode.ConditionalDesignFoundation

/-!
# Claude Code 条件付き公理系: 形式検証ツールチェーン (#401)

Lean 4 / Mathlib / Verso を形式検証ツールチェーンとして使用する際の
制約と運用パターンを条件付き公理として構造化する。

## 反証トリガー

Lean 4 のバージョンアップ、Mathlib の破壊的変更、Verso の仕様変更時に
このファイル全体が再検証対象となる。

## 設計方針

- 手書き（ツールチェーン制約の意味的推論が必要）
- 0 sorry を維持
-/

namespace Manifest.Models.Instances.ClaudeCode

open Manifest

-- ============================================================
-- 形式検証カードの型定義
-- ============================================================

/-- 公理カード (Axiom Card) のフィールド。CC-C21 に基づく。 -/
inductive AxiomCardField where
  | layer              -- 公理の認識論的層
  | content            -- 公理の内容
  | basis              -- 根拠（数学的根拠、先行研究等）
  | source             -- 出典
  | refutationCondition -- 反証条件
  deriving BEq, Repr

/-- 導出カード (Derivation Card) のフィールド。CC-C22 に基づく。 -/
inductive DerivationCardField where
  | derivesFrom    -- 導出元の公理/定理
  | proposition    -- 命題 ID
  | content        -- 内容
  | proofStrategy  -- 証明戦略
  deriving BEq, Repr

-- ============================================================
-- FT1: カードフォーマットの完全性
-- ============================================================

/-- Axiom Card の必須フィールド数。 -/
def axiomCardFieldCount : Nat :=
  [AxiomCardField.layer, .content, .basis, .source, .refutationCondition].length

/-- Derivation Card の必須フィールド数。 -/
def derivationCardFieldCount : Nat :=
  [DerivationCardField.derivesFrom, .proposition, .content, .proofStrategy].length

/-- [Derivation Card]
    Derives from: D5 (spec-test-impl), CC-C21, CC-C22
    Proposition: FT1
    Content: Axiom Cards have 5 required fields, Derivation Cards have 4.
      p3-axiom-evidence-check.sh enforces field presence (not content validity).
    Proof strategy: native_decide -/
theorem ft1_card_field_completeness :
  axiomCardFieldCount = 5 ∧ derivationCardFieldCount = 4 := by
  native_decide

-- ============================================================
-- FT2: Lean 4 構文制約
-- ============================================================

/-- Lean 4 ソースファイルの構文順序制約。 -/
inductive LeanSyntaxElement where
  | importStmt     -- import 文
  | docComment     -- /-! ... -/ ドキュメントコメント
  | declaration    -- def, theorem, axiom 等
  deriving BEq, Repr

/-- 構文要素の必須順序値。import が最初。 -/
def syntaxOrder : LeanSyntaxElement → Nat
  | .importStmt  => 0  -- 最初
  | .docComment  => 1  -- import の後
  | .declaration => 2  -- doc comment の後

/-- [Derivation Card]
    Derives from: CC-H27
    Proposition: FT2
    Content: Lean 4 requires import before doc comments.
      This is a parser constraint, not a convention.
    Proof strategy: simp -/
theorem ft2_import_before_doc :
  syntaxOrder .importStmt < syntaxOrder .docComment := by
  simp [syntaxOrder]

-- ============================================================
-- FT3: カウントスコープの非対称性
-- ============================================================

/-- Lean モジュールディレクトリのカウント対象分類。 -/
inductive ModuleScope where
  | manifest       -- Manifest/*.lean (直下)
  | framework      -- Manifest/Framework/*.lean
  | models         -- Manifest/Models/**/*.lean
  | foundation     -- Manifest/Foundation/*.lean
  deriving BEq, Repr

/-- sync-counts.sh のカウント対象か。CC-C23 に基づく。 -/
def isCountTarget : ModuleScope → Bool
  | .manifest  => true
  | .framework => true
  | .models    => false  -- 条件付き公理系（プロジェクト固有）
  | .foundation => false  -- 数学的基盤（Mathlib 上）

/-- [Derivation Card]
    Derives from: CC-C23
    Proposition: FT3
    Content: sync-counts.sh intentionally excludes Models/ and Foundation/.
      Models/ contains project-specific conditional axiom systems.
      Foundation/ contains mathematical foundations on Mathlib.
      Both are excluded to keep counts focused on the core axiom system.
    Proof strategy: constructor with rfl -/
theorem ft3_count_scope_asymmetry :
  isCountTarget .manifest = true ∧
  isCountTarget .models = false ∧
  isCountTarget .foundation = false := by
  exact ⟨rfl, rfl, rfl⟩

end Manifest.Models.Instances.ClaudeCode
