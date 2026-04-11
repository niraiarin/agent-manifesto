import Manifest.Ontology

/-!
# 数理論理学用語リファレンスの形式化

`docs/mathematical-logic-terminology.md` の概念体系を Lean の型として書き下す。

## 形式化の構造

- **論議領域**: 用語リファレンスの各セクション (§1-§9) が定義する概念
- **T₀**: 概念の定義自体。型定義（定義的拡大, §5.5）としてエンコード。
  列挙型の網羅性は CIC の帰結であり、theorem で証明する
- **Γ \ T₀**: 概念間の関係に関する主張のうち、CIC から導出不能なもの
- **φ**: 用語体系の内部整合性。概念間の関係が正しく成立すること

## 対象セクション

マニフェスト形式化で参照される概念に焦点を当てる:
- §1: 形式体系の 3 要素
- §4: 公理と定理の分類・独立性
- §5: メタ性質（無矛盾性, 健全性, 完全性）と体系の拡張
- §6: 空虚な推論（公理衛生との接続）
- §9: 隣接分野（反証可能性, 信念修正, プログラム検証）
-/

namespace Manifest.Terminology

-- ============================================================
-- §1. 形式体系 (Formal System)
-- ============================================================

/-!
## S1 Formal System Components

「形式体系は以下の 3 要素から構成される:
 形式言語、公理、推論規則」

形式体系の中で、公理に推論規則を繰り返し適用して得られる
整式を定理と呼ぶ。公理から定理に至る推論規則の適用列を証明と呼ぶ。
-/

/-- 形式体系の構成要素。§1 の 3 要素。 -/
inductive FormalSystemComponent where
  /-- 形式言語: 記号の集合と組み合わせ規則。整式 (wff) を定める -/
  | formalLanguage
  /-- 公理: 証明なしに真と仮定する整式の集合 -/
  | axiomSet
  /-- 推論規則: 整式から整式を導く変換規則 -/
  | inferenceRule
  deriving BEq, Repr, DecidableEq

/-- T₀: 形式体系は正確に 3 つの構成要素を持つ。
    ソース: mathematical-logic-terminology.md §1 -/
theorem formal_system_has_three_components :
  ∀ (c : FormalSystemComponent),
    c = .formalLanguage ∨ c = .axiomSet ∨ c = .inferenceRule := by
  intro c; cases c <;> simp

/-- 形式体系の産出物。公理から推論規則で得られるもの。 -/
inductive FormalSystemOutput where
  /-- 定理: 公理に推論規則を繰り返し適用して得られる整式 -/
  | theorem_
  /-- 証明: 公理から定理に至る推論規則の適用列 -/
  | proof
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- §4. 公理と定理
-- ============================================================

/-!
## S4 Axiom and Theorem Classification

S4.1 Axiom classification
- 論理的公理: 論理体系自体に属する。すべての理論で共有
- 非論理的公理: 特定の理論に固有。その理論が扱う対象についての仮定

S4.2 Theorem classification
- 定理・補題・系・命題の区別は純粋に慣習的であり、
  形式的にはすべて「公理から導出された命題」

S4.3 Axiom independence
- 独立: ある公理が残りの公理から導出できないこと
-/

/-- 公理の分類。§4.1。 -/
inductive AxiomKind where
  /-- 論理的公理: すべての理論で共有される。例: 命題論理の公理図式 -/
  | logical
  /-- 非論理的公理: 特定の理論に固有。その理論が扱う対象についての仮定 -/
  | nonLogical
  deriving BEq, Repr, DecidableEq

/-- T₀: 公理は論理的か非論理的かの 2 種に分類される。
    ソース: mathematical-logic-terminology.md §4.1 -/
theorem axiom_kinds_exhaustive :
  ∀ (k : AxiomKind), k = .logical ∨ k = .nonLogical := by
  intro k; cases k <;> simp

/-- 定理の慣習的分類。§4.2。
    注: 形式的にはすべて同等（「公理から導出された命題」）。 -/
inductive TheoremRole where
  /-- 定理: 主要な結果 -/
  | theorem_
  /-- 補題: 定理の証明に用いる中間的な結果 -/
  | lemma_
  /-- 系: ある定理から直ちに導かれる結果 -/
  | corollary
  /-- 命題: 定理ほど重要でないが独立して述べる価値のある結果 -/
  | proposition
  deriving BEq, Repr, DecidableEq

