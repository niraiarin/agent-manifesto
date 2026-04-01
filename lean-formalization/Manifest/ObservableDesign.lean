import Manifest.Observable

/-!
# Epistemic Layer: designTheorem (strength 1) — トレードオフ・Goodhart・投資サイクル

Observable.lean（boundary 層, strength 2）の V1–V7 可測性基盤の上に構築される
設計定理層。公理系の基盤（Axioms.lean, Observable.lean）から**導出不可能な**
設計判断に基づく公理と、それらから導出される定理を含む。

## Observable.lean との関係

Observable.lean が boundary 層（V1–V7 の存在と可測性）を定義し、
本ファイルが designTheorem 層（V1–V7 間の関係性と設計上の性質）を定義する。

```
Observable.lean (boundary, strength 2)
  │  V1–V7 opaque, Measurable axioms, systemHealthy
  ▼
ObservableDesign.lean (designTheorem, strength 1)
    TradeoffExists, GoodhartVulnerable, 投資サイクル,
    HealthThresholds, Pareto, sorry解消 axioms
```

## Γ \ T₀ としての位置づけ（手順書 §2.4）

本ファイルの axiom は前提集合 Γ の拡大部分（Γ \ T₀）に属し、
設計由来（ドメインモデルの前提、設計判断に基づく）の非論理的公理（§4.1）である。

## 内容

### トレードオフ構造
V1–V7 は独立に最適化できない。ある変数の改善が別の変数を
劣化させうるトレードオフが構造的に存在する（T3 + T7 の帰結）。

### Goodhart's Law への構造的防御
変数が測定対象になった瞬間、メトリクスとしての妥当性を失い始める。

### 投資サイクル (manifesto Section 6)
信頼は投資行動として具体化される。正方向（信頼→投資増）と
負方向（リスク→投資減）の両面を持つ。

### Sorry 解消用 axiom
Phase 3 の sorry を解消するための axiom。
-/

namespace Manifest

-- ============================================================
-- トレードオフ構造
-- ============================================================

/-!
## 変数の相互依存性

V1–V7 は独立に最適化できない。ある変数の改善が別の変数を
劣化させうるトレードオフが構造的に存在する。

これは T3（コンテキスト有限性）と T7（リソース有限性）の
直接的帰結: 有限のリソースを共有する指標は
必然的にトレードオフ関係にある。
-/

/-- トレードオフの存在。2つの測定関数 m₁, m₂ について、
    m₁ が改善するとき m₂ が劣化するワールド対が存在する。

    注: これは「常に劣化する」ではなく「劣化しうる」を表現する。
    Pareto 改善（両方同時に改善）が不可能であることは含意しない。 -/
def TradeoffExists (m₁ m₂ : World → Nat) : Prop :=
  ∃ w w', m₁ w < m₁ w' ∧ m₂ w' < m₂ w

/-- [Axiom Card]
    Layer: Γ \ T₀（設計由来）
    Content: V1↑ → V2↓ のトレードオフ。
          スキルがコンテキストを消費するため、スキル品質の向上は
          コンテキスト効率を圧迫しうる
    Basis: T3（コンテキスト有限性）の帰結。有限リソースを共有する指標間の
          トレードオフは T3 + T7 から構造的に導出される
    Source: Ontology.lean L2/L3 境界条件の分析
    Refutation condition: スキルのコンテキスト消費が 0 になる技術が実現した場合 -/
axiom tradeoff_v1_v2 : TradeoffExists skillQuality contextEfficiency

/-- [Axiom Card]
    Layer: Γ \ T₀（設計由来）
    Content: V6↑ → V2↓ のトレードオフ。
          詳細な知識ほどコンテキストを占有するため、
          知識構造の質の向上はコンテキスト効率を圧迫しうる
    Basis: T3（コンテキスト有限性）の帰結
    Source: Ontology.lean L2 境界条件の分析
    Refutation condition: 知識のコンテキスト消費が 0 になる技術が実現した場合 -/
axiom tradeoff_v6_v2 : TradeoffExists knowledgeStructureQuality contextEfficiency

/-- [Axiom Card]
    Layer: Γ \ T₀（設計由来）
    Content: V2↑ → V1↓ のトレードオフ。
          効率追求で必要なスキル情報を圧縮しすぎるリスク
    Basis: 圧縮は情報損失を伴いうるという情報理論的制約
    Source: V1/V2 の相互依存性分析
    Refutation condition: 無損失圧縮がスキル情報に対して常に実現可能な場合 -/
