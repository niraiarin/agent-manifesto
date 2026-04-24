import AgentSpec.Manifest.Ontology
import AgentSpec.Manifest.Procedure

/-!
# 認識論的層構造の性質（Epistemic Layer Properties）

Issue #33 Gate 1: PropositionCategory.strength の上に認識論的層構造の
6 つの基本性質を定理として導出する。

## 導出する 6 性質

1. **非自明性**: 認識論的に区別すべき層が ≥ 2 存在する
2. **半順序性**: strength による PropositionCategory 上の順序
3. **単調性**: 依存は strength の降順（dependency_respects_strength から）
4. **T₀ 不変性**: 基底層（constraint, strength 最大）は独立かつ縮小不可
5. **有界性**: 層の数は有限、strength は有界
6. **join 存在**: max による結合演算が bounded join-semilattice を構成

## 順序の規約

PropositionCategory.strength は Nat 値を返す:
- constraint = 5（最強、基底理論 T₀）
- hypothesis = 0（最弱、未検証）

順序は strength ≤ で定義。依存は降順: 依存先は依存元以上の strength を持つ。
-/

set_option autoImplicit true

namespace AgentSpec.Manifest.EpistemicLayer

open AgentSpec.Manifest
open AgentSpec.Manifest.Procedure

-- ============================================================
-- Property 1: 非自明性（Non-triviality）
-- ============================================================

/-!
## Property 1 Non-triviality

T4（解釈の非決定性）の前提条件: 認識論的に区別すべき層が 1 つしかなければ、
「解釈」の概念自体が意味をなさない。PropositionCategory が 6 つの相異なる
strength 値を持つことを示す。
-/

/-- 認識論的層は非自明: 異なる strength を持つカテゴリが少なくとも 2 つ存在する。 -/
theorem epistemic_layer_nontrivial :
    ∃ (c₁ c₂ : PropositionCategory),
      c₁.strength ≠ c₂.strength :=
  ⟨.constraint, .hypothesis, by simp [PropositionCategory.strength]⟩

/-- 全 6 カテゴリの strength 値は相異なる。 -/
theorem all_strengths_distinct :
    [PropositionCategory.constraint.strength,
     PropositionCategory.empiricalPostulate.strength,
     PropositionCategory.principle.strength,
     PropositionCategory.boundary.strength,
     PropositionCategory.designTheorem.strength,
     PropositionCategory.hypothesis.strength] =
    [5, 4, 3, 2, 1, 0] := by rfl

-- ============================================================
-- Property 2: 半順序性（Partial Order）
-- ============================================================

/-!
## Property 2 Partial Order

strength : PropositionCategory → Nat が誘導する ≤ 順序は、
Nat の ≤ を通じて反射的・反対称的・推移的な半順序を構成する。
strength が単射であるため、PropositionCategory 上に全順序を誘導する。
-/

/-- strength 順序の反射性。 -/
theorem strength_reflexive :
    ∀ (c : PropositionCategory), c.strength ≤ c.strength :=
  fun _ => Nat.le_refl _

/-- strength は単射: 異なるカテゴリは異なる strength を持つ。
    StructureKind.priority_injective の PropositionCategory 版。 -/
theorem strength_injective :
    ∀ (c₁ c₂ : PropositionCategory),
      c₁.strength = c₂.strength → c₁ = c₂ := by
  intro c₁ c₂; cases c₁ <;> cases c₂ <;> simp [PropositionCategory.strength]

/-- strength 順序の反対称性: strength が相互に ≤ ならば同一カテゴリ。
    Nat.le_antisymm + strength_injective から導出。 -/
theorem strength_antisymmetric :
    ∀ (c₁ c₂ : PropositionCategory),
      c₁.strength ≤ c₂.strength → c₂.strength ≤ c₁.strength →
      c₁ = c₂ := by
  intro c₁ c₂ h₁ h₂
  exact strength_injective c₁ c₂ (Nat.le_antisymm h₁ h₂)

/-- strength 順序の推移性。 -/
theorem strength_transitive :
    ∀ (c₁ c₂ c₃ : PropositionCategory),
      c₁.strength ≤ c₂.strength → c₂.strength ≤ c₃.strength →
      c₁.strength ≤ c₃.strength :=
  fun _ _ _ h₁ h₂ => Nat.le_trans h₁ h₂

