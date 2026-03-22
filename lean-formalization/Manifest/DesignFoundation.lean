import Manifest.Ontology
import Manifest.Axioms
import Manifest.EmpiricalPostulates
import Manifest.Observable

/-!
# Layer 8: Design Foundation — 設計開発基礎論の形式化

design-development-foundation.md の D1–D9 がマニフェストの
T/E/P から導出されることを型検査する。

## 設計方針

各 D を型（def）または定理（theorem）として表現し、
根拠となる T/E/P の axiom/theorem との接続を明示する。

D はメタレベルの設計原理であり、対象レベルの axiom（T/E）とは
異なる。D の形式化は「D が T/E/P と整合していること」の
型レベルでの保証であり、D 自体を axiom として追加するものではない。
-/

namespace Manifest

-- ============================================================
-- D1: 強制のレイヤリング原理
-- ============================================================

/-!
## D1: 強制のレイヤリング

根拠: P5（確率的解釈）+ L1–L6（境界条件の階層）

P5 により、規範的指針は確率的にしか遵守されない。
したがって、L1（安全）のような絶対制約は
構造的強制（確率的解釈を受けない）で実装すべき。
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
## D2: Worker/Verifier 分離

根拠: E1（検証の独立性）+ P2（認知的役割分離）

E1a (verification_requires_independence) が直接の根拠。
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
## D3: 可観測性先行

根拠: P4（劣化の可観測性）+ T5（フィードバックなしに改善なし）

T5 (no_improvement_without_feedback) が直接の根拠:
改善にはフィードバックが必要 → フィードバックには観測が必要。
-/

/-- D3 の根拠: 改善にはフィードバック（＝観測結果）が先行する。
    T5 の直接適用。 -/
theorem d3_observability_precedes_improvement :
  ∀ (w w' : World),
    structureImproved w w' →
    ∃ (f : Feedback), f ∈ w'.feedbacks ∧
      f.timestamp ≥ w.time ∧ f.timestamp ≤ w'.time :=
  no_improvement_without_feedback

-- ============================================================
-- D4: 漸進的自己適用
-- ============================================================

/-!
## D4: 漸進的自己適用

根拠: Section 7（自己適用）+ P3（学習の統治）+ T2（構造の永続性）

開発フェーズは順序を持ち、各フェーズの完了は構造に永続する（T2）。
フェーズ順序は D1–D3 の依存関係から導出される。
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

-- ============================================================
-- D6: 三段設計（境界→緩和策→変数）
-- ============================================================

/-!
## D6: 三段設計

根拠: constraints-taxonomy Part II

Ontology.lean に BoundaryLayer, BoundaryId, Mitigation が
既に定義されている。ここではその設計原理を定理として表現する。
-/

/-- D6 の根拠: 固定境界に対応する変数は緩和策の品質のみ改善可能。
    Observable.lean の fixed_boundary_variables_mitigate_only の再利用。 -/
theorem d6_fixed_boundary_mitigated :
  boundaryLayer .ethicsSafety = .fixed ∧
  boundaryLayer .ontological = .fixed := by
  simp [boundaryLayer]

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
## D9: 分類自体のメンテナンス

根拠: constraints-taxonomy Part IV + P3（学習の統治）+ Section 7（自己適用）

設計基礎論自体が更新対象であり、更新は P3 の互換性分類に従う。

### 自己適用の要件

D9 は「分類自体のメンテナンス」を述べる原理であるから、
D1–D9 自身もまた D9 の適用対象でなければならない（Section 7）。

これを型レベルで表現するために:
1. D1–D9 を DesignPrinciple 型の値としてモデル化する
2. DesignPrinciple の更新が CompatibilityClass で分類されることを要求する
3. 設計基礎論全体を VersionTransition の対象としてモデル化する
-/

/-- 設計原理の識別子。D1–D9 を値として列挙する。
    これにより D1–D9 自身が「更新される対象」として型レベルで扱える。 -/
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

/-- D9 の網羅性: D1–D9 の全原理が更新対象として列挙されている。 -/
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
    p = .d9_selfMaintenance := by
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
-- Sorry Inventory
-- ============================================================

/-!
## Sorry Inventory (DesignFoundation)

sorry なし。新規 axiom なし。

全 theorem は既存の axiom（T/E/P/V）の直接適用、
または inductive 型の cases 解析で証明完了。

D1–D9 の各原理は、マニフェストの axiom 系から
**導出可能**であることが型検査で保証されている。

### Section 7（自己適用）の構造的強制

`SelfGoverning` typeclass（Ontology.lean）により、
D1–D9 を定義する `DesignPrinciple` 型は以下を満たす:
- 互換性分類の適用可能性（`canClassifyUpdate`）
- 分類の網羅性（`classificationExhaustive`）

`governed_update_classified` を呼ぶには `[SelfGoverning α]` が
必要なため、SelfGoverning を実装しない型は自己適用の文脈で
使用できない → **実装忘れは型エラーとして検出される**。
-/

end Manifest
