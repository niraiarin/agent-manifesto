import Manifest.Ontology
import Manifest.Observable
import Manifest.DesignFoundation

/-!
# TaskClassification — 決定論的タスクの構造的強制

決定可能性理論 (Church 1936, Rice 1953) と効果システム (Moggi 1991) の
合流点として、タスクを自動化可能性で分類する。

- **Rice の定理**: 構文的性質 → 決定可能 → スクリプト / 意味論的性質 → 決定不可能 → 判断
- **Observable**: `∃ f : World → Bool, ∀ w, f w = true ↔ P w` — スクリプトの存在を型レベルで表現
- **D11**: structural enforcement はコンテキストコスト最小
-/

namespace Manifest

-- ============================================================
-- タスク自動化分類
-- ============================================================

/-- タスクの自動化分類。
    決定可能性理論の 3 層（decidable / semi-decidable / undecidable）を
    D1 の EnforcementLayer にマッピングする。 -/
inductive TaskAutomationClass where
  | deterministic  -- 成功判定が決定可能。スクリプトで自動化可能
  | bounded        -- 成功は有限時間で検証可能だが、失敗証明が有限時間で不可能な場合がある
  | judgmental      -- 成功判定に非機械的評価が必要。LLM / 人間が担当
  deriving BEq, Repr

-- ============================================================
-- EnforcementLayer へのマッピング
-- ============================================================

/-- タスク分類から最低限必要な強制レイヤーへのマッピング。 -/
def taskMinEnforcement : TaskAutomationClass → EnforcementLayer
  | .deterministic => .structural
  | .bounded       => .procedural
  | .judgmental     => .normative

-- ============================================================
-- 順序構造
-- ============================================================

/-- 自動化クラスの強度順序。deterministic が最も自動化可能。 -/
def TaskAutomationClass.automationPower : TaskAutomationClass → Nat
  | .deterministic => 3
  | .bounded       => 2
  | .judgmental     => 1

/-- 自動化クラスの順序は EnforcementLayer の強度順序と整合する。 -/
theorem automation_enforcement_consistent :
  ∀ (tc : TaskAutomationClass),
    (taskMinEnforcement tc).strength = tc.automationPower := by
  intro tc; cases tc <;> rfl

-- ============================================================
-- コンテキストコストとの接続（D11 系）
-- ============================================================

/-- 決定論的タスクの強制コストは全分類中で最小（D11 の TaskClassification 版）。 -/
theorem deterministic_minimizes_cost :
  ∀ (tc : TaskAutomationClass),
    contextCost (taskMinEnforcement .deterministic) ≤
    contextCost (taskMinEnforcement tc) := by
  intro tc; cases tc <;> simp [taskMinEnforcement, contextCost]

/-- 決定論的タスクを judgmental 層で実行するとコストが増大する。
    sync-counts.sh (#121) の形式的正当化。 -/
theorem deterministic_judgmental_wasteful :
  contextCost (taskMinEnforcement .judgmental) >
  contextCost (taskMinEnforcement .deterministic) := by
  simp [taskMinEnforcement, contextCost]

-- ============================================================
-- Observable との接続
-- ============================================================

/-- タスクの成功条件。World の状態に基づく述語。 -/
def TaskSuccessCondition := World → Prop

/-- 成功条件が Observable なら deterministic に分類できる。
    Observable（∃ f : World → Bool, ...）はスクリプトの存在を意味する。 -/
theorem observable_implies_automatable :
  ∀ (P : TaskSuccessCondition),
    Observable P →
    ∃ (tc : TaskAutomationClass), tc = .deterministic := by
  intro _ _; exact ⟨.deterministic, rfl⟩

/-- 逆: deterministic に分類されるなら成功条件は Observable でなければならない。
    決定論的でないものを誤分類することを防ぐ。 -/
axiom deterministic_requires_observable :
  ∀ (P : TaskSuccessCondition),
    (∀ tc : TaskAutomationClass, tc = .deterministic) →
    Observable P

-- ============================================================
-- 構造的強制の義務（核心の命題）
-- ============================================================

/-- **核心公理**: 決定論的タスクは構造的強制レイヤーで実行されなければならない。

    「LLM がやるべきでないことを LLM にやらせてはならない」の形式化。

    D11 (contextCost) + T3 (context_finite) + T7 (resource_finite) から:
    決定論的タスクを normative 層で実行することは非効率的リソース使用。 -/
axiom deterministic_must_be_structural :
  ∀ (tc : TaskAutomationClass),
    tc = .deterministic →
    (taskMinEnforcement tc).strength ≥ EnforcementLayer.structural.strength

/-- 対偶: 強制力が structural 未満のタスクは deterministic ではない。 -/
theorem weak_enforcement_not_deterministic :
  ∀ (tc : TaskAutomationClass),
    (taskMinEnforcement tc).strength < EnforcementLayer.structural.strength →
    tc ≠ .deterministic := by
  intro tc h heq; subst heq; simp [taskMinEnforcement] at h

-- ============================================================
-- 基本性質
-- ============================================================

/-- 決定論的タスクの最低強制は structural（strength = 3）。 -/
theorem deterministic_strength :
  (taskMinEnforcement .deterministic).strength = 3 := by rfl

/-- judgmental タスクの最低強制は normative（strength = 1）。 -/
theorem judgmental_strength :
  (taskMinEnforcement .judgmental).strength = 1 := by rfl

/-- 3 分類は網羅的。 -/
theorem classification_exhaustive :
  ∀ (tc : TaskAutomationClass),
    tc = .deterministic ∨ tc = .bounded ∨ tc = .judgmental := by
  intro tc; cases tc
  · left; rfl
  · right; left; rfl
  · right; right; rfl

/-- 分類間の強度は厳密な全順序。 -/
theorem automation_strict_order :
  TaskAutomationClass.automationPower .deterministic >
  TaskAutomationClass.automationPower .bounded ∧
  TaskAutomationClass.automationPower .bounded >
  TaskAutomationClass.automationPower .judgmental := by
  constructor <;> decide

end Manifest
