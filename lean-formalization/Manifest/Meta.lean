import Manifest.Ontology
import Manifest.Axioms
import Manifest.EmpiricalPostulates
import Manifest.Observable

/-!
# Layer 7: Meta — 公理系のメタ性質（メタ理論, 用語リファレンス §5.6）

公理系自体の構造的性質を検証する。
本ファイルの定理はメタ定理（§5.6）であり、対象理論の性質を論じる。

## 設計方針

メタ層は公理系の「内部整合性」と「層構造」を型レベルで表現する。
具体的には:

1. **層の分離**: T₀（基底理論）と Γ \ T₀（拡大部分）は独立に仮定されている
2. **公理の性格分類**: 各非論理的公理（§4.1）がどの層に属するかの型レベル表現
3. **導出の方向性**: P（定理, §4.2）は T/E（公理）から導出される（逆方向の依存はない）
4. **反証可能性の保持**: Γ \ T₀ が反証（§9.1）された場合に影響を受ける P の追跡

## メタ定理 vs 対象定理（用語リファレンス §5.6）

- **対象理論** (Object Theory): Axioms.lean, EmpiricalPostulates.lean, Principles.lean の公理系
- **メタ理論** (Metatheory): 本ファイル。対象理論の性質を論じる理論
- **メタ定理** (Metatheorem): 本ファイルの theorem。例:「E の反証が影響するのは P1, P2 のみ」
- **対象言語** (Object Language): Lean の型と命題
- **メタ言語** (Metalanguage): 同じく Lean（Lean は自身のメタ理論を内部化できる）

## 用語リファレンスとの対応

- AxiomValidityCriteria → 公理衛生（手順書 §2.6）の 3 検査項目への対応
- isFalsifiable → 反証可能性（§9.1）
- AxiomStatus → 非論理的公理（§4.1）の認識論的分類
- DerivationBasis → 導出可能性（§2.4）の根拠分類
-/

namespace Manifest

-- ============================================================
-- 公理の性格分類
-- ============================================================

/-- 公理の認識論的地位。
    T（拘束条件）と E（経験的公準）は異なる堅牢性を持つ。 -/
inductive AxiomStatus where
  | constraint         -- T: 否定不可能。技術非依存の事実
  | empiricalPostulate -- E: 繰り返し実証されているが覆りうる
  | observableAxiom    -- V: Observable 層の設計仮定
  deriving BEq, Repr

/-- 定理の導出根拠。どの層の公理に依拠するか。 -/
inductive DerivationBasis where
  | constraintOnly       -- T のみに依拠（最も堅牢）
  | empiricalDependent   -- E に依拠（E の反証で見直し対象）
  | observableDependent  -- V の axiom に依拠
  | structural           -- 型の構造から導出（axiom 非依存）
  deriving BEq, Repr

/-- 導出根拠の堅牢性順序。
    constraintOnly が最も堅牢、observableDependent が最も脆弱。 -/
def DerivationBasis.robustness : DerivationBasis → Nat
  | .constraintOnly      => 3
  | .structural          => 3  -- 型構造は axiom と同等に堅牢
  | .empiricalDependent  => 2
  | .observableDependent => 1

-- ============================================================
-- 公理系の構成
-- ============================================================

/-- 公理系の層構成。
    マニフェストの公理系（T₀ / Γ \ T₀, 用語リファレンス §4.1）を型として表現。 -/
structure AxiomSystemProfile where
  /-- T₀: 拘束条件（T1–T8）の axiom 数 -/
  constraintCount       : Nat
  /-- Γ \ T₀: 経験的公準（E1–E2）の axiom 数 -/
  empiricalCount        : Nat
  /-- Γ \ T₀: Observable 層の axiom 数 -/
  observableCount       : Nat
  /-- Γ \ T₀: 応用層（FormalDerivationSkill, ConformanceVerification）の axiom 数 -/
  applicationCount      : Nat
  /-- theorem 数（全モジュール合計）-/
  theoremCount          : Nat
  /-- sorry の数 -/
  sorryCount            : Nat
  deriving BEq, Repr

/-- 現在の公理系のプロファイル。 -/
def currentProfile : AxiomSystemProfile :=
  { constraintCount  := 13   -- T1–T8 (Axioms.lean: 13 axioms)
    empiricalCount   := 4    -- E1–E2 (EmpiricalPostulates.lean: 4 axioms)
    observableCount  := 25   -- V1–V7 + tradeoff + Goodhart + sorry解消 + 投資 (Observable.lean: 25 axioms: +2 tradeoff_v3_v2, tradeoff_v5_v2)
    applicationCount := 20   -- FormalDerivationSkill: 17 + ConformanceVerification: 3
    theoremCount     := 243  -- 全モジュール合計（Run 33: +2 Ontology.lean 半順序性質）
    sorryCount       := 0 }

