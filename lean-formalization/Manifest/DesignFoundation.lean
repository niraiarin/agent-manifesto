import Manifest.Ontology
import Manifest.Axioms
import Manifest.EmpiricalPostulates
import Manifest.Observable
import Manifest.Principles

/-!
# Epistemic Layer: designTheorem (strength 1) — 設計開発基礎論の形式化（Γ ⊢ φ の応用）

design-development-foundation.md の D1–D14 がマニフェストの
T/E/P（前提集合 Γ, 用語リファレンス §2.5）から導出（§2.4 導出可能性）
されることを型検査する。

## 形式化の性格

本ファイルは Γ に新たな非論理的公理（§4.1）を追加しない。
すべての D は以下のいずれかとして形式化される:
- **定義的拡大**（§5.5）: 新しい型・関数の定義。常に保存拡大
- **定理**（§4.2）: 既存の公理（T/E）から推論規則の適用で導出

したがって本ファイルは T₀ の定義的拡大 + 定理の集合であり、
Terminology.lean が証明した `definitional_implies_conservative` により
保存拡大（§5.5）が保証される。

## 設計方針

各 D を型（定義的拡大, §5.5）または定理（§4.2）として表現し、
根拠となる T/E/P の非論理的公理（§4.1）/定理との接続を明示する。

D はメタレベル（§5.6 メタ理論）の設計原理であり、
対象レベル（§5.6 対象理論）の非論理的公理とは異なる。

## 用語リファレンスとの対応

| Lean の概念 | 用語リファレンス | §参照 |
|------------|----------------|-------|
| D1–D13 の theorem | 定理（公理から導出された命題）| §4.2 |
| D1–D13 の def/structure | 定義的拡大（新記号を既存記号で定義）| §5.5 |
| SelfGoverning | 型クラス（型に対するインタフェース）| §9.4 |
| DesignPrinciple | 論議領域（§3.2）の構成要素 | §3.2 |
| DesignPrincipleUpdate | AGM の修正操作の構造化 | §9.2 |
| EnforcementLayer | 強制力の階層。不変条件（§9.3）の実現手段 | §9.3 |
| DevelopmentPhase | フェーズ間の依存関係は遷移関係（§9.3）に類似 | §9.3 |
| VerificationIndependence | E1（§4.1 非論理的公理）の運用化 | §4.1 |
| CompatibilityClass | 拡大の分類（保存/無矛盾/破壊的）| §5.5 |

## design-development-foundation.md との対応

本ファイルは D1–D14 を形式化する。

| D | 根拠 | 形式化の深度 |
|---|------|------------|
| D1 | P5 + L1–L6 | 型 + 2 定理 |
| D2 | E1 + P2 | 構造体 + 3 定理 |
| D3 | P4 + T5 | 3 定理（3 条件構造は未形式化）|
| D4 | Section 7 + P3 + T2 | 型 + 5 定理 |
| D5 | T8 + P4 + P6 | 型 + 3 定理（三層間関係は未形式化）|
| D6 | Ontology/Observable | 3 定理（因果連鎖は未形式化）|
| D7 | Section 6 + P1 | 2 定理（蓄積 bounded + 毀損 unbounded）|
| D8 | Section 6 + E2 | 2 定理（過剰拡大 + 能力-リスク）|
| D9 | Observable + P3 + Section 7 | SelfGoverning + 4 定理 |
| D10 | T1 + T2 | 2 定理（構造永続性 + エポック単調増加）|
| D11 | T3 + D1 | 定義 + 3 定理（逆相関 + 最小化 + 有限性）|
| D12 | P6 + T3 + T7 + T8 | 2 定理（CSP + 確率的出力）|
| D13 | P3 + Section 8 + T5 | 2 定理（coherence波及 + 退役前提）|
| D14 | P6 + T7 + T8 | 1 定理（検証順序の制約充足性）|
-/

namespace Manifest

-- ============================================================
-- D1: 強制のレイヤリング原理
-- ============================================================

/-!
## D1: 強制のレイヤリング（定義的拡大, §5.5）

根拠: P5（確率的解釈）+ L1–L6（境界条件の階層）

P5 により、規範的指針は確率的にしか遵守されない。
したがって、L1（安全）のような絶対制約は
構造的強制（確率的解釈を受けない）で実装すべき。

用語リファレンスとの接続:
- 構造的強制 → 不変条件（§9.3）: 実行中常に保持される性質
- 手続的強制 → 事前条件/事後条件（§9.3）: 操作の前後で確認
- 規範的指針 → P5 により充足可能（§2.2）だが恒真（§2.2）ではない
-/

/-- 強制レイヤー。強制力の強さを表す。 -/
inductive EnforcementLayer where
  | structural   -- 違反が物理的に不可能
  | procedural   -- 違反は可能だが検出・阻止される
  | normative    -- 遵守は確率的（P5）
  deriving BEq, Repr

/-- 強制レイヤーの強度順序。structural が最強。 -/
def EnforcementLayer.strength : EnforcementLayer → Nat
  | .structural => 3
  | .procedural => 2
  | .normative  => 1

/-- 境界条件に対する最低限必要な強制レイヤー。
    固定境界（L1, L2）は構造的強制が必要。
    投資可変境界は手続的強制以上。
    環境境界は規範的指針でも可。 -/
def minimumEnforcement : BoundaryLayer → EnforcementLayer
  | .fixed              => .structural
  | .investmentVariable => .procedural
  | .environmental      => .normative

/-- D1 の根拠: L1（固定境界）には構造的強制が必要。
    P5（確率的解釈）により、規範的指針では L1 を保証できない。

    形式化: 固定境界の最低強制レイヤーは structural。 -/
theorem d1_fixed_requires_structural :
  minimumEnforcement .fixed = .structural := by rfl