/-- T₀: 定理の慣習的分類は 4 種。§4.2。 -/
theorem theorem_roles_exhaustive :
  ∀ (r : TheoremRole), r = .theorem_ ∨ r = .lemma_ ∨
    r = .corollary ∨ r = .proposition := by
  intro r; cases r <;> simp

/-- §4.2 の核心: 定理・補題・系・命題の区別は形式的には同等。
    これを「任意の 2 つの TheoremRole は形式的に区別不能」として表現する。
    具体的には、形式的地位 (formal standing) は全て同一。 -/
def formalStanding : TheoremRole → String
  | .theorem_    => "derived from axioms"
  | .lemma_      => "derived from axioms"
  | .corollary   => "derived from axioms"
  | .proposition => "derived from axioms"

/-- §4.2 の定理: すべての TheoremRole は同一の形式的地位を持つ。 -/
theorem theorem_roles_formally_equivalent :
  ∀ (r₁ r₂ : TheoremRole), formalStanding r₁ = formalStanding r₂ := by
  intro r₁ r₂; cases r₁ <;> cases r₂ <;> rfl

/-- 公理の独立性の概念。§4.3。
    独立: ある公理が残りの公理から導出できないこと。 -/
inductive IndependenceStatus where
  /-- 独立: 残りの公理から導出不能 -/
  | independent
  /-- 冗長: 残りの公理から導出可能 -/
  | redundant
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- §5. 形式体系のメタ性質
-- ============================================================

/-!
## S5 Meta-properties and System Extension

S5.1 Basic meta-properties
無矛盾性、健全性、完全性、決定可能性

S5.5 System extension
拡大の 4 種とその包含関係:
  定義的拡大 ⊂ 保存拡大 ⊂ 無矛盾な拡大 ⊂ 拡大

S5.6 Object theory and metatheory
-/

/-- 形式体系のメタ性質。§5.1。 -/
inductive MetaProperty where
  /-- 無矛盾性: 体系から矛盾が導出されない -/
  | consistency
  /-- 健全性: 証明可能なものはすべて妥当。⊢ φ ⇒ ⊨ φ -/
  | soundness
  /-- 完全性: 妥当なものはすべて証明可能。⊨ φ ⇒ ⊢ φ -/
  | completeness
  /-- 決定可能性: 定理であるか否かを判定するアルゴリズムが存在 -/
  | decidability
  deriving BEq, Repr, DecidableEq

/-- T₀: 基本的メタ性質は 4 種。§5.1。 -/
theorem meta_properties_exhaustive :
  ∀ (p : MetaProperty), p = .consistency ∨ p = .soundness ∨
    p = .completeness ∨ p = .decidability := by
  intro p; cases p <;> simp

/-- 体系の拡張の種類。§5.5。
    包含関係: definitional ⊂ conservative ⊂ consistent ⊂ general -/
inductive ExtensionKind where
  /-- 定義的拡大: 新しい記号を既存の記号で定義。常に保存拡大 -/
  | definitional
  /-- 保存拡大: 元の言語の定理を保存する拡大 -/
  | conservative
  /-- 無矛盾な拡大: 拡大後の体系が無矛盾 -/
  | consistent
  /-- 拡大（一般）: Thm(S₁) ⊆ Thm(S₂) -/
  | general
  deriving BEq, Repr, DecidableEq

/-- T₀: 拡大は 4 種に分類される。§5.5。 -/
theorem extension_kinds_exhaustive :
  ∀ (k : ExtensionKind), k = .definitional ∨ k = .conservative ∨
    k = .consistent ∨ k = .general := by
  intro k; cases k <;> simp

/-- 拡大の強度順序。
    定義的(3) > 保存(2) > 無矛盾(1) > 一般(0)
    値が大きいほど性質が強い（より多くの保証を提供する）。 -/
def ExtensionKind.strength : ExtensionKind → Nat
  | .definitional => 3
  | .conservative => 2
  | .consistent   => 1
  | .general      => 0

/-- 拡大の包含関係。§5.5:
    「定義的拡大 ⊂ 保存拡大 ⊂ 無矛盾な拡大」 -/
def ExtensionKind.impliedBy : ExtensionKind → ExtensionKind → Prop :=
  fun k₁ k₂ => k₁.strength ≤ k₂.strength

instance : LE ExtensionKind := ⟨fun k₁ k₂ => k₂.strength ≤ k₁.strength⟩

/-- §5.5 の定理: 定義的拡大は保存拡大を含意する。
    「定義的拡大は常に保存拡大」 -/
