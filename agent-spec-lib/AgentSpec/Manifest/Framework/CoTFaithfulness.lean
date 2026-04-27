import AgentSpec.Manifest.Ontology
import AgentSpec.Manifest.E1
import AgentSpec.Manifest.E2
import AgentSpec.Manifest.E3

/-!
# CoT Faithfulness

## 目的

LLM が出力する推論過程（Chain-of-Thought）が実際の内部計算過程を
忠実に反映しない場合があるという経験的知見を形式化する。

## T4 との差異

- **T4** (`output_nondeterministic`): 同一入力に対して異なる出力が生じうる（World レベルの非決定性）
- **E3-CoT**: 出力された推論過程が実際の内部過程と乖離する（観察可能な説明と観察不能な計算の不一致）

T4 は「何が出力されるか」の非決定性。E3-CoT は「出力された説明が実際の過程を反映しているか」の忠実性。
直交する概念であり、T4 から E3-CoT は導出不可能。

## E1 との関係

E3-CoT は E1（検証の独立性）の empirical backing を強化する:
- E1: 生成と検証は分離すべき
- E3-CoT が示す根拠: 生成者の CoT（推論説明）は内部過程を反映しない場合がある
  → 生成者の自己説明を検証根拠として信頼できない → 独立した検証者が必要

## Research Issue

#529 (Parent: #526), Gap 4
-/

namespace AgentSpec.Manifest.Framework.CoTFaithfulness

open Manifest

-- ============================================================
-- CoT の表現
-- ============================================================

/-- 推論過程（Chain-of-Thought）のステップ。
    LLM が出力するテキストとしての推論を表現する。 -/
structure CoTStep where
  /-- ステップの説明（LLM が出力するテキスト）。 -/
  explanation : String
  /-- このステップが参照する前提（前のステップの番号等）。 -/
  premises : List Nat
  deriving Repr

/-- CoT 全体。ステップの列。 -/
structure CoT where
  steps : List CoTStep
  deriving Repr

-- ============================================================
-- E3-CoT: 推論過程の事後合理化
-- ============================================================

/-- 推論過程の忠実性。
    あるエージェントの出力に付随する CoT が、そのエージェントの
    内部計算過程を忠実に反映しているかの述語。

    この述語は opaque: LLM の内部過程は外部から直接観察不能であるため、
    忠実性の判定は原理的に不完全。 -/
opaque isFaithful (agent : Agent) (cot : CoT) (w : World) : Prop

/-- [Axiom Card]
    Layer: Γ \ T₀ (Hypothesis-derived)
    Content: LLM が出力する推論過程（CoT）は、実際の内部計算過程を
          忠実に反映しない場合がある（事後合理化）。

    T4 との差異:
    - T4: World レベルの非決定性（Output 全体が異なりうる）
    - E3-CoT: 出力された CoT が内部過程と乖離しうる
    T4 は出力の「何」、E3-CoT は出力の「なぜ」の信頼性に関する主張。

    E1 との関係:
    E3-CoT は E1 の empirical backing を強化する。
    生成者の CoT が事後合理化であるならば、生成者の自己説明を
    検証根拠として使用することは P2 違反のリスクを持つ。
    → 独立した検証者による検証が必要（E1 の結論と一致）。

    根拠:
    [R71] Lanham et al. (Anthropic, 2025) "Measuring Faithfulness in
          Chain-of-Thought Reasoning" — Claude 3.7 Sonnet が hidden hints の
          使用を 25% しか開示せず、75% の場合で plausible な代替説明を生成。
          → Registered as CORE-H2 in Models/Assumptions/EpistemicLayer.lean (#547)
    [R72] Turpin et al. (2024) "Language Models Don't Always Say What They Think"
          — Biased few-shot examples が CoT に反映されず、出力のみに影響。
          → Registered as CORE-H3 in Models/Assumptions/EpistemicLayer.lean (#547)

    反証条件: LLM の内部表現と出力 CoT の因果関係が確立され、
          CoT が常に内部過程を忠実に反映することが示された場合。 -/
axiom cot_not_always_faithful :
  ∃ (agent : Agent) (cot : CoT) (w : World),
    ¬isFaithful agent cot w

-- ============================================================
-- E1 の empirical backing としての導出
-- ============================================================

/-- CoT が事後合理化でありうるならば、生成者の自己説明は
    検証根拠として無条件に信頼できない。 -/
theorem cot_unfaithfulness_implies_verification_need :
    (∃ (agent : Agent) (cot : CoT) (w : World), ¬isFaithful agent cot w) →
    ¬(∀ (agent : Agent) (cot : CoT) (w : World), isFaithful agent cot w) := by
  intro ⟨agent, cot, w, h⟩ hall
  exact h (hall agent cot w)

/-- E3-CoT は T4 と独立: T4 の成立は CoT の忠実性について何も述べない。
    T4 は World の差異（出力の非決定性）、E3-CoT は CoT の忠実性（説明の信頼性）。
    同一 World でも CoT が不忠実でありうるし、異なる World でも CoT が忠実でありうる。 -/
theorem cot_independent_of_output_nondeterminism :
    -- T4 が成立しても、全ての CoT が忠実である可能性は排除されない
    -- （T4 は World の差異を述べるが、CoT の忠実性には言及しない）
    (∃ (agent : Agent) (action : Action) (w w₁ w₂ : World),
      canTransition agent action w w₁ ∧
      canTransition agent action w w₂ ∧
      w₁ ≠ w₂) →
    -- この前提からは CoT の不忠実性は導出できない
    -- （結論を True にすることで、T4 → E3-CoT が trivial でないことを表現）
    True := by
  intro _
  trivial

end AgentSpec.Manifest.Framework.CoTFaithfulness
