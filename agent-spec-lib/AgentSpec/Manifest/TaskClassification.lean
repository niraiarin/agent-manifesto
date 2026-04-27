import AgentSpec.Manifest.Ontology
import AgentSpec.Manifest.Observable
import AgentSpec.Manifest.DesignFoundation

/-!
# TaskClassification - Structural Enforcement of Deterministic Tasks

決定可能性理論 (Church 1936, Rice 1953) と効果システム (Moggi 1991) の
合流点として、タスクを自動化可能性で分類する。

- **Rice の定理**: 構文的性質 → 決定可能 → スクリプト / 意味論的性質 → 決定不可能 → 判断
- **Observable**: `∃ f : World → Bool, ∀ w, f w = true ↔ P w` — スクリプトの存在を型レベルで表現
- **D11**: structural enforcement はコンテキストコスト最小
-/

namespace AgentSpec.Manifest

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

-- ============================================================
-- 構造的強制の義務（核心の命題）
-- ============================================================

/-- 決定論的タスクは構造的強制レイヤーで実行されなければならない。

    「LLM がやるべきでないことを LLM にやらせてはならない」の形式化。

    D11 (contextCost) + T3 (context_finite) + T7 (resource_finite) から:
    決定論的タスクを normative 層で実行することは非効率的リソース使用。

    Note: taskMinEnforcement の定義から直接導出可能（定義的真理）。
    axiom ではなく theorem として証明する（公理衛生: nonTautological）。 -/
theorem deterministic_must_be_structural :
  ∀ (tc : TaskAutomationClass),
    tc = .deterministic →
    (taskMinEnforcement tc).strength ≥ EnforcementLayer.structural.strength := by
  intro tc h; subst h; decide

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

-- ============================================================
-- メタ定理: 分類のブートストラップ問題 (#236)
-- ============================================================

/-! ## 分類のメタレベル分析

タスクを TaskAutomationClass に分類する行為自体のコスト構造を形式化する。

Rice の定理 (1953): 任意のプログラムの非自明な意味論的性質は決定不能。
「TaskSuccessCondition が Observable か」は意味論的性質であり、
一般には決定手続きが存在しない。したがって分類タスクは judgmental。

この事実から、分類をいつ行うか（デザインタイム vs ランタイム）の
コスト最適化が導出される。
-/

/- [Derivation Card]
   Proposition: classification_is_judgmental
   Derives from: Rice の定理（外部数学）、TaskAutomationClass の定義
   Content: タスク分類の meta-task は judgmental に分類される
   Proof strategy: 定義による（Rice の定理を根拠に .judgmental と定義し、
                   taskMinEnforcement が .normative であることを導出） -/

/-- タスク分類の meta-task の自動化クラス。
    「任意の TaskSuccessCondition が Observable か否か」を判定するタスクは、
    Rice の定理により一般に決定不能であるため、judgmental に分類される。

    注記: これは定義的真理ではなく、Rice の定理に基づく設計判断の形式化。
    Rice の定理自体はこの形式化の射程外（計算可能性理論）。 -/
def classificationTaskClass : TaskAutomationClass := .judgmental

/-- タスク分類は judgmental — 構造的強制では自動化できない。
    Rice の定理の系: Observable かどうかの判定は意味論的性質であり決定不能。 -/
theorem classification_is_judgmental :
  taskMinEnforcement classificationTaskClass = .normative := by rfl

/-- タスク分類のコンテキストコストは最大（normative 層）。 -/
theorem classification_cost_is_maximal :
  contextCost (taskMinEnforcement classificationTaskClass) =
  contextCost .normative := by rfl

/- [Derivation Card]
   Proposition: designtime_classification_amortizes
   Derives from: contextCost の定義、classification_is_judgmental
   Content: デザインタイム分類（1 回 judgmental + n 回 structural）の
            トータルコストはランタイム分類（n 回 judgmental）以下（n ≥ 2）
   Proof strategy: contextCost .structural = 0, .normative = 2 を展開し、
                   2 + n * 0 ≤ n * 2 を n ≥ 2 から導出 -/

/-- デザインタイム分類の償却定理。

    デザインタイム: 分類を 1 回実行（normative コスト）+ n 回の実行（structural コスト）
    ランタイム: 毎回分類を実行（n 回の normative コスト）

    n ≥ 2 のとき、デザインタイムのトータルコストはランタイム以下。
    /evolve は 95+ 回実行されており、償却効果は顕著。 -/
theorem designtime_classification_amortizes (n : Nat) (h : n ≥ 2) :
  contextCost .normative + n * contextCost .structural ≤
  n * contextCost .normative := by
  simp [contextCost]
  omega

/-- デザインタイムの節約量は (n-1) * normative コスト。 -/
theorem designtime_savings (n : Nat) (h : n ≥ 1) :
  n * contextCost .normative - (contextCost .normative + n * contextCost .structural) =
  (n - 1) * contextCost .normative := by
  simp [contextCost]
  omega

/- [Derivation Card]
   Proposition: mixed_task_decomposition
   Derives from: contextCost の順序（deterministic_minimizes_cost）
   Content: mixed タスクを deterministic 成分と judgmental 成分に分解すると、
            全体を judgmental として実行するよりコストが小さい
   Proof strategy: contextCost .structural = 0 より、
                   d * 0 + j * 2 ≤ (d + j) * 2 を自然数算術で導出 -/

/-- mixed タスクの分解原理。

    d 個の deterministic 成分 + j 個の judgmental 成分からなるタスクを、
    各成分を適切な層で実行する（structural + normative）方が、
    全体を normative 層で実行するよりコストが小さい。

    これは /evolve の各フェーズ内で「データ収集（script）と
    解釈（agent）を分離する」設計判断の形式的根拠。 -/
theorem mixed_task_decomposition (d j : Nat) :
  d * contextCost .structural + j * contextCost .normative ≤
  (d + j) * contextCost .normative := by
  simp [contextCost]
  omega

/-- mixed タスク分解の節約量は d * normative コスト。
    deterministic 成分が多いほど節約効果が大きい。 -/
theorem mixed_decomposition_savings (d j : Nat) :
  (d + j) * contextCost .normative -
  (d * contextCost .structural + j * contextCost .normative) =
  d * contextCost .normative := by
  simp [contextCost]
  omega

end AgentSpec.Manifest