theorem definitional_implies_conservative :
  ExtensionKind.conservative.strength ≤ ExtensionKind.definitional.strength := by
  simp [ExtensionKind.strength]

/-- §5.5 の定理: 保存拡大は無矛盾な拡大を含意する。
    「保存拡大は無矛盾な拡大であるが、逆は成立しない」 -/
theorem conservative_implies_consistent :
  ExtensionKind.consistent.strength ≤ ExtensionKind.conservative.strength := by
  simp [ExtensionKind.strength]

/-- §5.5 の定理: 完全な包含関係の連鎖。
    定義的 ≥ 保存 ≥ 無矛盾 ≥ 一般 -/
theorem extension_strength_chain :
  ExtensionKind.definitional.strength ≥ ExtensionKind.conservative.strength ∧
  ExtensionKind.conservative.strength ≥ ExtensionKind.consistent.strength ∧
  ExtensionKind.consistent.strength ≥ ExtensionKind.general.strength := by
  simp [ExtensionKind.strength]

/-- §5.5 の定理: 包含関係は真部分集合（strict）。
    定義的拡大 ⊊ 保存拡大 ⊊ 無矛盾な拡大 ⊊ 拡大。
    各レベルは異なる strength を持つ。 -/
theorem extension_kinds_strictly_ordered :
  ExtensionKind.definitional.strength ≠ ExtensionKind.conservative.strength ∧
  ExtensionKind.conservative.strength ≠ ExtensionKind.consistent.strength ∧
  ExtensionKind.consistent.strength ≠ ExtensionKind.general.strength := by
  simp [ExtensionKind.strength]

/-- 対象理論とメタ理論の区別。§5.6。 -/
inductive TheoryLevel where
  /-- 対象理論: 研究対象となる形式体系そのもの -/
  | objectTheory
  /-- メタ理論: 対象理論の性質を論じる理論 -/
  | metatheory
  deriving BEq, Repr, DecidableEq

/-- 言語レベルの区別。§5.6。 -/
inductive LanguageLevel where
  /-- 対象言語: 対象理論の言語 -/
  | objectLanguage
  /-- メタ言語: メタ理論を記述する言語 -/
  | metalanguage
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- §2.4/§2.5 構文論と意味論の対応
-- ============================================================

/-!
## S2.4 and S2.5 Derivability and Logical Consequence

⊨ と ⊢ の区別:
- ⊨ は意味論的（真理値割り当て / 解釈に基づく）
- ⊢ は構文論的（推論規則に基づく）

健全性と完全性が成立する体系では Γ ⊨ φ と Γ ⊢ φ は一致する。
-/

/-- 論理的関係の種類。§2.4。 -/
inductive LogicalRelation where
  /-- 論理的帰結 Γ ⊨ φ: 意味論的。Γ を真にする全割り当てで φ も真 -/
  | logicalConsequence
  /-- 導出可能性 Γ ⊢ φ: 構文論的。推論規則の有限回適用で導出可能 -/
  | derivability
  deriving BEq, Repr, DecidableEq

/-- 論理的関係の所属レベル。§2.4/§10.2。 -/
def LogicalRelation.level : LogicalRelation → String
  | .logicalConsequence => "semantics"
  | .derivability       => "syntax"

/-- §2.4: ⊨ と ⊢ は異なるレベルに属する。 -/
theorem semantic_syntactic_distinct :
  LogicalRelation.logicalConsequence.level ≠ LogicalRelation.derivability.level := by
  simp [LogicalRelation.level]

/-- 単調性の概念。§2.5/§5.3。
    Γ ⊢ φ ⇒ Γ ∪ {ψ} ⊢ φ -/
inductive MonotonicityStatus where
  /-- 単調: 前提の追加は既存の導出を保存する -/
  | monotonic
  /-- 非単調: 前提の追加で既存の結論が撤回されうる -/
  | nonMonotonic
  deriving BEq, Repr, DecidableEq

/-- §2.5/§5.3/§5.5: 単調性と拡大の接続。
    単調な体系では、前提集合の拡大（§5.5）が
    既存の定理を保存する（単調性の帰結）。
    これは拡大が定理集合を縮小しないことの根拠。 -/
def monotonicityPreservesExtension : MonotonicityStatus → Bool
  | .monotonic    => true   -- 拡大は既存の導出を保存
  | .nonMonotonic => false  -- 拡大で既存の結論が撤回されうる

/-- §2.5: 単調な体系では拡大が定理を保存する。 -/
theorem monotonic_preserves_extension :
  monotonicityPreservesExtension .monotonic = true := by rfl