-- ============================================================
-- Property 3: 単調性（Monotonicity）
-- ============================================================

/-!
## Property 3 Monotonicity

dependency_respects_strength（Ontology.lean axiom）から:
依存先は依存元以上の strength を持つ。導出結果（低 strength）は
前提（高 strength）に依存する。

この性質は既存 axiom の直接的な帰結。ここでは推移的依存への
拡張と、構成的な具体例を追加する。
-/

/-- 直接依存の単調性（dependency_respects_strength の再表明）。
    依存先 b は依存元 a 以上の認識論的強度を持つ。 -/
theorem direct_dependency_monotone :
    ∀ (a b : PropositionId),
      propositionDependsOn a b = true →
      b.category.strength ≥ a.category.strength :=
  dependency_respects_strength

/-- constraint カテゴリの命題は根ノード（依存なし）であり、
    単調性から他の全カテゴリの命題が依存しうる最上位層。 -/
theorem constraint_layer_is_root :
    ∀ (p : PropositionId),
      p.category = .constraint → p.dependencies = [] :=
  constraints_are_roots

/-- 単調性の具体例: D カテゴリ（designTheorem, strength 1）から
    T カテゴリ（constraint, strength 5）への依存は単調性を満たす。 -/
theorem monotonicity_example_d_to_t :
    PropositionCategory.constraint.strength ≥
    PropositionCategory.designTheorem.strength := by
  simp [PropositionCategory.strength]

-- ============================================================
-- Property 4: T₀ 不変性（T₀ Invariance）
-- ============================================================

/-!
## Property 4 T0 Invariance

基底理論 T₀ に対応する constraint 層の 2 つの不変性質:
1. 根ノード性: 他の命題に依存しない（constraints_are_roots）
2. 縮小禁止: AGM contraction が禁止（t0_contraction_forbidden）

この合成が認識論的層の最上位（strength 最大）が
不動点であることの構造的根拠。
-/

/-- T₀ 不変性: constraint 層は独立（根ノード）かつ縮小不可。
    constraints_are_roots と t0_contraction_forbidden の合成。 -/
theorem t0_invariance :
    (∀ (p : PropositionId), p.category = .constraint → p.dependencies = []) ∧
    (permittedOp .baseTheory .contraction = false) :=
  ⟨constraints_are_roots, t0_contraction_forbidden⟩

/-- constraint は最大 strength を持つ（T₀ は認識論的最上位）。 -/
theorem constraint_is_top :
    ∀ (c : PropositionCategory),
      c.strength ≤ PropositionCategory.constraint.strength := by
  intro c; cases c <;> simp [PropositionCategory.strength]

/-- T₀ 不変性の帰結: constraint 層への依存は常に単調性を満たす。
    （任意のカテゴリ c に対して constraint.strength ≥ c.strength） -/
theorem dependency_on_constraint_always_valid :
    ∀ (c : PropositionCategory),
      PropositionCategory.constraint.strength ≥ c.strength := by
  intro c; cases c <;> simp [PropositionCategory.strength]

-- ============================================================
-- Property 5: 有界性（Boundedness）
-- ============================================================

/-!
## Property 5 Boundedness

PropositionCategory は 6 構成子の帰納型であり、strength 値は 0..5。
T7（リソース有限性）の認識論的層への反映:
有限個のカテゴリしか存在しないため、層の深さは有界。
-/

/-- strength の上界: 全カテゴリの strength は 5 以下。 -/
theorem strength_upper_bound :
    ∀ (c : PropositionCategory), c.strength ≤ 5 := by
  intro c; cases c <;> simp [PropositionCategory.strength]

/-- strength の下界: 全カテゴリの strength は 0 以上（Nat の自明な性質）。 -/
theorem strength_lower_bound :
    ∀ (c : PropositionCategory), 0 ≤ c.strength :=
  fun _ => Nat.zero_le _

/-- 層の数は正確に 6（有限）。 -/
theorem layer_count_finite :
    [PropositionCategory.constraint,
     PropositionCategory.empiricalPostulate,
     PropositionCategory.principle,
     PropositionCategory.boundary,
     PropositionCategory.designTheorem,
     PropositionCategory.hypothesis].length = 6 := by rfl