axiom tradeoff_v2_v1 : TradeoffExists contextEfficiency skillQuality

/-- [Axiom Card]
    Layer: Γ \ T₀（設計由来）
    Content: V2↑ → V6↓ のトレードオフ。
          効率追求で必要な知識を圧縮しすぎるリスク
    Basis: 圧縮は情報損失を伴いうるという情報理論的制約
    Source: V2/V6 の相互依存性分析
    Refutation condition: 無損失圧縮が知識構造に対して常に実現可能な場合 -/
axiom tradeoff_v2_v6 : TradeoffExists contextEfficiency knowledgeStructureQuality

/-- [Axiom Card]
    Layer: Γ \ T₀（設計由来）
    Content: V7↑ → V2↓ のトレードオフ。
          高度な分散設計がコンテキストを消費するリスク
    Basis: T3（コンテキスト有限性）の帰結。設計の複雑性はコンテキストを消費する
    Source: V7/V2 の相互依存性分析
    Refutation condition: タスク設計の複雑性がコンテキスト消費と無相関になった場合 -/
axiom tradeoff_v7_v2 : TradeoffExists taskDesignEfficiency contextEfficiency

/-- [Axiom Card]
    Layer: Γ \ T₀（設計由来）
    Content: V3↑ → V2↓ のトレードオフ。
          品質向上のための追加検証（レビュー、テスト実行、ゲート確認）は
          コンテキストを消費するため、出力品質の向上はコンテキスト効率を圧迫しうる
    Basis: T3（コンテキスト有限性）の帰結。品質検証プロセスは有限のリソースを消費する
    Source: V3/V2 の相互依存性分析
    Refutation condition: 品質検証がコンテキストを消費しない（ゼロコスト検証が実現する）場合 -/
axiom tradeoff_v3_v2 : TradeoffExists outputQuality contextEfficiency

/-- [Axiom Card]
    Layer: Γ \ T₀（設計由来）
    Content: V5↑ → V2↓ のトレードオフ。
          提案精度の向上には詳細な要求分析とコンテキスト把握が必要であり、
          精度の高い提案ほど多くのコンテキストを消費しうる
    Basis: T3（コンテキスト有限性）の帰結。詳細分析はコンテキストを消費する
    Source: V5/V2 の相互依存性分析
    Refutation condition: 提案精度の向上がコンテキスト消費を増やさないことが示された場合 -/
axiom tradeoff_v5_v2 : TradeoffExists proposalAccuracy contextEfficiency

-- ============================================================
-- Goodhart's Law への構造的防御
-- ============================================================

/-!
## Goodhart's Law

「測定対象となった指標は、良い指標であることをやめる。」

変数 m の**近似測定** approx が m と乖離するリスクを型で表現する。
防御策:
1. 複数の独立した測定方法を持つ
2. メトリクス自体を定期的に見直す（P3 の学習ライフサイクル）
3. 人間の定性的判断を系の健全性評価に含める（T6）
-/

/-- Goodhart 脆弱性。最適化対象の近似測定 approx が
    真の指標 m から乖離するワールドが存在する。

    任意の近似測定に対してこれが成立する場合、
    その変数は Goodhart 脆弱性を持つ。 -/
def GoodhartVulnerable (m : World → Nat) : Prop :=
  ∀ (approx : World → Nat),
    (∃ w, approx w = m w) →   -- approx は少なくとも1点で一致する
    ∃ w', approx w' ≠ m w'    -- しかし乖離するワールドが存在する

/-- [Axiom Card]
    Layer: Γ \ T₀（設計由来）
    Content: V4（ゲート通過率）は Goodhart 脆弱性を持つ。
          ゲートが通りやすいタスクに偏るリスク
    Basis: Goodhart の法則は経済学・教育学で繰り返し観測されている
          （用語リファレンス §9.1 経験的命題に類似）
    Source: V4 の設計分析
    Refutation condition: 近似測定が真の指標から乖離しないことが証明された場合 -/
axiom v4_goodhart : GoodhartVulnerable gatePassRate

/-- [Axiom Card]
    Layer: Γ \ T₀（設計由来）
    Content: V7（タスク設計効率）は Goodhart 脆弱性を持つ。
          測定しやすいタスクに偏るリスク
    Basis: Goodhart の法則の適用
    Source: V7 の設計分析
    Refutation condition: 近似測定が真の指標から乖離しないことが証明された場合 -/
axiom v7_goodhart : GoodhartVulnerable taskDesignEfficiency

-- ============================================================
-- Goodhart 脆弱性からの導出定理
-- ============================================================

