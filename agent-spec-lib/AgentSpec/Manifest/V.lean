import AgentSpec.Manifest.Ontology

/-! # AgentSpec.Manifest.V (Week 3 Day 97)

V 系列 axiom batch 1 — tradeoff (V1↔V2, V6↔V2, V2↔V1, V2↔V6, V7↔V2, V3↔V2, V5↔V2)
+ Goodhart 脆弱性 (V4, V7)。Phase 0 ObservableDesign 由来 axiom 9 件。
-/

namespace AgentSpec.Manifest

/-- V1↑ → V2↓ tradeoff (skill が context 消費)。 -/
axiom tradeoff_v1_v2 : TradeoffExists skillQuality contextEfficiency

/-- V6↑ → V2↓ tradeoff (詳細知識が context 占有)。 -/
axiom tradeoff_v6_v2 : TradeoffExists knowledgeStructureQuality contextEfficiency

/-- V2↑ → V1↓ tradeoff (効率追求で skill 圧縮過剰リスク)。 -/
axiom tradeoff_v2_v1 : TradeoffExists contextEfficiency skillQuality

/-- V2↑ → V6↓ tradeoff (効率追求で知識圧縮過剰リスク)。 -/
axiom tradeoff_v2_v6 : TradeoffExists contextEfficiency knowledgeStructureQuality

/-- V7↑ → V2↓ tradeoff (高度分散設計が context 消費)。 -/
axiom tradeoff_v7_v2 : TradeoffExists taskDesignEfficiency contextEfficiency

/-- V3↑ → V2↓ tradeoff (品質検証が context 消費)。 -/
axiom tradeoff_v3_v2 : TradeoffExists outputQuality contextEfficiency

/-- V5↑ → V2↓ tradeoff (詳細分析が context 消費)。 -/
axiom tradeoff_v5_v2 : TradeoffExists proposalAccuracy contextEfficiency

/-- V4 (gate pass rate) は Goodhart 脆弱 (測定容易な gate に偏るリスク)。 -/
axiom v4_goodhart : GoodhartVulnerable gatePassRate

/-- V7 (task design efficiency) は Goodhart 脆弱 (測定容易タスクに偏るリスク)。 -/
axiom v7_goodhart : GoodhartVulnerable taskDesignEfficiency

/-! ## Day 99 拡張: V batch 2 (investment cycle + trust 漸進蓄積) -/

/-- 信頼の漸進蓄積 (action space 拡大 + risk 未顕在化 で trust 増加、但し増加幅は bounded)。 -/
axiom trust_accumulates_gradually :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w ≤ actionSpaceSize agent w' →
    ¬riskMaterialized agent w' →
    trustLevel agent w ≤ trustLevel agent w' ∧
    trustLevel agent w' ≤ trustLevel agent w + trustIncrementBound

/-- 投資は信頼に駆動される (system 健全 + V 改善 → 投資非減少)。 -/
axiom trust_drives_investment :
  ∀ (w w' : World),
    (∃ t, systemHealthy t w ∧ systemHealthy t w' ∧
      (skillQuality w < skillQuality w' ∨
       contextEfficiency w < contextEfficiency w' ∨
       outputQuality w < outputQuality w')) →
    investmentLevel w ≤ investmentLevel w'

/-- 逆サイクル: risk 顕在化 + trust 低下 → 投資縮小。 -/
axiom risk_reduces_investment :
  ∀ (agent : Agent) (w w' : World),
    riskMaterialized agent w' →
    trustLevel agent w' < trustLevel agent w →
    investmentLevel w' ≤ investmentLevel w

/-- 過拡張は協働価値を減らす (action space 拡大 → collaborative value 低下する世界対が存在)。 -/
axiom overexpansion_reduces_value :
  ∃ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' ∧
    collaborativeValue w' < collaborativeValue w

end AgentSpec.Manifest