/-- 全カテゴリの網羅性: 任意の PropositionCategory はリストに含まれる。 -/
theorem category_exhaustive :
    ∀ (c : PropositionCategory),
      c ∈ [PropositionCategory.constraint,
           PropositionCategory.empiricalPostulate,
           PropositionCategory.principle,
           PropositionCategory.boundary,
           PropositionCategory.designTheorem,
           PropositionCategory.hypothesis] := by
  intro c; cases c <;> simp

-- ============================================================
-- Property 6: join 存在（Join Existence）
-- ============================================================

/-!
## Property 6 Join Existence

strength 値の max が join（最小上界）を定義する。
hypothesis（strength 0）が bottom を構成し、
bounded join-semilattice の構造を形成する。

Gabbay (1996) の labelled deductive systems における
bounded join-semilattice に対応。
-/

/-- 2 つのカテゴリの strength の join（最小上界）。 -/
def strengthJoin (c₁ c₂ : PropositionCategory) : Nat :=
  max c₁.strength c₂.strength

/-- join は左引数以上。 -/
theorem join_upper_left :
    ∀ (c₁ c₂ : PropositionCategory),
      c₁.strength ≤ strengthJoin c₁ c₂ :=
  fun c₁ c₂ => Nat.le_max_left c₁.strength c₂.strength

/-- join は右引数以上。 -/
theorem join_upper_right :
    ∀ (c₁ c₂ : PropositionCategory),
      c₂.strength ≤ strengthJoin c₁ c₂ :=
  fun c₁ c₂ => Nat.le_max_right c₁.strength c₂.strength

/-- join は最小上界: 両方以上の任意の値は join 以上。 -/
theorem join_least_upper :
    ∀ (c₁ c₂ : PropositionCategory) (n : Nat),
      c₁.strength ≤ n → c₂.strength ≤ n →
      strengthJoin c₁ c₂ ≤ n := by
  intro c₁ c₂ n h₁ h₂
  exact Nat.max_le.mpr ⟨h₁, h₂⟩

/-- hypothesis は bottom: 全カテゴリの strength 以下。 -/
theorem hypothesis_is_bottom :
    ∀ (c : PropositionCategory),
      PropositionCategory.hypothesis.strength ≤ c.strength := by
  intro c; cases c <;> simp [PropositionCategory.strength]

/-- join の冪等性: join(c, c) = c.strength。 -/
theorem join_idempotent :
    ∀ (c : PropositionCategory),
      strengthJoin c c = c.strength := by
  intro c; simp [strengthJoin]

/-- join の可換性: join(c₁, c₂) = join(c₂, c₁)。 -/
theorem join_commutative :
    ∀ (c₁ c₂ : PropositionCategory),
      strengthJoin c₁ c₂ = strengthJoin c₂ c₁ := by
  intro c₁ c₂; simp [strengthJoin, Nat.max_comm]

/-- join の結合性: join(join(c₁, c₂), c₃) = join(c₁, join(c₂, c₃))。 -/
theorem join_associative :
    ∀ (c₁ c₂ c₃ : PropositionCategory),
      max (strengthJoin c₁ c₂) c₃.strength =
      max c₁.strength (strengthJoin c₂ c₃) := by
  intro c₁ c₂ c₃; simp [strengthJoin, Nat.max_assoc]

-- ============================================================
-- Gate 2: EpistemicLayerClass typeclass
-- ============================================================

/-!
## EpistemicLayerClass typeclass（Issue #33 Gate 2）

G1 の6性質を typeclass 制約として encode する。
任意の型 α が「認識論的層構造」を持つための必要十分条件。

Design decisions -

- `ord : α → Nat` で strength を抽象化。Nat の ≤ が順序を誘導
- `join` は typeclass フィールドではなく、`max (ord a) (ord b)` として導出
  （Nat レベルの操作で十分。α の元を返す必要はない）
- 半順序の反射性・推移性は Nat の性質から自動的に従う
- 反対称性は `ord_injective` から導出
- 単調性（Property 3）は依存関係に対する性質であり、
  層構造自体ではなく依存追跡の型制約（G3 スコープ）

Relation to existing patterns -

- SelfGoverning typeclass: 互換性分類の網羅性（Ontology.lean L725）
- StructureKind.priority: 構造の優先度（Ontology.lean L768）
- 本 typeclass は PropositionCategory.strength を一般化
-/