/-- Goodhart 脆弱な指標には完全な代理測定が存在しない。
    GoodhartVulnerable m は「任意の approx に乖離点が存在する」を述べるが、
    本定理はその直接的帰結として「全点で一致する approx は存在しない」を示す。 -/
theorem goodhart_no_perfect_proxy (m : World → Nat) (h : GoodhartVulnerable m) :
    ¬∃ (approx : World → Nat), ∀ w, approx w = m w := by
  intro ⟨approx, h_all⟩
  have h_some : ∃ w, approx w = m w := ⟨default, h_all default⟩
  obtain ⟨w', hw'⟩ := h approx h_some
  exact hw' (h_all w')

/-- V4 (gatePassRate) には完全な代理測定が存在しない。 -/
theorem v4_no_perfect_proxy :
    ¬∃ (approx : World → Nat), ∀ w, approx w = gatePassRate w :=
  goodhart_no_perfect_proxy gatePassRate v4_goodhart

/-- V7 (taskDesignEfficiency) には完全な代理測定が存在しない。 -/
theorem v7_no_perfect_proxy :
    ¬∃ (approx : World → Nat), ∀ w, approx w = taskDesignEfficiency w :=
  goodhart_no_perfect_proxy taskDesignEfficiency v7_goodhart

-- ============================================================
-- Sorry 解消用 axiom（Phase 3 → Phase 4）
-- ============================================================

/-!
## Phase 3 sorry の解消

Principles.lean の3つの sorry を解消するための axiom。

これらは V1–V7 の Observable 層が整備されたことで、
信頼・劣化・解釈の測定基盤が確立されたことを前提とする。

### 性格分類

- `trust_decreases_on_materialized_risk`: 経験的公準レベル。
  信頼蓄積の非対称性は繰り返し観測されているが、
  原理的には覆りうる。[observable-axiom, empirical]

- `degradation_level_surjective`: Observable 層の設計仮定。
  劣化を連続的な尺度（壁ではなく勾配）で捉えるという
  P4 の設計判断を形式化。[observable-axiom]

- `interpretation_nondeterminism`: T4 の高水準再述。
  canTransition レベルの非決定性を構造解釈レベルに
  持ち上げる。T4 と interpretsStructure の橋渡し。
  [observable-axiom, derived-from-T4]
-/

/-- [Axiom Card]
    Layer: Γ \ T₀（仮説由来）
    Content: リスクが顕在化した場合、信頼度は低下する。
          行動空間の拡大後にリスクが顕在化した場合、
          信頼度は拡大前の水準を下回る
    Basis: 蓄積した信頼は漸進的だが、毀損は急激（非対称性）。
          組織心理学、ブランド管理、セキュリティ分野で繰り返し観測される
          （用語リファレンス §9.1 経験的命題）
    Source: P1b (`unprotected_expansion_destroys_trust`) の sorry 解消
    Refutation condition: 信頼毀損が信頼蓄積と同等の速度でしか生じないことが実証された場合 -/
axiom trust_decreases_on_materialized_risk :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskMaterialized agent w' →
    trustLevel agent w' < trustLevel agent w

/-- [Axiom Card]
    Layer: Γ \ T₀（設計由来）
    Content: 劣化レベルは任意の自然数を取りうる（全射性）。
          「制約は壁（バイナリ）ではなく勾配（グラデーション）」
          という P4 の概念を、degradationLevel の値域が Nat 全体に
          広がることで表現する
    Basis: 劣化を 0/1 で捉えると中間状態を見逃す。
          連続的な尺度により、早期警告と漸進的対応が可能になる
    Source: P4b (`degradation_is_gradient`) の sorry 解消
    Refutation condition: 劣化が本質的に二値（正常/異常）でしかないことが示された場合 -/
axiom degradation_level_surjective :
  ∀ (n : Nat), ∃ (w : World), degradationLevel w = n

/-- [Axiom Card]
    Layer: Γ \ T₀（設計由来）
    Content: 構造の解釈は非決定的。
          同一の構造を読んでも、異なるアクションが生成されうる
    Basis: T4 (`output_nondeterministic`) の高水準再述。
          canTransition の非決定性（同一入力→異なるワールド遷移）は、
          その前段階である構造解釈の非決定性を含意する
          （対偶: 解釈が決定的なら遷移も決定的）
    Source: P5 (`structure_interpretation_nondeterministic`) の sorry 解消
    Refutation condition: LLM の構造解釈が決定論的になった場合（T4 の反証に相当するが、
              T4 は T₀ であるため、本 axiom の反証は T4 との矛盾を意味する） -/