/-- §4.3 + §5.5: 独立性と拡大の接続。
    独立な公理を除去しても（§5.5 の逆操作 = 縮小）、
    残りの公理から導出可能な定理集合は変わらない。
    冗長な公理の除去は保存拡大の逆操作に相当。 -/
def independenceImplication : IndependenceStatus → String
  | .independent => "removal changes theorem set"     -- 除去すると定理集合が変わる
  | .redundant   => "removal preserves theorem set"   -- 除去しても定理集合は変わらない

/-- §4.3: 独立な公理と冗長な公理は異なる影響を持つ。 -/
theorem independence_matters :
  independenceImplication .independent ≠ independenceImplication .redundant := by
  simp [independenceImplication]

-- ============================================================
-- §6. 空虚な推論
-- ============================================================

/-!
## S6.4 Vacuous Reasoning

- 空虚な真: P → Q において P が偽のとき、含意全体は真
- 非空虚性: 公理が自明に真ではなく、前件が充足可能であること

公理衛生（手順書 §2.6 検査 1）との接続:
非空虚性チェックはこの概念の運用化。
-/

/-- 命題の空虚性。§6.4。 -/
inductive VacuityStatus where
  /-- 空虚に真: 前件が偽であるため、含意全体が自明に真 -/
  | vacuouslyTrue
  /-- 非空虚: 前件が充足可能であり、命題に実質的内容がある -/
  | nonVacuous
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- §9. 隣接分野の用語
-- ============================================================

/-!
## S9.1 Philosophy of Science - Falsifiability

反証可能性は形式体系内の公理には直接適用されないが、
公理を現実世界の主張として解釈する場合に意味を持つ。
マニフェストの E1-E2（経験的公準）はこの解釈を採用する。
-/

/-- 命題の認識論的地位。§9.1。 -/
inductive EpistemicStatus where
  /-- 反証可能: 偽とする観察が原理的に可能 -/
  | falsifiable
  /-- 分析的: 意味のみから真偽が定まる。形式体系の公理はこれに近い -/
  | analytic
  /-- 経験的: 観察・実験により真偽が検証される -/
  | empirical
  deriving BEq, Repr, DecidableEq

/-- T₀: 認識論的地位は 3 種。§9.1。 -/
theorem epistemic_status_exhaustive :
  ∀ (s : EpistemicStatus), s = .falsifiable ∨ s = .analytic ∨ s = .empirical := by
  intro s; cases s <;> simp

/-!
## S9.2 Belief Revision Theory AGM

AGM の 3 操作: 拡張、縮小、修正。
マニフェストの T₀/Γ\T₀ 構造と直結:
- T₀ の公理: 縮小の対象外
- Γ \ T₀ の公理: 縮小・修正の対象
-/

/-- AGM 信念修正の操作。§9.2。 -/
inductive BeliefRevisionOp where
  /-- 拡張: 信念集合に新しい信念を追加 -/
  | expansion
  /-- 縮小: 信念集合から信念を除去 -/
  | contraction
  /-- 修正: 新しい信念を追加し、無矛盾性を維持するよう調整 -/
  | revision
  deriving BEq, Repr, DecidableEq

/-- T₀: AGM は 3 操作を定義する。§9.2。 -/
theorem agm_operations_exhaustive :
  ∀ (op : BeliefRevisionOp), op = .expansion ∨ op = .contraction ∨ op = .revision := by
  intro op; cases op <;> simp

/-- AGM 操作の無矛盾性保存に関する保証水準。
    guaranteed = 操作の定義により常に保存される
    notGuaranteed = 保存されない場合がありうる（破壊するとは限らない） -/
inductive ConsistencyGuarantee where
  | guaranteed       -- 定義により無矛盾性を常に保存
  | notGuaranteed    -- 無矛盾性の保存が保証されない（破壊しうる）
  deriving BEq, Repr, DecidableEq

/-- AGM 操作と無矛盾性の関係。
    拡張は無矛盾性の保存が保証されない（破りうる）。
    縮小と修正は定義により無矛盾性を保存する。 -/
def consistencyGuarantee : BeliefRevisionOp → ConsistencyGuarantee
  | .expansion   => .notGuaranteed  -- 無矛盾性を破りうる（常にではない）
  | .contraction => .guaranteed     -- 信念の除去は無矛盾性を保つ
  | .revision    => .guaranteed     -- 定義により無矛盾性を維持