/-- 認識論的層構造の typeclass。
    型 α が bounded join-semilattice としての認識論的層を持つための条件。
    G1 の6性質のうち、層構造に内在する4性質を encode:
    非自明性、半順序性（単射性）、有界性、bottom 存在。 -/
class EpistemicLayerClass (α : Type) where
  /-- 認識論的強度。Nat の ≤ で順序を誘導する。 -/
  ord : α → Nat
  /-- 最弱元（bounded join-semilattice の bottom）。 -/
  bottom : α
  /-- 非自明性: 異なる ord 値を持つ要素が ≥ 2 存在する。 -/
  nontrivial : ∃ (a b : α), ord a ≠ ord b
  /-- 単射性: ord が単射 → 反対称性を含意。 -/
  ord_injective : ∀ (a b : α), ord a = ord b → a = b
  /-- 有界性: ord 値に有限上界が存在する。 -/
  ord_bounded : ∃ (n : Nat), ∀ (a : α), ord a ≤ n
  /-- bottom は最小: 全要素の ord 以下。 -/
  bottom_minimum : ∀ (a : α), ord bottom ≤ ord a

-- ============================================================
-- EpistemicLayerClass の導出定理
-- ============================================================

variable {α : Type} [EpistemicLayerClass α]

/-- 半順序の反射性（Nat.le_refl から自動導出）。 -/
theorem EpistemicLayerClass.ord_reflexive (a : α) :
    EpistemicLayerClass.ord a ≤ EpistemicLayerClass.ord a :=
  Nat.le_refl _

/-- 半順序の推移性（Nat.le_trans から自動導出）。 -/
theorem EpistemicLayerClass.ord_transitive (a b c : α) :
    EpistemicLayerClass.ord a ≤ EpistemicLayerClass.ord b →
    EpistemicLayerClass.ord b ≤ EpistemicLayerClass.ord c →
    EpistemicLayerClass.ord a ≤ EpistemicLayerClass.ord c :=
  Nat.le_trans

/-- 半順序の反対称性（ord_injective から導出）。 -/
theorem EpistemicLayerClass.ord_antisymmetric (a b : α) :
    EpistemicLayerClass.ord a ≤ EpistemicLayerClass.ord b →
    EpistemicLayerClass.ord b ≤ EpistemicLayerClass.ord a →
    a = b := by
  intro h₁ h₂
  exact EpistemicLayerClass.ord_injective a b (Nat.le_antisymm h₁ h₂)

/-- join 演算（max on ord values）。 -/
def EpistemicLayerClass.join (a b : α) : Nat :=
  max (EpistemicLayerClass.ord a) (EpistemicLayerClass.ord b)

/-- join は左引数の ord 以上。 -/
theorem EpistemicLayerClass.join_upper_left' (a b : α) :
    EpistemicLayerClass.ord a ≤ EpistemicLayerClass.join a b :=
  Nat.le_max_left _ _

/-- join は右引数の ord 以上。 -/
theorem EpistemicLayerClass.join_upper_right' (a b : α) :
    EpistemicLayerClass.ord b ≤ EpistemicLayerClass.join a b :=
  Nat.le_max_right _ _

/-- join は最小上界。 -/
theorem EpistemicLayerClass.join_least' (a b : α) (n : Nat) :
    EpistemicLayerClass.ord a ≤ n →
    EpistemicLayerClass.ord b ≤ n →
    EpistemicLayerClass.join a b ≤ n := by
  intro h₁ h₂
  exact Nat.max_le.mpr ⟨h₁, h₂⟩

/-- bottom と任意の要素の join は、その要素の ord に等しい。 -/
theorem EpistemicLayerClass.join_bottom_left (a : α) :
    EpistemicLayerClass.join (EpistemicLayerClass.bottom) a =
    EpistemicLayerClass.ord a := by
  simp [EpistemicLayerClass.join]
  exact Nat.max_eq_right (EpistemicLayerClass.bottom_minimum a)

-- ============================================================
-- PropositionCategory のインスタンス
-- ============================================================

/-!
## PropositionCategory.strength のインスタンス証明

G1 で証明した性質をそのまま使用して、
PropositionCategory が EpistemicLayerClass のインスタンスであることを示す。
-/

/-- PropositionCategory は EpistemicLayerClass のインスタンス。
    strength 関数が ord、hypothesis が bottom。 -/