axiom interpretation_nondeterminism :
  ∃ (agent : Agent) (st : Structure) (action₁ action₂ : Action) (w : World),
    interpretsStructure agent st action₁ w ∧
    interpretsStructure agent st action₂ w ∧
    action₁ ≠ action₂

-- ============================================================
-- Sorry Inventory (Phase 4)
-- ============================================================

/-!
## Sorry Inventory

Phase 4 では新たな sorry は導入しない。
Phase 3 の3つの sorry を axiom で解消する。

### 解消された sorry

| Principles.lean の sorry | 解消する axiom |
|--------------------------|---------------|
| `unprotected_expansion_destroys_trust` | `trust_decreases_on_materialized_risk` |
| `degradation_is_gradient` | `degradation_level_surjective` |
| `structure_interpretation_nondeterministic` | `interpretation_nondeterminism` |

### 新規 axiom の妥当性レビュー

| axiom | 空虚でないか | トートロジーでないか | 反証可能か |
|-------|------------|-------------------|-----------|
| `trust_decreases_on_materialized_risk` | ✓ 3つの前提が必要 | ✓ trustLevel の単調減少を主張 | ✓ 顕在化しても信頼が維持される事例 |
| `degradation_level_surjective` | ✓ 任意の n に対する存在 | ✓ World の構成を制約 | ✓ 有界な劣化モデル |
| `interpretation_nondeterminism` | ✓ 具体的な5つ組の存在 | ✓ 非決定性を主張 | ✓ 完全決定的な解釈モデル |
| v1–v7_measurable | ✓ opaque 展開不能 | ✓ 計算手続きの存在を主張 | ✓ 原理的に測定不能な指標 |
| tradeoff_* | ✓ 具体的なワールド対の存在 | ✓ 改善/劣化の同時発生 | ✓ 完全分離可能なリソース |
| v4/v7_goodhart | ✓ 任意の approx に対する乖離 | ✓ 近似の限界を主張 | ✓ 完璧な測定手段の存在 |
-/

-- ============================================================
-- Phase 5 拡張: 変数ごと閾値
-- ============================================================

/-!
## 変数ごと閾値（Per-variable Thresholds）

Phase 4 の `systemHealthy` は一律閾値だったが、
実運用では変数ごとに異なる閾値が必要。

例: gatePassRate は 800/1000 を要求するが、
proposalAccuracy は 600/1000 で十分、など。
閾値の設定は T6（人間がリソースの最終決定者）に対応する運用判断。
-/

/-- V1–V7 それぞれの閾値。
    変数ごとに異なる最低要求水準を設定する。 -/
structure HealthThresholds where
  v1_skillQuality              : Nat
  v2_contextEfficiency         : Nat
  v3_outputQuality             : Nat
  v4_gatePassRate              : Nat
  v5_proposalAccuracy          : Nat
  v6_knowledgeStructureQuality : Nat
  v7_taskDesignEfficiency      : Nat
  deriving BEq, Repr, DecidableEq

/-- 変数ごと閾値による系の健全性。
    `systemHealthy` の拡張版。 -/
def systemHealthyPerVar (th : HealthThresholds) (w : World) : Prop :=
  skillQuality w ≥ th.v1_skillQuality ∧
  contextEfficiency w ≥ th.v2_contextEfficiency ∧
  outputQuality w ≥ th.v3_outputQuality ∧
  gatePassRate w ≥ th.v4_gatePassRate ∧
  proposalAccuracy w ≥ th.v5_proposalAccuracy ∧
  knowledgeStructureQuality w ≥ th.v6_knowledgeStructureQuality ∧
  taskDesignEfficiency w ≥ th.v7_taskDesignEfficiency

/-- 一律閾値は変数ごと閾値の特殊ケース。
    全変数に同じ閾値を設定した HealthThresholds は
    systemHealthy と同値。 -/
def uniformThresholds (t : Nat) : HealthThresholds :=
  { v1_skillQuality := t
    v2_contextEfficiency := t
    v3_outputQuality := t
    v4_gatePassRate := t
    v5_proposalAccuracy := t
    v6_knowledgeStructureQuality := t
    v7_taskDesignEfficiency := t }

/-- 一律閾値による systemHealthyPerVar は systemHealthy と一致。 -/
theorem uniform_thresholds_equiv :
  ∀ (t : Nat) (w : World),
    systemHealthyPerVar (uniformThresholds t) w ↔ systemHealthy t w := by
  intro t w
  simp [systemHealthyPerVar, uniformThresholds, systemHealthy]