/-- §9.2 の定理: 縮小は無矛盾性の保存が保証される。 -/
theorem contraction_preserves_consistency :
  consistencyGuarantee .contraction = .guaranteed := by rfl

/-- §9.2 の定理: 修正は無矛盾性の保存が保証される。 -/
theorem revision_preserves_consistency :
  consistencyGuarantee .revision = .guaranteed := by rfl

/-!
## S9.3 Program Verification

不変条件、事前条件、事後条件、遷移関係。
Ontology.lean の canTransition は遷移関係の実装。
-/

/-- プログラム検証の条件の種類。§9.3。 -/
inductive VerificationConditionKind where
  /-- 不変条件: 実行中常に保持される性質 -/
  | invariant
  /-- 事前条件: 操作の実行前に成立すべき条件 -/
  | precondition
  /-- 事後条件: 操作の実行後に成立する条件 -/
  | postcondition
  /-- 遷移関係: 状態 s から状態 s' への遷移を表す関係 -/
  | transitionRelation
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- §7. 型理論（CIC との接続）
-- ============================================================

/-!
## S7 Type Theory

Curry-Howard correspondence S7.1 and S10.4

命題 ↔ 型、証明 ↔ 項。
Lean 4 はこの対応を基盤とする CIC に基づく。

S7.3 CIC-specific concepts

- 宇宙 (Universe): 型の型の階層
- Prop: 命題の宇宙。証明無関係が定義的に成立
- 帰納型 / 帰納的族
-/

/-- カリー＝ハワード対応の対応表。§7.1/§10.4。
    論理の概念と型理論の概念の対応。 -/
inductive CurryHowardPair where
  /-- 命題 ↔ 型 -/
  | propositionType
  /-- 証明 ↔ 項 -/
  | proofTerm
  /-- 含意 A → B ↔ 関数型 A → B -/
  | implicationFunction
  /-- 連言 A ∧ B ↔ 直積型 A × B -/
  | conjunctionProduct
  /-- 選言 A ∨ B ↔ 直和型 A + B -/
  | disjunctionSum
  /-- 全称 ∀x.P(x) ↔ 依存型 Πx.B(x) -/
  | universalDependent
  /-- 存在 ∃x.P(x) ↔ 依存和 Σx.B(x) -/
  | existentialSigma
  deriving BEq, Repr, DecidableEq

/-- T₀: カリー＝ハワード対応は 7 つの対応で構成される。§10.4。 -/
theorem curry_howard_has_seven_pairs :
  ∀ (p : CurryHowardPair),
    p = .propositionType ∨ p = .proofTerm ∨
    p = .implicationFunction ∨ p = .conjunctionProduct ∨
    p = .disjunctionSum ∨ p = .universalDependent ∨
    p = .existentialSigma := by
  intro p; cases p <;> simp

-- ============================================================
-- 概念間の横断的関係（φ の構成要素）
-- ============================================================

/-!
## Cross-cutting Relations Among Concepts

用語リファレンスが述べる概念間の関係を定理として導出する。
これらが φ（用語体系の内部整合性）を構成する。
-/

/-- §1 + §4: 形式体系の産出物は公理の種類に依存しない。
    論理的公理も非論理的公理も、推論規則を適用すれば定理を生む。
    定理の慣習的分類（theorem/lemma/corollary/proposition）は
    形式的には同等。 -/
theorem axiom_kind_does_not_affect_theorem_status :
  ∀ (r₁ r₂ : TheoremRole), formalStanding r₁ = formalStanding r₂ :=
  theorem_roles_formally_equivalent

/-- §5.5: 拡大の包含関係は推移的。
    definitional → conservative → consistent → general
    の各ステップで strength が非増加。 -/
theorem extension_ordering_transitive :
  ExtensionKind.definitional.strength ≥ ExtensionKind.conservative.strength ∧
  ExtensionKind.conservative.strength ≥ ExtensionKind.consistent.strength ∧
  ExtensionKind.consistent.strength ≥ ExtensionKind.general.strength :=
  extension_strength_chain

/-- §5.5 + §9.2: AGM 操作の無矛盾性保証の対比。
    縮小と修正は無矛盾性が保証されるが、拡張は保証されない。
    修正は拡張と縮小の合成（Levi Identity: K * φ = (K - ¬φ) + φ）に
    対応するが、無矛盾性の保証は修正の定義により付与される。 -/