instance : EpistemicLayerClass PropositionCategory where
  ord := PropositionCategory.strength
  bottom := .hypothesis
  nontrivial := epistemic_layer_nontrivial
  ord_injective := strength_injective
  ord_bounded := ⟨5, strength_upper_bound⟩
  bottom_minimum := hypothesis_is_bottom

/-- インスタンスの整合性: EpistemicLayerClass.ord と strength が一致。 -/
theorem epistemic_ord_is_strength :
    ∀ (c : PropositionCategory),
      EpistemicLayerClass.ord c = c.strength :=
  fun _ => rfl

/-- インスタンスの整合性: bottom は hypothesis。 -/
theorem epistemic_bottom_is_hypothesis :
    (EpistemicLayerClass.bottom : PropositionCategory) =
    PropositionCategory.hypothesis :=
  rfl

/-- インスタンスの整合性: join は strengthJoin と一致。 -/
theorem epistemic_join_is_strengthJoin :
    ∀ (c₁ c₂ : PropositionCategory),
      EpistemicLayerClass.join c₁ c₂ = strengthJoin c₁ c₂ :=
  fun _ _ => rfl

/-- constraint は EpistemicLayerClass の意味でも top（最大 ord）。 -/
theorem epistemic_constraint_is_top :
    ∀ (c : PropositionCategory),
      EpistemicLayerClass.ord c ≤
      EpistemicLayerClass.ord PropositionCategory.constraint :=
  constraint_is_top

-- ============================================================
-- Gate 3: LayerAssignment 型制約
-- ============================================================

/-!
## LayerAssignment 型制約（Issue #33 Gate 3）

valid な層割り当てが満たすべき整合性条件を型レベルで定義する。
「どの宣言がどの層か」は決めず（第2段階スコープ）、
「任意の valid な割り当てが満たすべき仕様」を定理化する。

Issue 37 scope changes -

| 旧 G3 | 新 G3 |
|--------|--------|
| 全 axiom/theorem の外延的分類 | 層割り当ての内包的型制約 |
| 人間の意味論的判断が必要 | 公理系内部で完結 |
| 第2段階の作業を含む | 第2段階への仕様提供 |
-/

/-- 命題間の依存関係を定義する typeclass。
    外部プロジェクトが独自の命題型 Q に対して依存関係を定義可能にする。 -/
class DependencyGraph (Q : Type) where
  dependsOn : Q → Q → Bool

/-- manifesto の PropositionId に対する DependencyGraph インスタンス。
    既存の propositionDependsOn をラップする。 -/
instance : DependencyGraph PropositionId where
  dependsOn := propositionDependsOn

/-- 認識論的層割り当ての整合性条件。
    型パラメータ P は DependencyGraph を持つ任意の命題型。
    型パラメータ L は EpistemicLayerClass を持つ任意の層型。
    assign は各命題に層を割り当てる関数。
    monotone は依存の方向と層の強度が整合することを要求する。 -/
structure LayerAssignment (P : Type) (L : Type) [DependencyGraph P] [EpistemicLayerClass L] where
  /-- 各命題への層割り当て -/
  assign : P → L
  /-- 単調性: 依存先は依存元以上の ord を持つ。
      dependency_respects_strength の一般化。 -/
  monotone : ∀ (a b : P),
    DependencyGraph.dependsOn a b = true →
    EpistemicLayerClass.ord (assign b) ≥ EpistemicLayerClass.ord (assign a)
  /-- 有界性: 全割り当ての ord に有限上界が存在する。 -/
  bounded : ∃ (n : Nat), ∀ (d : P),
    EpistemicLayerClass.ord (assign d) ≤ n

/-- manifesto 内部用の型エイリアス。既存使用箇所の互換性を保持する。 -/
abbrev ManifestoLayerAssignment (L : Type) [EpistemicLayerClass L] :=
  LayerAssignment PropositionId L

-- ============================================================
-- Theorem 1: 存在性（自明な割り当て）
-- ============================================================

/-- 自明な LayerAssignment が存在する: 全命題を bottom に割り当て。
    bottom の ord は全要素で等しいため、単調性は自明に成立。 -/