/-- 運用閾値（observe.sh と対応する具体的な閾値設定）。
    各フィールドの値はパーセント（observe.sh と同一スケール）。

    運用対応表:
    - v3_outputQuality = 90: test_pass_rate 指標（90% 以上で健全）。
      fix_ratio 削除後（Run 69）、test_pass_rate が正式指標として確立。
      閾値 90 は test_pass_rate スケール（0-100%）に整合した運用値（Run 70 で調整）。
    - 他の変数は暫定値 50（50%）。運用データ蓄積後に個別調整

    注: この定数は T6（人間がリソースの最終決定者）に基づく運用判断であり、
    T₀ の一部ではない。値の変更は compatible change として扱う。 -/
def operationalThresholds : HealthThresholds :=
  { v1_skillQuality              := 50
    v2_contextEfficiency         := 50
    v3_outputQuality             := 90   -- test_pass_rate 指標。90% 以上で健全（Run 70 で旧 fix_ratio 由来 20 から調整）
    v4_gatePassRate              := 50
    v5_proposalAccuracy          := 50
    v6_knowledgeStructureQuality := 50
    v7_taskDesignEfficiency      := 50 }

/-- 運用閾値の V3 は 90（test_pass_rate: 90% 以上で健全。Run 70 で旧 fix_ratio 由来の 20 から調整）。 -/
theorem operational_v3_threshold :
  operationalThresholds.v3_outputQuality = 90 := by rfl

/-- 運用閾値は一律閾値の特殊化ではない（V3 が他と異なる）。 -/
theorem operational_not_uniform :
  operationalThresholds ≠ uniformThresholds 50 := by decide

-- ============================================================
-- Phase 5 拡張: Pareto フロンティア
-- ============================================================

/-!
## Pareto フロンティア

Pareto フロンティアは「これ以上の Pareto 改善が不可能な領域」。
トレードオフ axiom の存在から、系が常に Pareto フロンティア上に
留まれるとは限らないことを示す。

### 形式化の方針

Pareto optimal の定義を与え、トレードオフ axiom から
「すべてのワールドが Pareto optimal ではない」ことを示す。
-/