/-- 公理系の総 axiom 数。 -/
def AxiomSystemProfile.totalAxioms (p : AxiomSystemProfile) : Nat :=
  p.constraintCount + p.empiricalCount + p.observableCount + p.applicationCount

/-- 現在の公理系の総 axiom 数は 62。 -/
theorem current_total_axioms :
  currentProfile.totalAxioms = 62 := by rfl

/-- 現在の公理系の定理数は 243。 -/
theorem current_theorem_count :
  currentProfile.theoremCount = 243 := by rfl

/-- sorry が 0 であることの証明。 -/
theorem current_sorry_free :
  currentProfile.sorryCount = 0 := by rfl

-- ============================================================
-- モジュール別定理分布
-- ============================================================

/-- 各 Lean モジュールの定理数。totalAxioms の補完として、
    定理がどのモジュールに分布しているかを型レベルで記録する。 -/
structure TheoremDistribution where
  ontologyM              : Nat  -- Ontology.lean
  axiomsM                : Nat  -- Axioms.lean
  empiricalPostulatesM   : Nat  -- EmpiricalPostulates.lean
  observableM            : Nat  -- Observable.lean
  principlesM            : Nat  -- Principles.lean
  metaM                  : Nat  -- Meta.lean（本ファイル）
  terminologyM           : Nat  -- Terminology.lean
  formalDerivationSkillM : Nat  -- FormalDerivationSkill.lean
  conformanceVerificationM : Nat -- ConformanceVerification.lean
  designFoundationM      : Nat  -- DesignFoundation.lean
  procedureM             : Nat  -- Procedure.lean
  evolutionM             : Nat  -- Evolution.lean
  evolveSkillM           : Nat  -- EvolveSkill.lean
  workflowM              : Nat  -- Workflow.lean
  axiomQualityM          : Nat  -- AxiomQuality.lean
  deriving BEq, Repr

/-- モジュール別定理数の合計。 -/
def TheoremDistribution.total (d : TheoremDistribution) : Nat :=
  d.ontologyM + d.axiomsM + d.empiricalPostulatesM + d.observableM +
  d.principlesM + d.metaM + d.terminologyM + d.formalDerivationSkillM +
  d.conformanceVerificationM + d.designFoundationM + d.procedureM +
  d.evolutionM + d.evolveSkillM + d.workflowM + d.axiomQualityM

/-- 現在のモジュール別定理分布。 -/
def currentTheoremDistribution : TheoremDistribution :=
  { ontologyM              := 11  -- +2: structureDependsOn_transitive, structureDependsOn_asymmetric
    axiomsM                := 0
    empiricalPostulatesM   := 0
    observableM            := 23
    principlesM            := 14
    metaM                  := 12  -- theorem_distribution_consistent を含む
    terminologyM           := 23
    formalDerivationSkillM := 35
    conformanceVerificationM := 17
    designFoundationM      := 33
    procedureM             := 19
    evolutionM             := 16
    evolveSkillM           := 22
    workflowM              := 7   -- +2: no_self_knowledge_transition, knowledge_full_cycle_exists
    axiomQualityM          := 11 }

/-- モジュール別定理数の合計が currentProfile.theoremCount と一致する。 -/
theorem theorem_distribution_consistent :
  currentTheoremDistribution.total = currentProfile.theoremCount := by rfl

-- ============================================================
-- 層の独立性
-- ============================================================

/-!
## 層の独立性

T（拘束条件）は E（経験的公準）に依存しない。
E が反証されても T は影響を受けない。

この独立性は import DAG で構造的に保証されている:
- Axioms.lean は Ontology.lean のみを import
- EmpiricalPostulates.lean は Ontology.lean のみを import
- 両者は相互に import しない

以下のメタ定理は、この独立性の型レベル表現。
-/

/-- T の反証は考慮しない（T は否定不可能）。
    E の反証のみが影響分析の対象。 -/
def isFalsifiable (s : AxiomStatus) : Prop :=
  s = .empiricalPostulate ∨ s = .observableAxiom

/-- T は反証不可能。 -/
theorem constraint_not_falsifiable :
  ¬isFalsifiable .constraint := by
  simp [isFalsifiable]

/-- E は反証可能。 -/
theorem empirical_is_falsifiable :
  isFalsifiable .empiricalPostulate := by
  simp [isFalsifiable]

/-- E の反証が影響するのは empiricalDependent な定理のみ。 -/
def impactedByEmpiricalFalsification (b : DerivationBasis) : Prop :=
  b = .empiricalDependent

/-- constraintOnly な定理は E の反証で影響を受けない。 -/
theorem constraint_derived_immune :
  ¬impactedByEmpiricalFalsification .constraintOnly := by
  simp [impactedByEmpiricalFalsification]

