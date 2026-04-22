import Mathlib.Order.Lattice
import Mathlib.Order.PropInstances
import AgentSpec.Spine.ResearchSpec

/-! # AgentSpec.Spine.ResearchSpecLattice (Week 3 Day 76、GA-S15 Lattice instance)

Q1=A 設計 (Day 75 人間判断): PrePred / PostPred 各々独立 Lattice
(Mathlib `Pi.instLattice` + `Prop.instDistribLattice` 流用で自動付与)。
Q3=B: 既存 `AgentSpec/Spine/ResearchSpec.lean` (Day 53) を不変保持、本 module で隔離追加。

## 設計 (10-gap-analysis.md §GA-S15、Day 75 design)

ResearchSpec の `pre : State → Input → Prop` と `post : State → Input → Output → State → Prop`
は Pi 型の入れ子で、Mathlib の `Prop.instDistribLattice` (DistribLattice Prop) と
`Pi.instLattice [∀ i, Lattice (α' i)] : Lattice (∀ i, α' i)` の組み合わせで
**自動的に Lattice instance を持つ** (再 declare 不要)。

定義的に:
- `(p ⊓ q) s i = p s i ⊓ q s i = p s i ∧ q s i` (Pi.inf + Prop.inf)
- `(p ⊔ q) s i = p s i ⊔ q s i = p s i ∨ q s i` (Pi.sup + Prop.sup)
- `p ≤ q ⟺ ∀ s i, p s i → q s i` (Pi.le + Prop.le = 含意)

## TyDD 原則 (Day 75 design 反映)

- **Pattern #5** (def Prop signature): `PrePred` / `PostPred` は abbrev で alias、Lattice 自動継承
- **Pattern #6** (sorry 0): instance は Mathlib 流用、helper theorem は rfl / Lattice 法則のみ
- **Pattern #7** (artifact-manifest 同 commit): Day 5 hook 済
- **Pattern #8** (Lean 4 予約語回避): `meetPre` / `joinPost` は予約語ではない

## TyDD-F2 / F7 接続

- TyDD-F2 (Lattice): pre/post を partial order 構造として扱う基盤
- TyDD-F7 (Fixed-point iteration on SpecSig lattice): GA-M11 LLM refine loop 収束証明の前提
- Liquid Haskell pre/post 流の lattice 構造を Lean 4 で再現

## Day 76 意思決定ログ

### D1. abbrev (vs def) for PrePred/PostPred
- **採用**: `abbrev PrePred := State → Input → Prop`
- **理由**: Lattice instance を Pi.instLattice + Prop.instDistribLattice から自動継承するために
  type-level transparency が必要。`def` だと typeclass resolution が失敗する。

### D2. helper theorem は rfl で (vs simp / by-tactic)
- **採用**: `strengthenPre_eq_meetPre` / `weakenPost_eq_joinPost` を rfl で証明
- **理由**: Pi.inf と Prop.inf は definitionally equal。`fun s i => p s i ∧ q s i` と
  `(p ⊓ q)` は unfold 後に同形、rfl 成立。
-/

namespace AgentSpec.Spine.ResearchSpecLattice

/-- Pre-condition predicate type (Lattice instance を Pi + Prop から自動継承)。 -/
abbrev PrePred (State Input : Type) : Type := State → Input → Prop

/-- Post-condition predicate type (4-arg、Lattice instance を Pi + Prop から自動継承)。 -/
abbrev PostPred (State Input Output : Type) : Type :=
  State → Input → Output → State → Prop

/-! ## Lattice instance 自動継承 example

Pi.instLattice + Prop.instDistribLattice により、PrePred / PostPred は再 declare なしで
Lattice instance を持つ。以下 example で確認。 -/

example {S I : Type} (p q : PrePred S I) : PrePred S I := p ⊓ q
example {S I : Type} (p q : PrePred S I) : PrePred S I := p ⊔ q
example {S I O : Type} (p q : PostPred S I O) : PostPred S I O := p ⊓ q
example {S I O : Type} (p q : PostPred S I O) : PostPred S I O := p ⊔ q

/-! ## Helper definitions (既存 strengthenPre / weakenPost との連結) -/

/-- `meetPre p q` = pre 強化 (AND 合成)。Pi.inf (Prop.inf 経由) で `fun s i => p s i ∧ q s i`. -/
def meetPre {S I : Type} (p q : PrePred S I) : PrePred S I := p ⊓ q

/-- `joinPost p q` = post 弱化 (OR 合成)。Pi.sup (Prop.sup 経由) で `fun s i o s' => p s i o s' ∨ q s i o s'`. -/
def joinPost {S I O : Type} (p q : PostPred S I O) : PostPred S I O := p ⊔ q

/-! ## 既存 ResearchSpec.strengthenPre / weakenPost との等価性

Day 53 で導入された helper が新 Lattice operator と definitionally equal であることを示す。
既存 helper を変更せずに lattice 構造を後付け可能 (Q3=B 隔離設計の検証)。 -/

/-- `strengthenPre` の pre は meetPre と等価 (Day 53 helper を Lattice 言語で再表現)。 -/
theorem strengthenPre_pre_eq_meetPre {S I O : Type}
    (spec : AgentSpec.Spine.ResearchSpec S I O) (extra : PrePred S I) :
    (spec.strengthenPre extra).pre = meetPre spec.pre extra := rfl