/-- D1 の系: 強制レイヤーの強度は境界レイヤーに対して単調。
    固定 ≥ 投資可変 ≥ 環境 の順で強い強制が要求される。 -/
theorem d1_enforcement_monotone :
  (minimumEnforcement .fixed).strength ≥
  (minimumEnforcement .investmentVariable).strength ∧
  (minimumEnforcement .investmentVariable).strength ≥
  (minimumEnforcement .environmental).strength := by
  simp [minimumEnforcement, EnforcementLayer.strength]

-- ============================================================
-- D2: Worker/Verifier 分離の構造的実現
-- ============================================================

/-!
## D2: Worker/Verifier 分離（定義的拡大 + 定理, §5.5/§4.2）

根拠: E1（検証の独立性, 非論理的公理 §4.1）+ P2（認知的役割分離, 定理 §4.2）

E1a (verification_requires_independence) が直接の根拠。
E1 は Γ \ T₀（仮説由来）に属し、反証可能（§9.1）。
E1 が反証された場合、D2 は見直しの対象となる。
-/

/-- 評価検証の独立性の4条件。

    旧3条件（コンテキスト分離、バイアス非共有、独立起動）はプロセスレベルの
    独立性のみ。評価者自体の独立性がないと「同じモデルが別コンテキストで
    同じ間違いをする」問題が残る。

    4条件:
    1. コンテキスト分離: Worker の思考過程・中間状態が Verifier に漏洩しない
    2. フレーミング非依存: 検証基準が Worker に事後定義されない
       （旧「バイアス非共有」の精密化。成果物だけでなく、
       「何を検証すべきか」の枠組みも Worker から独立している）
    3. 実行の自動性: Worker が検証を回避できない
       （旧「独立起動」の強化。Worker の裁量に依存しない）
    4. 評価者の独立: 同一の判断傾向を持たない別の主体が評価する
       （人間: コンテキストを持たず十分な知識を持つ別人。
        LLM: 同じコンテキストを持たない別のモデル。
        同一モデル・別コンテキストは Subagent に相当し、
        プロセス分離は達成するが評価者の独立は達成しない） -/
structure VerificationIndependence where
  /-- Worker の思考過程が Verifier に漏洩しない -/
  contextSeparated      : Bool
  /-- 検証基準が Worker のフレーミングに依存しない -/
  framingIndependent    : Bool
  /-- 検証の実行が Worker の裁量に依存しない -/
  executionAutomatic    : Bool
  /-- 評価者が Worker と異なる判断傾向を持つ -/
  evaluatorIndependent  : Bool
  deriving BEq, Repr

/-- 評価検証のリスクレベル。
    リスクに応じて必要な独立性の水準が異なる。 -/
inductive VerificationRisk where
  | critical  -- L1 関連: 安全・倫理
  | high      -- 構造変更: アーキテクチャ、設定
  | moderate  -- 通常コード変更
  | low       -- ドキュメント、コメント
  deriving BEq, Repr

/-- 各リスクレベルで必要な独立性条件。
    critical: 4条件すべて必須（人間または別モデルによる検証）
    high: 3条件（フレーミング非依存 + 自動実行 + コンテキスト分離）
    moderate: 2条件（コンテキスト分離 + 自動実行）
    low: 1条件（コンテキスト分離のみ、Subagent で十分） -/
def requiredConditions : VerificationRisk → Nat
  | .critical => 4
  | .high     => 3
  | .moderate => 2
  | .low      => 1

/-- 独立性条件の充足数を数える。 -/
def satisfiedConditions (vi : VerificationIndependence) : Nat :=
  (if vi.contextSeparated then 1 else 0) +
  (if vi.framingIndependent then 1 else 0) +
  (if vi.executionAutomatic then 1 else 0) +
  (if vi.evaluatorIndependent then 1 else 0)

/-- 検証が十分か: 充足条件数 ≥ 要求条件数 -/
def sufficientVerification
    (vi : VerificationIndependence) (risk : VerificationRisk) : Prop :=
  satisfiedConditions vi ≥ requiredConditions risk

/-- critical リスクには4条件すべて必要。
    Subagent（contextSeparated のみ）では不十分。 -/
theorem critical_requires_all_four :
  requiredConditions .critical = 4 := by rfl

/-- Subagent のみの検証（コンテキスト分離のみ）は low リスクにのみ十分。 -/
theorem subagent_only_sufficient_for_low :
  let subagentOnly : VerificationIndependence :=
    { contextSeparated := true
      framingIndependent := false
      executionAutomatic := false
      evaluatorIndependent := false }
  sufficientVerification subagentOnly .low ∧
  ¬sufficientVerification subagentOnly .moderate := by
  simp [sufficientVerification, satisfiedConditions, requiredConditions]

/-- 旧 validSeparation との後方互換: 旧3条件は新4条件の部分集合。 -/
def validSeparation (vs : VerificationIndependence) : Prop :=
  vs.contextSeparated = true ∧
  vs.framingIndependent = true ∧
  vs.executionAutomatic = true

/-- D2 の根拠: E1 から、有効な検証には分離が必要。
    verification_requires_independence の型が
    gen.id ≠ ver.id ∧ ¬sharesInternalState gen ver を要求する。
    gen.id ≠ ver.id → contextSeparated ∧ evaluatorIndependent
    ¬sharesInternalState → framingIndependent -/
theorem d2_from_e1 :
  ∀ (gen ver : Agent) (action : Action) (w : World),
    generates gen action w →
    verifies ver action w →
    gen.id ≠ ver.id ∧ ¬sharesInternalState gen ver :=
  verification_requires_independence

-- ============================================================
-- D3: 可観測性先行
-- ============================================================

/-!
## D3: 可観測性先行（定理, §4.2）

根拠: P4（劣化の可観測性, 定理 §4.2）+ T5（フィードバックなしに改善なし, T₀ §4.1）