theorem agm_consistency_contrast :
  consistencyGuarantee .revision = .guaranteed ∧
  consistencyGuarantee .contraction = .guaranteed ∧
  consistencyGuarantee .expansion = .notGuaranteed := by
  constructor
  · rfl
  constructor
  · rfl
  · rfl

-- ============================================================
-- 目標命題 φ: 用語体系の内部整合性
-- ============================================================

/-- [目標命題]
    タスク: 「数理論理学用語リファレンスの概念体系は内部的に整合している」

    形式化の意図:
    用語リファレンスが定義する概念の分類が網羅的であり、
    概念間の関係（拡大の包含関係、定理の形式的同等性、
    AGM 操作の無矛盾性保存）が正しく成立することを導出する。

    構造: 各セクションの整合性の合取。 -/
theorem terminology_internally_consistent :
  -- §1: 形式体系は 3 要素
  (∀ (c : FormalSystemComponent),
    c = .formalLanguage ∨ c = .axiomSet ∨ c = .inferenceRule) ∧
  -- §4.1: 公理は 2 種
  (∀ (k : AxiomKind), k = .logical ∨ k = .nonLogical) ∧
  -- §4.2: 定理の分類は形式的に同等
  (∀ (r₁ r₂ : TheoremRole), formalStanding r₁ = formalStanding r₂) ∧
  -- §5.1: メタ性質は 4 種
  (∀ (p : MetaProperty), p = .consistency ∨ p = .soundness ∨
    p = .completeness ∨ p = .decidability) ∧
  -- §5.5: 拡大の包含関係
  (ExtensionKind.definitional.strength ≥ ExtensionKind.conservative.strength ∧
   ExtensionKind.conservative.strength ≥ ExtensionKind.consistent.strength ∧
   ExtensionKind.consistent.strength ≥ ExtensionKind.general.strength) ∧
  -- §2.4: 構文論と意味論は異なるレベル
  (LogicalRelation.logicalConsequence.level ≠ LogicalRelation.derivability.level) ∧
  -- §9.1: 認識論的地位は 3 種
  (∀ (s : EpistemicStatus), s = .falsifiable ∨ s = .analytic ∨ s = .empirical) ∧
  -- §9.2: AGM は 3 操作、縮小と修正は無矛盾性保証
  (∀ (op : BeliefRevisionOp), op = .expansion ∨ op = .contraction ∨ op = .revision) ∧
  (consistencyGuarantee .contraction = .guaranteed) ∧
  (consistencyGuarantee .revision = .guaranteed) ∧
  -- §5.5: 拡大の真部分集合関係（strict ordering）
  (ExtensionKind.definitional.strength ≠ ExtensionKind.conservative.strength ∧
   ExtensionKind.conservative.strength ≠ ExtensionKind.consistent.strength ∧
   ExtensionKind.consistent.strength ≠ ExtensionKind.general.strength) ∧
  -- §2.5/§5.5: 単調性は拡大を保存する
  (monotonicityPreservesExtension .monotonic = true) ∧
  -- §4.3: 独立な公理と冗長な公理は異なる影響
  (independenceImplication .independent ≠ independenceImplication .redundant) :=
  ⟨formal_system_has_three_components,
   axiom_kinds_exhaustive,
   theorem_roles_formally_equivalent,
   meta_properties_exhaustive,
   extension_strength_chain,
   semantic_syntactic_distinct,
   epistemic_status_exhaustive,
   agm_operations_exhaustive,
   contraction_preserves_consistency,
   revision_preserves_consistency,
   extension_kinds_strictly_ordered,
   monotonic_preserves_extension,
   independence_matters⟩

-- ============================================================
-- SelfGoverning 自己適用
-- ============================================================

/-- 用語リファレンスのセクション。本形式化自体の更新追跡用。 -/
inductive TerminologySection where
  | formalSystem         -- §1
  | axiomAndTheorem      -- §4
  | metaProperties       -- §5
  | proofTheory          -- §6
  | typeTheory           -- §7
  | adjacentFields       -- §9
  deriving BEq, Repr, DecidableEq

instance : SelfGoverning TerminologySection where
  classificationExhaustive := by intro c; cases c <;> simp
  canClassifyUpdate _ _ := True

/-- 全セクションが列挙されていることの証明。 -/
theorem all_sections_enumerated :
  ∀ (s : TerminologySection),
    s = .formalSystem ∨ s = .axiomAndTheorem ∨
    s = .metaProperties ∨ s = .proofTheory ∨
    s = .typeTheory ∨ s = .adjacentFields := by
  intro s; cases s <;> simp

end Manifest.Terminology
