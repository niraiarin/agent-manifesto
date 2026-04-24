import AgentSpec.Manifest.Terminology
import AgentSpec.Manifest.Models.Assumptions.EpistemicLayer

/-!
# EpistemicBridge

## 目的

`EpistemicSource` (Models/Assumptions/EpistemicLayer.lean, namespace Manifest.Models.Assumptions)
と `EpistemicStatus` (Terminology.lean, namespace Manifest.Terminology) を型レベルで接続する。

## 設計判断

- **Conservative extension**: 既存の `EpistemicSource` と `EpistemicStatus` を変更しない
- **独立モジュール**: 両方を import し、対応関数として橋渡しを提供
- **import chain**: Manifest.Terminology ← このファイル → Manifest.Models.Assumptions.EpistemicLayer
  循環なし（Terminology は Models を import しない、Models.Assumptions は Terminology を import しない）

## Research Issue

#529 (Parent: #526), Gap 5
-/

namespace AgentSpec.Manifest.Framework.EpistemicBridge

open AgentSpec.Manifest.Terminology
open AgentSpec.Manifest.Models.Assumptions

-- ============================================================
-- EpistemicSource → EpistemicStatus 対応
-- ============================================================

/-- H-type 仮定の根拠の認識論的地位を返す。

    - `humanDecision`: 人間の判断に基づく → `empirical`（経験的観察に基づく）
    - `llmInference`: LLM の推論に基づく → `falsifiable`（反証条件が定義されている）

    判定根拠:
    - C (humanDecision) は T6 権威に基づく経験的判断。analytic（定義から真偽が定まる）
      ではなく、empirical（観察・経験に基づく）に分類される。
    - H (llmInference) は反証条件 (refutation) を明示的に持つ。
      falsifiable（偽とする観察が原理的に可能）に分類される。 -/
def epistemicStatusOf : EpistemicSource → EpistemicStatus
  | .humanDecision _ _ _ => .empirical
  | .llmInference _ _ => .falsifiable

/-- humanDecision は empirical に対応する。 -/
theorem human_decision_is_empirical (phase : Nat) (q : String) (date : String) :
    epistemicStatusOf (.humanDecision phase q date) = .empirical := by
  simp [epistemicStatusOf]

/-- llmInference は falsifiable に対応する。 -/
theorem llm_inference_is_falsifiable (basis : List String) (refutation : String) :
    epistemicStatusOf (.llmInference basis refutation) = .falsifiable := by
  simp [epistemicStatusOf]

/-- EpistemicSource の全コンストラクタが EpistemicStatus に対応する（全射的ではないが全域的）。 -/
theorem epistemic_bridge_total :
    ∀ (s : EpistemicSource), epistemicStatusOf s = .empirical ∨ epistemicStatusOf s = .falsifiable := by
  intro s
  cases s with
  | humanDecision _ _ _ => left; simp [epistemicStatusOf]
  | llmInference _ _ => right; simp [epistemicStatusOf]

/-- humanDecision と llmInference は異なる EpistemicStatus に対応する。 -/
theorem epistemic_bridge_discriminates
    (phase : Nat) (q : String) (date : String)
    (basis : List String) (refutation : String) :
    epistemicStatusOf (.humanDecision phase q date) ≠
    epistemicStatusOf (.llmInference basis refutation) := by
  simp [epistemicStatusOf]

-- ============================================================
-- Assumption レベルの橋渡し
-- ============================================================

/-- Assumption の認識論的地位を返す。 -/
def assumptionEpistemicStatus (a : Assumption) : EpistemicStatus :=
  epistemicStatusOf a.source

/-- H-type Assumption は falsifiable。 -/
theorem h_type_assumption_is_falsifiable
    (a : Assumption)
    (h : ∃ basis refutation, a.source = .llmInference basis refutation) :
    assumptionEpistemicStatus a = .falsifiable := by
  obtain ⟨basis, refutation, hsrc⟩ := h
  simp [assumptionEpistemicStatus, hsrc, epistemicStatusOf]

/-- C-type Assumption は empirical。 -/
theorem c_type_assumption_is_empirical
    (a : Assumption)
    (h : ∃ phase q date, a.source = .humanDecision phase q date) :
    assumptionEpistemicStatus a = .empirical := by
  obtain ⟨phase, q, date, hsrc⟩ := h
  simp [assumptionEpistemicStatus, hsrc, epistemicStatusOf]

-- ============================================================
-- analytic は EpistemicSource からは到達しない
-- ============================================================

/-- analytic は EpistemicSource の像に含まれない。
    条件付き公理系の仮定は analytic（定義的に真）ではありえない。
    これは意図通り: 公理系の仮定は検証可能（empirical/falsifiable）であるべき。 -/
theorem analytic_unreachable :
    ∀ (s : EpistemicSource), epistemicStatusOf s ≠ .analytic := by
  intro s
  cases s with
  | humanDecision _ _ _ => simp [epistemicStatusOf]
  | llmInference _ _ => simp [epistemicStatusOf]

end AgentSpec.Manifest.Framework.EpistemicBridge