theorem trivial_assignment_exists (P : Type) (L : Type) [DependencyGraph P] [EpistemicLayerClass L] :
    ∃ (_ : LayerAssignment P L), True :=
  ⟨{ assign := fun _ => EpistemicLayerClass.bottom
     monotone := fun _ _ _ => Nat.le_refl _
     bounded := ⟨EpistemicLayerClass.ord (EpistemicLayerClass.bottom : L),
                 fun _ => Nat.le_refl _⟩ }, trivial⟩

/-- PropositionId.category による自然な LayerAssignment。
    dependency_respects_strength axiom が monotone 条件を直接満たす。
    これは自明でない valid な割り当ての具体例。 -/
def canonicalAssignment : ManifestoLayerAssignment PropositionCategory where
  assign := PropositionId.category
  monotone := dependency_respects_strength
  bounded := ⟨5, fun d => strength_upper_bound d.category⟩

/-- canonical assignment は自明でない: 異なる命題に異なる層を割り当てる。 -/
theorem canonical_assignment_nontrivial :
    ∃ (p₁ p₂ : PropositionId),
      canonicalAssignment.assign p₁ ≠ canonicalAssignment.assign p₂ := by
  exact ⟨.t1, .d1, by simp [canonicalAssignment, PropositionId.category]⟩

-- ============================================================
-- Theorem 2: 単調性の伝播（推移的依存）
-- ============================================================

/-- 推移的依存: 直接依存の推移閉包。任意の命題型 P に対して一般化。 -/
inductive TransitivelyDependsOn {P : Type} [DependencyGraph P] : P → P → Prop where
  | direct : DependencyGraph.dependsOn a b = true → TransitivelyDependsOn a b
  | trans : TransitivelyDependsOn a b → TransitivelyDependsOn b c →
            TransitivelyDependsOn a c

/-- 単調性は推移的依存に対しても伝播する。
    直接依存の単調性（la.monotone）+ Nat.le_trans から帰納法で導出。 -/
theorem monotonicity_transitive {P : Type} {L : Type} [DependencyGraph P] [EpistemicLayerClass L]
    (la : LayerAssignment P L) :
    ∀ (a c : P),
      TransitivelyDependsOn a c →
      EpistemicLayerClass.ord (la.assign c) ≥
      EpistemicLayerClass.ord (la.assign a) := by
  intro a c h
  induction h with
  | direct hdep => exact la.monotone _ _ hdep
  | trans _ _ ih₁ ih₂ => exact Nat.le_trans ih₁ ih₂

/-- 推移的依存の具体例: D1 → L1 → T6 のチェーン。
    D1 depends on L1, L1 depends on T6。 -/
theorem transitive_dependency_example :
    @TransitivelyDependsOn PropositionId _ .d1 .t6 := by
  apply TransitivelyDependsOn.trans
    (b := PropositionId.l1)
  · exact TransitivelyDependsOn.direct (by native_decide)
  · exact TransitivelyDependsOn.direct (by native_decide)

-- ============================================================
-- Theorem 3: join との整合性
-- ============================================================

/-- join 整合性: 命題 d が d₁ と d₂ の両方に依存するとき、
    d の層は d₁ と d₂ の層の join 以下。
    （依存先が依存元より強いため、join はさらに強い） -/
theorem join_consistency {P : Type} {L : Type} [DependencyGraph P] [EpistemicLayerClass L]
    (la : LayerAssignment P L) :
    ∀ (d d₁ d₂ : P),
      DependencyGraph.dependsOn d d₁ = true →
      DependencyGraph.dependsOn d d₂ = true →
      EpistemicLayerClass.ord (la.assign d) ≤
      EpistemicLayerClass.join (la.assign d₁) (la.assign d₂) := by
  intro d d₁ d₂ h₁ _
  have m₁ := la.monotone d d₁ h₁
  exact Nat.le_trans m₁ (Nat.le_max_left _ _)

/-- join 整合性の対称版: 右側の依存からも導出可能。 -/
theorem join_consistency_right {P : Type} {L : Type} [DependencyGraph P] [EpistemicLayerClass L]
    (la : LayerAssignment P L) :
    ∀ (d d₁ d₂ : P),
      DependencyGraph.dependsOn d d₁ = true →
      DependencyGraph.dependsOn d d₂ = true →
      EpistemicLayerClass.ord (la.assign d) ≤
      EpistemicLayerClass.join (la.assign d₁) (la.assign d₂) := by
  intro d _ d₂ _ h₂
  have m₂ := la.monotone d d₂ h₂
  exact Nat.le_trans m₂ (Nat.le_max_right _ _)