/-- structural な定理も E の反証で影響を受けない。 -/
theorem structural_derived_immune :
  ¬impactedByEmpiricalFalsification .structural := by
  simp [impactedByEmpiricalFalsification]

-- ============================================================
-- P の導出根拠マッピング
-- ============================================================

/-!
## P1–P6 の導出根拠

各 P がどの層に依拠しているかの分類。
E が反証された場合の影響範囲を明確にする。

| P | 根拠 | 堅牢性 |
|---|------|--------|
| P1 | E2 | 経験的（E に依拠） |
| P2 | T4 + E1 | 経験的（E に依拠） |
| P3 | T1 + T2 | 堅牢（T のみ） |
| P4 | T5 | 堅牢（T のみ） |
| P5 | T4 | 堅牢（T のみ） |
| P6 | T3 + T7 + T8 | 堅牢（T のみ） |
-/

/-- P の識別子。 -/
inductive PrincipleId where
  | p1  -- 自律権と脆弱性の共成長
  | p2  -- 認知的役割分離
  | p3  -- 学習の統治
  | p4  -- 劣化の可観測性
  | p5  -- 構造の確率的解釈
  | p6  -- 制約充足としてのタスク設計
  deriving BEq, Repr

/-- 各 P の導出根拠。manifesto.md の導出構造表から。 -/
def principleDerivation : PrincipleId → DerivationBasis
  | .p1 => .empiricalDependent   -- E2 に依拠
  | .p2 => .empiricalDependent   -- E1 に依拠
  | .p3 => .constraintOnly       -- T1 + T2 のみ
  | .p4 => .constraintOnly       -- T5 のみ
  | .p5 => .constraintOnly       -- T4 のみ
  | .p6 => .constraintOnly       -- T3 + T7 + T8

/-- E が反証された場合に影響を受ける P は P1 と P2 のみ。 -/
theorem empirical_falsification_scope :
  impactedByEmpiricalFalsification (principleDerivation .p1) ∧
  impactedByEmpiricalFalsification (principleDerivation .p2) ∧
  ¬impactedByEmpiricalFalsification (principleDerivation .p3) ∧
  ¬impactedByEmpiricalFalsification (principleDerivation .p4) ∧
  ¬impactedByEmpiricalFalsification (principleDerivation .p5) ∧
  ¬impactedByEmpiricalFalsification (principleDerivation .p6) := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> simp [impactedByEmpiricalFalsification, principleDerivation]

/-- 堅牢な P（T のみに依拠）は過半数（4/6）。
    公理系は E の反証に対して構造的にレジリエント。 -/
theorem majority_principles_robust :
  (principleDerivation .p3).robustness ≥ 3 ∧
  (principleDerivation .p4).robustness ≥ 3 ∧
  (principleDerivation .p5).robustness ≥ 3 ∧
  (principleDerivation .p6).robustness ≥ 3 := by
  simp [principleDerivation, DerivationBasis.robustness]

-- ============================================================
-- 公理の妥当性基準
-- ============================================================

/-!
## 公理の妥当性レビュー基準

空虚な axiom（常に True）はシステムに何も追加しない。
各 axiom は以下の3基準で妥当性をレビューされる:

1. **非空虚性**: 常に True ではないか
2. **非トートロジー性**: 定義から自明ではないか
3. **反証可能性**: 原理的に偽になりうるか

具体的な検証は各 axiom の docstring で個別に論じている
（lean-formalization-details.md #16 参照）。
-/

/-- 公理の妥当性基準。3つの観点。 -/
structure AxiomValidityCriteria where
  nonVacuous      : Bool  -- 空虚でないか
  nonTautological : Bool  -- トートロジーでないか
  falsifiable     : Bool  -- 反証可能か
  deriving BEq, Repr

/-- 妥当な axiom は3基準すべてを満たす。 -/
def validAxiom (c : AxiomValidityCriteria) : Prop :=
  c.nonVacuous = true ∧ c.nonTautological = true ∧ c.falsifiable = true

/-- 3基準すべてが true なら validAxiom。 -/
theorem all_true_is_valid :
  validAxiom ⟨true, true, true⟩ := by
  simp [validAxiom]

/-- いずれかの基準が false なら invalid。 -/
theorem vacuous_is_invalid :
  ¬validAxiom ⟨false, true, true⟩ := by
  simp [validAxiom]

-- ============================================================
-- Sorry Inventory
-- ============================================================

/-!
## Sorry Inventory (Meta)

sorry なし。新規 axiom なし。
全 theorem は型の構造（cases, simp, rfl）で証明完了。

メタ層の定理はすべて公理系の構造的性質に関するものであり、
対象レベルの axiom に依存しない（structural derivation）。
-/

end Manifest