/-- `weakenPost` の post は joinPost と等価。 -/
theorem weakenPost_post_eq_joinPost {S I O : Type}
    (spec : AgentSpec.Spine.ResearchSpec S I O) (alt : PostPred S I O) :
    (spec.weakenPost alt).post = joinPost spec.post alt := rfl

/-! ## Lattice 法則 (Mathlib 既存 theorem を PrePred/PostPred で適用) -/

/-- meet は commutative。 -/
example {S I : Type} (p q : PrePred S I) : p ⊓ q = q ⊓ p := inf_comm _ _

/-- join は commutative。 -/
example {S I O : Type} (p q : PostPred S I O) : p ⊔ q = q ⊔ p := sup_comm _ _

/-- meet は associative。 -/
example {S I : Type} (p q r : PrePred S I) : (p ⊓ q) ⊓ r = p ⊓ (q ⊓ r) := inf_assoc _ _ _

/-- join は associative。 -/
example {S I O : Type} (p q r : PostPred S I O) : (p ⊔ q) ⊔ r = p ⊔ (q ⊔ r) := sup_assoc _ _ _

/-- meet/join 吸収律 (Lattice 法則)。 -/
example {S I : Type} (p q : PrePred S I) : p ⊓ (p ⊔ q) = p := inf_sup_self

/-- join/meet 吸収律。 -/
example {S I : Type} (p q : PrePred S I) : p ⊔ (p ⊓ q) = p := sup_inf_self

/-- meet idempotent。 -/
example {S I : Type} (p : PrePred S I) : p ⊓ p = p := inf_idem _

/-- join idempotent。 -/
example {S I O : Type} (p : PostPred S I O) : p ⊔ p = p := sup_idem _

end AgentSpec.Spine.ResearchSpecLattice

/-! ## ResearchSpec 全体 Lattice instance (Day 77、Q2=B 後半)

naive product order: `spec1 ≤ spec2 ⟺ spec1.pre ≤ spec2.pre ∧ spec1.post ≤ spec2.post`

Hoare refinement order との関係: Liquid Haskell subtype は pre contravariant + post covariant
(`pre(s2) ≤ pre(s1) ∧ post(s1) ≤ post(s2)`)。本 instance は naive product (両方 covariant)、
Q1=A の PrePred/PostPred 個別 Lattice の自然な拡張。Hoare refinement 別 instance は Day 78+
or Week 4 で必要時に追加可能 (Q3=B 隔離設計を維持して別 namespace に置く)。
-/

namespace AgentSpec.Spine.ResearchSpec

instance {S I O : Type} : Lattice (ResearchSpec S I O) where
  le s1 s2 := s1.pre ≤ s2.pre ∧ s1.post ≤ s2.post
  sup s1 s2 := { pre := s1.pre ⊔ s2.pre, post := s1.post ⊔ s2.post }
  inf s1 s2 := { pre := s1.pre ⊓ s2.pre, post := s1.post ⊓ s2.post }
  le_refl _ := ⟨le_refl _, le_refl _⟩
  le_trans _ _ _ h12 h23 := ⟨le_trans h12.1 h23.1, le_trans h12.2 h23.2⟩
  le_antisymm s1 s2 h12 h21 := by
    have hpre : s1.pre = s2.pre := le_antisymm h12.1 h21.1
    have hpost : s1.post = s2.post := le_antisymm h12.2 h21.2
    cases s1; cases s2; congr
  inf_le_left _ _ := ⟨inf_le_left, inf_le_left⟩
  inf_le_right _ _ := ⟨inf_le_right, inf_le_right⟩
  le_inf _ _ _ h1 h2 := ⟨le_inf h1.1 h2.1, le_inf h1.2 h2.2⟩
  le_sup_left _ _ := ⟨le_sup_left, le_sup_left⟩
  le_sup_right _ _ := ⟨le_sup_right, le_sup_right⟩
  sup_le _ _ _ h1 h2 := ⟨sup_le h1.1 h2.1, sup_le h1.2 h2.2⟩

/-! ### ResearchSpec lattice helper theorem -/

/-- meet の pre は pointwise meet。 -/
theorem inf_pre {S I O : Type} (s1 s2 : ResearchSpec S I O) :
    (s1 ⊓ s2).pre = s1.pre ⊓ s2.pre := rfl

/-- meet の post は pointwise meet。 -/
theorem inf_post {S I O : Type} (s1 s2 : ResearchSpec S I O) :
    (s1 ⊓ s2).post = s1.post ⊓ s2.post := rfl

/-- join の pre は pointwise join。 -/
theorem sup_pre {S I O : Type} (s1 s2 : ResearchSpec S I O) :
    (s1 ⊔ s2).pre = s1.pre ⊔ s2.pre := rfl

/-- join の post は pointwise join。 -/
theorem sup_post {S I O : Type} (s1 s2 : ResearchSpec S I O) :
    (s1 ⊔ s2).post = s1.post ⊔ s2.post := rfl

/-- LE は pointwise (pre + post 両方)。 -/
theorem le_iff {S I O : Type} (s1 s2 : ResearchSpec S I O) :
    s1 ≤ s2 ↔ s1.pre ≤ s2.pre ∧ s1.post ≤ s2.post := Iff.rfl

end AgentSpec.Spine.ResearchSpec