/-- canonical assignment における join 整合性の具体例:
    D1 は L1 と L2 の両方に依存し、
    D1.strength ≤ max(L1.strength, L2.strength)。 -/
theorem join_consistency_example :
    PropositionCategory.designTheorem.strength ≤
    max PropositionCategory.boundary.strength
        PropositionCategory.boundary.strength := by
  simp [PropositionCategory.strength]

/-- 全依存先の join は依存元以上（一般化された単調性）。
    命題 d の全依存先の strength の max は d.strength 以上。 -/
theorem all_dependencies_join_bound :
    ∀ (d dep : PropositionId),
      DependencyGraph.dependsOn d dep = true →
      (canonicalAssignment.assign dep).strength ≥
      (canonicalAssignment.assign d).strength :=
  fun d dep h => canonicalAssignment.monotone d dep h

-- ============================================================
-- Gate 4: 既存定義との互換性確認
-- ============================================================

/-!
## 既存定義との互換性確認（Issue #33 Gate 4）

EpistemicLayerClass が既存の型定義と矛盾しないことを確認する。
conservative extension のみ許可。

Two-axis classification -

| 軸 | 型 | 意味 | 例 |
|----|----|------|----|
| 内容的分類 | PropositionCategory | 命題の種類（T/E/P/L/D/H） | T1 は constraint |
| 認識論的強度 | EpistemicLayerClass.ord | 導出の認識論的層 | constraint は strength 5 |

この2軸は PropositionCategory.strength で接続されており、
EpistemicLayerClass.ord = strength がブリッジ。

Compatibility structure -

1. dependency_respects_strength (axiom) = canonicalAssignment.monotone
2. StructureKind.priority と PropositionCategory.strength は同型の順序構造
3. EpistemicLayerClass は半順序のみ要求 ⊂ 実際は全順序（互換）
-/

/-- dependency_respects_strength は EpistemicLayerClass の ord を通じて
    canonicalAssignment.monotone と同一。リファクタリング不要の根拠。 -/
theorem axiom_compatible_with_typeclass :
    ∀ (a b : PropositionId),
      propositionDependsOn a b = true →
      EpistemicLayerClass.ord (canonicalAssignment.assign b) ≥
      EpistemicLayerClass.ord (canonicalAssignment.assign a) :=
  canonicalAssignment.monotone

/-- StructureKind.priority と PropositionCategory.strength は共に
    単射的な Nat 値マッピングであり、同型の順序構造を持つ。
    （対応: manifest↔constraint, designConvention↔empiricalPostulate 等は
     意味論的対応であり、ここでは構造的同型性のみを示す） -/
theorem priority_and_strength_both_injective :
    (∀ (k₁ k₂ : StructureKind), k₁.priority = k₂.priority → k₁ = k₂) ∧
    (∀ (c₁ c₂ : PropositionCategory), c₁.strength = c₂.strength → c₁ = c₂) :=
  ⟨priority_injective, strength_injective⟩

/-- EpistemicLayerClass は半順序を要求するが、PropositionCategory.strength は
    実際には全順序（任意の2要素が比較可能）。これは互換: 全順序 ⊂ 半順序。 -/
theorem strength_is_total_order :
    ∀ (c₁ c₂ : PropositionCategory),
      c₁.strength ≤ c₂.strength ∨ c₂.strength ≤ c₁.strength := by
  intro c₁ c₂; exact Nat.le_total c₁.strength c₂.strength

/-- canonical assignment の assign は PropositionId.category そのもの。
    既存の category 関数を変更する必要がないことの形式的確認。 -/
theorem canonical_preserves_category :
    ∀ (p : PropositionId),
      canonicalAssignment.assign p = p.category :=
  fun _ => rfl

/-- EpistemicLayerClass の bounded 条件は AxiomSystemProfile の
    有限性と整合する。公理系が有限 → 層割り当ても有限。 -/
theorem bounded_consistent_with_profile :
    ∀ (d : PropositionId),
      EpistemicLayerClass.ord (canonicalAssignment.assign d) ≤ 5 :=
  fun d => strength_upper_bound d.category

end AgentSpec.Manifest.EpistemicLayer
