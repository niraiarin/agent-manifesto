import Manifest.EpistemicLayer
import Manifest.Models.Assumptions.EpistemicLayer

/-!
# Case 2: Assumption Contradiction

子の Assumption (CC-H 相当) の content が親の theorem の結論と矛盾するケース。

## 矛盾の構造

`Assumption.content` は `String` 型であり、Lean の型レベルでは親の定理と
直接矛盾しない。矛盾は `content` を `Prop` に解釈（interprets）して初めて現れる。

## 検出パターン

- **静的検出**: 不可能（`String` は `Prop` と型が異なる）
- **動的検出**: 仮定 ID と親の PropositionId の対応を instance-manifest.json に記録し、
  Assumption.content の意味と親定理の結論の整合性を manifest-trace 拡張でチェック
- **手動検出**: content の意味論的解釈は人間が行う（judgmental）

## Verifier 指摘への対応

Step 3.5 の Verifier が指摘した通り、`Assumption.content : String` は
Lean の型レベルで直接矛盾を表現できない。本ケースでは
`interprets : String → Prop` 述語を定義するアプローチ (a) を採用する。
-/

namespace Manifest.Models.PoC.Consistency.Case2

open Manifest
open Manifest.EpistemicLayer
open Manifest.Models.Assumptions

-- ============================================================
-- 1. 子プロジェクトの仮定（Assumption として登録）
-- ============================================================

/-- 子プロジェクトの仮定: 「全てのエージェントは独立している」。
    これは親公理系の T7 (collaboration) — 「協調は構造から創発する」と矛盾する意図。 -/
def childAssumption_independence : Assumption :=
  { id := "CHILD-H1"
    source := .llmInference ["CHILD-H1"] "エージェント間の協調メカニズムが存在する証拠が見つかった場合"
    content := "All agents operate in complete isolation; no collaboration emerges from structure"
    validity := some ⟨"hypothetical-child-project/docs/architecture.md", "2026-04-11", some 90⟩ }

-- ============================================================
-- 2. String → Prop の解釈層
-- ============================================================

/-- 仮定の content を Prop に解釈する関数。
    これは brownfield ワークフローで人間が定義する（judgmental）。
    実際のシステムでは NL→Formal の変換ツールまたは人間の判断で行う。 -/
class ContentInterpreter where
  /-- 自然言語の仮定文を Prop に変換。 -/
  interpret : String → Prop

/-- 解釈可能性の証拠: interpret が「意味のある」Prop を返すか。 -/
structure InterpretationWitness (ci : ContentInterpreter) (content : String) where
  /-- interpret の結果が trivial (True) でないことの証拠。 -/
  nontrivial : ci.interpret content ≠ True

-- ============================================================
-- 3. 子の仮定の解釈と親定理の帰結
-- ============================================================

/-- 子の仮定の形式的意味: 「いかなる構造も協調を生まない」。 -/
def child_independence_meaning : Prop :=
  ∀ (claim : Prop), claim → False  -- 極端な否定（矛盾を明確化）

/-- 親の T7 (collaboration) の帰結: 「協調は構造から創発しうる」。 -/
def parent_t7_consequence : Prop :=
  ∃ (_ : Prop), True  -- 何らかの性質が成立する

/-- 具体的な ContentInterpreter インスタンス。 -/
def childContent : String := childAssumption_independence.content

instance exampleInterpreter : ContentInterpreter where
  interpret := fun s =>
    if s == childContent then child_independence_meaning
    else True

-- ============================================================
-- 4. 矛盾の証明
-- ============================================================

/-- 子の仮定の解釈が親の帰結と矛盾することの証明。 -/
theorem assumption_contradiction
    (h_child : child_independence_meaning)
    (_h_parent : parent_t7_consequence) : False := by
  unfold child_independence_meaning at h_child
  exact h_child True trivial

/-- ContentInterpreter 経由での矛盾。
    interpret の結果を使って同じ矛盾を構成。 -/
theorem assumption_contradiction_via_interpreter
    (h_interp : exampleInterpreter.interpret childContent)
    (_h_parent : parent_t7_consequence) : False := by
  simp [ContentInterpreter.interpret] at h_interp
  exact h_interp True trivial

-- ============================================================
-- 5. 要約
-- ============================================================

/-- Assumption は Lean ビルドで問題を起こさない。content は String だから。 -/
example : Assumption := childAssumption_independence

/-- 検出パターン:
    1. Assumption.content を ContentInterpreter で Prop に変換
    2. 対応する親の命題の帰結を Prop として取得
    3. 両者の conjunction が False になるか検証
    人間の介入: ContentInterpreter の定義（judgmental）
    自動化可能: conjunction の矛盾チェック（bounded — Lean が証明を検索） -/
def _detectionPattern : String :=
  "assumption_contradiction: String → Prop interpretation + parent consequence check"

end Manifest.Models.PoC.Consistency.Case2