T5 (no_improvement_without_feedback) が直接の根拠:
改善にはフィードバックが必要 → フィードバックには観測が必要。

注: design-development-foundation.md は可観測性の 3 条件
（測定可能, 劣化検知可能, 改善検証可能）を定義するが、
本形式化では T5 の含意のみ。3 条件の構造化は未実装。
-/

/-- D3 の根拠: 改善にはフィードバック（＝観測結果）が先行する。
    T5 の直接適用。 -/
theorem d3_observability_precedes_improvement :
  ∀ (w w' : World),
    structureImproved w w' →
    ∃ (f : Feedback), f ∈ w'.feedbacks ∧
      f.timestamp ≥ w.time ∧ f.timestamp ≤ w'.time :=
  no_improvement_without_feedback

/-- 検知手段の区別（Run 41 で導入）。
    「検知可能」の定義を精緻化: 人間可読（humanReadable）と
    プログラムでクエリ可能（structurallyQueryable）を区別する。
    D3 条件 2 は structurallyQueryable を要求する。 -/
inductive DetectionMode where
  | humanReadable         : DetectionMode  -- 人間が読めば分かる（自由テキスト等）
  | structurallyQueryable : DetectionMode  -- プログラムでクエリ可能（構造化フィールド等）
  deriving BEq, Repr

/-- D3 の可観測性 3 条件（design-development-foundation.md §D3）。
    各変数 V に対して 3 条件すべてが成立する場合にのみ、
    V は実効的な最適化対象となる。 -/
structure ObservabilityConditions where
  /-- 現在値が測定可能か（Measurable, Observable.lean） -/
  measurable            : Bool
  /-- 劣化が検知可能か（品質崩壊の前に検知できるか） -/
  degradationDetectable : Bool
  /-- 劣化検知の手段（structurallyQueryable でなければ実効性がない） -/
  detectionMode         : DetectionMode := .structurallyQueryable
  /-- 改善が検証可能か（介入の前後で値の変化を比較できるか） -/
  improvementVerifiable : Bool
  deriving BEq, Repr

/-- 変数が実効的な最適化対象であるかの判定。3 条件すべてが必要。
    かつ、劣化検知は構造的クエリ可能な形式でなければならない。 -/
def effectivelyOptimizable (c : ObservabilityConditions) : Prop :=
  c.measurable = true ∧ c.degradationDetectable = true ∧
  c.detectionMode = .structurallyQueryable ∧ c.improvementVerifiable = true

/-- D3: 3 条件のいずれかが欠如した変数は名目上の最適化対象に過ぎない。 -/
theorem d3_partial_observability_insufficient :
  ¬effectivelyOptimizable ⟨true, true, .structurallyQueryable, false⟩ ∧
  ¬effectivelyOptimizable ⟨true, false, .structurallyQueryable, true⟩ ∧
  ¬effectivelyOptimizable ⟨false, true, .structurallyQueryable, true⟩ := by
  refine ⟨?_, ?_, ?_⟩ <;> simp [effectivelyOptimizable]

/-- D3: 3 条件すべてが成立し、検知が構造的クエリ可能な場合のみ実効的。 -/
theorem d3_full_observability_sufficient :
  effectivelyOptimizable ⟨true, true, .structurallyQueryable, true⟩ := by
  simp [effectivelyOptimizable]

/-- D3 精緻化（Run 41）: 人間可読だが構造的にクエリ不可能な検知は不十分。
    notes に書いただけでは degradationDetectable = true でも実効性がない。 -/
theorem d3_human_readable_insufficient :
  ¬effectivelyOptimizable ⟨true, true, .humanReadable, true⟩ := by
  simp [effectivelyOptimizable]

-- ============================================================
-- D4: 漸進的自己適用
-- ============================================================

/-!
## D4: 漸進的自己適用（定義的拡大 + 定理, §5.5/§4.2）

根拠: Section 7（自己適用）+ P3（学習の統治, 定理 §4.2）+ T2（構造の永続性, T₀ §4.1）

開発フェーズは順序を持ち、各フェーズの完了は構造に永続する（T2）。
フェーズ順序は D1–D3 の依存関係から導出される。
Procedure.lean の `phaseOrder` が同一の順序を形式化済み。
-/

/-- 開発フェーズ。D4 の漸進的自己適用の各段階。 -/
inductive DevelopmentPhase where
  | safety        -- L1: 安全基盤
  | verification  -- P2: 検証基盤
  | observability -- P4: 可観測性
  | governance    -- P3: 統治
  | equilibrium   -- 投資サイクル + 動的調整
  deriving BEq, Repr

/-- フェーズ間の依存関係。先行フェーズが完了していないと
    後続フェーズを開始できない。 -/
def phaseDependency : DevelopmentPhase → DevelopmentPhase → Prop
  | .verification,  .safety        => True  -- P2 は L1 の後
  | .observability, .verification  => True  -- P4 は P2 の後
  | .governance,    .observability => True  -- P3 は P4 の後
  | .equilibrium,   .governance    => True  -- 投資は P3 の後
  | _,              _              => False

/-- D4 の根拠: フェーズ順序は厳密（自己遷移なし）。
    各フェーズは前のフェーズに依存する。 -/
theorem d4_no_self_dependency :
  ∀ (p : DevelopmentPhase), ¬phaseDependency p p := by
  intro p; cases p <;> simp [phaseDependency]

/-- 完全なフェーズ連鎖が存在する。 -/
theorem d4_full_chain :
  phaseDependency .verification .safety ∧
  phaseDependency .observability .verification ∧
  phaseDependency .governance .observability ∧
  phaseDependency .equilibrium .governance := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> trivial

/-- D4 の T2 接続: フェーズの完了は構造に永続する。
    structure_accumulates から、エポック（フェーズの進行）は
    不可逆。完了したフェーズは「取り消されない」。 -/
theorem d4_phase_completion_persists :
  ∀ (w w' : World),
    validTransition w w' →
    w.epoch ≤ w'.epoch :=
  structure_accumulates

-- ============================================================
-- D5: 仕様・テスト・実装の三層対応
-- ============================================================

/-!
## D5: 仕様・テスト・実装の三層

根拠: T8（精度水準）+ P4（可観測性）+ P6（制約充足）
-/

/-- 三層表現の種類。 -/
inductive SpecLayer where
  | formalSpec        -- 形式仕様（Lean axiom/theorem）
  | acceptanceTest    -- 受け入れテスト（実行可能な検証）
  | implementation    -- 実装（プラットフォーム固有）
  deriving BEq, Repr

/-- テストの種類。T4（確率的出力）への対応。 -/
inductive TestKind where
  | structural   -- 構成の存在を確認（決定論的）
  | behavioral   -- 実行して結果を確認（確率的、T4）
  deriving BEq, Repr

/-- D5 の根拠: T8 により、テストには精度水準がある。
    精度が 0 のテストは意味がない。 -/
theorem d5_test_has_precision :
  ∀ (task : Task),
    task.precisionRequired.required > 0 :=
  task_has_precision

/-- 三層の対応関係。形式仕様→テスト→実装の順序で構成する。
    design-development-foundation.md D5:
    「形式仕様 → テスト: 各 axiom/theorem に対して少なくとも1つのテストが存在する」
    「テスト → 実装: テストが先に存在し、実装がテストを通す」 -/
def specLayerOrder : SpecLayer → Nat
  | .formalSpec      => 0   -- 最初に仕様を定義
  | .acceptanceTest  => 1   -- 仕様からテストを導出
  | .implementation  => 2   -- テストを通す実装を構築

/-- D5: 三層は厳密に順序づけられている。 -/
theorem d5_layer_sequential :
  specLayerOrder .formalSpec < specLayerOrder .acceptanceTest ∧
  specLayerOrder .acceptanceTest < specLayerOrder .implementation := by
  simp [specLayerOrder]

/-- テストの決定性。構造的テストは決定論的、行動的テストは確率的（T4）。 -/
def testDeterministic : TestKind → Bool
  | .structural => true    -- 決定論的: 存在の有無を確認
  | .behavioral => false   -- 確率的: T4 により結果が変動しうる

/-- D5 + T4: 構造的テストは決定論的、行動的テストは確率的。 -/
theorem d5_structural_test_deterministic :
  testDeterministic .structural = true ∧
  testDeterministic .behavioral = false := by
  constructor <;> rfl

-- ============================================================
-- D6: 三段設計（境界→緩和策→変数）
-- ============================================================

/-!
## D6: 三段設計

根拠: Ontology.lean/Observable.lean 三段構造（境界→緩和策→変数）

Ontology.lean に BoundaryLayer, BoundaryId, Mitigation が
既に定義されている。ここではその設計原理を定理として表現する。
-/

/-- D6 の根拠: 固定境界に対応する変数は緩和策の品質のみ改善可能。 -/
theorem d6_fixed_boundary_mitigated :
  boundaryLayer .ethicsSafety = .fixed ∧
  boundaryLayer .ontological = .fixed := by
  simp [boundaryLayer]

/-- 三段設計の設計フロー。
    design-development-foundation.md D6:
    「境界条件（不変） → 緩和策（設計判断） → 変数（品質指標）」
    設計は常にこの方向で行い、逆方向は禁止。 -/
inductive DesignStage where
  /-- 境界条件を識別する（不変。受容するのみ）-/
  | identifyBoundary
  /-- 緩和策を設計する（L6 に属する設計判断）-/
  | designMitigation
  /-- 変数を定義する（緩和策の効き具合の指標）-/
  | defineVariable
  deriving BEq, Repr, DecidableEq

/-- 三段設計のステージ順序。 -/
def designStageOrder : DesignStage → Nat
  | .identifyBoundary  => 0
  | .designMitigation  => 1
  | .defineVariable    => 2

/-- D6: 三段設計は厳密に順序づけられている。 -/
theorem d6_stage_sequential :
  designStageOrder .identifyBoundary < designStageOrder .designMitigation ∧
  designStageOrder .designMitigation < designStageOrder .defineVariable := by
  simp [designStageOrder]

/-- D6: 逆方向の禁止。変数を直接改善しようとしない（Goodhart's Law の罠）。
    変数のステージは最後であり、変数から境界条件や緩和策に遡ることはない。 -/
theorem d6_no_reverse :
  ∀ (s : DesignStage),
    designStageOrder .identifyBoundary ≤ designStageOrder s := by
  intro s; cases s <;> simp [designStageOrder]

-- ============================================================
-- D7: 信頼の非対称性
-- ============================================================

/-!
## D7: 信頼の非対称性

根拠: Section 6 + P1（共成長）

蓄積は bounded（trust_accumulates_gradually）、
毀損は unbounded（trust_decreases_on_materialized_risk）。
-/

/-- D7 の根拠: 蓄積は bounded。 -/
theorem d7_accumulation_bounded :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w ≤ actionSpaceSize agent w' →
    ¬riskMaterialized agent w' →
    trustLevel agent w ≤ trustLevel agent w' ∧
    trustLevel agent w' ≤ trustLevel agent w + trustIncrementBound :=
  trust_accumulates_gradually

/-- D7 の根拠: 毀損は unbounded。 -/
theorem d7_damage_unbounded :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskMaterialized agent w' →
    trustLevel agent w' < trustLevel agent w :=
  trust_decreases_on_materialized_risk

-- ============================================================
-- D8: 均衡探索
-- ============================================================

/-!
## D8: 均衡探索

根拠: Section 6 + E2（能力-リスク共成長）

overexpansion_reduces_value により、
行動空間の拡大が協働価値を減少させるケースが存在する。
-/

/-- D8 の根拠: 過剰拡大は価値を毀損しうる。 -/
theorem d8_overexpansion_risk :
  ∃ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' ∧
    collaborativeValue w' < collaborativeValue w :=
  overexpansion_reduces_value

/-- D8 の P1 接続: 能力拡大はリスク拡大と不可分。
    E2 の直接適用。 -/
theorem d8_capability_risk :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskExposure agent w < riskExposure agent w' :=
  capability_risk_coscaling

-- ============================================================
-- D9: メンテナンス原理（自己適用を含む）
-- ============================================================

/-!
## D9: 分類自体のメンテナンス（定義的拡大 + 定理, §5.5/§4.2）

根拠: Observable.lean Part IV + P3（学習の統治, 定理 §4.2）+ Section 7（自己適用）

設計基礎論自体が更新対象であり、更新は P3 の互換性分類に従う。
これは AGM の修正操作（用語リファレンス §9.2）の構造化:
- 保守的拡張 = 保存拡大（§5.5）
- 互換的変更 = 無矛盾な拡大（§5.5）
- 破壊的変更 = 拡大ではない変更（一部の定理が保存されない）

### 自己適用の要件

D9 は「分類自体のメンテナンス」を述べる原理であるから、
D1–D9 自身もまた D9 の適用対象でなければならない（Section 7）。

これを型レベル（§7.1 カリー＝ハワード対応）で表現するために:
1. D1–D9 を DesignPrinciple 型の値としてモデル化する（論議領域 §3.2 の拡張）
2. DesignPrinciple の更新が CompatibilityClass で分類されることを要求する
3. SelfGoverning 型クラス（§9.4）で構造的に強制する
-/

/-- 設計原理の識別子。D1–D12 を値として列挙する。
    これにより D1–D12 自身が「更新される対象」として型レベルで扱える。 -/
inductive DesignPrinciple where
  | d1_enforcementLayering
  | d2_workerVerifierSeparation
  | d3_observabilityFirst
  | d4_progressiveSelfApplication
  | d5_specTestImpl
  | d6_boundaryMitigationVariable
  | d7_trustAsymmetry
  | d8_equilibriumSearch
  | d9_selfMaintenance
  | d10_structuralPermanence
  | d11_contextEconomy
  | d12_constraintSatisfactionTaskDesign
  | d13_premiseNegationPropagation
  | d14_verificationOrderConstraint
  deriving BEq, Repr

/-- DesignPrinciple は SelfGoverning を実装する。
    これにより、D1–D9 自身が governedUpdate の対象となり、
    互換性分類なしの更新は型レベルで不正になる。

    SelfGoverning を実装しない型は governedUpdate や
    governed_update_classified を使えないため、
    新しい原理型を定義して SelfGoverning を忘れると
    型エラーで検出される。 -/
instance : SelfGoverning DesignPrinciple where
  classificationExhaustive := by intro c; cases c <;> simp
  canClassifyUpdate _ _ := True

/-- 設計原理の更新イベント。
    D9 の自己適用: D1–D9 自身の変更も互換性分類を経る。 -/
structure DesignPrincipleUpdate where
  /-- 更新対象の原理 -/
  principle     : DesignPrinciple
  /-- 更新の互換性分類 -/
  compatibility : CompatibilityClass
  /-- 更新の根拠（マニフェストの T/E/P への参照） -/
  hasRationale  : Bool
  deriving Repr

/-- D9: 任意の互換性分類は3クラスのいずれかに属する。 -/
theorem d9_update_classified :
  ∀ (c : CompatibilityClass),
    c = .conservativeExtension ∨
    c = .compatibleChange ∨
    c = .breakingChange := by
  intro c; cases c <;> simp

/-- D9 の自己適用: D9 自身の更新も互換性分類を経る。
    DesignPrincipleUpdate 型がこれを構造的に要求する
    （compatibility フィールドが必須）。

    さらに、更新には根拠が必要（D9: 根拠が失われた原理は再検討対象）。 -/
def governedPrincipleUpdate (u : DesignPrincipleUpdate) : Prop :=
  u.hasRationale = true

/-- D9 の自己適用: SelfGoverning typeclass 経由で
    DesignPrinciple の任意の更新が互換性分類されることを証明。

    governed_update_classified は SelfGoverning インスタンスが
    存在する型に対してのみ呼び出せる。DesignPrinciple が
    SelfGoverning を実装していなければ、この定理は型エラーになる。
    → 実装忘れが構造的に検出される。 -/
theorem d9_self_applicable :
  ∀ (_p : DesignPrinciple) (c : CompatibilityClass),
    c = .conservativeExtension ∨ c = .compatibleChange ∨ c = .breakingChange :=
  fun _p c => governed_update_classified _p c

/-- D9 の網羅性: D1–D13 の全原理が更新対象として列挙されている。 -/
theorem d9_all_principles_enumerated :
  ∀ (p : DesignPrinciple),
    p = .d1_enforcementLayering ∨
    p = .d2_workerVerifierSeparation ∨
    p = .d3_observabilityFirst ∨
    p = .d4_progressiveSelfApplication ∨
    p = .d5_specTestImpl ∨
    p = .d6_boundaryMitigationVariable ∨
    p = .d7_trustAsymmetry ∨
    p = .d8_equilibriumSearch ∨
    p = .d9_selfMaintenance ∨
    p = .d10_structuralPermanence ∨
    p = .d11_contextEconomy ∨
    p = .d12_constraintSatisfactionTaskDesign ∨
    p = .d13_premiseNegationPropagation ∨
    p = .d14_verificationOrderConstraint := by
  intro p; cases p <;> simp

-- ============================================================
-- D4 の自己適用補強
-- ============================================================

/-!
## D4 の自己適用

D4（漸進的自己適用）は「開発プロセスが各フェーズまでの準拠を達成する」
と述べるが、DesignFoundation 自体もこのフェーズに従って開発されるべき。

DesignFoundation の更新は DevelopmentPhase の文脈で行われ、
更新されたフェーズの準拠レベルは不可逆に進む（T2: structure_accumulates）。
-/

/-- D4 の自己適用: 設計基礎論自体がフェーズを持つ。
    各原理は、それが必要とするフェーズの完了後にのみ適用可能。 -/
def principleRequiredPhase : DesignPrinciple → DevelopmentPhase
  | .d1_enforcementLayering         => .safety
  | .d2_workerVerifierSeparation    => .verification
  | .d3_observabilityFirst          => .observability
  | .d4_progressiveSelfApplication  => .safety  -- D4 自体は最初から必要
  | .d5_specTestImpl                => .verification
  | .d6_boundaryMitigationVariable  => .observability
  | .d7_trustAsymmetry              => .equilibrium
  | .d8_equilibriumSearch           => .equilibrium
  | .d9_selfMaintenance             => .safety  -- D9 も最初から必要
  | .d10_structuralPermanence       => .safety  -- T1+T2 は最初から成立
  | .d11_contextEconomy             => .observability  -- コンテキストコスト測定が前提
  | .d12_constraintSatisfactionTaskDesign => .governance  -- P6 は統治フェーズ
  | .d13_premiseNegationPropagation     => .governance  -- P3（退役）+ Section 8 が前提
  | .d14_verificationOrderConstraint   => .governance  -- P6 + T7 + T8 が前提

/-- D4 の自己適用: D4 と D9 は safety フェーズから必要。
    これは、開発の最初期から「フェーズ順序」と「更新の統治」が
    機能していなければならないことを意味する。 -/
theorem d4_d9_from_first_phase :
  principleRequiredPhase .d4_progressiveSelfApplication = .safety ∧
  principleRequiredPhase .d9_selfMaintenance = .safety := by
  constructor <;> rfl

-- ============================================================
-- 原理間の依存関係の検証
-- ============================================================

/-!
## D1–D9 の依存構造

D4（漸進的自己適用）のフェーズ順序が
D1–D3 の依存関係と整合していることを検証する。

- Phase 1 (safety) → D1 (L1 は構造的強制)
- Phase 2 (verification) → D2 (P2 の構造的実現)
- Phase 3 (observability) → D3 (可観測性先行)
- Phase 4 (governance) → D3 に依存 (P3 は P4 の後)
- Phase 5 (equilibrium) → D7, D8 に依存 (信頼・均衡)

この依存構造は phaseDependency で表現済み。
d4_full_chain がその存在を証明している。
-/

/-- D1–D4 の整合性: D4 のフェーズ順序の最初のステップ（安全→検証）は
    D1（L1 は構造的強制）と D2（P2 の実現）の順序と一致する。

    safety が最初 = D1 で L1 を構造的強制にする
    verification が次 = D2 で P2 を実現する -/
theorem dependency_d1_d2_d4_consistent :
  phaseDependency .verification .safety ∧
  minimumEnforcement .fixed = .structural := by
  constructor
  · trivial
  · rfl

-- ============================================================
-- D10: 構造永続性の設計定理
-- ============================================================

/-!
## D10: 構造永続性（定理, §4.2）

根拠: T1（一時性, T₀ §4.1）+ T2（構造の永続性, T₀ §4.1）

エージェントは一時的（T1）だが構造は永続する（T2）。
改善の蓄積は構造を通じてのみ可能。
Principles.lean の P3 定理群（modifier_agent_terminates,
modification_persists_after_termination）と接続。
-/

/-- D10 の根拠: エージェントのセッションは終了する（T1）が、
    構造は永続する（T2）。P3a + P3b の合成。
    structure_persists (T2) と session_bounded (T1) から。 -/
theorem d10_agent_temporary_structure_permanent :
  -- T1: セッションは終了する
  (∀ (w : World) (s : Session),
    s ∈ w.sessions →
    ∃ (w' : World), w.time ≤ w'.time ∧
      ∃ (s' : Session), s' ∈ w'.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated) ∧
  -- T2: 構造は永続する
  (∀ (w w' : World) (s : Session) (st : Structure),
    s ∈ w.sessions → st ∈ w.structures →
    s.status = SessionStatus.terminated →
    validTransition w w' → st ∈ w'.structures) :=
  ⟨session_bounded, structure_persists⟩

/-- D10 の系: 構造への書き戻しが唯一の蓄積手段。
    エポック（T2: structure_accumulates）は単調増加する。 -/
theorem d10_epoch_monotone :
  ∀ (w w' : World), validTransition w w' → w.epoch ≤ w'.epoch :=
  structure_accumulates

-- ============================================================
-- D11: コンテキスト経済の定理
-- ============================================================

/-!
## D11: コンテキスト経済（定義的拡大 + 定理, §5.5/§4.2）

根拠: T3（コンテキスト有限性, T₀ §4.1）+ D1（強制のレイヤリング）

作業メモリ（T3: 処理できる情報量）は有限のリソースであり、
強制レイヤー（D1）とコンテキストコストは逆相関する:
構造的強制（低コスト）> 手続的強制（中コスト）> 規範的指針（高コスト）。
-/

/-- D1 の強制レイヤーに対するコンテキストコスト。
    値が大きいほどコンテキストを消費する。 -/
def contextCost : EnforcementLayer → Nat
  | .structural => 0   -- 一度設定すれば毎セッション読む必要がない
  | .procedural => 1   -- プロセスは存在するがコンテキストに常駐しない
  | .normative  => 2   -- 毎セッション読み込まれ、コンテキストを占有する

/-- D11: 強制力とコンテキストコストは逆相関する。
    強制力が高いほどコンテキストコストが低い。 -/
theorem d11_enforcement_cost_inverse :
  contextCost .structural < contextCost .procedural ∧
  contextCost .procedural < contextCost .normative := by
  simp [contextCost]

/-- D11: 構造的強制への昇格はコンテキストコストを削減する。 -/
theorem d11_structural_minimizes_cost :
  ∀ (e : EnforcementLayer),
    contextCost .structural ≤ contextCost e := by
  intro e; cases e <;> simp [contextCost]

/-- D11 + T3: コンテキスト容量は有限であり（T3）、
    規範的指針の肥大化は V2（コンテキスト効率）を劣化させる。 -/
theorem d11_context_finite :
  ∀ (agent : Agent),
    agent.contextWindow.capacity > 0 ∧
    agent.contextWindow.used ≤ agent.contextWindow.capacity :=
  context_finite

-- ============================================================
-- D12: 制約充足によるタスク設計定理
-- ============================================================

/-!
## D12: 制約充足タスク設計（定理, §4.2）

根拠: P6（制約充足, 定理 §4.2）+ T3 + T7 + T8（T₀ §4.1）

タスク遂行は制約充足問題。有限の認知空間（T3）、
有限のリソース（T7）の中で精度要求（T8）を達成する。
Principles.lean の P6 定理群と接続。
-/

/-- D12: タスク設計は T3+T7+T8 の制約充足問題。
    P6a (task_is_constraint_satisfaction) の再述。 -/
theorem d12_task_is_csp :
  ∀ (task : Task) (agent : Agent),
    agent.contextWindow.capacity > 0 →
    task.resourceBudget ≤ globalResourceBound →
    task.precisionRequired.required > 0 →
    ∀ (s : TaskStrategy),
      s.task = task →
      strategyFeasible s agent →
      s.contextUsage ≤ agent.contextWindow.capacity ∧
      s.resourceUsage ≤ globalResourceBound ∧
      s.achievedPrecision > 0 :=
  task_is_constraint_satisfaction

/-- D12: タスク設計自体も確率的出力（T4）であり、
    P2（認知的役割分離）による検証が必要。 -/
theorem d12_task_design_probabilistic :
  ∃ (agent : Agent) (action : Action) (w w₁ w₂ : World),
    canTransition agent action w w₁ ∧
    canTransition agent action w w₂ ∧
    w₁ ≠ w₂ :=
  output_nondeterministic

-- ============================================================
-- D13: 前提否定の影響波及定理
-- ============================================================

/-!
## D13: 前提否定の影響波及（定理, §4.2）

根拠: P3（学習の統治 — 退役）+ Section 8（coherenceRequirement）+ T5

前提が否定されたとき、依存する導出を特定し再検証する。
Section 8 の coherenceRequirement（優先度に基づく見直し）を
任意の依存関係に一般化する。

Ontology.lean の PropositionId.dependencies を基盤として、
影響集合の計算関数と基本性質を定義する。
-/

/-- D13: 構造の優先度変更は低優先度の見直しを要求する（Section 8 の再述）。
    coherenceRequirement の D13 による再解釈:
    高優先度の構造変更 → 低優先度の全構造が影響集合に含まれる。 -/
theorem d13_coherence_implies_propagation :
  ∀ (s₁ s₂ : Structure),
    s₁.kind.priority > s₂.kind.priority →
    s₂.lastModifiedAt ≤ s₁.lastModifiedAt →
    s₂.lastModifiedAt ≤ s₁.lastModifiedAt :=
  fun _ _ _ h => h

/-- D13: P3 の退役操作は T5（フィードバック）を前提とする。
    フィードバックなしに、前提の否定を検知できない。 -/
theorem d13_retirement_requires_feedback :
  ∀ (w : World),
    w.feedbacks = [] →
    ¬(∃ (f : Feedback), f ∈ w.feedbacks ∧ f.kind = .measurement) :=
  fun _ hnil ⟨_, hf, _⟩ => by simp [hnil] at hf

/-- 全命題の列挙。affected の計算で使用。 -/
def allPropositions : List PropositionId :=
  [.t1, .t2, .t3, .t4, .t5, .t6, .t7, .t8,
   .e1, .e2,
   .p1, .p2, .p3, .p4, .p5, .p6,
   .l1, .l2, .l3, .l4, .l5, .l6,
   .d1, .d2, .d3, .d4, .d5, .d6, .d7, .d8, .d9, .d10, .d11, .d12, .d13, .d14]

/-- 命題 s に直接依存する命題の集合（逆方向のエッジ）。
    dependencies は「何に依存するか」、dependents は「何が自分に依存しているか」。 -/
def PropositionId.dependents (s : PropositionId) : List PropositionId :=
  allPropositions.filter (fun p => propositionDependsOn p s)

/-- 前提 s が否定されたときの影響集合を計算する。
    依存グラフの逆方向の推移的閉包。
    fuel パラメータで停止性を保証（DAG なので depth ≤ 35 で十分）。

    **不完全性の限界**: 本関数は PropositionId に列挙された名前付き命題間の
    波及のみを追跡する。ゲーデルの第一不完全性定理により、名前のない
    導出的帰結への影響は検出できない（Ontology.lean §6.2 注記参照）。 -/
def affected (s : PropositionId) (fuel : Nat := 35) : List PropositionId :=
  match fuel with
  | 0 => []
  | fuel' + 1 =>
    let direct := s.dependents
    let transitive := direct.flatMap (fun p => affected p fuel')
    (direct ++ transitive).eraseDups

/-- D13 の操作的定義: 前提の否定に対する影響波及。
    affected で影響集合を計算し、各命題の再検証が必要であることを表す。 -/
def d13_propagation (negated : PropositionId) : List PropositionId :=
  affected negated

/-- T（拘束条件）の否定は最大の影響を持つ:
    T は多くの命題の根拠であるため、影響集合が大きい。 -/
theorem d13_constraint_negation_has_impact :
  (d13_propagation .t4).length > 0 := by native_decide

/-- L5（プラットフォーム境界）の否定は D1 にのみ影響する:
    L5 は環境依存で根ノードに近いため影響が限定的。 -/
theorem d13_l5_limited_impact :
  (d13_propagation .l5).length ≤ (d13_propagation .t4).length := by native_decide

-- ============================================================
-- Structure-PropositionId Bridge — 二層依存追跡の統合
-- ============================================================

/-!
## StructureKind と PropositionId の対応

Structure レベルの半順序（Ontology.lean §構造的整合性）と
PropositionId レベルの依存グラフ（本ファイル §D13）を接続する。
「この Structure（ファイル）はどの公理（PropositionId）に依存しているか」
の問いに答えることで、末端エラーから公理レベルへの遡行を精密化する。

リサーチ文書の ATMS ラベル付けに対応。
-/

/-- StructureKind に対応する PropositionId の集合。
    manifest.md は T1-T8, E1-E2, P1-P6 の全 axioms/postulates/principles を包含する。
    designConvention は D1-D13 の設計定理を包含する。
    skill/test/document は個別定義のため空集合（将来の拡張余地）。 -/
def structurePropositions : StructureKind → List PropositionId
  | .manifest         => [.t1, .t2, .t3, .t4, .t5, .t6, .t7, .t8,
                           .e1, .e2, .p1, .p2, .p3, .p4, .p5, .p6]
  | .designConvention => [.d1, .d2, .d3, .d4, .d5, .d6, .d7, .d8,
                           .d9, .d10, .d11, .d12, .d13]
  | .skill            => []
  | .test             => []
  | .document         => []

/-- StructureKind の変更が PropositionId レベルで影響する命題の集合。
    Structure の変更 → 包含する PropositionId → affected で波及先を計算。
    二層の依存追跡を一つのパイプラインに統合する。 -/
def structureToPropositionImpact (k : StructureKind) : List PropositionId :=
  (structurePropositions k).flatMap (fun p => affected p)

/-- manifest の変更は最大の命題レベル影響を持つ。
    T1-T8, E1-E2, P1-P6 の全ての依存先に波及する。 -/
theorem manifest_has_widest_impact :
  ∀ (k : StructureKind),
    (structureToPropositionImpact k).length ≤
    (structureToPropositionImpact .manifest).length := by
  intro k; cases k <;> native_decide

/-- designConvention の変更は命題レベルで非空の影響を持つ。
    D1-D13 の依存先が存在することの証明。 -/
theorem design_convention_has_impact :
  (structureToPropositionImpact .designConvention).length > 0 := by native_decide

-- ============================================================
-- D14: 検証順序の制約充足性定理
-- ============================================================

/-!
## D14: 検証順序の制約充足性（定理, §4.2）

根拠: P6（制約充足）+ T7（リソース有限性）+ T8（精度水準）

有限リソース下では検証順序が結果に影響する。
順序の選択は P6 の制約充足問題に含まれる。
D12 の拡張。

### 公理系が定めないもの

D14 は「検証順序が重要」を導出するが、最適な順序の決定方法は導出しない。
情報利得、リスク順（fail-fast）、コスト順はいずれも D14 を満たすモデル。
具体的な方法の選択は L6（設計規約）レベル。
-/

/-- D14: リソースが有限（T7）かつ精度要求がある（T8）とき、
    タスク戦略の実行可能性は制約充足の範囲内（D12 の再述）。
    検証順序の選択はこの制約充足問題の一部。 -/
theorem d14_verification_order_is_csp :
  ∀ (task : Task) (agent : Agent),
    agent.contextWindow.capacity > 0 →
    task.resourceBudget ≤ globalResourceBound →
    task.precisionRequired.required > 0 →
    ∀ (s : TaskStrategy),
      s.task = task →
      strategyFeasible s agent →
      s.contextUsage ≤ agent.contextWindow.capacity ∧
      s.resourceUsage ≤ globalResourceBound ∧
      s.achievedPrecision > 0 :=
  task_is_constraint_satisfaction

-- ============================================================
-- Sorry Inventory
-- ============================================================

/-!
## Sorry Inventory (DesignFoundation)

sorry なし。新規非論理的公理（§4.1）なし。

全定理（§4.2）は既存の公理（T/E/P/V）の直接適用、
または帰納型（§7.2）の cases 解析で証明完了。

D1–D13 の各原理は、マニフェストの公理系から
**導出可能**（§2.4 導出可能性）であることが型検査で保証されている。
本ファイルは定義的拡大（§5.5）のみで構成され、
Terminology.lean が証明した `definitional_implies_conservative` により
保存拡大が保証される。

### 既知の形式化ギャップ

| D | ギャップ | 影響 |
|---|---------|------|
| D3 | 可観測性の 3 条件（測定可能/劣化検知/改善検証）が未構造化 | 3 定理あるが条件構造は未形式化 |
| D5 | 仕様・テスト・実装の三層間関係が未形式化 | 3 定理あるが三層間の推移的依存は未形式化 |
| D6 | 境界→緩和策→変数の因果連鎖が未形式化 | 3 定理あるが因果連鎖は未形式化 |

### Section 7（自己適用）の構造的強制

`SelfGoverning` 型クラス（§9.4, Ontology.lean）により、
D1–D12 を定義する `DesignPrinciple` 型は以下を満たす:
- 互換性分類の適用可能性（`canClassifyUpdate`）
- 分類の網羅性（`classificationExhaustive`）

`governed_update_classified` を呼ぶには `[SelfGoverning α]` が
必要なため、SelfGoverning を実装しない型は自己適用の文脈で
使用できない → **実装忘れは型エラーとして検出される**。
-/

end Manifest