/-- Pareto 改善: すべての変数が悪化せず、少なくとも1つが改善。 -/
def paretoImprovement (w w' : World) : Prop :=
  (skillQuality w ≤ skillQuality w') ∧
  (contextEfficiency w ≤ contextEfficiency w') ∧
  (outputQuality w ≤ outputQuality w') ∧
  (gatePassRate w ≤ gatePassRate w') ∧
  (proposalAccuracy w ≤ proposalAccuracy w') ∧
  (knowledgeStructureQuality w ≤ knowledgeStructureQuality w') ∧
  (taskDesignEfficiency w ≤ taskDesignEfficiency w') ∧
  (skillQuality w < skillQuality w' ∨
   contextEfficiency w < contextEfficiency w' ∨
   outputQuality w < outputQuality w' ∨
   gatePassRate w < gatePassRate w' ∨
   proposalAccuracy w < proposalAccuracy w' ∨
   knowledgeStructureQuality w < knowledgeStructureQuality w' ∨
   taskDesignEfficiency w < taskDesignEfficiency w')

/-- Pareto optimal: w からの Pareto 改善が存在しない。 -/
def paretoOptimal (w : World) : Prop :=
  ¬∃ w', paretoImprovement w w'

/-- Pareto dominated: w' による Pareto 改善が可能。 -/
def paretoDominated (w : World) : Prop :=
  ∃ w', paretoImprovement w w'

/-- Pareto optimal と Pareto dominated は排他的。 -/
theorem pareto_optimal_not_dominated :
  ∀ (w : World),
    paretoOptimal w → ¬paretoDominated w := by
  intro w h_opt h_dom
  exact h_opt h_dom

/-- Pareto dominated でなければ Pareto optimal。 -/
theorem not_dominated_is_optimal :
  ∀ (w : World),
    ¬paretoDominated w → paretoOptimal w := by
  intro w h
  exact h

-- ============================================================
-- Phase 5 拡張: robustStructure の具体化
-- ============================================================

/-!
## robustStructure の具体化

Principles.lean の `robustStructure` を Observable 層の
具体的な安全性制約と接続する。

robustStructure は「解釈のばらつきに対して安全性が保持される」
ことを要求する。ここでは安全性制約として systemHealthyPerVar を使い、
「構造の解釈がばらついても系の健全性が維持される」ことを定義する。
-/

/-- 健全性堅牢構造: 解釈のばらつきに対して
    系の健全性（変数ごと閾値）が保持される構造。

    robustStructure (Principles.lean) の具体化。
    safety := systemHealthyPerVar th とした場合。 -/
def healthRobustStructure
    (st : Structure) (th : HealthThresholds) : Prop :=
  ∀ (agent : Agent) (action : Action) (w w' : World),
    interpretsStructure agent st action w →
    canTransition agent action w w' →
    systemHealthyPerVar th w'

/-- healthRobustStructure は robustStructure の特殊化であることの
    型レベル表現。safety = systemHealthyPerVar th としたもの。

    注: robustStructure は Principles.lean で定義されているが、
    Evolution.lean は Principles.lean を import しないため、
    ここでは同じ構造を直接展開して定義している。
    両者の同値性は型の構造から自明。 -/
theorem health_robust_unfolds :
  ∀ (st : Structure) (th : HealthThresholds),
    healthRobustStructure st th =
    (∀ (agent : Agent) (action : Action) (w w' : World),
      interpretsStructure agent st action w →
      canTransition agent action w w' →
      systemHealthyPerVar th w') := by
  intro st th
  rfl

-- ============================================================
-- 投資サイクル (manifesto Section 6, taxonomy Part III)
-- ============================================================

/-!
## Part III: 協働の均衡と投資サイクル（Collaborative Equilibrium & Investment Cycle）

仮説（運用データで更新しうる）: 信頼とは抽象的な感情ではなく、
人間による協働システムへの投資行動として具体化される。
ただし信頼は非合理的にも動く（感情的愛着、惰性、不均衡な毀損）。

### サイクルの構造

```
  エージェントが構造品質を改善する
  （V1-V7。境界条件の内側で。系の健全性を維持して。）
    │
    ▼
  人間が利益を受け取る
  （時間節約、品質向上、新しい能力）
    │
    ▼
  投資意欲が変化する（増加も減少もありうる）
    │
    ├─→ リソース調整（L3の上限が変化する）
    ├─→ 行動空間調整（L4が均衡点に向かう）
    └─→ 時間投資の変化（協働の深度が変わる）
          │
          └─→ 改善余地が変化 → サイクル先頭へ
```

### 均衡の探索

投資サイクルの目的は行動空間の**最大化**ではなく、
人間-エージェント-構造の三者の協働価値が最大化される**均衡点**の探索。
均衡点は文脈によって前にも後ろにも動く。

### P1が生む構造的緊張

```
信頼蓄積 → L4拡張 → 行動空間の拡大 → 改善余地の拡大（正）
                  │
                  └→ 攻撃面・副作用の拡大 → 潜在的被害の増大（負）
```

正と負のフィードバックは同時に回る。この緊張関係は解消されるものではなく、
管理されるもの。自律権の拡張提案は、対応する防護設計とセットで行い、
拡張がもたらすリスク増分を明示する。

### この仮説の更新可能性

- 信頼は投資以外の形態（感情的愛着、惰性）でも蓄積されるかもしれない
- 投資の増加が必ずしも構造改善の機会に直結しないかもしれない
- 人間側の投資意思決定がより複雑（組織力学、予算サイクル等）かもしれない
-/

/-- 信頼蓄積の上限: 1回の改善で得られる信頼には限界がある。 -/
opaque trustIncrementBound : Nat

/-- [Axiom Card]
    Layer: Γ \ T₀（仮説由来）
    Content: 信頼の漸進的蓄積。構造品質が改善された場合、信頼は（小さく）増加する。
          非対称性の「蓄積は漸進」の半分
    Basis: 信頼蓄積の漸進性は組織心理学で繰り返し観測されている
          （用語リファレンス §9.1 経験的命題）
    Source: manifesto.md Section 6
    Refutation condition: 信頼が一度の改善で無制限に蓄積されることが実証された場合 -/
axiom trust_accumulates_gradually :
  ∀ (agent : Agent) (w w' : World),
    -- 行動空間は縮小していない（拡張方向の投資がある）
    actionSpaceSize agent w ≤ actionSpaceSize agent w' →
    -- リスクは顕在化していない
    ¬riskMaterialized agent w' →
    -- 結論: 信頼は増加するが、増加幅は boundされている
    trustLevel agent w ≤ trustLevel agent w' ∧
    trustLevel agent w' ≤ trustLevel agent w + trustIncrementBound

/-- [Axiom Card]
    Layer: Γ \ T₀（仮説由来）
    Content: 投資は信頼に駆動される。信頼が高い → 投資が増加する
    Basis: 構造品質の改善 → 利益 → 投資意欲の変化
    Source: manifesto.md Section 6 投資サイクル
    Refutation condition: 品質改善が投資増加に結びつかないことが繰り返し観測された場合 -/
axiom trust_drives_investment :
  ∀ (w w' : World),
    -- 系の健全性が改善された（全変数がある閾値以上）
    (∃ t, systemHealthy t w ∧ systemHealthy t w' ∧
      -- かつ少なくとも1つの変数が改善
      (skillQuality w < skillQuality w' ∨
       contextEfficiency w < contextEfficiency w' ∨
       outputQuality w < outputQuality w')) →
    -- 結論: 投資水準は非減少
    investmentLevel w ≤ investmentLevel w'

/-- [Axiom Card]
    Layer: Γ \ T₀（仮説由来）
    Content: 逆サイクル: 品質事故は投資を縮小させる。
          リスク顕在化 → 信頼減少 → 投資縮小
    Basis: 信頼毀損→投資縮小のサイクルは経済学・組織論で観測されている
    Source: manifesto.md Section 6「品質事故やスコープ逸脱 → 信頼の減少 → 投資の縮小」
    Refutation condition: 品質事故後も投資が維持・増加されることが繰り返し観測された場合 -/
axiom risk_reduces_investment :
  ∀ (agent : Agent) (w w' : World),
    riskMaterialized agent w' →
    trustLevel agent w' < trustLevel agent w →
    investmentLevel w' ≤ investmentLevel w

-- ============================================================
-- 均衡の探索 (manifesto Section 6)
-- ============================================================

/-!
## 均衡の探索

manifesto Section 6:
「最適な自律度は最大自律度ではない。人間・エージェント・構造の
協働価値が最大化される均衡点が存在し、均衡点は文脈によって動く。」

自律権の過剰拡張が協働価値を減少させるシナリオ:
- 人間がシステム全体を把握できなくなる
- 人間の専門スキルが退化しフォールバック不能に
- P1 により攻撃面が防御能力を超える

### 変数と境界条件の相互作用

```
変数の改善 ──→ 人間への利益の増加 ──→ 投資可変境界の調整
                                         │
   ┌─────────────────────────────────────┘
   ├─→ L3（リソース境界）の調整 ──→ 変数の改善余地が変化する
   └─→ L4（行動空間境界）の調整 ──→ 行動空間が均衡点に向かう
```
-/

/-- 協働価値: 人間・エージェント・構造の三者から成る総合的な価値。
    Section 6: 均衡点は協働価値が最大化される点。 -/
opaque collaborativeValue (w : World) : Nat

/-- 均衡状態: 行動空間をこれ以上拡大しても協働価値が改善しない。
    「最適自律度 ≠ 最大自律度」の形式化。 -/
def atEquilibrium (agent : Agent) (w : World) : Prop :=
  ∀ (w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    collaborativeValue w' ≤ collaborativeValue w

/-- [Axiom Card]
    Layer: Γ \ T₀（仮説由来）
    Content: 過剰拡大は協働価値を減少させうる。
          行動空間の拡大が価値を減少させるシナリオが存在する
    Basis: P1 (capability_risk_coscaling) の帰結として
          行動空間↑ → リスク↑ → 潜在的被害↑ → 過剰拡大は価値毀損。
          E2 だけでは「協働価値の減少」を導出できない
          （協働価値は opaque であり、追加の仮定が必要）
    Source: manifesto.md Section 6「最適な自律度は最大自律度ではない」
    Refutation condition: 行動空間の拡大が常に協働価値を改善することが証明された場合 -/
axiom overexpansion_reduces_value :
  ∃ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' ∧
    collaborativeValue w' < collaborativeValue w

/-- L4 の縮小トリガー: 行動空間は縮小もありうる。
    taxonomy L4: 「L4 は拡張ではなく調整」
    品質事故 → 行動空間の縮小が正当化される。 -/
def contractionJustified (agent : Agent) (w : World) : Prop :=
  riskMaterialized agent w ∧
  ¬atEquilibrium agent w

-- ============================================================
-- 信頼の非対称性の統合的表現
-- ============================================================

/-!
## 信頼の非対称性

蓄積は漸進的（trust_accumulates_gradually: bounded increment）、
毀損は急激（trust_decreases_on_materialized_risk: unbounded decrease）。

この非対称性が L1（倫理・安全境界）の存在意義を補強する:
「毀損を起こさないための絶対的な防護壁」
-/

/-- 信頼の非対称性: 蓄積には上限があるが、毀損には下限がない。
    trust_accumulates_gradually の帰結として、
    蓄積は boundされている（≤ trustIncrementBound）が、
    trust_decreases_on_materialized_risk は decrease に bound を課さない。

    この非対称性は型の構造から読み取れる:
    - 蓄積: trustLevel w' ≤ trustLevel w + trustIncrementBound
    - 毀損: trustLevel w' < trustLevel w （下限なし） -/
def trustAsymmetry (agent : Agent) (w w' : World) : Prop :=
  -- 蓄積は bounded
  (¬riskMaterialized agent w' →
    trustLevel agent w' ≤ trustLevel agent w + trustIncrementBound) ∧
  -- 毀損は unbounded（下限なし）
  (riskMaterialized agent w' →
    actionSpaceSize agent w < actionSpaceSize agent w' →
    trustLevel agent w' < trustLevel agent w)

-- ============================================================
-- Derived theorems: TradeoffExists aggregation lemmas
-- ============================================================

/-!
## TradeoffExists 集約定理

トレードオフ構造の集約的な表現。V2 がハブ変数であること、
双方向トレードオフの存在を aggregation lemma として表現する。
-/

/-- V2 (contextEfficiency) は 5 変数とトレードオフ関係を持つハブ変数（aggregation lemma）。
    V1（スキル品質）, V3（出力品質）, V5（提案精度）, V6（知識構造の質）,
    V7（タスク設計効率）がいずれもコンテキスト効率とトレードオフ関係を持つ。 -/
theorem tradeoff_context_is_hub :
    TradeoffExists skillQuality contextEfficiency ∧
    TradeoffExists outputQuality contextEfficiency ∧
    TradeoffExists proposalAccuracy contextEfficiency ∧
    TradeoffExists knowledgeStructureQuality contextEfficiency ∧
    TradeoffExists taskDesignEfficiency contextEfficiency :=
  ⟨tradeoff_v1_v2, tradeoff_v3_v2, tradeoff_v5_v2, tradeoff_v6_v2, tradeoff_v7_v2⟩

/-- V1-V2 間の双方向トレードオフ（aggregation lemma）。 -/
theorem bidirectional_tradeoff_v1_v2 :
    TradeoffExists skillQuality contextEfficiency ∧
    TradeoffExists contextEfficiency skillQuality :=
  ⟨tradeoff_v1_v2, tradeoff_v2_v1⟩

/-- V6-V2 間の双方向トレードオフ（aggregation lemma）。 -/
theorem bidirectional_tradeoff_v6_v2 :
    TradeoffExists knowledgeStructureQuality contextEfficiency ∧
    TradeoffExists contextEfficiency knowledgeStructureQuality :=
  ⟨tradeoff_v6_v2, tradeoff_v2_v6⟩

-- ============================================================
-- Derived theorems: Investment cycle
-- ============================================================

/-!
## 投資サイクル派生定理

投資サイクルの正方向・負方向の両面を集約する aggregation lemma と、
measurable_threshold_observable の適用による Observable 派生定理。
-/

/-- 投資サイクルは正方向（信頼→投資増）と負方向（リスク→投資減）の両方を持つ（aggregation lemma）。 -/
theorem investment_cycle_complete :
    (∀ (w w' : World),
      (∃ t, systemHealthy t w ∧ systemHealthy t w' ∧
        (skillQuality w < skillQuality w' ∨
         contextEfficiency w < contextEfficiency w' ∨
         outputQuality w < outputQuality w')) →
      investmentLevel w ≤ investmentLevel w') ∧
    (∀ (agent : Agent) (w w' : World),
      riskMaterialized agent w' →
      trustLevel agent w' < trustLevel agent w →
      investmentLevel w' ≤ investmentLevel w) :=
  ⟨trust_drives_investment, risk_reduces_investment⟩

/-- trustLevel が Observable（measurable_threshold_observable の適用）。 -/
theorem trust_threshold_observable (agent : Agent) (t : Nat) :
    Observable (fun w => trustLevel agent w ≥ t) :=
  measurable_threshold_observable (trust_measurable agent) t

/-- degradationLevel が Observable（measurable_threshold_observable の適用）。 -/
theorem degradation_threshold_observable (t : Nat) :
    Observable (fun w => degradationLevel w ≥ t) :=
  measurable_threshold_observable degradation_measurable t

end Manifest
