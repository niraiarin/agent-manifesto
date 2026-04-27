import AgentSpec.Manifest.Ontology
import AgentSpec.Manifest.Framework.LLMRejection

/-!
# Epistemic Tagging

## 目的

推論チェーン内の中間値（閾値、パラメータ、計算結果）に認識論的地位を
型レベルで付与し、仮置き値が暗黙に確定値として扱われることを防ぐ。

## 設計判断

- `CandidateSource`（LLMRejection.lean）は出自（human/llm）を追跡する。
  本モジュールの `EpistemicTag` は**検証状態**（仮置き/検証済み）を追跡する。
  これらは直交する関心であり、重複ではない。
- `Assumption`（Models/Assumptions/EpistemicLayer.lean）は公理系レベルの仮定に適用される。
  本モジュールは任意の型の値に適用可能な汎用ラッパーを提供する。

## Research Issue

#527 (Parent: #526)
-/

set_option autoImplicit true

namespace AgentSpec.Manifest.Framework.EpistemicTagging

open AgentSpec.Manifest
open AgentSpec.Manifest.Framework

-- ============================================================
-- Approach (a): Tagged wrapper type
-- ============================================================

/-- 検証根拠。値が validated に昇格した際の根拠を記録する。 -/
structure ValidationEvidence where
  /-- 検証を行ったエージェントの識別子。P2: 生成者と異なること。 -/
  verifierId : String
  /-- 検証方法の記述。 -/
  method : String
  /-- 検証日時。 -/
  timestamp : String
  deriving Repr

/-- 認識論的タグ。値の検証状態を型レベルで区別する。 -/
inductive EpistemicTag where
  /-- 仮置き: 未検証、暫定値。根拠なしに意思決定に使用すべきでない。 -/
  | provisional
  /-- 検証済み: 外部検証を経た値。検証根拠を保持する。 -/
  | validated (evidence : ValidationEvidence)
  deriving Repr

/-- 認識論的にタグ付けされた値。
    任意の型 α の値に検証状態を付与する汎用ラッパー。 -/
structure Tagged (α : Type) where
  /-- 包まれた値。 -/
  value : α
  /-- 認識論的タグ（仮置き or 検証済み）。 -/
  tag : EpistemicTag
  deriving Repr

-- ============================================================
-- 基本操作
-- ============================================================

/-- 仮置き値を構成する。 -/
def Tagged.provisional (v : α) : Tagged α :=
  { value := v, tag := .provisional }

/-- 検証済み値を構成する。evidence が必要。 -/
def Tagged.validated (v : α) (evidence : ValidationEvidence) : Tagged α :=
  { value := v, tag := .validated evidence }

/-- 値を取り出す（タグを無視）。
    注意: この操作は認識論的地位を破棄する。
    タグを保持したまま変換する場合は `Tagged.map` を使用すること。 -/
def Tagged.unwrap (t : Tagged α) : α := t.value

/-- タグを保持したまま値を変換する。 -/
def Tagged.map (f : α → β) (t : Tagged α) : Tagged β :=
  { value := f t.value, tag := t.tag }

/-- 仮置き値かどうかを判定する。 -/
def Tagged.isProvisional (t : Tagged α) : Bool :=
  match t.tag with
  | .provisional => true
  | .validated _ => false

/-- 検証済み値かどうかを判定する。 -/
def Tagged.isValidated (t : Tagged α) : Bool :=
  match t.tag with
  | .provisional => false
  | .validated _ => true

-- ============================================================
-- 昇格操作（仮置き → 検証済み）
-- ============================================================

/-- 仮置き値を検証済みに昇格する。evidence が必須。
    すでに検証済みの場合は evidence を更新する（再検証）。 -/
def Tagged.promote (t : Tagged α) (evidence : ValidationEvidence) : Tagged α :=
  { value := t.value, tag := .validated evidence }

-- ============================================================
-- 定理: 型レベルの保証
-- ============================================================

/-- provisional で構成した値は isProvisional = true。 -/
theorem provisional_is_provisional (v : α) :
    (Tagged.provisional v).isProvisional = true := by
  simp [Tagged.provisional, Tagged.isProvisional]

/-- validated で構成した値は isValidated = true。 -/
theorem validated_is_validated (v : α) (e : ValidationEvidence) :
    (Tagged.validated v e).isValidated = true := by
  simp [Tagged.validated, Tagged.isValidated]

/-- promote の結果は常に isValidated = true。 -/
theorem promote_is_validated (t : Tagged α) (e : ValidationEvidence) :
    (t.promote e).isValidated = true := by
  simp [Tagged.promote, Tagged.isValidated]

/-- map は認識論的タグを保存する。 -/
theorem map_preserves_tag (f : α → β) (t : Tagged α) :
    (t.map f).tag = t.tag := by
  simp [Tagged.map]

/-- map は provisional を保存する。 -/
theorem map_preserves_provisional (f : α → β) (t : Tagged α) :
    t.isProvisional = true → (t.map f).isProvisional = true := by
  intro h
  simp [Tagged.map, Tagged.isProvisional] at *
  exact h

/-- map は validated を保存する。 -/
theorem map_preserves_validated (f : α → β) (t : Tagged α) :
    t.isValidated = true → (t.map f).isValidated = true := by
  intro h
  simp [Tagged.map, Tagged.isValidated] at *
  exact h

/-- unwrap は値を保存する。 -/
theorem unwrap_value (t : Tagged α) :
    t.unwrap = t.value := by
  simp [Tagged.unwrap]

-- ============================================================
-- CandidateSource との直交性
-- ============================================================

/-- 出自タグと検証状態タグの両方を持つ値。
    CandidateSource（誰が作ったか）と EpistemicTag（検証されたか）は
    直交する関心であることを型レベルで表現する。 -/
structure FullyTagged (α : Type) where
  value : α
  source : CandidateSource
  epistemic : EpistemicTag
  deriving Repr

/-- Candidate から FullyTagged への変換（初期状態は provisional）。 -/
def FullyTagged.fromCandidate (c : Candidate α) : FullyTagged α :=
  { value := c.value, source := c.source, epistemic := .provisional }

/-- FullyTagged の検証状態を昇格する。 -/
def FullyTagged.promote (ft : FullyTagged α) (evidence : ValidationEvidence) : FullyTagged α :=
  { ft with epistemic := .validated evidence }

-- ============================================================
-- 実用性の検証: 閾値の例
-- ============================================================

/-- 閾値の例: 仮置きの 0.7 を構成。 -/
def exampleThreshold : Tagged Float :=
  Tagged.provisional 0.7

/-- 閾値の例: 検証後に validated に昇格。 -/
def exampleValidatedThreshold : Tagged Float :=
  exampleThreshold.promote {
    verifierId := "human-review-2026-04-15"
    method := "empirical measurement on test dataset"
    timestamp := "2026-04-15"
  }

/-- 例: 仮置き閾値は provisional。 -/
theorem example_is_provisional :
    exampleThreshold.isProvisional = true := by
  simp [exampleThreshold, Tagged.provisional, Tagged.isProvisional]

/-- 例: 昇格後は validated。 -/
theorem example_validated_after_promote :
    exampleValidatedThreshold.isValidated = true := by
  simp [exampleValidatedThreshold, Tagged.promote, Tagged.isValidated]

end AgentSpec.Manifest.Framework.EpistemicTagging
